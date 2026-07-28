package com.zennyt.games.domain.vo;

import java.util.UUID;

/**
 * Une scène d'« Emotional Radar », <b>côté serveur</b>.
 *
 * <p>⚠️ Cet objet porte la <b>clé de correction</b> ({@code expectedEmotion},
 * {@code expectedNuance}, {@code expectedIntensity}, {@code explanation}). Il ne
 * doit <b>jamais</b> être sérialisé tel quel vers le client : le DTO exposé
 * ({@code EmotionalRadarSceneResponse}) n'expose que l'énoncé et le média. La
 * réponse attendue n'est divulguée qu'après validation, dans le feedback.
 *
 * <p>Auto-validant : la planche « Accessibility Compliance » impose un
 * équivalent textuel pour tout média et une transcription pour la vidéo, donc
 * une scène incomplète ne peut pas exister.
 */
public record EmotionalRadarScene(
    UUID id,
    int sceneOrder,
    SceneMediaType mediaType,
    String promptText,
    String instructionText,
    String mediaUrl,
    String mediaPublicId,
    String altText,
    String transcript,
    BasicEmotion expectedEmotion,
    String expectedNuance,
    int expectedIntensity,
    String explanation
) {

    public EmotionalRadarScene {
        if (id == null) {
            throw new IllegalArgumentException("id de scène requis");
        }
        if (mediaType == null) {
            throw new IllegalArgumentException("mediaType requis");
        }
        if (isBlank(promptText)) {
            throw new IllegalArgumentException("promptText requis");
        }
        if (expectedEmotion == null) {
            throw new IllegalArgumentException("expectedEmotion requise");
        }
        if (isBlank(expectedNuance)) {
            throw new IllegalArgumentException("expectedNuance requise");
        }
        if (expectedIntensity < EmotionalRadarConfigBounds.MIN_INTENSITY
            || expectedIntensity > EmotionalRadarConfigBounds.MAX_INTENSITY) {
            throw new IllegalArgumentException(
                "expectedIntensity hors échelle 1–5 : " + expectedIntensity);
        }
        // Accessibilité : un média sans équivalent textuel est refusé par le domaine.
        if (mediaType.requiresMedia()) {
            if (isBlank(mediaUrl)) {
                throw new IllegalArgumentException(
                    "mediaUrl requis pour une scène " + mediaType);
            }
            if (isBlank(altText)) {
                throw new IllegalArgumentException(
                    "altText requis pour une scène " + mediaType + " (accessibilité)");
            }
        }
        if (mediaType.requiresTranscript() && isBlank(transcript)) {
            throw new IllegalArgumentException(
                "transcript requis pour une scène VIDEO (accessibilité)");
        }
    }

    private static boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    /**
     * Bornes de l'échelle d'intensité, dupliquées ici pour garder le record
     * auto-validant sans dépendre du paquet {@code config} (le domaine reste pur,
     * mais {@code config} dépend déjà de {@code vo} — on évite le cycle).
     */
    static final class EmotionalRadarConfigBounds {
        private EmotionalRadarConfigBounds() {
        }

        static final int MIN_INTENSITY = 1;
        static final int MAX_INTENSITY = 5;
    }
}
