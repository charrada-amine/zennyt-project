package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.Subscription;
import com.zennyt.engagement.domain.repository.SubscriptionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;
import java.util.UUID;

/** Cas d'usage : abonnement courant de l'utilisateur (éventuellement absent). */
@Service
@RequiredArgsConstructor
public class GetSubscriptionUseCase {

    private final SubscriptionRepository subscriptions;

    @Transactional(readOnly = true)
    public Optional<Subscription> execute(UUID userId) {
        return subscriptions.findByUserId(userId);
    }
}
