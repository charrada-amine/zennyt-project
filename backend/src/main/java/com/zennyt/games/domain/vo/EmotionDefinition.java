package com.zennyt.games.domain.vo;

/**
 * Définition d'une émotion du référentiel « Emotional Radar v2 ».
 *
 * <p>Les coordonnées {@code valence} / {@code arousal} sont un placeholder 2D
 * <b>PROVISOIRE</b> de l'espace sémantique : elles servent à calculer une distance
 * entre émotions (proximité = scène difficile) en attendant les coordonnées réelles
 * de l'espace de Cowen &amp; Keltner. Voir {@code EMOTIONAL_RADAR_V2_TASKS.md}.
 *
 * @param key          identifiant stable (ex. {@code "JOY"}), autoritaire côté serveur
 * @param labelFr      libellé français affichable
 * @param labelEn      libellé anglais affichable
 * @param category     grande famille ({@link EmotionCategory})
 * @param stimulusType type de stimulus requis ({@link StimulusType})
 * @param valence      axe plaisir/déplaisir, -1..1 (PROVISOIRE)
 * @param arousal      axe activation, 0..1 (PROVISOIRE)
 */
public record EmotionDefinition(
    String key,
    String labelFr,
    String labelEn,
    EmotionCategory category,
    StimulusType stimulusType,
    double valence,
    double arousal
) {

    public EmotionDefinition {
        if (key == null || key.isBlank()) {
            throw new IllegalArgumentException("key requise");
        }
        if (category == null) {
            throw new IllegalArgumentException("category requise pour " + key);
        }
        if (stimulusType == null) {
            throw new IllegalArgumentException("stimulusType requis pour " + key);
        }
        if (valence < -1.0 || valence > 1.0) {
            throw new IllegalArgumentException("valence hors [-1,1] pour " + key + " : " + valence);
        }
        if (arousal < 0.0 || arousal > 1.0) {
            throw new IllegalArgumentException("arousal hors [0,1] pour " + key + " : " + arousal);
        }
    }
}
