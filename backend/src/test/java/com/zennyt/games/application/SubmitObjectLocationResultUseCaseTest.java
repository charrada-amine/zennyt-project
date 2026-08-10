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
import com.zennyt.games.domain.vo.GameType;
import com.zennyt.games.domain.vo.ObjectLocationCompletionReason;
import com.zennyt.games.domain.vo.ObjectLocationMetrics;
import com.zennyt.games.domain.vo.SessionStatus;
import com.zennyt.games.support.ObjectLocationTestFixtures;
import com.zennyt.shared.application.exception.ForbiddenException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.context.ApplicationEventPublisher;

import java.util.List;
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

class SubmitObjectLocationResultUseCaseTest {

    private GameSessionRepository sessions;
    private ObjectLocationMetricsRepository rawMetrics;
    private ApplicationEventPublisher events;
    private SubmitGameResultUseCase useCase;

    @BeforeEach
    void setUp() {
        sessions = mock(GameSessionRepository.class);
        rawMetrics = mock(ObjectLocationMetricsRepository.class);
        events = mock(ApplicationEventPublisher.class);
        useCase = new SubmitGameResultUseCase(
            sessions,
            mock(DeviceCalibrationRepository.class),
            mock(EmotionalRadarAnswerRepository.class),
            mock(ContinuousAttentionMetricsRepository.class),
            mock(CoordinationMetricsRepository.class),
            rawMetrics,
            events,
            mock(DecisionScenarioCatalog.class));
        when(sessions.save(any(GameSession.class)))
            .thenAnswer(invocation -> invocation.getArgument(0));
    }

    @Test
    void validOwnerSubmissionPersistsAttemptButDoesNotPublishProvisionalFitEvent() {
        UUID ownerId = UUID.randomUUID();
        GameSession session = GameSession.rehydrate(
            ObjectLocationTestFixtures.SESSION_ID, ownerId,
            GameType.VISUOSPATIAL_MEMORY, SessionStatus.IN_PROGRESS,
            List.of(), java.time.Instant.now(), null);
        ObjectLocationMetrics metrics =
            ObjectLocationTestFixtures.perfect(session.id());
        when(sessions.findByIdForUpdate(session.id())).thenReturn(Optional.of(session));

        SubmitGameResultUseCase.Outcome outcome = useCase.execute(
            command(session, ownerId, metrics));

        assertEquals(SessionStatus.COMPLETED, outcome.session().status());
        assertEquals(1, outcome.session().attempts().size());
        assertEquals(100, outcome.session().compositeRaw());
        assertTrue(outcome.objectLocationReport().sessionValid());
        assertTrue(session.domainEvents().isEmpty());
        verify(rawMetrics).replace(session.id(), metrics,
            outcome.objectLocationReport());
        verify(sessions).save(session);
        verify(events, never()).publishEvent(any(GameResultRecordedEvent.class));
    }

    @Test
    void technicallyInvalidSubmissionIsAuditOnlyAndRetryable() {
        UUID ownerId = UUID.randomUUID();
        GameSession session = GameSession.rehydrate(
            ObjectLocationTestFixtures.SESSION_ID, ownerId,
            GameType.VISUOSPATIAL_MEMORY, SessionStatus.IN_PROGRESS,
            List.of(), java.time.Instant.now(), null);
        ObjectLocationMetrics valid = ObjectLocationTestFixtures.perfect(session.id());
        ObjectLocationMetrics invalid = new ObjectLocationMetrics(
            valid.protocolVersion(), ObjectLocationCompletionReason.MAX_LEVELS,
            valid.levels(), true, false, 1, 0, 0, 0);
        when(sessions.findByIdForUpdate(session.id())).thenReturn(Optional.of(session));

        SubmitGameResultUseCase.Outcome outcome = useCase.execute(
            command(session, ownerId, invalid));

        assertFalse(outcome.objectLocationReport().technicalValid());
        assertFalse(outcome.objectLocationReport().sessionValid());
        assertEquals(SessionStatus.IN_PROGRESS, outcome.session().status());
        assertTrue(outcome.session().attempts().isEmpty());
        verify(rawMetrics).replace(session.id(), invalid,
            outcome.objectLocationReport());
        verify(sessions, never()).save(any());
        verify(events, never()).publishEvent(any());
    }

    @Test
    void foreignPlayerAndWrongGameTypeAreRejectedBeforeRawPersistence() {
        UUID ownerId = UUID.randomUUID();
        GameSession session = GameSession.rehydrate(
            ObjectLocationTestFixtures.SESSION_ID, ownerId,
            GameType.VISUOSPATIAL_MEMORY, SessionStatus.IN_PROGRESS,
            List.of(), java.time.Instant.now(), null);
        when(sessions.findByIdForUpdate(session.id())).thenReturn(Optional.of(session));
        ObjectLocationMetrics metrics =
            ObjectLocationTestFixtures.perfect(session.id());

        assertThrows(ForbiddenException.class, () -> useCase.execute(
            command(session, UUID.randomUUID(), metrics)));
        verify(rawMetrics, never()).replace(any(), any(), any());

        GameSession wrong = GameSession.rehydrate(
            session.id(), ownerId, GameType.MEMORY_QUEST,
            SessionStatus.IN_PROGRESS, List.of(), java.time.Instant.now(), null);
        when(sessions.findByIdForUpdate(session.id())).thenReturn(Optional.of(wrong));
        assertThrows(IllegalArgumentException.class, () -> useCase.execute(
            command(wrong, ownerId, metrics)));
        verify(sessions, never()).save(any());
    }

    private static SubmitGameResultCommand command(
            GameSession session, UUID playerId, ObjectLocationMetrics metrics) {
        return new SubmitGameResultCommand(
            session.id(), playerId, MiniGame.OBJECT_LOCATION_BINDING_CORE,
            metrics, null);
    }
}
