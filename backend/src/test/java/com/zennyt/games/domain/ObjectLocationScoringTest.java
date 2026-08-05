package com.zennyt.games.domain;

import com.zennyt.games.domain.config.ObjectLocationConfig;
import com.zennyt.games.domain.config.ObjectLocationProvisionalRules;
import com.zennyt.games.domain.service.ObjectLocationLayoutGenerator;
import com.zennyt.games.domain.service.ObjectLocationScoringService;
import com.zennyt.games.domain.vo.ObjectLocationActionType;
import com.zennyt.games.domain.vo.ObjectLocationCompletionReason;
import com.zennyt.games.domain.vo.ObjectLocationLevelMetric;
import com.zennyt.games.domain.vo.ObjectLocationMetrics;
import com.zennyt.games.domain.vo.ObjectLocationPhase;
import com.zennyt.games.domain.vo.ObjectLocationPlacementAction;
import com.zennyt.games.domain.vo.ObjectLocationReport;
import com.zennyt.games.domain.vo.ObjectLocationReserveZone;
import com.zennyt.games.support.ObjectLocationTestFixtures;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ObjectLocationScoringTest {

    private final ObjectLocationLayoutGenerator generator =
        new ObjectLocationLayoutGenerator();
    private final ObjectLocationScoringService scoring =
        new ObjectLocationScoringService();

    @Test
    void provisionalConfigIsIsolatedAndUsesTheValidatedFineProgression() {
        assertEquals("OBJECT_LOCATION_FINE_V1", ObjectLocationConfig.PROTOCOL_VERSION);
        assertEquals(List.of(3, 4, 5, 6, 7, 8),
            ObjectLocationConfig.TEST_OBJECT_COUNTS);
        assertEquals(List.of(2, 3, 3, 4, 5, 5),
            List.of(3, 4, 5, 6, 7, 8).stream()
                .map(ObjectLocationConfig::passThreshold).toList());
        assertEquals(20, ObjectLocationConfig.OBJECT_CATALOG_V1.size());
        assertEquals(20, new HashSet<>(ObjectLocationConfig.OBJECT_CATALOG_V1).size());
        assertEquals(13, ObjectLocationProvisionalRules.score(1, 8).rawPoints());
        assertEquals(50, ObjectLocationProvisionalRules.score(4, 8).rawPoints());
        assertEquals("Descriptive — provisional",
            ObjectLocationProvisionalRules.score(4, 8).level());
    }

    @Test
    void goldenLayoutLocksPrngDrawOrderObjectsOriginsAndReserve() {
        List<ObjectLocationLayoutGenerator.GeneratedLevel> levels =
            generator.generate(ObjectLocationTestFixtures.SESSION_ID);

        assertEquals(List.of(
            "SMARTPHONE@13/BELOW#1", "SNEAKER@1/BELOW#0"), spec(levels.get(0)));
        assertEquals(List.of(
            "SUNGLASSES@0/BELOW#2", "PORTABLE_SPEAKER@3/BELOW#0",
            "NOTEBOOK@7/BELOW#1"), spec(levels.get(1)));
        assertEquals(List.of(
            "BICYCLE_HELMET@9/LEFT#3", "SUCCULENT@7/LEFT#0",
            "WIRELESS_EARBUDS@5/LEFT#1", "INSTANT_CAMERA@0/LEFT#2"),
            spec(levels.get(2)));
        assertEquals(List.of(
            "CERAMIC_MUG@8/RIGHT#1", "TRAVEL_POUCH@2/RIGHT#2",
            "SMARTWATCH@7/RIGHT#3", "BACKPACK@0/RIGHT#4",
            "DESK_LAMP@9/RIGHT#0"), spec(levels.get(3)));
        assertEquals(List.of(
            "COMPACT_DRONE@4/LEFT#1", "POWER_BANK@10/LEFT#2",
            "KEYCARD@15/RIGHT#1", "STYLUS_TABLET@12/LEFT#0",
            "GAME_CONTROLLER@13/RIGHT#2", "REUSABLE_BOTTLE@11/RIGHT#0"),
            spec(levels.get(4)));
        assertEquals(List.of(
            "NOTEBOOK@4/BELOW#2", "SUNGLASSES@2/BELOW#0",
            "CERAMIC_MUG@7/BELOW#6", "SUCCULENT@12/BELOW#1",
            "SMARTWATCH@5/BELOW#3", "GAME_CONTROLLER@14/BELOW#5",
            "INSTANT_CAMERA@15/BELOW#4"), spec(levels.get(5)));
        assertEquals(List.of(
            "SMARTPHONE@2/LEFT#4", "KEYCARD@3/LEFT#1",
            "STYLUS_TABLET@4/LEFT#7", "DESK_LAMP@6/LEFT#6",
            "BACKPACK@15/LEFT#5", "PORTABLE_SPEAKER@7/LEFT#3",
            "SNEAKER@13/LEFT#2", "POWER_BANK@14/LEFT#0"),
            spec(levels.get(6)));
    }

    @Test
    void everyLayoutHasUniqueObjectsNoRegularLineAndNoRepeatedCellPerObject() {
        List<ObjectLocationLayoutGenerator.GeneratedLevel> levels =
            generator.generate(UUID.fromString("12345678-1234-4234-8234-123456789abc"));
        Map<String, Set<Integer>> priorCells = new HashMap<>();
        Map<String, Integer> uses = new HashMap<>();
        for (var level : levels) {
            Set<String> ids = new HashSet<>();
            Set<Integer> cells = new HashSet<>();
            for (var object : level.objects()) {
                assertTrue(ids.add(object.objectId()));
                assertTrue(cells.add(object.originCellIndex()));
                assertTrue(priorCells
                    .computeIfAbsent(object.objectId(), ignored -> new HashSet<>())
                    .add(object.originCellIndex()));
                uses.merge(object.objectId(), 1, Integer::sum);
            }
            assertFalse(containsCompleteLine(cells));
        }
        int min = uses.values().stream().mapToInt(Integer::intValue).min().orElseThrow();
        int max = uses.values().stream().mapToInt(Integer::intValue).max().orElseThrow();
        assertTrue(max - min <= 1);
    }

    @Test
    void perfectRunScoresOneHundredAndExcludesPractice() {
        ObjectLocationReport report = scoring.report(
            ObjectLocationTestFixtures.SESSION_ID,
            ObjectLocationTestFixtures.perfect(ObjectLocationTestFixtures.SESSION_ID));

        assertTrue(report.sessionValid());
        assertEquals(100, report.provisionalAccuracyScore());
        assertEquals(33, report.administeredObjectCount());
        assertEquals(33, report.exactPlacementCount());
        assertEquals(6, report.completedLevelCount());
        assertEquals(8, report.span());
        assertEquals(0, report.swapCount());
        assertEquals(0, report.unplacedCount());
        assertEquals(500.0, report.averageFirstPlacementIntervalMs());
        assertEquals(0.0, report.loadSlope());
    }

    @Test
    void stopAfterTwoFailuresIsValidOnlyAfterThreeCompletedLevels() {
        ObjectLocationReport report = scoring.report(
            ObjectLocationTestFixtures.SESSION_ID,
            ObjectLocationTestFixtures.validStopRule(ObjectLocationTestFixtures.SESSION_ID));

        assertTrue(report.sessionValid());
        assertTrue(report.progressionValid());
        assertEquals(3, report.completedLevelCount());
        assertEquals(1, report.passedLevelCount());
        assertEquals(3, report.exactPlacementCount());
        assertEquals(12, report.administeredObjectCount());
        assertEquals(9, report.unplacedCount());
        assertEquals(0, report.globalErrorCount());
        assertEquals(25, report.provisionalAccuracyScore());
    }

    @Test
    void continuingAfterEligibleFailurePairInvalidatesTheRun() {
        var layouts = generator.generate(ObjectLocationTestFixtures.SESSION_ID);
        List<ObjectLocationLevelMetric> levels = List.of(
            ObjectLocationTestFixtures.perfectLevel(layouts.get(0)),
            ObjectLocationTestFixtures.perfectLevel(layouts.get(1)),
            ObjectLocationTestFixtures.timeoutLevel(layouts.get(2)),
            ObjectLocationTestFixtures.timeoutLevel(layouts.get(3)),
            ObjectLocationTestFixtures.perfectLevel(layouts.get(4)));
        ObjectLocationMetrics metrics = new ObjectLocationMetrics(
            ObjectLocationConfig.PROTOCOL_VERSION,
            ObjectLocationCompletionReason.STOP_RULE,
            levels, true, false, 0, 0, 0, 0);

        ObjectLocationReport report = scoring.report(
            ObjectLocationTestFixtures.SESSION_ID, metrics);

        assertFalse(report.progressionValid());
        assertFalse(report.sessionValid());
        assertTrue(report.validityIssues().contains("INVALID_PROGRESSION"));
    }

    @Test
    void tooFastRecallIsAuditOnlyAndTimeoutUsesTwoHundredFiftyMsGrace() {
        var layouts = generator.generate(ObjectLocationTestFixtures.SESSION_ID);
        ObjectLocationLevelMetric fast = perfectAtDuration(
            layouts.get(1),
            ObjectLocationConfig.MIN_RECALL_MS_PER_OBJECT
                * layouts.get(1).objectCount() - 1);
        List<ObjectLocationLevelMetric> fastLevels = new ArrayList<>(
            ObjectLocationTestFixtures.perfect(ObjectLocationTestFixtures.SESSION_ID).levels());
        fastLevels.set(1, fast);
        ObjectLocationMetrics fastMetrics = new ObjectLocationMetrics(
            ObjectLocationConfig.PROTOCOL_VERSION,
            ObjectLocationCompletionReason.MAX_LEVELS,
            fastLevels, true, false, 0, 0, 0, 0);
        ObjectLocationReport fastReport = scoring.report(
            ObjectLocationTestFixtures.SESSION_ID, fastMetrics);
        assertFalse(fastReport.timingValid());
        assertFalse(fastReport.sessionValid());

        var layout = layouts.get(2);
        ObjectLocationLevelMetric withinGrace = new ObjectLocationLevelMetric(
            layout.phase(), layout.levelIndex(), layout.objectCount(),
            ObjectLocationConfig.encodingDurationMs(layout.objectCount()),
            ObjectLocationConfig.RETENTION_MS,
            ObjectLocationConfig.recallLimitMs(layout.objectCount()) + 250,
            true, true, List.of());
        assertEquals(ObjectLocationConfig.recallLimitMs(layout.objectCount()) + 250,
            withinGrace.actualRecallDurationMs());
        assertThrows(IllegalArgumentException.class, () ->
            new ObjectLocationLevelMetric(
                layout.phase(), layout.levelIndex(), layout.objectCount(),
                ObjectLocationConfig.encodingDurationMs(layout.objectCount()),
                ObjectLocationConfig.RETENTION_MS,
                ObjectLocationConfig.recallLimitMs(layout.objectCount()) + 251,
                true, true, List.of()));
    }

    @Test
    void unknownObjectAndImpossibleCompletedStateAreRejectedBeforeScoring() {
        var layouts = generator.generate(ObjectLocationTestFixtures.SESSION_ID);
        var level = layouts.get(0);
        ObjectLocationLevelMetric forged = new ObjectLocationLevelMetric(
            level.phase(), level.levelIndex(), level.objectCount(),
            ObjectLocationConfig.encodingDurationMs(level.objectCount()),
            ObjectLocationConfig.RETENTION_MS, 1_000, false, true,
            List.of(new ObjectLocationPlacementAction(
                1, ObjectLocationActionType.PLACE, "FORGED_OBJECT", 0, 500)));
        ObjectLocationMetrics metrics = new ObjectLocationMetrics(
            ObjectLocationConfig.PROTOCOL_VERSION,
            ObjectLocationCompletionReason.TECHNICAL_INTERRUPTION,
            List.of(forged), false, true, 0, 0, 0, 0);
        assertThrows(IllegalArgumentException.class, () ->
            scoring.report(ObjectLocationTestFixtures.SESSION_ID, metrics));

        ObjectLocationLevelMetric incompletePlacement = new ObjectLocationLevelMetric(
            level.phase(), level.levelIndex(), level.objectCount(),
            ObjectLocationConfig.encodingDurationMs(level.objectCount()),
            ObjectLocationConfig.RETENTION_MS, 1_000, false, true,
            List.of());
        ObjectLocationMetrics incomplete = new ObjectLocationMetrics(
            ObjectLocationConfig.PROTOCOL_VERSION,
            ObjectLocationCompletionReason.TECHNICAL_INTERRUPTION,
            List.of(incompletePlacement), false, true, 0, 0, 0, 0);
        assertThrows(IllegalArgumentException.class, () ->
            scoring.report(ObjectLocationTestFixtures.SESSION_ID, incomplete));
    }

    @Test
    void incompleteTechnicalRunHasNoScoreValidityOrSlope() {
        var practice = generator.generate(ObjectLocationTestFixtures.SESSION_ID).get(0);
        ObjectLocationLevelMetric partial = new ObjectLocationLevelMetric(
            practice.phase(), 0, practice.objectCount(), 0, 0, 0,
            false, false, List.of());
        ObjectLocationMetrics metrics = new ObjectLocationMetrics(
            ObjectLocationConfig.PROTOCOL_VERSION,
            ObjectLocationCompletionReason.TECHNICAL_INTERRUPTION,
            List.of(partial), false, true, 0, 0, 0, 0);

        ObjectLocationReport report = scoring.report(
            ObjectLocationTestFixtures.SESSION_ID, metrics);

        assertFalse(report.sessionValid());
        assertEquals(0, report.administeredObjectCount());
        assertEquals(0, report.provisionalAccuracyScore());
        assertNull(report.loadSlope());
        assertTrue(report.validityIssues().contains("SESSION_INCOMPLETE"));
        assertTrue(report.validityIssues().contains("INTERRUPTED"));
    }

    private static ObjectLocationLevelMetric perfectAtDuration(
            ObjectLocationLayoutGenerator.GeneratedLevel layout,
            int recallDurationMs) {
        List<ObjectLocationPlacementAction> actions = new ArrayList<>();
        for (int i = 0; i < layout.objects().size(); i++) {
            var object = layout.objects().get(i);
            actions.add(new ObjectLocationPlacementAction(
                i + 1, ObjectLocationActionType.PLACE, object.objectId(),
                object.originCellIndex(), 0));
        }
        return new ObjectLocationLevelMetric(
            layout.phase(), layout.levelIndex(), layout.objectCount(),
            ObjectLocationConfig.encodingDurationMs(layout.objectCount()),
            ObjectLocationConfig.RETENTION_MS, recallDurationMs,
            false, true, actions);
    }

    private static List<String> spec(
            ObjectLocationLayoutGenerator.GeneratedLevel level) {
        return level.objects().stream()
            .map(object -> object.objectId() + "@" + object.originCellIndex()
                + "/" + object.reserveSide() + "#" + object.reserveOrder())
            .toList();
    }

    private static boolean containsCompleteLine(Set<Integer> cells) {
        for (int row = 0; row < 4; row++) {
            if (cells.containsAll(Set.of(row * 4, row * 4 + 1,
                row * 4 + 2, row * 4 + 3))) return true;
        }
        for (int column = 0; column < 4; column++) {
            if (cells.containsAll(Set.of(column, column + 4,
                column + 8, column + 12))) return true;
        }
        return cells.containsAll(Set.of(0, 5, 10, 15))
            || cells.containsAll(Set.of(3, 6, 9, 12));
    }
}
