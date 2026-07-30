package com.zennyt.games.domain;

import com.zennyt.games.domain.service.PlanifikScoringService;
import com.zennyt.games.domain.service.ContinuousAttentionScoringService;
import com.zennyt.games.domain.service.ScoreBreakdownService;
import com.zennyt.games.domain.vo.CostlyZonesAvoided;
import com.zennyt.games.domain.vo.ContinuousAttentionReport;
import com.zennyt.games.domain.vo.MoveFastMetrics;
import com.zennyt.games.domain.vo.MoveFastResponse;
import com.zennyt.games.domain.vo.MoveFastRule;
import com.zennyt.games.domain.vo.OptimalPathLevel;
import com.zennyt.games.domain.vo.PlanifikMetrics;
import com.zennyt.games.domain.vo.PrevisionPuzzleLevel;
import com.zennyt.games.domain.vo.PrevisionPuzzleMetrics;
import com.zennyt.games.domain.vo.Score;
import com.zennyt.games.domain.vo.ScoreBreakdown;
import com.zennyt.games.domain.vo.SecondaryObjectivesReached;
import com.zennyt.games.support.ContinuousAttentionTestFixtures;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Détail du score (panneau) — vérifie que les lignes reflètent EXACTEMENT le
 * barème (aucun recalcul divergent). Java pur.
 */
class ScoreBreakdownServiceTest {

    private final PlanifikScoringService scoring = new PlanifikScoringService();
    private final ScoreBreakdownService breakdown = new ScoreBreakdownService();

    private static List<MoveFastResponse> correct(int n) {
        return IntStream.range(0, n)
            .mapToObj(i -> new MoveFastResponse(false, true, 500, MoveFastRule.ORIENTATION, false, false))
            .collect(Collectors.toList());
    }

    @Test
    void move_fast_breakdown_splits_game_points_and_final_bonus() {
        MoveFastMetrics m = new MoveFastMetrics(0, correct(4));
        Score score = scoring.scoreMoveFast(m); // 4 corrects → 200 jeu + 250×2 bonus = 700

        ScoreBreakdown b = breakdown.moveFast(m, score);

        // Multiplicateur atteint ×2 (streak de 4)
        assertTrue(b.lines().stream().anyMatch(l -> "Multiplicateur atteint".equals(l.label())
            && "×2".equals(l.detail())));
        // Bonus de fin = ×2 × 250 = 500
        assertTrue(b.lines().stream().anyMatch(l -> "Bonus de fin".equals(l.label())
            && l.detail().contains("× 250 = 500")));
        ScoreBreakdown.Line total = b.lines().get(b.lines().size() - 1);
        assertEquals(ScoreBreakdown.Kind.TOTAL, total.kind());
        assertEquals(700, total.points());
    }

    @Test
    void optimal_path_breakdown_lines_sum_to_level_and_average() {
        PlanifikMetrics m = new PlanifikMetrics(List.of(
            new OptimalPathLevel(0, 1, 10, 10, CostlyZonesAvoided.TOTAL, SecondaryObjectivesReached.YES)));
        Score score = scoring.scoreOptimalPath(m); // 10/10

        ScoreBreakdown b = breakdown.optimalPath(m, score);

        // 4 critères notés (chemin, essais, zones, objectif)
        long criteria = b.lines().stream()
            .filter(l -> l.kind() == ScoreBreakdown.Kind.CRITERION).count();
        assertEquals(4, criteria);
        int sum = b.lines().stream()
            .filter(l -> l.kind() == ScoreBreakdown.Kind.CRITERION)
            .mapToInt(ScoreBreakdown.Line::points).sum();
        assertEquals(10, sum);
        ScoreBreakdown.Line total = b.lines().get(b.lines().size() - 1);
        assertEquals(ScoreBreakdown.Kind.TOTAL, total.kind());
        assertEquals(10, total.points());
    }

    @Test
    void prevision_puzzle_breakdown_reflects_categorical_scale() {
        // 1er essai raté(0) + 2 erreurs(2) + planned 8 vs optimal 7 (≈14 %→2) = 4
        PrevisionPuzzleMetrics m = new PrevisionPuzzleMetrics(List.of(
            new PrevisionPuzzleLevel(0, 3, false, 2, 8, 7, 1, true)));
        Score score = scoring.scorePrevisionPuzzle(m); // 4/10

        ScoreBreakdown b = breakdown.previsionPuzzle(m, score);

        assertTrue(b.lines().stream().anyMatch(l -> "Réussi du 1er coup".equals(l.label())
            && l.points() == 0));
        assertTrue(b.lines().stream().anyMatch(l -> "Erreurs de séquence".equals(l.label())
            && "2".equals(l.detail()) && l.points() == 2));
        ScoreBreakdown.Line total = b.lines().get(b.lines().size() - 1);
        assertEquals(4, total.points());
    }

    @Test
    void continuous_attention_breakdown_is_canonical_and_uses_server_report() {
        UUID sessionId =
            UUID.fromString("00000000-0000-4000-8000-000000000001");
        ContinuousAttentionScoringService ca =
            new ContinuousAttentionScoringService();
        ContinuousAttentionReport report = ca.report(
            sessionId, ContinuousAttentionTestFixtures.perfect(sessionId));
        Score score = ca.score(report);

        ScoreBreakdown result = breakdown.continuousAttention(report, score);

        assertEquals(5, result.lines().size());
        assertEquals(ScoreBreakdown.Kind.NOTE, result.lines().get(0).kind());
        assertEquals("X_TEST — balanced accuracy", result.lines().get(1).label());
        assertEquals("100.0 %", result.lines().get(1).detail());
        assertEquals("AX_TEST — balanced accuracy", result.lines().get(2).label());
        assertEquals("100.0 %", result.lines().get(2).detail());
        assertEquals("Validité technique", result.lines().get(3).label());
        assertEquals("valide", result.lines().get(3).detail());
        assertEquals("Score descriptif", result.lines().get(4).label());
        assertEquals(100, result.lines().get(4).points());
        assertEquals(100, result.lines().get(4).maxPoints());
    }
}
