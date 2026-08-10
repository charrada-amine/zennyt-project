package com.zennyt.games.domain.config;

import com.zennyt.games.domain.vo.Score;

/** Barème isolé afin de pouvoir le remplacer sans toucher au protocole. */
public final class ContinuousAttentionProvisionalRules {

    public static final String DESCRIPTIVE_LEVEL =
        "Descriptive — provisional";

    private ContinuousAttentionProvisionalRules() {
    }

    /** Compteurs entiers nécessaires à un arrondi cross-platform exact. */
    public record AccuracyCounts(
        int hits,
        int targets,
        int correctRejections,
        int nonTargets
    ) {
        public AccuracyCounts {
            if (targets <= 0 || nonTargets <= 0
                || hits < 0 || hits > targets
                || correctRejections < 0 || correctRejections > nonTargets) {
                throw new IllegalArgumentException("Compteurs d'accuracy invalides");
            }
        }
    }

    // PROVISOIRE — non validé par le psychologue
    public static Score score(AccuracyCounts x, AccuracyCounts ax) {
        /*
         * Score = 25 × (hX/tX + crX/nX + hAX/tAX + crAX/nAX).
         * On garde toute l'expression en rationnels entiers puis on effectue
         * UN seul arrondi half-up. Cela évite les divergences Java/Dart aux .5.
         */
        long denominator =
            (long) x.targets() * x.nonTargets() * ax.targets() * ax.nonTargets();
        long sumNumerator =
            (long) x.hits() * x.nonTargets() * ax.targets() * ax.nonTargets()
            + (long) x.correctRejections() * x.targets()
                * ax.targets() * ax.nonTargets()
            + (long) ax.hits() * x.targets() * x.nonTargets() * ax.nonTargets()
            + (long) ax.correctRejections() * x.targets() * x.nonTargets()
                * ax.targets();
        long numerator = 25L * sumNumerator;
        int points = (int) ((2L * numerator + denominator) / (2L * denominator));
        return new Score(points, ContinuousAttentionConfig.SCORE_MAX, DESCRIPTIVE_LEVEL);
    }
}
