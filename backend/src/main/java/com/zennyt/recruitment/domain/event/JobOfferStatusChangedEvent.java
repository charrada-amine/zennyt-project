package com.zennyt.recruitment.domain.event;

import com.zennyt.recruitment.domain.vo.JobOfferStatus;
import com.zennyt.shared.domain.event.DomainEvent;

import java.time.Instant;
import java.util.UUID;

/** Émis quand le statut d'une offre change (DRAFT → ACTIVE, etc.). */
public record JobOfferStatusChangedEvent(
    UUID eventId, Instant occurredAt,
    UUID jobOfferId, JobOfferStatus previousStatus, JobOfferStatus newStatus
) implements DomainEvent {

    public static JobOfferStatusChangedEvent of(UUID jobOfferId, JobOfferStatus previous, JobOfferStatus newStatus) {
        return new JobOfferStatusChangedEvent(UUID.randomUUID(), Instant.now(), jobOfferId, previous, newStatus);
    }

    @Override public String eventType() { return "recruitment.joboffer.status_changed"; }
}
