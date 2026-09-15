package com.zennyt.engagement.api.dto;

import com.zennyt.engagement.application.WalletView;
import com.zennyt.engagement.domain.model.WalletCard;
import com.zennyt.engagement.domain.model.WalletTransaction;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public final class WalletDtos {

    private WalletDtos() {}

    public record WalletCardRequest(
        @NotBlank String cardNumber,
        @NotNull @Min(1) @Max(12) Integer expiryMonth,
        @NotNull Integer expiryYear,
        @NotBlank String cvv,
        @NotBlank @Size(max = 150) String cardholderName
    ) {}

    public record WalletCardResponse(String last4, String brand, int expiryMonth, int expiryYear,
                                     String cardholderName) {
        public static WalletCardResponse from(WalletCard card) {
            return card == null ? null : new WalletCardResponse(card.last4(), card.brand(),
                card.expiryMonth(), card.expiryYear(), card.cardholderName());
        }
    }

    public record WalletResponse(long balanceCents, String currency, WalletCardResponse card) {
        public static WalletResponse from(WalletView view) {
            return new WalletResponse(view.wallet().balanceCents(), view.wallet().currency(),
                WalletCardResponse.from(view.card()));
        }
    }

    public record WalletTransactionResponse(UUID id, long amountCents, String currency, String kind,
                                            String label, Instant createdAt) {
        public static WalletTransactionResponse from(WalletTransaction transaction) {
            return new WalletTransactionResponse(transaction.id(), transaction.amountCents(),
                transaction.currency(), transaction.kind().name(), transaction.label(),
                transaction.createdAt());
        }
    }

    public record WithdrawRequest(@NotNull @DecimalMin("0.01") BigDecimal amount) {}
}
