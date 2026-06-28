package com.zennyt.identity.domain.repository;

import com.zennyt.identity.domain.model.PasswordResetCode;

import java.util.Optional;

public interface PasswordResetCodeRepository {
    PasswordResetCode save(PasswordResetCode code);

    /** Dernier code non consommé de l'utilisateur (le plus récent). */
    Optional<PasswordResetCode> findLatestActiveByUserId(Long userId);

    /** Consomme tous les codes actifs de l'utilisateur (avant d'en émettre un nouveau). */
    void invalidateAllForUser(Long userId);
}
