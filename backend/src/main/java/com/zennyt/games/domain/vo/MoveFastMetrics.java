package com.zennyt.games.domain.vo;

import java.util.List;

/**
 * Raw metrics for the cognitive flexibility game « Je bouge / Move Fast ».
 *
 * <p>The client sends measured responses only. Scoring is replayed on the
 * server from the correct/incorrect sequence according to the Word module:
 * four consecutive correct responses increase the multiplier, incorrect
 * responses reset a partial counter or reduce the multiplier when empty, and a
 * final multiplier bonus is added at the end.
 *
 * @param correctResponses ordered response outcomes; true means correct
 * @param reactionTimesMs  per-response reaction time in milliseconds
 */
public record MoveFastMetrics(
    List<Boolean> correctResponses,
    List<Integer> reactionTimesMs
) implements GameMetrics {
    public MoveFastMetrics {
        if (correctResponses == null || correctResponses.isEmpty()) {
            throw new IllegalArgumentException("correctResponses ne doit pas être vide");
        }
        if (correctResponses.stream().anyMatch(value -> value == null)) {
            throw new IllegalArgumentException("correctResponses contient une valeur invalide");
        }
        correctResponses = List.copyOf(correctResponses);

        if (reactionTimesMs == null) {
            reactionTimesMs = List.of();
        } else {
            reactionTimesMs = List.copyOf(reactionTimesMs);
            if (!reactionTimesMs.isEmpty() && reactionTimesMs.size() != correctResponses.size()) {
                throw new IllegalArgumentException(
                    "reactionTimesMs doit être vide ou aligné avec correctResponses");
            }
            if (reactionTimesMs.stream().anyMatch(ms -> ms == null || ms < 0)) {
                throw new IllegalArgumentException("reactionTimesMs contient une valeur invalide");
            }
        }
    }

    public int responseCount() {
        return correctResponses.size();
    }

    public long correctCount() {
        return correctResponses.stream().filter(Boolean::booleanValue).count();
    }

    public double accuracy() {
        return correctCount() * 100.0 / responseCount();
    }
}
