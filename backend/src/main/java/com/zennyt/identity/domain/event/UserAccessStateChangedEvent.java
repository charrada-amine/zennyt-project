package com.zennyt.identity.domain.event;

import com.zennyt.shared.domain.event.DomainEvent;

import java.time.Instant;
import java.util.UUID;

/** État d'accès minimal publié aux autres bounded contexts, sans PII. */
public record UserAccessStateChangedEvent(
    UUID eventId,
    Instant occurredAt,
    UUID publicUserId,
    String role,
    boolean active
) implements DomainEvent {

    public static UserAccessStateChangedEvent of(UUID publicUserId, String role, boolean active) {
        return new UserAccessStateChangedEvent(
            UUID.randomUUID(), Instant.now(), publicUserId, role, active);
    }

    @Override
    public String eventType() {
        return "identity.user.access-state-changed.v1";
    }
}
