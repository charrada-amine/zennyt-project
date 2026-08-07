package com.zennyt.games.domain.service;

import com.zennyt.games.domain.config.ObjectLocationConfig;
import com.zennyt.games.domain.config.ObjectLocationProvisionalRules;
import com.zennyt.games.domain.vo.ObjectLocationCompletionReason;
import com.zennyt.games.domain.vo.ObjectLocationErrorCategory;
import com.zennyt.games.domain.vo.ObjectLocationLevelMetric;
import com.zennyt.games.domain.vo.ObjectLocationLevelReport;
import com.zennyt.games.domain.vo.ObjectLocationMetrics;
import com.zennyt.games.domain.vo.ObjectLocationPhase;
import com.zennyt.games.domain.vo.ObjectLocationReport;
import com.zennyt.games.domain.vo.Score;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Recalcule côté serveur le layout, l'état final, le score et les indicateurs.
 *
 * <p>Les quatre catégories sont exclusives : EXACT, puis SWAP, puis LOCAL,
 * puis GLOBAL, puis UNPLACED. Un objet non placé reçoit la distance diagonale
 * maximale mais ne gonfle pas artificiellement les erreurs globales placées.
 */
public final class ObjectLocationScoringService {

    private final ObjectLocationLayoutGenerator generator =
        new ObjectLocationLayoutGenerator();
    private final ObjectLocationActionReplayer replayer =
        new ObjectLocationActionReplayer();

    public ObjectLocationReport report(UUID sessionId, ObjectLocationMetrics metrics) {
        generator.validate(sessionId, metrics);
        List<ObjectLocationLayoutGenerator.GeneratedLevel> layouts =
            generator.generate(sessionId);
        List<ObjectLocationLevelReport> levelReports = new ArrayList<>();
        List<ObjectLocationActionReplayer.Replay> replays = new ArrayList<>();
        int timingDeviationCount = 0;

        for (int i = 0; i < metrics.levels().size(); i++) {
            ObjectLocationLevelMetric level = metrics.levels().get(i);
            ObjectLocationActionReplayer.Replay replay =
                replayer.replay(layouts.get(i), level);
            replays.add(replay);
            levelReports.add(levelReport(layouts.get(i), level, replay));
            if (hasTimingDeviation(level)) timingDeviationCount++;
        }

        List<ObjectLocationLevelReport> completedTests = levelReports.stream()
            .filter(level -> level.phase() == ObjectLocationPhase.TEST
                && level.completed())
            .toList();
        int completedLevelCount = completedTests.size();
        int passedLevelCount = (int) completedTests.stream()
            .filter(ObjectLocationLevelReport::passed).count();
        int administeredObjects = completedTests.stream()
            .mapToInt(ObjectLocationLevelReport::objectCount).sum();
        int exact = completedTests.stream()
            .mapToInt(ObjectLocationLevelReport::exactCount).sum();
        int swaps = completedTests.stream()
            .mapToInt(ObjectLocationLevelReport::swapCount).sum();
        int local = completedTests.stream()
            .mapToInt(ObjectLocationLevelReport::localErrorCount).sum();
        int global = completedTests.stream()
            .mapToInt(ObjectLocationLevelReport::globalErrorCount).sum();
        int unplaced = completedTests.stream()
            .mapToInt(ObjectLocationLevelReport::unplacedCount).sum();
        int repositionCount = completedTests.stream()
            .mapToInt(ObjectLocationLevelReport::repositionCount).sum();
        double displacementSum = completedTests.stream()
            .mapToDouble(level -> level.averageDisplacementCells()
                * level.objectCount()).sum();
        int span = completedTests.stream()
            .filter(ObjectLocationLevelReport::passed)
            .mapToInt(ObjectLocationLevelReport::objectCount)
            .max().orElse(0);

        boolean noContinuationAfterStop = noContinuationAfterStop(completedTests);
        boolean allProvidedTestsCompleted = levelReports.stream()
            .filter(level -> level.phase() == ObjectLocationPhase.TEST)
            .allMatch(ObjectLocationLevelReport::completed);
        boolean progressionValid = progressionValid(
            metrics.completionReason(), completedTests,
            allProvidedTestsCompleted, noContinuationAfterStop);
        boolean minimumLevelsValid =
            completedLevelCount >= ObjectLocationConfig.MIN_VALID_TEST_LEVELS;
        boolean timingValid = timingDeviationCount == 0;
        boolean technicalValid = metrics.sessionCompleted()
            && !metrics.interrupted()
            && metrics.backgroundEventCount() == 0
            && metrics.focusLossCount() == 0
            && metrics.orientationChangeCount() == 0
            && timingValid;
        boolean sessionValid = technicalValid
            && minimumLevelsValid && progressionValid;

        List<String> issues = validityIssues(metrics, minimumLevelsValid,
            progressionValid, timingValid);
        Score provisional = ObjectLocationProvisionalRules.score(exact, administeredObjects);

        return new ObjectLocationReport(
            ObjectLocationConfig.PROTOCOL_VERSION,
            metrics.completionReason(),
            metrics.sessionCompleted(),
            sessionValid,
            technicalValid,
            minimumLevelsValid,
            progressionValid,
            timingValid,
            provisional.rawPoints(),
            completedLevelCount,
            passedLevelCount,
            administeredObjects,
            exact,
            swaps,
            local,
            global,
            unplaced,
            percent(exact, administeredObjects),
            percent(swaps, administeredObjects),
            percent(local, administeredObjects),
            percent(global, administeredObjects),
            administeredObjects == 0 ? 0.0 : displacementSum / administeredObjects,
            span,
            loadSlope(completedTests),
            averageFirstPlacementInterval(levelReports, replays),
            repositionCount,
            metrics.backgroundEventCount(),
            metrics.focusLossCount(),
            metrics.orientationChangeCount(),
            metrics.droppedFrameCount(),
            timingDeviationCount,
            levelReports,
            issues);
    }

    public Score score(ObjectLocationReport report) {
        return new Score(report.provisionalAccuracyScore(),
            ObjectLocationProvisionalRules.MAX_POINTS,
            ObjectLocationProvisionalRules.DESCRIPTIVE_LEVEL);
    }

    private static ObjectLocationLevelReport levelReport(
            ObjectLocationLayoutGenerator.GeneratedLevel layout,
            ObjectLocationLevelMetric metric,
            ObjectLocationActionReplayer.Replay replay) {
        Map<String, Integer> origins = layout.originsByObject();
        Set<Integer> allOrigins = new HashSet<>(origins.values());
        int exact = 0;
        int swap = 0;
        int local = 0;
        int global = 0;
        int unplaced = 0;
        double distanceSum = 0.0;

        for (Map.Entry<String, Integer> origin : origins.entrySet()) {
            Integer finalCell = replay.finalCellsByObject().get(origin.getKey());
            Evaluation evaluation = evaluate(origin.getValue(), finalCell, allOrigins);
            distanceSum += evaluation.distance();
            switch (evaluation.category()) {
                case EXACT -> exact++;
                case SWAP -> swap++;
                case LOCAL -> local++;
                case GLOBAL -> global++;
                case UNPLACED -> unplaced++;
            }
        }
        boolean passed = metric.completed()
            && exact >= ObjectLocationConfig.passThreshold(metric.objectCount());
        return new ObjectLocationLevelReport(
            metric.phase(), metric.levelIndex(), metric.objectCount(),
            metric.completed(), metric.timedOut(), passed,
            exact, swap, local, global, unplaced,
            percent(exact, metric.objectCount()),
            distanceSum / metric.objectCount(),
            metric.actualRecallDurationMs(), metric.actions().size(),
            replay.repositionCount(), replay.averageFirstPlacementIntervalMs());
    }

    private static Evaluation evaluate(int originCell,
                                       Integer finalCell,
                                       Set<Integer> allOrigins) {
        if (finalCell == null) {
            return new Evaluation(ObjectLocationErrorCategory.UNPLACED,
                ObjectLocationConfig.MAX_CELL_DISTANCE);
        }
        double distance = distance(originCell, finalCell);
        if (finalCell == originCell) {
            return new Evaluation(ObjectLocationErrorCategory.EXACT, 0.0);
        }
        if (allOrigins.contains(finalCell)) {
            return new Evaluation(ObjectLocationErrorCategory.SWAP, distance);
        }
        if (distance <= 1.0) {
            return new Evaluation(ObjectLocationErrorCategory.LOCAL, distance);
        }
        return new Evaluation(ObjectLocationErrorCategory.GLOBAL, distance);
    }

    private static double distance(int first, int second) {
        int rowDifference = first / ObjectLocationConfig.GRID_SIDE
            - second / ObjectLocationConfig.GRID_SIDE;
        int columnDifference = first % ObjectLocationConfig.GRID_SIDE
            - second % ObjectLocationConfig.GRID_SIDE;
        return Math.sqrt(rowDifference * rowDifference
            + columnDifference * columnDifference);
    }

    private static boolean hasTimingDeviation(ObjectLocationLevelMetric level) {
        if (!level.completed()) return true;
        if (Math.abs(level.actualEncodingDurationMs()
                - ObjectLocationConfig.encodingDurationMs(level.objectCount()))
            > ObjectLocationConfig.TIMING_TOLERANCE_MS) return true;
        if (Math.abs(level.actualRetentionDurationMs()
                - ObjectLocationConfig.RETENTION_MS)
            > ObjectLocationConfig.TIMING_TOLERANCE_MS) return true;
        int recallLimit = ObjectLocationConfig.recallLimitMs(level.objectCount());
        if (level.timedOut()) {
            return Math.abs(level.actualRecallDurationMs() - recallLimit)
                > ObjectLocationConfig.RECALL_TECHNICAL_TOLERANCE_MS;
        }
        int minimumRecall = ObjectLocationConfig.MIN_RECALL_MS_PER_OBJECT
            * level.objectCount();
        return level.actualRecallDurationMs() < minimumRecall
            || level.actualRecallDurationMs()
                > recallLimit + ObjectLocationConfig.RECALL_TECHNICAL_TOLERANCE_MS;
    }

    private static boolean noContinuationAfterStop(
            List<ObjectLocationLevelReport> completedTests) {
        for (int i = ObjectLocationConfig.MIN_VALID_TEST_LEVELS - 1;
             i < completedTests.size() - 1; i++) {
            if (!completedTests.get(i).passed()
                && !completedTests.get(i - 1).passed()) return false;
        }
        return true;
    }

    private static boolean progressionValid(
            ObjectLocationCompletionReason reason,
            List<ObjectLocationLevelReport> completedTests,
            boolean allProvidedTestsCompleted,
            boolean noContinuationAfterStop) {
        if (!noContinuationAfterStop) return false;
        int count = completedTests.size();
        return switch (reason) {
            case MAX_LEVELS -> allProvidedTestsCompleted
                && count == ObjectLocationConfig.TEST_OBJECT_COUNTS.size();
            case STOP_RULE -> allProvidedTestsCompleted
                && count >= ObjectLocationConfig.MIN_VALID_TEST_LEVELS
                && count < ObjectLocationConfig.TEST_OBJECT_COUNTS.size()
                && !completedTests.get(count - 1).passed()
                && !completedTests.get(count - 2).passed();
            case TECHNICAL_INTERRUPTION -> true;
        };
    }

    private static List<String> validityIssues(
            ObjectLocationMetrics metrics,
            boolean minimumLevelsValid,
            boolean progressionValid,
            boolean timingValid) {
        List<String> issues = new ArrayList<>();
        if (!metrics.sessionCompleted()) issues.add("SESSION_INCOMPLETE");
        if (metrics.interrupted()) issues.add("INTERRUPTED");
        if (metrics.backgroundEventCount() > 0) issues.add("BACKGROUND_EVENT");
        if (metrics.focusLossCount() > 0) issues.add("FOCUS_LOSS");
        if (metrics.orientationChangeCount() > 0) issues.add("ORIENTATION_CHANGE");
        if (!timingValid) issues.add("TIMING_DEVIATION");
        if (!minimumLevelsValid) issues.add("INSUFFICIENT_TEST_LEVELS");
        if (!progressionValid) issues.add("INVALID_PROGRESSION");
        return issues;
    }

    private static Double loadSlope(List<ObjectLocationLevelReport> levels) {
        if (levels.size() < 2) return null;
        double meanX = levels.stream()
            .mapToDouble(ObjectLocationLevelReport::objectCount).average().orElse(0.0);
        double meanY = levels.stream()
            .mapToDouble(ObjectLocationLevelReport::exactAccuracyPercent).average().orElse(0.0);
        double numerator = 0.0;
        double denominator = 0.0;
        for (ObjectLocationLevelReport level : levels) {
            double dx = level.objectCount() - meanX;
            numerator += dx * (level.exactAccuracyPercent() - meanY);
            denominator += dx * dx;
        }
        return denominator == 0.0 ? null : numerator / denominator;
    }

    private static Double averageFirstPlacementInterval(
            List<ObjectLocationLevelReport> reports,
            List<ObjectLocationActionReplayer.Replay> replays) {
        double weightedSum = 0.0;
        int intervalCount = 0;
        for (int i = 0; i < reports.size(); i++) {
            if (reports.get(i).phase() != ObjectLocationPhase.TEST
                || !reports.get(i).completed()) continue;
            ObjectLocationActionReplayer.Replay replay = replays.get(i);
            if (replay.averageFirstPlacementIntervalMs() != null) {
                weightedSum += replay.averageFirstPlacementIntervalMs()
                    * replay.firstPlacementIntervalCount();
                intervalCount += replay.firstPlacementIntervalCount();
            }
        }
        return intervalCount == 0 ? null : weightedSum / intervalCount;
    }

    private static double percent(int numerator, int denominator) {
        return denominator == 0 ? 0.0 : numerator * 100.0 / denominator;
    }

    private record Evaluation(ObjectLocationErrorCategory category, double distance) {
    }
}
