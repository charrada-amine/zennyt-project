package com.zennyt.recruitment.domain.event;

import com.zennyt.shared.domain.event.DomainEvent;

import java.time.Instant;
import java.util.UUID;

/** Émis quand un candidat soumet une candidature. */
public record ApplicationSubmittedEvent(
    UUID eventId, Instant occurredAt,
    UUID applicationId, UUID candidateId, UUID jobOfferId
) implements DomainEvent {

    public static ApplicationSubmittedEvent of(UUID applicationId, UUID candidateId, UUID jobOfferId) {
        return new ApplicationSubmittedEvent(UUID.randomUUID(), Instant.now(), applicationId, candidateId, jobOfferId);
    }

    @Override public String eventType() { return "recruitment.application.submitted"; }
}
