package com.zennyt.games.application.usecase;

import com.zennyt.games.application.command.SubmitGameResultCommand;
import com.zennyt.games.domain.catalog.DecisionFormCatalog;
import com.zennyt.games.domain.catalog.DecisionScenarioCatalog;
import com.zennyt.games.domain.model.GameSession;
import com.zennyt.games.domain.model.MiniGame;
import com.zennyt.games.domain.repository.DeviceCalibrationRepository;
import com.zennyt.games.domain.repository.ContinuousAttentionMetricsRepository;
import com.zennyt.games.domain.repository.CoordinationMetricsRepository;
import com.zennyt.games.domain.repository.ObjectLocationMetricsRepository;
import com.zennyt.games.domain.repository.EmotionalRadarAnswerRepository;
import com.zennyt.games.domain.repository.GameSessionRepository;
import com.zennyt.games.domain.service.CalibrationService;
import com.zennyt.games.domain.service.ContinuousAttentionScoringService;
import com.zennyt.games.domain.service.CoordinationScoringService;
import com.zennyt.games.domain.service.ObjectLocationScoringService;
import com.zennyt.games.domain.service.DecisionScoringService;
import com.zennyt.games.domain.service.EmotionalRadarScoringService;
import com.zennyt.games.domain.service.MemoryQuestScoringService;
import com.zennyt.games.domain.service.PlanifikScoringService;
import com.zennyt.games.domain.service.ReflectivePauseScoringService;
import com.zennyt.games.domain.service.ScoreBreakdownService;
import com.zennyt.games.domain.vo.DecisionItemResponse;
import com.zennyt.games.domain.vo.DecisionMetrics;
import com.zennyt.games.domain.vo.ContinuousAttentionMetrics;
import com.zennyt.games.domain.vo.ContinuousAttentionReport;
import com.zennyt.games.domain.vo.CoordinationMetrics;
import com.zennyt.games.domain.vo.CoordinationReport;
import com.zennyt.games.domain.vo.ObjectLocationMetrics;
import com.zennyt.games.domain.vo.ObjectLocationReport;
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
import com.zennyt.games.domain.vo.GameType;
import com.zennyt.games.domain.vo.SessionStatus;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Set;

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
    private final ContinuousAttentionMetricsRepository continuousAttentionMetrics;
    private final CoordinationMetricsRepository coordinationMetrics;
    private final ObjectLocationMetricsRepository objectLocationMetrics;
    private final ApplicationEventPublisher eventPublisher;
    private final PlanifikScoringService scoring = new PlanifikScoringService();
    private final CalibrationService calibration = new CalibrationService();
    private final ScoreBreakdownService breakdown = new ScoreBreakdownService();
    private final MemoryQuestScoringService memoryQuest = new MemoryQuestScoringService();
    private final EmotionalRadarScoringService emotionalRadar = new EmotionalRadarScoringService();
    private final ReflectivePauseScoringService reflectivePause =
        new ReflectivePauseScoringService();
    private final ContinuousAttentionScoringService continuousAttention =
        new ContinuousAttentionScoringService();
    private final CoordinationScoringService coordination =
        new CoordinationScoringService();
    private final ObjectLocationScoringService objectLocation =
        new ObjectLocationScoringService();
    private final DecisionScoringService decision;
    private final DecisionFormCatalog decisionForms;

    public SubmitGameResultUseCase(GameSessionRepository repository,
                                   DeviceCalibrationRepository calibrationRepository,
                                   EmotionalRadarAnswerRepository emotionalRadarAnswers,
                                   ContinuousAttentionMetricsRepository continuousAttentionMetrics,
                                   CoordinationMetricsRepository coordinationMetrics,
                                   ObjectLocationMetricsRepository objectLocationMetrics,
                                   ApplicationEventPublisher eventPublisher,
                                   DecisionScenarioCatalog decisionCatalog,
                                   DecisionFormCatalog decisionForms) {
        this.repository = repository;
        this.calibrationRepository = calibrationRepository;
        this.emotionalRadarAnswers = emotionalRadarAnswers;
        this.continuousAttentionMetrics = continuousAttentionMetrics;
        this.coordinationMetrics = coordinationMetrics;
        this.objectLocationMetrics = objectLocationMetrics;
        this.eventPublisher = eventPublisher;
        // « Je Décide » : deux ports distincts. Le catalogue de NOTATION fournit la
        // qualité des options ; le catalogue de FORMES dit quels items la session
        // avait le droit de recevoir. L'impl vivante des deux est
        // DatabaseDecisionScenarioCatalog (banque de 120 items, V59).
        this.decision = new DecisionScoringService(decisionCatalog);
        this.decisionForms = decisionForms;
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
                          ContinuousAttentionReport continuousAttentionReport,
                          CoordinationReport coordinationReport,
                          ObjectLocationReport objectLocationReport,
                          ScoreBreakdown scoreBreakdown) {
    }

    @Transactional
    public Outcome execute(SubmitGameResultCommand command) {
        // Sérialise toutes les soumissions d'une même session. Sans ce verrou,
        // un retry invalide concurrent pouvait remplacer l'audit brut d'un
        // résultat déjà validé.
        GameSession session = repository.findByIdForUpdate(command.sessionId())
            .orElseThrow(() -> new NotFoundException(
                "Session introuvable : " + command.sessionId()));

        // L'UUID du JWT est vérifié avant scoring, persistance brute ou mutation.
        if (!session.playerId().equals(command.playerId())) {
            throw new ForbiddenException(
                "Cette session n'appartient pas au joueur authentifié.");
        }

        if (command.miniGame() == MiniGame.CONTINUOUS_ATTENTION_CORE) {
            return executeContinuousAttention(command, session);
        }
        if (command.miniGame() == MiniGame.COORDINATION_TRACKING_CORE) {
            return executeCoordination(command, session);
        }
        if (command.miniGame() == MiniGame.OBJECT_LOCATION_BINDING_CORE) {
            return executeObjectLocation(command, session);
        }

        assertDecisionItemsMatchAssignedForm(command, session);

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
        // événement : `saved.domainEvents()` serait toujours vide, donc
        // GameResultRecordedEvent ne serait jamais publié — la projection soft skills de
        // Recruitment ne serait alors jamais alimentée par une partie jouée. Même défaut
        // que celui corrigé sur SubmitTestAttemptUseCase et ChangeJobOfferStatusUseCase.
        publishAndClear(session);

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
            reflectivePauseReport(command), null, null, null, scoreBreakdown);
    }

    /**
     * « Je Décide » — les items soumis doivent appartenir à la forme assignée à la
     * session.
     *
     * <p>La forme est relue sur la SESSION, jamais prise dans le payload : sans ce
     * contrôle, un client pourrait répondre à des items qu'on ne lui a pas servis —
     * par exemple ne renvoyer que des items d'une dimension où il sait bien
     * réussir, ou piocher dans les 90 items hors forme. L'imputation par dimension
     * (≤ 2 manquants) reste, elle, un cas légitime : on n'exige pas les 30 items,
     * seulement qu'aucun item étranger ne se glisse dans le lot.
     */
    private void assertDecisionItemsMatchAssignedForm(
            SubmitGameResultCommand command, GameSession session) {

        if (command.miniGame() != MiniGame.DECISION_CORE
            || !(command.metrics() instanceof DecisionMetrics metrics)) {
            return;
        }
        String formCode = session.decisionFormCode();
        if (formCode == null) {
            throw new IllegalStateException(
                "Aucune forme « Je Décide » assignée à la session " + session.id());
        }
        Set<String> allowed = decisionForms.form(formCode).stream()
            .map(DecisionFormCatalog.Content::itemId)
            .collect(java.util.stream.Collectors.toSet());

        List<String> foreign = metrics.items().stream()
            .map(DecisionItemResponse::itemId)
            .filter(id -> !allowed.contains(id))
            .toList();
        if (!foreign.isEmpty()) {
            throw new IllegalArgumentException(
                "Items hors de la forme " + formCode + " : " + foreign);
        }
    }

    /**
     * Voie Long Rosvold : structure et séquence sont rejetées avant écriture.
     * Une capture techniquement invalide mais structurellement fiable est
     * conservée audit-only ; elle ne crée jamais d'Attempt ni d'événement.
     */
    private Outcome executeContinuousAttention(
            SubmitGameResultCommand command, GameSession session) {
        assertContinuousAttentionSubmissionAllowed(session);
        ContinuousAttentionMetrics metrics =
            expectMetrics(command, ContinuousAttentionMetrics.class);

        // Reconstruit d'abord la séquence depuis l'UUID. Toute divergence rejette
        // la soumission avant persistance, Attempt et Domain Event.
        ContinuousAttentionReport report =
            continuousAttention.report(command.sessionId(), metrics);
        Score score = continuousAttention.score(report);
        ScoreBreakdown scoreBreakdown =
            breakdown.continuousAttention(report, score);

        if (!report.sessionValid()) {
            // Retry autorisé : replace ne peut être atteint que tant que la session
            // reste IN_PROGRESS et sans Attempt CPT.
            continuousAttentionMetrics.replace(command.sessionId(), metrics, report);
            if (command.deviceCalibration() != null) {
                calibrationRepository.save(command.deviceCalibration());
            }
            return new Outcome(session, null, null, null, null, null, null,
                report, null, null, scoreBreakdown);
        }

        // L'invariant d'agrégat est appliqué AVANT les écritures. La transaction
        // rend raw trials + Attempt + événement atomiques.
        session.recordResult(command.miniGame(), score, scoring);
        continuousAttentionMetrics.replace(command.sessionId(), metrics, report);
        GameSession saved = repository.save(session);
        if (command.deviceCalibration() != null) {
            calibrationRepository.save(command.deviceCalibration());
        }
        publishAndClear(session);

        return new Outcome(saved, null, null, null, null, null, null,
            report, null, null, scoreBreakdown);
    }

    /**
     * Voie « Je coordonne » : la trace brute est notée uniquement côté serveur.
     * Un run interrompu/incomplet, en arrière-plan ou hors durée valide reste
     * audit-only et peut être remplacé par un retry sur la même session.
     */
    private Outcome executeCoordination(
            SubmitGameResultCommand command, GameSession session) {
        assertCoordinationSubmissionAllowed(session);
        CoordinationMetrics metrics = expectMetrics(command, CoordinationMetrics.class);
        CoordinationReport report = coordination.report(metrics);
        Score score = coordination.score(report);
        ScoreBreakdown scoreBreakdown = breakdown.coordination(report, score);

        if (!report.sessionValid()) {
            coordinationMetrics.replace(command.sessionId(), metrics, report);
            if (command.deviceCalibration() != null) {
                calibrationRepository.save(command.deviceCalibration());
            }
            return new Outcome(session, null, null, null, null, null, null,
                null, report, null, scoreBreakdown);
        }

        session.recordResult(command.miniGame(), score, scoring);
        coordinationMetrics.replace(command.sessionId(), metrics, report);
        GameSession saved = repository.save(session);
        if (command.deviceCalibration() != null) {
            calibrationRepository.save(command.deviceCalibration());
        }
        publishAndClear(session);
        return new Outcome(saved, null, null, null, null, null, null,
            null, report, null, scoreBreakdown);
    }

    /**
     * Voie « Je place » : le serveur reconstruit le layout, rejoue les actions
     * et conserve les runs techniquement invalides sans Attempt ni événement.
     */
    private Outcome executeObjectLocation(
            SubmitGameResultCommand command, GameSession session) {
        assertObjectLocationSubmissionAllowed(session);
        ObjectLocationMetrics metrics =
            expectMetrics(command, ObjectLocationMetrics.class);
        ObjectLocationReport report =
            objectLocation.report(command.sessionId(), metrics);
        Score score = objectLocation.score(report);
        ScoreBreakdown scoreBreakdown = breakdown.objectLocation(report, score);

        if (!report.sessionValid()) {
            objectLocationMetrics.replace(command.sessionId(), metrics, report);
            if (command.deviceCalibration() != null) {
                calibrationRepository.save(command.deviceCalibration());
            }
            return new Outcome(session, null, null, null, null, null, null,
                null, null, report, scoreBreakdown);
        }

        session.recordResult(command.miniGame(), score, scoring);
        objectLocationMetrics.replace(command.sessionId(), metrics, report);
        GameSession saved = repository.save(session);
        if (command.deviceCalibration() != null) {
            calibrationRepository.save(command.deviceCalibration());
        }
        /*
         * PROVISOIRE — score non validé par le psychologue : l'Attempt clôt la
         * session, mais l'événement alimentant Recruitment/Fit Score reste
         * volontairement supprimé. À réactiver uniquement après validation du
         * barème et décision explicite d'intégration inter-contextes.
         */
        session.clearEvents();
        return new Outcome(saved, null, null, null, null, null, null,
            null, null, report, scoreBreakdown);
    }

    private static void assertObjectLocationSubmissionAllowed(GameSession session) {
        if (session.status() != SessionStatus.IN_PROGRESS) {
            throw new IllegalStateException("Session non ouverte : " + session.status());
        }
        if (session.gameType() != GameType.VISUOSPATIAL_MEMORY) {
            throw new IllegalArgumentException(
                MiniGame.OBJECT_LOCATION_BINDING_CORE
                    + " n'appartient pas au type " + session.gameType());
        }
        boolean alreadyRecorded = session.attempts().stream()
            .anyMatch(attempt ->
                attempt.miniGame() == MiniGame.OBJECT_LOCATION_BINDING_CORE);
        if (alreadyRecorded) {
            throw new IllegalStateException(
                "Mini-jeu déjà joué : " + MiniGame.OBJECT_LOCATION_BINDING_CORE);
        }
    }

    private static void assertCoordinationSubmissionAllowed(GameSession session) {
        if (session.status() != SessionStatus.IN_PROGRESS) {
            throw new IllegalStateException("Session non ouverte : " + session.status());
        }
        if (session.gameType() != GameType.VISUOMOTOR_COORDINATION) {
            throw new IllegalArgumentException(
                MiniGame.COORDINATION_TRACKING_CORE
                    + " n'appartient pas au type " + session.gameType());
        }
        boolean alreadyRecorded = session.attempts().stream()
            .anyMatch(attempt ->
                attempt.miniGame() == MiniGame.COORDINATION_TRACKING_CORE);
        if (alreadyRecorded) {
            throw new IllegalStateException(
                "Mini-jeu déjà joué : " + MiniGame.COORDINATION_TRACKING_CORE);
        }
    }

    /**
     * Le repository renvoie une copie réhydratée, volontairement sans événements.
     * Les événements appartiennent donc à l'agrégat muté, pas à la copie sauvée.
     */
    private void publishAndClear(GameSession aggregate) {
        aggregate.domainEvents().forEach(eventPublisher::publishEvent);
        aggregate.clearEvents();
    }

    /**
     * Empêche notamment qu'un retry écrase l'audit d'un résultat déjà validé.
     * Cette garde précède reconstruction et persistance brute.
     */
    private static void assertContinuousAttentionSubmissionAllowed(GameSession session) {
        if (session.status() != SessionStatus.IN_PROGRESS) {
            throw new IllegalStateException("Session non ouverte : " + session.status());
        }
        if (session.gameType() != GameType.CONTINUOUS_ATTENTION) {
            throw new IllegalArgumentException(
                MiniGame.CONTINUOUS_ATTENTION_CORE
                    + " n'appartient pas au type " + session.gameType());
        }
        boolean alreadyRecorded = session.attempts().stream()
            .anyMatch(attempt ->
                attempt.miniGame() == MiniGame.CONTINUOUS_ATTENTION_CORE);
        if (alreadyRecorded) {
            throw new IllegalStateException(
                "Mini-jeu déjà joué : " + MiniGame.CONTINUOUS_ATTENTION_CORE);
        }
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
            case CONTINUOUS_ATTENTION_CORE -> continuousAttention.score(
                continuousAttention.report(command.sessionId(),
                    expectMetrics(command, ContinuousAttentionMetrics.class)));
            case COORDINATION_TRACKING_CORE -> coordination.score(
                coordination.report(expectMetrics(command, CoordinationMetrics.class)));
            case OBJECT_LOCATION_BINDING_CORE -> objectLocation.score(
                objectLocation.report(command.sessionId(),
                    expectMetrics(command, ObjectLocationMetrics.class)));
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
