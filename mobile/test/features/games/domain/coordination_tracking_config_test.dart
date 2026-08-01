import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/domain/config/coordination_tracking_config.dart';

void main() {
  test('protocol has 2 practice + 12 measured segments on one timeline', () {
    expect(CoordinationTrackingConfig.protocolVersion, 'FIXED_SQUARE_CW_V1');
    expect(
      CoordinationTrackingConfig.segments,
      hasLength(CoordinationTrackingConfig.totalSegmentCount),
    );
    expect(
      CoordinationTrackingConfig.segments
          .take(2)
          .every(
            (segment) => segment.phase == CoordinationTrackingPhase.practice,
          ),
      isTrue,
    );
    expect(
      CoordinationTrackingConfig.segments
          .skip(2)
          .every((segment) => segment.phase == CoordinationTrackingPhase.test),
      isTrue,
    );
    expect(
      CoordinationTrackingConfig.segments.last.scheduledEndMs,
      CoordinationTrackingConfig.totalDurationMs,
    );
    expect(CoordinationTrackingConfig.testDurationMs, 55998);
  });

  test(
    'practice performs three laps and checkpoint keeps the same position',
    () {
      final initial = CoordinationTrackingConfig.targetUnitsAtMs(0);
      final checkpoint = CoordinationTrackingConfig.targetUnitsAtMs(
        CoordinationTrackingConfig.practiceDurationMs,
      );

      expect(initial.x, CoordinationTrackingConfig.trackInsetUnits);
      expect(initial.y, CoordinationTrackingConfig.trackInsetUnits);
      expect(checkpoint.x, initial.x);
      expect(checkpoint.y, initial.y);
    },
  );

  test('trajectory remains continuous at every speed boundary', () {
    for (final segment in CoordinationTrackingConfig.segments.skip(1)) {
      final before = CoordinationTrackingConfig.targetUnitsAtMs(
        segment.scheduledStartMs - 1,
      );
      final at = CoordinationTrackingConfig.targetUnitsAtMs(
        segment.scheduledStartMs,
      );
      final displacement = (before.x - at.x).abs() + (before.y - at.y).abs();
      expect(displacement, lessThanOrEqualTo(800));
    }
  });

  test('fixed-point normalization is bounded and deterministic', () {
    expect(CoordinationTrackingConfig.normalizedToUnits(-1), 0);
    expect(CoordinationTrackingConfig.normalizedToUnits(.16), 160000);
    expect(CoordinationTrackingConfig.normalizedToUnits(2), 1000000);
  });
}
