package com.zennyt.engagement.infrastructure.persistence;

import jakarta.persistence.*;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.ColumnDefault;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "wallets", schema = "engagement")
@Check(name = "ck_wallets_balance_non_negative", constraints = "balance_cents >= 0")
class WalletEntity {
    @Id @Column(name = "user_id") private UUID userId;
    @ColumnDefault("0") @Column(name = "balance_cents", nullable = false) private long balanceCents;
    @ColumnDefault("'EUR'") @Column(nullable = false, length = 3) private String currency;
    @Column(name = "updated_at", nullable = false) private Instant updatedAt;

    protected WalletEntity() {}

    WalletEntity(UUID userId, long balanceCents, String currency, Instant updatedAt) {
        this.userId = userId;
        this.balanceCents = balanceCents;
        this.currency = currency;
        this.updatedAt = updatedAt;
    }

    UUID getUserId() { return userId; }
    long getBalanceCents() { return balanceCents; }
    String getCurrency() { return currency; }
    Instant getUpdatedAt() { return updatedAt; }
}
