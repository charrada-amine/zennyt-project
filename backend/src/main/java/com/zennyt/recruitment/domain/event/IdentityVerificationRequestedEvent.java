package com.zennyt.recruitment.domain.event;

import com.zennyt.shared.domain.event.DomainEvent;

import java.time.Instant;
import java.util.UUID;

/** Émis quand un recruteur demande une vérification d'identité pour un candidat. */
public record IdentityVerificationRequestedEvent(
    UUID eventId, Instant occurredAt,
    UUID verificationId, UUID recruiterId, UUID candidateId
) implements DomainEvent {

    public static IdentityVerificationRequestedEvent of(UUID verificationId, UUID recruiterId, UUID candidateId) {
        return new IdentityVerificationRequestedEvent(UUID.randomUUID(), Instant.now(), verificationId, recruiterId, candidateId);
    }

    @Override public String eventType() { return "recruitment.identity_verification.requested"; }
}
