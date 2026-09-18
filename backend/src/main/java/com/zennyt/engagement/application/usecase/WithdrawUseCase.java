package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.application.WalletView;
import com.zennyt.engagement.domain.model.Wallet;
import com.zennyt.engagement.domain.model.WalletTransaction;
import com.zennyt.engagement.domain.repository.WalletRepository;
import com.zennyt.engagement.domain.vo.WalletTransactionKind;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.UUID;

/**
 * Cas d'usage : retirer un montant du portefeuille. Le débit est refusé si le
 * solde est insuffisant ({@link IllegalArgumentException} → 400 côté API). Pas de
 * PSP réel : l'écriture matérialise le retrait, le virement bancaire reste à
 * intégrer.
 *
 * <p>Le portefeuille est chargé avec verrou pessimiste en écriture
 * (`findWalletForUpdate`) : deux retraits concurrents ne peuvent pas lire le
 * même solde et double-dépenser.
 */
@Service
@RequiredArgsConstructor
public class WithdrawUseCase {

    /** PROVISOIRE — à valider : plafond d'un retrait, en euros, avant tout contact PSP. */
    private static final BigDecimal MAX_WITHDRAW_AMOUNT_EUR = new BigDecimal("1000000");

    private final WalletRepository wallets;

    @Transactional
    public WalletView execute(UUID userId, BigDecimal amount) {
        if (amount == null || amount.signum() <= 0) {
            throw new IllegalArgumentException("Montant invalide");
        }
        if (amount.compareTo(MAX_WITHDRAW_AMOUNT_EUR) > 0) {
            throw new IllegalArgumentException("Montant supérieur au plafond de retrait");
        }
        // FLOOR, jamais HALF_UP : on n'arrondit JAMAIS un retrait au centime
        // supérieur — sinon l'utilisateur retirerait plus que demandé.
        long cents = amount.movePointRight(2).setScale(0, RoundingMode.FLOOR).longValueExact();
        Wallet wallet = wallets.findWalletForUpdate(userId).orElseGet(() -> Wallet.empty(userId));
        Wallet debited = wallets.saveWallet(wallet.debit(cents, Instant.now()));
        wallets.saveTransaction(WalletTransaction.of(userId, -cents, wallet.currency(),
            WalletTransactionKind.WITHDRAWAL, "Withdrawal"));
        return new WalletView(debited, wallets.findCard(userId).orElse(null));
    }
}
