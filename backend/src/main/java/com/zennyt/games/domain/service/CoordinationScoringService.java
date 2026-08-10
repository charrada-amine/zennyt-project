package com.zennyt.games.domain.service;

import com.zennyt.games.domain.config.CoordinationConfig;
import com.zennyt.games.domain.config.CoordinationConfig.SegmentSpec;
import com.zennyt.games.domain.config.CoordinationProvisionalRules;
import com.zennyt.games.domain.vo.CoordinationMetrics;
import com.zennyt.games.domain.vo.CoordinationPhase;
import com.zennyt.games.domain.vo.CoordinationPointerSample;
import com.zennyt.games.domain.vo.CoordinationReport;
import com.zennyt.games.domain.vo.CoordinationSegmentMetric;
import com.zennyt.games.domain.vo.CoordinationSpeed;
import com.zennyt.games.domain.vo.Score;

import java.util.ArrayList;
import java.util.List;

/**
 * Recalcule côté serveur précision, distances et validité de « Je coordonne ».
 *
 * <p>PARITÉ MOCK ⇄ BACKEND : miroir mobile dans
 * {@code mobile/lib/features/games/data/coordination_tracking_scoring.dart} ;
 * toute évolution doit modifier les deux côtés dans la même PR.
 */
public final class CoordinationScoringService {

    private static final double NORMALIZED_DIAGONAL = Math.sqrt(2.0);
    private final CoordinationTrajectoryService trajectory =
        new CoordinationTrajectoryService();

    public CoordinationReport report(CoordinationMetrics metrics) {
        Accumulator overall = new Accumulator();
        Accumulator fast = new Accumulator();
        Accumulator slow = new Accumulator();
        Accumulator longSegments = new Accumulator();
        Accumulator shortSegments = new Accumulator();
        int sampleCount = 0;
        int absentSampleCount = 0;
        int samplingGaps = 0;
        int timingDeviations = 0;

        for (CoordinationSegmentMetric segment : metrics.segments()) {
            SegmentSpec spec = CoordinationConfig.segment(segment.segmentIndex());
            if (segment.phase() == CoordinationPhase.TEST
                && (Math.abs(segment.actualStartMs() - spec.scheduledStartMs())
                        > CoordinationConfig.TIMING_TOLERANCE_MS
                    || Math.abs(segment.actualDurationMs() - spec.durationMs())
                        > CoordinationConfig.TIMING_TOLERANCE_MS)) {
                timingDeviations++;
            }
            samplingGaps += samplingGapCount(segment);
            if (segment.phase() != CoordinationPhase.TEST) {
                continue;
            }
            sampleCount += segment.samples().size();
            absentSampleCount += (int) segment.samples().stream()
                .filter(sample -> !sample.pointerPresent()).count();

            Accumulator speedAccumulator = segment.speed() == CoordinationSpeed.FAST
                ? fast : slow;
            Accumulator durationAccumulator = spec.isLong()
                ? longSegments : shortSegments;
            accumulateSegment(segment, spec, overall, speedAccumulator,
                durationAccumulator);
        }

        double accuracy = overall.accuracyPercent();
        boolean accuracyValid = Double.isFinite(accuracy)
            && accuracy >= 0.0 && accuracy <= 100.0;
        long testExecutionTime = metrics.testExecutionTimeMs();
        boolean executionTimeValid =
            testExecutionTime >= CoordinationConfig.MIN_VALID_TEST_EXECUTION_MS
                && testExecutionTime <= CoordinationConfig.MAX_VALID_TEST_EXECUTION_MS;
        boolean taskValid = accuracyValid && executionTimeValid;
        boolean technicalValid = metrics.sessionCompleted()
            && !metrics.interrupted()
            && metrics.backgroundEventCount() == 0
            && timingDeviations == 0;
        List<String> issues = new ArrayList<>();
        if (!metrics.sessionCompleted()) issues.add("SESSION_INCOMPLETE");
        if (metrics.interrupted()) issues.add("INTERRUPTED");
        if (metrics.backgroundEventCount() > 0) issues.add("BACKGROUND_EVENT");
        if (timingDeviations > 0) issues.add("TIMING_DEVIATION");
        if (!accuracyValid) issues.add("ACCURACY_OUT_OF_RANGE");
        if (!executionTimeValid) issues.add("EXECUTION_TIME_OUT_OF_RANGE");

        boolean sessionValid = technicalValid && taskValid;
        Score score = CoordinationProvisionalRules.score(
            overall.insideDurationMs, overall.totalDurationMs);

        return new CoordinationReport(
            CoordinationConfig.PROTOCOL_VERSION,
            metrics.inputSource(),
            metrics.sessionCompleted(),
            sessionValid,
            metrics.interrupted(),
            score.rawPoints(),
            accuracy,
            fast.accuracyPercent(),
            slow.accuracyPercent(),
            longSegments.accuracyPercent(),
            shortSegments.accuracyPercent(),
            overall.averageDistance(),
            testExecutionTime,
            accuracyValid,
            executionTimeValid,
            taskValid,
            technicalValid,
            sampleCount,
            absentSampleCount,
            metrics.backgroundEventCount(),
            metrics.droppedFrameCount(),
            timingDeviations,
            samplingGaps,
            issues);
    }

    public Score score(CoordinationReport report) {
        return new Score(
            report.provisionalAccuracyScore(),
            CoordinationProvisionalRules.MAX_POINTS,
            CoordinationProvisionalRules.DESCRIPTIVE_LEVEL);
    }

    private void accumulateSegment(CoordinationSegmentMetric segment,
                                   SegmentSpec spec,
                                   Accumulator overall,
                                   Accumulator bySpeed,
                                   Accumulator byDuration) {
        List<CoordinationPointerSample> samples = segment.samples();
        // Le score porte sur la fenêtre canonique décidée serveur, jamais sur
        // des bornes choisies par le client. Le pointeur est maintenu entre
        // deux échantillons, tandis que la cible continue d'avancer.
        long windowStart = spec.scheduledStartMs();
        long windowEnd = spec.scheduledEndMs();
        long cursor = windowStart;
        CoordinationPointerSample active = null;
        for (CoordinationPointerSample sample : samples) {
            if (sample.timestampMs() < windowStart) {
                active = sample;
                continue;
            }
            if (sample.timestampMs() >= windowEnd) {
                break;
            }
            if (sample.timestampMs() > cursor) {
                addInterval(cursor, sample.timestampMs(), active,
                    overall, bySpeed, byDuration);
            }
            active = sample;
            cursor = sample.timestampMs();
        }
        if (cursor < windowEnd) {
            addInterval(cursor, windowEnd, active,
                overall, bySpeed, byDuration);
        }
    }

    private void addInterval(long startMs,
                             long endMs,
                             CoordinationPointerSample pointer,
                             Accumulator... accumulators) {
        if (endMs <= startMs) return;
        // Grille serveur de 1 ms : deux positions clairsemées ne peuvent pas
        // faire croire que le pointeur a suivi une cible en mouvement.
        for (long timestampMs = startMs; timestampMs < endMs; timestampMs++) {
            SampleEvaluation evaluation = evaluate(timestampMs, pointer);
            for (Accumulator accumulator : accumulators) {
                accumulator.add(1, evaluation.inside(), evaluation.distance());
            }
        }
    }

    private SampleEvaluation evaluate(long timestampMs,
                                      CoordinationPointerSample pointer) {
        if (pointer == null || !pointer.pointerPresent()) {
            return new SampleEvaluation(false, CoordinationConfig.DISTANCE_SCALE_MAX);
        }
        CoordinationTrajectoryService.Position ball = trajectory.positionAt(timestampMs);
        long dx = pointer.pointerX().longValue() - ball.x();
        long dy = pointer.pointerY().longValue() - ball.y();
        long squaredDistance = dx * dx + dy * dy;
        long radiusSquared = (long) CoordinationConfig.BALL_RADIUS_UNITS
            * CoordinationConfig.BALL_RADIUS_UNITS;
        boolean inside = squaredDistance <= radiusSquared;
        double distance = Math.min(
            CoordinationConfig.DISTANCE_SCALE_MAX,
            Math.sqrt(squaredDistance)
                / (CoordinationConfig.COORDINATE_SCALE * NORMALIZED_DIAGONAL)
                * CoordinationConfig.DISTANCE_SCALE_MAX);
        return new SampleEvaluation(inside, distance);
    }

    private static int samplingGapCount(CoordinationSegmentMetric segment) {
        int gaps = 0;
        long previous = segment.actualStartMs();
        for (CoordinationPointerSample sample : segment.samples()) {
            if (sample.timestampMs() - previous > CoordinationConfig.MAX_SAMPLE_GAP_MS) {
                gaps++;
            }
            previous = sample.timestampMs();
        }
        if (segment.actualEndMs() - previous > CoordinationConfig.MAX_SAMPLE_GAP_MS) {
            gaps++;
        }
        return gaps;
    }

    private record SampleEvaluation(boolean inside, double distance) {
    }

    private static final class Accumulator {
        private long totalDurationMs;
        private long insideDurationMs;
        private double weightedDistance;

        void add(long durationMs, boolean inside, double distance) {
            totalDurationMs += durationMs;
            if (inside) insideDurationMs += durationMs;
            weightedDistance += distance * durationMs;
        }

        double accuracyPercent() {
            return totalDurationMs == 0 ? 0.0
                : insideDurationMs * 100.0 / totalDurationMs;
        }

        double averageDistance() {
            return totalDurationMs == 0 ? 0.0 : weightedDistance / totalDurationMs;
        }
    }
}
