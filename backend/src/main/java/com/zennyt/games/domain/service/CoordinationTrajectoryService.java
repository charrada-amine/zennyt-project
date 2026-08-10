package com.zennyt.games.domain.service;

import com.zennyt.games.domain.config.CoordinationConfig;
import com.zennyt.games.domain.config.CoordinationConfig.SegmentSpec;
import com.zennyt.games.domain.vo.CoordinationSpeed;

/** Reconstruction déterministe fixed-point de la trajectoire carrée horaire. */
public final class CoordinationTrajectoryService {

    public Position positionAt(long timestampMs) {
        if (timestampMs < 0) {
            throw new IllegalArgumentException("timestampMs doit être positif");
        }
        long clamped = Math.min(timestampMs, CoordinationConfig.TOTAL_NOMINAL_DURATION_MS);
        long equivalentSlowMs = equivalentSlowMs(clamped);
        long distanceNumerator =
            equivalentSlowMs * CoordinationConfig.TRACK_PERIMETER_UNITS;
        long distance = Math.floorMod(
            distanceNumerator / CoordinationConfig.SLOW_LAP_MS,
            CoordinationConfig.TRACK_PERIMETER_UNITS);
        return positionForDistance(distance);
    }

    private static long equivalentSlowMs(long timestampMs) {
        long weighted = 0;
        for (SegmentSpec segment : CoordinationConfig.SEGMENTS) {
            if (timestampMs <= segment.scheduledStartMs()) {
                break;
            }
            long elapsed = Math.min(timestampMs, segment.scheduledEndMs())
                - segment.scheduledStartMs();
            int multiplier = segment.speed() == CoordinationSpeed.SLOW ? 1 : 2;
            weighted += elapsed * multiplier;
            if (timestampMs < segment.scheduledEndMs()) {
                break;
            }
        }
        return weighted;
    }

    private static Position positionForDistance(long distance) {
        long side = CoordinationConfig.TRACK_SIDE_UNITS;
        long inset = CoordinationConfig.TRACK_INSET_UNITS;
        int edge = (int) (distance / side);
        long offset = distance % side;
        return switch (edge) {
            case 0 -> new Position(inset + offset, inset);
            case 1 -> new Position(inset + side, inset + offset);
            case 2 -> new Position(inset + side - offset, inset + side);
            case 3 -> new Position(inset, inset + side - offset);
            default -> throw new IllegalStateException("Arête carrée inattendue : " + edge);
        };
    }

    public record Position(long x, long y) {
    }
}
