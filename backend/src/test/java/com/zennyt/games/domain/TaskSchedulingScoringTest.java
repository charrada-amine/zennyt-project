package com.zennyt.games.domain;

import com.zennyt.games.domain.config.TaskSchedulingConfig;
import com.zennyt.games.domain.service.PlanifikScoringService;
import com.zennyt.games.domain.vo.Score;
import com.zennyt.games.domain.vo.TaskSchedulingMetrics;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Barème « Planning journalier » (Planifik #2) — quatre composantes /10.
 *
 * <p>Doit rester en parité stricte avec le mock mobile
 * ({@code task_scheduling_mock_test.dart}) : une démonstration hors ligne qui
 * noterait autrement qu'une passation réelle donnerait au client une impression
 * fausse du jeu.
 */
class TaskSchedulingScoringTest {

    private final PlanifikScoringService scoring = new PlanifikScoringService();

    /** Planning parfait, ajustable composante par composante. */
    private static TaskSchedulingMetrics parfait(
            int edgeCount, int edgesRespected, int directViolations,
            int timingCount, int timingRespected,
            boolean collisionFree, double deadTimeRatio,
            int proactive, int reactive) {
        return new TaskSchedulingMetrics(
            "restaurant", edgeCount, edgesRespected, directViolations,
            timingCount, timingRespected, collisionFree, deadTimeRatio,
            proactive, reactive, 1, null);
    }

    private static TaskSchedulingMetrics parfait() {
        return parfait(10, 10, 0, 6, 6, true, 0.0, 0, 0);
    }

    @Test
    void perfect_schedule_scores_full_marks() {
        Score score = scoring.scoreTaskScheduling(parfait());

        assertEquals(10, score.rawPoints());
        assertEquals(10, score.maxPoints());
    }

    // ── Composante 1 : dépendances ───────────────────────────────────────────

    @Test
    void dependencies_are_prorated_not_all_or_nothing() {
        // La moitié des arêtes vaut la moitié des points : 1,5 + 3 + 2 + 2 = 8,5
        // -> 9. L'ancien barème donnait 0 sur cette composante, confondant un
        // joueur à moitié correct et un joueur au hasard.
        assertEquals(1.5, TaskSchedulingConfig.dependencyScore(5, 10, 0), 1e-9);
        assertEquals(9, scoring.scoreTaskScheduling(
            parfait(10, 5, 0, 6, 6, true, 0.0, 0, 0)).rawPoints());
    }

    @Test
    void a_direct_violation_costs_a_full_point() {
        // Le référentiel traite la règle enfreinte — « tâche lancée sans que son
        // prérequis soit terminé » — comme une erreur distincte d'un simple
        // sous-optimum d'ordre.
        assertEquals(2.0, TaskSchedulingConfig.dependencyScore(10, 10, 1), 1e-9);
        assertEquals(9, scoring.scoreTaskScheduling(
            parfait(10, 10, 1, 6, 6, true, 0.0, 0, 0)).rawPoints());
    }

    @Test
    void the_dependency_component_never_goes_negative() {
        assertEquals(0.0, TaskSchedulingConfig.dependencyScore(10, 10, 9), 1e-9);
    }

    @Test
    void a_universe_without_dependencies_keeps_the_component() {
        assertEquals(3.0, TaskSchedulingConfig.dependencyScore(0, 0, 0), 1e-9);
    }

    // ── Composante 2 : gestion du temps ──────────────────────────────────────

    @Test
    void time_divides_by_the_real_constraint_count_of_the_universe() {
        // Le référentiel l'exige : n varie de 5 à 7 selon l'univers, et diviser
        // par une constante rendrait deux passations incomparables.
        double sur6 = TaskSchedulingConfig.timeScore(5, 6);
        double sur7 = TaskSchedulingConfig.timeScore(5, 7);
        assertTrue(sur7 < sur6, "5/7 doit valoir moins que 5/6");
        assertEquals(2.5, sur6, 1e-9);
    }

    // ── Composante 3 : cohérence séquentielle ────────────────────────────────

    @Test
    void a_collision_costs_its_point() {
        assertEquals(1.0, TaskSchedulingConfig.coherenceScore(false, 0.0), 1e-9);
        assertEquals(9, scoring.scoreTaskScheduling(
            parfait(10, 10, 0, 6, 6, false, 0.0, 0, 0)).rawPoints());
    }

    @Test
    void dead_time_bands_follow_the_referential() {
        // < 10 % -> 1 pt · 10-25 % -> 0,5 · > 25 % -> 0
        assertEquals(2.0, TaskSchedulingConfig.coherenceScore(true, 0.09), 1e-9);
        assertEquals(1.5, TaskSchedulingConfig.coherenceScore(true, 0.20), 1e-9);
        assertEquals(1.5, TaskSchedulingConfig.coherenceScore(true, 0.25), 1e-9);
        assertEquals(1.0, TaskSchedulingConfig.coherenceScore(true, 0.26), 1e-9);
    }

    // ── Composante 4 : autorégulation ────────────────────────────────────────

    @Test
    void self_regulation_bands_follow_the_referential() {
        assertEquals(2.0, TaskSchedulingConfig.selfRegulationScore(1, 0, 1), 1e-9);
        assertEquals(1.0, TaskSchedulingConfig.selfRegulationScore(2, 0, 1), 1e-9);
        assertEquals(1.0, TaskSchedulingConfig.selfRegulationScore(3, 0, 1), 1e-9);
        assertEquals(0.0, TaskSchedulingConfig.selfRegulationScore(4, 0, 1), 1e-9);
    }

    @Test
    void too_many_reactive_corrections_cancel_the_component() {
        // Quatre corrections subies après alerte : 0 pt, quel que soit le total.
        // Corriger seulement sous alerte ne démontre pas la même autorégulation
        // que se relire de soi-même.
        assertEquals(0.0, TaskSchedulingConfig.selfRegulationScore(0, 4, 1), 1e-9);
        assertTrue(
            TaskSchedulingConfig.selfRegulationScore(4, 0, 1)
                >= TaskSchedulingConfig.selfRegulationScore(0, 4, 1),
            "à nombre égal, le proactif ne doit pas valoir moins que le réactif");
    }

    @Test
    void thresholds_scale_with_the_number_of_plannings() {
        // Les seuils du référentiel — 1 puis 3 — valent PAR planning, et le
        // client envoie la somme des manches. Sans mise à l'échelle, un joueur
        // qui se reprend une fois par manche cumulerait 3 corrections sur une
        // partie de trois plannings et tomberait déjà sous le plein score, alors
        // qu'il tient exactement la même conduite qu'un joueur noté 2/2 sur un
        // planning unique.
        assertEquals(2.0, TaskSchedulingConfig.selfRegulationScore(3, 0, 3), 1e-9);
        assertEquals(1.0, TaskSchedulingConfig.selfRegulationScore(4, 0, 3), 1e-9);
        assertEquals(1.0, TaskSchedulingConfig.selfRegulationScore(9, 0, 3), 1e-9);
        assertEquals(0.0, TaskSchedulingConfig.selfRegulationScore(10, 0, 3), 1e-9);
        assertEquals(0.0, TaskSchedulingConfig.selfRegulationScore(0, 10, 3), 1e-9);
    }

    @Test
    void a_missing_planning_count_keeps_the_single_planning_scale() {
        // Un client antérieur aux manches multiples n'envoie rien. Le VO ramène
        // alors à 1 : l'ancien barème, à l'identique.
        TaskSchedulingMetrics sansNombre = new TaskSchedulingMetrics(
            "restaurant", 10, 10, 0, 6, 6, true, 0.0, 2, 0, 0, null);

        assertEquals(1, sansNombre.levelsPlayed());
        assertEquals(
            TaskSchedulingConfig.selfRegulationScore(2, 0, 1),
            TaskSchedulingConfig.selfRegulationScore(
                sansNombre.proactiveAdjustments(),
                sansNombre.reactiveAdjustments(),
                sansNombre.levelsPlayed()),
            1e-9);
    }

    // ── Métrique diagnostique ────────────────────────────────────────────────

    @Test
    void planning_latency_never_touches_the_score() {
        // Le référentiel la veut au profil qualitatif, explicitement hors barème.
        Score sans = scoring.scoreTaskScheduling(parfait());
        Score avec = scoring.scoreTaskScheduling(new TaskSchedulingMetrics(
            "restaurant", 10, 10, 0, 6, 6, true, 0.0, 0, 0, 1, 45_000));

        assertEquals(sans.rawPoints(), avec.rawPoints());
    }

    // ── Invariants du contrat ────────────────────────────────────────────────

    @Test
    void incoherent_metrics_are_rejected_at_construction() {
        // Le VO refuse ce qu'aucune partie réelle ne peut produire, plutôt que
        // de le laisser fausser un score en silence.
        assertThrows(IllegalArgumentException.class, () -> new TaskSchedulingMetrics(
            "restaurant", 5, 9, 0, 6, 6, true, 0.0, 0, 0, 1, null),
            "plus d'arêtes respectées que d'arêtes");
        assertThrows(IllegalArgumentException.class, () -> new TaskSchedulingMetrics(
            "restaurant", 10, 10, 0, 6, 9, true, 0.0, 0, 0, 1, null),
            "plus de contraintes tenues que de contraintes");
        assertThrows(IllegalArgumentException.class, () -> new TaskSchedulingMetrics(
            "restaurant", 10, 10, 0, 6, 6, true, 1.4, 0, 0, 1, null),
            "ratio de temps mort hors [0,1]");
    }
}
