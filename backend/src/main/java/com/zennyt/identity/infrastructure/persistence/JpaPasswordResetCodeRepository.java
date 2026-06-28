package com.zennyt.identity.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.Optional;

interface JpaPasswordResetCodeRepository extends JpaRepository<PasswordResetCodeEntity, Long> {

    Optional<PasswordResetCodeEntity> findFirstByUserIdAndConsumedAtIsNullOrderByCreatedAtDesc(
        Long userId);

    @Modifying
    @Query("update PasswordResetCodeEntity c set c.consumedAt = :now "
        + "where c.userId = :userId and c.consumedAt is null")
    void invalidateAllForUser(@Param("userId") Long userId, @Param("now") Instant now);
}
