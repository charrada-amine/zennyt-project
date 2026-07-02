package com.zennyt.games.domain.service;

import com.zennyt.games.domain.vo.PlanifikMetrics;
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
}
