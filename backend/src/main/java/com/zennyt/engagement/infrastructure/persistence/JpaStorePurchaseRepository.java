package com.zennyt.engagement.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

interface JpaStorePurchaseRepository extends JpaRepository<StorePurchaseEntity, UUID> {

    boolean existsByTransactionId(String transactionId);
}
