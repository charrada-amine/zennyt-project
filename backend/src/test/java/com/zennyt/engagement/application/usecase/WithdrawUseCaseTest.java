package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.Wallet;
import com.zennyt.engagement.domain.model.WalletTransaction;
import com.zennyt.engagement.domain.repository.WalletRepository;
import com.zennyt.engagement.domain.vo.WalletTransactionKind;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class WithdrawUseCaseTest {

    private static final UUID USER = UUID.randomUUID();

    private final WalletRepository wallets = mock(WalletRepository.class);
    private final WithdrawUseCase useCase = new WithdrawUseCase(wallets);

    @Test
    void debitsTheBalanceAndRecordsAWithdrawalTransaction() {
        Wallet wallet = new Wallet(USER, 10_000L, "EUR", java.time.Instant.now());
        when(wallets.findWalletForUpdate(USER)).thenReturn(Optional.of(wallet));
        when(wallets.saveWallet(any())).thenAnswer(inv -> inv.getArgument(0));

        var view = useCase.execute(USER, new BigDecimal("12.34"));

        // 12.34 € = 1234 centimes débités.
        assertThat(view.wallet().balanceCents()).isEqualTo(10_000L - 1_234L);
        verify(wallets).saveTransaction(argThat(transaction ->
            transaction.userId().equals(USER)
                && transaction.amountCents() == -1_234L
                && transaction.currency().equals("EUR")
                && transaction.kind() == WalletTransactionKind.WITHDRAWAL
                && transaction.label().equals("Withdrawal")));
    }

    @Test
    void floorsSubCentAmountsInsteadOfRoundingUp() {
        Wallet wallet = new Wallet(USER, 10_000L, "EUR", null);
        when(wallets.findWalletForUpdate(USER)).thenReturn(Optional.of(wallet));
        when(wallets.saveWallet(any())).thenAnswer(inv -> inv.getArgument(0));

        // 10.999 € → 1099 cents (FLOOR), jamais 1100.
        var debited = useCase.execute(USER, new BigDecimal("10.999"));

        assertThat(debited.wallet().balanceCents()).isEqualTo(10_000L - 1_099L);
        verify(wallets).saveTransaction(any(WalletTransaction.class));
    }

    @Test
    void rejectsNullNegativeAndZeroAmounts() {
        assertThatThrownBy(() -> useCase.execute(USER, null))
            .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> useCase.execute(USER, BigDecimal.ZERO))
            .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> useCase.execute(USER, new BigDecimal("-1.00")))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void rejectsAmountsAboveTheCeiling() {
        // PROVISOIRE — à valider : plafond anti-débordement (longValueExact).
        assertThatThrownBy(() -> useCase.execute(USER, new BigDecimal("1000001")))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void rejectsAnInsufficientBalance() {
        when(wallets.findWalletForUpdate(USER))
            .thenReturn(Optional.of(new Wallet(USER, 100L, "EUR", null)));

        assertThatThrownBy(() -> useCase.execute(USER, new BigDecimal("2.00")))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("Solde insuffisant");
    }

    @Test
    void anUnknownWalletCannotWithdraw() {
        when(wallets.findWalletForUpdate(USER)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.execute(USER, new BigDecimal("2.00")))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("Solde insuffisant");
        verify(wallets, never()).saveWallet(any());
    }

    @Test
    void chargesThroughThePessimisticLock() {
        when(wallets.findWalletForUpdate(USER))
            .thenReturn(Optional.of(new Wallet(USER, 500L, "EUR", null)));
        when(wallets.saveWallet(any())).thenAnswer(inv -> inv.getArgument(0));

        useCase.execute(USER, new BigDecimal("1.00"));

        verify(wallets).findWalletForUpdate(USER);
        verify(wallets, never()).findWallet(any());
    }
}
