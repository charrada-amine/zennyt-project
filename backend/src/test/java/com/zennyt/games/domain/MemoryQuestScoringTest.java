package com.zennyt.games.domain;

import com.zennyt.games.domain.config.MemoryQuestConfig;
import com.zennyt.games.domain.service.MemoryQuestScoringService;
import com.zennyt.games.domain.vo.MemoryQuestMetrics;
import com.zennyt.games.domain.vo.MemoryQuestReport;
import com.zennyt.games.domain.vo.MemoryTaskKind;
import com.zennyt.games.domain.vo.MemoryTaskResult;
import com.zennyt.games.domain.vo.Score;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
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

    // ── Système de niveaux (fiche Tableau 1) ─────────────────────────────────

    @Test
    void level_config_helpers_follow_the_progression() {
        assertEquals(3, MemoryQuestConfig.sequenceLengthForLevel(1));
        assertEquals(4, MemoryQuestConfig.sequenceLengthForLevel(2));
        assertEquals(9, MemoryQuestConfig.sequenceLengthForLevel(7));
        assertEquals(9, MemoryQuestConfig.sequenceLengthForLevel(20)); // plafonné
        assertEquals(4, MemoryQuestConfig.objectCountForLevel(1));
        assertEquals(12, MemoryQuestConfig.objectCountForLevel(7));
        // Distraction gatée au niveau ≥ 3.
        assertFalse(MemoryQuestConfig.distractionActiveAtLevel(2));
        assertTrue(MemoryQuestConfig.distractionActiveAtLevel(3));
    }

    // ── Calibrage appareil → timeout (le score dépend enfin du temps) ────────

    private static MemoryQuestMetrics withTask(MemoryTaskResult task, int level, boolean completed) {
        return new MemoryQuestMetrics(
            4, 4, 4, 4, 0, 0, 0, false, 0, 0, false,
            level, completed, List.of(task));
    }

    @Test
    void timeout_voids_task_unless_calibration_raises_threshold() {
        // Tâche parfaite (5/5) mais TROP LENTE d'1 ms au-delà du max.
        MemoryTaskResult slow = new MemoryTaskResult(
            MemoryTaskKind.SAME_ORDER, 4, 4, MemoryQuestConfig.MAX_TASK_TIME_MS + 1);
        MemoryQuestMetrics m = withTask(slow, 1, true);

        // Sans calibrage : dépassement → note voidée → composite 0.
        assertEquals(0, scoring.score(m, 0.0).rawPoints());
        // Appareil lent (offset) : seuil remonté → non échouée → note conservée → 100.
        assertEquals(100, scoring.score(m, 2000.0).rawPoints());
    }

    @Test
    void calibration_offset_only_affects_timeout_not_recall_accuracy() {
        // Tâche dans les temps : l'offset ne change PAS la note de rappel.
        MemoryTaskResult inTime = new MemoryTaskResult(
            MemoryTaskKind.SAME_ORDER, 3, 4, 1000); // 3/4 → 4/5 → 80
        MemoryQuestMetrics m = withTask(inTime, 1, true);
        assertEquals(80, scoring.score(m, 0.0).rawPoints());
        assertEquals(80, scoring.score(m, 3000.0).rawPoints());
    }

    // ── Validité de session (fiche Tableau 3) ────────────────────────────────

    @Test
    void session_invalid_on_abandon() {
        MemoryTaskResult ok = new MemoryTaskResult(MemoryTaskKind.SAME_ORDER, 4, 4, 1000);
        MemoryQuestReport r = scoring.report(withTask(ok, 2, false), 0.0); // abandon
        assertFalse(r.sessionValid());
    }

    @Test
    void session_invalid_on_critical_calibration_offset() {
        MemoryTaskResult ok = new MemoryTaskResult(MemoryTaskKind.SAME_ORDER, 4, 4, 1000);
        double critical = MemoryQuestConfig.CRITICAL_CALIBRATION_OFFSET_MS + 1;
        MemoryQuestReport r = scoring.report(withTask(ok, 2, true), critical);
        assertFalse(r.sessionValid());
    }

    @Test
    void session_invalid_on_too_many_timeouts() {
        int overMax = MemoryQuestConfig.MAX_TASK_TIME_MS + 1;
        List<MemoryTaskResult> tasks = List.of(
            new MemoryTaskResult(MemoryTaskKind.SAME_ORDER, 4, 4, overMax),
            new MemoryTaskResult(MemoryTaskKind.REVERSE_ORDER, 4, 4, overMax),
            new MemoryTaskResult(MemoryTaskKind.RESTORE, 4, 4, overMax),
            new MemoryTaskResult(MemoryTaskKind.AFTER_DISTRACTION, 4, 4, overMax));
        MemoryQuestMetrics m = new MemoryQuestMetrics(
            4, 4, 4, 4, 0, 0, 0, false, 0, 0, false, 3, true, tasks);

        MemoryQuestReport r = scoring.report(m, 0.0); // 4 timeouts > MAX_TIMEOUT_TASKS(3)
        assertEquals(4, r.timeoutTaskCount());
        assertFalse(r.sessionValid());
    }

    @Test
    void valid_session_when_completed_no_critical_offset_and_few_timeouts() {
        MemoryTaskResult ok = new MemoryTaskResult(MemoryTaskKind.SAME_ORDER, 4, 4, 1000);
        MemoryQuestReport r = scoring.report(withTask(ok, 3, true), 10.0);
        assertTrue(r.sessionValid());
        assertEquals(3, r.finalLevel());
        assertEquals(0, r.timeoutTaskCount());
    }

    // ── Non-régression : composite inchangé pour une session mono-niveau ─────

    @Test
    void legacy_metrics_composite_unchanged() {
        // Ancienne forme (agrégats plats, sans tasks) → composite identique.
        MemoryQuestMetrics legacy = new MemoryQuestMetrics(
            4, 4, 3, 5, 4, 4, 2, true, 4, 4, true);
        assertEquals(95, scoring.score(legacy).rawPoints());
        // Le calibrage n'a aucun effet en mode agrégat (pas de timings).
        assertEquals(95, scoring.score(legacy, 5000.0).rawPoints());
    }
}
