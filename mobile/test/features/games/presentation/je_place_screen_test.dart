import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/object_location_scoring.dart';
import 'package:zennyt/features/games/domain/config/object_location_config.dart';
import 'package:zennyt/features/games/domain/entities/device_calibration.dart';
import 'package:zennyt/features/games/domain/entities/emotional_radar.dart';
import 'package:zennyt/features/games/domain/entities/game_metrics.dart';
import 'package:zennyt/features/games/domain/entities/game_session.dart';
import 'package:zennyt/features/games/domain/entities/game_type.dart';
import 'package:zennyt/features/games/domain/entities/mini_game.dart';
import 'package:zennyt/features/games/domain/entities/object_location_metrics.dart';
import 'package:zennyt/features/games/domain/repositories/games_repository.dart';
import 'package:zennyt/features/games/presentation/games_providers.dart';
import 'package:zennyt/features/games/presentation/view/je_place_screen.dart';
import 'package:zennyt/features/games/presentation/widgets/game_system_components.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<({FakeObjectLocationClock clock, _RecordingRepository repository})>
  pumpGame(WidgetTester tester, {double textScale = 1}) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final clock = FakeObjectLocationClock();
    final repository = _RecordingRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [gamesRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: JePlaceScreen(clockFactory: () => clock),
        ),
      ),
    );
    await tester.pump();
    return (clock: clock, repository: repository);
  }

  Future<void> openPractice(WidgetTester tester) async {
    await tester.tap(find.text('Start the journey'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.tap(find.text('Begin practice'));
    await tester.pump();
  }

  Future<void> advanceToRecall(
    WidgetTester tester,
    FakeObjectLocationClock clock,
    int objectCount,
  ) async {
    clock.advance(ObjectLocationConfig.encodingDurationMs(objectCount));
    await tester.pump(
      Duration(
        milliseconds: ObjectLocationConfig.encodingDurationMs(objectCount),
      ),
    );
    clock.advance(ObjectLocationConfig.retentionDurationMs);
    await tester.pump(
      const Duration(milliseconds: ObjectLocationConfig.retentionDurationMs),
    );
    await tester.pump();
    expect(find.text('Restore'), findsWidgets);
  }

  Future<void> placePerfect(
    WidgetTester tester,
    FakeObjectLocationClock clock,
    ObjectLocationLevelLayout layout,
  ) async {
    for (final entry in layout.originalCells.entries) {
      final item = ObjectLocationConfig.item(entry.key);
      final object = find.bySemanticsLabel('Select ${item.accessibleName}');
      await tester.ensureVisible(object);
      await tester.tap(object);
      await tester.pump();
      final cell = find.byKey(ValueKey('je-place-cell-${entry.value}'));
      await tester.ensureVisible(cell);
      await tester.tap(cell);
      await tester.pump();
    }
    clock.advance(
      layout.objectCount * ObjectLocationConfig.minimumRecallPerObjectMs,
    );
    await tester.pump(const Duration(milliseconds: 200));
    final validate = find.byKey(const ValueKey('je-place-validate'));
    await tester.ensureVisible(validate);
    await tester.tap(validate);
    await tester.pump();
  }

  Future<List<ObjectLocationLevelLayout>> reachMeasuredReady(
    WidgetTester tester,
    FakeObjectLocationClock clock,
  ) async {
    await openPractice(tester);
    final layouts = ObjectLocationConfig.generateLayouts(
      _RecordingRepository.id,
    );
    await advanceToRecall(tester, clock, layouts.first.objectCount);
    await placePerfect(tester, clock, layouts.first);
    expect(find.text('Practice complete'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Build the picture, one level at a time'), findsOneWidget);
    return layouts;
  }

  testWidgets('cover and onboarding match the shared game language', (
    tester,
  ) async {
    await pumpGame(tester);

    expect(find.text('Je place'), findsWidgets);
    expect(find.text('Up to 5 minutes'), findsOneWidget);
    final logo = find.byKey(const ValueKey('je-place-cover-logo'));
    expect(tester.getSize(logo).width, greaterThanOrEqualTo(130));

    await tester.tap(find.text('Start the journey'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('je-place-tutorial-0')), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(find.byKey(const ValueKey('je-place-tutorial-1')), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(find.byKey(const ValueKey('je-place-tutorial-2')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('practice restores objects with tap-to-cell and no live score', (
    tester,
  ) async {
    final (:clock, :repository) = await pumpGame(tester);
    await openPractice(tester);
    final layout = ObjectLocationConfig.generateLayouts(
      repository.session.id,
    ).first;

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, ZennytGamePalette.gameBlue);
    expect(find.text('Score'), findsNothing);
    await advanceToRecall(tester, clock, layout.objectCount);
    expect(find.byKey(const ValueKey('je-place-reserve')), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Grid cell 1, empty. Place the selected object here.',
      ),
      findsOneWidget,
    );

    final before = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const ValueKey('je-place-validate')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(before.onPressed, isNull);
    await placePerfect(tester, clock, layout);

    expect(find.text('Practice complete'), findsOneWidget);
    expect(repository.metrics, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('practice pause freezes and resumes the monotonic phase clock', (
    tester,
  ) async {
    final (:clock, :repository) = await pumpGame(tester);
    await openPractice(tester);
    clock.advance(1000);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2s'), findsOneWidget);

    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();
    expect(find.text('Resume'), findsOneWidget);
    clock.advance(1000);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Resume'));
    await tester.pump();
    expect(find.text('2s'), findsOneWidget);

    clock.advance(2000);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Remember'), findsWidgets);
    expect(repository.metrics, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('measured pause audits before restarting the whole run', (
    tester,
  ) async {
    final (:clock, :repository) = await pumpGame(tester);
    await reachMeasuredReady(tester, clock);
    await tester.tap(find.byKey(const ValueKey('je-place-start-measured')));
    await tester.pump();

    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();
    expect(find.text('Resume'), findsNothing);
    expect(find.text('Restart run'), findsOneWidget);
    expect(find.text('View rules / Help'), findsOneWidget);

    await tester.tap(find.text('View rules / Help'));
    await tester.pumpAndSettle();
    expect(find.text('Rules / Help'), findsOneWidget);
    expect(find.textContaining('4 × 4'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restart run'));
    await tester.pumpAndSettle();
    expect(repository.submissions, hasLength(1));
    expect(
      repository.submissions.single.completionReason,
      ObjectLocationCompletionReason.technicalInterruption,
    );
    expect(repository.submissions.single.sessionCompleted, isFalse);
    expect(repository.submissions.single.interrupted, isTrue);
    expect(
      repository.submissions.single.objectLocationLevels.last.completed,
      isFalse,
    );
    expect(repository.session.attempts, isEmpty);
    expect(find.text('1 / 6'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lifecycle interruption is submitted audit-only', (tester) async {
    final (:clock, :repository) = await pumpGame(tester);
    await reachMeasuredReady(tester, clock);
    await tester.tap(find.byKey(const ValueKey('je-place-start-measured')));
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();

    expect(repository.metrics?.interrupted, isTrue);
    expect(repository.metrics?.sessionCompleted, isFalse);
    expect(
      repository.metrics?.completionReason,
      ObjectLocationCompletionReason.technicalInterruption,
    );
    expect(repository.session.attempts, isEmpty);
    expect(find.text('Journey interrupted'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('BOTH reserve stays responsive at 390x844 and 200% text', (
    tester,
  ) async {
    final (:clock, :repository) = await pumpGame(tester, textScale: 2);
    final layouts = await reachMeasuredReady(tester, clock);
    await tester.tap(find.byKey(const ValueKey('je-place-start-measured')));
    await tester.pump();

    for (var index = 1; index <= 3; index++) {
      await advanceToRecall(tester, clock, layouts[index].objectCount);
      await placePerfect(tester, clock, layouts[index]);
      await tester.tap(find.text('Continue to level ${index + 1}'));
      await tester.pump();
    }
    await advanceToRecall(tester, clock, layouts[4].objectCount);

    expect(layouts[4].reserveZone, ObjectLocationReserveZone.both);
    expect(find.byKey(const ValueKey('je-place-grid')), findsOneWidget);
    expect(find.byKey(const ValueKey('je-place-reserve')), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    expect(repository.metrics, isNull);
  });

  testWidgets('perfect journey reaches the server-backed results screen', (
    tester,
  ) async {
    final (:clock, :repository) = await pumpGame(tester);
    final layouts = await reachMeasuredReady(tester, clock);
    await tester.tap(find.byKey(const ValueKey('je-place-start-measured')));
    await tester.pump();

    for (var index = 1; index < layouts.length; index++) {
      await advanceToRecall(tester, clock, layouts[index].objectCount);
      await placePerfect(tester, clock, layouts[index]);
      if (index < layouts.length - 1) {
        await tester.tap(find.text('Continue to level ${index + 1}'));
        await tester.pump();
      }
    }
    await tester.pumpAndSettle();

    expect(repository.submissions, hasLength(1));
    final submitted = repository.submissions.single;
    expect(
      submitted.completionReason,
      ObjectLocationCompletionReason.maxLevels,
    );
    expect(submitted.sessionCompleted, isTrue);
    expect(submitted.interrupted, isFalse);
    expect(submitted.objectLocationLevels, hasLength(7));
    expect(repository.session.attempts, hasLength(1));
    expect(repository.session.attempts.single.score.rawPoints, 100);
    expect(find.text('Journey complete'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
    expect(find.text('Exact placement'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cover remains usable at 200 percent text scale', (tester) async {
    await pumpGame(tester, textScale: 2);
    expect(find.text('Start the journey'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class FakeObjectLocationClock implements ObjectLocationClock {
  int _elapsed = 0;
  bool _running = false;

  @override
  int get elapsedMilliseconds => _elapsed;
  @override
  bool get isRunning => _running;
  @override
  void reset() => _elapsed = 0;
  @override
  void start() => _running = true;
  @override
  void stop() => _running = false;

  void advance(int milliseconds) {
    if (_running) _elapsed += milliseconds;
  }
}

class _RecordingRepository implements GamesRepository {
  static const id = '00000000-0000-4000-8000-000000000004';
  static const _scoring = ObjectLocationScoring();

  GameSession session = GameSession(
    id: id,
    gameType: GameType.visuospatialMemory,
    status: 'IN_PROGRESS',
    compositeRaw: 0,
    compositeMax: 100,
    normalized: 0,
    attempts: const [],
    startedAt: DateTime(2026),
  );
  ObjectLocationMetrics? metrics;
  final List<ObjectLocationMetrics> submissions = [];

  @override
  Future<GameSession> startSession(GameType gameType) async {
    expect(gameType, GameType.visuospatialMemory);
    return session;
  }

  @override
  Future<GameSession> submitResult({
    required String sessionId,
    required MiniGame miniGame,
    required GameMetrics metrics,
    DeviceCalibration? deviceCalibration,
  }) async {
    expect(sessionId, id);
    expect(miniGame, MiniGame.objectLocationBindingCore);
    this.metrics = metrics as ObjectLocationMetrics;
    submissions.add(this.metrics!);
    final result = _scoring.score(sessionId: id, metrics: this.metrics!);
    final attempts = result.indicators.sessionValid
        ? [
            GameAttempt(
              miniGame: miniGame,
              score: result.score,
              recordedAt: DateTime(2026),
            ),
          ]
        : <GameAttempt>[];
    session = GameSession(
      id: id,
      gameType: GameType.visuospatialMemory,
      status: attempts.isEmpty ? 'IN_PROGRESS' : 'COMPLETED',
      compositeRaw: attempts.isEmpty ? 0 : result.score.rawPoints,
      compositeMax: 100,
      normalized: attempts.isEmpty ? 0 : result.score.normalized,
      attempts: attempts,
      startedAt: session.startedAt,
      completedAt: attempts.isEmpty ? null : DateTime(2026),
      objectLocationIndicators: result.indicators,
    );
    return session;
  }

  @override
  Future<EmotionalRadarFeedback> answerEmotionalRadarScene({
    required String sessionId,
    required String sceneId,
    required BasicEmotion emotion,
    required String nuanceKey,
    required int intensity,
  }) => throw UnimplementedError();

  @override
  Future<EmotionalRadarSceneSet> emotionalRadarScenes(String sessionId) =>
      throw UnimplementedError();
}
