package com.zennyt.games.domain;

import com.zennyt.games.domain.event.GameResultRecordedEvent;
import com.zennyt.games.domain.model.GameSession;
import com.zennyt.games.domain.model.MiniGame;
import com.zennyt.games.domain.service.PlanifikScoringService;
import com.zennyt.games.domain.vo.CostlyZonesAvoided;
import com.zennyt.games.domain.vo.GameType;
import com.zennyt.games.domain.vo.MoveFastMetrics;
import com.zennyt.games.domain.vo.MoveFastResponse;
import com.zennyt.games.domain.vo.MoveFastRule;
import com.zennyt.games.domain.vo.OptimalPathLevel;
import com.zennyt.games.domain.vo.PlanifikMetrics;
import com.zennyt.games.domain.vo.Score;
import com.zennyt.games.domain.vo.SecondaryObjectivesReached;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Tests unitaires du domaine Games — aucun contexte Spring, aucune base.
 * Bénéfice d'un domaine pur : rapide et isolé.
 */
class GameSessionTest {

    private final PlanifikScoringService scoring = new PlanifikScoringService();

    @Test
    void optimalPath_perfect_run_scores_full_marks() {
        // chemin optimal, 1 essai, zones évitées, objectif atteint => 4+3+2+1 = 10
        Score score = scoring.scoreOptimalPath(
            new PlanifikMetrics(1, 10, 10, true, 1));

        assertEquals(10, score.rawPoints());
        assertEquals("Bon à excellent", score.level());
    }

    @Test
    void optimalPath_deviation_over_10pct_loses_the_4_points() {
        // pathLength 13 vs optimal 10 => 30% d'écart, on perd les 4 pts du chemin
        Score score = scoring.scoreOptimalPath(
            new PlanifikMetrics(1, 13, 10, true, 0));

        assertEquals(5, score.rawPoints()); // 0 + 3 (1 essai) + 2 (zones) + 0
    }

    @Test
    void optimalPath_multi_level_score_is_rounded_average_over_10() {
        // Niveau 0 parfait = 10 ; niveau 1 : écart>10%(0) + 3 essais(1) + NONE(0) + NO(0) = 1.
        // Moyenne (10 + 1) / 2 = 5.5 → arrondi 6.
        PlanifikMetrics m = new PlanifikMetrics(List.of(
            new OptimalPathLevel(0, 1, 10, 10,
                CostlyZonesAvoided.TOTAL, SecondaryObjectivesReached.YES),
            new OptimalPathLevel(1, 3, 20, 10,
                CostlyZonesAvoided.NONE, SecondaryObjectivesReached.NO)));

        Score score = scoring.scoreOptimalPath(m);

        assertEquals(6, score.rawPoints());
        assertEquals(10, score.maxPoints());
    }

    @Test
    void optimalPath_level_partial_enums_score_between_none_and_full() {
        // chemin optimal(4) + 2 essais(2) + PARTIAL zones(1) + PARTIAL objectifs(0) = 7.
        PlanifikMetrics m = new PlanifikMetrics(List.of(
            new OptimalPathLevel(0, 2, 10, 10,
                CostlyZonesAvoided.PARTIAL, SecondaryObjectivesReached.PARTIAL)));

        Score score = scoring.scoreOptimalPath(m);

        assertEquals(7, score.rawPoints());
    }

    @Test
    void moveFast_four_correct_responses_increase_multiplier_and_bonus() {
        Score score = scoring.scoreMoveFast(
            moveFast(List.of(true, true, true, true)));

        assertEquals(700, score.rawPoints()); // 4 × 50 at x1 + final bonus 250 × x2
        assertEquals(700, score.maxPoints());
        assertEquals("Excellent", score.level());
    }

    @Test
    void moveFast_wrong_response_resets_partial_counter_without_lowering_multiplier() {
        Score score = scoring.scoreMoveFast(
            moveFast(List.of(true, true, false, true)));

        assertEquals(400, score.rawPoints()); // 3 correct at x1 + final bonus 250 × x1
        assertEquals(700, score.maxPoints());
        assertEquals("Moyen faible", score.level());
    }

    @Test
    void moveFast_excludes_practice_trials_from_scoring() {
        // 3 essais d'échauffement corrects + 4 essais notés corrects.
        // Le score ne doit compter QUE les 4 essais notés (= 700), pas les 7.
        MoveFastResponse practice = new MoveFastResponse(
            true, true, 400, MoveFastRule.ORIENTATION, false, false);
        List<MoveFastResponse> responses = new java.util.ArrayList<>();
        responses.add(practice);
        responses.add(practice);
        responses.add(practice);
        responses.addAll(scoredResponses(List.of(true, true, true, true)));

        Score score = scoring.scoreMoveFast(new MoveFastMetrics(3, responses));

        assertEquals(700, score.rawPoints());
        assertEquals("Excellent", score.level());
    }

    @Test
    void moveFast_session_completes_after_single_core_game() {
        GameSession session = GameSession.start(UUID.randomUUID(), GameType.MOVE_FAST);
        Score score = scoring.scoreMoveFast(
            moveFast(List.of(true, true, true, true)));

        session.recordResult(MiniGame.MOVE_FAST_CORE, score, scoring);

        assertEquals(700, session.compositeRaw());
        assertEquals(700, session.compositeMax());
        assertEquals(1, session.domainEvents().size());
        assertInstanceOf(GameResultRecordedEvent.class, session.domainEvents().get(0));
    }

    @Test
    void recording_a_foreign_minigame_is_rejected() {
        GameSession session = GameSession.start(UUID.randomUUID(), GameType.MEMORY_QUEST);
        Score score = new Score(10, 10, "Bon à excellent");

        // OPTIMAL_PATH appartient à PLANIFIK, pas à MEMORY_QUEST
        assertThrows(IllegalArgumentException.class,
            () -> session.recordResult(MiniGame.OPTIMAL_PATH, score, scoring));
    }

    @Test
    void planifik_session_completes_and_emits_event_after_the_playable_minigames() {
        // Transitoire : TASK_SCHEDULING n'a pas de barème, la complétion se calcule
        // donc sur OPTIMAL_PATH + PREVISION_PUZZLE uniquement (voir MiniGame.isPlayable()).
        GameSession session = GameSession.start(UUID.randomUUID(), GameType.PLANIFIK);
        Score full = new Score(10, 10, "Bon à excellent");

        session.recordResult(MiniGame.OPTIMAL_PATH, full, scoring);
        assertTrue(session.domainEvents().isEmpty(), "pas encore terminée");

        session.recordResult(MiniGame.PREVISION_PUZZLE, full, scoring);

        assertEquals(20, session.compositeRaw());
        assertEquals(20, session.compositeMax());
        assertEquals(1, session.domainEvents().size());
        assertInstanceOf(GameResultRecordedEvent.class, session.domainEvents().get(0));
    }

    @Test
    void recording_a_non_playable_minigame_is_rejected() {
        // TASK_SCHEDULING appartient à PLANIFIK mais n'est pas encore jouable.
        GameSession session = GameSession.start(UUID.randomUUID(), GameType.PLANIFIK);
        Score full = new Score(10, 10, "Bon à excellent");

        assertThrows(IllegalArgumentException.class,
            () -> session.recordResult(MiniGame.TASK_SCHEDULING, full, scoring));
    }

    /** Métriques Move Fast sans échauffement, règle Orientation, temps neutres. */
    private static MoveFastMetrics moveFast(List<Boolean> outcomes) {
        return new MoveFastMetrics(0, scoredResponses(outcomes));
    }

    private static List<MoveFastResponse> scoredResponses(List<Boolean> outcomes) {
        return IntStream.range(0, outcomes.size())
            .mapToObj(i -> new MoveFastResponse(
                false, outcomes.get(i), 500, MoveFastRule.ORIENTATION, false, false))
            .collect(Collectors.toList());
    }
}
