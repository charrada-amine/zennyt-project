import 'dart:math' as math;

enum CoordinationTrackingPhase {
  practice('PRACTICE'),
  test('TEST');

  const CoordinationTrackingPhase(this.wire);
  final String wire;
}

enum CoordinationTrackingSpeed {
  slow('SLOW'),
  fast('FAST');

  const CoordinationTrackingSpeed(this.wire);
  final String wire;
}

class CoordinationPoint {
  const CoordinationPoint(this.x, this.y);

  final double x;
  final double y;

  double distanceTo(CoordinationPoint other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }
}

class CoordinationFixedPoint {
  const CoordinationFixedPoint(this.x, this.y);

  final int x;
  final int y;

  CoordinationPoint get normalized => CoordinationPoint(
    x / CoordinationTrackingConfig.coordinateScale,
    y / CoordinationTrackingConfig.coordinateScale,
  );
}

class CoordinationSegmentSpec {
  const CoordinationSegmentSpec({
    required this.index,
    required this.phase,
    required this.durationMs,
    required this.speed,
    required this.scheduledStartMs,
  });

  final int index;
  final CoordinationTrackingPhase phase;
  final int durationMs;
  final CoordinationTrackingSpeed speed;
  final int scheduledStartMs;

  int get scheduledEndMs => scheduledStartMs + durationMs;
  bool get isLong => durationMs == CoordinationTrackingConfig.longSegmentMs;
}

/// Contractual protocol for « Je coordonne ».
///
/// PROVISOIRE — non validé par le psychologue. This speed/geometry/distance
/// block is the exact Dart mirror of backend `CoordinationConfig` and
/// `CoordinationTrajectoryService`; change both sides in the same PR.
class CoordinationTrackingConfig {
  const CoordinationTrackingConfig._();

  static const protocolVersion = 'FIXED_SQUARE_CW_V1';
  static const coordinateScale = 1000000;
  static const trackInsetUnits = 160000;
  static const traceInsetRatio = trackInsetUnits / coordinateScale;
  static const trackSideUnits = coordinateScale - 2 * trackInsetUnits;
  static const trackPerimeterUnits = 4 * trackSideUnits;
  static const ballRadiusUnits = 75000;
  static const targetRadiusRatio = ballRadiusUnits / coordinateScale;
  static const activationRadiusUnits = ballRadiusUnits ~/ 2;
  static const canonicalMaxDistance = 1200.0;

  static const slowLapMs = 7000;
  static const fastLapMs = 3500;
  static const longSegmentMs = 7000;
  static const shortSegmentMs = 2333;
  static const practiceSegmentCount = 2;
  static const testSegmentCount = 12;
  static const totalSegmentCount = 14;
  static const practiceDurationMs = 14000;
  static const testDurationMs = 55998;
  static const totalDurationMs = 69998;
  static const validTestDurationMinMs = 54000;
  static const validTestDurationMaxMs = 58000;
  static const timingToleranceMs = 100;
  static const maxSampleGapMs = 100;
  static const maxSamplesPerSegment = 2000;

  static const segments = <CoordinationSegmentSpec>[
    CoordinationSegmentSpec(
      index: 1,
      phase: CoordinationTrackingPhase.practice,
      durationMs: longSegmentMs,
      speed: CoordinationTrackingSpeed.slow,
      scheduledStartMs: 0,
    ),
    CoordinationSegmentSpec(
      index: 2,
      phase: CoordinationTrackingPhase.practice,
      durationMs: longSegmentMs,
      speed: CoordinationTrackingSpeed.fast,
      scheduledStartMs: 7000,
    ),
    CoordinationSegmentSpec(
      index: 3,
      phase: CoordinationTrackingPhase.test,
      durationMs: longSegmentMs,
      speed: CoordinationTrackingSpeed.slow,
      scheduledStartMs: 14000,
    ),
    CoordinationSegmentSpec(
      index: 4,
      phase: CoordinationTrackingPhase.test,
      durationMs: longSegmentMs,
      speed: CoordinationTrackingSpeed.fast,
      scheduledStartMs: 21000,
    ),
    CoordinationSegmentSpec(
      index: 5,
      phase: CoordinationTrackingPhase.test,
      durationMs: shortSegmentMs,
      speed: CoordinationTrackingSpeed.slow,
      scheduledStartMs: 28000,
    ),
    CoordinationSegmentSpec(
      index: 6,
      phase: CoordinationTrackingPhase.test,
      durationMs: shortSegmentMs,
      speed: CoordinationTrackingSpeed.fast,
      scheduledStartMs: 30333,
    ),
    CoordinationSegmentSpec(
      index: 7,
      phase: CoordinationTrackingPhase.test,
      durationMs: longSegmentMs,
      speed: CoordinationTrackingSpeed.slow,
      scheduledStartMs: 32666,
    ),
    CoordinationSegmentSpec(
      index: 8,
      phase: CoordinationTrackingPhase.test,
      durationMs: longSegmentMs,
      speed: CoordinationTrackingSpeed.fast,
      scheduledStartMs: 39666,
    ),
    CoordinationSegmentSpec(
      index: 9,
      phase: CoordinationTrackingPhase.test,
      durationMs: shortSegmentMs,
      speed: CoordinationTrackingSpeed.slow,
      scheduledStartMs: 46666,
    ),
    CoordinationSegmentSpec(
      index: 10,
      phase: CoordinationTrackingPhase.test,
      durationMs: shortSegmentMs,
      speed: CoordinationTrackingSpeed.fast,
      scheduledStartMs: 48999,
    ),
    CoordinationSegmentSpec(
      index: 11,
      phase: CoordinationTrackingPhase.test,
      durationMs: longSegmentMs,
      speed: CoordinationTrackingSpeed.slow,
      scheduledStartMs: 51332,
    ),
    CoordinationSegmentSpec(
      index: 12,
      phase: CoordinationTrackingPhase.test,
      durationMs: longSegmentMs,
      speed: CoordinationTrackingSpeed.fast,
      scheduledStartMs: 58332,
    ),
    CoordinationSegmentSpec(
      index: 13,
      phase: CoordinationTrackingPhase.test,
      durationMs: shortSegmentMs,
      speed: CoordinationTrackingSpeed.slow,
      scheduledStartMs: 65332,
    ),
    CoordinationSegmentSpec(
      index: 14,
      phase: CoordinationTrackingPhase.test,
      durationMs: shortSegmentMs,
      speed: CoordinationTrackingSpeed.fast,
      scheduledStartMs: 67665,
    ),
  ];

  static CoordinationSegmentSpec segmentAtMs(int timestampMs) {
    final clamped = timestampMs.clamp(0, totalDurationMs);
    for (final segment in segments) {
      if (clamped < segment.scheduledEndMs) return segment;
    }
    return segments.last;
  }

  /// Exact fixed-point trajectory: top-left, clockwise, no easing or jump.
  static CoordinationFixedPoint targetUnitsAtMs(int timestampMs) {
    final clamped = timestampMs.clamp(0, totalDurationMs);
    var equivalentSlowMs = 0;
    for (final segment in segments) {
      if (clamped <= segment.scheduledStartMs) break;
      final elapsed =
          math.min(clamped, segment.scheduledEndMs) - segment.scheduledStartMs;
      equivalentSlowMs +=
          elapsed * (segment.speed == CoordinationTrackingSpeed.slow ? 1 : 2);
      if (clamped < segment.scheduledEndMs) break;
    }
    final distance =
        (equivalentSlowMs * trackPerimeterUnits ~/ slowLapMs) %
        trackPerimeterUnits;
    final edge = distance ~/ trackSideUnits;
    final offset = distance % trackSideUnits;
    return switch (edge) {
      0 => CoordinationFixedPoint(trackInsetUnits + offset, trackInsetUnits),
      1 => CoordinationFixedPoint(
        trackInsetUnits + trackSideUnits,
        trackInsetUnits + offset,
      ),
      2 => CoordinationFixedPoint(
        trackInsetUnits + trackSideUnits - offset,
        trackInsetUnits + trackSideUnits,
      ),
      _ => CoordinationFixedPoint(
        trackInsetUnits,
        trackInsetUnits + trackSideUnits - offset,
      ),
    };
  }

  static CoordinationPoint targetAtMs(int timestampMs) =>
      targetUnitsAtMs(timestampMs).normalized;

  static int normalizedToUnits(double value) =>
      (value.clamp(0, 1) * coordinateScale).round().clamp(0, coordinateScale);

  static double canonicalDistanceUnits({
    required int? pointerX,
    required int? pointerY,
    required CoordinationFixedPoint target,
  }) {
    if (pointerX == null || pointerY == null) return canonicalMaxDistance;
    final dx = pointerX - target.x;
    final dy = pointerY - target.y;
    return (math.sqrt(dx * dx + dy * dy) /
            (coordinateScale * math.sqrt2) *
            canonicalMaxDistance)
        .clamp(0, canonicalMaxDistance)
        .toDouble();
  }
}
