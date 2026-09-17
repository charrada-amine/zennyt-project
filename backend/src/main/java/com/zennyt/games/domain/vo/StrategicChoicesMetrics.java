package com.zennyt.games.domain.vo;

import com.zennyt.games.domain.config.StrategicChoicesConfig;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Métriques d'une partie complète de « Choix Stratégiques ».
 *
 * <p>Les situations d'une partie sont distinctes : la banque en compte quatre-vingts
 * et une partie en tire dix, rejouer la même fausserait la mesure. Aucun point
 * ne circule dans ce payload.
 */
public record StrategicChoicesMetrics(
    List<StrategicChoiceAnswerMetric> answers
) implements GameMetrics {

    public StrategicChoicesMetrics {
        if (answers == null) {
            throw new IllegalArgumentException("answers requis");
        }
        answers = List.copyOf(answers);
        if (answers.size() != StrategicChoicesConfig.SITUATIONS_PER_JOURNEY) {
            throw new IllegalArgumentException(
                "Choix Stratégiques exige exactement "
                    + StrategicChoicesConfig.SITUATIONS_PER_JOURNEY + " situations");
        }
        Set<String> seen = new HashSet<>();
        for (StrategicChoiceAnswerMetric answer : answers) {
            if (!seen.add(answer.situationId())) {
                throw new IllegalArgumentException(
                    "Situation Choix Stratégiques dupliquée : " + answer.situationId());
            }
        }
    }

    public int averageResponseTimeMs() {
        if (answers.isEmpty()) {
            return 0;
        }
        return (int) Math.round(answers.stream()
            .mapToInt(StrategicChoiceAnswerMetric::responseTimeMs)
            .average()
            .orElse(0));
    }
}
