import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/games_mock_repository.dart';
import 'package:zennyt/features/games/data/object_location_scoring.dart';
import 'package:zennyt/features/games/domain/config/object_location_config.dart';
import 'package:zennyt/features/games/domain/entities/game_type.dart';
import 'package:zennyt/features/games/domain/entities/mini_game.dart';
import 'package:zennyt/features/games/domain/entities/object_location_metrics.dart';

void main() {
  const sessionId = '00000000-0000-4000-8000-000000000004';
  const scoring = ObjectLocationScoring();

  test(
    'perfect measured journey scores 100 and practice stays outside score',
    () {
      final layouts = ObjectLocationConfig.generateLayouts(sessionId);
      final metrics = _metrics(
        layouts.map((layout) => _perfect(layout)).toList(),
        ObjectLocationCompletionReason.maxLevels,
      );

      final result = scoring.score(sessionId: sessionId, metrics: metrics);

      expect(result.score.rawPoints, 100);
      expect(result.indicators.administeredObjectCount, 33);
      expect(result.indicators.exactPlacementCount, 33);
      expect(result.indicators.span, 8);
      expect(result.indicators.sessionValid, isTrue);
      expect(
        result.indicators.levels.first.phase,
        ObjectLocationPhase.practice,
      );
    },
  );

  test('continuing after a valid two-failure stop is rejected', () {
    final layouts = ObjectLocationConfig.generateLayouts(sessionId);
    final levels = <ObjectLocationLevelMetric>[
      _perfect(layouts[0]),
      _perfect(layouts[1]),
      _timeout(layouts[2]),
      _timeout(layouts[3]),
      _perfect(layouts[4]),
    ];
    final result = scoring.score(
      sessionId: sessionId,
      metrics: _metrics(levels, ObjectLocationCompletionReason.stopRule),
    );

    expect(result.indicators.progressionValid, isFalse);
    expect(result.indicators.sessionValid, isFalse);
    expect(result.indicators.validityIssues, contains('INVALID_PROGRESSION'));
  });

  test('valid stop rule completes after two consecutive failures', () {
    final layouts = ObjectLocationConfig.generateLayouts(sessionId);
    final levels = <ObjectLocationLevelMetric>[
      _perfect(layouts[0]),
      _perfect(layouts[1]),
      _perfect(layouts[2]),
      _timeout(layouts[3]),
      _timeout(layouts[4]),
    ];
    final result = scoring.score(
      sessionId: sessionId,
      metrics: _metrics(levels, ObjectLocationCompletionReason.stopRule),
    );

    expect(result.indicators.completedLevelCount, 4);
    expect(result.indicators.progressionValid, isTrue);
    expect(result.indicators.sessionValid, isTrue);
  });

  test('completed non-timeout level requires every object to be placed', () {
    final layouts = ObjectLocationConfig.generateLayouts(sessionId);
    final layout = layouts[1];
    final first = layout.originalCells.entries.first;
    final incomplete = _level(
      layout,
      actions: [_action(1, first.key, first.value, 200)],
    );

    expect(
      () => scoring.score(
        sessionId: sessionId,
        metrics: _metrics(
          [_perfect(layouts[0]), incomplete],
          ObjectLocationCompletionReason.technicalInterruption,
          completed: false,
          interrupted: true,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('error classes are exclusive and include omissions separately', () {
    final layouts = ObjectLocationConfig.generateLayouts(sessionId);
    final layout = layouts[1];
    final entries = layout.originalCells.entries.toList();
    final actions = [
      _action(1, entries[0].key, entries[0].value, 100),
      _action(2, entries[1].key, entries[2].value, 200),
    ];
    final level = _level(layout, actions: actions, timedOut: true);
    final result = scoring.score(
      sessionId: sessionId,
      metrics: _metrics(
        [_perfect(layouts[0]), level],
        ObjectLocationCompletionReason.technicalInterruption,
        completed: false,
        interrupted: true,
      ),
    );
    final report = result.indicators.levels[1];

    expect(report.exactCount, 1);
    expect(report.swapCount, 1);
    expect(report.localErrorCount, 0);
    expect(report.globalErrorCount, 0);
    expect(report.unplacedCount, 1);
    expect(
      report.exactCount +
          report.swapCount +
          report.localErrorCount +
          report.globalErrorCount +
          report.unplacedCount,
      report.objectCount,
    );
  });

  test('first-placement interval uses only objects actually placed', () {
    final layouts = ObjectLocationConfig.generateLayouts(sessionId);
    final layout = layouts[1];
    final ids = layout.objectIds;
    final partial = _level(
      layout,
      timedOut: true,
      actions: [
        _action(1, ids[0], 0, 100),
        _action(2, ids[0], 1, 200),
        _action(3, ids[1], 2, 500),
      ],
    );
    final result = scoring.score(
      sessionId: sessionId,
      metrics: _metrics(
        [_perfect(layouts[0]), partial],
        ObjectLocationCompletionReason.technicalInterruption,
        completed: false,
        interrupted: true,
      ),
    );

    expect(result.indicators.averageFirstPlacementIntervalMs, 400);
  });

  test('JSON is raw-only and uses the unique objectLocationLevels key', () {
    final layout = ObjectLocationConfig.generateLayouts(sessionId).first;
    final json = _metrics(
      [_perfect(layout)],
      ObjectLocationCompletionReason.technicalInterruption,
      completed: false,
      interrupted: true,
    ).toJson();
    final level =
        (json['objectLocationLevels'] as List).first as Map<String, dynamic>;
    final action = (level['actions'] as List).first as Map<String, dynamic>;

    expect(json['protocolVersion'], 'OBJECT_LOCATION_FINE_V1');
    expect(json, contains('objectLocationLevels'));
    expect(json, isNot(contains('levels')));
    expect(json, isNot(contains('score')));
    expect(level, isNot(contains('originalCells')));
    expect(level, isNot(contains('correct')));
    expect(action.keys, {
      'actionIndex',
      'actionType',
      'objectId',
      'targetCellIndex',
      'timestampMs',
    });
  });

  test('mock completes a valid server-shaped standalone session', () async {
    final repository = GamesMockRepository();
    final session = await repository.startSession(GameType.visuospatialMemory);
    final layouts = ObjectLocationConfig.generateLayouts(session.id);
    final completed = await repository.submitResult(
      sessionId: session.id,
      miniGame: MiniGame.objectLocationBindingCore,
      metrics: _metrics(
        layouts.map((layout) => _perfect(layout)).toList(),
        ObjectLocationCompletionReason.maxLevels,
      ),
    );

    expect(completed.isCompleted, isTrue);
    expect(completed.lastAttempt?.miniGame, MiniGame.objectLocationBindingCore);
    expect(completed.lastAttempt?.score.rawPoints, 100);
    expect(completed.objectLocationIndicators?.sessionValid, isTrue);
  });
}

ObjectLocationMetrics _metrics(
  List<ObjectLocationLevelMetric> levels,
  ObjectLocationCompletionReason reason, {
  bool completed = true,
  bool interrupted = false,
}) {
  return ObjectLocationMetrics(
    completionReason: reason,
    objectLocationLevels: levels,
    sessionCompleted: completed,
    interrupted: interrupted,
    backgroundEventCount: 0,
    focusLossCount: 0,
    orientationChangeCount: 0,
    droppedFrameCount: 0,
  );
}

ObjectLocationLevelMetric _perfect(ObjectLocationLevelLayout layout) {
  final actions = <ObjectLocationPlacementAction>[];
  for (final entry in layout.originalCells.entries) {
    actions.add(
      _action(
        actions.length + 1,
        entry.key,
        entry.value,
        (actions.length + 1) * 100,
      ),
    );
  }
  return _level(layout, actions: actions);
}

ObjectLocationLevelMetric _timeout(ObjectLocationLevelLayout layout) =>
    _level(layout, actions: const [], timedOut: true);

ObjectLocationLevelMetric _level(
  ObjectLocationLevelLayout layout, {
  required List<ObjectLocationPlacementAction> actions,
  bool timedOut = false,
}) {
  return ObjectLocationLevelMetric(
    phase: layout.levelIndex == 0
        ? ObjectLocationPhase.practice
        : ObjectLocationPhase.test,
    levelIndex: layout.levelIndex,
    objectCount: layout.objectCount,
    actualEncodingDurationMs: ObjectLocationConfig.encodingDurationMs(
      layout.objectCount,
    ),
    actualRetentionDurationMs: ObjectLocationConfig.retentionDurationMs,
    actualRecallDurationMs: timedOut
        ? ObjectLocationConfig.recallDurationMs(layout.objectCount)
        : layout.objectCount * ObjectLocationConfig.minimumRecallPerObjectMs,
    timedOut: timedOut,
    completed: true,
    actions: actions,
  );
}

ObjectLocationPlacementAction _action(
  int index,
  String objectId,
  int cell,
  int timestamp,
) {
  return ObjectLocationPlacementAction(
    actionIndex: index,
    actionType: ObjectLocationActionType.place,
    objectId: objectId,
    targetCellIndex: cell,
    timestampMs: timestamp,
  );
}
