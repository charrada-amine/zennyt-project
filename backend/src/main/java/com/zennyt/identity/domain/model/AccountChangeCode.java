package com.zennyt.identity.domain.model;

import java.time.Instant;

/**
 * Code OTP confirmant un changement de coordonnée (e-mail ou téléphone). Le code
 * en clair n'est jamais conservé : seul son empreinte SHA-256 ({@code codeHash})
 * l'est. La valeur cible ({@code target}) est mémorisée pour appliquer le
 * changement une fois le code validé.
 */
public record AccountChangeCode(
    Long id,
    Long userId,
    AccountChangeType type,
    String target,
    String codeHash,
    Instant expiresAt,
    Instant consumedAt,
    int attempts,
    Instant createdAt
) {
    public static AccountChangeCode issue(Long userId, AccountChangeType type, String target,
                                          String codeHash, Instant expiresAt) {
        return new AccountChangeCode(null, userId, type, target, codeHash, expiresAt, null, 0,
            Instant.now());
    }

    public boolean usableAt(Instant instant) {
        return consumedAt == null && expiresAt.isAfter(instant);
    }

    public AccountChangeCode withIncrementedAttempts() {
        return new AccountChangeCode(id, userId, type, target, codeHash, expiresAt, consumedAt,
            attempts + 1, createdAt);
    }

    public AccountChangeCode consume() {
        return new AccountChangeCode(id, userId, type, target, codeHash, expiresAt, Instant.now(),
            attempts, createdAt);
    }
}
