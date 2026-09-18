package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.vo.ReferralStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

interface JpaReferralRepository extends JpaRepository<ReferralEntity, UUID> {

    List<ReferralEntity> findByReferrerUserIdOrderByCreatedAtDesc(UUID referrerUserId);

    boolean existsByReferrerUserIdAndInviteeEmail(UUID referrerUserId, String inviteeEmail);

    long countByReferrerUserIdAndStatus(UUID referrerUserId, ReferralStatus status);
}
