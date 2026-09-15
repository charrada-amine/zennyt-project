package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.WalletCard;
import com.zennyt.engagement.domain.repository.WalletRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.YearMonth;
import java.util.UUID;

/**
 * Cas d'usage : enregistrer (ou remplacer) la carte de retrait. Le numéro complet
 * et le CVV ne sont jamais persistés — seuls les 4 derniers chiffres et la marque.
 */
@Service
@RequiredArgsConstructor
public class SaveWalletCardUseCase {

    private final WalletRepository wallets;

    @Transactional
    public WalletCard execute(UUID userId, String cardNumber, int expiryMonth, int expiryYear,
                              String cvv, String cardholderName) {
        String digits = cardNumber == null ? "" : cardNumber.replaceAll("\\D", "");
        if (digits.length() < 13 || digits.length() > 19) {
            throw new IllegalArgumentException("Numéro de carte invalide");
        }
        if (expiryMonth < 1 || expiryMonth > 12) {
            throw new IllegalArgumentException("Mois d'expiration invalide");
        }
        if (YearMonth.of(expiryYear, expiryMonth).isBefore(YearMonth.now())) {
            throw new IllegalArgumentException("Carte expirée");
        }
        if (cvv == null || !cvv.matches("\\d{3,4}")) {
            throw new IllegalArgumentException("CVV invalide");
        }
        if (cardholderName == null || cardholderName.isBlank()) {
            throw new IllegalArgumentException("Nom du titulaire obligatoire");
        }
        return wallets.saveCard(WalletCard.of(userId, digits, cardholderName.trim(), expiryMonth,
            expiryYear));
    }
}
