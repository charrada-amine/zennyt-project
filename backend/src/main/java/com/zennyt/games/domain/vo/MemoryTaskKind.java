package com.zennyt.games.domain.vo;

/** Type d'une tâche notée « J'investigue » (mémoire de travail). */
public enum MemoryTaskKind {
    SAME_ORDER,
    REVERSE_ORDER,
    RESTORE,
    AFTER_DISTRACTION,

    /**
     * Tâche parasite elle-même (intrus / pièce manquante) du jeu des images.
     *
     * <p>Notée comme les autres, mais son délai de référence est le budget de la
     * distraction au niveau concerné, pas {@code MAX_TASK_TIME_MS} — voir
     * {@code MemoryQuestConfig.isDistractionTimedOut}.
     */
    DISTRACTION_CHALLENGE
}
