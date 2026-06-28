package com.zennyt.identity.infrastructure.persistence;

import com.zennyt.identity.domain.model.PasswordResetCode;
import com.zennyt.identity.domain.repository.PasswordResetCodeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Optional;

@Component
@RequiredArgsConstructor
public class PasswordResetCodeRepositoryAdapter implements PasswordResetCodeRepository {
    private final JpaPasswordResetCodeRepository jpa;

    @Override
    public PasswordResetCode save(PasswordResetCode value) {
        PasswordResetCodeEntity saved = jpa.save(new PasswordResetCodeEntity(value.id(),
            value.userId(), value.codeHash(), value.expiresAt(), value.consumedAt(),
            value.attempts(), value.createdAt()));
        return toDomain(saved);
    }

    @Override
    public Optional<PasswordResetCode> findLatestActiveByUserId(Long userId) {
        return jpa.findFirstByUserIdAndConsumedAtIsNullOrderByCreatedAtDesc(userId)
            .map(this::toDomain);
    }

    @Override
    public void invalidateAllForUser(Long userId) {
        jpa.invalidateAllForUser(userId, Instant.now());
    }

    private PasswordResetCode toDomain(PasswordResetCodeEntity value) {
        return new PasswordResetCode(value.getId(), value.getUserId(), value.getCodeHash(),
            value.getExpiresAt(), value.getConsumedAt(), value.getAttempts(), value.getCreatedAt());
    }
}
