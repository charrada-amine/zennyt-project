package com.zennyt.games.domain.vo;

/**
 * Type de stimulus vidéo requis pour rendre une émotion lisible — pilote le cadrage
 * de la scène (admin table {@code stimulus_type} du brief v2).
 *
 * <p>Certaines émotions ne se lisent pas sur le visage seul : elles exigent le corps
 * entier, une interaction sociale visible, ou un contexte narratif / un objet.
 */
public enum StimulusType {
    /** Gros plan visage-épaules (5–6 s). */
    FACIAL,
    /** Plan large corps entier — la posture porte l'émotion (6–8 s). */
    BODY,
    /** Interaction entre plusieurs personnes — le contexte social est nécessaire. */
    SOCIAL,
    /** Contexte narratif ou objet visible — l'émotion se déduit de la situation. */
    CONTEXTUAL;

    /** Une légende contextuelle est-elle requise dans l'UI (jamais incrustée à la vidéo) ? */
    public boolean requiresContextualCaption() {
        return this == CONTEXTUAL;
    }

    /** Scène à plusieurs personnages : génération de variantes + sélection manuelle. */
    public boolean requiresManualSelection() {
        return this == SOCIAL;
    }
}
