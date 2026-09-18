package com.zennyt.engagement.infrastructure.persistence;

import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "wallets", schema = "engagement")
class WalletEntity {
    @Id @Column(name = "user_id") private UUID userId;
    @Column(name = "balance_cents", nullable = false) private long balanceCents;
    @Column(nullable = false, length = 3) private String currency;
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
