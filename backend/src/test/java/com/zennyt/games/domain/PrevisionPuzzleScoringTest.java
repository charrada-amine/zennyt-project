package com.zennyt.games.domain;

import com.zennyt.games.domain.service.PlanifikScoringService;
import com.zennyt.games.domain.vo.PrevisionPuzzleLevel;
import com.zennyt.games.domain.vo.PrevisionPuzzleMetrics;
import com.zennyt.games.domain.vo.PrevisionPuzzleReport;
import com.zennyt.games.domain.vo.Score;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Barème CATÉGORIEL « Predictive Puzzle » (Planifik #3 — seule fiche validée).
 * Java pur, sans Spring.
 */
class PrevisionPuzzleScoringTest {

    private final PlanifikScoringService scoring = new PlanifikScoringService();

    private static int optimal(int discCount) {
        return (1 << discCount) - 1;
    }

    private static PrevisionPuzzleLevel level(int index, int discCount, boolean firstTry,
                                              int sequenceErrors, int plannedMoves,
                                              int retries, boolean completed) {
        return new PrevisionPuzzleLevel(
            index, discCount, firstTry, sequenceErrors, plannedMoves,
            optimal(discCount), retries, completed);
    }

    @Test
    void perfect_run_scores_full_marks() {
        // 1er essai(4) + 0 erreur(3) + 0 coup superflu(3) = 10
        PrevisionPuzzleMetrics m = new PrevisionPuzzleMetrics(List.of(
            level(0, 3, true, 0, optimal(3), 0, true)));

        Score score = scoring.scorePrevisionPuzzle(m);

        assertEquals(10, score.rawPoints());
        assertEquals(10, score.maxPoints());
        assertEquals("Bon à excellent", score.level());
    }

    @Test
    void first_try_fail_two_errors_and_moderate_extra_moves_scores_four() {
        // 1er essai raté(0) + 2 erreurs(2) + ~14% coups superflus(2) = 4
        // discCount 3 → optimal 7 ; planned 8 → ratio 1/7 ≈ 14,3 % (<25 %)
        PrevisionPuzzleMetrics m = new PrevisionPuzzleMetrics(List.of(
            level(0, 3, false, 2, 8, 1, true)));

        Score score = scoring.scorePrevisionPuzzle(m);

        assertEquals(4, score.rawPoints());
    }

    @Test
    void failed_level_is_scored_on_real_counters_without_forfeit_base() {
        // Niveau échoué : 1er essai raté(0) + 3 erreurs(1) + ≥25% superflus(1) = 2
        // (et surtout PAS de « base 4 » forfaitaire de l'ancienne formule).
        // discCount 3 → optimal 7 ; planned 9 → ratio 2/7 ≈ 28,6 % (≥25 %)
        PrevisionPuzzleMetrics m = new PrevisionPuzzleMetrics(List.of(
            level(0, 3, false, 3, 9, 2, false)));

        Score score = scoring.scorePrevisionPuzzle(m);

        assertEquals(2, score.rawPoints());
    }

    @Test
    void mini_game_score_is_rounded_average_over_played_levels() {
        // Niveaux : 10, 4, 2 → moyenne 16/3 = 5,33 → arrondi 5
        PrevisionPuzzleMetrics m = new PrevisionPuzzleMetrics(List.of(
            level(0, 3, true, 0, optimal(3), 0, true),   // 10
            level(1, 4, false, 2, 17, 1, true),          // 0 + 2 + (2/15≈13%→2) = 4
            level(2, 5, false, 3, 40, 2, false)));       // 0 + 1 + (9/31≈29%→1) = 2

        Score score = scoring.scorePrevisionPuzzle(m);

        assertEquals(5, score.rawPoints());
    }

    @Test
    void report_exposes_global_plan_success_outside_the_score() {
        PrevisionPuzzleMetrics allDone = new PrevisionPuzzleMetrics(List.of(
            level(0, 3, true, 0, optimal(3), 0, true),
            level(1, 4, true, 0, optimal(4), 0, true)));
        PrevisionPuzzleReport ok = PrevisionPuzzleReport.from(allDone);
        assertTrue(ok.globalPlanSuccess());
        assertEquals(2, ok.levelsCompleted());
        assertEquals(2, ok.levelsPlayed());
        assertEquals(10, ok.levels().get(0).score());

        PrevisionPuzzleMetrics oneFailed = new PrevisionPuzzleMetrics(List.of(
            level(0, 3, true, 0, optimal(3), 0, true),
            level(1, 4, false, 3, 20, 2, false)));
        PrevisionPuzzleReport ko = PrevisionPuzzleReport.from(oneFailed);
        assertFalse(ko.globalPlanSuccess());
        assertEquals(1, ko.levelsCompleted());
    }
}
