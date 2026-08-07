import '../config/object_location_config.dart';
import 'game_metrics.dart';

enum ObjectLocationPhase {
  practice('PRACTICE'),
  test('TEST');

  const ObjectLocationPhase(this.wire);
  final String wire;

  static ObjectLocationPhase fromWire(String value) =>
      ObjectLocationPhase.values.firstWhere((phase) => phase.wire == value);
}

enum ObjectLocationCompletionReason {
  maxLevels('MAX_LEVELS'),
  stopRule('STOP_RULE'),
  technicalInterruption('TECHNICAL_INTERRUPTION');

  const ObjectLocationCompletionReason(this.wire);
  final String wire;

  static ObjectLocationCompletionReason fromWire(String value) =>
      ObjectLocationCompletionReason.values.firstWhere(
        (reason) => reason.wire == value,
      );
}

enum ObjectLocationActionType {
  place('PLACE'),
  returnToReserve('RETURN_TO_RESERVE');

  const ObjectLocationActionType(this.wire);
  final String wire;
}

/// Raw player manipulation. Original cells and correctness stay server-only.
class ObjectLocationPlacementAction {
  const ObjectLocationPlacementAction({
    required this.actionIndex,
    required this.actionType,
    required this.objectId,
    required this.targetCellIndex,
    required this.timestampMs,
  });

  final int actionIndex;
  final ObjectLocationActionType actionType;
  final String objectId;
  final int? targetCellIndex;
  final int timestampMs;

  Map<String, dynamic> toJson() => {
    'actionIndex': actionIndex,
    'actionType': actionType.wire,
    'objectId': objectId,
    'targetCellIndex': targetCellIndex,
    'timestampMs': timestampMs,
  };
}

/// One administered level, including practice for protocol audit.
class ObjectLocationLevelMetric {
  ObjectLocationLevelMetric({
    required this.phase,
    required this.levelIndex,
    required this.objectCount,
    required this.actualEncodingDurationMs,
    required this.actualRetentionDurationMs,
    required this.actualRecallDurationMs,
    required this.timedOut,
    required this.completed,
    required List<ObjectLocationPlacementAction> actions,
  }) : actions = List.unmodifiable(actions);

  final ObjectLocationPhase phase;
  final int levelIndex;
  final int objectCount;
  final int actualEncodingDurationMs;
  final int actualRetentionDurationMs;
  final int actualRecallDurationMs;
  final bool timedOut;
  final bool completed;
  final List<ObjectLocationPlacementAction> actions;

  Map<String, dynamic> toJson() => {
    'phase': phase.wire,
    'levelIndex': levelIndex,
    'objectCount': objectCount,
    'actualEncodingDurationMs': actualEncodingDurationMs,
    'actualRetentionDurationMs': actualRetentionDurationMs,
    'actualRecallDurationMs': actualRecallDurationMs,
    'timedOut': timedOut,
    'completed': completed,
    'actions': actions.map((action) => action.toJson()).toList(),
  };
}

/// Contract-first raw metrics for « Je place ».
///
/// The backend reconstructs the deterministic layout and derives every score
/// and indicator. This payload deliberately contains no original position,
/// correctness, distance or client-computed score.
class ObjectLocationMetrics extends GameMetrics {
  ObjectLocationMetrics({
    required this.completionReason,
    required List<ObjectLocationLevelMetric> objectLocationLevels,
    required this.sessionCompleted,
    required this.interrupted,
    required this.backgroundEventCount,
    required this.focusLossCount,
    required this.orientationChangeCount,
    required this.droppedFrameCount,
    this.protocolVersion = ObjectLocationConfig.protocolVersion,
  }) : objectLocationLevels = List.unmodifiable(objectLocationLevels);

  final String protocolVersion;
  final ObjectLocationCompletionReason completionReason;
  final List<ObjectLocationLevelMetric> objectLocationLevels;
  final bool sessionCompleted;
  final bool interrupted;
  final int backgroundEventCount;
  final int focusLossCount;
  final int orientationChangeCount;
  final int droppedFrameCount;

  @override
  Map<String, dynamic> toJson() => {
    'protocolVersion': protocolVersion,
    'completionReason': completionReason.wire,
    'objectLocationLevels': objectLocationLevels
        .map((level) => level.toJson())
        .toList(),
    'sessionCompleted': sessionCompleted,
    'interrupted': interrupted,
    'backgroundEventCount': backgroundEventCount,
    'focusLossCount': focusLossCount,
    'orientationChangeCount': orientationChangeCount,
    'droppedFrameCount': droppedFrameCount,
  };
}

class ObjectLocationLevelIndicators {
  const ObjectLocationLevelIndicators({
    required this.phase,
    required this.levelIndex,
    required this.objectCount,
    required this.completed,
    required this.timedOut,
    required this.passed,
    required this.exactCount,
    required this.swapCount,
    required this.localErrorCount,
    required this.globalErrorCount,
    required this.unplacedCount,
    required this.exactAccuracyPercent,
    required this.averageDisplacementCells,
    required this.recallDurationMs,
    required this.actionCount,
    required this.repositionCount,
    this.averageFirstPlacementIntervalMs,
  });

  final ObjectLocationPhase phase;
  final int levelIndex;
  final int objectCount;
  final bool completed;
  final bool timedOut;
  final bool passed;
  final int exactCount;
  final int swapCount;
  final int localErrorCount;
  final int globalErrorCount;
  final int unplacedCount;
  final double exactAccuracyPercent;
  final double averageDisplacementCells;
  final int recallDurationMs;
  final int actionCount;
  final int repositionCount;
  final double? averageFirstPlacementIntervalMs;

  factory ObjectLocationLevelIndicators.fromJson(Map<String, dynamic> json) {
    return ObjectLocationLevelIndicators(
      phase: ObjectLocationPhase.fromWire(json['phase'] as String),
      levelIndex: (json['levelIndex'] as num).toInt(),
      objectCount: (json['objectCount'] as num).toInt(),
      completed: json['completed'] as bool? ?? false,
      timedOut: json['timedOut'] as bool? ?? false,
      passed: json['passed'] as bool? ?? false,
      exactCount: (json['exactCount'] as num?)?.toInt() ?? 0,
      swapCount: (json['swapCount'] as num?)?.toInt() ?? 0,
      localErrorCount: (json['localErrorCount'] as num?)?.toInt() ?? 0,
      globalErrorCount: (json['globalErrorCount'] as num?)?.toInt() ?? 0,
      unplacedCount: (json['unplacedCount'] as num?)?.toInt() ?? 0,
      exactAccuracyPercent:
          (json['exactAccuracyPercent'] as num?)?.toDouble() ?? 0,
      averageDisplacementCells:
          (json['averageDisplacementCells'] as num?)?.toDouble() ?? 0,
      recallDurationMs: (json['recallDurationMs'] as num?)?.toInt() ?? 0,
      actionCount: (json['actionCount'] as num?)?.toInt() ?? 0,
      repositionCount: (json['repositionCount'] as num?)?.toInt() ?? 0,
      averageFirstPlacementIntervalMs:
          (json['averageFirstPlacementIntervalMs'] as num?)?.toDouble(),
    );
  }
}

/// Descriptive report calculated by the backend after replaying raw actions.
class ObjectLocationIndicators {
  ObjectLocationIndicators({
    required this.protocolVersion,
    required this.completionReason,
    required this.completed,
    required this.sessionValid,
    required this.technicalValid,
    required this.minimumLevelsValid,
    required this.progressionValid,
    required this.timingValid,
    required this.provisionalAccuracyScore,
    required this.completedLevelCount,
    required this.passedLevelCount,
    required this.administeredObjectCount,
    required this.exactPlacementCount,
    required this.swapCount,
    required this.localErrorCount,
    required this.globalErrorCount,
    required this.unplacedCount,
    required this.exactAccuracyPercent,
    required this.swapRatePercent,
    required this.localErrorRatePercent,
    required this.globalErrorRatePercent,
    required this.averageDisplacementCells,
    required this.span,
    required this.loadSlope,
    required this.averageFirstPlacementIntervalMs,
    required this.repositionCount,
    required this.backgroundEventCount,
    required this.focusLossCount,
    required this.orientationChangeCount,
    required this.droppedFrameCount,
    required this.timingDeviationCount,
    required List<ObjectLocationLevelIndicators> levels,
    required List<String> validityIssues,
  }) : levels = List.unmodifiable(levels),
       validityIssues = List.unmodifiable(validityIssues);

  final String protocolVersion;
  final ObjectLocationCompletionReason completionReason;
  final bool completed;
  final bool sessionValid;
  final bool technicalValid;
  final bool minimumLevelsValid;
  final bool progressionValid;
  final bool timingValid;
  final int provisionalAccuracyScore;
  final int completedLevelCount;
  final int passedLevelCount;
  final int administeredObjectCount;
  final int exactPlacementCount;
  final int swapCount;
  final int localErrorCount;
  final int globalErrorCount;
  final int unplacedCount;
  final double exactAccuracyPercent;
  final double swapRatePercent;
  final double localErrorRatePercent;
  final double globalErrorRatePercent;
  final double averageDisplacementCells;
  final int span;
  final double? loadSlope;
  final double? averageFirstPlacementIntervalMs;
  final int repositionCount;
  final int backgroundEventCount;
  final int focusLossCount;
  final int orientationChangeCount;
  final int droppedFrameCount;
  final int timingDeviationCount;
  final List<ObjectLocationLevelIndicators> levels;
  final List<String> validityIssues;

  factory ObjectLocationIndicators.fromJson(Map<String, dynamic> json) {
    return ObjectLocationIndicators(
      protocolVersion: json['protocolVersion'] as String? ?? '',
      completionReason: ObjectLocationCompletionReason.fromWire(
        json['completionReason'] as String,
      ),
      completed: json['completed'] as bool? ?? false,
      sessionValid: json['sessionValid'] as bool? ?? false,
      technicalValid: json['technicalValid'] as bool? ?? false,
      minimumLevelsValid: json['minimumLevelsValid'] as bool? ?? false,
      progressionValid: json['progressionValid'] as bool? ?? false,
      timingValid: json['timingValid'] as bool? ?? false,
      provisionalAccuracyScore:
          (json['provisionalAccuracyScore'] as num?)?.toInt() ?? 0,
      completedLevelCount: (json['completedLevelCount'] as num?)?.toInt() ?? 0,
      passedLevelCount: (json['passedLevelCount'] as num?)?.toInt() ?? 0,
      administeredObjectCount:
          (json['administeredObjectCount'] as num?)?.toInt() ?? 0,
      exactPlacementCount: (json['exactPlacementCount'] as num?)?.toInt() ?? 0,
      swapCount: (json['swapCount'] as num?)?.toInt() ?? 0,
      localErrorCount: (json['localErrorCount'] as num?)?.toInt() ?? 0,
      globalErrorCount: (json['globalErrorCount'] as num?)?.toInt() ?? 0,
      unplacedCount: (json['unplacedCount'] as num?)?.toInt() ?? 0,
      exactAccuracyPercent:
          (json['exactAccuracyPercent'] as num?)?.toDouble() ?? 0,
      swapRatePercent: (json['swapRatePercent'] as num?)?.toDouble() ?? 0,
      localErrorRatePercent:
          (json['localErrorRatePercent'] as num?)?.toDouble() ?? 0,
      globalErrorRatePercent:
          (json['globalErrorRatePercent'] as num?)?.toDouble() ?? 0,
      averageDisplacementCells:
          (json['averageDisplacementCells'] as num?)?.toDouble() ?? 0,
      span: (json['span'] as num?)?.toInt() ?? 0,
      loadSlope: (json['loadSlope'] as num?)?.toDouble(),
      averageFirstPlacementIntervalMs:
          (json['averageFirstPlacementIntervalMs'] as num?)?.toDouble(),
      repositionCount: (json['repositionCount'] as num?)?.toInt() ?? 0,
      backgroundEventCount:
          (json['backgroundEventCount'] as num?)?.toInt() ?? 0,
      focusLossCount: (json['focusLossCount'] as num?)?.toInt() ?? 0,
      orientationChangeCount:
          (json['orientationChangeCount'] as num?)?.toInt() ?? 0,
      droppedFrameCount: (json['droppedFrameCount'] as num?)?.toInt() ?? 0,
      timingDeviationCount:
          (json['timingDeviationCount'] as num?)?.toInt() ?? 0,
      levels:
          (json['levels'] as List<dynamic>?)
              ?.map(
                (value) => ObjectLocationLevelIndicators.fromJson(
                  value as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
      validityIssues:
          (json['validityIssues'] as List<dynamic>?)
              ?.map((value) => value as String)
              .toList() ??
          const [],
    );
  }
}
