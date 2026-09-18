package com.zennyt.engagement.api.dto;

import com.zennyt.engagement.application.ActorDirectory;
import com.zennyt.engagement.domain.model.Referral;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

public final class ReferralDtos {

    private ReferralDtos() {}

    public record ReferralInviteRequest(@NotBlank @Email @Size(max = 150) String email) {}

    public record ReferralResponse(UUID id, String inviteeEmail, String inviteeName,
                                   String inviteeAvatarUrl, String status, Instant createdAt,
                                   Instant probationEndsAt, Long daysRemaining) {
        public static ReferralResponse from(Referral referral, ActorDirectory actors) {
            String name = null;
            String avatar = null;
            if (referral.inviteeUserId() != null) {
                var presentation = actors.presentation(referral.inviteeUserId());
                name = presentation.displayName();
                avatar = presentation.photoUrl();
            }
            Long daysRemaining = referral.probationEndsAt() == null ? null
                : Math.max(0, Duration.between(Instant.now(), referral.probationEndsAt()).toDays());
            return new ReferralResponse(referral.id(), referral.inviteeEmail(), name, avatar,
                referral.status().name(), referral.createdAt(), referral.probationEndsAt(),
                daysRemaining);
        }
    }

    public record ReferralLinkResponse(String code, String url, int bonusAmount,
                                       String bonusCurrency) {}
}
