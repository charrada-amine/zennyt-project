package com.zennyt.engagement.domain;

import com.zennyt.engagement.domain.model.Wallet;
import com.zennyt.engagement.domain.model.WalletCard;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class WalletTest {

    private static final UUID USER = UUID.randomUUID();

    @Test
    void emptyWalletStartsAtZeroInEuro() {
        Wallet wallet = Wallet.empty(USER);
        assertThat(wallet.balanceCents()).isZero();
        assertThat(wallet.currency()).isEqualTo("EUR");
    }

    @Test
    void creditAndDebitMoveTheBalance() {
        Wallet wallet = Wallet.empty(USER).credit(50000, Instant.now());
        assertThat(wallet.balanceCents()).isEqualTo(50000);
        assertThat(wallet.debit(15000, Instant.now()).balanceCents()).isEqualTo(35000);
    }

    @Test
    void debitBeyondBalanceIsRejected() {
        Wallet wallet = Wallet.empty(USER).credit(1000, Instant.now());
        assertThatThrownBy(() -> wallet.debit(1001, Instant.now()))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("Solde insuffisant");
    }

    @Test
    void cardKeepsOnlyLast4AndBrand() {
        WalletCard visa = WalletCard.of(USER, "4111 1111 1111 1234", "Anna Mary", 12, 2030);
        assertThat(visa.last4()).isEqualTo("1234");
        assertThat(visa.brand()).isEqualTo("VISA");

        WalletCard mastercard = WalletCard.of(USER, "5555 5555 5555 4444", "Anna Mary", 6, 2029);
        assertThat(mastercard.brand()).isEqualTo("MASTERCARD");
    }
}
