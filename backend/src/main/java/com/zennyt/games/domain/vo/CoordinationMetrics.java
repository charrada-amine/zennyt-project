package com.zennyt.games.domain.vo;

import com.zennyt.games.domain.config.CoordinationConfig;
import com.zennyt.games.domain.config.CoordinationConfig.SegmentSpec;

import java.util.List;
import java.util.Objects;

/** Trace brute complète du protocole « Je coordonne ». */
public record CoordinationMetrics(
    String protocolVersion,
    CoordinationInputSource inputSource,
    List<CoordinationSegmentMetric> segments,
    boolean sessionCompleted,
    boolean interrupted,
    int backgroundEventCount,
    int droppedFrameCount
) implements GameMetrics {

    public CoordinationMetrics {
        if (!CoordinationConfig.PROTOCOL_VERSION.equals(protocolVersion)) {
            throw new IllegalArgumentException(
                "protocolVersion attendu : " + CoordinationConfig.PROTOCOL_VERSION);
        }
        Objects.requireNonNull(inputSource, "inputSource");
        segments = List.copyOf(Objects.requireNonNull(segments, "segments"));
        if (segments.size() != CoordinationConfig.TOTAL_SEGMENT_COUNT) {
            throw new IllegalArgumentException("Le protocole exige exactement 14 segments");
        }
        if (backgroundEventCount < 0 || droppedFrameCount < 0) {
            throw new IllegalArgumentException("Les compteurs doivent être positifs");
        }
        validateStructure(segments);
    }

    private static void validateStructure(List<CoordinationSegmentMetric> segments) {
        long previousEnd = 0;
        for (int i = 0; i < segments.size(); i++) {
            CoordinationSegmentMetric actual = segments.get(i);
            SegmentSpec expected = CoordinationConfig.SEGMENTS.get(i);
            if (actual.segmentIndex() != expected.segmentIndex()
                || actual.phase() != expected.phase()
                || actual.speed() != expected.speed()
                || actual.nominalDurationMs() != expected.durationMs()) {
                throw new IllegalArgumentException(
                    "Séquence de segments invalide à l'index " + (i + 1));
            }
            if (actual.actualStartMs() != previousEnd) {
                throw new IllegalArgumentException(
                    "Les segments doivent être strictement contigus");
            }
            previousEnd = actual.actualEndMs();
        }
        CoordinationPointerSample activation = segments.get(0).samples().get(0);
        long dx = activation.pointerX() == null
            ? Long.MAX_VALUE : activation.pointerX() - CoordinationConfig.TRACK_INSET_UNITS;
        long dy = activation.pointerY() == null
            ? Long.MAX_VALUE : activation.pointerY() - CoordinationConfig.TRACK_INSET_UNITS;
        long activationRadiusSquared =
            (long) CoordinationConfig.ACTIVATION_RADIUS_UNITS
                * CoordinationConfig.ACTIVATION_RADIUS_UNITS;
        if (segments.get(0).actualStartMs() != 0
            || activation.timestampMs() != 0
            || !activation.pointerPresent()
            || dx == Long.MAX_VALUE || dy == Long.MAX_VALUE
            || dx * dx + dy * dy > activationRadiusSquared) {
            throw new IllegalArgumentException(
                "Le mouvement doit être déclenché au centre de la balle initiale");
        }
    }

    public long testExecutionTimeMs() {
        CoordinationSegmentMetric firstTest =
            segments.get(CoordinationConfig.PRACTICE_SEGMENT_COUNT);
        CoordinationSegmentMetric last = segments.get(segments.size() - 1);
        return last.actualEndMs() - firstTest.actualStartMs();
    }
}
