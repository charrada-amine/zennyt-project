package com.zennyt.games.domain.service;

import com.zennyt.games.domain.config.MoveFastConfig;
import com.zennyt.games.domain.config.OptimalPathConfig;
import com.zennyt.games.domain.config.PrevisionPuzzleConfig;
import com.zennyt.games.domain.vo.OptimalPathLevel;
import com.zennyt.games.domain.vo.PlanifikMetrics;
import com.zennyt.games.domain.vo.GameType;
import com.zennyt.games.domain.vo.MoveFastMetrics;
import com.zennyt.games.domain.vo.PrevisionPuzzleLevel;
import com.zennyt.games.domain.vo.PrevisionPuzzleMetrics;
import com.zennyt.games.domain.vo.Score;

/**
 * Service de domaine : barème déterministe de Planifik.
 *
 * <p>Java pur, sans Spring : c'est une règle métier issue de la fiche
 * « Je planifie », donc testable unitairement et rejouable à l'identique.
 * Le score est <b>calculé serveur</b> à partir des métriques — le client ne
 * transmet jamais de points.
 *
 * <p><b>⚠️ PARITÉ MOCK ⇄ BACKEND.</b> Ce barème (Planifik « Chemin Optimal »,
 * Move Fast, « Predictive Puzzle ») a un <b>miroir mobile exact</b> dans
 * {@code mobile/lib/features/games/data/games_mock_repository.dart}
 * (méthodes {@code _scoreOptimalPath} / {@code _scoreMoveFast} /
 * {@code _scorePrevisionPuzzle}). Toute modification de barème DOIT être
 * répercutée dans les deux fichiers <b>dans la même PR</b>.
 */
public class PlanifikScoringService {

    /**
     * Barème « Chemin Optimal » (sur 10) :
     * <ul>
     *   <li>Respect du chemin optimal ±10% → 4 pts</li>
     *   <li>Nombre d'essais (1 = 3 pts, 2 = 2 pts, 3+ = 1 pt) → 3 pts</li>
     *   <li>Évitement des zones coûteuses → 2 pts</li>
     *   <li>Objectifs secondaires atteints → 1 pt</li>
     * </ul>
     */
    public Score scoreOptimalPath(PlanifikMetrics m) {
        // Chaque niveau est noté /10 ; le score du mini-jeu est la MOYENNE
        // arrondie des niveaux (toujours /10 → un seul Attempt par mini-jeu).
        // ⚠️ Agrégation par moyenne à valider avec le psychologue (voir GAMES_MODULE.md).
        double average = m.levels().stream()
            .mapToInt(this::scoreOptimalPathLevel)
            .average()
            .orElse(0.0);
        int points = (int) Math.round(average);
        points = Math.max(0, Math.min(OptimalPathConfig.MAX_POINTS, points));
        return new Score(points, OptimalPathConfig.MAX_POINTS, interpretMiniGame(points));
    }

    /** Note un niveau de « Chemin Optimal » sur 10 selon le barème de la fiche. */
    private int scoreOptimalPathLevel(OptimalPathLevel level) {
        int points = 0;

        // Respect du chemin optimal (tolérance ±optimal_path_tolerance) → 4 pts sinon 0
        if (level.deviationFromOptimal() <= OptimalPathConfig.OPTIMAL_PATH_TOLERANCE) {
            points += OptimalPathConfig.OPTIMAL_PATH_POINTS;
        }

        // Nombre d'essais (1→3 pts, 2→2 pts, ≥max_attempts→1 pt)
        points += OptimalPathConfig.attemptScore(level.attempts());

        // Évitement des zones coûteuses (TOTAL=2 / PARTIAL=1 / NONE=0)
        points += switch (level.costlyZonesAvoided()) {
            case TOTAL -> OptimalPathConfig.COSTLY_ZONES_POINTS;
            case PARTIAL -> OptimalPathConfig.COSTLY_ZONES_PARTIAL_POINTS;
            case NONE -> 0;
        };

        // Objectifs secondaires (YES=1 / PARTIAL=règle à valider / NO=0)
        points += switch (level.secondaryObjectivesReached()) {
            case YES -> OptimalPathConfig.SECONDARY_OBJECTIVE_POINTS;
            case PARTIAL -> OptimalPathConfig.SECONDARY_OBJECTIVE_PARTIAL_POINTS;
            case NO -> 0;
        };

        return points;
    }

    /**
     * Barème « Je bouge / Move Fast » :
     * <ul>
     *   <li>Multiplicateur initial x1, maximum x10</li>
     *   <li>Réponse correcte : 50 × multiplicateur courant</li>
     *   <li>4 bonnes réponses consécutives : multiplicateur +1, compteur remis à 0</li>
     *   <li>Erreur avec compteur partiel : compteur remis à 0</li>
     *   <li>Erreur avec compteur vide : multiplicateur -1, minimum x1</li>
     *   <li>Bonus final : 250 × multiplicateur de fin</li>
     * </ul>
     */
    public Score scoreMoveFast(MoveFastMetrics m) {
        int points = replayMoveFastScore(m.correctResponses());
        int maxPoints = replayMoveFastScore(allCorrect(m.responseCount()));

        return new Score(points, maxPoints, interpretMoveFast(points * 100.0 / maxPoints));
    }

    /**
     * Barème CATÉGORIEL « Predictive Puzzle » de la fiche (Planifik #3, seule
     * fiche validée « conforme au script »). Noté PAR NIVEAU sur 10 :
     * <ul>
     *   <li>Séquence correcte au 1er essai → 4 pts sinon 0</li>
     *   <li>Erreurs de séquence : 0 → 3 · 1-2 → 2 · ≥3 → 1</li>
     *   <li>Mouvements superflus (ratio) : &lt;10 % → 3 · &lt;25 % → 2 · ≥25 % → 1</li>
     * </ul>
     * Score du mini-jeu = <b>moyenne arrondie</b> des niveaux joués. Un niveau
     * échoué est noté sur ses compteurs réels (pas de « base 4 » forfaitaire).
     * {@code global_plan_success} reste un indicateur qualitatif HORS du /10
     * (exposé via {@code PrevisionPuzzleReport}).
     */
    public Score scorePrevisionPuzzle(PrevisionPuzzleMetrics m) {
        double average = m.levels().stream()
            .mapToInt(this::scorePrevisionPuzzleLevel)
            .average()
            .orElse(0.0);
        int points = (int) Math.round(average);
        points = Math.max(0, Math.min(PrevisionPuzzleConfig.MAX_POINTS, points));
        return new Score(points, PrevisionPuzzleConfig.MAX_POINTS, interpretMiniGame(points));
    }

    /** Note un niveau de « Predictive Puzzle » sur 10 (barème catégoriel de la fiche). */
    private int scorePrevisionPuzzleLevel(PrevisionPuzzleLevel level) {
        return PrevisionPuzzleConfig.levelScore(
            level.firstTrySuccess(), level.sequenceErrors(),
            level.plannedMoves(), level.optimalMoves());
    }

    private int replayMoveFastScore(Iterable<Boolean> responses) {
        int points = 0;
        int multiplier = MoveFastConfig.MIN_MULTIPLIER;
        int streakCounter = 0;

        for (boolean correct : responses) {
            if (correct) {
                points += MoveFastConfig.BASE_POINTS_PER_CORRECT * multiplier;
                streakCounter++;
                if (streakCounter == MoveFastConfig.CORRECT_STREAK_FOR_UPGRADE) {
                    streakCounter = 0;
                    multiplier = Math.min(MoveFastConfig.MAX_MULTIPLIER, multiplier + 1);
                }
                continue;
            }

            if (MoveFastConfig.RESET_STREAK_ON_ERROR && streakCounter > 0) {
                streakCounter = 0;
            } else if (MoveFastConfig.DECREASE_MULTIPLIER_ON_ERROR) {
                multiplier = Math.max(MoveFastConfig.MIN_MULTIPLIER, multiplier - 1);
            }
        }

        return points + (MoveFastConfig.FINAL_BONUS_MULTIPLIER * multiplier);
    }

    private Iterable<Boolean> allCorrect(int count) {
        return java.util.Collections.nCopies(count, true);
    }

    /**
     * Interprétation /10 d'un mini-jeu Planifik (0–3 / 4–6 / 7–10).
     * Bandes provisoires isolées dans {@code OptimalPathConfig}
     * (// AJOUT NON VALIDÉ PAR LE PSYCHOLOGUE). Partagé avec Predictive Puzzle.
     */
    private String interpretMiniGame(int points) {
        return OptimalPathConfig.interpretMiniGame(points);
    }

    /**
     * Interprétation du profil de planification global (sur 30).
     * Barème de la fiche « Je planifie ».
     */
    public String interpretGlobal(int totalRaw) {
        if (totalRaw <= 10) return "Très faible";
        if (totalRaw <= 17) return "Moyen faible";
        if (totalRaw <= 23) return "Moyen";
        if (totalRaw <= 27) return "Bon";
        return "Excellent";
    }

    public String interpretGlobal(GameType gameType, int totalRaw, double normalized) {
        return switch (gameType) {
            case PLANIFIK -> interpretGlobal(totalRaw);
            case MOVE_FAST -> interpretMoveFast(normalized);
            case MEMORY_QUEST, DECISION -> "Non interprété";
        };
    }

    private String interpretMoveFast(double normalized) {
        // Bandes provisoires — voir MoveFastConfig.INTERPRETATION_BANDS
        // (// AJOUT NON VALIDÉ PAR LE PSYCHOLOGUE).
        return MoveFastConfig.interpret(normalized);
    }
}
