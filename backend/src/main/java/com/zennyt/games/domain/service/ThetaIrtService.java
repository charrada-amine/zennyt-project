package com.zennyt.games.domain.service;

import com.zennyt.games.domain.config.EmotionalRadarV2ProvisionalRules;
import com.zennyt.games.domain.vo.RadarSceneOutcome;
import com.zennyt.games.domain.vo.RadarThetaEstimate;

import java.util.List;

/**
 * Couche décisionnelle theta (IRT) d'« Emotional Radar v2 » — <b>ISOLÉE et
 * VERROUILLÉE</b>. Estime la compétence continue du joueur en pondérant chaque
 * réponse par la difficulté réelle de la scène (distance sémantique), à la manière
 * d'un classement Elo : réussir une scène difficile (émotions proches) compte
 * beaucoup plus que réussir une scène facile.
 *
 * <p><b>Modèle 2PL</b> : P(correct | θ) = 1 / (1 + exp(−a·(θ − b_i))), avec b_i dérivé
 * de la distance sémantique de l'item (théorique, PROVISOIRE). θ est estimé par
 * maximum de vraisemblance (Newton-Raphson). L'erreur-type vient de l'information de
 * Fisher. Toutes les constantes vivent dans {@link EmotionalRadarV2ProvisionalRules}.
 *
 * <p>⚠️ {@code decisionalUseAllowed} reste {@code false} tant que la calibration
 * (brief §4) n'est pas « Validé » : le résultat est diagnostic, jamais comparatif.
 */
public final class ThetaIrtService {

    private static final int MAX_ITERATIONS = 50;
    private static final double CONVERGENCE = 1e-4;
    private static final double THETA_BOUND = 4.0; // garde-fou d'échelle logit

    /** Estime theta à partir des scènes notées (difficulté = distance sémantique). */
    public RadarThetaEstimate estimate(List<RadarSceneOutcome> outcomes) {
        if (outcomes == null || outcomes.isEmpty()) {
            return new RadarThetaEstimate(0.0, Double.POSITIVE_INFINITY, 0, "Provisoire", false);
        }
        double a = EmotionalRadarV2ProvisionalRules.IRT_DISCRIMINATION;
        double[] b = outcomes.stream()
            .mapToDouble(o -> EmotionalRadarV2ProvisionalRules.itemDifficultyFromDistance(o.sceneDifficulty()))
            .toArray();
        boolean[] correct = new boolean[outcomes.size()];
        for (int i = 0; i < outcomes.size(); i++) {
            correct[i] = outcomes.get(i).correct();
        }

        double theta = newtonRaphson(a, b, correct);
        double information = fisherInformation(a, b, theta);
        double se = information > 0 ? 1.0 / Math.sqrt(information) : Double.POSITIVE_INFINITY;

        boolean reliable = outcomes.size() >= EmotionalRadarV2ProvisionalRules.MIN_ITEMS_FOR_RELIABLE_THETA;
        String flag = reliable ? "Fiable" : "Provisoire";
        return new RadarThetaEstimate(theta, se, outcomes.size(), flag,
            EmotionalRadarV2ProvisionalRules.DECISIONAL_USE_ALLOWED);
    }

    private static double newtonRaphson(double a, double[] b, boolean[] correct) {
        double theta = 0.0;
        for (int iter = 0; iter < MAX_ITERATIONS; iter++) {
            double firstDerivative = 0.0;  // d(logL)/dθ
            double secondDerivative = 0.0; // d²(logL)/dθ²
            for (int i = 0; i < b.length; i++) {
                double p = probability(a, b[i], theta);
                double x = correct[i] ? 1.0 : 0.0;
                firstDerivative += a * (x - p);
                secondDerivative -= a * a * p * (1.0 - p);
            }
            if (Math.abs(secondDerivative) < 1e-9) {
                break; // information nulle : impossible d'affiner
            }
            double step = firstDerivative / secondDerivative;
            theta -= step;
            theta = Math.max(-THETA_BOUND, Math.min(THETA_BOUND, theta));
            if (Math.abs(step) < CONVERGENCE) {
                break;
            }
        }
        return theta;
    }

    private static double fisherInformation(double a, double[] b, double theta) {
        double info = 0.0;
        for (double difficulty : b) {
            double p = probability(a, difficulty, theta);
            info += a * a * p * (1.0 - p);
        }
        return info;
    }

    private static double probability(double a, double b, double theta) {
        return 1.0 / (1.0 + Math.exp(-a * (theta - b)));
    }
}
