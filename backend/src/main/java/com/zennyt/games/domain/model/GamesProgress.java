package com.zennyt.games.domain.model;

import java.time.Instant;
import java.util.Collections;
import java.util.EnumMap;
import java.util.Map;

/**
 * Progression d'un joueur dans le catalogue des jeux.
 *
 * <p>La couverture est la part des jeux du catalogue terminés au moins une
 * fois, chacun pesant autant que les autres. Elle dit combien du catalogue a
 * été parcouru, pas à quel point il a été réussi : le score reste l'affaire de
 * chaque jeu.
 *
 * @param lastCompletedAt dernière fin de partie par jeu terminé ; absent = jamais
 */
public record GamesProgress(Map<CatalogGame, Instant> lastCompletedAt) {

    public GamesProgress {
        EnumMap<CatalogGame, Instant> copy = new EnumMap<>(CatalogGame.class);
        copy.putAll(lastCompletedAt);
        lastCompletedAt = Collections.unmodifiableMap(copy);
    }

    public int totalGames() {
        return CatalogGame.values().length;
    }

    public int completedGames() {
        return lastCompletedAt.size();
    }

    /** Couverture 0-100, arrondie à l'entier le plus proche. */
    public int coveragePercent() {
        return Math.round(completedGames() * 100f / totalGames());
    }

    public boolean isCompleted(CatalogGame game) {
        return lastCompletedAt.containsKey(game);
    }
}
