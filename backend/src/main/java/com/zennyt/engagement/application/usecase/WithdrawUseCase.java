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
 */
@Service
@RequiredArgsConstructor
public class WithdrawUseCase {

    private final WalletRepository wallets;

    @Transactional
    public WalletView execute(UUID userId, BigDecimal amount) {
        if (amount == null || amount.signum() <= 0) {
            throw new IllegalArgumentException("Montant invalide");
        }
        long cents = amount.movePointRight(2).setScale(0, RoundingMode.HALF_UP).longValueExact();
        Wallet wallet = wallets.findWallet(userId).orElseGet(() -> Wallet.empty(userId));
        Wallet debited = wallets.saveWallet(wallet.debit(cents, Instant.now()));
        wallets.saveTransaction(WalletTransaction.of(userId, -cents, wallet.currency(),
            WalletTransactionKind.WITHDRAWAL, "Withdrawal"));
        return new WalletView(debited, wallets.findCard(userId).orElse(null));
    }
}
