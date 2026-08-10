package com.zennyt.games.domain.config;

import com.zennyt.games.domain.vo.Score;

/** Couche remplaçable du score provisoire de « Je coordonne ». */
public final class CoordinationProvisionalRules {

    public static final int MAX_POINTS = 100;
    public static final String DESCRIPTIVE_LEVEL = "Descriptive — provisional";

    private CoordinationProvisionalRules() {
    }

    /**
     * PROVISOIRE — non validé par le psychologue.
     *
     * <p>Le score est la précision globale pondérée par le temps, arrondie
     * half-up une seule fois. Les précisions par vitesse/durée et la distance
     * moyenne restent strictement descriptives.
     */
    public static Score score(long insideDurationMs, long totalDurationMs) {
        if (insideDurationMs < 0 || totalDurationMs <= 0
            || insideDurationMs > totalDurationMs) {
            throw new IllegalArgumentException("Durées de précision invalides");
        }
        long numerator = insideDurationMs * MAX_POINTS;
        int roundedHalfUp = Math.toIntExact(
            (2L * numerator + totalDurationMs) / (2L * totalDurationMs));
        return new Score(roundedHalfUp, MAX_POINTS, DESCRIPTIVE_LEVEL);
    }
}
