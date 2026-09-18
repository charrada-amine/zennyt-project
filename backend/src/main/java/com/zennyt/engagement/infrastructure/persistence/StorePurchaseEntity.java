package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.vo.PurchaseKind;
import com.zennyt.engagement.domain.vo.StorePlatform;
import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "store_purchases", schema = "engagement")
class StorePurchaseEntity {
    @Id private UUID id;
    @Column(name = "user_id", nullable = false) private UUID userId;
    @Column(name = "product_id", nullable = false, length = 60) private String productId;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 20) private PurchaseKind kind;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 10) private StorePlatform store;
    @Column(name = "transaction_id", nullable = false, unique = true, length = 200) private String transactionId;
    @Column(nullable = false) private boolean verified;
    @Column(name = "purchased_at", nullable = false) private Instant purchasedAt;

    protected StorePurchaseEntity() {}

    StorePurchaseEntity(UUID id, UUID userId, String productId, PurchaseKind kind,
                        StorePlatform store, String transactionId, boolean verified,
                        Instant purchasedAt) {
        this.id = id;
        this.userId = userId;
        this.productId = productId;
        this.kind = kind;
        this.store = store;
        this.transactionId = transactionId;
        this.verified = verified;
        this.purchasedAt = purchasedAt;
    }

    UUID getId() { return id; }
    UUID getUserId() { return userId; }
    String getProductId() { return productId; }
    PurchaseKind getKind() { return kind; }
    StorePlatform getStore() { return store; }
    String getTransactionId() { return transactionId; }
    boolean isVerified() { return verified; }
    Instant getPurchasedAt() { return purchasedAt; }
}
