package com.zennyt.games.domain.vo;

/**
 * Indicateurs « Reflective Pause » dérivés côté serveur.
 */
public record ReflectivePauseReport(
    int momentsPlayed,
    double controlledReactionTimeScore,
    double nonImpulsiveResponsesScore,
    double abilityToStepBackScore,
    int impulsiveChoiceCount,
    int averageResponseTimeMs,
    String level
) {
}
