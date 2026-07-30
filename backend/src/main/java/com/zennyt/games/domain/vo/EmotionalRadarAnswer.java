package com.zennyt.games.domain.vo;

import java.time.Instant;
import java.util.UUID;

/**
 * Réponse d'un joueur à UNE scène, <b>déjà notée par le serveur</b>.
 *
 * <p>C'est la pièce maîtresse de l'anti-triche du jeu : les points proviennent de
 * cet objet — produit et persisté par le serveur au moment de la validation de la
 * scène — et jamais du payload final envoyé par le client. Falsifier la soumission
 * finale ne peut donc pas modifier le score.
 *
 * @param scenePoints total de la scène, borné par le barème
 *                    ({@code EmotionalRadarConfig.POINTS_PER_SCENE})
 */
public record EmotionalRadarAnswer(
    UUID sessionId,
    UUID sceneId,
    int sceneOrder,
    BasicEmotion selectedEmotion,
    String selectedNuance,
    int selectedIntensity,
    BasicEmotion expectedEmotion,
    String expectedNuance,
    int expectedIntensity,
    int emotionPoints,
    int nuancePoints,
    int intensityPoints,
    int scenePoints,
    boolean correct,
    Instant answeredAt
) {

    public EmotionalRadarAnswer {
        if (sessionId == null || sceneId == null) {
            throw new IllegalArgumentException("sessionId et sceneId requis");
        }
        if (selectedEmotion == null) {
            throw new IllegalArgumentException("selectedEmotion requise");
        }
        if (scenePoints < 0) {
            throw new IllegalArgumentException("scenePoints négatif : " + scenePoints);
        }
    }

    /** Le joueur a-t-il identifié la bonne famille d'émotion ? */
    public boolean emotionCorrect() {
        return selectedEmotion == expectedEmotion;
    }

    /** Le joueur a-t-il identifié la bonne nuance ? */
    public boolean nuanceCorrect() {
        return expectedNuance != null && expectedNuance.equalsIgnoreCase(selectedNuance);
    }

    /** Écart d'intensité (0 = calibrage parfait). */
    public int intensityGap() {
        return Math.abs(expectedIntensity - selectedIntensity);
    }
}
