package com.zennyt.games.domain;

import com.zennyt.games.domain.event.GameResultRecordedEvent;
import com.zennyt.games.domain.model.GameSession;
import com.zennyt.games.domain.model.MiniGame;
import com.zennyt.games.domain.service.PlanifikScoringService;
import com.zennyt.games.domain.vo.GameType;
import com.zennyt.games.domain.vo.PlanifikMetrics;
import com.zennyt.games.domain.vo.Score;
import org.junit.jupiter.api.Test;

import java.util.UUID;

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
    void recording_a_foreign_minigame_is_rejected() {
        GameSession session = GameSession.start(UUID.randomUUID(), GameType.MEMORY_QUEST);
        Score score = new Score(10, 10, "Bon à excellent");

        // OPTIMAL_PATH appartient à PLANIFIK, pas à MEMORY_QUEST
        assertThrows(IllegalArgumentException.class,
            () -> session.recordResult(MiniGame.OPTIMAL_PATH, score, scoring));
    }

    @Test
    void session_completes_and_emits_event_after_all_minigames() {
        GameSession session = GameSession.start(UUID.randomUUID(), GameType.PLANIFIK);
        Score full = new Score(10, 10, "Bon à excellent");

        session.recordResult(MiniGame.OPTIMAL_PATH, full, scoring);
        assertTrue(session.domainEvents().isEmpty(), "pas encore terminée");

        session.recordResult(MiniGame.TASK_SCHEDULING, full, scoring);
        session.recordResult(MiniGame.PREVISION_PUZZLE, full, scoring);

        assertEquals(30, session.compositeRaw());
        assertEquals(1, session.domainEvents().size());
        assertInstanceOf(GameResultRecordedEvent.class, session.domainEvents().get(0));
    }
}
