package com.zennyt.games.domain.vo;

import com.zennyt.games.domain.config.IstConfig;

import java.util.List;
import java.util.Objects;

/** Trace brute complète de l'IST : essais joués dans l'ordre + état technique. */
public record IstMetrics(
    String protocolVersion,
    List<IstTrialMetric> trials,
    boolean sessionCompleted,
    boolean interrupted,
    int backgroundEventCount,
    int focusLossCount
) implements GameMetrics {
    public IstMetrics {
        if (!IstConfig.PROTOCOL_VERSION.equals(protocolVersion)) {
            throw new IllegalArgumentException(
                "protocolVersion attendu : " + IstConfig.PROTOCOL_VERSION);
        }
        trials = List.copyOf(Objects.requireNonNull(trials, "trials"));
        if (trials.isEmpty() || trials.size() > IstConfig.TOTAL_TRIAL_COUNT) {
            throw new IllegalArgumentException("Nombre d'essais hors protocole");
        }
        for (int i = 0; i < trials.size(); i++) {
            if (trials.get(i).trialIndex() != i) {
                throw new IllegalArgumentException("Les essais doivent être contigus depuis 0");
            }
        }
        if (backgroundEventCount < 0 || focusLossCount < 0) {
            throw new IllegalArgumentException("Les compteurs techniques doivent être positifs");
        }
        if (sessionCompleted != (trials.size() == IstConfig.TOTAL_TRIAL_COUNT)) {
            throw new IllegalArgumentException(
                "sessionCompleted incompatible avec le nombre d'essais joués");
        }
    }

    public List<IstTrialMetric> testTrials() {
        return trials.stream().filter(t -> t.phase() == IstPhase.TEST).toList();
    }
}
