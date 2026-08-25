package com.zennyt.games.application.usecase;

import com.zennyt.games.domain.catalog.EmotionReferential;
import com.zennyt.games.domain.config.EmotionalRadarV2Config;
import com.zennyt.games.domain.config.EmotionalRadarV2ProvisionalRules;
import com.zennyt.games.domain.model.GameSession;
import com.zennyt.games.domain.model.MiniGame;
import com.zennyt.games.domain.repository.EmotionalRadarV2SceneRepository;
import com.zennyt.games.domain.repository.GameSessionRepository;
import com.zennyt.games.domain.service.AdaptiveDifficultyService;
import com.zennyt.games.domain.service.EmotionalRadarV2ReportService;
import com.zennyt.games.domain.service.EmotionalRadarV2SceneFactory;
import com.zennyt.games.domain.service.RadarGameScoreService;
import com.zennyt.games.domain.service.SemanticDistanceModel;
import com.zennyt.games.domain.service.ThetaIrtService;
import com.zennyt.games.domain.service.ValenceArousalDistanceModel;
import com.zennyt.games.domain.vo.EmotionDefinition;
import com.zennyt.games.domain.vo.EmotionalRadarV2Report;
import com.zennyt.games.domain.vo.GameType;
import com.zennyt.games.domain.vo.RadarSceneOutcome;
import com.zennyt.games.domain.vo.RadarV2SceneAssignment;
import com.zennyt.games.domain.vo.SessionStatus;
import com.zennyt.shared.application.exception.ConflictException;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Orchestration autoritaire et reprenable d'une session Emotional Radar V2.
 *
 * <p>Le verrou pessimiste de {@link GameSessionRepository#findByIdForUpdate(UUID)}
 * sérialise les activations POST et les réponses concurrentes ; GET reste une
 * lecture pure. Les scènes sont
 * matérialisées une par une : le niveau de la scène N+1 dépend de la fenêtre
 * glissante réellement notée jusqu'à N.
 */
@Service
public class EmotionalRadarV2SessionUseCase {

    private final GameSessionRepository sessions;
    private final EmotionalRadarV2SceneRepository scenes;
    private final EmotionReferential referential;
    private final SemanticDistanceModel distanceModel = new ValenceArousalDistanceModel();
    private final AdaptiveDifficultyService adaptive = new AdaptiveDifficultyService();
    private final EmotionalRadarV2SceneFactory sceneFactory;
    private final RadarGameScoreService gameScore = new RadarGameScoreService();
    private final EmotionalRadarV2ReportService reports;

    public EmotionalRadarV2SessionUseCase(GameSessionRepository sessions,
                                          EmotionalRadarV2SceneRepository scenes,
                                          EmotionReferential referential) {
        this.sessions = sessions;
        this.scenes = scenes;
        this.referential = referential;
        this.sceneFactory = new EmotionalRadarV2SceneFactory(referential, distanceModel);
        this.reports = new EmotionalRadarV2ReportService(
            gameScore, new ThetaIrtService());
    }

    @Transactional(readOnly = true)
    public State getState(UUID sessionId, UUID playerId) {
        return getStateAt(sessionId, playerId, Instant.now());
    }

    @Transactional
    public State activateNext(UUID sessionId, UUID playerId) {
        return activateNextAt(sessionId, playerId, Instant.now());
    }

    @Transactional
    public AnswerResult answer(UUID sessionId, UUID playerId, int sceneOrder,
                               String selectedEmotionKey, int selectedIntensity,
                               String explanation) {
        return answerAt(sessionId, playerId, sceneOrder, selectedEmotionKey,
            selectedIntensity, explanation, Instant.now());
    }

    State getStateAt(UUID sessionId, UUID playerId, Instant now) {
        GameSession session = ownedRadarSession(sessionId, playerId, false);
        List<RadarV2SceneAssignment> assigned = scenes.findBySessionId(sessionId);
        validateSequence(sessionId, assigned);
        rejectLegacyAttempt(session);
        if (answered(assigned).size() < EmotionalRadarV2Config.TOTAL_SCENES) {
            assertOpen(session);
        }

        return state(assigned, now);
    }

    State activateNextAt(UUID sessionId, UUID playerId, Instant now) {
        GameSession session = ownedRadarSession(sessionId, playerId, true);
        List<RadarV2SceneAssignment> assigned = scenes.findBySessionId(sessionId);
        validateSequence(sessionId, assigned);
        rejectLegacyAttempt(session);
        List<RadarV2SceneAssignment> completedAnswers = answered(assigned);
        if (completedAnswers.size() < EmotionalRadarV2Config.TOTAL_SCENES) {
            assertOpen(session);
        }

        if (assigned.size() < EmotionalRadarV2Config.TOTAL_SCENES
            && assigned.stream().noneMatch(scene -> !scene.answered())) {
            int nextOrder = assigned.size() + 1;
            int nextLevel = nextLevel(completedAnswers);
            RadarV2SceneAssignment created = sceneFactory.create(
                sessionId, nextOrder, nextLevel, assignedTargetKeys(assigned), now);
            scenes.insert(created);
            assigned = append(assigned, created);
        }
        return state(assigned, now);
    }

    AnswerResult answerAt(UUID sessionId, UUID playerId, int sceneOrder,
                          String selectedEmotionKey, int selectedIntensity,
                          String explanation, Instant now) {
        GameSession session = ownedRadarSession(sessionId, playerId, true);
        assertOpen(session);
        List<RadarV2SceneAssignment> assigned = scenes.findBySessionId(sessionId);
        validateSequence(sessionId, assigned);
        rejectLegacyAttempt(session);

        RadarV2SceneAssignment current = assigned.stream()
            .filter(scene -> !scene.answered())
            .findFirst()
            .orElseThrow(() -> new ConflictException(
                "Aucune scène courante : activez la prochaine scène V2 avant de répondre."));
        if (current.sceneOrder() != sceneOrder) {
            throw new ConflictException(
                "La scène courante est " + current.sceneOrder() + ", pas " + sceneOrder + ".");
        }

        long elapsedMs = Duration.between(current.servedAt(), now).toMillis();
        RadarV2SceneAssignment answeredScene = current.answer(
            selectedEmotionKey, selectedIntensity, explanation, elapsedMs,
            referential, distanceModel, now);
        RadarV2SceneAssignment persisted = scenes.answer(answeredScene);

        List<RadarV2SceneAssignment> updated = new ArrayList<>(assigned.size() + 1);
        for (RadarV2SceneAssignment scene : assigned) {
            updated.add(scene.sceneOrder() == sceneOrder ? persisted : scene);
        }

        /*
         * Phase A : le rapport /10 est calculé côté serveur mais aucun Attempt ni
         * Domain Event n'est créé avec un stimulus placeholder. Sinon une future
         * soumission de Reflective Pause republierait indirectement ce score non
         * normé dans Recruitment. L'unique cible d'activation reste
         * MiniGame.EMOTIONAL_RADAR_CORE lorsque MEDIA_LIBRARY_READY passera à true.
         * La scène suivante n'est volontairement créée que par POST scenes/next, lorsque
         * le joueur quitte le feedback, afin que son budget serveur ne s'écoule pas
         * avant son affichage.
         */
        return new AnswerResult(
            Feedback.from(persisted), state(List.copyOf(updated), now));
    }

    private GameSession ownedRadarSession(
            UUID sessionId, UUID playerId, boolean forUpdate) {
        GameSession session = (forUpdate
            ? sessions.findByIdForUpdate(sessionId)
            : sessions.findById(sessionId))
            .orElseThrow(() -> new NotFoundException("Session introuvable : " + sessionId));
        if (!session.playerId().equals(playerId)) {
            throw new ForbiddenException(
                "Cette session n'appartient pas au joueur authentifié.");
        }
        if (session.gameType() != GameType.EMOTIONAL_REGULATION) {
            throw new IllegalArgumentException(
                MiniGame.EMOTIONAL_RADAR_CORE + " n'appartient pas au type "
                    + session.gameType());
        }
        return session;
    }

    private static void assertOpen(GameSession session) {
        if (session.status() != SessionStatus.IN_PROGRESS) {
            throw new ConflictException("Session non ouverte : " + session.status());
        }
    }

    private static void rejectLegacyAttempt(GameSession session) {
        boolean recorded = session.attempts().stream()
            .anyMatch(attempt -> attempt.miniGame() == MiniGame.EMOTIONAL_RADAR_CORE);
        if (recorded) {
            throw new ConflictException(
                "EMOTIONAL_RADAR_CORE a déjà été enregistré par le parcours V1.");
        }
    }

    private static java.util.Set<String> assignedTargetKeys(
            List<RadarV2SceneAssignment> assigned) {
        return assigned.stream()
            .map(RadarV2SceneAssignment::correctEmotionKey)
            .collect(java.util.stream.Collectors.toUnmodifiableSet());
    }

    private int nextLevel(List<RadarV2SceneAssignment> answered) {
        if (answered.isEmpty()) {
            return EmotionalRadarV2Config.STARTING_LEVEL;
        }
        RadarV2SceneAssignment last = answered.get(answered.size() - 1);
        return adaptive.nextLevel(last.level(), answered.stream()
            .map(RadarV2SceneAssignment::outcome)
            .map(RadarSceneOutcome::correct)
            .toList());
    }

    private State state(List<RadarV2SceneAssignment> assigned, Instant snapshotAt) {
        validateSequence(assigned.isEmpty() ? null : assigned.get(0).sessionId(), assigned);
        List<RadarV2SceneAssignment> answered = answered(assigned);
        boolean complete = answered.size() == EmotionalRadarV2Config.TOTAL_SCENES;
        RadarV2SceneAssignment current = complete ? null : assigned.stream()
            .filter(scene -> !scene.answered())
            .findFirst()
            .orElse(null);
        int currentLevel = current != null
            ? current.level()
            : answered.isEmpty()
                ? EmotionalRadarV2Config.STARTING_LEVEL
                : answered.get(answered.size() - 1).level();
        int remainingResponseTimeMs = current == null
            ? 0 : remainingResponseTimeMs(current, snapshotAt);
        EmotionalRadarV2Report report = complete ? completedReport(answered) : null;
        List<EmotionDefinition> choices = current == null ? List.of() : current.choiceKeys().stream()
            .map(key -> referential.byKey(key)
                .orElseThrow(() -> new IllegalStateException("émotion inconnue : " + key)))
            .toList();
        return new State(
            EmotionalRadarV2Config.TOTAL_SCENES,
            answered.size(),
            EmotionalRadarV2Config.STARTING_LEVEL,
            currentLevel,
            complete,
            EmotionalRadarV2ProvisionalRules.MEDIA_LIBRARY_READY,
            EmotionalRadarV2ProvisionalRules.SCORING_PROVISIONAL,
            EmotionalRadarV2ProvisionalRules.FIT_SCORE_PUBLISHING_ALLOWED,
            EmotionalRadarV2ProvisionalRules.MEASUREMENT_AVAILABLE,
            current,
            choices,
            remainingResponseTimeMs,
            report);
    }

    private EmotionalRadarV2Report completedReport(
            List<RadarV2SceneAssignment> answered) {
        List<RadarSceneOutcome> outcomes = answered.stream()
            .map(RadarV2SceneAssignment::outcome)
            .toList();
        List<Integer> levels = answered.stream()
            .map(RadarV2SceneAssignment::level)
            .toList();
        int finalLevel = levels.get(levels.size() - 1);
        return reports.report(
            outcomes,
            EmotionalRadarV2Config.STARTING_LEVEL,
            finalLevel,
            EmotionalRadarV2ReportService.transitionsAsText(levels));
    }

    private static int remainingResponseTimeMs(
            RadarV2SceneAssignment current, Instant snapshotAt) {
        long elapsedMs = Math.max(0L,
            Duration.between(current.servedAt(), snapshotAt).toMillis());
        long remainingMs = Math.max(0L,
            EmotionalRadarV2Config.MAX_RESPONSE_TIME_MS - elapsedMs);
        return (int) remainingMs;
    }

    private static List<RadarV2SceneAssignment> answered(
            List<RadarV2SceneAssignment> assigned) {
        return assigned.stream().filter(RadarV2SceneAssignment::answered).toList();
    }

    private static List<RadarV2SceneAssignment> append(
            List<RadarV2SceneAssignment> existing, RadarV2SceneAssignment added) {
        List<RadarV2SceneAssignment> out = new ArrayList<>(existing);
        out.add(added);
        return List.copyOf(out);
    }

    private static void validateSequence(
            UUID sessionId, List<RadarV2SceneAssignment> assigned) {
        if (assigned.size() > EmotionalRadarV2Config.TOTAL_SCENES) {
            throw new IllegalStateException("plus de 15 scènes V2 assignées");
        }
        boolean pendingSeen = false;
        for (int i = 0; i < assigned.size(); i++) {
            RadarV2SceneAssignment scene = assigned.get(i);
            if (sessionId != null && !sessionId.equals(scene.sessionId())) {
                throw new IllegalStateException("session V2 incohérente");
            }
            if (scene.sceneOrder() != i + 1) {
                throw new IllegalStateException("ordre de scène V2 non contigu");
            }
            if (!scene.answered()) {
                if (pendingSeen || i != assigned.size() - 1) {
                    throw new IllegalStateException("une seule scène V2 courante est autorisée");
                }
                pendingSeen = true;
            } else if (pendingSeen) {
                throw new IllegalStateException("réponse après une scène en attente");
            }
        }
    }

    public record State(
        int totalScenes,
        int answeredScenes,
        int startingLevel,
        int currentLevel,
        boolean completed,
        boolean mediaLibraryReady,
        boolean scoringProvisional,
        boolean fitScorePublished,
        boolean measurementAvailable,
        RadarV2SceneAssignment currentScene,
        List<EmotionDefinition> currentChoices,
        int currentSceneRemainingResponseTimeMs,
        EmotionalRadarV2Report report
    ) {
    }

    public record Feedback(
        int sceneOrder,
        boolean correct,
        boolean timedOut,
        int responseTimeMs,
        boolean impulsive,
        String expectedEmotionKey,
        int expectedIntensity,
        double semanticErrorDistance
    ) {
        static Feedback from(RadarV2SceneAssignment scene) {
            RadarSceneOutcome outcome = scene.outcome();
            return new Feedback(
                scene.sceneOrder(), outcome.correct(), scene.timedOut(),
                scene.responseTimeMs(), scene.impulsive(), scene.correctEmotionKey(),
                scene.stimulusIntensity(), scene.semanticErrorDistance());
        }
    }

    public record AnswerResult(Feedback feedback, State state) {
    }
}
