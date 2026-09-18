package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.application.PlanCatalog;
import com.zennyt.engagement.application.port.StoreReceiptVerifierPort;
import com.zennyt.engagement.domain.model.Plan;
import com.zennyt.engagement.domain.model.StorePurchase;
import com.zennyt.engagement.domain.model.Subscription;
import com.zennyt.engagement.domain.repository.StorePurchaseRepository;
import com.zennyt.engagement.domain.repository.SubscriptionRepository;
import com.zennyt.engagement.domain.vo.PlanPeriod;
import com.zennyt.engagement.domain.vo.PurchaseKind;
import com.zennyt.engagement.domain.vo.StorePlatform;
import com.zennyt.shared.application.exception.ConflictException;
import com.zennyt.shared.application.exception.NotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Optional;
import java.util.UUID;

/**
 * Cas d'usage : enregistrer un achat après vérification auprès du store.
 *
 * <p>Idempotent par identifiant de transaction : un rejeu par le **même**
 * utilisateur ne crée pas de doublon. Un identifiant de transaction déjà
 * enregistré pour un **autre** utilisateur est un rejeu inter-comptes → 409.
 * Un abonnement met à jour `subscriptions` (échéance +30 jours) ; un achat unique
 * (consommable) n'enregistre qu'un achat.
 */
@Service
@RequiredArgsConstructor
public class VerifyPurchaseUseCase {

    /** Durée d'un cycle mensuel, en attendant l'échéance réelle renvoyée par le store. */
    private static final long SUBSCRIPTION_PERIOD_DAYS = 30;

    public record Result(Subscription subscription, StorePurchase purchase) {}

    private final SubscriptionRepository subscriptions;
    private final StorePurchaseRepository purchases;
    private final StoreReceiptVerifierPort verifier;

    @Transactional
    public Result execute(UUID userId, String productId, StorePlatform store, String receipt,
                           String transactionId) {
        Plan plan = PlanCatalog.byCode(productId)
            .orElseThrow(() -> new NotFoundException("Produit inconnu : " + productId));

        if (transactionId != null) {
            Optional<StorePurchase> existing = purchases.findByTransactionId(transactionId);
            if (existing.isPresent()) {
                if (!existing.get().userId().equals(userId)) {
                    // Rejeu croisé : la transaction appartient à un autre compte.
                    throw new ConflictException(
                        "Cette transaction appartient déjà à un autre utilisateur");
                }
                return new Result(subscriptions.findByUserId(userId).orElse(null), null);
            }
        }

        var verified = verifier.verify(store, productId, receipt, transactionId);
        if (!verified.valid()) {
            throw new IllegalArgumentException("Achat non vérifié");
        }

        PurchaseKind kind = plan.period() == PlanPeriod.MONTHLY
            ? PurchaseKind.SUBSCRIPTION : PurchaseKind.CONSUMABLE;
        StorePurchase purchase;
        try {
            purchase = purchases.save(StorePurchase.verified(userId, productId, kind,
                store, transactionId, verified.purchasedAt()));
        } catch (DataIntegrityViolationException race) {
            // Deux appels concurrents sur le même transactionId : l'unique
            // contrainte (`transaction_id`) a gagné la course → 409 déterministe
            // plutôt qu'un 500 brut.
            throw new ConflictException(
                "Cette transaction est déjà enregistrée par un autre utilisateur");
        }

        Subscription subscription;
        if (kind == PurchaseKind.SUBSCRIPTION) {
            Instant expiresAt = verified.purchasedAt().plus(SUBSCRIPTION_PERIOD_DAYS, ChronoUnit.DAYS);
            subscription = subscriptions.save(Subscription.activate(userId, plan.code(), store,
                verified.originalTransactionId(), verified.purchasedAt(), expiresAt,
                verified.autoRenewing()));
        } else {
            subscription = subscriptions.findByUserId(userId).orElse(null);
        }
        return new Result(subscription, purchase);
    }
}
