package com.zennyt.games.support;

import com.zennyt.games.domain.config.CoordinationConfig;
import com.zennyt.games.domain.config.CoordinationConfig.SegmentSpec;
import com.zennyt.games.domain.service.CoordinationTrajectoryService;
import com.zennyt.games.domain.vo.CoordinationInputSource;
import com.zennyt.games.domain.vo.CoordinationMetrics;
import com.zennyt.games.domain.vo.CoordinationPointerSample;
import com.zennyt.games.domain.vo.CoordinationSegmentMetric;

import java.util.ArrayList;
import java.util.List;

/** Fabriques déterministes du protocole complet de « Je coordonne ». */
public final class CoordinationTestFixtures {

    private static final int SAMPLE_PERIOD_MS = 4;
    private static final CoordinationTrajectoryService TRAJECTORY =
        new CoordinationTrajectoryService();

    private CoordinationTestFixtures() {
    }

    public static CoordinationMetrics perfect() {
        return build(CoordinationConfig.TEST_NOMINAL_DURATION_MS,
            true, false, 0, 0, true, SAMPLE_PERIOD_MS);
    }

    public static CoordinationMetrics absentDuringTest() {
        return build(CoordinationConfig.TEST_NOMINAL_DURATION_MS,
            true, false, 0, 0, false, SAMPLE_PERIOD_MS);
    }

    public static CoordinationMetrics withTestExecutionTime(long testDurationMs) {
        return build(testDurationMs, true, false, 0, 0, true, SAMPLE_PERIOD_MS);
    }

    public static CoordinationMetrics withTechnicalState(boolean completed,
                                                          boolean interrupted,
                                                          int backgroundEvents,
                                                          int droppedFrames) {
        return build(CoordinationConfig.TEST_NOMINAL_DURATION_MS,
            completed, interrupted, backgroundEvents, droppedFrames, true,
            SAMPLE_PERIOD_MS);
    }

    public static CoordinationMetrics withSamplingPeriod(int samplePeriodMs) {
        return build(CoordinationConfig.TEST_NOMINAL_DURATION_MS,
            true, false, 0, 0, true, samplePeriodMs);
    }

    private static CoordinationMetrics build(long testDurationMs,
                                              boolean completed,
                                              boolean interrupted,
                                              int backgroundEvents,
                                              int droppedFrames,
                                              boolean trackDuringTest,
                                              int samplePeriodMs) {
        if (testDurationMs < CoordinationConfig.TEST_SEGMENT_COUNT) {
            throw new IllegalArgumentException("Durée test insuffisante");
        }
        if (samplePeriodMs <= 0) {
            throw new IllegalArgumentException("Période d'échantillonnage invalide");
        }
        List<Long> durations = new ArrayList<>(CoordinationConfig.TOTAL_SEGMENT_COUNT);
        durations.add((long) CoordinationConfig.LONG_SEGMENT_MS);
        durations.add((long) CoordinationConfig.LONG_SEGMENT_MS);
        for (int i = CoordinationConfig.PRACTICE_SEGMENT_COUNT;
                i < CoordinationConfig.TOTAL_SEGMENT_COUNT; i++) {
            durations.add((long) CoordinationConfig.SEGMENTS.get(i).durationMs());
        }
        long testDelta = testDurationMs - CoordinationConfig.TEST_NOMINAL_DURATION_MS;
        int lastIndex = durations.size() - 1;
        durations.set(lastIndex, durations.get(lastIndex) + testDelta);
        if (durations.get(lastIndex) <= 1) {
            throw new IllegalArgumentException("Durée du dernier segment insuffisante");
        }

        List<CoordinationSegmentMetric> segments = new ArrayList<>();
        long start = 0;
        for (int i = 0; i < CoordinationConfig.TOTAL_SEGMENT_COUNT; i++) {
            SegmentSpec spec = CoordinationConfig.SEGMENTS.get(i);
            long end = start + durations.get(i);
            boolean pointerPresent = i < CoordinationConfig.PRACTICE_SEGMENT_COUNT
                || trackDuringTest;
            segments.add(new CoordinationSegmentMetric(
                spec.phase(),
                spec.segmentIndex(),
                spec.speed(),
                spec.durationMs(),
                start,
                end,
                samples(start, end, pointerPresent, samplePeriodMs)));
            start = end;
        }
        return new CoordinationMetrics(
            CoordinationConfig.PROTOCOL_VERSION,
            CoordinationInputSource.TOUCH,
            segments,
            completed,
            interrupted,
            backgroundEvents,
            droppedFrames);
    }

    private static List<CoordinationPointerSample> samples(long start,
                                                            long end,
                                                            boolean present,
                                                            int samplePeriodMs) {
        List<CoordinationPointerSample> samples = new ArrayList<>();
        int index = 1;
        for (long timestamp = start; timestamp < end; timestamp += samplePeriodMs) {
            samples.add(sample(index++, timestamp, present));
        }
        if (samples.size() == 1) {
            samples.add(sample(index, end - 1, present));
        }
        return samples;
    }

    private static CoordinationPointerSample sample(int index,
                                                     long timestamp,
                                                     boolean present) {
        if (!present) {
            return new CoordinationPointerSample(index, timestamp, false, null, null);
        }
        CoordinationTrajectoryService.Position position = TRAJECTORY.positionAt(timestamp);
        return new CoordinationPointerSample(
            index, timestamp, true, Math.toIntExact(position.x()),
            Math.toIntExact(position.y()));
    }
}
