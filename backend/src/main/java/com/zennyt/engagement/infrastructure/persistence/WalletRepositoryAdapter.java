package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.model.Wallet;
import com.zennyt.engagement.domain.model.WalletCard;
import com.zennyt.engagement.domain.model.WalletTransaction;
import com.zennyt.engagement.domain.repository.WalletRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class WalletRepositoryAdapter implements WalletRepository {
    private final JpaWalletRepository wallets;
    private final JpaWalletTransactionRepository transactions;
    private final JpaWalletCardRepository cards;

    @Override
    public Optional<Wallet> findWallet(UUID userId) {
        return wallets.findById(userId).map(e -> new Wallet(
            e.getUserId(), e.getBalanceCents(), e.getCurrency(), e.getUpdatedAt()));
    }

    @Override
    public Optional<Wallet> findWalletForUpdate(UUID userId) {
        // Le verrou pessimiste vit dans JpaWalletRepository (SELECT ... FOR UPDATE).
        return wallets.findForUpdateByUserId(userId).map(e -> new Wallet(
            e.getUserId(), e.getBalanceCents(), e.getCurrency(), e.getUpdatedAt()));
    }

    @Override
    public Wallet saveWallet(Wallet wallet) {
        WalletEntity saved = wallets.save(new WalletEntity(
            wallet.userId(), wallet.balanceCents(), wallet.currency(), wallet.updatedAt()));
        return new Wallet(saved.getUserId(), saved.getBalanceCents(), saved.getCurrency(),
            saved.getUpdatedAt());
    }

    @Override
    public List<WalletTransaction> findTransactions(UUID userId) {
        return transactions.findByUserIdOrderByCreatedAtDesc(userId).stream()
            .map(e -> new WalletTransaction(e.getId(), e.getUserId(), e.getAmountCents(),
                e.getCurrency(), e.getKind(), e.getLabel(), e.getCreatedAt()))
            .toList();
    }

    @Override
    public WalletTransaction saveTransaction(WalletTransaction transaction) {
        WalletTransactionEntity saved = transactions.save(new WalletTransactionEntity(
            transaction.id(), transaction.userId(), transaction.amountCents(), transaction.currency(),
            transaction.kind(), transaction.label(), transaction.createdAt()));
        return new WalletTransaction(saved.getId(), saved.getUserId(), saved.getAmountCents(),
            saved.getCurrency(), saved.getKind(), saved.getLabel(), saved.getCreatedAt());
    }

    @Override
    public Optional<WalletCard> findCard(UUID userId) {
        return cards.findById(userId).map(e -> new WalletCard(e.getUserId(), e.getLast4(),
            e.getBrand(), e.getExpiryMonth(), e.getExpiryYear(), e.getCardholderName(),
            e.getUpdatedAt()));
    }

    @Override
    public WalletCard saveCard(WalletCard card) {
        WalletCardEntity saved = cards.save(new WalletCardEntity(card.userId(), card.last4(),
            card.brand(), card.expiryMonth(), card.expiryYear(), card.cardholderName(),
            card.updatedAt()));
        return new WalletCard(saved.getUserId(), saved.getLast4(), saved.getBrand(),
            saved.getExpiryMonth(), saved.getExpiryYear(), saved.getCardholderName(),
            saved.getUpdatedAt());
    }
}
