package com.zennyt.games.domain;

import com.zennyt.games.domain.config.TaskSchedulingConfig;
import com.zennyt.games.domain.service.PlanifikScoringService;
import com.zennyt.games.domain.vo.Score;
import com.zennyt.games.domain.vo.TaskSchedulingMetrics;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * Barème « Ordonnancement de tâches » (Planifik #2). Java pur, parité mock.
 * Dépendances 3/0 + contraintes 3/0 + cohérence 0–2 + réajustements (dérivé).
 */
class TaskSchedulingScoringTest {

    private final PlanifikScoringService scoring = new PlanifikScoringService();

    @Test
    void perfect_schedule_scores_full_marks() {
        // 3 (deps) + 3 (horaires) + 2 (cohérence) + 2 (0 réajustement) = 10
        Score score = scoring.scoreTaskScheduling(
            new TaskSchedulingMetrics(true, true, 2, 0));

        assertEquals(10, score.rawPoints());
        assertEquals(10, score.maxPoints());
        assertEquals("Bon à excellent", score.level());
    }

    @Test
    void broken_dependencies_lose_the_whole_criterion() {
        // deps NON respectées → 0 (tout-ou-rien) ; 0 + 3 + 2 + 2 = 7
        Score score = scoring.scoreTaskScheduling(
            new TaskSchedulingMetrics(false, true, 2, 0));

        assertEquals(7, score.rawPoints());
    }

    @Test
    void adjustment_count_two_falls_in_the_2to4_band_worth_one_point() {
        // ⚠️ Piège : 2 réajustements = 1 pt (tranche 2-4), PAS 2 pts.
        assertEquals(1, TaskSchedulingConfig.adjustmentScore(2));

        // 3 (deps) + 3 (horaires) + 0 (cohérence) + 1 (2 réajustements) = 7
        Score score = scoring.scoreTaskScheduling(
            new TaskSchedulingMetrics(true, true, 0, 2));

        assertEquals(7, score.rawPoints());
    }

    @Test
    void more_than_four_adjustments_scores_zero_on_that_criterion() {
        assertEquals(0, TaskSchedulingConfig.adjustmentScore(5));
        assertEquals(2, TaskSchedulingConfig.adjustmentScore(1)); // < 2 → 2 pts

        // 3 + 3 + 2 + 0 = 8
        Score score = scoring.scoreTaskScheduling(
            new TaskSchedulingMetrics(true, true, 2, 5));

        assertEquals(8, score.rawPoints());
    }
}
