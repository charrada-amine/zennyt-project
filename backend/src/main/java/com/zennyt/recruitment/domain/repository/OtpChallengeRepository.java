package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.OtpChallenge;
import com.zennyt.recruitment.domain.vo.OtpPurpose;

import java.util.Optional;
import java.util.UUID;

public interface OtpChallengeRepository {
    OtpChallenge save(OtpChallenge challenge);
    Optional<OtpChallenge> findLatest(UUID resourceId, OtpPurpose purpose);
}
