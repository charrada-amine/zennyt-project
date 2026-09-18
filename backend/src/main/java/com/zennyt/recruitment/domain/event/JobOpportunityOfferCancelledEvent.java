package com.zennyt.recruitment.domain.event;

import com.zennyt.shared.domain.event.DomainEvent;

import java.time.Instant;
import java.util.UUID;

public record JobOpportunityOfferCancelledEvent(
    UUID eventId, Instant occurredAt,
    UUID offerId, UUID recruiterId, UUID candidateId, UUID jobOfferId
) implements DomainEvent {

    public static JobOpportunityOfferCancelledEvent of(UUID offerId, UUID recruiterId,
                                                       UUID candidateId, UUID jobOfferId) {
        return new JobOpportunityOfferCancelledEvent(UUID.randomUUID(), Instant.now(),
            offerId, recruiterId, candidateId, jobOfferId);
    }

    @Override public String eventType() { return "recruitment.opportunity_offer.cancelled"; }
}
