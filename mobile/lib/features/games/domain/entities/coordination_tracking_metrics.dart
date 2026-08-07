import '../config/coordination_tracking_config.dart';
import 'game_metrics.dart';

enum CoordinationInputSource {
  mouse('MOUSE'),
  touch('TOUCH'),
  stylus('STYLUS');

  const CoordinationInputSource(this.wire);
  final String wire;

  static CoordinationInputSource fromWire(String value) =>
      CoordinationInputSource.values.firstWhere(
        (source) => source.wire == value,
      );
}

class CoordinationTrackingSample {
  const CoordinationTrackingSample({
    required this.sampleIndex,
    required this.timestampMs,
    required this.pointerPresent,
    required this.pointerX,
    required this.pointerY,
  });

  final int sampleIndex;
  final int timestampMs;
  final bool pointerPresent;
  final int? pointerX;
  final int? pointerY;

  Map<String, dynamic> toJson() => {
    'sampleIndex': sampleIndex,
    'timestampMs': timestampMs,
    'pointerPresent': pointerPresent,
    'pointerX': pointerX,
    'pointerY': pointerY,
  };
}

class CoordinationSegmentMetric {
  CoordinationSegmentMetric({
    required this.phase,
    required this.segmentIndex,
    required this.speed,
    required this.nominalDurationMs,
    required this.actualStartMs,
    required this.actualEndMs,
    required List<CoordinationTrackingSample> samples,
  }) : samples = List.unmodifiable(samples);

  final CoordinationTrackingPhase phase;
  final int segmentIndex;
  final CoordinationTrackingSpeed speed;
  final int nominalDurationMs;
  final int actualStartMs;
  final int actualEndMs;
  final List<CoordinationTrackingSample> samples;

  Map<String, dynamic> toJson() => {
    'phase': phase.wire,
    'segmentIndex': segmentIndex,
    'speed': speed.wire,
    'nominalDurationMs': nominalDurationMs,
    'actualStartMs': actualStartMs,
    'actualEndMs': actualEndMs,
    'samples': samples.map((sample) => sample.toJson()).toList(),
  };
}

/// Exact contract payload. Practice segments are persisted for audit and are
/// excluded from every score calculation.
class CoordinationTrackingMetrics extends GameMetrics {
  CoordinationTrackingMetrics({
    required this.inputSource,
    required List<CoordinationSegmentMetric> coordinationSegments,
    required this.sessionCompleted,
    required this.interrupted,
    required this.backgroundEventCount,
    required this.droppedFrameCount,
    this.protocolVersion = CoordinationTrackingConfig.protocolVersion,
  }) : coordinationSegments = List.unmodifiable(coordinationSegments);

  final String protocolVersion;
  final CoordinationInputSource inputSource;
  final List<CoordinationSegmentMetric> coordinationSegments;
  final bool sessionCompleted;
  final bool interrupted;
  final int backgroundEventCount;
  final int droppedFrameCount;

  @override
  Map<String, dynamic> toJson() => {
    'protocolVersion': protocolVersion,
    'inputSource': inputSource.wire,
    'coordinationSegments': coordinationSegments
        .map((segment) => segment.toJson())
        .toList(),
    'sessionCompleted': sessionCompleted,
    'interrupted': interrupted,
    'backgroundEventCount': backgroundEventCount,
    'droppedFrameCount': droppedFrameCount,
  };
}

class CoordinationTrackingIndicators {
  CoordinationTrackingIndicators({
    required this.protocolVersion,
    required this.inputSource,
    required this.completed,
    required this.sessionValid,
    required this.interrupted,
    required this.provisionalAccuracyScore,
    required this.overallAccuracyPercent,
    required this.fastAccuracyPercent,
    required this.slowAccuracyPercent,
    required this.longSegmentAccuracyPercent,
    required this.shortSegmentAccuracyPercent,
    required this.averageCenterDistance,
    required this.testExecutionTimeMs,
    required this.accuracyValid,
    required this.executionTimeValid,
    required this.taskValid,
    required this.technicalValid,
    required this.sampleCount,
    required this.absentSampleCount,
    required this.backgroundEventCount,
    required this.droppedFrameCount,
    required this.timingDeviationCount,
    required this.samplingGapCount,
    required List<String> validityIssues,
  }) : validityIssues = List.unmodifiable(validityIssues);

  final String protocolVersion;
  final CoordinationInputSource inputSource;
  final bool completed;
  final bool sessionValid;
  final bool interrupted;
  final int provisionalAccuracyScore;
  final double overallAccuracyPercent;
  final double fastAccuracyPercent;
  final double slowAccuracyPercent;
  final double longSegmentAccuracyPercent;
  final double shortSegmentAccuracyPercent;
  final double averageCenterDistance;
  final int testExecutionTimeMs;
  final bool accuracyValid;
  final bool executionTimeValid;
  final bool taskValid;
  final bool technicalValid;
  final int sampleCount;
  final int absentSampleCount;
  final int backgroundEventCount;
  final int droppedFrameCount;
  final int timingDeviationCount;
  final int samplingGapCount;
  final List<String> validityIssues;

  factory CoordinationTrackingIndicators.fromJson(Map<String, dynamic> json) {
    return CoordinationTrackingIndicators(
      protocolVersion: json['protocolVersion'] as String? ?? '',
      inputSource: CoordinationInputSource.fromWire(
        json['inputSource'] as String? ?? 'TOUCH',
      ),
      completed: json['completed'] as bool? ?? false,
      sessionValid: json['sessionValid'] as bool? ?? false,
      interrupted: json['interrupted'] as bool? ?? false,
      provisionalAccuracyScore:
          (json['provisionalAccuracyScore'] as num?)?.toInt() ?? 0,
      overallAccuracyPercent:
          (json['overallAccuracyPercent'] as num?)?.toDouble() ?? 0,
      fastAccuracyPercent:
          (json['fastAccuracyPercent'] as num?)?.toDouble() ?? 0,
      slowAccuracyPercent:
          (json['slowAccuracyPercent'] as num?)?.toDouble() ?? 0,
      longSegmentAccuracyPercent:
          (json['longSegmentAccuracyPercent'] as num?)?.toDouble() ?? 0,
      shortSegmentAccuracyPercent:
          (json['shortSegmentAccuracyPercent'] as num?)?.toDouble() ?? 0,
      averageCenterDistance:
          (json['averageCenterDistance'] as num?)?.toDouble() ?? 0,
      testExecutionTimeMs: (json['testExecutionTimeMs'] as num?)?.toInt() ?? 0,
      accuracyValid: json['accuracyValid'] as bool? ?? false,
      executionTimeValid: json['executionTimeValid'] as bool? ?? false,
      taskValid: json['taskValid'] as bool? ?? false,
      technicalValid: json['technicalValid'] as bool? ?? false,
      sampleCount: (json['sampleCount'] as num?)?.toInt() ?? 0,
      absentSampleCount: (json['absentSampleCount'] as num?)?.toInt() ?? 0,
      backgroundEventCount:
          (json['backgroundEventCount'] as num?)?.toInt() ?? 0,
      droppedFrameCount: (json['droppedFrameCount'] as num?)?.toInt() ?? 0,
      timingDeviationCount:
          (json['timingDeviationCount'] as num?)?.toInt() ?? 0,
      samplingGapCount: (json['samplingGapCount'] as num?)?.toInt() ?? 0,
      validityIssues:
          (json['validityIssues'] as List<dynamic>?)
              ?.map((value) => value as String)
              .toList() ??
          const [],
    );
  }
}
