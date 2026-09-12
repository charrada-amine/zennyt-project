package com.zennyt.engagement.domain.repository;

import com.zennyt.engagement.domain.model.Referral;

import java.util.List;
import java.util.UUID;

public interface ReferralRepository {
    Referral save(Referral referral);

    List<Referral> findByReferrerUserId(UUID referrerUserId);

    boolean existsByReferrerUserIdAndInviteeEmail(UUID referrerUserId, String inviteeEmail);
}
