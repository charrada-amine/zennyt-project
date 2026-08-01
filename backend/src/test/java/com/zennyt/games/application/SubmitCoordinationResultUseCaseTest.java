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
import com.zennyt.games.domain.vo.CoordinationMetrics;
import com.zennyt.games.domain.vo.GameType;
import com.zennyt.games.domain.vo.SessionStatus;
import com.zennyt.games.support.CoordinationTestFixtures;
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

class SubmitCoordinationResultUseCaseTest {

    private GameSessionRepository sessions;
    private CoordinationMetricsRepository rawMetrics;
    private ApplicationEventPublisher events;
    private SubmitGameResultUseCase useCase;

    @BeforeEach
    void setUp() {
        sessions = mock(GameSessionRepository.class);
        rawMetrics = mock(CoordinationMetricsRepository.class);
        events = mock(ApplicationEventPublisher.class);
        useCase = new SubmitGameResultUseCase(
            sessions,
            mock(DeviceCalibrationRepository.class),
            mock(EmotionalRadarAnswerRepository.class),
            mock(ContinuousAttentionMetricsRepository.class),
            rawMetrics,
            events,
            mock(DecisionScenarioCatalog.class));
        when(sessions.save(any(GameSession.class)))
            .thenAnswer(invocation -> invocation.getArgument(0));
    }

    @Test
    void validOwnerSubmissionPersistsRawAttemptAndPublishesServerScore() {
        UUID ownerId = UUID.randomUUID();
        GameSession session =
            GameSession.start(ownerId, GameType.VISUOMOTOR_COORDINATION);
        CoordinationMetrics metrics = CoordinationTestFixtures.perfect();
        when(sessions.findByIdForUpdate(session.id())).thenReturn(Optional.of(session));
        // L'adaptateur de production renvoie une copie réhydratée sans événements.
        when(sessions.save(session)).thenAnswer(invocation -> rehydrated(session));

        SubmitGameResultUseCase.Outcome outcome = useCase.execute(
            command(session, ownerId, metrics));

        assertEquals(SessionStatus.COMPLETED, outcome.session().status());
        assertEquals(1, outcome.session().attempts().size());
        assertEquals(100, outcome.session().compositeRaw());
        assertTrue(outcome.coordinationReport().sessionValid());
        verify(rawMetrics).replace(
            session.id(), metrics, outcome.coordinationReport());
        verify(sessions).save(session);
        verify(events).publishEvent(any(GameResultRecordedEvent.class));
    }

    @Test
    void technicallyInvalidSubmissionIsAuditOnlyAndRetryable() {
        UUID ownerId = UUID.randomUUID();
        GameSession session =
            GameSession.start(ownerId, GameType.VISUOMOTOR_COORDINATION);
        CoordinationMetrics metrics =
            CoordinationTestFixtures.withTechnicalState(true, false, 1, 0);
        when(sessions.findByIdForUpdate(session.id())).thenReturn(Optional.of(session));

        SubmitGameResultUseCase.Outcome outcome = useCase.execute(
            command(session, ownerId, metrics));

        assertFalse(outcome.coordinationReport().technicalValid());
        assertFalse(outcome.coordinationReport().sessionValid());
        assertEquals(SessionStatus.IN_PROGRESS, outcome.session().status());
        assertTrue(outcome.session().attempts().isEmpty());
        verify(rawMetrics).replace(
            session.id(), metrics, outcome.coordinationReport());
        verify(sessions, never()).save(any());
        verify(events, never()).publishEvent(any());
    }

    @Test
    void foreignPlayerIsRejectedBeforeRawPersistenceOrScoringSideEffects() {
        UUID ownerId = UUID.randomUUID();
        GameSession session =
            GameSession.start(ownerId, GameType.VISUOMOTOR_COORDINATION);
        when(sessions.findByIdForUpdate(session.id())).thenReturn(Optional.of(session));

        assertThrows(ForbiddenException.class, () -> useCase.execute(
            command(session, UUID.randomUUID(), CoordinationTestFixtures.perfect())));

        verify(rawMetrics, never()).replace(any(), any(), any());
        verify(sessions, never()).save(any());
        verify(events, never()).publishEvent(any());
    }

    @Test
    void coordinationPayloadCannotBeSubmittedToAnotherGameType() {
        UUID ownerId = UUID.randomUUID();
        GameSession session = GameSession.start(ownerId, GameType.MOVE_FAST);
        when(sessions.findByIdForUpdate(session.id())).thenReturn(Optional.of(session));

        assertThrows(IllegalArgumentException.class, () -> useCase.execute(
            command(session, ownerId, CoordinationTestFixtures.perfect())));

        verify(rawMetrics, never()).replace(any(), any(), any());
        verify(sessions, never()).save(any());
    }

    private static SubmitGameResultCommand command(GameSession session,
                                                   UUID playerId,
                                                   CoordinationMetrics metrics) {
        return new SubmitGameResultCommand(
            session.id(), playerId, MiniGame.COORDINATION_TRACKING_CORE,
            metrics, null);
    }

    private static GameSession rehydrated(GameSession session) {
        return GameSession.rehydrate(
            session.id(), session.playerId(), session.gameType(), session.status(),
            session.attempts(), session.startedAt(), session.completedAt());
    }
}
