package com.zennyt.games.application.usecase;

import com.zennyt.games.application.command.SubmitGameResultCommand;
import com.zennyt.games.domain.catalog.DecisionScenarioCatalog;
import com.zennyt.games.domain.event.GameResultRecordedEvent;
import com.zennyt.games.domain.model.GameSession;
import com.zennyt.games.domain.model.MiniGame;
import com.zennyt.games.domain.repository.ContinuousAttentionMetricsRepository;
import com.zennyt.games.domain.repository.CoordinationMetricsRepository;
import com.zennyt.games.domain.repository.DeviceCalibrationRepository;
import com.zennyt.games.domain.repository.EmotionalRadarAnswerRepository;
import com.zennyt.games.domain.repository.EmotionalRadarV2SceneRepository;
import com.zennyt.games.domain.repository.GameSessionRepository;
import com.zennyt.games.domain.repository.ObjectLocationMetricsRepository;
import com.zennyt.games.domain.vo.GameType;
import com.zennyt.games.domain.vo.RadarMediaStatus;
import com.zennyt.games.domain.vo.RadarV2SceneAssignment;
import com.zennyt.games.domain.vo.ReflectivePauseMetrics;
import com.zennyt.games.domain.vo.ReflectivePauseMomentMetric;
import com.zennyt.games.domain.vo.ReflectivePauseResponseType;
import com.zennyt.games.domain.vo.SessionStatus;
import com.zennyt.games.infrastructure.catalog.JsonEmotionReferential;
import com.zennyt.shared.application.exception.ConflictException;
import com.zennyt.shared.application.exception.ForbiddenException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.context.ApplicationEventPublisher;

import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

class EmotionalRadarV2SessionUseCaseTest {

    private static final UUID SESSION_ID =
        UUID.fromString("10000000-0000-4000-8000-000000000001");
    private static final UUID PLAYER_ID =
        UUID.fromString("20000000-0000-4000-8000-000000000002");
    private static final Instant START = Instant.parse("2026-08-13T08:00:00Z");

    private InMemorySessions sessions;
    private InMemoryRadarScenes scenes;
    private EmotionalRadarV2SessionUseCase useCase;

    @BeforeEach
    void setUp() {
        sessions = new InMemorySessions();
        sessions.value = GameSession.rehydrate(
            SESSION_ID, PLAYER_ID, GameType.EMOTIONAL_REGULATION,
            SessionStatus.IN_PROGRESS, List.of(), START, null);
        scenes = new InMemoryRadarScenes();
        useCase = new EmotionalRadarV2SessionUseCase(
            sessions, scenes, new JsonEmotionReferential());
    }

    @Test
    void getStateIsPureAndActivateNextIsIdempotentWithServerBudget() {
        var state = useCase.getStateAt(SESSION_ID, PLAYER_ID, START);

        assertThat(state.totalScenes()).isEqualTo(15);
        assertThat(state.answeredScenes()).isZero();
        assertThat(state.currentLevel()).isEqualTo(1);
        assertThat(state.currentScene()).isNull();
        assertThat(state.currentChoices()).isEmpty();
        assertThat(state.currentSceneRemainingResponseTimeMs()).isZero();
        assertThat(state.measurementAvailable()).isFalse();
        assertThat(scenes.values).isEmpty();

        var activated = useCase.activateNextAt(SESSION_ID, PLAYER_ID, START);
        assertThat(activated.currentScene().sceneOrder()).isEqualTo(1);
        assertThat(activated.currentChoices()).hasSize(6);
        assertThat(activated.currentScene().mediaStatus())
            .isEqualTo(RadarMediaStatus.PLACEHOLDER_PENDING);
        assertThat(activated.currentScene().mediaUrl()).isNull();
        assertThat(activated.mediaLibraryReady()).isFalse();
        assertThat(activated.scoringProvisional()).isTrue();
        assertThat(activated.fitScorePublished()).isFalse();
        assertThat(activated.currentSceneRemainingResponseTimeMs()).isEqualTo(8000);
        assertThat(scenes.values).hasSize(1);

        var idempotent = useCase.activateNextAt(
            SESSION_ID, PLAYER_ID, START.plusMillis(1500));
        assertThat(idempotent.currentScene().servedAt()).isEqualTo(START);
        assertThat(idempotent.currentSceneRemainingResponseTimeMs()).isEqualTo(6500);
        assertThat(scenes.values).hasSize(1);

        var resumed = useCase.getStateAt(SESSION_ID, PLAYER_ID, START.plusMillis(1500));
        assertThat(resumed.currentScene().servedAt()).isEqualTo(START);
        assertThat(resumed.currentSceneRemainingResponseTimeMs()).isEqualTo(6500);
        assertThat(scenes.values).hasSize(1);

        var expired = useCase.getStateAt(SESSION_ID, PLAYER_ID, START.plusSeconds(30));
        assertThat(expired.currentSceneRemainingResponseTimeMs()).isZero();
    }

    @Test
    void ownershipTypeAndOneShotOrderAreEnforcedBeforeMutation() {
        assertThatThrownBy(() -> useCase.getStateAt(
            SESSION_ID, UUID.randomUUID(), START))
            .isInstanceOf(ForbiddenException.class);
        assertThat(scenes.values).isEmpty();

        var state = useCase.activateNextAt(SESSION_ID, PLAYER_ID, START);
        var current = state.currentScene();
        var answer = useCase.answerAt(
            SESSION_ID, PLAYER_ID, 1, current.correctEmotionKey(),
            current.stimulusIntensity(), "Le signal émotionnel est identifiable.",
            START.plusMillis(1200));

        assertThat(answer.state().completed()).isFalse();
        assertThat(answer.state().currentScene()).isNull();
        assertThat(answer.state().currentSceneRemainingResponseTimeMs()).isZero();
        assertThat(scenes.values).hasSize(1);

        Instant nextDisplayedAt = START.plusSeconds(30);
        var snapshotBeforeNext = useCase.getStateAt(
            SESSION_ID, PLAYER_ID, nextDisplayedAt);
        assertThat(snapshotBeforeNext.currentScene()).isNull();
        assertThat(scenes.values).hasSize(1);

        var next = useCase.activateNextAt(SESSION_ID, PLAYER_ID, nextDisplayedAt);
        assertThat(next.currentScene().sceneOrder()).isEqualTo(2);
        assertThat(next.currentScene().servedAt()).isEqualTo(nextDisplayedAt);
        assertThat(next.currentSceneRemainingResponseTimeMs()).isEqualTo(8000);
        assertThat(scenes.values).hasSize(2);

        assertThatThrownBy(() -> useCase.answerAt(
            SESSION_ID, PLAYER_ID, 1, current.correctEmotionKey(),
            current.stimulusIntensity(), "Nouvelle tentative", START.plusSeconds(2)))
            .isInstanceOf(ConflictException.class)
            .hasMessageContaining("scène courante");
        assertThat(scenes.values.get(0).explanation())
            .isEqualTo("Le signal émotionnel est identifiable.");
    }

    @Test
    void serverTimingCapsTimeoutAndMakesLateCorrectChoiceIncorrect() {
        var current = useCase.activateNextAt(
            SESSION_ID, PLAYER_ID, START).currentScene();

        var result = useCase.answerAt(
            SESSION_ID, PLAYER_ID, 1, current.correctEmotionKey(),
            current.stimulusIntensity(), "Réponse arrivée trop tard.",
            START.plusMillis(8001));

        assertThat(result.feedback().timedOut()).isTrue();
        assertThat(result.feedback().responseTimeMs()).isEqualTo(8000);
        assertThat(result.feedback().correct()).isFalse();
        assertThat(result.feedback().impulsive()).isFalse();
    }

    @Test
    void fifteenAnswersDriveAdaptiveSixSixNineNineAndReturnLockedReport() {
        EmotionalRadarV2SessionUseCase.State state =
            useCase.activateNextAt(SESSION_ID, PLAYER_ID, START);
        Instant answerAt = START;

        for (int order = 1; order <= 15; order++) {
            RadarV2SceneAssignment current = state.currentScene();
            answerAt = current.servedAt().plusMillis(1000);
            var result = useCase.answerAt(
                SESSION_ID, PLAYER_ID, order,
                current.correctEmotionKey(), current.stimulusIntensity(),
                "Les indices convergent vers l'émotion sélectionnée.", answerAt);
            state = order == 15
                ? result.state()
                : useCase.activateNextAt(
                    SESSION_ID, PLAYER_ID, answerAt.plusSeconds(30));
        }

        assertThat(state.completed()).isTrue();
        assertThat(state.answeredScenes()).isEqualTo(15);
        assertThat(state.currentScene()).isNull();
        assertThat(state.report()).isNotNull();
        assertThat(state.report().totalScenes()).isEqualTo(15);
        assertThat(state.report().correctEmotions()).isEqualTo(15);
        assertThat(state.report().radarEmotionScore()).isEqualTo(10);
        assertThat(state.report().theta().itemsUsed()).isEqualTo(15);
        assertThat(state.report().theta().reliabilityFlag()).isEqualTo("Provisoire");
        assertThat(state.report().theta().decisionalUseAllowed()).isFalse();
        assertThat(state.report().justificationScore()).isNull();
        assertThat(state.report().justificationScoringAvailable()).isFalse();
        assertThat(state.report().accuracyBySemanticDistance()).isEmpty();
        assertThat(state.report().semanticDistanceScoringAvailable()).isFalse();
        assertThat(state.report().stimulusTypePerformance()).isEmpty();
        assertThat(state.report().stimulusTypeScoringAvailable()).isFalse();
        assertThat(state.measurementAvailable()).isFalse();
        assertThat(state.fitScorePublished()).isFalse();
        assertThat(sessions.value.attempts()).isEmpty();

        assertThat(scenes.values).hasSize(15);
        assertThat(scenes.values).extracting(RadarV2SceneAssignment::correctEmotionKey)
            .doesNotHaveDuplicates();
        assertThat(scenes.values.subList(0, 3))
            .allSatisfy(scene -> assertThat(scene.choiceKeys()).hasSize(6));
        assertThat(scenes.values.stream().filter(scene -> scene.level() >= 3).toList())
            .allSatisfy(scene -> assertThat(scene.choiceKeys()).hasSize(9));
        assertThat(state.report().levelTransitions())
            .contains("↑ 1→2", "↑ 2→3", "↑ 3→4");
    }

    @Test
    void finalLevelIsLastAnsweredSceneNotHypotheticalPostSessionLevel() {
        EmotionalRadarV2SessionUseCase.State state =
            useCase.activateNextAt(SESSION_ID, PLAYER_ID, START);

        for (int order = 1; order <= 15; order++) {
            RadarV2SceneAssignment current = state.currentScene();
            boolean answerCorrectly = order < 12;
            String selectedKey = answerCorrectly
                ? current.correctEmotionKey()
                : current.choiceKeys().stream()
                    .filter(key -> !key.equals(current.correctEmotionKey()))
                    .findFirst()
                    .orElseThrow();
            var answer = useCase.answerAt(
                SESSION_ID, PLAYER_ID, order, selectedKey,
                current.stimulusIntensity(), "Explication brute conservée.",
                current.servedAt().plusMillis(1000));
            state = order == 15
                ? answer.state()
                : useCase.activateNextAt(
                    SESSION_ID, PLAYER_ID,
                    current.servedAt().plusSeconds(30));
        }

        RadarV2SceneAssignment lastAnswered = scenes.values.get(14);
        assertThat(lastAnswered.level()).isEqualTo(3);
        assertThat(state.currentLevel()).isEqualTo(lastAnswered.level());
        assertThat(state.report().finalLevel()).isEqualTo(lastAnswered.level());
        assertThat(state.report().levelTransitions()).doesNotContain("↓ 3→2");
    }

    @Test
    void placeholderRunNeverLeaksIntoLaterReflectivePauseEvent() {
        EmotionalRadarV2SessionUseCase.State state =
            useCase.activateNextAt(SESSION_ID, PLAYER_ID, START);
        for (int order = 1; order <= 15; order++) {
            RadarV2SceneAssignment current = state.currentScene();
            Instant answeredAt = current.servedAt().plusMillis(1000);
            var answer = useCase.answerAt(
                SESSION_ID, PLAYER_ID, order, current.correctEmotionKey(),
                current.stimulusIntensity(), "Explication Phase A persistée.", answeredAt);
            state = order == 15
                ? answer.state()
                : useCase.activateNextAt(
                    SESSION_ID, PLAYER_ID, answeredAt.plusSeconds(30));
        }

        assertThat(state.completed()).isTrue();
        assertThat(sessions.value.attempts()).isEmpty();
        assertThat(sessions.value.domainEvents()).isEmpty();

        ApplicationEventPublisher publisher = mock(ApplicationEventPublisher.class);
        SubmitGameResultUseCase submit = new SubmitGameResultUseCase(
            sessions,
            mock(DeviceCalibrationRepository.class),
            mock(EmotionalRadarAnswerRepository.class),
            mock(ContinuousAttentionMetricsRepository.class),
            mock(CoordinationMetricsRepository.class),
            mock(ObjectLocationMetricsRepository.class),
            publisher,
            mock(DecisionScenarioCatalog.class));

        submit.execute(new SubmitGameResultCommand(
            SESSION_ID, PLAYER_ID, MiniGame.REFLECTIVE_PAUSE_CORE,
            perfectReflectivePauseMetrics(), null));

        var captor = org.mockito.ArgumentCaptor.forClass(GameResultRecordedEvent.class);
        verify(publisher).publishEvent(captor.capture());
        GameResultRecordedEvent event = captor.getValue();
        assertThat(sessions.value.attempts())
            .extracting(attempt -> attempt.miniGame())
            .containsExactly(MiniGame.REFLECTIVE_PAUSE_CORE);
        assertThat(event.coverageRatio()).isEqualTo(50);
        assertThat(event.compositeRaw()).isEqualTo(10);
        assertThat(event.compositeMax()).isEqualTo(10);
        assertThat(event.normalizedScore()).isEqualTo(100.0);
    }

    private static ReflectivePauseMetrics perfectReflectivePauseMetrics() {
        List<ReflectivePauseMomentMetric> moments = new ArrayList<>();
        for (int i = 1; i <= 10; i++) {
            ReflectivePauseResponseType response = switch (i) {
                case 1, 5, 9 -> ReflectivePauseResponseType.BREATHE_ANALYZE;
                case 2, 4, 10 -> ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION;
                case 3, 7 -> ReflectivePauseResponseType.WAIT;
                case 6, 8 -> ReflectivePauseResponseType.REFORMULATE_CALMLY;
                default -> throw new IllegalStateException("moment inattendu");
            };
            moments.add(new ReflectivePauseMomentMetric(
                "PRESSURE_%02d".formatted(i), response, 3000, true));
        }
        return new ReflectivePauseMetrics(moments);
    }

    private static final class InMemorySessions implements GameSessionRepository {
        private GameSession value;

        @Override
        public GameSession save(GameSession session) {
            value = session;
            return session;
        }

        @Override
        public Optional<GameSession> findById(UUID id) {
            return value != null && value.id().equals(id) ? Optional.of(value) : Optional.empty();
        }

        @Override
        public Optional<GameSession> findByIdForUpdate(UUID id) {
            return findById(id);
        }
    }

    private static final class InMemoryRadarScenes
        implements EmotionalRadarV2SceneRepository {
        private final List<RadarV2SceneAssignment> values = new ArrayList<>();

        @Override
        public List<RadarV2SceneAssignment> findBySessionId(UUID sessionId) {
            return values.stream()
                .filter(scene -> scene.sessionId().equals(sessionId))
                .sorted(java.util.Comparator.comparingInt(RadarV2SceneAssignment::sceneOrder))
                .toList();
        }

        @Override
        public Optional<RadarV2SceneAssignment> findBySessionIdAndOrder(
                UUID sessionId, int sceneOrder) {
            return values.stream().filter(scene -> scene.sessionId().equals(sessionId)
                && scene.sceneOrder() == sceneOrder).findFirst();
        }

        @Override
        public RadarV2SceneAssignment insert(RadarV2SceneAssignment assignment) {
            if (findBySessionIdAndOrder(
                assignment.sessionId(), assignment.sceneOrder()).isPresent()) {
                throw new IllegalStateException("duplicate");
            }
            values.add(assignment);
            return assignment;
        }

        @Override
        public RadarV2SceneAssignment answer(RadarV2SceneAssignment answeredAssignment) {
            for (int i = 0; i < values.size(); i++) {
                RadarV2SceneAssignment existing = values.get(i);
                if (existing.sessionId().equals(answeredAssignment.sessionId())
                    && existing.sceneOrder() == answeredAssignment.sceneOrder()) {
                    if (existing.answered()) throw new IllegalStateException("immutable");
                    values.set(i, answeredAssignment);
                    return answeredAssignment;
                }
            }
            throw new IllegalStateException("missing");
        }
    }
}
