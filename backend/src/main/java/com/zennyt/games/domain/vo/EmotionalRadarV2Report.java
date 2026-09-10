package com.zennyt.games.domain.vo;

import java.util.List;
import java.util.Map;

/**
 * Indicateurs de session d'« Emotional Radar v2 » (tableau de performance
 * utilisateur du brief §2). Deux couches nettement séparées :
 * <ul>
 *   <li><b>Score « jeu »</b> ({@code radarEmotionScore} /10 + {@code emotionalLevel})
 *       — visible du joueur, gamification, utilisable ;</li>
 *   <li><b>Score « décisionnel »</b> ({@code theta}) — invisible, diagnostic,
 *       VERROUILLÉ tant que non calibré.</li>
 * </ul>
 *
 * <p>Les champs {@code accuracyByChoiceCount} et {@code accuracyBySemanticDistance}
 * permettent de distinguer, pour un joueur en difficulté, si la cause est la
 * surcharge de choix (axe charge) ou la finesse de discrimination (axe distance).
 */
public record EmotionalRadarV2Report(
    int totalScenes,
    int startingLevel,
    int finalLevel,
    List<String> levelTransitions,
    int correctEmotions,
    double emotionAccuracyPercent,
    Map<Integer, Double> accuracyByLevel,
    Map<Integer, Double> accuracyByChoiceCount,
    Map<String, Double> accuracyBySemanticDistance,
    boolean semanticDistanceScoringAvailable,
    double semanticProximityErrorScore,
    double intensityMatchPercent,
    Map<String, Integer> intensityErrorDirection,
    Map<String, Double> accuracyByStimulusIntensity,
    Map<String, Double> stimulusTypePerformance,
    boolean stimulusTypeScoringAvailable,
    Double justificationScore,
    boolean justificationScoringAvailable,
    int averageResponseTimeMs,
    double impulsiveResponsesPercent,
    int radarEmotionScore,
    String emotionalLevel,
    RadarThetaEstimate theta
) {
}
