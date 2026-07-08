package com.zennyt.games.domain.service;

import com.zennyt.games.domain.config.MoveFastConfig;
import com.zennyt.games.domain.config.OptimalPathConfig;
import com.zennyt.games.domain.config.PrevisionPuzzleConfig;
import com.zennyt.games.domain.vo.GameMetrics;
import com.zennyt.games.domain.vo.MoveFastMetrics;
import com.zennyt.games.domain.vo.OptimalPathLevel;
import com.zennyt.games.domain.vo.PlanifikMetrics;
import com.zennyt.games.domain.vo.PrevisionPuzzleLevel;
import com.zennyt.games.domain.vo.PrevisionPuzzleMetrics;
import com.zennyt.games.domain.vo.Score;
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

    /** Détail selon le type de métriques ; {@code null} si non supporté. */
    public ScoreBreakdown build(GameMetrics metrics, Score score) {
        if (metrics instanceof MoveFastMetrics m) {
            return moveFast(m, score);
        }
        if (metrics instanceof PlanifikMetrics m) {
            return optimalPath(m, score);
        }
        if (metrics instanceof PrevisionPuzzleMetrics m) {
            return previsionPuzzle(m, score);
        }
        return null;
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
