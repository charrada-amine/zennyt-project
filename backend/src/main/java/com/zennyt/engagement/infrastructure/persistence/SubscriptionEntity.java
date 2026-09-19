package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.vo.StorePlatform;
import com.zennyt.engagement.domain.vo.SubscriptionStatus;
import jakarta.persistence.*;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.ColumnDefault;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "subscriptions", schema = "engagement")
@Check(name = "ck_subscriptions_status", constraints = "status IN ('ACTIVE', 'EXPIRED', 'CANCELLED')")
@Check(name = "ck_subscriptions_store", constraints = "store IN ('APPLE', 'GOOGLE')")
class SubscriptionEntity {
    @Id @Column(name = "user_id") private UUID userId;
    @Column(name = "plan_code", nullable = false, length = 60) private String planCode;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 20) private SubscriptionStatus status;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 10) private StorePlatform store;
    @Column(name = "original_transaction_id", length = 200) private String originalTransactionId;
    @Column(name = "purchased_at") private Instant purchasedAt;
    @Column(name = "expires_at") private Instant expiresAt;
    @ColumnDefault("false") @Column(name = "auto_renewing", nullable = false) private boolean autoRenewing;
    @Column(name = "updated_at", nullable = false) private Instant updatedAt;

    protected SubscriptionEntity() {}

    SubscriptionEntity(UUID userId, String planCode, SubscriptionStatus status, StorePlatform store,
                       String originalTransactionId, Instant purchasedAt, Instant expiresAt,
                       boolean autoRenewing, Instant updatedAt) {
        this.userId = userId;
        this.planCode = planCode;
        this.status = status;
        this.store = store;
        this.originalTransactionId = originalTransactionId;
        this.purchasedAt = purchasedAt;
        this.expiresAt = expiresAt;
        this.autoRenewing = autoRenewing;
        this.updatedAt = updatedAt;
    }

    UUID getUserId() { return userId; }
    String getPlanCode() { return planCode; }
    SubscriptionStatus getStatus() { return status; }
    StorePlatform getStore() { return store; }
    String getOriginalTransactionId() { return originalTransactionId; }
    Instant getPurchasedAt() { return purchasedAt; }
    Instant getExpiresAt() { return expiresAt; }
    boolean isAutoRenewing() { return autoRenewing; }
    Instant getUpdatedAt() { return updatedAt; }
}
