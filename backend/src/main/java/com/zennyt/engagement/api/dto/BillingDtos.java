package com.zennyt.engagement.api.dto;

import com.zennyt.engagement.application.usecase.VerifyPurchaseUseCase;
import com.zennyt.engagement.domain.model.Plan;
import com.zennyt.engagement.domain.model.Subscription;
import jakarta.validation.constraints.NotBlank;

import java.time.Instant;

public final class BillingDtos {

    private BillingDtos() {}

    public record PlanResponse(String code, String productId, String name, String description,
                               long priceCents, String currency, String period, boolean popular) {
        public static PlanResponse from(Plan plan) {
            return new PlanResponse(plan.code(), plan.productId(), plan.name(), plan.description(),
                plan.priceCents(), plan.currency(), plan.period().name(), plan.popular());
        }
    }

    public record SubscriptionResponse(String planCode, String status, String store,
                                       Instant purchasedAt, Instant expiresAt, boolean autoRenewing) {
        public static SubscriptionResponse from(Subscription subscription) {
            return subscription == null ? null : new SubscriptionResponse(subscription.planCode(),
                subscription.status().name(), subscription.store().name(), subscription.purchasedAt(),
                subscription.expiresAt(), subscription.autoRenewing());
        }
    }

    public record VerifyPurchaseRequest(@NotBlank String productId, @NotBlank String store,
                                        @NotBlank String receipt, @NotBlank String transactionId) {}

    public record PurchaseResultResponse(SubscriptionResponse subscription, String productId,
                                         String kind) {
        public static PurchaseResultResponse from(VerifyPurchaseUseCase.Result result) {
            return new PurchaseResultResponse(SubscriptionResponse.from(result.subscription()),
                result.purchase() == null ? null : result.purchase().productId(),
                result.purchase() == null ? null : result.purchase().kind().name());
        }
    }
}
