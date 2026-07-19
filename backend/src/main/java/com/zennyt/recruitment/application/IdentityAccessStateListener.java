package com.zennyt.recruitment.application;

import com.zennyt.identity.domain.event.UserAccessStateChangedEvent;
import com.zennyt.recruitment.domain.model.RecruitmentActor;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/** Maintient la projection locale de sécurité sans appel direct au module Identity. */
@Component
@RequiredArgsConstructor
public class IdentityAccessStateListener {
    private final RecruitmentActorRepository actors;

    @EventListener
    @Transactional
    public void on(UserAccessStateChangedEvent event) {
        var existing = actors.findById(event.publicUserId());
        if (existing.isEmpty()) {
            actors.save(new RecruitmentActor(event.publicUserId(), event.role(), event.active(),
                event.fullName(), event.avatarUrl(), event.city(), event.country(),
                event.occurredAt(), event.eventId()));
            return;
        }
        RecruitmentActor actor = existing.get();
        if (!actor.lastEventAt().isBefore(event.occurredAt())
                || actor.lastEventId().equals(event.eventId())) return;
        actors.save(actor.apply(event.role(), event.active(), event.fullName(), event.avatarUrl(),
            event.city(), event.country(), event.occurredAt(), event.eventId()));
    }
}
