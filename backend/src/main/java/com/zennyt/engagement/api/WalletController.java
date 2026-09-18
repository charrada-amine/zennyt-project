package com.zennyt.engagement.api;

import com.zennyt.engagement.api.dto.WalletDtos.WalletCardRequest;
import com.zennyt.engagement.api.dto.WalletDtos.WalletCardResponse;
import com.zennyt.engagement.api.dto.WalletDtos.WalletResponse;
import com.zennyt.engagement.api.dto.WalletDtos.WalletTransactionResponse;
import com.zennyt.engagement.api.dto.WalletDtos.WithdrawRequest;
import com.zennyt.engagement.api.security.EngagementAuthenticated;
import com.zennyt.engagement.application.usecase.GetWalletUseCase;
import com.zennyt.engagement.application.usecase.ListWalletTransactionsUseCase;
import com.zennyt.engagement.application.usecase.SaveWalletCardUseCase;
import com.zennyt.engagement.application.usecase.WithdrawUseCase;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.UUID;

/** Portefeuille (solde, écritures, carte de retrait) — contrat engagement. */
@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class WalletController {

    private final GetWalletUseCase getWallet;
    private final ListWalletTransactionsUseCase listTransactions;
    private final SaveWalletCardUseCase saveCard;
    private final WithdrawUseCase withdraw;

    @GetMapping("/wallet/me")
    @EngagementAuthenticated
    public WalletResponse wallet(Principal principal) {
        return WalletResponse.from(getWallet.execute(actor(principal)));
    }

    @GetMapping("/wallet/me/transactions")
    @EngagementAuthenticated
    public List<WalletTransactionResponse> transactions(Principal principal) {
        return listTransactions.execute(actor(principal)).stream()
            .map(WalletTransactionResponse::from)
            .toList();
    }

    @PutMapping("/wallet/me/card")
    @EngagementAuthenticated
    public WalletCardResponse putCard(@Valid @RequestBody WalletCardRequest request,
                                      Principal principal) {
        return WalletCardResponse.from(saveCard.execute(actor(principal), request.cardNumber(),
            request.expiryMonth(), request.expiryYear(), request.cvv(), request.cardholderName()));
    }

    @PostMapping("/wallet/me/withdraw")
    @EngagementAuthenticated
    public WalletResponse withdraw(@Valid @RequestBody WithdrawRequest request,
                                   Principal principal) {
        return WalletResponse.from(withdraw.execute(actor(principal), request.amount()));
    }

    private static UUID actor(Principal principal) {
        return UUID.fromString(principal.getName());
    }
}
