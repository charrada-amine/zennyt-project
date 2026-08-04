package com.zennyt.games.domain;

import com.zennyt.games.domain.config.ReflectivePauseConfig;
import com.zennyt.games.domain.model.GameSession;
import com.zennyt.games.domain.model.MiniGame;
import com.zennyt.games.domain.service.PlanifikScoringService;
import com.zennyt.games.domain.service.ReflectivePauseScoringService;
import com.zennyt.games.domain.vo.GameType;
import com.zennyt.games.domain.vo.ReflectivePauseMetrics;
import com.zennyt.games.domain.vo.ReflectivePauseMomentMetric;
import com.zennyt.games.domain.vo.ReflectivePauseReport;
import com.zennyt.games.domain.vo.ReflectivePauseResponseType;
import com.zennyt.games.domain.vo.Score;
import com.zennyt.games.domain.vo.SessionStatus;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Barème « Reflective Pause » — Java pur, sans Spring.
 */
class ReflectivePauseScoringTest {

    private final ReflectivePauseScoringService scoring =
        new ReflectivePauseScoringService();

    private static ReflectivePauseResponseType recommended(int index) {
        return switch (index) {
            case 1, 5, 9 -> ReflectivePauseResponseType.BREATHE_ANALYZE;
            case 2, 4, 10 -> ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION;
            case 3, 7 -> ReflectivePauseResponseType.WAIT;
            case 6, 8 -> ReflectivePauseResponseType.REFORMULATE_CALMLY;
            default -> throw new IllegalArgumentException();
        };
    }

    private static ReflectivePauseMetrics perfectMetrics() {
        List<ReflectivePauseMomentMetric> moments = new ArrayList<>();
        for (int i = 1; i <= ReflectivePauseConfig.TOTAL_MOMENTS; i++) {
            moments.add(new ReflectivePauseMomentMetric(
                "PRESSURE_%02d".formatted(i),
                recommended(i),
                4_000,
                true));
        }
        return new ReflectivePauseMetrics(moments);
    }

    @Test
    @DisplayName("10 pauses + 10 réponses recommandées → 3 + 4 + 3 = 10/10")
    void perfectJourneyScoresTen() {
        Score score = scoring.score(perfectMetrics());
        ReflectivePauseReport report = scoring.report(perfectMetrics());

        assertThat(score.rawPoints()).isEqualTo(10);
        assertThat(score.maxPoints()).isEqualTo(10);
        assertThat(score.level()).isEqualTo("Very good self-control");
        assertThat(report.controlledReactionTimeScore()).isEqualTo(3.0);
        assertThat(report.nonImpulsiveResponsesScore()).isEqualTo(4.0);
        assertThat(report.abilityToStepBackScore()).isEqualTo(3.0);
        assertThat(report.impulsiveChoiceCount()).isZero();
    }

    @Test
    @DisplayName("8 pauses, 9 non-impulsives, 7 recommandées → 2.4 + 3.6 + 2.1 → 8/10")
    void mixedJourneyUsesWeightedRatesAndRoundsOnce() {
        List<ReflectivePauseMomentMetric> moments =
            new ArrayList<>(perfectMetrics().moments());
        moments.set(0, new ReflectivePauseMomentMetric(
            "PRESSURE_01",
            ReflectivePauseResponseType.RESPOND_IMPULSIVELY,
            2_000,
            false));
        moments.set(7, new ReflectivePauseMomentMetric(
            "PRESSURE_08",
            ReflectivePauseResponseType.WAIT,
            2_000,
            false));
        moments.set(9, new ReflectivePauseMomentMetric(
            "PRESSURE_10",
            ReflectivePauseResponseType.WAIT,
            4_000,
            true));
        ReflectivePauseMetrics metrics = new ReflectivePauseMetrics(moments);

        ReflectivePauseReport report = scoring.report(metrics);
        Score score = scoring.score(metrics);

        assertThat(report.controlledReactionTimeScore()).isEqualTo(2.4);
        assertThat(report.nonImpulsiveResponsesScore()).isEqualTo(3.6);
        assertThat(report.abilityToStepBackScore()).isEqualTo(2.1);
        assertThat(score.rawPoints()).isEqualTo(8);
    }

    @Test
    @DisplayName("Le booléen du timer ne peut pas contredire le temps brut")
    void timerFlagMustMatchResponseTime() {
        assertThatThrownBy(() -> new ReflectivePauseMomentMetric(
            "PRESSURE_01",
            ReflectivePauseResponseType.BREATHE_ANALYZE,
            2_999,
            true))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("incohérent");
    }

    @Test
    @DisplayName("Les 10 identifiants du catalogue sont obligatoires et uniques")
    void completeUniqueCatalogIsRequired() {
        List<ReflectivePauseMomentMetric> duplicated =
            new ArrayList<>(perfectMetrics().moments());
        duplicated.set(9, duplicated.get(0));

        assertThatThrownBy(() -> new ReflectivePauseMetrics(duplicated))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("dupliqué");
    }

    @Test
    @DisplayName("Emotional Regulation : Radar /27 + Reflective /10 → composite provisoire /37")
    void emotionalRegulationCompletesAfterBothMiniGames() {
        GameSession session = GameSession.start(
            UUID.randomUUID(), GameType.EMOTIONAL_REGULATION);
        PlanifikScoringService global = new PlanifikScoringService();

        session.recordResult(
            MiniGame.EMOTIONAL_RADAR_CORE,
            new Score(27, 27, "Excellent"),
            global);

        assertThat(session.status()).isEqualTo(SessionStatus.IN_PROGRESS);
        assertThat(session.compositeRaw()).isEqualTo(27);
        assertThat(session.compositeMax()).isEqualTo(37);
        assertThat(session.normalizedScore()).isLessThanOrEqualTo(100.0);

        session.recordResult(
            MiniGame.REFLECTIVE_PAUSE_CORE,
            new Score(8, 10, "Very good self-control"),
            global);

        assertThat(session.status()).isEqualTo(SessionStatus.COMPLETED);
        assertThat(session.compositeRaw()).isEqualTo(35);
        assertThat(session.compositeMax()).isEqualTo(37);
        // F14 — un événement par mini-jeu : le premier portait une couverture de 50 %
        // (1 des 2 mini-jeux du module), le second la porte à 100 %.
        assertThat(session.domainEvents()).hasSize(2);
        var premier = (com.zennyt.games.domain.event.GameResultRecordedEvent) session.domainEvents().get(0);
        var second = (com.zennyt.games.domain.event.GameResultRecordedEvent) session.domainEvents().get(1);
        assertThat(premier.coverageRatio()).isEqualTo(50);
        assertThat(second.coverageRatio()).isEqualTo(100);
    }
}
