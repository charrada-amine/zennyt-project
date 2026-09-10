package com.zennyt.games.domain.vo;

import java.util.List;

/**
 * Indicateurs de « Je Décide », calculés côté serveur.
 *
 * <p>Détail par dimension (/18) + brut (/90) + SCW (/100) + niveau, interprétations
 * automatiques (fiche), qualité de session (fiche) et indicateurs temporels. Le
 * SCW, le niveau et les seuils d'interprétation proviennent de la couche
 * provisoire ; l'agrégation, la règle DT et les textes d'interprétation sont le
 * moteur définitif.
 */
public record DecisionReport(
    int rawScore,
    int rawMax,
    int scwScore,
    String level,
    List<DimensionScore> dimensions,
    List<String> interpretations,
    // Qualité de session (fiche) — sous-contrôles + verdict.
    boolean avgTimePlausible,
    boolean randomResponseRateOk,
    boolean impulsiveRateOk,
    boolean deviceLatencyWithinNorm,
    boolean sessionUsable,
    // Indicateurs temporels & comportementaux.
    double averageResponseTimeMs,
    double medianResponseTimeMs,
    double stdDevResponseTimeMs,
    double impulsiveResponsePercent,
    double slowResponsePercent,
    double intraSessionVariability,
    int decisionChangesCount,
    double averageResponseTimeAdjustedMs,
    boolean dtScoreCalibrationAdjusted,
    // Calibrage appareil (socle réutilisé).
    boolean calibrationApplied,
    boolean calibrationReliable,
    double calibrationOffsetMs
) {
    /** Score /18 d'une dimension ({@code exploitable=false} si &gt; 2 items manquants). */
    public record DimensionScore(
        DecisionDimension dimension,
        Integer score,
        int maxScore,
        boolean exploitable,
        int answeredItems,
        /** true → tous les items servis sur cette dimension sont en notation neutre. */
        boolean provisionalScoring
    ) {
    }
}
