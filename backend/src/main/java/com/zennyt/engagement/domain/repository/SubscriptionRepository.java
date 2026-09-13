package com.zennyt.engagement.domain.repository;

import com.zennyt.engagement.domain.model.Subscription;

import java.util.Optional;
import java.util.UUID;

public interface SubscriptionRepository {
    Optional<Subscription> findByUserId(UUID userId);

    Subscription save(Subscription subscription);
}
