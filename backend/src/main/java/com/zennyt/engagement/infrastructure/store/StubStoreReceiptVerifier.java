package com.zennyt.engagement.infrastructure.store;

import com.zennyt.engagement.application.port.StoreReceiptVerifierPort;
import com.zennyt.engagement.domain.vo.StorePlatform;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.time.Instant;

/**
 * Vérificateur **provisoire** : accepte tout achat non vide sans interroger
 * Apple/Google. À remplacer par une validation serveur réelle (App Store Server
 * API + Google Play Developer API avec identifiants secrets) avant mise en
 * production — voir `docs/SCREENS_1TO1_PLAN.md` et `ENGAGEMENT_MODULE.md`.
 *
 * <p>N'existe que si la propriété `zennyt.billing.receipt-verifier=stub` est
 * explicitement définie (dev/tests uniquement). Sans cette propriété — donc en
 * prod — aucun bean {@link StoreReceiptVerifierPort} n'est disponible et le
 * démarrage échoue : `VerifyPurchaseUseCase` l'exige par injection
 * constructeur. C'est le garde-fou anti « abonnements gratuits en prod ».
 */
@Component
@ConditionalOnProperty(name = "zennyt.billing.receipt-verifier", havingValue = "stub")
public class StubStoreReceiptVerifier implements StoreReceiptVerifierPort {
    private static final Logger log = LoggerFactory.getLogger(StubStoreReceiptVerifier.class);

    @Override
    public VerifiedPurchase verify(StorePlatform store, String productId, String receipt,
                                   String transactionId) {
        boolean present = receipt != null && !receipt.isBlank()
            && transactionId != null && !transactionId.isBlank();
        if (!present) {
            return new VerifiedPurchase(false, null, null, false);
        }
        log.warn("PROVISOIRE — achat non vérifié auprès de {} (productId={}, transactionId={})",
            store, productId, transactionId);
        return new VerifiedPurchase(true, transactionId, Instant.now(), true);
    }
}
