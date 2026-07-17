package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.model.OtpChallenge;
import com.zennyt.recruitment.domain.repository.OtpChallengeRepository;
import com.zennyt.recruitment.domain.vo.OtpPurpose;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class OtpChallengeRepositoryAdapter implements OtpChallengeRepository {
    private final JpaOtpChallengeRepository jpa;

    @Override
    public OtpChallenge save(OtpChallenge value) {
        return toDomain(jpa.save(new OtpChallengeEntity(
            value.id(), value.resourceId(), value.recipientUserId(), value.purpose(),
            value.salt(), value.codeHash(), value.expiresAt(), value.attemptsRemaining(),
            value.consumedAt(), value.createdAt())));
    }

    @Override
    public Optional<OtpChallenge> findLatest(UUID resourceId, OtpPurpose purpose) {
        return jpa.findFirstByResourceIdAndPurposeOrderByCreatedAtDesc(resourceId, purpose)
            .map(this::toDomain);
    }

    private OtpChallenge toDomain(OtpChallengeEntity value) {
        return OtpChallenge.rehydrate(value.getId(), value.getResourceId(),
            value.getRecipientUserId(), value.getPurpose(), value.getSalt(), value.getCodeHash(),
            value.getExpiresAt(), value.getAttemptsRemaining(), value.getConsumedAt(),
            value.getCreatedAt());
    }
}
