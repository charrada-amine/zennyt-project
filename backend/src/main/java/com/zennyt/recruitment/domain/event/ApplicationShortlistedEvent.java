package com.zennyt.recruitment.domain.event;

import com.zennyt.shared.domain.event.DomainEvent;

import java.time.Instant;
import java.util.UUID;

/** Émis quand le recruteur présélectionne une candidature (le candidat doit répondre). */
public record ApplicationShortlistedEvent(
    UUID eventId, Instant occurredAt,
    UUID applicationId, UUID candidateId, UUID jobOfferId
) implements DomainEvent {

    public static ApplicationShortlistedEvent of(UUID applicationId, UUID candidateId, UUID jobOfferId) {
        return new ApplicationShortlistedEvent(UUID.randomUUID(), Instant.now(), applicationId, candidateId, jobOfferId);
    }

    @Override public String eventType() { return "recruitment.application.shortlisted"; }
}
