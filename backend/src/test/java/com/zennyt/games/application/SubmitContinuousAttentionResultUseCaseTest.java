package com.zennyt.games.application;

import com.zennyt.games.application.command.SubmitGameResultCommand;
import com.zennyt.games.application.usecase.SubmitGameResultUseCase;
import com.zennyt.games.domain.catalog.DecisionScenarioCatalog;
import com.zennyt.games.domain.event.GameResultRecordedEvent;
import com.zennyt.games.domain.model.GameSession;
import com.zennyt.games.domain.model.MiniGame;
import com.zennyt.games.domain.repository.ContinuousAttentionMetricsRepository;
import com.zennyt.games.domain.repository.CoordinationMetricsRepository;
import com.zennyt.games.domain.repository.DeviceCalibrationRepository;
import com.zennyt.games.domain.repository.EmotionalRadarAnswerRepository;
import com.zennyt.games.domain.repository.GameSessionRepository;
import com.zennyt.games.domain.repository.ObjectLocationMetricsRepository;
import com.zennyt.games.domain.service.PlanifikScoringService;
import com.zennyt.games.domain.vo.ContinuousAttentionMetrics;
import com.zennyt.games.domain.vo.ContinuousAttentionTrialMetric;
import com.zennyt.games.domain.vo.GameType;
import com.zennyt.games.domain.vo.Score;
import com.zennyt.games.domain.vo.SessionStatus;
import com.zennyt.games.support.ContinuousAttentionTestFixtures;
import com.zennyt.shared.application.exception.ForbiddenException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.context.ApplicationEventPublisher;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class SubmitContinuousAttentionResultUseCaseTest {

    private GameSessionRepository sessions;
    private ContinuousAttentionMetricsRepository rawMetrics;
    private ApplicationEventPublisher events;
    private SubmitGameResultUseCase useCase;

    @BeforeEach
    void setUp() {
        sessions = mock(GameSessionRepository.class);
        rawMetrics = mock(ContinuousAttentionMetricsRepository.class);
        events = mock(ApplicationEventPublisher.class);
        useCase = new SubmitGameResultUseCase(
            sessions,
            mock(DeviceCalibrationRepository.class),
            mock(EmotionalRadarAnswerRepository.class),
            rawMetrics,
            mock(CoordinationMetricsRepository.class),
            mock(ObjectLocationMetricsRepository.class),
            events,
            mock(DecisionScenarioCatalog.class));
        when(sessions.save(any(GameSession.class)))
            .thenAnswer(invocation -> invocation.getArgument(0));
    }

    @Test
    void validOwnerSubmissionPersistsRawAndAttemptAtomicallyThenPublishes() {
        UUID ownerId = UUID.randomUUID();
        GameSession session =
            GameSession.start(ownerId, GameType.CONTINUOUS_ATTENTION);
        ContinuousAttentionMetrics metrics =
            ContinuousAttentionTestFixtures.perfect(session.id());
        when(sessions.findByIdForUpdate(session.id())).thenReturn(Optional.of(session));

        SubmitGameResultUseCase.Outcome outcome = useCase.execute(
            command(session, ownerId, metrics));

        assertEquals(SessionStatus.COMPLETED, outcome.session().status());
        assertEquals(1, outcome.session().attempts().size());
        assertEquals(100, outcome.session().compositeRaw());
        assertTrue(outcome.continuousAttentionReport().sessionValid());
        verify(rawMetrics).replace(
            session.id(), metrics, outcome.continuousAttentionReport());
        verify(sessions).save(session);
        verify(events).publishEvent(any(GameResultRecordedEvent.class));
    }

    @Test
    void technicallyInvalidSubmissionIsAuditOnlyWithoutAttemptSaveOrEvent() {
        UUID ownerId = UUID.randomUUID();
        GameSession session =
            GameSession.start(ownerId, GameType.CONTINUOUS_ATTENTION);
        ContinuousAttentionMetrics valid =
            ContinuousAttentionTestFixtures.perfect(session.id());
        ContinuousAttentionTrialMetric first =
            valid.blocks().get(0).trials().get(0);
        ContinuousAttentionMetrics timingInvalid =
            ContinuousAttentionTestFixtures.replaceTrial(
                valid, 0, 0, withDisplayDuration(first, 791));
        when(sessions.findByIdForUpdate(session.id())).thenReturn(Optional.of(session));

        SubmitGameResultUseCase.Outcome outcome = useCase.execute(
            command(session, ownerId, timingInvalid));

        assertFalse(outcome.continuousAttentionReport().sessionValid());
        assertEquals("TIMING_DEVIATION",
            outcome.continuousAttentionReport().validityIssues().get(0));
        assertFalse(outcome.scoreBreakdown().lines().isEmpty(),
            "l'audit-only renvoie tout de même le breakdown descriptif");
        assertEquals(SessionStatus.IN_PROGRESS, outcome.session().status());
        assertTrue(outcome.session().attempts().isEmpty());
        verify(rawMetrics).replace(
            session.id(), timingInvalid, outcome.continuousAttentionReport());
        verify(sessions, never()).save(any());
        verify(events, never()).publishEvent(any());
    }

    @Test
    void foreignPlayerIsRejectedBeforeValidationOrAnyPersistence() {
        UUID ownerId = UUID.randomUUID();
        GameSession session =
            GameSession.start(ownerId, GameType.CONTINUOUS_ATTENTION);
        when(sessions.findByIdForUpdate(session.id())).thenReturn(Optional.of(session));

        assertThrows(ForbiddenException.class, () -> useCase.execute(
            command(session, UUID.randomUUID(),
                ContinuousAttentionTestFixtures.perfect(session.id()))));

        verify(rawMetrics, never()).replace(any(), any(), any());
        verify(sessions, never()).save(any());
        verify(events, never()).publishEvent(any());
    }

    @Test
    void deterministicMismatchIsRejectedBeforeRawPersistence() {
        UUID ownerId = UUID.randomUUID();
        GameSession session =
            GameSession.start(ownerId, GameType.CONTINUOUS_ATTENTION);
        when(sessions.findByIdForUpdate(session.id())).thenReturn(Optional.of(session));
        ContinuousAttentionMetrics metricsForAnotherSession =
            ContinuousAttentionTestFixtures.perfect(UUID.randomUUID());

        assertThrows(IllegalArgumentException.class, () -> useCase.execute(
            command(session, ownerId, metricsForAnotherSession)));

        verify(rawMetrics, never()).replace(any(), any(), any());
        verify(sessions, never()).save(any());
        verify(events, never()).publishEvent(any());
    }

    @Test
    void duplicateAfterValidatedAttemptCannotOverwriteRawOrRepublish() {
        UUID ownerId = UUID.randomUUID();
        GameSession session =
            GameSession.start(ownerId, GameType.CONTINUOUS_ATTENTION);
        session.recordResult(
            MiniGame.CONTINUOUS_ATTENTION_CORE,
            new Score(100, 100, "Descriptive — provisional"),
            new PlanifikScoringService());
        session.clearEvents();
        when(sessions.findByIdForUpdate(session.id())).thenReturn(Optional.of(session));

        assertThrows(IllegalStateException.class, () -> useCase.execute(
            command(session, ownerId,
                ContinuousAttentionTestFixtures.perfect(session.id()))));

        verify(rawMetrics, never()).replace(any(), any(), any());
        verify(sessions, never()).save(any());
        verify(events, never()).publishEvent(any());
    }

    private static SubmitGameResultCommand command(
            GameSession session,
            UUID playerId,
            ContinuousAttentionMetrics metrics) {
        return new SubmitGameResultCommand(
            session.id(), playerId, MiniGame.CONTINUOUS_ATTENTION_CORE,
            metrics, null);
    }

    private static ContinuousAttentionTrialMetric withDisplayDuration(
            ContinuousAttentionTrialMetric t, int duration) {
        return new ContinuousAttentionTrialMetric(
            t.trialIndex(), t.previousLetter(), t.currentLetter(),
            t.responseCode(), t.correct(), t.latencyMs(),
            t.scheduledOnsetMs(), t.actualOnsetMs(), t.responseTimestampMs(),
            duration, t.actualIsiDurationMs(), t.inputSource(),
            t.extraResponseCount(), t.interrupted());
    }
}
