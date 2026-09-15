package com.zennyt.engagement.api;

import com.zennyt.engagement.api.dto.ReferralDtos.ReferralInviteRequest;
import com.zennyt.engagement.api.dto.ReferralDtos.ReferralLinkResponse;
import com.zennyt.engagement.api.dto.ReferralDtos.ReferralResponse;
import com.zennyt.engagement.api.security.EngagementAuthenticated;
import com.zennyt.engagement.application.ActorDirectory;
import com.zennyt.engagement.application.usecase.GetReferralLinkUseCase;
import com.zennyt.engagement.application.usecase.InviteReferralUseCase;
import com.zennyt.engagement.application.usecase.ListReferralsUseCase;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.UUID;

/** Parrainage (programme Ambassadeur) — contrat engagement. */
@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class ReferralController {

    private final ListReferralsUseCase listReferrals;
    private final InviteReferralUseCase inviteReferral;
    private final GetReferralLinkUseCase getReferralLink;
    private final ActorDirectory actors;

    @GetMapping("/referrals/me")
    @EngagementAuthenticated
    public List<ReferralResponse> list(Principal principal) {
        return listReferrals.execute(actor(principal)).stream()
            .map(referral -> ReferralResponse.from(referral, actors))
            .toList();
    }

    @PostMapping("/referrals/invite")
    @EngagementAuthenticated
    public ResponseEntity<ReferralResponse> invite(
            @Valid @RequestBody ReferralInviteRequest request, Principal principal) {
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ReferralResponse.from(
                inviteReferral.execute(actor(principal), request.email()), actors));
    }

    @GetMapping("/referrals/me/link")
    @EngagementAuthenticated
    public ReferralLinkResponse link(Principal principal) {
        var link = getReferralLink.execute(actor(principal));
        return new ReferralLinkResponse(link.code(), link.url(), link.bonusAmount(),
            link.bonusCurrency());
    }

    private static UUID actor(Principal principal) {
        return UUID.fromString(principal.getName());
    }
}
