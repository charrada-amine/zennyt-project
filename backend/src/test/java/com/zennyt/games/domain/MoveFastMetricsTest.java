package com.zennyt.games.domain;

import com.zennyt.games.domain.config.MoveFastConfig;
import com.zennyt.games.domain.vo.MoveFastFlexibilityReport;
import com.zennyt.games.domain.vo.MoveFastMetrics;
import com.zennyt.games.domain.vo.MoveFastResponse;
import com.zennyt.games.domain.vo.MoveFastRule;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Tests du domaine « Je bouge / Move Fast » : validation des métriques,
 * indicateurs de flexibilité cognitive et bandes d'interprétation. Java pur.
 */
class MoveFastMetricsTest {

    private static MoveFastResponse scored(boolean correct, int ms, MoveFastRule rule,
                                           boolean isSwitch, boolean appliedOld) {
        return new MoveFastResponse(false, correct, ms, rule, isSwitch, appliedOld);
    }

    // ── Validation (1.C anti-triche + intégrité échauffement) ────────────────

    @Test
    void rejects_practice_count_mismatch() {
        List<MoveFastResponse> responses = List.of(
            scored(true, 500, MoveFastRule.ORIENTATION, false, false));
        // 0 essai marqué practiceTrial mais on annonce 1 exclusion
        assertThrows(IllegalArgumentException.class,
            () -> new MoveFastMetrics(1, responses));
    }

    @Test
    void rejects_more_scored_responses_than_max() {
        int max = MoveFastConfig.SESSION_END_CONDITION.maxResponses();
        List<MoveFastResponse> responses = new ArrayList<>();
        for (int i = 0; i < max + 1; i++) {
            responses.add(scored(true, 100, MoveFastRule.ORIENTATION, false, false));
        }
        assertThrows(IllegalArgumentException.class,
            () -> new MoveFastMetrics(0, responses));
    }

    @Test
    void rejects_total_reaction_time_beyond_session_duration() {
        int sessionMs = MoveFastConfig.SESSION_END_CONDITION.sessionSeconds() * 1000;
        List<MoveFastResponse> responses = List.of(
            scored(true, sessionMs, MoveFastRule.ORIENTATION, false, false),
            scored(true, sessionMs, MoveFastRule.ORIENTATION, false, false));
        assertThrows(IllegalArgumentException.class,
            () -> new MoveFastMetrics(0, responses));
    }

    @Test
    void rejects_when_only_practice_trials() {
        MoveFastResponse practice = new MoveFastResponse(
            true, true, 400, MoveFastRule.ORIENTATION, false, false);
        assertThrows(IllegalArgumentException.class,
            () -> new MoveFastMetrics(1, List.of(practice)));
    }

    // ── Indicateurs de flexibilité (Tableau 3) ───────────────────────────────

    @Test
    void report_computes_switch_cost_and_perseverative_errors() {
        List<MoveFastResponse> responses = List.of(
            scored(true, 400, MoveFastRule.ORIENTATION, false, false),
            scored(true, 500, MoveFastRule.ORIENTATION, false, false),
            // bascule vers MOVEMENT, plus lente
            scored(true, 900, MoveFastRule.MOVEMENT, true, false),
            // bascule + erreur persévérative (a appliqué l'ancienne règle)
            scored(false, 1000, MoveFastRule.ORIENTATION, true, true));

        MoveFastFlexibilityReport report =
            MoveFastFlexibilityReport.from(new MoveFastMetrics(0, responses), 42, "completed");

        // switch trials : 900, 1000 → avg 950 ; non-switch : 400, 500 → avg 450
        assertEquals(950.0, report.switchResponseTimeAvgMs(), 0.001);
        assertEquals(450.0, report.nonSwitchResponseTimeAvgMs(), 0.001);
        assertEquals(500.0, report.switchCostMs(), 0.001);
        assertEquals(1, report.perseverativeErrorsCount());
        assertEquals(2, report.correctResponsesRuleOrientation());
        assertEquals(1, report.correctResponsesRuleMovement());
        assertEquals(75.0, report.precisionRatio(), 0.001); // 3/4
        assertEquals(42, report.sessionDurationSec());
        assertEquals("completed", report.sessionCompletionStatus());
    }

    @Test
    void report_excludes_practice_from_indicators() {
        MoveFastResponse practice = new MoveFastResponse(
            true, false, 5000, MoveFastRule.ORIENTATION, false, false);
        List<MoveFastResponse> responses = List.of(
            practice,
            scored(true, 200, MoveFastRule.ORIENTATION, false, false),   // rapide (<250)
            scored(true, 2500, MoveFastRule.ORIENTATION, false, false)); // lente (>2000)

        MoveFastFlexibilityReport report =
            MoveFastFlexibilityReport.from(new MoveFastMetrics(1, responses), 30, "completed");

        assertEquals(100.0, report.precisionRatio(), 0.001);  // 2/2 notés
        assertEquals(50.0, report.fastResponsesPercent(), 0.001);
        assertEquals(50.0, report.slowResponsesPercent(), 0.001);
    }

    // ── Mode de fin de session (configurable, défaut FIXED_BUDGET) ───────────

    @Test
    void default_session_end_mode_is_fixed_budget() {
        // ⚠️ Défaut = FIXED_BUDGET (diverge de la fiche) — comportement inchangé.
        assertEquals(MoveFastConfig.SessionEndMode.FIXED_BUDGET,
            MoveFastConfig.SESSION_END_MODE);
        assertTrue(MoveFastConfig.enforcesFixedBudget());
    }

    @Test
    void plausibility_fixed_budget_caps_responses_and_duration() {
        int max = MoveFastConfig.SESSION_END_CONDITION.maxResponses();
        long sessionMs = MoveFastConfig.SESSION_END_CONDITION.sessionSeconds() * 1000L;

        // Dans le budget → aucune violation.
        assertNull(MoveFastConfig.plausibilityViolation(
            MoveFastConfig.SessionEndMode.FIXED_BUDGET, max, sessionMs));
        // Trop d'essais → violation.
        assertNotNull(MoveFastConfig.plausibilityViolation(
            MoveFastConfig.SessionEndMode.FIXED_BUDGET, max + 1, 0));
        // Durée dépassée → violation.
        assertNotNull(MoveFastConfig.plausibilityViolation(
            MoveFastConfig.SessionEndMode.FIXED_BUDGET, 1, sessionMs + 1));
    }

    @Test
    void plausibility_reach_max_multiplier_has_no_caps() {
        // Mode fiche : ni plafond d'essais ni de durée, même valeurs extrêmes.
        assertNull(MoveFastConfig.plausibilityViolation(
            MoveFastConfig.SessionEndMode.REACH_MAX_MULTIPLIER, 10_000, 10_000_000L));
    }

    // ── Bandes d'interprétation provisoires ──────────────────────────────────

    @Test
    void interpretation_bands_match_provisional_thresholds() {
        assertEquals("Très faible", MoveFastConfig.interpret(0));
        assertEquals("Très faible", MoveFastConfig.interpret(39)); // 39 → Très faible
        assertEquals("Moyen faible", MoveFastConfig.interpret(40));
        assertEquals("Moyen", MoveFastConfig.interpret(60));
        assertEquals("Bon", MoveFastConfig.interpret(75));
        assertEquals("Bon", MoveFastConfig.interpret(89.9)); // borne haute de « Bon »
        assertEquals("Excellent", MoveFastConfig.interpret(90)); // 90 → Excellent
        assertEquals("Excellent", MoveFastConfig.interpret(100));
    }
}
