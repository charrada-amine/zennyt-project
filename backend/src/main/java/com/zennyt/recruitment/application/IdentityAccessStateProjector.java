package com.zennyt.recruitment.application;

import com.zennyt.identity.domain.event.UserAccessStateChangedEvent;
import com.zennyt.recruitment.application.port.EmbeddingPort;
import com.zennyt.recruitment.domain.model.RecruitmentActor;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/** Applique une mise à jour de projection Identity dans une transaction isolée. */
@Service
public class IdentityAccessStateProjector {
    private final RecruitmentActorRepository actors;
    private final EmbeddingPort embeddings;

    public IdentityAccessStateProjector(RecruitmentActorRepository actors, EmbeddingPort embeddings) {
        this.actors = actors;
        this.embeddings = embeddings;
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void project(UserAccessStateChangedEvent event) {
        var workplaceTypePreference = CandidatePreferenceMapper.toWorkplaceType(event.workplaceTypePreference());
        var contractTypePreference = CandidatePreferenceMapper.toContractType(event.jobTypePreference());
        // Calculé une seule fois ici (à chaque mise à jour de profil), jamais à l'affichage
        // d'une liste d'offres — voir plan "Recommended for you".
        String lookingForEmbedding = EmbeddingCodec.toJson(embeddings.embed(event.lookingFor()));
        var existing = actors.findById(event.publicUserId());
        if (existing.isEmpty()) {
            actors.save(new RecruitmentActor(event.publicUserId(), event.role(), event.active(),
                event.fullName(), event.avatarUrl(), event.city(), event.country(),
                event.companyName(), event.companyInfo(),
                workplaceTypePreference, contractTypePreference, event.targetJobLocation(),
                event.openInternationally(), event.yearsOfExperience(), event.lookingFor(),
                lookingForEmbedding, event.occurredAt(), event.eventId()));
            return;
        }
        RecruitmentActor actor = existing.get();
        if (!actor.lastEventAt().isBefore(event.occurredAt())
                || actor.lastEventId().equals(event.eventId())) return;
        actors.save(actor.apply(event.role(), event.active(), event.fullName(), event.avatarUrl(),
            event.city(), event.country(), event.companyName(), event.companyInfo(),
            workplaceTypePreference, contractTypePreference, event.targetJobLocation(),
            event.openInternationally(), event.yearsOfExperience(), event.lookingFor(),
            lookingForEmbedding, event.occurredAt(), event.eventId()));
    }
}
