package com.zennyt.engagement.domain.repository;

import com.zennyt.engagement.domain.model.StorePurchase;

import java.util.Optional;

public interface StorePurchaseRepository {
    StorePurchase save(StorePurchase purchase);

    boolean existsByTransactionId(String transactionId);

    /** Achat déjà enregistré pour cet identifiant de transaction, quel que soit l'acheteur. */
    Optional<StorePurchase> findByTransactionId(String transactionId);
}
