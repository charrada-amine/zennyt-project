package com.zennyt.games.domain.vo;

/**
 * Format d'un item « Je Décide ». Détermine la règle de notation appliquée par
 * {@code DecisionScoringService}.
 *
 * <p><b>Couche MOTEUR</b> pour {@link #TEMPORAL_DECISION} (règle DT de la fiche).
 * Le mapping option → qualité vit dans la <b>couche provisoire</b> ; pour
 * {@link #COHERENCE_PAIR}, la dérivation de la note depuis la cohérence de la
 * paire est elle aussi <b>provisoire</b> ({@code DecisionProvisionalRules}).
 */
public enum DecisionItemFormat {
    /** Item classique : la note = score de qualité de l'option choisie. */
    STANDARD,
    /**
     * Item chronométré (DT) : la note dépend de la latence (règle DT de la fiche
     * — correct + rapide → 3, correct + lent → 2, incorrect → qualité de l'option).
     */
    TEMPORAL_DECISION,
    /**
     * Item en paire liée (CS) : la note dérive de la cohérence entre les deux
     * réponses de la paire (dérivation PROVISOIRE, isolée dans la couche provisoire).
     */
    COHERENCE_PAIR
}
