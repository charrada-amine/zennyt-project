package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.model.Referral;
import com.zennyt.engagement.domain.repository.ReferralRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class ReferralRepositoryAdapter implements ReferralRepository {
    private final JpaReferralRepository jpa;

    @Override
    public Referral save(Referral referral) {
        return toDomain(jpa.save(new ReferralEntity(referral.id(), referral.referrerUserId(),
            referral.inviteeEmail(), referral.inviteeUserId(), referral.status(),
            referral.hiredAt(), referral.probationEndsAt(), referral.createdAt(),
            referral.updatedAt())));
    }

    @Override
    public List<Referral> findByReferrerUserId(UUID referrerUserId) {
        return jpa.findByReferrerUserIdOrderByCreatedAtDesc(referrerUserId).stream()
            .map(this::toDomain)
            .toList();
    }

    @Override
    public boolean existsByReferrerUserIdAndInviteeEmail(UUID referrerUserId, String inviteeEmail) {
        return jpa.existsByReferrerUserIdAndInviteeEmail(referrerUserId, inviteeEmail);
    }

    private Referral toDomain(ReferralEntity e) {
        return new Referral(e.getId(), e.getReferrerUserId(), e.getInviteeEmail(),
            e.getInviteeUserId(), e.getStatus(), e.getHiredAt(), e.getProbationEndsAt(),
            e.getCreatedAt(), e.getUpdatedAt());
    }
}
