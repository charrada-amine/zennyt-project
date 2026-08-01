import '../domain/config/coordination_tracking_config.dart';
import '../domain/entities/coordination_tracking_metrics.dart';
import '../domain/entities/game_score.dart';

class CoordinationTrackingScoringResult {
  const CoordinationTrackingScoringResult({
    required this.score,
    required this.indicators,
  });

  final GameScore score;
  final CoordinationTrackingIndicators indicators;
}

/// Exact mock mirror of backend `CoordinationScoringService`.
class CoordinationTrackingScoring {
  const CoordinationTrackingScoring();

  CoordinationTrackingScoringResult score(CoordinationTrackingMetrics metrics) {
    _validate(metrics);
    final overall = _Accumulator();
    final fast = _Accumulator();
    final slow = _Accumulator();
    final longSegments = _Accumulator();
    final shortSegments = _Accumulator();
    var sampleCount = 0;
    var absentSampleCount = 0;
    var timingDeviationCount = 0;
    var samplingGapCount = 0;

    for (var index = 0; index < metrics.coordinationSegments.length; index++) {
      final segment = metrics.coordinationSegments[index];
      final spec = CoordinationTrackingConfig.segments[index];
      if (segment.phase == CoordinationTrackingPhase.test &&
          ((segment.actualStartMs - spec.scheduledStartMs).abs() >
                  CoordinationTrackingConfig.timingToleranceMs ||
              ((segment.actualEndMs - segment.actualStartMs) - spec.durationMs)
                      .abs() >
                  CoordinationTrackingConfig.timingToleranceMs)) {
        timingDeviationCount++;
      }
      samplingGapCount += _samplingGaps(segment);
      if (segment.phase != CoordinationTrackingPhase.test) continue;
      sampleCount += segment.samples.length;
      absentSampleCount += segment.samples
          .where((sample) => !sample.pointerPresent)
          .length;
      _accumulateSegment(
        segment,
        spec,
        overall,
        segment.speed == CoordinationTrackingSpeed.fast ? fast : slow,
        spec.isLong ? longSegments : shortSegments,
      );
    }

    final accuracy = overall.accuracyPercent;
    final accuracyValid = accuracy.isFinite && accuracy >= 0 && accuracy <= 100;
    final firstTest = metrics
        .coordinationSegments[CoordinationTrackingConfig.practiceSegmentCount];
    final last = metrics.coordinationSegments.last;
    final testExecutionTimeMs = last.actualEndMs - firstTest.actualStartMs;
    final executionTimeValid =
        testExecutionTimeMs >=
            CoordinationTrackingConfig.validTestDurationMinMs &&
        testExecutionTimeMs <=
            CoordinationTrackingConfig.validTestDurationMaxMs;
    final taskValid = accuracyValid && executionTimeValid;
    final technicalValid =
        metrics.sessionCompleted &&
        !metrics.interrupted &&
        metrics.backgroundEventCount == 0 &&
        timingDeviationCount == 0;
    final sessionValid = taskValid && technicalValid;
    final issues = <String>[
      if (!metrics.sessionCompleted) 'SESSION_INCOMPLETE',
      if (metrics.interrupted) 'INTERRUPTED',
      if (metrics.backgroundEventCount > 0) 'BACKGROUND_EVENT',
      if (timingDeviationCount > 0) 'TIMING_DEVIATION',
      if (!accuracyValid) 'ACCURACY_OUT_OF_RANGE',
      if (!executionTimeValid) 'EXECUTION_TIME_OUT_OF_RANGE',
    ];
    final points = _roundHalfUp(
      overall.insideDurationMs,
      overall.totalDurationMs,
    );
    final score = GameScore(
      rawPoints: points,
      maxPoints: 100,
      normalized: points.toDouble(),
      level: 'Descriptive — provisional',
    );
    return CoordinationTrackingScoringResult(
      score: score,
      indicators: CoordinationTrackingIndicators(
        protocolVersion: metrics.protocolVersion,
        inputSource: metrics.inputSource,
        completed: metrics.sessionCompleted,
        sessionValid: sessionValid,
        interrupted: metrics.interrupted,
        provisionalAccuracyScore: points,
        overallAccuracyPercent: accuracy,
        fastAccuracyPercent: fast.accuracyPercent,
        slowAccuracyPercent: slow.accuracyPercent,
        longSegmentAccuracyPercent: longSegments.accuracyPercent,
        shortSegmentAccuracyPercent: shortSegments.accuracyPercent,
        averageCenterDistance: overall.averageDistance,
        testExecutionTimeMs: testExecutionTimeMs,
        accuracyValid: accuracyValid,
        executionTimeValid: executionTimeValid,
        taskValid: taskValid,
        technicalValid: technicalValid,
        sampleCount: sampleCount,
        absentSampleCount: absentSampleCount,
        backgroundEventCount: metrics.backgroundEventCount,
        droppedFrameCount: metrics.droppedFrameCount,
        timingDeviationCount: timingDeviationCount,
        samplingGapCount: samplingGapCount,
        validityIssues: issues,
      ),
    );
  }

  void _validate(CoordinationTrackingMetrics metrics) {
    if (metrics.protocolVersion != CoordinationTrackingConfig.protocolVersion) {
      throw ArgumentError('Unsupported coordination protocol');
    }
    if (metrics.coordinationSegments.length !=
        CoordinationTrackingConfig.totalSegmentCount) {
      throw ArgumentError('The protocol requires exactly 14 segments');
    }
    var previousEnd = 0;
    for (var index = 0; index < metrics.coordinationSegments.length; index++) {
      final segment = metrics.coordinationSegments[index];
      final spec = CoordinationTrackingConfig.segments[index];
      if (segment.segmentIndex != spec.index ||
          segment.phase != spec.phase ||
          segment.speed != spec.speed ||
          segment.nominalDurationMs != spec.durationMs) {
        throw ArgumentError('Invalid segment sequence at ${index + 1}');
      }
      if (segment.actualStartMs != previousEnd ||
          segment.actualEndMs <= segment.actualStartMs ||
          segment.samples.length < 2 ||
          segment.samples.length >
              CoordinationTrackingConfig.maxSamplesPerSegment) {
        throw ArgumentError('Invalid segment timeline at ${index + 1}');
      }
      var previousTimestamp = -1;
      for (
        var sampleIndex = 0;
        sampleIndex < segment.samples.length;
        sampleIndex++
      ) {
        final sample = segment.samples[sampleIndex];
        if (sample.sampleIndex != sampleIndex + 1 ||
            sample.timestampMs < segment.actualStartMs ||
            sample.timestampMs >= segment.actualEndMs ||
            sample.timestampMs <= previousTimestamp) {
          throw ArgumentError('Invalid sample timeline at ${index + 1}');
        }
        if (sample.pointerPresent) {
          if (sample.pointerX == null ||
              sample.pointerY == null ||
              sample.pointerX! < 0 ||
              sample.pointerX! > CoordinationTrackingConfig.coordinateScale ||
              sample.pointerY! < 0 ||
              sample.pointerY! > CoordinationTrackingConfig.coordinateScale) {
            throw ArgumentError(
              'Present pointer must have fixed-point coordinates',
            );
          }
        } else if (sample.pointerX != null || sample.pointerY != null) {
          throw ArgumentError('Absent pointer coordinates must be null');
        }
        previousTimestamp = sample.timestampMs;
      }
      previousEnd = segment.actualEndMs;
    }
    final activation = metrics.coordinationSegments.first.samples.first;
    final dx =
        (activation.pointerX ?? 1 << 30) -
        CoordinationTrackingConfig.trackInsetUnits;
    final dy =
        (activation.pointerY ?? 1 << 30) -
        CoordinationTrackingConfig.trackInsetUnits;
    if (metrics.coordinationSegments.first.actualStartMs != 0 ||
        activation.timestampMs != 0 ||
        !activation.pointerPresent ||
        dx * dx + dy * dy >
            CoordinationTrackingConfig.activationRadiusUnits *
                CoordinationTrackingConfig.activationRadiusUnits) {
      throw ArgumentError('The first sample must activate the initial target');
    }
  }

  void _accumulateSegment(
    CoordinationSegmentMetric segment,
    CoordinationSegmentSpec spec,
    _Accumulator overall,
    _Accumulator bySpeed,
    _Accumulator byDuration,
  ) {
    final windowStart = spec.scheduledStartMs;
    final windowEnd = spec.scheduledEndMs;
    var cursor = windowStart;
    CoordinationTrackingSample? active;
    for (final sample in segment.samples) {
      if (sample.timestampMs < windowStart) {
        active = sample;
        continue;
      }
      if (sample.timestampMs >= windowEnd) break;
      if (sample.timestampMs > cursor) {
        _addInterval(cursor, sample.timestampMs, active, [
          overall,
          bySpeed,
          byDuration,
        ]);
      }
      active = sample;
      cursor = sample.timestampMs;
    }
    if (cursor < windowEnd) {
      _addInterval(cursor, windowEnd, active, [overall, bySpeed, byDuration]);
    }
  }

  void _addInterval(
    int startMs,
    int endMs,
    CoordinationTrackingSample? pointer,
    List<_Accumulator> accumulators,
  ) {
    if (endMs <= startMs) return;
    // Exact mirror of the server 1 ms grid. Sparse samples hold the pointer,
    // never the moving target, so they cannot manufacture perfect tracking.
    for (var timestampMs = startMs; timestampMs < endMs; timestampMs++) {
      final target = CoordinationTrackingConfig.targetUnitsAtMs(timestampMs);
      final dx = (pointer?.pointerX ?? target.x + 2000000) - target.x;
      final dy = (pointer?.pointerY ?? target.y + 2000000) - target.y;
      final present = pointer?.pointerPresent ?? false;
      final inside =
          present &&
          dx * dx + dy * dy <=
              CoordinationTrackingConfig.ballRadiusUnits *
                  CoordinationTrackingConfig.ballRadiusUnits;
      final distance = present
          ? CoordinationTrackingConfig.canonicalDistanceUnits(
              pointerX: pointer!.pointerX,
              pointerY: pointer.pointerY,
              target: target,
            )
          : CoordinationTrackingConfig.canonicalMaxDistance;
      for (final accumulator in accumulators) {
        accumulator.add(1, inside, distance);
      }
    }
  }

  int _samplingGaps(CoordinationSegmentMetric segment) {
    var gaps = 0;
    var previous = segment.actualStartMs;
    for (final sample in segment.samples) {
      if (sample.timestampMs - previous >
          CoordinationTrackingConfig.maxSampleGapMs) {
        gaps++;
      }
      previous = sample.timestampMs;
    }
    if (segment.actualEndMs - previous >
        CoordinationTrackingConfig.maxSampleGapMs) {
      gaps++;
    }
    return gaps;
  }

  /// PROVISOIRE — non validé par le psychologue; exact integer half-up mirror.
  int _roundHalfUp(int insideDurationMs, int totalDurationMs) {
    if (totalDurationMs <= 0 ||
        insideDurationMs < 0 ||
        insideDurationMs > totalDurationMs) {
      throw ArgumentError('Invalid accuracy durations');
    }
    final numerator = insideDurationMs * 100;
    return (2 * numerator + totalDurationMs) ~/ (2 * totalDurationMs);
  }
}

class _Accumulator {
  int totalDurationMs = 0;
  int insideDurationMs = 0;
  double weightedDistance = 0;

  void add(int durationMs, bool inside, double distance) {
    totalDurationMs += durationMs;
    if (inside) insideDurationMs += durationMs;
    weightedDistance += distance * durationMs;
  }

  double get accuracyPercent =>
      totalDurationMs == 0 ? 0 : insideDurationMs * 100.0 / totalDurationMs;

  double get averageDistance =>
      totalDurationMs == 0 ? 0 : weightedDistance / totalDurationMs;
}
