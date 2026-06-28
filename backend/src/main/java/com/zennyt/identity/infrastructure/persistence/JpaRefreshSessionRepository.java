package com.zennyt.identity.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

interface JpaRefreshSessionRepository extends JpaRepository<RefreshSessionEntity, UUID> {
    Optional<RefreshSessionEntity> findByTokenHash(String tokenHash);

    @Modifying
    @Query("update RefreshSessionEntity s set s.revokedAt = :now "
        + "where s.userId = :userId and s.revokedAt is null")
    void revokeAllForUser(@Param("userId") Long userId, @Param("now") Instant now);
}
