package com.zennyt.identity.infrastructure.persistence;

import com.zennyt.identity.domain.model.AccountChangeCode;
import com.zennyt.identity.domain.model.AccountChangeType;
import com.zennyt.identity.domain.repository.AccountChangeCodeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Optional;

@Component
@RequiredArgsConstructor
public class AccountChangeCodeRepositoryAdapter implements AccountChangeCodeRepository {
    private final JpaAccountChangeCodeRepository jpa;

    @Override
    public AccountChangeCode save(AccountChangeCode value) {
        AccountChangeCodeEntity saved = jpa.save(new AccountChangeCodeEntity(value.id(),
            value.userId(), value.type(), value.target(), value.codeHash(), value.expiresAt(),
            value.consumedAt(), value.attempts(), value.createdAt()));
        return toDomain(saved);
    }

    @Override
    public Optional<AccountChangeCode> findLatestActiveByUserIdAndType(Long userId,
                                                                       AccountChangeType type) {
        return jpa.findFirstByUserIdAndChangeTypeAndConsumedAtIsNullOrderByCreatedAtDesc(userId, type)
            .map(this::toDomain);
    }

    @Override
    public void invalidateAllForUserAndType(Long userId, AccountChangeType type) {
        jpa.invalidateAllForUserAndType(userId, type, Instant.now());
    }

    private AccountChangeCode toDomain(AccountChangeCodeEntity value) {
        return new AccountChangeCode(value.getId(), value.getUserId(), value.getChangeType(),
            value.getTarget(), value.getCodeHash(), value.getExpiresAt(), value.getConsumedAt(),
            value.getAttempts(), value.getCreatedAt());
    }
}
