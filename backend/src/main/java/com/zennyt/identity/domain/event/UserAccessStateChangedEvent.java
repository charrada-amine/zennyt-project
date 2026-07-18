package com.zennyt.identity.domain.event;

import com.zennyt.shared.domain.event.DomainEvent;

import java.time.Instant;
import java.util.UUID;

/** État d'accès et présentation publique publié aux autres bounded contexts. */
public record UserAccessStateChangedEvent(
    UUID eventId,
    Instant occurredAt,
    UUID publicUserId,
    String role,
    boolean active,
    String displayName,
    String photoUrl
) implements DomainEvent {

    public static UserAccessStateChangedEvent of(UUID publicUserId, String role, boolean active,
                                                 String displayName, String photoUrl) {
        return new UserAccessStateChangedEvent(
            UUID.randomUUID(), Instant.now(), publicUserId, role, active, displayName, photoUrl);
    }

    @Override
    public String eventType() {
        return "identity.user.access-state-changed.v1";
    }
}
