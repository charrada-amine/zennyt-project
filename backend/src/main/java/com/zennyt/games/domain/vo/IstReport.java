package com.zennyt.games.domain.vo;

import java.util.List;

/**
 * Indicateurs IST dérivés côté serveur, sur les essais NOTÉS uniquement.
 *
 * @param conditionDiscrimination cases ouvertes en gain fixe − en gain décroissant ;
 *                                positif = échantillonne moins quand c'est coûteux
 * @param calibrationBias         confiance moyenne − exactitude, sur les essais notés
 *                                où une confiance a été donnée ; positif = surconfiance.
 *                                DESCRIPTIF, hors score ; null sans aucune réponse
 */
public record IstReport(
    String protocolVersion,
    boolean sessionValid,
    List<String> validityIssues,
    int testTrialCount,
    int correctCount,
    double accuracyPercent,
    double meanBoxesFixedWin,
    double meanBoxesDecreasingWin,
    double conditionDiscrimination,
    double meanPCorrectAtDecision,
    double meanPCorrectFixedWin,
    double meanPCorrectDecreasingWin,
    int totalEarnings,
    int randomResponseCount,
    Double medianInterActionIntervalMs,
    int confidenceResponseCount,
    Double calibrationBias,
    int provisionalScore,
    List<IstTrialReport> trials
) {
    public IstReport {
        validityIssues = List.copyOf(validityIssues);
        trials = List.copyOf(trials);
    }
}
