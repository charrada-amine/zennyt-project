package com.zennyt.engagement.infrastructure.persistence;

import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "wallet_cards", schema = "engagement")
class WalletCardEntity {
    @Id @Column(name = "user_id") private UUID userId;
    @Column(nullable = false, length = 4) private String last4;
    @Column(nullable = false, length = 20) private String brand;
    @Column(name = "expiry_month", nullable = false) private int expiryMonth;
    @Column(name = "expiry_year", nullable = false) private int expiryYear;
    @Column(name = "cardholder_name", nullable = false, length = 150) private String cardholderName;
    @Column(name = "updated_at", nullable = false) private Instant updatedAt;

    protected WalletCardEntity() {}

    WalletCardEntity(UUID userId, String last4, String brand, int expiryMonth, int expiryYear,
                     String cardholderName, Instant updatedAt) {
        this.userId = userId;
        this.last4 = last4;
        this.brand = brand;
        this.expiryMonth = expiryMonth;
        this.expiryYear = expiryYear;
        this.cardholderName = cardholderName;
        this.updatedAt = updatedAt;
    }

    UUID getUserId() { return userId; }
    String getLast4() { return last4; }
    String getBrand() { return brand; }
    int getExpiryMonth() { return expiryMonth; }
    int getExpiryYear() { return expiryYear; }
    String getCardholderName() { return cardholderName; }
    Instant getUpdatedAt() { return updatedAt; }
}
