package com.zennyt.games.domain;

import com.zennyt.games.domain.config.MoveFastConfig;
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
import com.zennyt.games.domain.vo.SessionStatus;
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
    void optimalPath_failed_level_scores_one_over_ten() {
        // Niveau échoué (3 chemins ratés) : chemin jamais atteint (pathLength 0 →
        // écart 100 % → 0/4), 3 essais → 1/3, zones NONE → 0/2, objectif NO → 0/1
        // ⇒ 1/10. Parité avec le mock mobile (games_mock_repository.dart).
        PlanifikMetrics m = new PlanifikMetrics(List.of(
            new OptimalPathLevel(0, 3, 0, 9,
                CostlyZonesAvoided.NONE, SecondaryObjectivesReached.NO)));

        Score score = scoring.scoreOptimalPath(m);

        assertEquals(1, score.rawPoints());
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
    void moveFast_score_is_independent_of_session_end_mode() {
        // Le barème (rejeu) ne consulte JAMAIS SessionEndMode : pour une même
        // séquence de réponses, le score est identique quel que soit le mode de
        // fin. Le mode ne change que la DURÉE de jeu / l'anti-triche, pas le score.
        List<Boolean> outcomes = List.of(true, true, true, true, false, true);

        Score score = scoring.scoreMoveFast(moveFast(outcomes));

        // Référence = rejeu pur du barème (aucune notion de mode).
        assertEquals(MoveFastConfig.replay(outcomes).total(), score.rawPoints());
        assertEquals(
            MoveFastConfig.replay(List.of(true, true, true, true, true, true)).total(),
            score.maxPoints());
        // Le mode n'intervient QUE dans la plausibilité (anti-triche), pas le score.
        assertNull(MoveFastConfig.plausibilityViolation(
            MoveFastConfig.SessionEndMode.FIXED_BUDGET, outcomes.size(), 3000));
        assertNull(MoveFastConfig.plausibilityViolation(
            MoveFastConfig.SessionEndMode.REACH_MAX_MULTIPLIER, 10_000, 10_000_000L));
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
    void continuousAttention_is_separate_and_completes_on_its_single_core_game() {
        GameSession session =
            GameSession.start(UUID.randomUUID(), GameType.CONTINUOUS_ATTENTION);
        Score score = new Score(84, 100, "Descriptive — provisional");

        session.recordResult(MiniGame.CONTINUOUS_ATTENTION_CORE, score, scoring);

        assertEquals(SessionStatus.COMPLETED, session.status());
        assertEquals(84, session.compositeRaw());
        assertEquals(100, session.compositeMax());
        assertEquals(1, session.domainEvents().size());
        GameResultRecordedEvent event =
            assertInstanceOf(GameResultRecordedEvent.class, session.domainEvents().get(0));
        assertEquals(GameType.CONTINUOUS_ATTENTION, event.gameType());
        assertEquals("Descriptive — provisional", event.level());
    }

    @Test
    void visuomotorCoordination_isSeparateAndDoesNotChangeMoveFastComposition() {
        GameSession coordination = GameSession.start(
            UUID.randomUUID(), GameType.VISUOMOTOR_COORDINATION);
        assertEquals(List.of(MiniGame.COORDINATION_TRACKING_CORE),
            coordination.expectedMiniGames());

        coordination.recordResult(
            MiniGame.COORDINATION_TRACKING_CORE,
            new Score(73, 100, "Descriptive — provisional"),
            scoring);

        assertEquals(SessionStatus.COMPLETED, coordination.status());
        assertEquals(73, coordination.compositeRaw());
        assertEquals(100, coordination.compositeMax());
        assertEquals(List.of(MiniGame.MOVE_FAST_CORE),
            GameSession.start(UUID.randomUUID(), GameType.MOVE_FAST)
                .expectedMiniGames());
    }

    @Test
    void visuospatialMemory_isSeparateAndDoesNotChangeMemoryQuestComposition() {
        GameSession objectLocation = GameSession.start(
            UUID.randomUUID(), GameType.VISUOSPATIAL_MEMORY);
        assertEquals(List.of(MiniGame.OBJECT_LOCATION_BINDING_CORE),
            objectLocation.expectedMiniGames());
        assertEquals(List.of(MiniGame.MEMORY_QUEST_CORE),
            GameSession.start(UUID.randomUUID(), GameType.MEMORY_QUEST)
                .expectedMiniGames());
        assertEquals("Descriptive — provisional",
            scoring.interpretGlobal(GameType.VISUOSPATIAL_MEMORY, 72, 72.0));
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
    void planifik_session_completes_on_three_minigames_with_composite_over_30() {
        // Les 3 mini-jeux Planifik sont jouables → la session se complète sur
        // OPTIMAL_PATH + TASK_SCHEDULING + PREVISION_PUZZLE et le profil est /30.
        GameSession session = GameSession.start(UUID.randomUUID(), GameType.PLANIFIK);
        Score full = new Score(10, 10, "Bon à excellent");

        // F14 — un événement est désormais émis à CHAQUE mini-jeu, avec la couverture
        // courante. Avant, une session partielle n'émettait rien : le candidat n'avait
        // aucun score tant qu'il n'avait pas tout terminé (CdC §3.3, qui prévoit une
        // décote de couverture, pas une disparition).
        session.recordResult(MiniGame.OPTIMAL_PATH, full, scoring);
        assertEquals(1, session.domainEvents().size(), "émis dès le 1er mini-jeu");
        assertEquals(33, event(session, 0).coverageRatio(), "1/3 joué");
        assertEquals(100.0, event(session, 0).normalizedScore(),
            "sans faute sur ce qui a été joué : la couverture porte l'incomplétude, pas le score");

        session.recordResult(MiniGame.TASK_SCHEDULING, full, scoring);
        assertEquals(2, session.domainEvents().size());
        assertEquals(67, event(session, 1).coverageRatio(), "2/3 joué");
        assertNotEquals(SessionStatus.COMPLETED, session.status(), "pas encore terminée (2/3)");

        session.recordResult(MiniGame.PREVISION_PUZZLE, full, scoring);

        assertEquals(SessionStatus.COMPLETED, session.status());
        assertEquals(30, session.compositeRaw());
        assertEquals(30, session.compositeMax());
        assertEquals(3, session.domainEvents().size());
        GameResultRecordedEvent event = event(session, 2);
        assertEquals(30, event.compositeRaw());
        assertEquals(30, event.compositeMax());
        assertEquals(100, event.coverageRatio(), "module entièrement couvert");
    }

    private static GameResultRecordedEvent event(GameSession session, int index) {
        return assertInstanceOf(GameResultRecordedEvent.class, session.domainEvents().get(index));
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
