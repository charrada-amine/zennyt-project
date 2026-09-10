import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/games_mock_repository.dart';
import 'package:zennyt/features/games/domain/entities/device_calibration.dart';
import 'package:zennyt/features/games/domain/entities/game_metrics.dart';
import 'package:zennyt/features/games/domain/entities/game_session.dart';
import 'package:zennyt/features/games/domain/entities/game_type.dart';
import 'package:zennyt/features/games/domain/entities/mini_game.dart';
import 'package:zennyt/features/games/domain/entities/task_scheduling_metrics.dart';
import 'package:zennyt/features/games/presentation/games_providers.dart';
import 'package:zennyt/features/games/presentation/view/task_scheduling_screen.dart';

class _RecordingRepository extends GamesMockRepository {
  int starts = 0;
  TaskSchedulingMetrics? submitted;

  @override
  Future<GameSession> startSession(GameType gameType) {
    starts++;
    return super.startSession(gameType);
  }

  @override
  Future<GameSession> submitResult({
    required String sessionId,
    required MiniGame miniGame,
    required GameMetrics metrics,
    DeviceCalibration? deviceCalibration,
  }) {
    submitted = metrics as TaskSchedulingMetrics;
    return super.submitResult(
      sessionId: sessionId,
      miniGame: miniGame,
      metrics: metrics,
      deviceCalibration: deviceCalibration,
    );
  }
}

void main() {
  Future<_RecordingRepository> start(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _RecordingRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [gamesRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const TaskSchedulingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final label in ['Start', 'I am ready']) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    return repo;
  }

  Future<void> place(WidgetTester tester, int task) async {
    final tray = find.descendant(
      of: find.byKey(const ValueKey('day-stack-tray')),
      matching: find.byType(Scrollable),
    );
    // Each placement can change list order/extent. Start from the top.
    await tester.drag(tray, const Offset(0, 2000));
    await tester.pumpAndSettle();
    final target = find.byKey(ValueKey('day-stack-task-$task'));
    await tester.scrollUntilVisible(target, 100, scrollable: tray);
    await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(390, 844), 2.0),
    (const Size(1024, 768), 1.0),
  ]) {
    testWidgets('schedule and tray fit $size at text scale $scale', (
      tester,
    ) async {
      await start(tester, size: size, scale: scale);
      expect(tester.takeException(), isNull);
      expect(find.text('0 / 9 tasks placed'), findsOneWidget);
      expect(find.text('Validate schedule').hitTestable(), findsOneWidget);
      await place(tester, 0);
      expect(find.text('1 / 9 tasks placed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('rules preserve placements and the original session', (
    tester,
  ) async {
    final repo = await start(tester);
    await place(tester, 0);
    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View rules'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Resume schedule'));
    await tester.tap(find.text('Resume schedule'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 9 tasks placed'), findsOneWidget);
    expect(repo.starts, 1);
  });

  testWidgets(
    'nine placements send raw metrics and show the repository score',
    (tester) async {
      final repo = await start(tester);
      for (var task = 0; task < 9; task++) {
        await place(tester, task);
      }
      await tester.tap(find.text('Validate schedule'));
      await tester.pumpAndSettle();
      expect(repo.submitted?.toJson(), {
        'dependenciesRespected': true,
        'timeConstraintsRespected': true,
        'planningCoherence': 2,
        'adjustmentCount': 0,
      });
      expect(find.text('10/10'), findsOneWidget);
    },
  );
}
