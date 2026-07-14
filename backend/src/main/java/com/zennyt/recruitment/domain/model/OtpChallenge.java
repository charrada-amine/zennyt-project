package com.zennyt.recruitment.domain.model;

import com.zennyt.recruitment.domain.vo.OtpPurpose;

import java.security.MessageDigest;
import java.time.Instant;
import java.util.UUID;

/** Challenge OTP hashé, expirant, limité en essais et à usage unique. */
public class OtpChallenge {
    private final UUID id;
    private final UUID resourceId;
    private final UUID recipientUserId;
    private final OtpPurpose purpose;
    private final String salt;
    private final String codeHash;
    private final Instant expiresAt;
    private int attemptsRemaining;
    private Instant consumedAt;
    private final Instant createdAt;

    private OtpChallenge(UUID id, UUID resourceId, UUID recipientUserId, OtpPurpose purpose,
                         String salt, String codeHash, Instant expiresAt, int attemptsRemaining,
                         Instant consumedAt, Instant createdAt) {
        this.id = id;
        this.resourceId = resourceId;
        this.recipientUserId = recipientUserId;
        this.purpose = purpose;
        this.salt = salt;
        this.codeHash = codeHash;
        this.expiresAt = expiresAt;
        this.attemptsRemaining = attemptsRemaining;
        this.consumedAt = consumedAt;
        this.createdAt = createdAt;
    }

    public static OtpChallenge issue(UUID resourceId, UUID recipientUserId, OtpPurpose purpose,
                                     String salt, String codeHash, Instant expiresAt,
                                     int maxAttempts) {
        if (maxAttempts < 1) throw new IllegalArgumentException("maxAttempts doit être positif");
        return new OtpChallenge(UUID.randomUUID(), resourceId, recipientUserId, purpose,
            salt, codeHash, expiresAt, maxAttempts, null, Instant.now());
    }

    public static OtpChallenge rehydrate(UUID id, UUID resourceId, UUID recipientUserId,
                                         OtpPurpose purpose, String salt, String codeHash,
                                         Instant expiresAt, int attemptsRemaining,
                                         Instant consumedAt, Instant createdAt) {
        return new OtpChallenge(id, resourceId, recipientUserId, purpose, salt, codeHash,
            expiresAt, attemptsRemaining, consumedAt, createdAt);
    }

    public boolean verify(String candidateHash, Instant now) {
        if (consumedAt != null) throw new IllegalStateException("Ce code OTP a déjà été utilisé");
        if (!expiresAt.isAfter(now)) throw new IllegalStateException("Ce code OTP a expiré");
        if (attemptsRemaining <= 0) throw new IllegalStateException("Ce code OTP est bloqué");
        boolean matches = MessageDigest.isEqual(
            codeHash.getBytes(java.nio.charset.StandardCharsets.UTF_8),
            candidateHash.getBytes(java.nio.charset.StandardCharsets.UTF_8));
        if (!matches) {
            attemptsRemaining--;
            return false;
        }
        consumedAt = now;
        return true;
    }

    public boolean usableAt(Instant now) {
        return consumedAt == null && attemptsRemaining > 0 && expiresAt.isAfter(now);
    }

    public UUID id() { return id; }
    public UUID resourceId() { return resourceId; }
    public UUID recipientUserId() { return recipientUserId; }
    public OtpPurpose purpose() { return purpose; }
    public String salt() { return salt; }
    public String codeHash() { return codeHash; }
    public Instant expiresAt() { return expiresAt; }
    public int attemptsRemaining() { return attemptsRemaining; }
    public Instant consumedAt() { return consumedAt; }
    public Instant createdAt() { return createdAt; }
}
