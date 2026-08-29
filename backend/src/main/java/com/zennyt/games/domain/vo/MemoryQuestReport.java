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
    /** Nul quand le mode ne joue pas les chiffres (partie d'images). */
    Integer sameOrderScore,
    /** Nul quand le mode ne joue pas les chiffres (partie d'images). */
    Integer reverseOrderScore,
    Integer restoreScore,
    Integer afterDistractionScore,
    /** Note des tâches parasites (intrus / pièce manquante) ; nul si aucune. */
    Integer distractionChallengeScore,
    int highestSequenceLength,
    boolean distractionQuestionCorrect,
    boolean missionBPlayed,
    boolean distractionPlayed,
    int distractionChallengesPlayed,
    int distractionChallengesSolved,
    int distractionTimeouts,
    MemoryQuestMode mode,
    int finalLevel,
    boolean sessionValid,
    int timeoutTaskCount
) {
}
