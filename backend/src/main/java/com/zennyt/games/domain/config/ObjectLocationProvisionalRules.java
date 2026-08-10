package com.zennyt.games.domain.config;

import com.zennyt.games.domain.vo.Score;

/** Barème provisoire isolé du moteur et des indicateurs descriptifs. */
public final class ObjectLocationProvisionalRules {

    public static final int MAX_POINTS = 100;
    public static final String DESCRIPTIVE_LEVEL = "Descriptive — provisional";

    private ObjectLocationProvisionalRules() {
    }

    /**
     * PROVISOIRE — non validé par le psychologue.
     *
     * <p>Score = exactitudes / objets administrés, puis un seul arrondi
     * half-up. Les swaps, distances et temps n'interviennent jamais ici.
     */
    public static Score score(int exactPlacementCount, int administeredObjectCount) {
        if (administeredObjectCount < 0
            || exactPlacementCount < 0
            || exactPlacementCount > administeredObjectCount) {
            throw new IllegalArgumentException("Compteurs d'exactitude invalides");
        }
        int points = administeredObjectCount == 0 ? 0
            : (int) ((200L * exactPlacementCount + administeredObjectCount)
                / (2L * administeredObjectCount));
        return new Score(points, MAX_POINTS, DESCRIPTIVE_LEVEL);
    }
}
