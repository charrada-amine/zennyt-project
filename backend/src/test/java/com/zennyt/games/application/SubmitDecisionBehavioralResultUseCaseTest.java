package com.zennyt.games.application;

import com.zennyt.games.application.command.SubmitGameResultCommand;
import com.zennyt.games.application.usecase.SubmitGameResultUseCase;
import com.zennyt.games.domain.catalog.DecisionFormCatalog;
import com.zennyt.games.domain.catalog.DecisionScenarioCatalog;
import com.zennyt.games.domain.catalog.StrategicChoicesCatalog;
import com.zennyt.games.domain.event.GameResultRecordedEvent;
import com.zennyt.games.domain.model.GameSession;
import com.zennyt.games.domain.model.MiniGame;
import com.zennyt.games.domain.repository.ContinuousAttentionMetricsRepository;
import com.zennyt.games.domain.repository.CoordinationMetricsRepository;
import com.zennyt.games.domain.repository.DecisionBehavioralMetricsRepository;
import com.zennyt.games.domain.repository.DeviceCalibrationRepository;
import com.zennyt.games.domain.repository.EmotionalRadarAnswerRepository;
import com.zennyt.games.domain.repository.GameSessionRepository;
import com.zennyt.games.domain.repository.ObjectLocationMetricsRepository;
import com.zennyt.games.domain.config.BartConfig;
import com.zennyt.games.domain.service.BartSequenceGenerator;
import com.zennyt.games.domain.service.PlanifikScoringService;
import com.zennyt.games.domain.vo.BartBalloonMetric;
import com.zennyt.games.domain.vo.BartBalloonOutcome;
import com.zennyt.games.domain.vo.BartMetrics;
import com.zennyt.games.domain.vo.BartPhase;
import com.zennyt.games.domain.vo.GameMetrics;
import com.zennyt.games.domain.vo.GameType;
import com.zennyt.games.domain.vo.IstMetrics;
import com.zennyt.games.domain.vo.Score;
import com.zennyt.games.domain.vo.SessionStatus;
import com.zennyt.shared.application.exception.ForbiddenException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.context.ApplicationEventPublisher;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static com.zennyt.games.support.DecisionBehavioralTestFixtures.SESSION_ID;
import static com.zennyt.games.support.DecisionBehavioralTestFixtures.bartFixedStrategy;
import static com.zennyt.games.support.DecisionBehavioralTestFixtures.istStrategy;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class SubmitDecisionBehavioralResultUseCaseTest {

    private GameSessionRepository sessions;
    private DecisionBehavioralMetricsRepository rawMetrics;
    private ApplicationEventPublisher events;
    private SubmitGameResultUseCase useCase;
    private UUID ownerId;
    private GameSession session;

    @BeforeEach
    void setUp() {
        sessions = mock(GameSessionRepository.class);
        rawMetrics = mock(DecisionBehavioralMetricsRepository.class);
        events = mock(ApplicationEventPublisher.class);
        useCase = new SubmitGameResultUseCase(
            sessions,
            mock(DeviceCalibrationRepository.class),
            mock(EmotionalRadarAnswerRepository.class),
            mock(ContinuousAttentionMetricsRepository.class),
            mock(CoordinationMetricsRepository.class),
            mock(ObjectLocationMetricsRepository.class),
            rawMetrics,
            events,
            mock(DecisionScenarioCatalog.class),
            mock(DecisionFormCatalog.class),
            mock(StrategicChoicesCatalog.class));
        when(sessions.save(any(GameSession.class)))
            .thenAnswer(invocation -> invocation.getArgument(0));
        ownerId = UUID.randomUUID();
        session = GameSession.rehydrate(SESSION_ID, ownerId, GameType.DECISION_BEHAVIORAL,
            SessionStatus.IN_PROGRESS, List.of(), Instant.now(), null);
        when(sessions.findByIdForUpdate(SESSION_ID)).thenReturn(Optional.of(session));
    }

    @Test
    @DisplayName("BART puis IST : la session se clôt au second, sans jamais publier d'événement Fit Score")
    void completesAfterBothMiniGamesWithoutProvisionalFitEvent() {
        BartMetrics bart = bartFixedStrategy(SESSION_ID, 64, 200);
        SubmitGameResultUseCase.Outcome first = useCase.execute(
            command(MiniGame.BART_CORE, bart));

        assertThat(first.session().status()).isEqualTo(SessionStatus.IN_PROGRESS);
        assertThat(first.session().coverageRatio()).isEqualTo(50);
        assertThat(first.bartReport().sessionValid()).isTrue();
        assertThat(first.istReport()).isNull();
        verify(rawMetrics).replaceBart(SESSION_ID, bart, first.bartReport());

        IstMetrics ist = istStrategy(SESSION_ID, 25, 15, 3, false, 300);
        SubmitGameResultUseCase.Outcome second = useCase.execute(
            command(MiniGame.INFORMATION_SAMPLING_CORE, ist));

        assertThat(second.session().status()).isEqualTo(SessionStatus.COMPLETED);
        assertThat(second.session().coverageRatio()).isEqualTo(100);
        assertThat(second.session().compositeMax()).isEqualTo(200);
        assertThat(second.istReport().sessionValid()).isTrue();
        verify(rawMetrics).replaceIst(SESSION_ID, ist, second.istReport());
        assertThat(session.domainEvents()).isEmpty();
        verify(events, never()).publishEvent(any(GameResultRecordedEvent.class));
        verify(events, never()).publishEvent(any(Object.class));
    }

    @Test
    @DisplayName("Un run invalide est conservé pour audit, sans Attempt, et peut être rejoué")
    void invalidRunIsAuditOnlyAndRetryable() {
        BartMetrics nonEngaged = bartFixedStrategy(SESSION_ID, 0, 200);

        SubmitGameResultUseCase.Outcome outcome = useCase.execute(
            command(MiniGame.BART_CORE, nonEngaged));

        assertThat(outcome.bartReport().sessionValid()).isFalse();
        assertThat(outcome.session().attempts()).isEmpty();
        verify(rawMetrics).replaceBart(SESSION_ID, nonEngaged, outcome.bartReport());
        verify(sessions, never()).save(any());

        SubmitGameResultUseCase.Outcome retry = useCase.execute(
            command(MiniGame.BART_CORE, bartFixedStrategy(SESSION_ID, 40, 200)));
        assertThat(retry.session().attempts()).hasSize(1);
    }

    @Test
    @DisplayName("Une issue impossible est refusée avant toute persistance")
    void impossibleClaimIsRejectedBeforePersistence() {
        // Le client « collecte » exactement à la pompe où le serveur fait éclater le ballon.
        int explosionPoint = new BartSequenceGenerator().generate(SESSION_ID).get(0);
        List<BartBalloonMetric> forged = new ArrayList<>(bartFixedStrategy(SESSION_ID, 64, 200).balloons());
        List<Long> stamps = new ArrayList<>();
        for (int p = 1; p <= explosionPoint; p++) stamps.add(p * 200L);
        forged.set(0, new BartBalloonMetric(0, BartPhase.PRACTICE, explosionPoint,
            BartBalloonOutcome.COLLECTED, stamps, (explosionPoint + 1) * 200L));
        BartMetrics metrics = new BartMetrics(BartConfig.PROTOCOL_VERSION, forged, true, false, 0, 0);

        assertThatThrownBy(() -> useCase.execute(command(MiniGame.BART_CORE, metrics)))
            .isInstanceOf(IllegalArgumentException.class);
        verify(rawMetrics, never()).replaceBart(any(), any(), any());
        verify(sessions, never()).save(any());
    }

    @Test
    @DisplayName("Joueur étranger, mauvais type et mini-jeu déjà joué sont refusés")
    void ownershipTypeAndDuplicateAreEnforced() {
        BartMetrics bart = bartFixedStrategy(SESSION_ID, 64, 200);

        assertThatThrownBy(() -> useCase.execute(new SubmitGameResultCommand(
            SESSION_ID, UUID.randomUUID(), MiniGame.BART_CORE, bart, null)))
            .isInstanceOf(ForbiddenException.class);
        verify(rawMetrics, never()).replaceBart(any(), any(), any());

        useCase.execute(command(MiniGame.BART_CORE, bart));
        assertThatThrownBy(() -> useCase.execute(command(MiniGame.BART_CORE, bart)))
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("déjà joué");

        GameSession wrongType = GameSession.rehydrate(SESSION_ID, ownerId, GameType.DECISION,
            SessionStatus.IN_PROGRESS, List.of(), Instant.now(), null, "A");
        when(sessions.findByIdForUpdate(SESSION_ID)).thenReturn(Optional.of(wrongType));
        assertThatThrownBy(() -> useCase.execute(command(MiniGame.BART_CORE, bart)))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    @DisplayName("Non-régression : « Je Décide » reste complet à lui seul, couverture 100 %")
    void decisionTypeIsUnaffected() {
        GameSession decide = GameSession.rehydrate(UUID.randomUUID(), ownerId, GameType.DECISION,
            SessionStatus.IN_PROGRESS, List.of(), Instant.now(), null, "A");

        assertThat(decide.expectedMiniGames()).containsExactly(MiniGame.DECISION_CORE);
        decide.recordResult(MiniGame.DECISION_CORE,
            new Score(70, 100, "Normal"), new PlanifikScoringService());
        assertThat(decide.status()).isEqualTo(SessionStatus.COMPLETED);
        assertThat(decide.coverageRatio()).isEqualTo(100);

        GameSession behavioral = GameSession.start(ownerId, GameType.DECISION_BEHAVIORAL);
        assertThat(behavioral.expectedMiniGames())
            .containsExactly(MiniGame.BART_CORE, MiniGame.INFORMATION_SAMPLING_CORE);
        assertThat(behavioral.decisionFormCode()).isNull();
    }

    private SubmitGameResultCommand command(MiniGame miniGame, GameMetrics metrics) {
        return new SubmitGameResultCommand(SESSION_ID, ownerId, miniGame, metrics, null);
    }
}
