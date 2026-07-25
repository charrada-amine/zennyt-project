package com.zennyt.identity.domain.event;

import com.zennyt.identity.domain.model.Profile;
import com.zennyt.shared.domain.event.DomainEvent;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Émis quand les données CV/profil professionnel d'un candidat changent
 * (à propos, poste actuel, expérience, compétences, postes, formations,
 * certifications). Consommé par Recruitment pour alimenter le résumé IA
 * — voir la projection {@code CvProfileProjection}.
 *
 * <p>Les snapshots ci-dessous sont volontairement des types plats (aucune
 * dépendance vers {@code identity.domain.model}), pour que les autres
 * contextes n'aient jamais à connaître {@link Profile} ou ses value objects.
 */
public record ProfileCvUpdatedEvent(
    UUID eventId, Instant occurredAt, UUID publicUserId,
    String currentPosition, String aboutMe, Integer yearsOfExperience,
    List<SkillSnapshot> skills, List<PositionSnapshot> positions,
    List<EducationSnapshot> education, List<CertificationSnapshot> certifications
) implements DomainEvent {

    public record SkillSnapshot(String name, String type, Integer level) {}
    public record PositionSnapshot(String title, String companyName, String description, boolean current) {}
    public record EducationSnapshot(String degree, String school, String fieldOfStudy) {}
    public record CertificationSnapshot(String title, String issuer) {}

    public static ProfileCvUpdatedEvent of(UUID publicUserId, Profile profile) {
        return new ProfileCvUpdatedEvent(UUID.randomUUID(), Instant.now(), publicUserId,
            profile.currentPosition(), profile.aboutMe(), profile.yearsOfExperience(),
            profile.skills().stream()
                .map(s -> new SkillSnapshot(s.name(), s.type() == null ? null : s.type().name(), s.level()))
                .toList(),
            profile.positions().stream()
                .map(p -> new PositionSnapshot(p.title(), p.companyName(), p.description(), p.current()))
                .toList(),
            profile.education().stream()
                .map(e -> new EducationSnapshot(e.degree(), e.school(), e.fieldOfStudy()))
                .toList(),
            profile.certifications().stream()
                .map(c -> new CertificationSnapshot(c.title(), c.issuer()))
                .toList());
    }

    @Override public String eventType() { return "identity.profile.cv-updated.v1"; }
}
