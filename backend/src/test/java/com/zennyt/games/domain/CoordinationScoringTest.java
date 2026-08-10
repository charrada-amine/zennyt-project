package com.zennyt.games.domain;

import com.zennyt.games.domain.config.CoordinationConfig;
import com.zennyt.games.domain.config.CoordinationProvisionalRules;
import com.zennyt.games.domain.service.CoordinationScoringService;
import com.zennyt.games.domain.service.CoordinationTrajectoryService;
import com.zennyt.games.domain.service.CoordinationTrajectoryService.Position;
import com.zennyt.games.domain.vo.CoordinationMetrics;
import com.zennyt.games.domain.vo.CoordinationPhase;
import com.zennyt.games.domain.vo.CoordinationPointerSample;
import com.zennyt.games.domain.vo.CoordinationReport;
import com.zennyt.games.domain.vo.CoordinationSegmentMetric;
import com.zennyt.games.domain.vo.CoordinationSpeed;
import com.zennyt.games.support.CoordinationTestFixtures;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class CoordinationScoringTest {

    private final CoordinationScoringService scoring =
        new CoordinationScoringService();

    @Test
    void protocolHasExactlyTwoPracticeAndTwelveOrderedTestSegments() {
        assertEquals(14, CoordinationConfig.SEGMENTS.size());
        assertEquals(69_998L, CoordinationConfig.TOTAL_NOMINAL_DURATION_MS);
        assertEquals(55_998L, CoordinationConfig.TEST_NOMINAL_DURATION_MS);
        assertEquals(CoordinationPhase.PRACTICE,
            CoordinationConfig.segment(1).phase());
        assertEquals(CoordinationSpeed.SLOW,
            CoordinationConfig.segment(1).speed());
        assertEquals(CoordinationPhase.PRACTICE,
            CoordinationConfig.segment(2).phase());
        assertEquals(CoordinationSpeed.FAST,
            CoordinationConfig.segment(2).speed());

        List<Integer> expectedDurations = List.of(
            7_000, 7_000, 2_333, 2_333,
            7_000, 7_000, 2_333, 2_333,
            7_000, 7_000, 2_333, 2_333);
        for (int i = 0; i < expectedDurations.size(); i++) {
            var segment = CoordinationConfig.segment(i + 3);
            assertEquals(CoordinationPhase.TEST, segment.phase());
            assertEquals(i % 2 == 0 ? CoordinationSpeed.SLOW : CoordinationSpeed.FAST,
                segment.speed());
            assertEquals(expectedDurations.get(i), segment.durationMs());
        }
    }

    @Test
    void trajectoryStartsTopLeftAndMovesClockwiseContinuously() {
        CoordinationTrajectoryService trajectory =
            new CoordinationTrajectoryService();
        long inset = CoordinationConfig.TRACK_INSET_UNITS;
        long far = inset + CoordinationConfig.TRACK_SIDE_UNITS;

        assertEquals(new Position(inset, inset), trajectory.positionAt(0));
        assertEquals(new Position(far, inset), trajectory.positionAt(1_750));
        assertEquals(new Position(far, far), trajectory.positionAt(3_500));
        assertEquals(new Position(inset, inset), trajectory.positionAt(7_000));
        assertEquals(new Position(far, inset), trajectory.positionAt(7_875));
        assertThrows(IllegalArgumentException.class, () -> trajectory.positionAt(-1));
    }

    @Test
    void serverRecomputesPerfectAndAbsentRunsFromRawPointerPositions() {
        CoordinationReport perfect = scoring.report(CoordinationTestFixtures.perfect());
        assertEquals(100, perfect.provisionalAccuracyScore());
        assertEquals(100.0, perfect.overallAccuracyPercent(), 0.000_001);
        assertEquals(100.0, perfect.fastAccuracyPercent(), 0.000_001);
        assertEquals(100.0, perfect.slowAccuracyPercent(), 0.000_001);
        assertTrue(perfect.averageCenterDistance() < 2.0,
            "l'intégration 1 ms conserve une distance quasi nulle à cadence 4 ms");
        assertTrue(perfect.taskValid());
        assertTrue(perfect.technicalValid());
        assertTrue(perfect.sessionValid());

        CoordinationReport absent =
            scoring.report(CoordinationTestFixtures.absentDuringTest());
        assertEquals(0, absent.provisionalAccuracyScore());
        assertEquals(0.0, absent.overallAccuracyPercent(), 0.000_001);
        assertEquals(1_200.0, absent.averageCenterDistance(), 0.000_001);
        assertEquals(absent.sampleCount(), absent.absentSampleCount());
        assertTrue(absent.sessionValid(),
            "une faible performance valide ne doit pas devenir invalide");
    }

    @Test
    void executionTimeValidityUsesInclusiveSpecifiedBoundaries() {
        for (long valid : List.of(54_000L, 58_000L)) {
            CoordinationReport report = scoring.report(
                CoordinationTestFixtures.withTestExecutionTime(valid));
            assertTrue(report.executionTimeValid());
            assertTrue(report.taskValid());
            assertFalse(report.technicalValid(),
                "une durée totale valide ne masque pas un rythme de segments altéré");
            assertFalse(report.sessionValid());
        }
        for (long invalid : List.of(53_999L, 58_001L)) {
            CoordinationReport report = scoring.report(
                CoordinationTestFixtures.withTestExecutionTime(invalid));
            assertFalse(report.executionTimeValid());
            assertFalse(report.taskValid());
            assertFalse(report.sessionValid());
        }
    }

    @Test
    void samplingGapsAndDroppedFramesRemainDescriptive() {
        CoordinationReport gaps = scoring.report(
            CoordinationTestFixtures.withSamplingPeriod(200));
        assertTrue(gaps.samplingGapCount() > 0);
        assertTrue(gaps.taskValid());
        assertTrue(gaps.technicalValid());
        assertTrue(gaps.sessionValid());

        CoordinationReport dropped = scoring.report(
            CoordinationTestFixtures.withTechnicalState(true, false, 0, 9));
        assertEquals(9, dropped.droppedFrameCount());
        assertTrue(dropped.sessionValid());
    }

    @Test
    void timingDeviationInvalidatesTechnicalComparabilityWithoutChangingTaskRule() {
        CoordinationReport timing = scoring.report(
            CoordinationTestFixtures.withTestExecutionTime(54_000));

        assertTrue(timing.timingDeviationCount() > 0);
        assertTrue(timing.taskValid());
        assertFalse(timing.technicalValid());
        assertFalse(timing.sessionValid());
        assertTrue(timing.validityIssues().contains("TIMING_DEVIATION"));
    }

    @Test
    void sparseEndpointSamplesCannotManufacturePerfectTracking() {
        CoordinationReport sparse = scoring.report(
            CoordinationTestFixtures.withSamplingPeriod(7_000));

        assertTrue(sparse.samplingGapCount() > 0);
        assertTrue(sparse.provisionalAccuracyScore() < 25,
            "la cible doit continuer à avancer entre deux positions pointeur");
        assertTrue(sparse.sessionValid(),
            "une performance faible mais chronométrée reste interprétable");
    }

    @Test
    void completionInterruptionAndBackgroundOnlyAffectTechnicalValidity() {
        for (CoordinationMetrics metrics : List.of(
            CoordinationTestFixtures.withTechnicalState(false, false, 0, 0),
            CoordinationTestFixtures.withTechnicalState(true, true, 0, 0),
            CoordinationTestFixtures.withTechnicalState(true, false, 1, 0))) {
            CoordinationReport report = scoring.report(metrics);
            assertTrue(report.taskValid());
            assertFalse(report.technicalValid());
            assertFalse(report.sessionValid());
        }
    }

    @Test
    void provisionalScoreUsesExactHalfUpRoundingInReplaceableRules() {
        assertEquals(1, CoordinationProvisionalRules.score(1, 200).rawPoints());
        assertEquals(0, CoordinationProvisionalRules.score(1, 201).rawPoints());
        assertEquals(100, CoordinationProvisionalRules.score(200, 200).rawPoints());
        assertThrows(IllegalArgumentException.class,
            () -> CoordinationProvisionalRules.score(2, 1));
    }

    @Test
    void domainRejectsAnySegmentSequenceDivergenceBeforePersistence() {
        CoordinationMetrics valid = CoordinationTestFixtures.perfect();
        List<CoordinationSegmentMetric> segments = new ArrayList<>(valid.segments());
        CoordinationSegmentMetric third = segments.get(2);
        segments.set(2, new CoordinationSegmentMetric(
            third.phase(), third.segmentIndex(), CoordinationSpeed.FAST,
            third.nominalDurationMs(), third.actualStartMs(), third.actualEndMs(),
            third.samples()));

        assertThrows(IllegalArgumentException.class, () -> new CoordinationMetrics(
            valid.protocolVersion(), valid.inputSource(), segments,
            true, false, 0, 0));
    }

    @Test
    void domainRequiresInitialActivationInsideHalfRadiusAndCopiesCollections() {
        CoordinationMetrics valid = CoordinationTestFixtures.perfect();
        assertThrows(UnsupportedOperationException.class,
            () -> valid.segments().add(valid.segments().get(0)));

        List<CoordinationSegmentMetric> segments = new ArrayList<>(valid.segments());
        CoordinationSegmentMetric first = segments.get(0);
        List<CoordinationPointerSample> samples = new ArrayList<>(first.samples());
        samples.set(0, new CoordinationPointerSample(
            1, 0, true, CoordinationConfig.COORDINATE_SCALE,
            CoordinationConfig.COORDINATE_SCALE));
        segments.set(0, new CoordinationSegmentMetric(
            first.phase(), first.segmentIndex(), first.speed(),
            first.nominalDurationMs(), first.actualStartMs(), first.actualEndMs(),
            samples));

        assertThrows(IllegalArgumentException.class, () -> new CoordinationMetrics(
            valid.protocolVersion(), valid.inputSource(), segments,
            true, false, 0, 0));
    }
}
