import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/coordination_tracking_scoring.dart';
import 'package:zennyt/features/games/domain/entities/coordination_tracking_metrics.dart';
import 'package:zennyt/features/games/domain/entities/device_calibration.dart';
import 'package:zennyt/features/games/domain/entities/emotional_radar.dart';
import 'package:zennyt/features/games/domain/entities/game_metrics.dart';
import 'package:zennyt/features/games/domain/entities/game_session.dart';
import 'package:zennyt/features/games/domain/entities/game_type.dart';
import 'package:zennyt/features/games/domain/entities/mini_game.dart';
import 'package:zennyt/features/games/domain/repositories/games_repository.dart';
import 'package:zennyt/features/games/presentation/games_providers.dart';
import 'package:zennyt/features/games/presentation/view/coordination_tracking_screen.dart';
import 'package:zennyt/features/games/presentation/widgets/game_system_components.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<_RecordingRepository> pumpGame(
    WidgetTester tester, {
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
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
          home: const CoordinationTrackingScreen(),
        ),
      ),
    );
    await tester.pump();
    return repository;
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

  Future<void> finishPractice(WidgetTester tester) async {
    await openPractice(tester);
    final rect = tester.getRect(
      find.byKey(const ValueKey('coordination-board')),
    );
    final gesture = await tester.startGesture(
      rect.topLeft + Offset(rect.width * .16, rect.height * .16),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 14000));
    await tester.pump();
    await gesture.up();
    await tester.pump();
  }

  testWidgets('cover, tutorials and board follow the shared purple game UI', (
    tester,
  ) async {
    await pumpGame(tester);

    final logoFinder = find.byKey(const ValueKey('coordination-cover-logo'));
    expect(tester.getSize(logoFinder).width, greaterThanOrEqualTo(140));
    final logoImage = tester.widget<Image>(
      find.descendant(of: logoFinder, matching: find.byType(Image)),
    );
    expect((logoImage.image as AssetImage).assetName, endsWith('.png'));

    await tester.tap(find.text('Start the journey'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('coordination-tutorial-illustration-0')),
      findsOneWidget,
    );
    expect(find.text('Enter the center to begin'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('coordination-tutorial-illustration-1')),
      findsOneWidget,
    );
    expect(find.text('READ THE CIRCLE'), findsOneWidget);
    expect(find.text('Centered'), findsOneWidget);
    expect(find.text('Inside'), findsOneWidget);
    expect(find.text('Outside'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('coordination-tutorial-illustration-2')),
      findsOneWidget,
    );
    expect(find.text('SAME PATH · TWO PACES'), findsOneWidget);

    await tester.tap(find.text('Begin practice'));
    await tester.pump();
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, ZennytGamePalette.gameBlue);
    final surface = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('coordination-board-surface')),
    );
    expect(
      (surface.decoration as BoxDecoration).color,
      ZennytGamePalette.gamePanel,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'full journey submits 14 fixed-point segments and shows results',
    (tester) async {
      final repository = await pumpGame(tester);

      expect(find.text('Je coordonne'), findsWidgets);
      expect(find.text('About 3 minutes'), findsOneWidget);
      await finishPractice(tester);
      expect(find.text('Practice complete'), findsOneWidget);

      await tester.tap(find.text('Start measured round'));
      await tester.pump();
      expect(find.text('Focused round'), findsOneWidget);
      expect(find.text('Score'), findsNothing);
      final rect = tester.getRect(
        find.byKey(const ValueKey('coordination-board')),
      );
      final gesture = await tester.startGesture(
        rect.topLeft + Offset(rect.width * .16, rect.height * .16),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 55998));
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pump();

      final metrics = repository.metrics;
      expect(metrics, isNotNull);
      expect(metrics!.coordinationSegments, hasLength(14));
      expect(
        metrics.coordinationSegments.every(
          (segment) => segment.samples.length >= 2,
        ),
        isTrue,
      );
      expect(metrics.coordinationSegments.first.segmentIndex, 1);
      expect(metrics.coordinationSegments.last.segmentIndex, 14);
      expect(metrics.coordinationSegments.first.samples.first.timestampMs, 0);
      expect(metrics.coordinationSegments[2].samples.first.timestampMs, 14000);
      expect(metrics.inputSource, CoordinationInputSource.touch);
      expect(find.text('Journey complete'), findsOneWidget);
      expect(find.byKey(const ValueKey('coordination-result-score')), findsOne);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('measured pause exposes help and requires a full test restart', (
    tester,
  ) async {
    await pumpGame(tester);
    await finishPractice(tester);
    await tester.tap(find.text('Start measured round'));
    await tester.pump();
    final rect = tester.getRect(
      find.byKey(const ValueKey('coordination-board')),
    );
    final gesture = await tester.startGesture(
      rect.topLeft + Offset(rect.width * .16, rect.height * .16),
    );
    await tester.pump(const Duration(milliseconds: 120));

    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('Resume'), findsNothing);
    expect(find.text('Restart phase'), findsOneWidget);
    expect(find.text('View rules / Help'), findsOneWidget);
    expect(find.text('Exit journey'), findsOneWidget);

    await tester.tap(find.text('View rules / Help'));
    await tester.pumpAndSettle();
    expect(find.text('Rules / Help'), findsOneWidget);
    expect(find.textContaining('fixed square'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Pause'), findsOneWidget);
    await tester.tap(find.text('Restart phase'));
    await tester.pump();
    expect(find.text('1 / 12'), findsOneWidget);
    expect(find.text('Enter the center to begin'), findsOneWidget);
    await gesture.up();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'resume before activation keeps practice armed and clock stopped',
    (tester) async {
      await pumpGame(tester);
      await openPractice(tester);
      expect(find.text('Enter the center to begin'), findsOneWidget);
      expect(find.text('14s'), findsOneWidget);

      await tester.tap(find.byTooltip('Pause'));
      await tester.pumpAndSettle();
      expect(find.text('Resume'), findsOneWidget);
      await tester.tap(find.text('Resume'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Enter the center to begin'), findsOneWidget);
      expect(find.text('14s'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('an incidental mouse hover does not block touch activation', (
    tester,
  ) async {
    await pumpGame(tester);
    await openPractice(tester);
    final rect = tester.getRect(
      find.byKey(const ValueKey('coordination-board')),
    );
    final mouse = TestPointer(41, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(
      mouse.hover(rect.bottomRight - const Offset(8, 8)),
    );
    await tester.pump();

    final touch = await tester.startGesture(
      rect.topLeft + Offset(rect.width * .16, rect.height * .16),
      pointer: 42,
      kind: PointerDeviceKind.touch,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('13s'), findsOneWidget);
    await touch.up();
    expect(tester.takeException(), isNull);
  });

  testWidgets('practice resumes after a lifecycle pause dialog', (
    tester,
  ) async {
    await pumpGame(tester);
    await openPractice(tester);
    final rect = tester.getRect(
      find.byKey(const ValueKey('coordination-board')),
    );
    final gesture = await tester.startGesture(
      rect.topLeft + Offset(rect.width * .16, rect.height * .16),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('13s'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Pause'), findsOneWidget);
    await tester.tap(find.text('Resume'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('12s'), findsOneWidget);
    await gesture.up();
    expect(tester.takeException(), isNull);
  });

  testWidgets('cover remains usable at 200 percent text scale', (tester) async {
    await pumpGame(tester, textScale: 2);
    expect(find.text('Start the journey'), findsOneWidget);
    expect(find.byTooltip('More options'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'late final frame preserves observed duration and invalidates run',
    (tester) async {
      final repository = await pumpGame(tester);
      await finishPractice(tester);
      await tester.tap(find.text('Start measured round'));
      await tester.pump();
      final rect = tester.getRect(
        find.byKey(const ValueKey('coordination-board')),
      );
      final gesture = await tester.startGesture(
        rect.topLeft + Offset(rect.width * .16, rect.height * .16),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 59000));
      await tester.pumpAndSettle();

      expect(repository.metrics!.coordinationSegments.last.actualEndMs, 73000);
      expect(find.text('Test interrupted'), findsOneWidget);
      await gesture.up();
      expect(tester.takeException(), isNull);
    },
  );
}

class _RecordingRepository implements GamesRepository {
  static const _sessionId = '00000000-0000-4000-8000-000000000099';
  CoordinationTrackingMetrics? metrics;

  @override
  Future<GameSession> startSession(GameType gameType) async => GameSession(
    id: _sessionId,
    gameType: gameType,
    status: 'IN_PROGRESS',
    compositeRaw: 0,
    compositeMax: 100,
    normalized: 0,
    attempts: const [],
    startedAt: DateTime(2026),
  );

  @override
  Future<GameSession> submitResult({
    required String sessionId,
    required MiniGame miniGame,
    required GameMetrics metrics,
    DeviceCalibration? deviceCalibration,
  }) async {
    final raw = metrics as CoordinationTrackingMetrics;
    this.metrics = raw;
    final result = const CoordinationTrackingScoring().score(raw);
    return GameSession(
      id: sessionId,
      gameType: GameType.visuomotorCoordination,
      status: 'COMPLETED',
      compositeRaw: result.score.rawPoints,
      compositeMax: 100,
      normalized: result.score.normalized,
      attempts: [
        GameAttempt(
          miniGame: miniGame,
          score: result.score,
          recordedAt: DateTime(2026),
        ),
      ],
      startedAt: DateTime(2026),
      completedAt: DateTime(2026),
      coordinationIndicators: result.indicators,
    );
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
