package com.zennyt.games.domain.repository;

import com.zennyt.games.domain.model.GameSession;

import java.util.Optional;
import java.util.UUID;

/**
 * Port (interface) du repository de sessions de jeu.
 *
 * <p>Défini dans le domaine, implémenté dans l'infrastructure. Le domaine
 * dépend de cette abstraction, jamais de JPA — inversion de dépendance de
 * l'architecture hexagonale.
 */
public interface GameSessionRepository {

    GameSession save(GameSession session);

    Optional<GameSession> findById(UUID id);
}
