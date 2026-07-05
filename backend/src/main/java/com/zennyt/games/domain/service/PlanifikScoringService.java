package com.zennyt.games.domain.service;

import com.zennyt.games.domain.vo.PlanifikMetrics;
import com.zennyt.games.domain.vo.GameType;
import com.zennyt.games.domain.vo.MoveFastMetrics;
import com.zennyt.games.domain.vo.PrevisionPuzzleMetrics;
import com.zennyt.games.domain.vo.Score;

/**
 * Service de domaine : barème déterministe de Planifik.
 *
 * <p>Java pur, sans Spring : c'est une règle métier issue de la fiche
 * « Je planifie », donc testable unitairement et rejouable à l'identique.
 * Le score est <b>calculé serveur</b> à partir des métriques — le client ne
 * transmet jamais de points.
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
        int points = 0;

        // Respect du chemin optimal (±10%)
        if (m.deviationFromOptimal() <= 0.10) {
            points += 4;
        }

        // Nombre d'essais
        points += switch (m.attempts()) {
            case 1 -> 3;
            case 2 -> 2;
            default -> 1;
        };

        // Évitement des zones coûteuses
        if (m.costlyZonesAvoided()) {
            points += 2;
        }

        // Objectifs secondaires
        if (m.secondaryObjectives() > 0) {
            points += 1;
        }

        return new Score(points, 10, interpretMiniGame(points));
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
     * Barème « Predictive Puzzle » (sur 10) :
     * <ul>
     *   <li>Plan complété : base 10 ; plan non complété : base 4</li>
     *   <li>Erreur de séquence : -2 points</li>
     *   <li>Mouvement inutile : -1 point</li>
     *   <li>Retry : -1 point</li>
     * </ul>
     */
    public Score scorePrevisionPuzzle(PrevisionPuzzleMetrics m) {
        int points = m.targetCompleted() ? 10 : 4;
        points -= m.sequenceErrors() * 2;
        points -= m.unnecessaryMoves();
        points -= m.retries();
        points = Math.max(0, Math.min(10, points));
        return new Score(points, 10, interpretMiniGame(points));
    }

    private int replayMoveFastScore(Iterable<Boolean> responses) {
        int points = 0;
        int multiplier = 1;
        int streakCounter = 0;

        for (boolean correct : responses) {
            if (correct) {
                points += 50 * multiplier;
                streakCounter++;
                if (streakCounter == 4) {
                    streakCounter = 0;
                    multiplier = Math.min(10, multiplier + 1);
                }
                continue;
            }

            if (streakCounter > 0) {
                streakCounter = 0;
            } else {
                multiplier = Math.max(1, multiplier - 1);
            }
        }

        return points + (250 * multiplier);
    }

    private Iterable<Boolean> allCorrect(int count) {
        return java.util.Collections.nCopies(count, true);
    }

    /** Interprétation « Chemin Optimal » : 0–3 Très faible, 4–6 Moyen, 7–10 Bon à excellent. */
    private String interpretMiniGame(int points) {
        if (points <= 3) return "Très faible";
        if (points <= 6) return "Moyen";
        return "Bon à excellent";
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
        if (normalized < 40) return "Très faible";
        if (normalized < 60) return "Moyen faible";
        if (normalized < 75) return "Moyen";
        if (normalized < 90) return "Bon";
        return "Excellent";
    }
}
