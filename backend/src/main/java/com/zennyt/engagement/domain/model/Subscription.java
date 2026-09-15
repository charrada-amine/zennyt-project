package com.zennyt.engagement.domain.model;

import com.zennyt.engagement.domain.vo.StorePlatform;
import com.zennyt.engagement.domain.vo.SubscriptionStatus;

import java.time.Instant;
import java.util.UUID;

/**
 * Abonnement d'un utilisateur à une offre (une ligne par utilisateur). L'état
 * réel fait foi côté Apple/Google ; on conserve ici le dernier achat vérifié.
 */
public record Subscription(UUID userId, String planCode, SubscriptionStatus status,
                           StorePlatform store, String originalTransactionId, Instant purchasedAt,
                           Instant expiresAt, boolean autoRenewing, Instant updatedAt) {

    public static Subscription activate(UUID userId, String planCode, StorePlatform store,
                                        String originalTransactionId, Instant purchasedAt,
                                        Instant expiresAt, boolean autoRenewing) {
        return new Subscription(userId, planCode, SubscriptionStatus.ACTIVE, store,
            originalTransactionId, purchasedAt, expiresAt, autoRenewing, Instant.now());
    }
}
