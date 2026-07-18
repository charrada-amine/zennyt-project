package com.zennyt.engagement.application;

import com.zennyt.engagement.domain.model.EngagementActor;
import com.zennyt.engagement.domain.repository.EngagementActorRepository;
import com.zennyt.identity.domain.event.UserAccessStateChangedEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/** Maintient une projection locale de sécurité sans appel direct au module Identity. */
@Component
@RequiredArgsConstructor
public class EngagementIdentityAccessStateListener {
    private final EngagementActorRepository actors;

    @EventListener
    @Transactional
    public void on(UserAccessStateChangedEvent event) {
        EngagementActor current = actors.findById(event.publicUserId()).orElse(null);
        if (current == null) {
            actors.save(new EngagementActor(event.publicUserId(), event.role(), event.active(),
                event.displayName(), event.photoUrl(), event.occurredAt(), event.eventId()));
            return;
        }
        EngagementActor updated = current.apply(
            event.role(), event.active(), event.displayName(), event.photoUrl(),
            event.occurredAt(), event.eventId());
        if (updated != current) actors.save(updated);
    }
}
