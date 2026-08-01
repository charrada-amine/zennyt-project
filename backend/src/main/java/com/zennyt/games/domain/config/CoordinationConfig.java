package com.zennyt.games.domain.config;

import com.zennyt.games.domain.vo.CoordinationPhase;
import com.zennyt.games.domain.vo.CoordinationSpeed;

import java.util.ArrayList;
import java.util.List;

/**
 * Source de vérité du protocole visuomoteur « Je coordonne ».
 *
 * <p>Le plateau est un carré fixed-point de {@value #COORDINATE_SCALE} unités.
 * La trajectoire commence au coin supérieur gauche, reste carrée (aucun easing)
 * et avance continûment dans le sens horaire, y compris aux changements de
 * segment et de vitesse.
 *
 * <p>PARITÉ MOCK ⇄ BACKEND : miroir mobile dans
 * {@code mobile/lib/features/games/domain/config/coordination_tracking_config.dart} ;
 * toute évolution doit modifier les deux côtés dans la même PR.
 */
public final class CoordinationConfig {

    public static final String PROTOCOL_VERSION = "FIXED_SQUARE_CW_V1";

    // PROVISOIRE — non validé par le psychologue : géométrie normalisée,
    // départ au coin supérieur gauche et rayon de la balle.
    public static final int COORDINATE_SCALE = 1_000_000;
    public static final int TRACK_INSET_UNITS = 160_000;
    public static final int TRACK_SIDE_UNITS =
        COORDINATE_SCALE - 2 * TRACK_INSET_UNITS;
    public static final int TRACK_PERIMETER_UNITS = 4 * TRACK_SIDE_UNITS;
    public static final int BALL_RADIUS_UNITS = 75_000;
    public static final int ACTIVATION_RADIUS_UNITS = BALL_RADIUS_UNITS / 2;

    // PROVISOIRE — non validé par le psychologue : vitesses de parcours.
    public static final int SLOW_LAP_MS = 7_000;
    public static final int FAST_LAP_MS = 3_500;
    public static final int LONG_SEGMENT_MS = 7_000;
    public static final int SHORT_SEGMENT_MS = 2_333;

    public static final int PRACTICE_SEGMENT_COUNT = 2;
    public static final int TEST_SEGMENT_COUNT = 12;
    public static final int TOTAL_SEGMENT_COUNT =
        PRACTICE_SEGMENT_COUNT + TEST_SEGMENT_COUNT;
    public static final long TEST_NOMINAL_DURATION_MS = 55_998L;
    public static final long TOTAL_NOMINAL_DURATION_MS = 69_998L;

    public static final long MIN_VALID_TEST_EXECUTION_MS = 54_000L;
    public static final long MAX_VALID_TEST_EXECUTION_MS = 58_000L;

    // PROVISOIRE — à valider sur le parc d'appareils réel.
    public static final int TIMING_TOLERANCE_MS = 100;
    // PROVISOIRE — garantit qu'une unique position ne peut représenter un segment entier.
    public static final int MAX_SAMPLE_GAP_MS = 100;
    public static final int MAX_SAMPLES_PER_SEGMENT = 2_000;

    /**
     * PROVISOIRE — non validé par le psychologue : diagonale du plateau
     * normalisée vers la plage descriptive 0..1200.
     */
    public static final double DISTANCE_SCALE_MAX = 1_200.0;

    public static final List<SegmentSpec> SEGMENTS = buildSegments();

    private CoordinationConfig() {
    }

    public static int lapDurationMs(CoordinationSpeed speed) {
        return speed == CoordinationSpeed.SLOW ? SLOW_LAP_MS : FAST_LAP_MS;
    }

    public static SegmentSpec segment(int oneBasedIndex) {
        if (oneBasedIndex < 1 || oneBasedIndex > SEGMENTS.size()) {
            throw new IllegalArgumentException("segmentIndex doit être compris entre 1 et 14");
        }
        return SEGMENTS.get(oneBasedIndex - 1);
    }

    private static List<SegmentSpec> buildSegments() {
        List<SegmentSpec> segments = new ArrayList<>(TOTAL_SEGMENT_COUNT);
        long start = 0;
        start = add(segments, CoordinationPhase.PRACTICE, CoordinationSpeed.SLOW,
            LONG_SEGMENT_MS, start);
        start = add(segments, CoordinationPhase.PRACTICE, CoordinationSpeed.FAST,
            LONG_SEGMENT_MS, start);
        for (int repetition = 0; repetition < 3; repetition++) {
            start = add(segments, CoordinationPhase.TEST, CoordinationSpeed.SLOW,
                LONG_SEGMENT_MS, start);
            start = add(segments, CoordinationPhase.TEST, CoordinationSpeed.FAST,
                LONG_SEGMENT_MS, start);
            start = add(segments, CoordinationPhase.TEST, CoordinationSpeed.SLOW,
                SHORT_SEGMENT_MS, start);
            start = add(segments, CoordinationPhase.TEST, CoordinationSpeed.FAST,
                SHORT_SEGMENT_MS, start);
        }
        if (start != TOTAL_NOMINAL_DURATION_MS) {
            throw new IllegalStateException("Durée protocolaire incohérente : " + start);
        }
        return List.copyOf(segments);
    }

    private static long add(List<SegmentSpec> segments,
                            CoordinationPhase phase,
                            CoordinationSpeed speed,
                            int durationMs,
                            long scheduledStartMs) {
        int index = segments.size() + 1;
        segments.add(new SegmentSpec(
            index, phase, speed, durationMs, scheduledStartMs));
        return scheduledStartMs + durationMs;
    }

    /** Segment attendu, avec son début nominal sur l'horloge globale. */
    public record SegmentSpec(
        int segmentIndex,
        CoordinationPhase phase,
        CoordinationSpeed speed,
        int durationMs,
        long scheduledStartMs
    ) {
        public long scheduledEndMs() {
            return scheduledStartMs + durationMs;
        }

        public boolean isLong() {
            return durationMs == LONG_SEGMENT_MS;
        }
    }
}
