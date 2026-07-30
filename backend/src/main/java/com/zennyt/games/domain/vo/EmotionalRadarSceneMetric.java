package com.zennyt.games.domain.vo;

import java.util.UUID;

/**
 * Mesures <b>comportementales</b> d'une scène, envoyées par le client.
 *
 * <p>Volontairement dépourvu de toute réponse et de tout point : ce record ne
 * contient que ce que le serveur ne peut pas observer lui-même (temps de réponse,
 * ouverture de l'aide, passage en plein écran, mouvement réduit). La justesse et
 * les points viennent des {@link EmotionalRadarAnswer} notées serveur.
 */
public record EmotionalRadarSceneMetric(
    UUID sceneId,
    int responseTimeMs,
    boolean helpOpened,
    boolean fullscreenOpened,
    boolean reducedMotion
) {

    public EmotionalRadarSceneMetric {
        if (sceneId == null) {
            throw new IllegalArgumentException("sceneId requis");
        }
        if (responseTimeMs < 0) {
            throw new IllegalArgumentException("responseTimeMs négatif : " + responseTimeMs);
        }
    }
}
