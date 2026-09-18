package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.model.StorePurchase;
import com.zennyt.engagement.domain.repository.StorePurchaseRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Component
@RequiredArgsConstructor
public class StorePurchaseRepositoryAdapter implements StorePurchaseRepository {
    private final JpaStorePurchaseRepository jpa;

    @Override
    public StorePurchase save(StorePurchase p) {
        StorePurchaseEntity saved = jpa.saveAndFlush(new StorePurchaseEntity(p.id(), p.userId(),
            p.productId(), p.kind(), p.store(), p.transactionId(), p.verified(), p.purchasedAt()));
        return new StorePurchase(saved.getId(), saved.getUserId(), saved.getProductId(),
            saved.getKind(), saved.getStore(), saved.getTransactionId(), saved.isVerified(),
            saved.getPurchasedAt());
    }

    @Override
    public boolean existsByTransactionId(String transactionId) {
        return jpa.existsByTransactionId(transactionId);
    }

    @Override
    public Optional<StorePurchase> findByTransactionId(String transactionId) {
        return jpa.findByTransactionId(transactionId).map(e -> new StorePurchase(e.getId(),
            e.getUserId(), e.getProductId(), e.getKind(), e.getStore(), e.getTransactionId(),
            e.isVerified(), e.getPurchasedAt()));
    }
}
