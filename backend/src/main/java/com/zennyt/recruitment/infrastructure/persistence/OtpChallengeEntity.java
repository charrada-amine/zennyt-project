package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.OtpPurpose;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "otp_challenges", schema = "recruitment")
public class OtpChallengeEntity {
    @Id private UUID id;
    @Column(name = "resource_id", nullable = false) private UUID resourceId;
    @Column(name = "recipient_user_id", nullable = false) private UUID recipientUserId;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30) private OtpPurpose purpose;
    @Column(nullable = false, length = 64) private String salt;
    @Column(name = "code_hash", nullable = false, length = 64) private String codeHash;
    @Column(name = "expires_at", nullable = false) private Instant expiresAt;
    @Column(name = "attempts_remaining", nullable = false) private int attemptsRemaining;
    @Column(name = "consumed_at") private Instant consumedAt;
    @Column(name = "created_at", nullable = false) private Instant createdAt;

    protected OtpChallengeEntity() {}

    public OtpChallengeEntity(UUID id, UUID resourceId, UUID recipientUserId, OtpPurpose purpose,
                              String salt, String codeHash, Instant expiresAt,
                              int attemptsRemaining, Instant consumedAt, Instant createdAt) {
        this.id = id; this.resourceId = resourceId; this.recipientUserId = recipientUserId;
        this.purpose = purpose; this.salt = salt; this.codeHash = codeHash;
        this.expiresAt = expiresAt; this.attemptsRemaining = attemptsRemaining;
        this.consumedAt = consumedAt; this.createdAt = createdAt;
    }

    public UUID getId() { return id; }
    public UUID getResourceId() { return resourceId; }
    public UUID getRecipientUserId() { return recipientUserId; }
    public OtpPurpose getPurpose() { return purpose; }
    public String getSalt() { return salt; }
    public String getCodeHash() { return codeHash; }
    public Instant getExpiresAt() { return expiresAt; }
    public int getAttemptsRemaining() { return attemptsRemaining; }
    public Instant getConsumedAt() { return consumedAt; }
    public Instant getCreatedAt() { return createdAt; }
}
