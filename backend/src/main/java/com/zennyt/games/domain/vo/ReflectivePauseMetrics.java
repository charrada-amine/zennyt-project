package com.zennyt.games.domain.vo;

import com.zennyt.games.domain.config.ReflectivePauseConfig;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Métriques d'une session complète « Reflective Pause ».
 *
 * <p>Les dix moments sont obligatoires et uniques. Les points ne circulent
 * jamais dans ce payload.
 */
public record ReflectivePauseMetrics(
    List<ReflectivePauseMomentMetric> moments
) implements GameMetrics {

    public ReflectivePauseMetrics {
        if (moments == null) {
            throw new IllegalArgumentException("moments requis");
        }
        moments = List.copyOf(moments);
        if (moments.size() != ReflectivePauseConfig.TOTAL_MOMENTS) {
            throw new IllegalArgumentException(
                "Reflective Pause exige exactement "
                    + ReflectivePauseConfig.TOTAL_MOMENTS + " moments");
        }
        Set<String> ids = new HashSet<>();
        for (ReflectivePauseMomentMetric moment : moments) {
            if (!ids.add(moment.momentId())) {
                throw new IllegalArgumentException(
                    "Moment Reflective Pause dupliqué : " + moment.momentId());
            }
        }
        if (!ids.equals(ReflectivePauseConfig.momentIds())) {
            throw new IllegalArgumentException(
                "Le catalogue complet des moments Reflective Pause est requis");
        }
    }

    public int controlledReactionCount() {
        return (int) moments.stream()
            .filter(ReflectivePauseMomentMetric::minimumTimerReached)
            .count();
    }

    public int nonImpulsiveCount() {
        return (int) moments.stream()
            .filter(ReflectivePauseMomentMetric::nonImpulsive)
            .count();
    }

    public int stepBackCount() {
        return (int) moments.stream()
            .filter(ReflectivePauseMomentMetric::recommended)
            .count();
    }

    public int impulsiveChoiceCount() {
        return moments.size() - nonImpulsiveCount();
    }

    public int averageResponseTimeMs() {
        return (int) Math.round(moments.stream()
            .mapToInt(ReflectivePauseMomentMetric::responseTimeMs)
            .average()
            .orElse(0.0));
    }
}
