package com.zennyt.engagement.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

interface JpaSubscriptionRepository extends JpaRepository<SubscriptionEntity, UUID> {
}
