package com.zennyt.identity.infrastructure.persistence;

import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "refresh_sessions")
public class RefreshSessionEntity {
    @Id
    private UUID id;
    @Column(name = "user_id", nullable = false)
    private Long userId;
    @Column(name = "token_hash", nullable = false, unique = true, length = 64)
    private String tokenHash;
    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
    @Column(name = "revoked_at")
    private Instant revokedAt;

    protected RefreshSessionEntity() {}
    RefreshSessionEntity(UUID id, Long userId, String tokenHash, Instant expiresAt,
                         Instant createdAt, Instant revokedAt) {
        this.id = id; this.userId = userId; this.tokenHash = tokenHash; this.expiresAt = expiresAt;
        this.createdAt = createdAt; this.revokedAt = revokedAt;
    }
    public UUID getId() { return id; }
    public Long getUserId() { return userId; }
    public String getTokenHash() { return tokenHash; }
    public Instant getExpiresAt() { return expiresAt; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getRevokedAt() { return revokedAt; }
}
