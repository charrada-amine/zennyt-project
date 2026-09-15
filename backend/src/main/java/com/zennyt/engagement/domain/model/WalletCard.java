package com.zennyt.engagement.domain.model;

import java.time.Instant;
import java.util.UUID;

/**
 * Carte enregistrée pour le retrait des gains. **Aucune donnée sensible n'est
 * conservée** : ni numéro complet, ni CVV — seulement les 4 derniers chiffres et
 * la marque, comme le fait déjà le paiement de visioconférence côté Recruitment.
 */
public record WalletCard(UUID userId, String last4, String brand, int expiryMonth,
                         int expiryYear, String cardholderName, Instant updatedAt) {

    public static WalletCard of(UUID userId, String cardNumber, String cardholderName,
                                int expiryMonth, int expiryYear) {
        return new WalletCard(userId, last4(cardNumber), detectBrand(cardNumber), expiryMonth,
            expiryYear, cardholderName, Instant.now());
    }

    static String last4(String cardNumber) {
        String digits = cardNumber == null ? "" : cardNumber.replaceAll("\\D", "");
        if (digits.length() < 4) {
            throw new IllegalArgumentException("Numéro de carte invalide");
        }
        return digits.substring(digits.length() - 4);
    }

    static String detectBrand(String cardNumber) {
        String digits = cardNumber == null ? "" : cardNumber.replaceAll("\\D", "");
        if (digits.startsWith("4")) return "VISA";
        if (digits.matches("^5[1-5].*") || digits.matches("^2(2[2-9]|[3-6].|7[01]|720).*")) {
            return "MASTERCARD";
        }
        return "UNKNOWN";
    }
}
