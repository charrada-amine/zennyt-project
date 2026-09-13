package com.zennyt.engagement.application;

import com.zennyt.engagement.application.port.StoreReceiptVerifierPort;
import com.zennyt.engagement.application.usecase.VerifyPurchaseUseCase;
import com.zennyt.engagement.domain.model.StorePurchase;
import com.zennyt.engagement.domain.model.Subscription;
import com.zennyt.engagement.domain.repository.StorePurchaseRepository;
import com.zennyt.engagement.domain.repository.SubscriptionRepository;
import com.zennyt.engagement.domain.vo.PurchaseKind;
import com.zennyt.engagement.domain.vo.StorePlatform;
import com.zennyt.engagement.domain.vo.SubscriptionStatus;
import com.zennyt.shared.application.exception.NotFoundException;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class VerifyPurchaseUseCaseTest {

    private static final UUID USER = UUID.randomUUID();

    private final SubscriptionRepository subscriptions = mock(SubscriptionRepository.class);
    private final StorePurchaseRepository purchases = mock(StorePurchaseRepository.class);
    private final StoreReceiptVerifierPort verifier = mock(StoreReceiptVerifierPort.class);
    private final VerifyPurchaseUseCase useCase =
        new VerifyPurchaseUseCase(subscriptions, purchases, verifier);

    private void validPurchase() {
        when(verifier.verify(any(), any(), any(), any())).thenReturn(
            new StoreReceiptVerifierPort.VerifiedPurchase(true, "orig-1", Instant.now(), true));
        when(purchases.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(subscriptions.save(any())).thenAnswer(inv -> inv.getArgument(0));
    }

    @Test
    void aSubscriptionPurchaseActivatesTheSubscription() {
        validPurchase();
        when(purchases.existsByTransactionId("tx-1")).thenReturn(false);

        var result = useCase.execute(USER, "recruiter_pro_monthly", StorePlatform.APPLE, "receipt",
            "tx-1");

        assertThat(result.purchase().kind()).isEqualTo(PurchaseKind.SUBSCRIPTION);
        assertThat(result.subscription().status()).isEqualTo(SubscriptionStatus.ACTIVE);
        assertThat(result.subscription().planCode()).isEqualTo("recruiter_pro_monthly");
        assertThat(result.subscription().expiresAt()).isAfter(Instant.now());
    }

    @Test
    void aConsumablePurchaseDoesNotCreateASubscription() {
        validPurchase();
        when(purchases.existsByTransactionId("tx-2")).thenReturn(false);
        when(subscriptions.findByUserId(USER)).thenReturn(Optional.empty());

        var result = useCase.execute(USER, "video_interview_single", StorePlatform.GOOGLE, "receipt",
            "tx-2");

        assertThat(result.purchase().kind()).isEqualTo(PurchaseKind.CONSUMABLE);
        assertThat(result.subscription()).isNull();
        verify(subscriptions, never()).save(any());
    }

    @Test
    void anUnknownProductIsRejected() {
        assertThatThrownBy(() -> useCase.execute(USER, "nope", StorePlatform.APPLE, "r", "tx"))
            .isInstanceOf(NotFoundException.class);
    }

    @Test
    void aReplayedTransactionIsIdempotent() {
        when(purchases.existsByTransactionId("tx-3")).thenReturn(true);

        var result = useCase.execute(USER, "recruiter_pro_monthly", StorePlatform.APPLE, "r", "tx-3");

        assertThat(result.purchase()).isNull();
        verify(verifier, never()).verify(any(), any(), any(), any());
    }
}
