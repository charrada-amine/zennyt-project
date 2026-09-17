package com.zennyt.engagement.domain.repository;

import com.zennyt.engagement.domain.model.Wallet;
import com.zennyt.engagement.domain.model.WalletCard;
import com.zennyt.engagement.domain.model.WalletTransaction;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface WalletRepository {
    Optional<Wallet> findWallet(UUID userId);

    /**
     * Portefeuille chargé avec verrou pessimiste en écriture — obligatoire pour
     * tout débit : deux retraits concurrents ne peuvent pas lire le même solde
     * et double-dépenser.
     */
    Optional<Wallet> findWalletForUpdate(UUID userId);

    Wallet saveWallet(Wallet wallet);

    List<WalletTransaction> findTransactions(UUID userId);

    WalletTransaction saveTransaction(WalletTransaction transaction);

    Optional<WalletCard> findCard(UUID userId);

    WalletCard saveCard(WalletCard card);
}
