package com.zennyt.identity.domain.model;

import java.time.Instant;

/**
 * Code OTP de réinitialisation de mot de passe. Le code en clair n'est jamais
 * conservé : seul son empreinte ({@code codeHash}) est stockée.
 */
public record PasswordResetCode(
    Long id,
    Long userId,
    String codeHash,
    Instant expiresAt,
    Instant consumedAt,
    int attempts,
    Instant createdAt
) {
    public static PasswordResetCode issue(Long userId, String codeHash, Instant expiresAt) {
        return new PasswordResetCode(null, userId, codeHash, expiresAt, null, 0, Instant.now());
    }

    public boolean usableAt(Instant instant) {
        return consumedAt == null && expiresAt.isAfter(instant);
    }

    public PasswordResetCode withIncrementedAttempts() {
        return new PasswordResetCode(id, userId, codeHash, expiresAt, consumedAt, attempts + 1,
            createdAt);
    }

    public PasswordResetCode consume() {
        return new PasswordResetCode(id, userId, codeHash, expiresAt, Instant.now(), attempts,
            createdAt);
    }
}
