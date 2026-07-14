package com.zennyt.recruitment.domain.event;

import com.zennyt.shared.domain.event.DomainEvent;

import java.time.Instant;
import java.util.UUID;

/** Émis quand un recruteur crée une nouvelle offre d'emploi. */
public record JobOfferCreatedEvent(
    UUID eventId, Instant occurredAt,
    UUID jobOfferId, UUID recruiterId
) implements DomainEvent {

    public static JobOfferCreatedEvent of(UUID jobOfferId, UUID recruiterId) {
        return new JobOfferCreatedEvent(UUID.randomUUID(), Instant.now(), jobOfferId, recruiterId);
    }

    @Override public String eventType() { return "recruitment.joboffer.created"; }
}
