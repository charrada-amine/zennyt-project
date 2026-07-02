package com.zennyt.games.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

/** Repository Spring Data JPA technique (interne à l'infrastructure). */
public interface JpaGameSessionRepository extends JpaRepository<GameSessionEntity, UUID> {
}
