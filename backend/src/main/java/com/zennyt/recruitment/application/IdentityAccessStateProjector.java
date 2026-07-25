package com.zennyt.recruitment.application;

import com.zennyt.identity.domain.event.UserAccessStateChangedEvent;
import com.zennyt.recruitment.domain.model.RecruitmentActor;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/** Applique une mise à jour de projection Identity dans une transaction isolée. */
@Service
@RequiredArgsConstructor
public class IdentityAccessStateProjector {
    private final RecruitmentActorRepository actors;

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void project(UserAccessStateChangedEvent event) {
        var existing = actors.findById(event.publicUserId());
        if (existing.isEmpty()) {
            actors.save(new RecruitmentActor(event.publicUserId(), event.role(), event.active(),
                event.fullName(), event.avatarUrl(), event.city(), event.country(),
                event.companyName(), event.companyInfo(),
                event.occurredAt(), event.eventId()));
            return;
        }
        RecruitmentActor actor = existing.get();
        if (!actor.lastEventAt().isBefore(event.occurredAt())
                || actor.lastEventId().equals(event.eventId())) return;
        actors.save(actor.apply(event.role(), event.active(), event.fullName(), event.avatarUrl(),
            event.city(), event.country(), event.companyName(), event.companyInfo(),
            event.occurredAt(), event.eventId()));
    }
}
