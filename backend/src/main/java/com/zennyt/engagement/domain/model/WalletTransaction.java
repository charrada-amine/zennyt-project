package com.zennyt.engagement.domain.model;

import com.zennyt.engagement.domain.vo.WalletTransactionKind;

import java.time.Instant;
import java.util.UUID;

/**
 * Écriture du portefeuille. {@code amountCents} est signé : positif pour un
 * crédit, négatif pour un débit/retrait.
 */
public record WalletTransaction(UUID id, UUID userId, long amountCents, String currency,
                                WalletTransactionKind kind, String label, Instant createdAt) {

    public static WalletTransaction of(UUID userId, long signedAmountCents, String currency,
                                       WalletTransactionKind kind, String label) {
        return new WalletTransaction(UUID.randomUUID(), userId, signedAmountCents, currency, kind,
            label, Instant.now());
    }
}
