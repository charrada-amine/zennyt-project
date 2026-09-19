package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.vo.PurchaseKind;
import com.zennyt.engagement.domain.vo.StorePlatform;
import jakarta.persistence.*;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.ColumnDefault;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "store_purchases", schema = "engagement",
    uniqueConstraints = @UniqueConstraint(name = "store_purchases_transaction_id_key", columnNames = {"transaction_id"}),
    indexes = @Index(name = "idx_store_purchases_user", columnList = "user_id"))
@Check(name = "ck_store_purchases_kind", constraints = "kind IN ('SUBSCRIPTION', 'CONSUMABLE')")
@Check(name = "ck_store_purchases_store", constraints = "store IN ('APPLE', 'GOOGLE')")
class StorePurchaseEntity {
    @Id private UUID id;
    @Column(name = "user_id", nullable = false) private UUID userId;
    @Column(name = "product_id", nullable = false, length = 60) private String productId;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 20) private PurchaseKind kind;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 10) private StorePlatform store;
    @Column(name = "transaction_id", nullable = false, length = 200) private String transactionId;
    @ColumnDefault("false") @Column(nullable = false) private boolean verified;
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
