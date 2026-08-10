package com.zennyt.games.domain.vo;

import com.zennyt.games.domain.config.CoordinationConfig;

import java.util.List;
import java.util.Objects;

/** Mesures brutes d'un segment contigu de « Je coordonne ». */
public record CoordinationSegmentMetric(
    CoordinationPhase phase,
    int segmentIndex,
    CoordinationSpeed speed,
    int nominalDurationMs,
    long actualStartMs,
    long actualEndMs,
    List<CoordinationPointerSample> samples
) {
    public CoordinationSegmentMetric {
        Objects.requireNonNull(phase, "phase");
        Objects.requireNonNull(speed, "speed");
        samples = List.copyOf(Objects.requireNonNull(samples, "samples"));
        if (segmentIndex < 1 || segmentIndex > CoordinationConfig.TOTAL_SEGMENT_COUNT) {
            throw new IllegalArgumentException("segmentIndex doit être compris entre 1 et 14");
        }
        if (nominalDurationMs <= 0 || actualStartMs < 0 || actualEndMs <= actualStartMs) {
            throw new IllegalArgumentException("Timeline de segment invalide");
        }
        if (samples.size() < 2
            || samples.size() > CoordinationConfig.MAX_SAMPLES_PER_SEGMENT) {
            throw new IllegalArgumentException("Chaque segment exige 2 à 2000 samples");
        }
        long previousTimestamp = -1;
        for (int i = 0; i < samples.size(); i++) {
            CoordinationPointerSample sample = samples.get(i);
            if (sample.sampleIndex() != i + 1) {
                throw new IllegalArgumentException("Ordre sampleIndex invalide");
            }
            if (sample.timestampMs() < actualStartMs
                || sample.timestampMs() >= actualEndMs) {
                throw new IllegalArgumentException(
                    "timestampMs doit appartenir à [actualStartMs, actualEndMs)");
            }
            if (sample.timestampMs() <= previousTimestamp) {
                throw new IllegalArgumentException(
                    "Les timestamps doivent être strictement croissants");
            }
            previousTimestamp = sample.timestampMs();
        }
    }

    public long actualDurationMs() {
        return actualEndMs - actualStartMs;
    }
}
