package com.zennyt.games.domain.service;

import com.zennyt.games.domain.config.IstProvisionalRules;
import com.zennyt.games.domain.vo.IstTrialReport;

import java.util.List;

/**
 * Couche confiance — biais de calibration UNIQUEMENT.
 *
 * <p>La sensibilité métacognitive (AUROC2, meta-d′, M-ratio) est volontairement
 * ABSENTE : AUROC2 dépend de la performance de type 1, et le M-ratio exige au moins
 * 400 essais (Guggenmos, 2021) contre 20 ici. Voir preuves §4.2. Ne pas la
 * réintroduire sans un protocole d'un autre ordre.
 */
public final class MetacognitionService {

    /** Résultat : nombre de jugements exploités et biais (null si aucun). */
    public record Calibration(int responseCount, Double bias) {
    }

    /**
     * Biais = probabilité subjective moyenne − exactitude, sur les MÊMES essais (ceux
     * où une confiance a été donnée). Positif = surconfiance.
     */
    public Calibration calibration(List<IstTrialReport> scoredTrials) {
        double confidenceSum = 0.0;
        int correct = 0;
        int count = 0;
        for (IstTrialReport trial : scoredTrials) {
            if (trial.confidence() == null) continue;
            confidenceSum += IstProvisionalRules.confidenceProbability(trial.confidence());
            if (trial.correct()) correct++;
            count++;
        }
        if (count == 0) return new Calibration(0, null);
        return new Calibration(count, DecisionBehavioralStatistics.round4(
            confidenceSum / count - (double) correct / count));
    }
}
