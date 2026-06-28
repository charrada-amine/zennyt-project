package com.zennyt.identity.infrastructure.persistence;

import com.zennyt.identity.domain.model.RefreshSession;
import com.zennyt.identity.domain.repository.RefreshSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Component
@RequiredArgsConstructor
public class RefreshSessionRepositoryAdapter implements RefreshSessionRepository {
    private final JpaRefreshSessionRepository jpa;

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

    @Override
    public void revokeAllForUser(Long userId) {
        jpa.revokeAllForUser(userId, java.time.Instant.now());
    }

    private RefreshSession toDomain(RefreshSessionEntity value) {
        return new RefreshSession(value.getId(), value.getUserId(), value.getTokenHash(),
            value.getExpiresAt(), value.getCreatedAt(), value.getRevokedAt());
    }
}
