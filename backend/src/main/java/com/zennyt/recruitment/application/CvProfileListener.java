package com.zennyt.recruitment.application;

import com.zennyt.identity.domain.event.ProfileCvUpdatedEvent;
import com.zennyt.recruitment.domain.model.CvProfileProjection;
import com.zennyt.recruitment.domain.repository.CvProfileProjectionRepository;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.stream.Collectors;

/**
 * Maintient la projection locale du CV (texte pré-formaté) sans appel direct
 * au module Identity — même principe que {@link IdentityAccessStateListener}.
 */
@Component
public class CvProfileListener {
    private final CvProfileProjectionRepository projections;

    public CvProfileListener(CvProfileProjectionRepository projections) {
        this.projections = projections;
    }

    @EventListener
    @Transactional
    public void on(ProfileCvUpdatedEvent event) {
        projections.save(new CvProfileProjection(event.publicUserId(), format(event), event.occurredAt()));
    }

    private static String format(ProfileCvUpdatedEvent event) {
        StringBuilder text = new StringBuilder();
        if (event.currentPosition() != null && !event.currentPosition().isBlank()) {
            text.append("Current position: ").append(event.currentPosition()).append('\n');
        }
        if (event.yearsOfExperience() != null) {
            text.append("Years of experience: ").append(event.yearsOfExperience()).append('\n');
        }
        if (event.aboutMe() != null && !event.aboutMe().isBlank()) {
            text.append("About: ").append(event.aboutMe()).append('\n');
        }
        if (!event.skills().isEmpty()) {
            text.append("Skills: ").append(event.skills().stream()
                .map(s -> s.name() + " (" + s.type()
                    + (s.level() != null ? ", level " + s.level() : "") + ")")
                .collect(Collectors.joining(", "))).append('\n');
        }
        if (!event.positions().isEmpty()) {
            text.append("Experience:\n").append(event.positions().stream()
                .map(p -> "- " + p.title() + " at " + p.companyName() + (p.current() ? " (current)" : "")
                    + (p.description() != null && !p.description().isBlank() ? ": " + p.description() : ""))
                .collect(Collectors.joining("\n"))).append('\n');
        }
        if (!event.education().isEmpty()) {
            text.append("Education:\n").append(event.education().stream()
                .map(e -> "- " + e.degree() + ", " + e.school()
                    + (e.fieldOfStudy() != null && !e.fieldOfStudy().isBlank() ? " (" + e.fieldOfStudy() + ")" : ""))
                .collect(Collectors.joining("\n"))).append('\n');
        }
        if (!event.certifications().isEmpty()) {
            text.append("Certifications: ").append(event.certifications().stream()
                .map(c -> c.title() + " — " + c.issuer())
                .collect(Collectors.joining(", ")));
        }
        return text.toString().trim();
    }
}
