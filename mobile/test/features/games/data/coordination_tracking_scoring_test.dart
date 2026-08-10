import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/coordination_tracking_scoring.dart';
import 'package:zennyt/features/games/data/games_mock_repository.dart';
import 'package:zennyt/features/games/domain/config/coordination_tracking_config.dart';
import 'package:zennyt/features/games/domain/entities/coordination_tracking_metrics.dart';
import 'package:zennyt/features/games/domain/entities/game_type.dart';
import 'package:zennyt/features/games/domain/entities/mini_game.dart';

void main() {
  const scoring = CoordinationTrackingScoring();

  test('perfect test score is 100 and practice never contributes', () {
    final perfectPractice = scoring.score(
      _trackingMetrics(testInsideBudgetMs: 55998, practiceInside: true),
    );
    final missedPractice = scoring.score(
      _trackingMetrics(testInsideBudgetMs: 55998, practiceInside: false),
    );

    expect(perfectPractice.score.rawPoints, 100);
    expect(perfectPractice.indicators.overallAccuracyPercent, 100);
    expect(perfectPractice.indicators.fastAccuracyPercent, 100);
    expect(perfectPractice.indicators.slowAccuracyPercent, 100);
    expect(perfectPractice.indicators.sessionValid, isTrue);
    expect(missedPractice.score.rawPoints, perfectPractice.score.rawPoints);
  });

  test('round-half-up uses exact duration arithmetic', () {
    final below = scoring.score(_trackingMetrics(testInsideBudgetMs: 8119));
    final above = scoring.score(_trackingMetrics(testInsideBudgetMs: 8120));

    expect(below.indicators.overallAccuracyPercent, lessThan(14.5));
    expect(below.score.rawPoints, 14);
    expect(above.indicators.overallAccuracyPercent, greaterThan(14.5));
    expect(above.score.rawPoints, 15);
  });

  test(
    'frame cadence changes neither a perfectly followed target nor score',
    () {
      final scores = <int>[];
      for (final cadenceMs in [8, 11, 16]) {
        final result = scoring.score(_followEvery(cadenceMs));
        scores.add(result.score.rawPoints);
        expect(result.indicators.overallAccuracyPercent, 100);
      }
      expect(scores, everyElement(100));
    },
  );

  test('dropped frames and sampling gaps stay descriptive', () {
    final result = scoring.score(
      _trackingMetrics(
        testInsideBudgetMs: 55998,
        droppedFrameCount: 42,
        cadenceMs: 200,
      ),
    );

    expect(result.indicators.droppedFrameCount, 42);
    expect(result.indicators.samplingGapCount, greaterThan(0));
    expect(result.indicators.taskValid, isTrue);
    expect(result.indicators.sessionValid, isTrue);
    expect(result.score.rawPoints, inInclusiveRange(0, 100));
  });

  test('two endpoint samples cannot manufacture perfect tracking', () {
    final result = scoring.score(_followEvery(7000));

    expect(result.indicators.samplingGapCount, greaterThan(0));
    expect(result.score.rawPoints, lessThan(25));
    expect(result.indicators.sessionValid, isTrue);
  });

  test(
    'background interruption is audit-only but does not alter raw score',
    () {
      final result = scoring.score(
        _trackingMetrics(
          testInsideBudgetMs: 55998,
          interrupted: true,
          backgroundEventCount: 1,
        ),
      );

      expect(result.score.rawPoints, 100);
      expect(result.indicators.taskValid, isTrue);
      expect(result.indicators.technicalValid, isFalse);
      expect(result.indicators.sessionValid, isFalse);
      expect(
        result.indicators.validityIssues,
        containsAll(['INTERRUPTED', 'BACKGROUND_EVENT']),
      );
    },
  );

  test('JSON is the exact 14-segment fixed-point contract shape', () {
    final json = _trackingMetrics(testInsideBudgetMs: 0).toJson();
    final segments = json['coordinationSegments'] as List<dynamic>;
    final first = segments.first as Map<String, dynamic>;
    final sample =
        (first['samples'] as List<dynamic>).first as Map<String, dynamic>;

    expect(json['protocolVersion'], 'FIXED_SQUARE_CW_V1');
    expect(json['inputSource'], 'TOUCH');
    expect(segments, hasLength(14));
    expect(first['segmentIndex'], 1);
    expect(first['phase'], 'PRACTICE');
    expect(sample.keys, {
      'sampleIndex',
      'timestampMs',
      'pointerPresent',
      'pointerX',
      'pointerY',
    });
    expect(sample['pointerX'], isA<int>());
    expect(json, isNot(contains('score')));
  });

  test(
    'mock returns server-shaped indicators and completes valid session',
    () async {
      final repository = GamesMockRepository();
      final session = await repository.startSession(
        GameType.visuomotorCoordination,
      );
      final completed = await repository.submitResult(
        sessionId: session.id,
        miniGame: MiniGame.coordinationTrackingCore,
        metrics: _trackingMetrics(testInsideBudgetMs: 55998),
      );

      expect(completed.isCompleted, isTrue);
      expect(completed.lastAttempt?.score.rawPoints, 100);
      expect(completed.coordinationIndicators?.sessionValid, isTrue);
      expect(completed.scoreBreakdown.last.points, 100);
    },
  );
}

CoordinationTrackingMetrics _trackingMetrics({
  required int testInsideBudgetMs,
  bool practiceInside = true,
  bool interrupted = false,
  int backgroundEventCount = 0,
  int droppedFrameCount = 0,
  int cadenceMs = 16,
}) {
  var remainingInsideMs = testInsideBudgetMs;
  final segments = <CoordinationSegmentMetric>[];
  for (final spec in CoordinationTrackingConfig.segments) {
    final insideMs = spec.phase == CoordinationTrackingPhase.practice
        ? (practiceInside ? spec.durationMs : 0)
        : math.min(remainingInsideMs, spec.durationMs);
    if (spec.phase == CoordinationTrackingPhase.test) {
      remainingInsideMs -= insideMs;
    }
    final samples = <CoordinationTrackingSample>[];

    void addInside(int timestampMs) {
      final target = CoordinationTrackingConfig.targetUnitsAtMs(timestampMs);
      samples.add(
        CoordinationTrackingSample(
          sampleIndex: samples.length + 1,
          timestampMs: timestampMs,
          pointerPresent: true,
          pointerX: target.x,
          pointerY: target.y,
        ),
      );
    }

    void addAbsent(int timestampMs) {
      if (samples.isNotEmpty && samples.last.timestampMs == timestampMs) return;
      samples.add(
        CoordinationTrackingSample(
          sampleIndex: samples.length + 1,
          timestampMs: timestampMs,
          pointerPresent: false,
          pointerX: null,
          pointerY: null,
        ),
      );
    }

    final insideEnd = spec.scheduledStartMs + insideMs;
    if (insideMs > 0) {
      for (
        var timestampMs = spec.scheduledStartMs;
        timestampMs < insideEnd;
        timestampMs += cadenceMs
      ) {
        addInside(timestampMs);
      }
      if (samples.last.timestampMs != insideEnd - 1) addInside(insideEnd - 1);
    } else if (spec.index == 1) {
      // Mandatory activation; practice remains excluded from the score.
      addInside(spec.scheduledStartMs);
    }
    if (insideMs < spec.durationMs) {
      final absentStart = spec.index == 1 && insideMs == 0
          ? spec.scheduledStartMs + 1
          : insideEnd;
      addAbsent(absentStart);
      addAbsent(spec.scheduledEndMs - 1);
    } else if (samples.last.timestampMs != spec.scheduledEndMs - 1) {
      addInside(spec.scheduledEndMs - 1);
    }
    segments.add(
      CoordinationSegmentMetric(
        phase: spec.phase,
        segmentIndex: spec.index,
        speed: spec.speed,
        nominalDurationMs: spec.durationMs,
        actualStartMs: spec.scheduledStartMs,
        actualEndMs: spec.scheduledEndMs,
        samples: samples,
      ),
    );
  }
  return CoordinationTrackingMetrics(
    inputSource: CoordinationInputSource.touch,
    coordinationSegments: segments,
    sessionCompleted: true,
    interrupted: interrupted,
    backgroundEventCount: backgroundEventCount,
    droppedFrameCount: droppedFrameCount,
  );
}

CoordinationTrackingMetrics _followEvery(int cadenceMs) {
  final segments = <CoordinationSegmentMetric>[];
  for (final spec in CoordinationTrackingConfig.segments) {
    final samples = <CoordinationTrackingSample>[];
    var timestampMs = spec.scheduledStartMs;
    while (timestampMs < spec.scheduledEndMs) {
      final target = CoordinationTrackingConfig.targetUnitsAtMs(timestampMs);
      samples.add(
        CoordinationTrackingSample(
          sampleIndex: samples.length + 1,
          timestampMs: timestampMs,
          pointerPresent: true,
          pointerX: target.x,
          pointerY: target.y,
        ),
      );
      timestampMs += cadenceMs;
    }
    if (samples.last.timestampMs != spec.scheduledEndMs - 1) {
      final lastMs = spec.scheduledEndMs - 1;
      final target = CoordinationTrackingConfig.targetUnitsAtMs(lastMs);
      samples.add(
        CoordinationTrackingSample(
          sampleIndex: samples.length + 1,
          timestampMs: lastMs,
          pointerPresent: true,
          pointerX: target.x,
          pointerY: target.y,
        ),
      );
    }
    segments.add(
      CoordinationSegmentMetric(
        phase: spec.phase,
        segmentIndex: spec.index,
        speed: spec.speed,
        nominalDurationMs: spec.durationMs,
        actualStartMs: spec.scheduledStartMs,
        actualEndMs: spec.scheduledEndMs,
        samples: samples,
      ),
    );
  }
  return CoordinationTrackingMetrics(
    inputSource: CoordinationInputSource.mouse,
    coordinationSegments: segments,
    sessionCompleted: true,
    interrupted: false,
    backgroundEventCount: 0,
    droppedFrameCount: 0,
  );
}
