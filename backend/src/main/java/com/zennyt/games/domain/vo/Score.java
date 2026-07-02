package com.zennyt.games.domain.vo;

/**
 * Value Object Score — résultat noté d'un mini-jeu ou d'une session.
 *
 * <p>Immuable et auto-validant : on ne fait pas circuler des {@code int} nus.
 * Le score porte ses points bruts, le maximum du barème et un niveau
 * d'interprétation textuel (issu des fiches d'évaluation).
 */
public record Score(int rawPoints, int maxPoints, String level) {

    public Score {
        if (maxPoints <= 0) {
            throw new IllegalArgumentException("maxPoints doit être > 0");
        }
        if (rawPoints < 0 || rawPoints > maxPoints) {
            throw new IllegalArgumentException(
                "rawPoints hors barème : " + rawPoints + " / " + maxPoints);
        }
    }

    /** Score ramené sur 100 pour faciliter l'interprétation. */
    public double normalized() {
        return rawPoints * 100.0 / maxPoints;
    }
}
