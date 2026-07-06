package com.zennyt.games.domain.vo;

import com.zennyt.games.domain.config.PrevisionPuzzleConfig;

/**
 * Métriques mesurées d'UN niveau de « Predictive Puzzle » (Tour de Hanoï).
 *
 * <p>Le mini-jeu enchaîne plusieurs niveaux ; chaque niveau est noté /10 par le
 * barème catégoriel de la fiche, puis agrégé (moyenne) en un score unique de
 * mini-jeu. L'optimal est déterministe ({@code 2^discCount − 1}) : le VO le
 * vérifie pour empêcher toute falsification.
 *
 * @param levelIndex      index du niveau (0-based)
 * @param discCount       nombre de disques (≥ 1)
 * @param firstTrySuccess réussite au 1er run sans retry ni erreur
 * @param sequenceErrors  nombre d'erreurs de séquence (≥ 0)
 * @param plannedMoves    coups planifiés du run final (≥ 0)
 * @param optimalMoves    optimal déterministe {@code 2^discCount − 1}
 * @param retries         nombre de réinitialisations de plan (≥ 0)
 * @param completed       cible du niveau atteinte
 */
public record PrevisionPuzzleLevel(
    int levelIndex,
    int discCount,
    boolean firstTrySuccess,
    int sequenceErrors,
    int plannedMoves,
    int optimalMoves,
    int retries,
    boolean completed
) {
    public PrevisionPuzzleLevel {
        if (levelIndex < 0) {
            throw new IllegalArgumentException("levelIndex doit être ≥ 0");
        }
        if (discCount < 1) {
            throw new IllegalArgumentException("discCount doit être ≥ 1");
        }
        if (sequenceErrors < 0) {
            throw new IllegalArgumentException("sequenceErrors doit être ≥ 0");
        }
        if (plannedMoves < 0) {
            throw new IllegalArgumentException("plannedMoves doit être ≥ 0");
        }
        if (retries < 0) {
            throw new IllegalArgumentException("retries doit être ≥ 0");
        }
        int expectedOptimal = PrevisionPuzzleConfig.optimalMoves(discCount);
        if (optimalMoves != expectedOptimal) {
            throw new IllegalArgumentException(
                "optimalMoves doit être déterministe (2^" + discCount + " − 1 = "
                    + expectedOptimal + "), reçu " + optimalMoves);
        }
    }

    /** Ratio de coups superflus : {@code (planned − optimal) / optimal}. */
    public double extraMovesRatio() {
        return optimalMoves <= 0 ? 0.0 : (plannedMoves - optimalMoves) / (double) optimalMoves;
    }

    /** true si le niveau a dépassé la tolérance d'erreurs (échec de niveau). */
    public boolean failedByErrorTolerance() {
        return sequenceErrors > PrevisionPuzzleConfig.maxSequenceErrorsForLevel(levelIndex);
    }
}
