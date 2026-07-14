package com.zennyt.recruitment.domain.event;

import com.zennyt.shared.domain.event.DomainEvent;

import java.time.Instant;
import java.util.UUID;

/** Émis quand un paiement visioconférence est confirmé via OTP. */
public record VideoConferencePaymentConfirmedEvent(
    UUID eventId, Instant occurredAt,
    UUID paymentId, UUID matchId, UUID recruiterId
) implements DomainEvent {

    public static VideoConferencePaymentConfirmedEvent of(UUID paymentId, UUID matchId, UUID recruiterId) {
        return new VideoConferencePaymentConfirmedEvent(UUID.randomUUID(), Instant.now(), paymentId, matchId, recruiterId);
    }

    @Override public String eventType() { return "recruitment.payment.confirmed"; }
}
