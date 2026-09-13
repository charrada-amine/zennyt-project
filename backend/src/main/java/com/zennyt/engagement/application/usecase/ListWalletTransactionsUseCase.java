package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.WalletTransaction;
import com.zennyt.engagement.domain.repository.WalletRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/** Cas d'usage : lister les écritures du portefeuille de l'utilisateur. */
@Service
@RequiredArgsConstructor
public class ListWalletTransactionsUseCase {

    private final WalletRepository wallets;

    @Transactional(readOnly = true)
    public List<WalletTransaction> execute(UUID userId) {
        return wallets.findTransactions(userId);
    }
}
