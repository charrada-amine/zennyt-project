package com.zennyt.games.domain.vo;

/**
 * Métriques brutes remontées par le mini-jeu « Chemin Optimal » (Planifik #1).
 *
 * <p>Ce sont des mesures objectives collectées côté client (voir fiche
 * « Je planifie ») — jamais un score. Le calcul du score déterministe est du
 * ressort du domaine ({@code PlanifikScoringService}), garantissant que le
 * client ne peut pas s'auto-attribuer de points.
 *
 * @param attempts             nombre d'essais avant validation (≥ 1)
 * @param pathLength           longueur du chemin tracé par le joueur
 * @param optimalLength        longueur du chemin optimal théorique
 * @param costlyZonesAvoided   le joueur a-t-il évité les zones coûteuses
 * @param secondaryObjectives  nombre d'objectifs secondaires atteints
 */
public record PlanifikMetrics(
    int attempts,
    int pathLength,
    int optimalLength,
    boolean costlyZonesAvoided,
    int secondaryObjectives
) {
    public PlanifikMetrics {
        if (attempts < 1) {
            throw new IllegalArgumentException("attempts doit être ≥ 1");
        }
        if (pathLength < 0 || optimalLength <= 0) {
            throw new IllegalArgumentException("longueurs de chemin invalides");
        }
        if (secondaryObjectives < 0) {
            throw new IllegalArgumentException("secondaryObjectives doit être ≥ 0");
        }
    }

    /** Écart relatif au chemin optimal (0.0 = parfait). */
    public double deviationFromOptimal() {
        return Math.abs(pathLength - optimalLength) / (double) optimalLength;
    }
}
