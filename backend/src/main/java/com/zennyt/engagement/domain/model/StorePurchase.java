package com.zennyt.engagement.domain.model;

import com.zennyt.engagement.domain.vo.PurchaseKind;
import com.zennyt.engagement.domain.vo.StorePlatform;

import java.time.Instant;
import java.util.UUID;

/**
 * Achat vérifié auprès d'un store. On ne conserve **jamais** le reçu brut
 * (receipt/token) — seulement l'identifiant de transaction et le produit, comme
 * pour les cartes du portefeuille.
 */
public record StorePurchase(UUID id, UUID userId, String productId, PurchaseKind kind,
                            StorePlatform store, String transactionId, boolean verified,
                            Instant purchasedAt) {

    public static StorePurchase verified(UUID userId, String productId, PurchaseKind kind,
                                         StorePlatform store, String transactionId,
                                         Instant purchasedAt) {
        return new StorePurchase(UUID.randomUUID(), userId, productId, kind, store, transactionId,
            true, purchasedAt);
    }
}
