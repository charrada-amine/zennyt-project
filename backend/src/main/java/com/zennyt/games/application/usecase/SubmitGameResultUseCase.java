package com.zennyt.games.application.usecase;

import com.zennyt.games.application.command.SubmitGameResultCommand;
import com.zennyt.games.domain.catalog.DecisionScenarioCatalog;
import com.zennyt.games.domain.model.GameSession;
import com.zennyt.games.domain.model.MiniGame;
import com.zennyt.games.domain.repository.DeviceCalibrationRepository;
import com.zennyt.games.domain.repository.EmotionalRadarAnswerRepository;
import com.zennyt.games.domain.repository.GameSessionRepository;
import com.zennyt.games.domain.service.CalibrationService;
import com.zennyt.games.domain.service.DecisionScoringService;
import com.zennyt.games.domain.service.EmotionalRadarScoringService;
import com.zennyt.games.domain.service.MemoryQuestScoringService;
import com.zennyt.games.domain.service.PlanifikScoringService;
import com.zennyt.games.domain.service.ReflectivePauseScoringService;
import com.zennyt.games.domain.service.ScoreBreakdownService;
import com.zennyt.games.domain.vo.DecisionMetrics;
import com.zennyt.games.domain.vo.DecisionReport;
import com.zennyt.games.domain.vo.DeviceCalibration;
import com.zennyt.games.domain.vo.EmotionalRadarAnswer;
import com.zennyt.games.domain.vo.EmotionalRadarMetrics;
import com.zennyt.games.domain.vo.EmotionalRadarReport;
import com.zennyt.games.domain.vo.MemoryQuestMetrics;
import com.zennyt.games.domain.vo.MemoryQuestReport;
import com.zennyt.games.domain.vo.MoveFastFlexibilityReport;
import com.zennyt.games.domain.vo.ScoreBreakdown;
import com.zennyt.games.domain.vo.MoveFastMetrics;
import com.zennyt.games.domain.vo.PlanifikMetrics;
import com.zennyt.games.domain.vo.PrevisionPuzzleMetrics;
import com.zennyt.games.domain.vo.PrevisionPuzzleReport;
import com.zennyt.games.domain.vo.ReflectivePauseMetrics;
import com.zennyt.games.domain.vo.ReflectivePauseReport;
import com.zennyt.games.domain.vo.Score;
import com.zennyt.games.domain.vo.TaskSchedulingMetrics;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.List;

/**
 * Use case : soumettre le résultat d'un mini-jeu.
 *
 * <p>Flux applicatif :
 * <ol>
 *   <li>charge la session ;</li>
 *   <li>calcule le score déterministe à partir des métriques (domaine) ;</li>
 *   <li>enregistre le résultat sur l'agrégat (qui se termine + émet l'événement
 *       au dernier mini-jeu) ;</li>
 *   <li>persiste, puis publie les Domain Events après commit.</li>
 * </ol>
 */
@Service
public class SubmitGameResultUseCase {

    private final GameSessionRepository repository;
    private final DeviceCalibrationRepository calibrationRepository;
    private final EmotionalRadarAnswerRepository emotionalRadarAnswers;
    private final ApplicationEventPublisher eventPublisher;
    private final PlanifikScoringService scoring = new PlanifikScoringService();
    private final CalibrationService calibration = new CalibrationService();
    private final ScoreBreakdownService breakdown = new ScoreBreakdownService();
    private final MemoryQuestScoringService memoryQuest = new MemoryQuestScoringService();
    private final EmotionalRadarScoringService emotionalRadar = new EmotionalRadarScoringService();
    private final ReflectivePauseScoringService reflectivePause =
        new ReflectivePauseScoringService();
    private final DecisionScoringService decision;

    public SubmitGameResultUseCase(GameSessionRepository repository,
                                   DeviceCalibrationRepository calibrationRepository,
                                   EmotionalRadarAnswerRepository emotionalRadarAnswers,
                                   ApplicationEventPublisher eventPublisher,
                                   DecisionScenarioCatalog decisionCatalog) {
        this.repository = repository;
        this.calibrationRepository = calibrationRepository;
        this.emotionalRadarAnswers = emotionalRadarAnswers;
        this.eventPublisher = eventPublisher;
        // « Je Décide » : le catalogue (port) est injecté ; l'impl vivante est vide
        // tant que le psychologue n'a pas fourni les 30 scénarios.
        this.decision = new DecisionScoringService(decisionCatalog);
    }

    /**
     * Résultat d'une soumission : la session mise à jour et, selon le jeu, les
     * indicateurs dérivés côté serveur (flexibilité Move Fast, plan Predictive Puzzle).
     *
     * @param session               session après enregistrement du résultat
     * @param moveFastReport         indicateurs Move Fast (null pour les autres jeux)
     * @param previsionPuzzleReport  indicateurs Predictive Puzzle (null sinon)
     * @param memoryQuestReport      indicateurs « J'investigue » (null sinon)
     * @param emotionalRadarReport   indicateurs « Emotional Radar » (null sinon)
     * @param scoreBreakdown         détail du calcul du score (panneau), null si non supporté
     */
    public record Outcome(GameSession session,
                          MoveFastFlexibilityReport moveFastReport,
                          PrevisionPuzzleReport previsionPuzzleReport,
                          MemoryQuestReport memoryQuestReport,
                          DecisionReport decisionReport,
                          EmotionalRadarReport emotionalRadarReport,
                          ReflectivePauseReport reflectivePauseReport,
                          ScoreBreakdown scoreBreakdown) {
    }

    @Transactional
    public Outcome execute(SubmitGameResultCommand command) {
        GameSession session = repository.findById(command.sessionId())
            .orElseThrow(() -> new NotFoundException(
                "Session introuvable : " + command.sessionId()));

        Score score = computeScore(command.miniGame(), command);
        session.recordResult(command.miniGame(), score, scoring);

        GameSession saved = repository.save(session);

        // Calibrage appareil (optionnel) : persisté tel quel pour audit ; la
        // correction s'applique au calcul des indicateurs, jamais aux temps bruts.
        if (command.deviceCalibration() != null) {
            calibrationRepository.save(command.deviceCalibration());
        }

        // Publication des Domain Events après persistance réussie — depuis l'agrégat qui
        // les a enregistrés, jamais depuis ce que renvoie le dépôt. `save` reconstruit une
        // GameSession via `rehydrate`, et une session reconstruite ne porte aucun
        // événement : `saved.domainEvents()` était toujours vide, donc
        // GameResultRecordedEvent n'a jamais été publié. Conséquence silencieuse — la
        // projection soft skills de Recruitment n'était jamais alimentée par une partie
        // jouée, et le résumé IA correspondant jamais généré. Même défaut que celui
        // corrigé sur SubmitTestAttemptUseCase et ChangeJobOfferStatusUseCase.
        session.domainEvents().forEach(eventPublisher::publishEvent);
        session.clearEvents();

        // « Je Décide » : le détail par dimension vient du report (catalogue), pas
        // des seules métriques — on le calcule une fois et le réutilise.
        DecisionReport decisionReport = decisionReport(command);

        // Détail du score (panneau) : mêmes données + même barème que le score.
        // Emotional Radar et « Je Décide » ont une signature dédiée car leur détail
        // ne dérive pas des métriques reçues.
        ScoreBreakdown scoreBreakdown;
        if (decisionReport != null) {
            scoreBreakdown = breakdown.decision(decisionReport, score);
        } else if (command.miniGame() == MiniGame.EMOTIONAL_RADAR_CORE) {
            scoreBreakdown = breakdown.emotionalRadar(gradedAnswers(command), score);
        } else {
            scoreBreakdown = breakdown.build(command.metrics(), score);
        }

        return new Outcome(saved, moveFastReport(command, saved),
            previsionPuzzleReport(command), memoryQuestReport(command),
            decisionReport, emotionalRadarReport(command),
            reflectivePauseReport(command), scoreBreakdown);
    }

    /** Dérive les trois indicateurs de maîtrise de l'impulsivité ; null sinon. */
    private ReflectivePauseReport reflectivePauseReport(SubmitGameResultCommand command) {
        if (command.miniGame() != MiniGame.REFLECTIVE_PAUSE_CORE
            || !(command.metrics() instanceof ReflectivePauseMetrics metrics)) {
            return null;
        }
        return reflectivePause.report(metrics);
    }

    /** Dérive les indicateurs de reconnaissance émotionnelle ; null sinon. */
    private EmotionalRadarReport emotionalRadarReport(SubmitGameResultCommand command) {
        if (command.miniGame() != MiniGame.EMOTIONAL_RADAR_CORE
            || !(command.metrics() instanceof EmotionalRadarMetrics metrics)) {
            return null;
        }
        // Croise les réponses notées serveur (justesse) avec les temps mesurés client.
        return emotionalRadar.report(
            emotionalRadarAnswers.findBySessionId(command.sessionId()), metrics);
    }

    /** Dérive les indicateurs pour « Je Décide » (dimensions, SCW, validité) ; null sinon. */
    private DecisionReport decisionReport(SubmitGameResultCommand command) {
        if (command.miniGame() != MiniGame.DECISION_CORE
            || !(command.metrics() instanceof DecisionMetrics metrics)) {
            return null;
        }
        // Le calibrage appareil ajuste le temps imparti DT (double ajustement langue + calibrage).
        return decision.report(metrics, calibration.offsetMs(command.deviceCalibration()));
    }

    /** Dérive les indicateurs qualitatifs pour « Predictive Puzzle » ; null sinon. */
    private PrevisionPuzzleReport previsionPuzzleReport(SubmitGameResultCommand command) {
        if (command.miniGame() != MiniGame.PREVISION_PUZZLE
            || !(command.metrics() instanceof PrevisionPuzzleMetrics metrics)) {
            return null;
        }
        return PrevisionPuzzleReport.from(metrics);
    }

    /** Dérive les indicateurs de flexibilité pour « Je bouge » ; null sinon. */
    private MoveFastFlexibilityReport moveFastReport(SubmitGameResultCommand command, GameSession saved) {
        if (command.miniGame() != MiniGame.MOVE_FAST_CORE
            || !(command.metrics() instanceof MoveFastMetrics metrics)) {
            return null;
        }
        Instant end = saved.completedAt() != null ? saved.completedAt() : Instant.now();
        int durationSec = (int) Math.max(0, Duration.between(saved.startedAt(), end).toSeconds());

        // Le score Move Fast ne dépend pas du temps ; le calibrage n'affecte QUE
        // les indicateurs comportementaux (versions *_adjusted).
        DeviceCalibration cal = command.deviceCalibration();
        double offset = calibration.offsetMs(cal);
        boolean applied = cal != null;
        boolean reliable = cal == null || !cal.reducedReliability();

        return MoveFastFlexibilityReport.from(
            metrics, durationSec, saved.status().name().toLowerCase(),
            offset, applied, reliable);
    }

    /** Sélectionne le barème selon le mini-jeu. */
    private Score computeScore(MiniGame miniGame, SubmitGameResultCommand command) {
        return switch (miniGame) {
            case OPTIMAL_PATH -> scoring.scoreOptimalPath(expectMetrics(command, PlanifikMetrics.class));
            case TASK_SCHEDULING -> scoring.scoreTaskScheduling(expectMetrics(command, TaskSchedulingMetrics.class));
            case MOVE_FAST_CORE -> scoring.scoreMoveFast(expectMetrics(command, MoveFastMetrics.class));
            case PREVISION_PUZZLE -> scoring.scorePrevisionPuzzle(expectMetrics(command, PrevisionPuzzleMetrics.class));
            case MEMORY_QUEST_CORE -> memoryQuest.score(
                expectMetrics(command, MemoryQuestMetrics.class),
                calibration.offsetMs(command.deviceCalibration()));
            case DECISION_CORE -> decision.score(
                expectMetrics(command, DecisionMetrics.class),
                calibration.offsetMs(command.deviceCalibration()));
            // ⚠️ Seul mini-jeu dont le score NE dérive PAS des métriques reçues : il
            // est reconstruit depuis les réponses que le serveur a notées scène par
            // scène. Les métriques ne servent qu'aux indicateurs comportementaux.
            case EMOTIONAL_RADAR_CORE -> {
                expectMetrics(command, EmotionalRadarMetrics.class);
                yield emotionalRadar.score(gradedAnswers(command));
            }
            case REFLECTIVE_PAUSE_CORE -> reflectivePause.score(
                expectMetrics(command, ReflectivePauseMetrics.class));
        };
    }

    /** Réponses notées et persistées par le serveur — source de vérité du score. */
    private List<EmotionalRadarAnswer> gradedAnswers(SubmitGameResultCommand command) {
        List<EmotionalRadarAnswer> answers =
            emotionalRadarAnswers.findBySessionId(command.sessionId());
        if (answers.isEmpty()) {
            throw new IllegalArgumentException(
                "Aucune scène validée pour cette session : soumission refusée.");
        }
        return answers;
    }

    /** Dérive les indicateurs pour « J'investigue » ; null sinon. */
    private MemoryQuestReport memoryQuestReport(SubmitGameResultCommand command) {
        if (command.miniGame() != MiniGame.MEMORY_QUEST_CORE
            || !(command.metrics() instanceof MemoryQuestMetrics metrics)) {
            return null;
        }
        // Le calibrage appareil est enfin exploité pour un SCORE (via le timeout),
        // pas seulement des indicateurs (socle DeviceCalibration/CalibrationService réutilisé).
        return memoryQuest.report(metrics, calibration.offsetMs(command.deviceCalibration()));
    }

    private <T> T expectMetrics(SubmitGameResultCommand command, Class<T> type) {
        if (!type.isInstance(command.metrics())) {
            throw new IllegalArgumentException(
                "Métriques incompatibles avec " + command.miniGame());
        }
        return type.cast(command.metrics());
    }
}
