package com.zennyt.games.infrastructure.persistence;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.UUID;

/** Repository Spring Data JPA technique (interne à l'infrastructure). */
public interface JpaGameSessionRepository extends JpaRepository<GameSessionEntity, UUID> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select session from GameSessionEntity session where session.id = :id")
    Optional<GameSessionEntity> findByIdForUpdate(@Param("id") UUID id);
}
