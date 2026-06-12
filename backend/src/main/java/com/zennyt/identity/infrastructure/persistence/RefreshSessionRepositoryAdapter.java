package com.zennyt.identity.infrastructure.persistence;

import com.zennyt.identity.domain.model.RefreshSession;
import com.zennyt.identity.domain.repository.RefreshSessionRepository;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Component
public class RefreshSessionRepositoryAdapter implements RefreshSessionRepository {
    private final JpaRefreshSessionRepository jpa;

    public RefreshSessionRepositoryAdapter(JpaRefreshSessionRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public RefreshSession save(RefreshSession value) {
        RefreshSessionEntity saved = jpa.save(new RefreshSessionEntity(value.id(), value.userId(),
            value.tokenHash(), value.expiresAt(), value.createdAt(), value.revokedAt()));
        return toDomain(saved);
    }

    @Override
    public Optional<RefreshSession> findByTokenHash(String tokenHash) {
        return jpa.findByTokenHash(tokenHash).map(this::toDomain);
    }

    private RefreshSession toDomain(RefreshSessionEntity value) {
        return new RefreshSession(value.getId(), value.getUserId(), value.getTokenHash(),
            value.getExpiresAt(), value.getCreatedAt(), value.getRevokedAt());
    }
}
