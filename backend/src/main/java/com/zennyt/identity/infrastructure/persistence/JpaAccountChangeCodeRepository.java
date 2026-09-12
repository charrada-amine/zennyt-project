package com.zennyt.identity.infrastructure.persistence;

import com.zennyt.identity.domain.model.AccountChangeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.Optional;

interface JpaAccountChangeCodeRepository extends JpaRepository<AccountChangeCodeEntity, Long> {

    Optional<AccountChangeCodeEntity> findFirstByUserIdAndChangeTypeAndConsumedAtIsNullOrderByCreatedAtDesc(
        Long userId, AccountChangeType changeType);

    @Modifying
    @Query("update AccountChangeCodeEntity c set c.consumedAt = :now "
        + "where c.userId = :userId and c.changeType = :type and c.consumedAt is null")
    void invalidateAllForUserAndType(@Param("userId") Long userId,
                                     @Param("type") AccountChangeType type,
                                     @Param("now") Instant now);
}
