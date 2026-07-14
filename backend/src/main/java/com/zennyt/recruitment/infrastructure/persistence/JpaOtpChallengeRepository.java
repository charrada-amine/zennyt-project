package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.OtpPurpose;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface JpaOtpChallengeRepository extends JpaRepository<OtpChallengeEntity, UUID> {
    Optional<OtpChallengeEntity> findFirstByResourceIdAndPurposeOrderByCreatedAtDesc(
        UUID resourceId, OtpPurpose purpose);
}
