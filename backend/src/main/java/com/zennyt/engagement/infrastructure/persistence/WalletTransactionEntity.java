package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.vo.WalletTransactionKind;
import jakarta.persistence.*;
import org.hibernate.annotations.Check;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "wallet_transactions", schema = "engagement",
    indexes = @Index(name = "idx_wallet_transactions_user", columnList = "user_id, created_at DESC"))
@Check(name = "ck_wallet_transactions_kind", constraints = "kind IN ('CREDIT', 'DEBIT', 'WITHDRAWAL')")
class WalletTransactionEntity {
    @Id private UUID id;
    @Column(name = "user_id", nullable = false) private UUID userId;
    @Column(name = "amount_cents", nullable = false) private long amountCents;
    @Column(nullable = false, length = 3) private String currency;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 20) private WalletTransactionKind kind;
    @Column(nullable = false, length = 200) private String label;
    @Column(name = "created_at", nullable = false) private Instant createdAt;

    protected WalletTransactionEntity() {}

    WalletTransactionEntity(UUID id, UUID userId, long amountCents, String currency,
                            WalletTransactionKind kind, String label, Instant createdAt) {
        this.id = id;
        this.userId = userId;
        this.amountCents = amountCents;
        this.currency = currency;
        this.kind = kind;
        this.label = label;
        this.createdAt = createdAt;
    }

    UUID getId() { return id; }
    UUID getUserId() { return userId; }
    long getAmountCents() { return amountCents; }
    String getCurrency() { return currency; }
    WalletTransactionKind getKind() { return kind; }
    String getLabel() { return label; }
    Instant getCreatedAt() { return createdAt; }
}
