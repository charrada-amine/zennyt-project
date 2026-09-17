package com.zennyt.games.application;

import com.zennyt.games.application.command.SubmitGameResultCommand;
import com.zennyt.games.application.usecase.SubmitGameResultUseCase;
import com.zennyt.games.domain.catalog.DecisionFormCatalog;
import com.zennyt.games.domain.catalog.DecisionScenarioCatalog;
import com.zennyt.games.domain.catalog.StrategicChoicesCatalog;
import com.zennyt.games.domain.model.CatalogGame;
import com.zennyt.games.domain.model.GameSession;
import com.zennyt.games.domain.model.MiniGame;
import com.zennyt.games.domain.repository.ContinuousAttentionMetricsRepository;
import com.zennyt.games.domain.repository.CoordinationMetricsRepository;
import com.zennyt.games.domain.repository.DeviceCalibrationRepository;
import com.zennyt.games.domain.repository.EmotionalRadarAnswerRepository;
import com.zennyt.games.domain.repository.GameCompletionRepository;
import com.zennyt.games.domain.repository.GameSessionRepository;
import com.zennyt.games.domain.repository.ObjectLocationMetricsRepository;
import com.zennyt.games.domain.vo.ContinuousAttentionMetrics;
import com.zennyt.games.domain.vo.ContinuousAttentionTrialMetric;
import com.zennyt.games.domain.vo.GameType;
import com.zennyt.games.support.ContinuousAttentionTestFixtures;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.context.ApplicationEventPublisher;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/** La soumission d'une partie fait progresser la couverture du catalogue. */
class GamesProgressRecordingTest {

    private GameSessionRepository sessions;
    private GameCompletionRepository completions;
    private SubmitGameResultUseCase useCase;

    @BeforeEach
    void setUp() {
        sessions = mock(GameSessionRepository.class);
        completions = mock(GameCompletionRepository.class);
        useCase = new SubmitGameResultUseCase(
            sessions,
            mock(DeviceCalibrationRepository.class),
            mock(EmotionalRadarAnswerRepository.class),
            mock(ContinuousAttentionMetricsRepository.class),
            mock(CoordinationMetricsRepository.class),
            mock(ObjectLocationMetricsRepository.class),
            mock(ApplicationEventPublisher.class),
            mock(DecisionScenarioCatalog.class),
            mock(DecisionFormCatalog.class),
            mock(StrategicChoicesCatalog.class));
        useCase.setCompletions(completions);
        when(sessions.save(any(GameSession.class)))
            .thenAnswer(invocation -> invocation.getArgument(0));
    }

    @Test
    void aRecordedResultCompletesItsCatalogGame() {
        UUID player = UUID.randomUUID();
        GameSession session = GameSession.start(player, GameType.CONTINUOUS_ATTENTION);
        when(sessions.findByIdForUpdate(session.id())).thenReturn(Optional.of(session));

        useCase.execute(command(session, player,
            ContinuousAttentionTestFixtures.perfect(session.id())));

        verify(completions).recordCompletion(
            eq(player), eq(CatalogGame.CONTINUOUS_ATTENTION), any(Instant.class));
    }

    @Test
    void anAuditOnlyInvalidRunDoesNotCount() {
        UUID player = UUID.randomUUID();
        GameSession session = GameSession.start(player, GameType.CONTINUOUS_ATTENTION);
        when(sessions.findByIdForUpdate(session.id())).thenReturn(Optional.of(session));
        ContinuousAttentionMetrics valid =
            ContinuousAttentionTestFixtures.perfect(session.id());
        ContinuousAttentionTrialMetric t = valid.blocks().get(0).trials().get(0);
        ContinuousAttentionMetrics invalid = ContinuousAttentionTestFixtures.replaceTrial(
            valid, 0, 0, new ContinuousAttentionTrialMetric(
                t.trialIndex(), t.previousLetter(), t.currentLetter(),
                t.responseCode(), t.correct(), t.latencyMs(),
                t.scheduledOnsetMs(), t.actualOnsetMs(), t.responseTimestampMs(),
                791, t.actualIsiDurationMs(), t.inputSource(),
                t.extraResponseCount(), t.interrupted()));

        useCase.execute(command(session, player, invalid));

        verify(completions, never()).recordCompletion(any(), any(), any());
    }

    private static SubmitGameResultCommand command(
            GameSession session, UUID player, ContinuousAttentionMetrics metrics) {
        return new SubmitGameResultCommand(
            session.id(), player, MiniGame.CONTINUOUS_ATTENTION_CORE, metrics, null);
    }
}
