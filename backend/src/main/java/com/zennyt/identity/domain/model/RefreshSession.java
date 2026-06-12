package com.zennyt.identity.domain.model;

import java.time.Instant;
import java.util.UUID;

public record RefreshSession(UUID id, Long userId, String tokenHash, Instant expiresAt,
                             Instant createdAt, Instant revokedAt) {
    public static RefreshSession create(Long userId, String tokenHash, Instant expiresAt) {
        return new RefreshSession(UUID.randomUUID(), userId, tokenHash, expiresAt, Instant.now(), null);
    }

    public boolean usableAt(Instant instant) {
        return revokedAt == null && expiresAt.isAfter(instant);
    }

    public RefreshSession revoke() {
        return new RefreshSession(id, userId, tokenHash, expiresAt, createdAt, Instant.now());
    }
}
