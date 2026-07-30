package com.zennyt.games.domain.vo;

import java.util.List;

/**
 * Métriques finales d'« Emotional Radar ».
 *
 * <p>⚠️ Contrairement aux autres jeux, ces métriques <b>ne permettent pas</b> de
 * reconstruire le score : elles ne portent aucune réponse. Le score est calculé à
 * partir des {@link EmotionalRadarAnswer} que le serveur a notées et persistées
 * scène par scène (AGENTS.md §7.4). Ce payload ne sert qu'aux <b>indicateurs
 * comportementaux</b> (temps de réponse, recours à l'aide, plein écran).
 *
 * <p>Conséquence directe : un client qui falsifierait cette soumission ne pourrait
 * pas s'attribuer de points — au pire il fausserait ses propres indicateurs.
 */
public record EmotionalRadarMetrics(
    List<EmotionalRadarSceneMetric> scenes
) implements GameMetrics {

    public EmotionalRadarMetrics {
        if (scenes == null || scenes.isEmpty()) {
            throw new IllegalArgumentException("au moins une scène mesurée est requise");
        }
        scenes = List.copyOf(scenes);
    }

    /** Temps de réponse moyen, toutes scènes confondues. */
    public int averageResponseTimeMs() {
        return (int) Math.round(scenes.stream()
            .mapToInt(EmotionalRadarSceneMetric::responseTimeMs)
            .average()
            .orElse(0));
    }

    /** Nombre de scènes où le joueur a ouvert l'aide (sans pénalité au barème). */
    public int helpOpenedCount() {
        return (int) scenes.stream()
            .filter(EmotionalRadarSceneMetric::helpOpened)
            .count();
    }
}
