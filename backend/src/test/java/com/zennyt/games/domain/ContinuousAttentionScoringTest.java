package com.zennyt.games.domain;

import com.zennyt.games.domain.config.ContinuousAttentionConfig;
import com.zennyt.games.domain.service.ContinuousAttentionScoringService;
import com.zennyt.games.domain.service.ContinuousAttentionSequenceGenerator;
import com.zennyt.games.domain.vo.ContinuousAttentionInputSource;
import com.zennyt.games.domain.vo.ContinuousAttentionMetrics;
import com.zennyt.games.domain.vo.ContinuousAttentionPhase;
import com.zennyt.games.domain.vo.ContinuousAttentionReport;
import com.zennyt.games.domain.vo.ContinuousAttentionTrialMetric;
import com.zennyt.games.domain.vo.Score;
import com.zennyt.games.support.ContinuousAttentionTestFixtures;
import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ContinuousAttentionScoringTest {

    private static final UUID GOLDEN_SESSION =
        UUID.fromString("00000000-0000-4000-8000-000000000001");
    private final ContinuousAttentionScoringService scoring =
        new ContinuousAttentionScoringService();

    @Test
    void fnv1aAndXorShiftMatchCrossPlatformQaVectors() {
        assertEquals(0x811C9DC5,
            ContinuousAttentionSequenceGenerator.fnv1a32(""));
        assertEquals(0xE40C292C,
            ContinuousAttentionSequenceGenerator.fnv1a32("a"));
        assertEquals(0xBF9CF968,
            ContinuousAttentionSequenceGenerator.fnv1a32("foobar"));

        ContinuousAttentionSequenceGenerator.XorShift32 random =
            new ContinuousAttentionSequenceGenerator.XorShift32(1);
        long[] actual = new long[5];
        for (int i = 0; i < actual.length; i++) {
            actual[i] = random.nextUnsigned();
        }
        assertArrayEquals(new long[] {
            270369L, 67634689L, 2647435461L, 307599695L, 2398689233L
        }, actual);
    }

    @Test
    void deterministicSequenceMatchesGoldenSessionEndToEnd() throws Exception {
        ContinuousAttentionSequenceGenerator generator =
            new ContinuousAttentionSequenceGenerator();
        List<ContinuousAttentionSequenceGenerator.GeneratedBlock> blocks =
            generator.generate(GOLDEN_SESSION);
        String seedMaterial = GOLDEN_SESSION.toString().toLowerCase()
            + "|" + ContinuousAttentionConfig.PROTOCOL_VERSION;
        String flattened = blocks.stream()
            .flatMap(block -> block.letters().stream())
            .collect(Collectors.joining());

        assertEquals(0xFC0A124C,
            ContinuousAttentionSequenceGenerator.fnv1a32(seedMaterial));
        assertEquals(0xD9278D75,
            ContinuousAttentionSequenceGenerator.fnv1a32(flattened));
        assertEquals(
            "34d7fda1e34f0e932743084c6a962f4bc3c65ddb0d27ba16c3fbd891b4174e1d",
            HexFormat.of().formatHex(
                MessageDigest.getInstance("SHA-256")
                    .digest(flattened.getBytes(StandardCharsets.UTF_8))));
        assertEquals("HZNXXAJGQXXYYKEOCXFVXOXLJLNNIXH",
            String.join("", blocks.get(0).letters()));
        assertEquals("AXHAXDNCNOJAAXVAXAXZUAXAIIPACHW",
            String.join("", blocks.get(22).letters()));
        assertEquals("JYGAXJBYARQQKAXFSPAXXAXFYAXAXDY",
            String.join("", blocks.get(43).letters()));
    }

    @Test
    void everyGeneratedBlockHasExactTargetsAndNoAccidentalAx() {
        ContinuousAttentionSequenceGenerator generator =
            new ContinuousAttentionSequenceGenerator();
        for (int seed = 0; seed < 40; seed++) {
            UUID sessionId = new UUID(seed, seed * 17L + 1);
            List<ContinuousAttentionSequenceGenerator.GeneratedBlock> blocks =
                generator.generate(sessionId);
            assertEquals(44, blocks.size());
            String previous = null;
            for (var block : blocks) {
                if (block.phase() == ContinuousAttentionPhase.AX_PRACTICE
                    && block.blockIndex() == 1) {
                    previous = null;
                }
                int targets = 0;
                for (String current : block.letters()) {
                    if (ContinuousAttentionMetrics.isTarget(
                        block.phase(), previous, current)) {
                        targets++;
                    }
                    previous = current;
                }
                assertEquals(block.phase().isAx() ? 6 : 8, targets);
            }
        }
    }

    @Test
    void scoreUsesOnlyTestBalancedAccuracyAndRoundsOnce() {
        ContinuousAttentionMetrics metrics =
            ContinuousAttentionTestFixtures.metrics(
                GOLDEN_SESSION,
                (phase, target, targetOrdinal, nonTargetOrdinal) -> {
                    if (phase.isPractice()) {
                        return target;
                    }
                    if (phase == ContinuousAttentionPhase.X_TEST) {
                        return target ? targetOrdinal <= 120 : nonTargetOrdinal <= 46;
                    }
                    return target ? targetOrdinal <= 108 : nonTargetOrdinal <= 100;
                });

        ContinuousAttentionReport report = scoring.report(GOLDEN_SESSION, metrics);
        Score score = scoring.score(report);

        assertEquals(160, report.xPhase().targetCount());
        assertEquals(460, report.xPhase().nonTargetCount());
        assertEquals(120, report.xPhase().hitCount());
        assertEquals(40, report.xPhase().omissionCount());
        assertEquals(46, report.xPhase().commissionCount());
        assertEquals(414, report.xPhase().correctRejectionCount());
        assertEquals(75.0, report.xPhase().hitRatePercent(), 1e-12);
        assertEquals(90.0, report.xPhase().correctRejectionRatePercent(), 1e-12);
        assertEquals(82.5, report.xPhase().balancedAccuracyPercent(), 1e-12);
        assertEquals(1.9462343855, report.xPhase().dPrime(), 1e-8);
        assertEquals(0.3035058635, report.xPhase().responseBiasC(), 1e-8);

        assertEquals(120, report.axPhase().targetCount());
        assertEquals(500, report.axPhase().nonTargetCount());
        assertEquals(108, report.axPhase().hitCount());
        assertEquals(12, report.axPhase().omissionCount());
        assertEquals(100, report.axPhase().commissionCount());
        assertEquals(400, report.axPhase().correctRejectionCount());
        assertEquals(90.0, report.axPhase().hitRatePercent(), 1e-12);
        assertEquals(80.0, report.axPhase().correctRejectionRatePercent(), 1e-12);
        assertEquals(85.0, report.axPhase().balancedAccuracyPercent(), 1e-12);
        assertEquals(2.1024219831, report.axPhase().dPrime(), 1e-8);
        assertEquals(-0.2117267076, report.axPhase().responseBiasC(), 1e-8);

        assertEquals(84, score.rawPoints());
        assertEquals(100, score.maxPoints());
        assertEquals("Descriptive — provisional", score.level());
    }

    @Test
    void perfectIs100AndDegenerateStrategiesExposeChanceFloor50() {
        assertEquals(100, scoring.score(scoring.report(
            GOLDEN_SESSION,
            ContinuousAttentionTestFixtures.perfect(GOLDEN_SESSION))).rawPoints());
        assertEquals(50, scoring.score(scoring.report(
            GOLDEN_SESSION,
            ContinuousAttentionTestFixtures.neverRespond(GOLDEN_SESSION))).rawPoints());
        assertEquals(50, scoring.score(scoring.report(
            GOLDEN_SESSION,
            ContinuousAttentionTestFixtures.alwaysRespond(GOLDEN_SESSION))).rawPoints());
    }

    @Test
    void practiceResponsesAreStrictlyExcludedFromScoreAndFinalIndicators() {
        ContinuousAttentionMetrics practicePerfect =
            ContinuousAttentionTestFixtures.metrics(
                GOLDEN_SESSION,
                (phase, target, targetOrdinal, nonTargetOrdinal) -> target);
        ContinuousAttentionMetrics practiceOpposite =
            ContinuousAttentionTestFixtures.metrics(
                GOLDEN_SESSION,
                (phase, target, targetOrdinal, nonTargetOrdinal) ->
                    phase.isPractice() ? !target : target);

        ContinuousAttentionReport first =
            scoring.report(GOLDEN_SESSION, practicePerfect);
        ContinuousAttentionReport second =
            scoring.report(GOLDEN_SESSION, practiceOpposite);

        assertEquals(first.provisionalAccuracyScore(),
            second.provisionalAccuracyScore());
        assertEquals(first.xPhase(), second.xPhase());
        assertEquals(first.axPhase(), second.axPhase());
        assertEquals(first.epochs(), second.epochs());
    }

    @Test
    void rationalHalfUpRoundingAvoidsJavaDartFloatingDivergence() {
        ContinuousAttentionMetrics metrics =
            ContinuousAttentionTestFixtures.metrics(
                GOLDEN_SESSION,
                (phase, target, targetOrdinal, nonTargetOrdinal) -> {
                    if (phase.isPractice()) {
                        return target;
                    }
                    if (phase == ContinuousAttentionPhase.X_TEST) {
                        // X : hits 0, correct rejections 0.
                        return !target;
                    }
                    // AX : hits 0, CR 290 sur 500 (donc 210 commissions).
                    return !target && nonTargetOrdinal <= 210;
                });

        ContinuousAttentionReport report = scoring.report(GOLDEN_SESSION, metrics);

        assertEquals(0, report.xPhase().hitCount());
        assertEquals(0, report.xPhase().correctRejectionCount());
        assertEquals(0, report.axPhase().hitCount());
        assertEquals(290, report.axPhase().correctRejectionCount());
        assertEquals(15, scoring.score(report).rawPoints(),
            "14.5 doit être arrondi half-up à 15, sans flottants");
    }

    @Test
    void latencyWindowIsHalfOpenAndResponseTupleIsCoherent() {
        assertResponseLatencyAccepted(0);
        assertResponseLatencyAccepted(689);
        assertThrows(IllegalArgumentException.class,
            () -> responseTrial(690, 1_690L));
        assertThrows(IllegalArgumentException.class,
            () -> new ContinuousAttentionTrialMetric(
                1, null, "X", 0, 0, null, 0, 0, null,
                690, 230, ContinuousAttentionInputSource.TOUCH, 0, false));
        assertThrows(IllegalArgumentException.class,
            () -> new ContinuousAttentionTrialMetric(
                1, null, "X", 57, 1, 200, 0, 1_000, 1_201L,
                690, 230, ContinuousAttentionInputSource.KEYBOARD, 0, false));
    }

    @Test
    void timingToleranceInvalidatesAuditButNeverChangesScore() {
        ContinuousAttentionMetrics base =
            ContinuousAttentionTestFixtures.perfect(GOLDEN_SESSION);
        ContinuousAttentionTrialMetric original =
            base.blocks().get(0).trials().get(0);
        ContinuousAttentionMetrics accepted = ContinuousAttentionTestFixtures.replaceTrial(
            base, 0, 0, withDisplayDuration(original, 790));
        ContinuousAttentionMetrics rejected = ContinuousAttentionTestFixtures.replaceTrial(
            base, 0, 0, withDisplayDuration(original, 791));

        ContinuousAttentionReport acceptedReport = scoring.report(GOLDEN_SESSION, accepted);
        ContinuousAttentionReport rejectedReport = scoring.report(GOLDEN_SESSION, rejected);

        assertTrue(acceptedReport.sessionValid(), "écart exact de 100 ms accepté");
        assertEquals(0, acceptedReport.timingDeviationCount());
        assertFalse(rejectedReport.sessionValid(), "écart de 101 ms invalide");
        assertEquals(1, rejectedReport.timingDeviationCount());
        assertEquals(
            scoring.score(acceptedReport).rawPoints(),
            scoring.score(rejectedReport).rawPoints(),
            "le timing ne doit jamais entrer dans le /100");
    }

    @Test
    void droppedFramesRemainDescriptiveWhileBackgroundInvalidates() {
        ContinuousAttentionMetrics base =
            ContinuousAttentionTestFixtures.perfect(GOLDEN_SESSION);
        ContinuousAttentionMetrics dropped = new ContinuousAttentionMetrics(
            base.protocolVersion(), base.blocks(), true, false, 0, 3);
        ContinuousAttentionMetrics background = new ContinuousAttentionMetrics(
            base.protocolVersion(), base.blocks(), true, false, 1, 0);
        ContinuousAttentionMetrics interrupted = new ContinuousAttentionMetrics(
            base.protocolVersion(), base.blocks(), true, true, 0, 0);

        assertTrue(scoring.report(GOLDEN_SESSION, dropped).sessionValid());
        assertFalse(scoring.report(GOLDEN_SESSION, background).sessionValid());
        ContinuousAttentionReport interruptedReport =
            scoring.report(GOLDEN_SESSION, interrupted);
        assertFalse(interruptedReport.sessionValid());
        assertEquals(List.of("INTERRUPTED"), interruptedReport.validityIssues());
    }

    @Test
    void deterministicMismatchAndMutableListsAreRejected() {
        ContinuousAttentionMetrics metrics =
            ContinuousAttentionTestFixtures.perfect(GOLDEN_SESSION);
        assertThrows(IllegalArgumentException.class,
            () -> scoring.report(UUID.randomUUID(), metrics));
        assertThrows(UnsupportedOperationException.class,
            () -> metrics.blocks().clear());
        assertThrows(UnsupportedOperationException.class,
            () -> metrics.blocks().get(0).trials().clear());
    }

    @Test
    void actualOnsetsMustBeStrictlyMonotoneWithinEachPhase() {
        ContinuousAttentionMetrics base =
            ContinuousAttentionTestFixtures.neverRespond(GOLDEN_SESSION);
        ContinuousAttentionTrialMetric second =
            base.blocks().get(0).trials().get(1);
        ContinuousAttentionTrialMetric nonMonotone =
            new ContinuousAttentionTrialMetric(
                second.trialIndex(), second.previousLetter(), second.currentLetter(),
                second.responseCode(), second.correct(), second.latencyMs(),
                second.scheduledOnsetMs(), 0, second.responseTimestampMs(),
                second.actualDisplayDurationMs(), second.actualIsiDurationMs(),
                second.inputSource(), second.extraResponseCount(), second.interrupted());

        assertThrows(IllegalArgumentException.class,
            () -> ContinuousAttentionTestFixtures.replaceTrial(
                base, 0, 1, nonMonotone));
    }

    private static void assertResponseLatencyAccepted(int latency) {
        ContinuousAttentionTrialMetric trial =
            responseTrial(latency, 1_000L + latency);
        assertEquals(latency, trial.latencyMs());
    }

    private static ContinuousAttentionTrialMetric responseTrial(
            int latency, long responseTimestamp) {
        return new ContinuousAttentionTrialMetric(
            1, null, "X", 57, 1, latency,
            0, 1_000, responseTimestamp,
            690, 230, ContinuousAttentionInputSource.KEYBOARD, 0, false);
    }

    private static ContinuousAttentionTrialMetric withDisplayDuration(
            ContinuousAttentionTrialMetric t, int displayDuration) {
        return new ContinuousAttentionTrialMetric(
            t.trialIndex(), t.previousLetter(), t.currentLetter(),
            t.responseCode(), t.correct(), t.latencyMs(),
            t.scheduledOnsetMs(), t.actualOnsetMs(), t.responseTimestampMs(),
            displayDuration, t.actualIsiDurationMs(), t.inputSource(),
            t.extraResponseCount(), t.interrupted());
    }
}
