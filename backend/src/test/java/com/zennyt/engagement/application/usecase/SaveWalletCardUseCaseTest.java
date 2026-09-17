package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.WalletCard;
import com.zennyt.engagement.domain.repository.WalletRepository;
import org.junit.jupiter.api.Test;

import java.time.YearMonth;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class SaveWalletCardUseCaseTest {
    private static final UUID USER = UUID.randomUUID();
    private static final String CARD = "4111111111111111";
    private final WalletRepository wallets = mock(WalletRepository.class);
    private final SaveWalletCardUseCase useCase = new SaveWalletCardUseCase(wallets);

    @Test
    void rejectsExpiredCards() {
        YearMonth expiry = YearMonth.now().minusMonths(1);
        assertThatThrownBy(() -> useCase.execute(USER, CARD, expiry.getMonthValue(),
            expiry.getYear(), "123", "Test User"))
            .isInstanceOf(IllegalArgumentException.class);
        verify(wallets, never()).saveCard(any());
    }

    @Test
    void rejectsYearsBeyondTheSupportedHorizon() {
        int year = YearMonth.now().getYear();
        for (int invalidYear : new int[]{year - 1, year + 26, Integer.MAX_VALUE}) {
            assertThatThrownBy(() -> useCase.execute(USER, CARD, 12,
                invalidYear, "123", "Test User"))
                .isInstanceOf(IllegalArgumentException.class);
        }
        verify(wallets, never()).saveCard(any());
    }

    @Test
    void acceptsCurrentMonthAndUpperYearBoundary() {
        YearMonth now = YearMonth.now();
        when(wallets.saveCard(any())).thenAnswer(invocation -> invocation.getArgument(0));
        WalletCard current = useCase.execute(USER, CARD, now.getMonthValue(),
            now.getYear(), "123", " Test User ");
        WalletCard latest = useCase.execute(USER, CARD, 12,
            now.getYear() + 25, "123", "Test User");
        assertThat(current.last4()).isEqualTo("1111");
        assertThat(current.cardholderName()).isEqualTo("Test User");
        assertThat(latest.expiryYear()).isEqualTo(now.getYear() + 25);
    }
}
