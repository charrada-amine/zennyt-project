package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.IdentityVerification;

import java.util.Optional;
import java.util.UUID;

/**
 * Port du repository de vérifications d'identité.
 */
public interface IdentityVerificationRepository {

    IdentityVerification save(IdentityVerification verification);

    Optional<IdentityVerification> findById(UUID id);
}
