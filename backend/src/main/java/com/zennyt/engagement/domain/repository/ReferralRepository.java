package com.zennyt.engagement.domain.repository;

import com.zennyt.engagement.domain.model.Referral;
import com.zennyt.engagement.domain.vo.ReferralStatus;

import java.util.List;
import java.util.UUID;

public interface ReferralRepository {
    Referral save(Referral referral);

    List<Referral> findByReferrerUserId(UUID referrerUserId);

    boolean existsByReferrerUserIdAndInviteeEmail(UUID referrerUserId, String inviteeEmail);

    /** Nombre de parrainages d'un parrain dans un statut donné (garde-fou anti-spam d'invitations). */
    long countByReferrerUserIdAndStatus(UUID referrerUserId, ReferralStatus status);
}
