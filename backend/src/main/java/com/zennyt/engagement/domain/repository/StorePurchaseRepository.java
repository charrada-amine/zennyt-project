package com.zennyt.engagement.domain.repository;

import com.zennyt.engagement.domain.model.StorePurchase;

public interface StorePurchaseRepository {
    StorePurchase save(StorePurchase purchase);

    boolean existsByTransactionId(String transactionId);
}
