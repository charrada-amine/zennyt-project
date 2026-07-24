package com.zennyt.engagement.application;

import com.zennyt.engagement.domain.model.EngagementActor;
import com.zennyt.engagement.domain.repository.EngagementActorRepository;
import com.zennyt.identity.domain.event.UserAccessStateChangedEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/** Applique une mise à jour de projection Identity dans une transaction isolée. */
@Service
@RequiredArgsConstructor
public class EngagementIdentityAccessStateProjector {
    private final EngagementActorRepository actors;

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void project(UserAccessStateChangedEvent event) {
        EngagementActor current = actors.findById(event.publicUserId()).orElse(null);
        if (current == null) {
            actors.save(new EngagementActor(event.publicUserId(), event.role(), event.active(),
                event.fullName(), event.avatarUrl(), event.occurredAt(), event.eventId()));
            return;
        }
        EngagementActor updated = current.apply(
            event.role(), event.active(), event.fullName(), event.avatarUrl(),
            event.occurredAt(), event.eventId());
        if (updated != current) actors.save(updated);
    }
}
