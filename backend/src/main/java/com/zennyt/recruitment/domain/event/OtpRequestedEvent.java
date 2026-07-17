package com.zennyt.recruitment.domain.event;

import com.zennyt.recruitment.domain.vo.OtpPurpose;
import com.zennyt.shared.domain.event.DomainEvent;

import java.time.Instant;
import java.util.UUID;

/** Événement éphémère destiné au canal de livraison OTP ; le code n'est jamais persisté en clair. */
public record OtpRequestedEvent(
    UUID eventId,
    Instant occurredAt,
    UUID resourceId,
    UUID recipientUserId,
    OtpPurpose purpose,
    String oneTimeCode,
    Instant expiresAt
) implements DomainEvent {
    public static OtpRequestedEvent of(UUID resourceId, UUID recipientUserId,
                                       OtpPurpose purpose, String oneTimeCode,
                                       Instant expiresAt) {
        return new OtpRequestedEvent(UUID.randomUUID(), Instant.now(), resourceId,
            recipientUserId, purpose, oneTimeCode, expiresAt);
    }

    @Override
    public String eventType() { return "recruitment.otp.requested.v1"; }
}
