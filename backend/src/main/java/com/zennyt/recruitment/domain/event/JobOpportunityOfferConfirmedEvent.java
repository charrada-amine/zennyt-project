package com.zennyt.recruitment.domain.event;

import com.zennyt.shared.domain.event.DomainEvent;

import java.time.Instant;
import java.util.UUID;

/** Émis quand un candidat confirme une offre d'opportunité via OTP. */
public record JobOpportunityOfferConfirmedEvent(
    UUID eventId, Instant occurredAt,
    UUID offerId, UUID candidateId, UUID jobOfferId
) implements DomainEvent {

    public static JobOpportunityOfferConfirmedEvent of(UUID offerId, UUID candidateId, UUID jobOfferId) {
        return new JobOpportunityOfferConfirmedEvent(UUID.randomUUID(), Instant.now(), offerId, candidateId, jobOfferId);
    }

    @Override public String eventType() { return "recruitment.opportunity_offer.confirmed"; }
}
