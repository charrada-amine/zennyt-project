package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.model.Subscription;
import com.zennyt.engagement.domain.repository.SubscriptionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class SubscriptionRepositoryAdapter implements SubscriptionRepository {
    private final JpaSubscriptionRepository jpa;

    @Override
    public Optional<Subscription> findByUserId(UUID userId) {
        return jpa.findById(userId).map(e -> new Subscription(e.getUserId(), e.getPlanCode(),
            e.getStatus(), e.getStore(), e.getOriginalTransactionId(), e.getPurchasedAt(),
            e.getExpiresAt(), e.isAutoRenewing(), e.getUpdatedAt()));
    }

    @Override
    public Subscription save(Subscription s) {
        SubscriptionEntity saved = jpa.save(new SubscriptionEntity(s.userId(), s.planCode(),
            s.status(), s.store(), s.originalTransactionId(), s.purchasedAt(), s.expiresAt(),
            s.autoRenewing(), s.updatedAt()));
        return new Subscription(saved.getUserId(), saved.getPlanCode(), saved.getStatus(),
            saved.getStore(), saved.getOriginalTransactionId(), saved.getPurchasedAt(),
            saved.getExpiresAt(), saved.isAutoRenewing(), saved.getUpdatedAt());
    }
}
