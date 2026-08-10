import 'dart:math' as math;

import '../domain/config/object_location_config.dart';
import '../domain/entities/game_score.dart';
import '../domain/entities/object_location_metrics.dart';

class ObjectLocationScoringResult {
  const ObjectLocationScoringResult({
    required this.score,
    required this.indicators,
  });

  final GameScore score;
  final ObjectLocationIndicators indicators;
}

/// Exact mock mirror of backend `ObjectLocationScoringService`.
///
/// PROVISOIRE — non validé par le psychologue. The mock preview controls only
/// local flow and offline demos; the backend always recalculates the result.
class ObjectLocationScoring {
  const ObjectLocationScoring();

  ObjectLocationScoringResult score({
    required String sessionId,
    required ObjectLocationMetrics metrics,
  }) {
    if (metrics.protocolVersion != ObjectLocationConfig.protocolVersion) {
      throw ArgumentError('Unsupported object-location protocol');
    }
    final layouts = ObjectLocationConfig.generateLayouts(sessionId);
    _validateMetrics(metrics, layouts);
    final levelReports = <ObjectLocationLevelIndicators>[];
    var timingDeviationCount = 0;
    for (var index = 0; index < metrics.objectLocationLevels.length; index++) {
      final metric = metrics.objectLocationLevels[index];
      final layout = layouts[index];
      if (!_timingMatches(metric)) timingDeviationCount++;
      levelReports.add(_scoreLevel(layout, metric));
    }

    final tests = levelReports
        .where((level) => level.phase == ObjectLocationPhase.test)
        .toList();
    final completedTests = tests.where((level) => level.completed).toList();
    final administered = completedTests.fold<int>(
      0,
      (sum, level) => sum + level.objectCount,
    );
    final exact = completedTests.fold<int>(
      0,
      (sum, level) => sum + level.exactCount,
    );
    final provisionalPoints = _roundHalfUp(exact, administered);
    final score = GameScore(
      rawPoints: provisionalPoints,
      maxPoints: 100,
      normalized: provisionalPoints.toDouble(),
      level: 'Descriptive — provisional',
    );
    final minimumLevelsValid =
        completedTests.length >=
        ObjectLocationConfig.minimumValidMeasuredLevels;
    final progressionValid = _progressionValid(metrics, completedTests);
    final timingValid = timingDeviationCount == 0;
    final technicalValid =
        metrics.sessionCompleted &&
        !metrics.interrupted &&
        metrics.backgroundEventCount == 0 &&
        metrics.focusLossCount == 0 &&
        metrics.orientationChangeCount == 0 &&
        timingValid;
    final sessionValid =
        technicalValid && minimumLevelsValid && progressionValid;
    final passed = completedTests.where((level) => level.passed).length;
    final issues = <String>[
      if (!metrics.sessionCompleted) 'SESSION_INCOMPLETE',
      if (metrics.interrupted) 'INTERRUPTED',
      if (metrics.backgroundEventCount > 0) 'BACKGROUND_EVENT',
      if (metrics.focusLossCount > 0) 'FOCUS_LOSS',
      if (metrics.orientationChangeCount > 0) 'ORIENTATION_CHANGE',
      if (!timingValid) 'TIMING_DEVIATION',
      if (!minimumLevelsValid) 'INSUFFICIENT_TEST_LEVELS',
      if (!progressionValid) 'INVALID_PROGRESSION',
    ];

    return ObjectLocationScoringResult(
      score: score,
      indicators: ObjectLocationIndicators(
        protocolVersion: metrics.protocolVersion,
        completionReason: metrics.completionReason,
        completed: metrics.sessionCompleted,
        sessionValid: sessionValid,
        technicalValid: technicalValid,
        minimumLevelsValid: minimumLevelsValid,
        progressionValid: progressionValid,
        timingValid: timingValid,
        provisionalAccuracyScore: provisionalPoints,
        completedLevelCount: completedTests.length,
        passedLevelCount: passed,
        administeredObjectCount: administered,
        exactPlacementCount: exact,
        swapCount: _sum(completedTests, (level) => level.swapCount),
        localErrorCount: _sum(completedTests, (level) => level.localErrorCount),
        globalErrorCount: _sum(
          completedTests,
          (level) => level.globalErrorCount,
        ),
        unplacedCount: _sum(completedTests, (level) => level.unplacedCount),
        exactAccuracyPercent: _percent(exact, administered),
        swapRatePercent: _percent(
          _sum(completedTests, (level) => level.swapCount),
          administered,
        ),
        localErrorRatePercent: _percent(
          _sum(completedTests, (level) => level.localErrorCount),
          administered,
        ),
        globalErrorRatePercent: _percent(
          _sum(completedTests, (level) => level.globalErrorCount),
          administered,
        ),
        averageDisplacementCells: administered == 0
            ? 0
            : completedTests.fold<double>(
                    0,
                    (sum, level) =>
                        sum +
                        level.averageDisplacementCells * level.objectCount,
                  ) /
                  administered,
        span: completedTests
            .where((level) => level.passed)
            .fold<int>(0, (value, level) => math.max(value, level.objectCount)),
        loadSlope: _loadSlope(completedTests),
        averageFirstPlacementIntervalMs: _averageFirstPlacementInterval(
          metrics.objectLocationLevels,
        ),
        repositionCount: _sum(completedTests, (level) => level.repositionCount),
        backgroundEventCount: metrics.backgroundEventCount,
        focusLossCount: metrics.focusLossCount,
        orientationChangeCount: metrics.orientationChangeCount,
        droppedFrameCount: metrics.droppedFrameCount,
        timingDeviationCount: timingDeviationCount,
        levels: levelReports,
        validityIssues: issues,
      ),
    );
  }

  ObjectLocationLevelIndicators _scoreLevel(
    ObjectLocationLevelLayout layout,
    ObjectLocationLevelMetric metric,
  ) {
    final placed = <String, int>{};
    final occupancy = <int, String>{};
    final placedBefore = <String>{};
    final firstPlacementTimes = <int>[];
    var repositionCount = 0;
    var previousTimestamp = -1;

    for (var index = 0; index < metric.actions.length; index++) {
      final action = metric.actions[index];
      if (action.actionIndex != index + 1 ||
          action.timestampMs < previousTimestamp ||
          action.timestampMs > metric.actualRecallDurationMs ||
          !layout.originalCells.containsKey(action.objectId)) {
        throw ArgumentError('Invalid placement action at ${index + 1}');
      }
      if (action.actionType == ObjectLocationActionType.returnToReserve) {
        if (action.targetCellIndex != null) {
          throw ArgumentError('Return action cannot target a cell');
        }
        final prior = placed.remove(action.objectId);
        if (prior != null) occupancy.remove(prior);
      } else {
        final target = action.targetCellIndex;
        if (target == null ||
            target < 0 ||
            target >= ObjectLocationConfig.cellCount) {
          throw ArgumentError('Place action requires a grid cell');
        }
        final prior = placed.remove(action.objectId);
        if (prior != null) occupancy.remove(prior);
        final ejected = occupancy.remove(target);
        if (ejected != null) placed.remove(ejected);
        placed[action.objectId] = target;
        occupancy[target] = action.objectId;
        if (placedBefore.add(action.objectId)) {
          firstPlacementTimes.add(action.timestampMs);
        } else {
          repositionCount++;
        }
      }
      previousTimestamp = action.timestampMs;
    }

    var exact = 0;
    var swaps = 0;
    var local = 0;
    var global = 0;
    var unplaced = 0;
    var totalDistance = 0.0;
    final originalCellSet = layout.originalCells.values.toSet();
    for (final entry in layout.originalCells.entries) {
      final finalCell = placed[entry.key];
      if (finalCell == null) {
        unplaced++;
        totalDistance += math.sqrt(18);
        continue;
      }
      final distance = _cellDistance(entry.value, finalCell);
      totalDistance += distance;
      if (finalCell == entry.value) {
        exact++;
      } else if (originalCellSet.contains(finalCell)) {
        swaps++;
      } else if (distance <= 1) {
        local++;
      } else {
        global++;
      }
    }
    final intervals = <int>[];
    for (var index = 1; index < firstPlacementTimes.length; index++) {
      intervals.add(
        firstPlacementTimes[index] - firstPlacementTimes[index - 1],
      );
    }
    final averageInterval = intervals.isEmpty
        ? null
        : intervals.reduce((a, b) => a + b) / intervals.length;
    return ObjectLocationLevelIndicators(
      phase: metric.phase,
      levelIndex: metric.levelIndex,
      objectCount: metric.objectCount,
      completed: metric.completed,
      timedOut: metric.timedOut,
      passed:
          metric.completed &&
          exact >=
              ObjectLocationConfig.exactPlacementsToAdvance(metric.objectCount),
      exactCount: exact,
      swapCount: swaps,
      localErrorCount: local,
      globalErrorCount: global,
      unplacedCount: unplaced,
      exactAccuracyPercent: _percent(exact, metric.objectCount),
      averageDisplacementCells: totalDistance / metric.objectCount,
      recallDurationMs: metric.actualRecallDurationMs,
      actionCount: metric.actions.length,
      repositionCount: repositionCount,
      averageFirstPlacementIntervalMs: averageInterval,
    );
  }

  void _validateMetrics(
    ObjectLocationMetrics metrics,
    List<ObjectLocationLevelLayout> layouts,
  ) {
    final levels = metrics.objectLocationLevels;
    if (levels.isEmpty || levels.length > layouts.length) {
      throw ArgumentError('Invalid number of object-location levels');
    }
    if (metrics.backgroundEventCount < 0 ||
        metrics.focusLossCount < 0 ||
        metrics.orientationChangeCount < 0 ||
        metrics.droppedFrameCount < 0) {
      throw ArgumentError('Technical counters must be non-negative');
    }
    final technicalInterruption =
        metrics.completionReason ==
        ObjectLocationCompletionReason.technicalInterruption;
    if (metrics.sessionCompleted == technicalInterruption) {
      throw ArgumentError('Completion reason and session state disagree');
    }

    for (var index = 0; index < levels.length; index++) {
      final metric = levels[index];
      final layout = layouts[index];
      final expectedPhase = index == 0
          ? ObjectLocationPhase.practice
          : ObjectLocationPhase.test;
      if (metric.levelIndex != index ||
          metric.phase != expectedPhase ||
          metric.objectCount != layout.objectCount) {
        throw ArgumentError('Invalid object-location level sequence');
      }
      if (!metric.completed && index != levels.length - 1) {
        throw ArgumentError('Only the final level may be incomplete');
      }
      if (metric.actualEncodingDurationMs < 0 ||
          metric.actualRetentionDurationMs < 0 ||
          metric.actualRecallDurationMs < 0 ||
          metric.actualEncodingDurationMs >
              ObjectLocationConfig.encodingDurationMs(metric.objectCount) +
                  ObjectLocationConfig.technicalRecallGraceMs ||
          metric.actualRetentionDurationMs >
              ObjectLocationConfig.retentionDurationMs +
                  ObjectLocationConfig.technicalRecallGraceMs ||
          metric.actualRecallDurationMs >
              ObjectLocationConfig.recallDurationMs(metric.objectCount) +
                  ObjectLocationConfig.technicalRecallGraceMs) {
        throw ArgumentError('Level duration is outside protocol bounds');
      }
      if (metric.timedOut && !metric.completed) {
        throw ArgumentError('A timeout must complete its level');
      }
      if (metric.actions.length > ObjectLocationConfig.maxActionsPerLevel) {
        throw ArgumentError('Too many placement actions');
      }

      var previousTimestamp = -1;
      for (
        var actionIndex = 0;
        actionIndex < metric.actions.length;
        actionIndex++
      ) {
        final action = metric.actions[actionIndex];
        if (action.actionIndex != actionIndex + 1 ||
            action.timestampMs < 0 ||
            action.timestampMs < previousTimestamp ||
            action.timestampMs > metric.actualRecallDurationMs ||
            action.objectId.isEmpty ||
            action.objectId.length > 48 ||
            !layout.originalCells.containsKey(action.objectId)) {
          throw ArgumentError('Invalid placement action at ${actionIndex + 1}');
        }
        if (action.actionType == ObjectLocationActionType.place) {
          final cell = action.targetCellIndex;
          if (cell == null ||
              cell < 0 ||
              cell >= ObjectLocationConfig.cellCount) {
            throw ArgumentError('Place action requires a grid cell');
          }
        } else if (action.targetCellIndex != null) {
          throw ArgumentError('Return action cannot target a cell');
        }
        previousTimestamp = action.timestampMs;
      }

      if (metric.completed && !metric.timedOut) {
        final placedObjects = _replayPlacedObjects(metric);
        if (placedObjects.length != metric.objectCount) {
          throw ArgumentError(
            'A validated non-timeout level requires every object placed',
          );
        }
      }
    }
  }

  Set<String> _replayPlacedObjects(ObjectLocationLevelMetric metric) {
    final placed = <String, int>{};
    final occupancy = <int, String>{};
    for (final action in metric.actions) {
      final previous = placed.remove(action.objectId);
      if (previous != null) occupancy.remove(previous);
      if (action.actionType == ObjectLocationActionType.returnToReserve) {
        continue;
      }
      final target = action.targetCellIndex!;
      final displaced = occupancy.remove(target);
      if (displaced != null) placed.remove(displaced);
      placed[action.objectId] = target;
      occupancy[target] = action.objectId;
    }
    return placed.keys.toSet();
  }

  bool _timingMatches(ObjectLocationLevelMetric metric) {
    if (!metric.completed) return false;
    final expectedEncoding = ObjectLocationConfig.encodingDurationMs(
      metric.objectCount,
    );
    if ((metric.actualEncodingDurationMs - expectedEncoding).abs() >
            ObjectLocationConfig.technicalTimingToleranceMs ||
        (metric.actualRetentionDurationMs -
                    ObjectLocationConfig.retentionDurationMs)
                .abs() >
            ObjectLocationConfig.technicalTimingToleranceMs) {
      return false;
    }
    final limit = ObjectLocationConfig.recallDurationMs(metric.objectCount);
    if (metric.timedOut) {
      return (metric.actualRecallDurationMs - limit).abs() <=
          ObjectLocationConfig.technicalRecallGraceMs;
    }
    return metric.actualRecallDurationMs >=
            metric.objectCount *
                ObjectLocationConfig.minimumRecallPerObjectMs &&
        metric.actualRecallDurationMs <=
            limit + ObjectLocationConfig.technicalRecallGraceMs;
  }

  bool _progressionValid(
    ObjectLocationMetrics metrics,
    List<ObjectLocationLevelIndicators> tests,
  ) {
    for (
      var index = ObjectLocationConfig.minimumValidMeasuredLevels - 1;
      index < tests.length - 1;
      index++
    ) {
      if (!tests[index].passed && !tests[index - 1].passed) return false;
    }
    if (metrics.completionReason ==
        ObjectLocationCompletionReason.technicalInterruption) {
      return true;
    }
    final allProvidedTestsCompleted = metrics.objectLocationLevels
        .where((level) => level.phase == ObjectLocationPhase.test)
        .every((level) => level.completed);
    if (!allProvidedTestsCompleted) return false;
    if (metrics.completionReason == ObjectLocationCompletionReason.maxLevels) {
      return tests.length == ObjectLocationConfig.measuredObjectCounts.length;
    }
    if (tests.length < ObjectLocationConfig.minimumValidMeasuredLevels ||
        tests.length < 2 ||
        tests.length >= ObjectLocationConfig.measuredObjectCounts.length) {
      return false;
    }
    return !tests[tests.length - 1].passed && !tests[tests.length - 2].passed;
  }

  int _sum(
    List<ObjectLocationLevelIndicators> values,
    int Function(ObjectLocationLevelIndicators) select,
  ) => values.fold(0, (sum, value) => sum + select(value));

  double _percent(int numerator, int denominator) =>
      denominator == 0 ? 0 : numerator * 100.0 / denominator;

  int _roundHalfUp(int numerator, int denominator) => denominator == 0
      ? 0
      : (200 * numerator + denominator) ~/ (2 * denominator);

  double _cellDistance(int origin, int destination) {
    final x =
        origin % ObjectLocationConfig.gridSize -
        destination % ObjectLocationConfig.gridSize;
    final y =
        origin ~/ ObjectLocationConfig.gridSize -
        destination ~/ ObjectLocationConfig.gridSize;
    return math.sqrt(x * x + y * y);
  }

  double? _loadSlope(List<ObjectLocationLevelIndicators> levels) {
    if (levels.length < 2) return null;
    final meanX =
        levels.fold<double>(0, (sum, level) => sum + level.objectCount) /
        levels.length;
    final meanY =
        levels.fold<double>(
          0,
          (sum, level) => sum + level.exactAccuracyPercent,
        ) /
        levels.length;
    var numerator = 0.0;
    var denominator = 0.0;
    for (final level in levels) {
      final dx = level.objectCount - meanX;
      numerator += dx * (level.exactAccuracyPercent - meanY);
      denominator += dx * dx;
    }
    return denominator == 0 ? null : numerator / denominator;
  }

  double? _averageFirstPlacementInterval(
    List<ObjectLocationLevelMetric> levels,
  ) {
    var weighted = 0.0;
    var intervals = 0;
    for (final level in levels) {
      if (level.phase != ObjectLocationPhase.test || !level.completed) continue;
      final seen = <String>{};
      final firstPlacementTimes = <int>[];
      for (final action in level.actions) {
        if (action.actionType == ObjectLocationActionType.place &&
            seen.add(action.objectId)) {
          firstPlacementTimes.add(action.timestampMs);
        }
      }
      for (var index = 1; index < firstPlacementTimes.length; index++) {
        weighted += firstPlacementTimes[index] - firstPlacementTimes[index - 1];
        intervals++;
      }
    }
    return intervals == 0 ? null : weighted / intervals;
  }
}
