package com.zennyt.games.domain;

import com.zennyt.games.domain.config.OptimalPathConfig;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Tests des constantes de configuration « Chemin Optimal » (Planifik #1).
 * Verrouille les valeurs de la fiche « JE PLANIFIE — Mini-jeu 1 ».
 */
class OptimalPathConfigTest {

    @Test
    void freezes_fiche_technical_keys() {
        assertEquals(0.10, OptimalPathConfig.OPTIMAL_PATH_TOLERANCE, 0.0);
        assertEquals(3, OptimalPathConfig.MAX_ATTEMPTS);
        assertEquals(4, OptimalPathConfig.TOTAL_LEVELS); // décision produit (fiche : « à définir »)
        assertTrue(OptimalPathConfig.PREPLANNING_REQUIRED);
        assertTrue(OptimalPathConfig.GLOBAL_PLAN_VALIDATION);
        assertEquals(10, OptimalPathConfig.MAX_POINTS);
    }

    @Test
    void attempt_score_matches_scale_1to3_2to2_3plus_to1() {
        assertEquals(3, OptimalPathConfig.attemptScore(1));
        assertEquals(2, OptimalPathConfig.attemptScore(2));
        assertEquals(1, OptimalPathConfig.attemptScore(3));
        assertEquals(1, OptimalPathConfig.attemptScore(4));
        assertEquals(1, OptimalPathConfig.attemptScore(10));
    }
}
