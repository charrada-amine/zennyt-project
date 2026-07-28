package com.zennyt.games.domain.vo;

import java.util.List;

/**
 * Indicateurs de reconnaissance émotionnelle dérivés serveur.
 *
 * <p>Exposés dans {@code GameSessionResponse.emotionalRadarIndicators}. Ils
 * n'entrent <b>pas</b> dans le score : ce sont des indicateurs qualitatifs, à
 * l'image de {@code globalPlanSuccess} pour Predictive Puzzle.
 *
 * <p>Les trois pourcentages reprennent les trois tuiles de la planche des états
 * d'interaction (« 89% Basic emotion / 76% Nuance / 81% Intensity »).
 */
public record EmotionalRadarReport(
    int scenesPlayed,
    double emotionAccuracyPercent,
    double nuanceAccuracyPercent,
    double intensityCalibrationPercent,
    int averageResponseTimeMs,
    int helpOpenedCount,
    List<Confusion> confusedEmotions
) {

    /** Une confusion observée : la famille attendue vs celle choisie. */
    public record Confusion(BasicEmotion expected, BasicEmotion selected) {
    }

    public EmotionalRadarReport {
        confusedEmotions = confusedEmotions == null
            ? List.of()
            : List.copyOf(confusedEmotions);
    }
}
