package com.zennyt.games.domain.service;

import com.zennyt.games.domain.config.EmotionalRadarConfig;
import com.zennyt.games.domain.config.MemoryQuestConfig;
import com.zennyt.games.domain.config.MoveFastConfig;
import com.zennyt.games.domain.config.OptimalPathConfig;
import com.zennyt.games.domain.config.PrevisionPuzzleConfig;
import com.zennyt.games.domain.config.ReflectivePauseConfig;
import com.zennyt.games.domain.config.TaskSchedulingConfig;
import com.zennyt.games.domain.vo.DecisionReport;
import com.zennyt.games.domain.vo.ContinuousAttentionReport;
import com.zennyt.games.domain.vo.GameMetrics;
import com.zennyt.games.domain.vo.MemoryQuestMetrics;
import com.zennyt.games.domain.vo.MoveFastMetrics;
import com.zennyt.games.domain.vo.OptimalPathLevel;
import com.zennyt.games.domain.vo.PlanifikMetrics;
import com.zennyt.games.domain.vo.PrevisionPuzzleLevel;
import com.zennyt.games.domain.vo.PrevisionPuzzleMetrics;
import com.zennyt.games.domain.vo.ReflectivePauseMetrics;
import com.zennyt.games.domain.vo.Score;
import com.zennyt.games.domain.vo.TaskSchedulingMetrics;
import com.zennyt.games.domain.vo.ScoreBreakdown;
import com.zennyt.games.domain.vo.ScoreBreakdown.Line;

import java.util.ArrayList;
import java.util.List;

/**
 * Construit le <b>détail du score</b> (panneau « d'où viennent mes points »)
 * comme une suite de lignes, à partir des mêmes métriques et du même barème que
 * le calcul du score. Java pur : aucune nouvelle règle, aucun recalcul côté
 * client. Les libellés suivent {@code GAMES_MODULE.md}.
 *
 * <p>⚠️ PARITÉ MOCK ⇄ BACKEND : le mock mobile ({@code games_mock_repository.dart},
 * {@code _buildBreakdown}) reproduit ces lignes à l'identique.
 */
public class ScoreBreakdownService {

    /**
     * Long Rosvold — le /100 est la moyenne unique des deux balanced
     * accuracies. RT, d-prime et biais restent informatifs et hors score.
     */
    public ScoreBreakdown continuousAttention(
            ContinuousAttentionReport report, Score score) {
        List<Line> lines = new ArrayList<>();
        lines.add(Line.note("Score provisoire = moyenne de la balanced accuracy "
            + "X_TEST et AX_TEST, arrondie une seule fois. Entraînement, temps, "
            + "d-prime et biais c sont hors score."));
        lines.add(Line.info("X_TEST — balanced accuracy",
            report.xPhase().balancedAccuracyPercent() + " %"));
        lines.add(Line.info("AX_TEST — balanced accuracy",
            report.axPhase().balancedAccuracyPercent() + " %"));
        lines.add(Line.info("Validité technique",
            report.sessionValid() ? "valide" : String.join(", ", report.validityIssues())));
        lines.add(Line.total("Score descriptif", score.rawPoints(), score.maxPoints()));
        return new ScoreBreakdown(lines);
    }

    /** Détail selon le type de métriques ; {@code null} si non supporté. */
    public ScoreBreakdown build(GameMetrics metrics, Score score) {
        if (metrics instanceof MoveFastMetrics m) {
            return moveFast(m, score);
        }
        if (metrics instanceof PlanifikMetrics m) {
            return optimalPath(m, score);
        }
        if (metrics instanceof TaskSchedulingMetrics m) {
            return taskScheduling(m, score);
        }
        if (metrics instanceof PrevisionPuzzleMetrics m) {
            return previsionPuzzle(m, score);
        }
        if (metrics instanceof MemoryQuestMetrics m) {
            return memoryQuest(m, score);
        }
        if (metrics instanceof ReflectivePauseMetrics m) {
            return reflectivePause(m, score);
        }
        return null;
    }

    /** Reflective Pause — trois indicateurs pondérés 3 + 4 + 3, total /10. */
    public ScoreBreakdown reflectivePause(ReflectivePauseMetrics m, Score score) {
        int total = m.moments().size();
        double controlled = ReflectivePauseConfig.criterionScore(
            m.controlledReactionCount(), total, ReflectivePauseConfig.CONTROLLED_REACTION_MAX);
        double nonImpulsive = ReflectivePauseConfig.criterionScore(
            m.nonImpulsiveCount(), total, ReflectivePauseConfig.NON_IMPULSIVE_MAX);
        double stepBack = ReflectivePauseConfig.criterionScore(
            m.stepBackCount(), total, ReflectivePauseConfig.STEP_BACK_MAX);
        List<Line> lines = new ArrayList<>();
        lines.add(Line.note("Temps contrôlé /3 + réponses non impulsives /4 + "
            + "capacité à prendre du recul /3 ; la somme est arrondie une fois."));
        lines.add(Line.info("Controlled reaction time",
            m.controlledReactionCount() + "/" + total + " → " + controlled + "/3"));
        lines.add(Line.info("Non-impulsive responses",
            m.nonImpulsiveCount() + "/" + total + " → " + nonImpulsive + "/4"));
        lines.add(Line.info("Ability to step back",
            m.stepBackCount() + "/" + total + " → " + stepBack + "/3"));
        lines.add(Line.total("Total", score.rawPoints(), score.maxPoints()));
        return new ScoreBreakdown(lines);
    }

    /**
     * « Je Décide » — une ligne par dimension /18, puis brut /90, puis SCW /100.
     * Le détail par dimension vient du {@link DecisionReport} (catalogue serveur),
     * pas des seules métriques : d'où une signature dédiée.
     */
    public ScoreBreakdown decision(DecisionReport report, Score score) {
        List<Line> lines = new ArrayList<>();
        lines.add(Line.note("Chaque dimension est notée /18 (6 items × 3) ; brut = somme /90 ; "
            + "SCW = score composite standardisé pondéré /100 (poids provisoires)."));
        for (DecisionReport.DimensionScore d : report.dimensions()) {
            if (d.exploitable() && d.score() != null) {
                lines.add(Line.criterion(d.dimension().name(),
                    d.answeredItems() + " items", d.score(), d.maxScore()));
            } else {
                lines.add(Line.info(d.dimension().name(), "bloc non exploitable (> 2 items manquants)"));
            }
        }
        lines.add(Line.subtotal("Brut", report.rawScore(), report.rawMax()));
        lines.add(Line.total("SCW", score.rawPoints(), score.maxPoints()));
        return new ScoreBreakdown(lines);
    }

    /**
     * « Emotional Radar » — une ligne par critère et par scène, puis le total.
     *
     * <p>Signature dédiée (comme {@link #decision}) : le détail provient des
     * réponses <b>notées serveur</b>, jamais des métriques reçues du client — ces
     * dernières ne portent aucune réponse.
     */
    public ScoreBreakdown emotionalRadar(
            List<com.zennyt.games.domain.vo.EmotionalRadarAnswer> answers, Score score) {
        List<Line> lines = new ArrayList<>();
        lines.add(Line.note("Chaque scène vaut 9 points : émotion de base 3, nuance 4, "
            + "intensité 2 (écart 0 → 2 pts · écart 1 → 1 pt · écart ≥ 2 → 0)."));
        for (com.zennyt.games.domain.vo.EmotionalRadarAnswer a : answers) {
            int sceneNumber = a.sceneOrder();
            lines.add(Line.criterion("Scène " + sceneNumber + " — Émotion de base",
                a.selectedEmotion() + " / attendu " + a.expectedEmotion(),
                a.emotionPoints(), EmotionalRadarConfig.EMOTION_POINTS));
            lines.add(Line.criterion("Scène " + sceneNumber + " — Nuance",
                a.selectedNuance() + " / attendu " + a.expectedNuance(),
                a.nuancePoints(), EmotionalRadarConfig.NUANCE_POINTS));
            lines.add(Line.criterion("Scène " + sceneNumber + " — Intensité",
                a.selectedIntensity() + " / attendu " + a.expectedIntensity()
                    + " (écart " + a.intensityGap() + ")",
                a.intensityPoints(), EmotionalRadarConfig.INTENSITY_POINTS));
            lines.add(Line.subtotal("Scène " + sceneNumber,
                a.scenePoints(), EmotionalRadarConfig.POINTS_PER_SCENE));
        }
        lines.add(Line.total("Total (" + answers.size() + " scènes)",
            score.rawPoints(), score.maxPoints()));
        return new ScoreBreakdown(lines);
    }

    /** « J'investigue » — notes par tâche (0–5) puis composite /100. */
    public ScoreBreakdown memoryQuest(MemoryQuestMetrics m, Score score) {
        List<Line> lines = new ArrayList<>();
        lines.add(Line.note("Chaque tâche est notée sur 5 ; le score = moyenne des "
            + "tâches jouées, ramenée sur 100."));
        lines.add(Line.criterion("Rappel même ordre", percent(m.sameAccuracy()),
            MemoryQuestConfig.taskScore(m.sameAccuracy()), MemoryQuestConfig.TASK_MAX_SCORE));
        lines.add(Line.criterion("Rappel inverse", percent(m.reverseAccuracy()),
            MemoryQuestConfig.taskScore(m.reverseAccuracy()), MemoryQuestConfig.TASK_MAX_SCORE));
        if (m.missionBPlayed()) {
            lines.add(Line.criterion("Restauration d'objets", percent(m.restoreAccuracy()),
                MemoryQuestConfig.taskScore(m.restoreAccuracy()), MemoryQuestConfig.TASK_MAX_SCORE));
        }
        if (m.distractionPlayed()) {
            lines.add(Line.criterion("Rappel après distraction", percent(m.afterDistractionAccuracy()),
                MemoryQuestConfig.taskScore(m.afterDistractionAccuracy()), MemoryQuestConfig.TASK_MAX_SCORE));
            lines.add(Line.info("Question rapide",
                m.distractionQuestionCorrect() ? "correcte" : "manquée"));
        }
        lines.add(Line.total("Composite", score.rawPoints(), score.maxPoints()));
        return new ScoreBreakdown(lines);
    }

    /** Move Fast — escalade (points de jeu + bonus de fin). */
    public ScoreBreakdown moveFast(MoveFastMetrics m, Score score) {
        MoveFastConfig.Replay replay = MoveFastConfig.replay(m.correctResponses());
        List<Line> lines = new ArrayList<>();
        lines.add(Line.note("Chaque bonne réponse = " + MoveFastConfig.BASE_POINTS_PER_CORRECT
            + " × multiplicateur ; +1 au multiplicateur toutes les "
            + MoveFastConfig.CORRECT_STREAK_FOR_UPGRADE + " bonnes réponses d'affilée."));
        lines.add(Line.info("Bonnes réponses", String.valueOf(m.correctCount())));
        lines.add(Line.info("Multiplicateur atteint", "×" + replay.finalMultiplier()));
        lines.add(Line.info("Points de jeu", String.valueOf(replay.gamePoints())));
        lines.add(Line.info("Bonus de fin", "×" + replay.finalMultiplier() + " × "
            + MoveFastConfig.FINAL_BONUS_MULTIPLIER + " = " + replay.finalBonus()));
        lines.add(Line.total("Total", score.rawPoints(), score.maxPoints()));
        return new ScoreBreakdown(lines);
    }

    /** Ordonnancement de tâches — 4 critères (3 + 3 + 2 + 2) → /10. */
    public ScoreBreakdown taskScheduling(TaskSchedulingMetrics m, Score score) {
        int coherencePts = Math.max(0, Math.min(
            TaskSchedulingConfig.PLANNING_COHERENCE_MAX_POINTS, m.planningCoherence()));
        int adjustmentPts = TaskSchedulingConfig.adjustmentScore(m.adjustmentCount());
        List<Line> lines = new ArrayList<>();
        lines.add(Line.criterion("Dépendances respectées",
            m.dependenciesRespected() ? "oui" : "non",
            m.dependenciesRespected() ? TaskSchedulingConfig.DEPENDENCIES_POINTS : 0,
            TaskSchedulingConfig.DEPENDENCIES_POINTS));
        lines.add(Line.criterion("Contraintes horaires",
            m.timeConstraintsRespected() ? "oui" : "non",
            m.timeConstraintsRespected() ? TaskSchedulingConfig.TIME_CONSTRAINTS_POINTS : 0,
            TaskSchedulingConfig.TIME_CONSTRAINTS_POINTS));
        lines.add(Line.criterion("Cohérence du planning",
            coherenceLabel(m.planningCoherence()), coherencePts,
            TaskSchedulingConfig.PLANNING_COHERENCE_MAX_POINTS));
        lines.add(Line.criterion("Réajustements", String.valueOf(m.adjustmentCount()),
            adjustmentPts, TaskSchedulingConfig.ADJUSTMENT_MAX_POINTS));
        lines.add(Line.total("Total", score.rawPoints(), score.maxPoints()));
        return new ScoreBreakdown(lines);
    }

    private static String coherenceLabel(int coherence) {
        return switch (coherence) {
            case 2 -> "clair";
            case 1 -> "partiel";
            default -> "désordonné";
        };
    }

    /** Optimal Path — barème par niveau puis moyenne. */
    public ScoreBreakdown optimalPath(PlanifikMetrics m, Score score) {
        List<Line> lines = new ArrayList<>();
        int n = m.levels().size();
        for (int i = 0; i < n; i++) {
            OptimalPathLevel lvl = m.levels().get(i);
            int optimalPts = lvl.deviationFromOptimal() <= OptimalPathConfig.OPTIMAL_PATH_TOLERANCE
                ? OptimalPathConfig.OPTIMAL_PATH_POINTS : 0;
            int attemptsPts = OptimalPathConfig.attemptScore(lvl.attempts());
            int zonesPts = switch (lvl.costlyZonesAvoided()) {
                case TOTAL -> OptimalPathConfig.COSTLY_ZONES_POINTS;
                case PARTIAL -> OptimalPathConfig.COSTLY_ZONES_PARTIAL_POINTS;
                case NONE -> 0;
            };
            int secondaryPts = switch (lvl.secondaryObjectivesReached()) {
                case YES -> OptimalPathConfig.SECONDARY_OBJECTIVE_POINTS;
                case PARTIAL -> OptimalPathConfig.SECONDARY_OBJECTIVE_PARTIAL_POINTS;
                case NO -> 0;
            };
            int levelScore = optimalPts + attemptsPts + zonesPts + secondaryPts;

            if (n > 1) {
                lines.add(Line.info("Niveau " + (i + 1), null));
            }
            lines.add(Line.criterion("Chemin optimal (±10 %)",
                percent(lvl.deviationFromOptimal()), optimalPts, OptimalPathConfig.OPTIMAL_PATH_POINTS));
            lines.add(Line.criterion("Essais", String.valueOf(lvl.attempts()),
                attemptsPts, OptimalPathConfig.MAX_ATTEMPTS));
            lines.add(Line.criterion("Zones coûteuses évitées", zonesLabel(lvl),
                zonesPts, OptimalPathConfig.COSTLY_ZONES_POINTS));
            lines.add(Line.criterion("Objectif secondaire", secondaryLabel(lvl),
                secondaryPts, OptimalPathConfig.SECONDARY_OBJECTIVE_POINTS));
            lines.add(Line.subtotal("Niveau " + (i + 1), levelScore, OptimalPathConfig.MAX_POINTS));
        }
        lines.add(Line.total("Moyenne des " + n + " niveaux",
            score.rawPoints(), OptimalPathConfig.MAX_POINTS));
        return new ScoreBreakdown(lines);
    }

    /** Predictive Puzzle — barème catégoriel par niveau puis moyenne. */
    public ScoreBreakdown previsionPuzzle(PrevisionPuzzleMetrics m, Score score) {
        List<Line> lines = new ArrayList<>();
        int n = m.levels().size();
        for (int i = 0; i < n; i++) {
            PrevisionPuzzleLevel lvl = m.levels().get(i);
            int firstTryPts = PrevisionPuzzleConfig.firstTryScore(lvl.firstTrySuccess());
            int seqPts = PrevisionPuzzleConfig.sequenceErrorsScore(lvl.sequenceErrors());
            int extraPts = PrevisionPuzzleConfig.extraMovesScore(lvl.plannedMoves(), lvl.optimalMoves());
            int levelScore = firstTryPts + seqPts + extraPts;

            if (n > 1) {
                lines.add(Line.info("Niveau " + (i + 1), lvl.discCount() + " disques"));
            }
            lines.add(Line.criterion("Réussi du 1er coup",
                lvl.firstTrySuccess() ? "oui" : "non", firstTryPts, PrevisionPuzzleConfig.FIRST_TRY_POINTS));
            lines.add(Line.criterion("Erreurs de séquence",
                String.valueOf(lvl.sequenceErrors()), seqPts, 3));
            lines.add(Line.criterion("Coups superflus",
                percent(Math.max(0.0, lvl.extraMovesRatio())), extraPts, 3));
            lines.add(Line.subtotal("Niveau " + (i + 1), levelScore, PrevisionPuzzleConfig.MAX_POINTS));
        }
        lines.add(Line.total("Moyenne des " + n + " niveaux",
            score.rawPoints(), PrevisionPuzzleConfig.MAX_POINTS));
        return new ScoreBreakdown(lines);
    }

    private static String percent(double ratio) {
        return Math.round(ratio * 100) + " %";
    }

    private static String zonesLabel(OptimalPathLevel lvl) {
        return switch (lvl.costlyZonesAvoided()) {
            case TOTAL -> "évitement total";
            case PARTIAL -> "évitement partiel";
            case NONE -> "non évitées";
        };
    }

    private static String secondaryLabel(OptimalPathLevel lvl) {
        return switch (lvl.secondaryObjectivesReached()) {
            case YES -> "atteint";
            case PARTIAL -> "partiel";
            case NO -> "manqué";
        };
    }
}
