package com.zennyt.games.domain;

import com.zennyt.games.domain.service.MemoryQuestScoringService;
import com.zennyt.games.domain.vo.MemoryQuestMetrics;
import com.zennyt.games.domain.vo.MemoryQuestReport;
import com.zennyt.games.domain.vo.Score;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Barème « J'investigue » (mémoire de travail) : tâches 0–5 → composite /100.
 * Java pur. Parité avec le mock mobile (games_mock_repository.dart).
 */
class MemoryQuestScoringTest {

    private final MemoryQuestScoringService scoring = new MemoryQuestScoringService();

    @Test
    void composite_averages_task_scores_over_100() {
        // Same 4/4 → 5 ; reverse 3/4 → 4 ; restore 4/4 → 5 ; after-distr 4/4 → 5.
        // Moyenne (5+4+5+5)/4 = 4.75 /5 → 95.
        MemoryQuestMetrics m = new MemoryQuestMetrics(
            4, 4, 3, 5,
            4, 4, 2,
            true, 4, 4, true);

        Score score = scoring.score(m);

        assertEquals(95, score.rawPoints());
        assertEquals(100, score.maxPoints());
        assertEquals("Excellent", score.level());
    }

    @Test
    void mission_a_only_composite_uses_two_tasks() {
        // Pas de Mission B (objectCount 0) ni distraction : same 2/4→3 (round 2.5),
        // reverse 4/4→5 → moyenne (3+5)/2 = 4 /5 → 80.
        MemoryQuestMetrics m = new MemoryQuestMetrics(
            4, 2, 4, 4,
            0, 0, 0,
            false, 0, 0, false);

        assertEquals(80, scoring.score(m).rawPoints());
    }

    @Test
    void report_exposes_task_scores_and_nulls_for_unplayed_tasks() {
        MemoryQuestMetrics m = new MemoryQuestMetrics(
            4, 4, 4, 6,
            0, 0, 0,
            false, 0, 0, false);

        MemoryQuestReport r = scoring.report(m);

        assertEquals(5, r.sameOrderScore());
        assertEquals(5, r.reverseOrderScore());
        assertNull(r.restoreScore());
        assertNull(r.afterDistractionScore());
        assertEquals(6, r.highestSequenceLength());
        assertTrue(!r.missionBPlayed() && !r.distractionPlayed());
    }

    @Test
    void rejects_correct_greater_than_observed() {
        assertThrows(IllegalArgumentException.class, () -> new MemoryQuestMetrics(
            4, 5, 0, 4, 0, 0, 0, false, 0, 0, false));
    }
}
