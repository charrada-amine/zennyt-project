package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.application.WalletView;
import com.zennyt.engagement.domain.model.Wallet;
import com.zennyt.engagement.domain.repository.WalletRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/** Cas d'usage : lire le portefeuille (solde + carte) de l'utilisateur. */
@Service
@RequiredArgsConstructor
public class GetWalletUseCase {

    private final WalletRepository wallets;

    @Transactional(readOnly = true)
    public WalletView execute(UUID userId) {
        Wallet wallet = wallets.findWallet(userId).orElseGet(() -> Wallet.empty(userId));
        return new WalletView(wallet, wallets.findCard(userId).orElse(null));
    }
}
