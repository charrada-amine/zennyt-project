package com.zennyt.games.domain.repository;

import com.zennyt.games.domain.model.CatalogGame;
import com.zennyt.games.domain.model.GamesProgress;

import java.time.Instant;
import java.util.UUID;

/** Historique des jeux du catalogue terminés par chaque joueur. */
public interface GameCompletionRepository {

    /** Note que [playerId] a terminé [game] à l'instant [completedAt]. Idempotent. */
    void recordCompletion(UUID playerId, CatalogGame game, Instant completedAt);

    GamesProgress progressOf(UUID playerId);
}
