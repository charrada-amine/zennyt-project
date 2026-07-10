package com.zennyt.games.domain.vo;

/**
 * Indicateurs de « J'investigue » (mémoire de travail), calculés côté serveur.
 *
 * <p>Notes par tâche (0–5) + composite /100 (indicatif, non diagnostique). Les
 * tâches optionnelles sont {@code null} si non jouées. La justesse de la question
 * de distraction est un indicateur qualitatif, hors du barème noté.
 */
public record MemoryQuestReport(
    int compositeScore,
    int sameOrderScore,
    int reverseOrderScore,
    Integer restoreScore,
    Integer afterDistractionScore,
    int highestSequenceLength,
    boolean distractionQuestionCorrect,
    boolean missionBPlayed,
    boolean distractionPlayed,
    int finalLevel,
    boolean sessionValid,
    int timeoutTaskCount
) {
}
