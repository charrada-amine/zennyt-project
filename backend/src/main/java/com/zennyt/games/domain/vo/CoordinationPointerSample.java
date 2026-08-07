package com.zennyt.games.domain.vo;

import com.zennyt.games.domain.config.CoordinationConfig;

/** Position brute fixed-point du pointeur sur une frame. */
public record CoordinationPointerSample(
    int sampleIndex,
    long timestampMs,
    boolean pointerPresent,
    Integer pointerX,
    Integer pointerY
) {
    public CoordinationPointerSample {
        if (sampleIndex < 1 || sampleIndex > CoordinationConfig.MAX_SAMPLES_PER_SEGMENT) {
            throw new IllegalArgumentException("sampleIndex hors limites");
        }
        if (timestampMs < 0) {
            throw new IllegalArgumentException("timestampMs doit être positif");
        }
        if (pointerPresent) {
            validateCoordinate(pointerX, "pointerX");
            validateCoordinate(pointerY, "pointerY");
        } else if (pointerX != null || pointerY != null) {
            throw new IllegalArgumentException(
                "Un pointeur absent exige pointerX/pointerY null");
        }
    }

    private static void validateCoordinate(Integer value, String field) {
        if (value == null || value < 0 || value > CoordinationConfig.COORDINATE_SCALE) {
            throw new IllegalArgumentException(
                field + " doit appartenir à [0, "
                    + CoordinationConfig.COORDINATE_SCALE + "]");
        }
    }
}
