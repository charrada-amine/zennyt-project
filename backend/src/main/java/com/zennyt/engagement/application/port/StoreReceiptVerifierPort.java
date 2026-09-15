package com.zennyt.engagement.application.port;

import com.zennyt.engagement.domain.vo.StorePlatform;

import java.time.Instant;

/**
 * Port de vérification d'un achat StoreKit / Google Play.
 *
 * <p>L'implémentation réelle doit interroger les API serveur Apple/Google
 * (App Store Server API, Google Play Developer API) avec des identifiants
 * secrets. Tant que ceux-ci ne sont pas fournis, un stub accepte l'achat
 * (voir {@code StubStoreReceiptVerifier}, marqué provisoire).
 */
public interface StoreReceiptVerifierPort {

    record VerifiedPurchase(boolean valid, String originalTransactionId, Instant purchasedAt,
                            boolean autoRenewing) {}

    VerifiedPurchase verify(StorePlatform store, String productId, String receipt,
                            String transactionId);
}
