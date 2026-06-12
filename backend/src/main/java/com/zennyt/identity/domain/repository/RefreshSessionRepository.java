package com.zennyt.identity.domain.repository;

import com.zennyt.identity.domain.model.RefreshSession;

import java.util.Optional;

public interface RefreshSessionRepository {
    RefreshSession save(RefreshSession session);
    Optional<RefreshSession> findByTokenHash(String tokenHash);
}
