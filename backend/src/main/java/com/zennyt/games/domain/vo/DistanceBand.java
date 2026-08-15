package com.zennyt.games.domain.vo;

/**
 * Bande de proximité sémantique visée par un niveau de difficulté
 * (paramètre {@code target_distance_per_level} du brief v2).
 *
 * <p>La valeur cible {@code target} (dans [0,1]) est <b>PROVISOIRE</b> : elle sera
 * recalibrée sur données réelles (section 4 du brief) avant tout usage décisionnel.
 * Distance élevée = émotions très différentes = scène facile ; distance faible =
 * émotions proches = scène difficile.
 */
public enum DistanceBand {
    /** Émotions très différentes (facile). PROVISOIRE. */
    HIGH(0.70),
    /** Émotions moyennement proches. PROVISOIRE. */
    MEDIUM(0.45),
    /** Émotions très proches (difficile). PROVISOIRE. */
    LOW(0.22);

    private final double target;

    DistanceBand(double target) {
        this.target = target;
    }

    /** Distance sémantique visée pour cette bande (PROVISOIRE, à recalibrer). */
    public double target() {
        return target;
    }
}
