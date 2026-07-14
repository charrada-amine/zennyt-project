package com.zennyt.recruitment.domain.event;

import com.zennyt.shared.domain.event.DomainEvent;

import java.time.Instant;
import java.util.UUID;

/** Émis quand un recruteur envoie une offre d'opportunité à un candidat. */
public record JobOpportunityOfferSentEvent(
    UUID eventId, Instant occurredAt,
    UUID offerId, UUID recruiterId, UUID candidateId, UUID jobOfferId
) implements DomainEvent {

    public static JobOpportunityOfferSentEvent of(UUID offerId, UUID recruiterId, UUID candidateId, UUID jobOfferId) {
        return new JobOpportunityOfferSentEvent(UUID.randomUUID(), Instant.now(), offerId, recruiterId, candidateId, jobOfferId);
    }

    @Override public String eventType() { return "recruitment.opportunity_offer.sent"; }
}
