package com.zennyt.games.domain.vo;

/**
 * Métriques mesurées d'UN niveau de « Chemin Optimal » (Planifik #1).
 *
 * <p>Le mini-jeu enchaîne plusieurs niveaux ; chaque niveau est noté /10 par le
 * domaine, puis agrégé (moyenne) en un score unique de mini-jeu. Ce sont des
 * mesures objectives — jamais un score.
 *
 * @param levelIndex                index du niveau (0-based)
 * @param attempts                  essais avant validation du niveau (≥ 1)
 * @param pathLength                longueur du chemin tracé
 * @param optimalLength             longueur du chemin optimal théorique (≥ 1)
 * @param costlyZonesAvoided        degré d'évitement des zones coûteuses
 * @param secondaryObjectivesReached atteinte des objectifs secondaires
 */
public record OptimalPathLevel(
    int levelIndex,
    int attempts,
    int pathLength,
    int optimalLength,
    CostlyZonesAvoided costlyZonesAvoided,
    SecondaryObjectivesReached secondaryObjectivesReached
) {
    public OptimalPathLevel {
        if (levelIndex < 0) {
            throw new IllegalArgumentException("levelIndex doit être ≥ 0");
        }
        if (attempts < 1) {
            throw new IllegalArgumentException("attempts doit être ≥ 1");
        }
        if (pathLength < 0 || optimalLength <= 0) {
            throw new IllegalArgumentException("longueurs de chemin invalides");
        }
        if (costlyZonesAvoided == null) {
            throw new IllegalArgumentException("costlyZonesAvoided est requis");
        }
        if (secondaryObjectivesReached == null) {
            throw new IllegalArgumentException("secondaryObjectivesReached est requis");
        }
    }

    /** Écart relatif au chemin optimal (0.0 = parfait) : {@code |path − optimal| / optimal}. */
    public double deviationFromOptimal() {
        return Math.abs(pathLength - optimalLength) / (double) optimalLength;
    }
}
