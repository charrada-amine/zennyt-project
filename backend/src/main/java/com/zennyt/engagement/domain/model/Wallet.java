package com.zennyt.engagement.domain.model;

import java.time.Instant;
import java.util.UUID;

/**
 * Portefeuille d'un utilisateur. Le solde est stocké en **centimes** (entier)
 * pour éviter les erreurs de virgule flottante ; il ne peut pas devenir négatif.
 */
public record Wallet(UUID userId, long balanceCents, String currency, Instant updatedAt) {

    public static final String DEFAULT_CURRENCY = "EUR";

    public static Wallet empty(UUID userId) {
        return new Wallet(userId, 0L, DEFAULT_CURRENCY, Instant.now());
    }

    public Wallet credit(long amountCents, Instant at) {
        if (amountCents <= 0) {
            throw new IllegalArgumentException("Le montant crédité doit être positif");
        }
        return new Wallet(userId, balanceCents + amountCents, currency, at);
    }

    public Wallet debit(long amountCents, Instant at) {
        if (amountCents <= 0) {
            throw new IllegalArgumentException("Le montant débité doit être positif");
        }
        if (amountCents > balanceCents) {
            throw new IllegalArgumentException("Solde insuffisant");
        }
        return new Wallet(userId, balanceCents - amountCents, currency, at);
    }
}
