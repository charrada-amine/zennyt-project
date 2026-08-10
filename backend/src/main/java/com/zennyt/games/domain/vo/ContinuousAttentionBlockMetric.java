package com.zennyt.games.domain.vo;

import com.zennyt.games.domain.config.ContinuousAttentionConfig;

import java.util.List;
import java.util.Objects;

/** Bloc de 31 essais d'une phase Long Rosvold. */
public record ContinuousAttentionBlockMetric(
    ContinuousAttentionPhase phase,
    int blockIndex,
    List<ContinuousAttentionTrialMetric> trials
) {
    public ContinuousAttentionBlockMetric {
        Objects.requireNonNull(phase, "phase");
        if (blockIndex < 1 || blockIndex > phase.expectedBlockCount()) {
            throw new IllegalArgumentException(
                "blockIndex invalide pour " + phase + " : " + blockIndex);
        }
        trials = List.copyOf(Objects.requireNonNull(trials, "trials"));
        if (trials.size() != ContinuousAttentionConfig.TRIALS_PER_BLOCK) {
            throw new IllegalArgumentException("Un bloc doit contenir exactement 31 essais");
        }
        for (int index = 0; index < trials.size(); index++) {
            if (trials.get(index).trialIndex() != index + 1) {
                throw new IllegalArgumentException(
                    "Les trialIndex doivent être consécutifs de 1 à 31");
            }
        }
    }
}
