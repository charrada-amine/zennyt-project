package com.zennyt.engagement.api;

import com.zennyt.engagement.api.dto.BillingDtos.PlanResponse;
import com.zennyt.engagement.api.dto.BillingDtos.PurchaseResultResponse;
import com.zennyt.engagement.api.dto.BillingDtos.SubscriptionResponse;
import com.zennyt.engagement.api.dto.BillingDtos.VerifyPurchaseRequest;
import com.zennyt.engagement.api.security.EngagementAuthenticated;
import com.zennyt.engagement.application.usecase.GetSubscriptionUseCase;
import com.zennyt.engagement.application.usecase.ListPlansUseCase;
import com.zennyt.engagement.application.usecase.VerifyPurchaseUseCase;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.UUID;

/**
 * Abonnements & achats via App Store / Google Play. Le client envoie le reçu
 * après l'achat ; le serveur le vérifie (stub provisoire) et enregistre l'achat.
 */
@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class BillingController {

    private final ListPlansUseCase listPlans;
    private final GetSubscriptionUseCase getSubscription;
    private final VerifyPurchaseUseCase verifyPurchase;

    @GetMapping("/plans")
    @EngagementAuthenticated
    public List<PlanResponse> plans() {
        return listPlans.execute().stream().map(PlanResponse::from).toList();
    }

    @GetMapping("/subscriptions/me")
    @EngagementAuthenticated
    public ResponseEntity<SubscriptionResponse> subscription(Principal principal) {
        return ResponseEntity.ok(SubscriptionResponse.from(
            getSubscription.execute(actor(principal)).orElse(null)));
    }

    @PostMapping("/purchases/verify")
    @EngagementAuthenticated
    public PurchaseResultResponse verify(@Valid @RequestBody VerifyPurchaseRequest request,
                                         Principal principal) {
        return PurchaseResultResponse.from(verifyPurchase.execute(actor(principal),
            request.productId(), request.store(), request.receipt(),
            request.transactionId()));
    }

    private static UUID actor(Principal principal) {
        return UUID.fromString(principal.getName());
    }
}
