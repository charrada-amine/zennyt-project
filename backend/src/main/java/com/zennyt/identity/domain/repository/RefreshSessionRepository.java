package com.zennyt.identity.domain.repository;

import com.zennyt.identity.domain.model.RefreshSession;

import java.util.Optional;

public interface RefreshSessionRepository {
    RefreshSession save(RefreshSession session);
    Optional<RefreshSession> findByTokenHash(String tokenHash);

    /** Révoque toutes les sessions actives d'un utilisateur (changement de mot de passe, désactivation, suppression). */
    void revokeAllForUser(Long userId);
}
