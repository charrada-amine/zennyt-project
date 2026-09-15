package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.Referral;
import com.zennyt.engagement.domain.repository.ReferralRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/** Cas d'usage : lister les parrainages de l'utilisateur connecté. */
@Service
@RequiredArgsConstructor
public class ListReferralsUseCase {

    private final ReferralRepository referrals;

    @Transactional(readOnly = true)
    public List<Referral> execute(UUID referrerUserId) {
        return referrals.findByReferrerUserId(referrerUserId);
    }
}
