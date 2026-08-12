import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zennyt/core/storage/shared_preferences_provider.dart';
import 'package:zennyt/features/auth/presentation/current_user_provider.dart';
import 'package:zennyt/features/games/domain/config/continuous_attention_config.dart';
import 'package:zennyt/features/games/domain/entities/continuous_attention_metrics.dart';
import 'package:zennyt/features/games/domain/entities/device_calibration.dart';
import 'package:zennyt/features/games/domain/entities/emotional_radar.dart';
import 'package:zennyt/features/games/domain/entities/game_metrics.dart';
import 'package:zennyt/features/games/domain/entities/game_session.dart';
import 'package:zennyt/features/games/domain/entities/game_type.dart';
import 'package:zennyt/features/games/domain/entities/mini_game.dart';
import 'package:zennyt/features/games/domain/repositories/games_repository.dart';
import 'package:zennyt/features/games/presentation/games_providers.dart';
import 'package:zennyt/features/games/presentation/view/continuous_attention_screen.dart';

const _acceleratedTempo = ContinuousAttentionTempo(
  stimulusDuration: Duration.zero,
  interStimulusDuration: Duration.zero,
  scheduledRestDuration: Duration.zero,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<_RecordingGamesRepository> pumpGame(
    WidgetTester tester, {
    ContinuousAttentionTempo tempo = _acceleratedTempo,
    ContinuousAttentionClock Function()? clockFactory,
    double textScale = 1,
    _RecordingGamesRepository? repository,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final gameRepository = repository ?? _RecordingGamesRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gamesRepositoryProvider.overrideWithValue(gameRepository),
          sharedPreferencesProvider.overrideWithValue(preferences),
          currentUserProvider.overrideWithValue(null),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: ContinuousAttentionScreen(
            tempo: tempo,
            clockFactory: clockFactory ?? _StepClock.new,
            quickRun: false,
          ),
        ),
      ),
    );
    await tester.pump();
    return gameRepository;
  }

  Future<void> openFirstPractice(WidgetTester tester) async {
    await tester.tap(find.text('Start the journey'));
    await tester.pump();
    await tester.tap(find.text('Learn the first rule'));
    await tester.pump();
    await tester.tap(find.text('Start practice'));
    await tester.pump();
    await tester.pump();
  }

  Future<void> finishAcceleratedJourney(WidgetTester tester) async {
    await tester.tap(find.text('Start the journey'));
    await tester.pump();
    await tester.tap(find.text('Learn the first rule'));
    await tester.pump();
    await tester.tap(find.text('Start practice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start focused round'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    await tester.tap(find.text('Learn the second rule'));
    await tester.pump();
    await tester.tap(find.text('Start second practice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start final round'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'le parcours complet 390x844 atteint les résultats puis les insights',
    (tester) async {
      final repository = await pumpGame(tester, textScale: 1.3);

      expect(find.text('Je continue'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('About 25 minutes'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('About 25 minutes'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Start the journey'));
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('A steady focus journey'), findsOneWidget);

      await tester.tap(find.text('Learn the first rule'));
      await tester.pump();
      expect(find.text('Respond whenever X appears'), findsOneWidget);

      await tester.tap(find.text('Start practice'));
      await tester.pumpAndSettle();
      expect(find.text('Practice complete'), findsOneWidget);

      await tester.tap(find.text('Start focused round'));
      await tester.pumpAndSettle();
      expect(find.text('Scheduled break'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      await tester.tap(find.text('Learn the second rule'));
      await tester.pump();
      expect(find.text('Watch for A, then X'), findsOneWidget);

      await tester.tap(find.text('Start second practice'));
      await tester.pumpAndSettle();
      expect(find.text('Second practice complete'), findsOneWidget);

      await tester.tap(find.text('Start final round'));
      await tester.pumpAndSettle();

      expect(repository.submittedMetrics, isNotNull);
      expect(
        repository.submittedMetrics!.blocks,
        hasLength(ContinuousAttentionConfig.totalBlocks),
      );
      expect(
        repository.submittedMetrics!.blocks.fold<int>(
          0,
          (total, block) => total + block.trials.length,
        ),
        ContinuousAttentionConfig.totalTrials,
      );
      expect(find.text('Journey complete'), findsOneWidget);
      expect(find.byKey(const ValueKey('continuous-result-score')), findsOne);
      expect(find.text('84'), findsOneWidget);
      expect(find.text('Provisional accuracy'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('View descriptive insights'));
      await tester.pumpAndSettle();
      expect(find.text('Descriptive insights'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Signal separation (d′)'),
        260,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Signal separation (d′)'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Response tendency (c)'),
        260,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Response tendency (c)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'le menu pause expose règles, reprise de pratique et restart du test',
    (tester) async {
      final bindingClock = _BindingClock(tester.binding.clock.now);
      await pumpGame(
        tester,
        tempo: const ContinuousAttentionTempo(
          stimulusDuration: Duration(seconds: 1),
          interStimulusDuration: Duration(seconds: 1),
          scheduledRestDuration: Duration.zero,
        ),
        clockFactory: () => bindingClock,
        textScale: 2,
      );
      await openFirstPractice(tester);

      expect(find.text('First rule · Practice'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1));
      final stimulusLetter = find.byKey(
        const ValueKey('continuous-stimulus-letter'),
      );
      expect(stimulusLetter, findsOneWidget);
      final stimulusSemantics = tester.widget<Semantics>(
        find
            .ancestor(of: stimulusLetter, matching: find.byType(Semantics))
            .first,
      );
      expect(stimulusSemantics.properties.liveRegion, isNot(isTrue));
      expect(stimulusSemantics.container, isTrue);
      expect(stimulusSemantics.excludeSemantics, isTrue);
      await tester.tap(find.byTooltip('Pause'));
      await tester.pumpAndSettle();
      expect(find.textContaining('practice clock is stopped'), findsOneWidget);
      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pump();
      expect(find.text('Pause'), findsOneWidget);
      expect(find.textContaining('practice clock is stopped'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Restart phase'), findsOneWidget);
      expect(find.text('View rules / Help'), findsOneWidget);
      expect(find.text('Exit journey'), findsOneWidget);

      await tester.ensureVisible(find.text('View rules / Help'));
      await tester.pump();
      await tester.tap(find.text('View rules / Help'));
      await tester.pumpAndSettle();
      expect(find.text('Rules / Help'), findsOneWidget);
      expect(
        find.textContaining('Respond whenever the current letter is X'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Got it'));
      await tester.pump();
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.text('Pause'), findsOneWidget);

      await tester.ensureVisible(find.text('Resume'));
      await tester.pump();
      await tester.tap(find.text('Resume'));
      await tester.pump();
      expect(find.text('First rule · Practice'), findsOneWidget);

      await tester.tap(find.byTooltip('Pause'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Restart phase'));
      await tester.pump();
      await tester.tap(find.text('Restart phase'));
      await tester.pump();
      expect(find.text('Block 1 / 2'), findsOneWidget);

      await tester.pump(const Duration(minutes: 3));
      await tester.pumpAndSettle();
      expect(find.text('Practice complete'), findsOneWidget);
      await tester.tap(find.text('Start focused round'));
      await tester.pump();
      await tester.pump();
      expect(find.text('First focus round'), findsOneWidget);

      await tester.tap(find.byTooltip('Pause and restart phase'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('measured phase was interrupted'),
        findsOneWidget,
      );
      expect(find.text('Resume'), findsNothing);
      final dialogRestart = find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Restart phase'),
      );
      await tester.ensureVisible(dialogRestart);
      await tester.pump();
      await tester.tap(dialogRestart);
      await tester.pump();
      expect(find.text('Block 1 / 20'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cover et résultats restent sans overflow à 200%', (
    tester,
  ) async {
    await pumpGame(tester, textScale: 2);
    expect(find.text('Je continue'), findsWidgets);
    expect(tester.takeException(), isNull);

    await finishAcceleratedJourney(tester);
    expect(find.text('Journey complete'), findsOneWidget);
    expect(find.byKey(const ValueKey('continuous-result-score')), findsOne);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un audit invalide est remplacé sur la même session au retry', (
    tester,
  ) async {
    final repository = _RecordingGamesRepository(invalidFirst: true);
    await pumpGame(tester, repository: repository);
    await finishAcceleratedJourney(tester);

    expect(find.text('Restart the journey'), findsOneWidget);
    expect(repository.startCallCount, 1);
    expect(repository.submitCallCount, 1);
    expect(repository.submittedSessionIds, [
      _RecordingGamesRepository.sessionId,
    ]);

    await tester.tap(find.text('Restart journey'));
    await tester.pumpAndSettle();
    expect(find.text('Practice complete'), findsOneWidget);

    await tester.tap(find.text('Start focused round'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    await tester.tap(find.text('Learn the second rule'));
    await tester.pump();
    await tester.tap(find.text('Start second practice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start final round'));
    await tester.pumpAndSettle();

    expect(find.text('Journey complete'), findsOneWidget);
    expect(repository.startCallCount, 1);
    expect(repository.submitCallCount, 2);
    expect(
      repository.submittedSessionIds,
      everyElement(_RecordingGamesRepository.sessionId),
    );
    expect(tester.takeException(), isNull);
  });
}

class _StepClock implements ContinuousAttentionClock {
  int _elapsedMicroseconds = 0;
  bool _running = false;

  @override
  int get elapsedMicroseconds {
    if (_running) _elapsedMicroseconds += 1000;
    return _elapsedMicroseconds;
  }

  @override
  bool get isRunning => _running;

  @override
  void reset() => _elapsedMicroseconds = 0;

  @override
  void start() => _running = true;

  @override
  void stop() => _running = false;
}

class _BindingClock implements ContinuousAttentionClock {
  _BindingClock(this._now);

  final DateTime Function() _now;
  Duration _elapsed = Duration.zero;
  DateTime? _startedAt;

  @override
  int get elapsedMicroseconds {
    final startedAt = _startedAt;
    return (_elapsed +
            (startedAt == null ? Duration.zero : _now().difference(startedAt)))
        .inMicroseconds;
  }

  @override
  bool get isRunning => _startedAt != null;

  @override
  void reset() {
    _elapsed = Duration.zero;
    if (isRunning) _startedAt = _now();
  }

  @override
  void start() {
    _startedAt ??= _now();
  }

  @override
  void stop() {
    final startedAt = _startedAt;
    if (startedAt == null) return;
    _elapsed += _now().difference(startedAt);
    _startedAt = null;
  }
}

class _RecordingGamesRepository implements GamesRepository {
  _RecordingGamesRepository({this.invalidFirst = false});

  static const sessionId = '00000000-0000-4000-8000-000000000001';

  final bool invalidFirst;
  ContinuousAttentionMetrics? submittedMetrics;
  int startCallCount = 0;
  int submitCallCount = 0;
  final List<String> submittedSessionIds = [];

  @override
  Future<GameSession> startSession(GameType gameType) async {
    startCallCount++;
    return GameSession(
      id: sessionId,
      gameType: gameType,
      status: 'IN_PROGRESS',
      compositeRaw: 0,
      compositeMax: 0,
      normalized: 0,
      attempts: const [],
      startedAt: DateTime.utc(2026, 7, 30),
    );
  }

  @override
  Future<GameSession> submitResult({
    required String sessionId,
    required MiniGame miniGame,
    required GameMetrics metrics,
    DeviceCalibration? deviceCalibration,
  }) async {
    submitCallCount++;
    submittedSessionIds.add(sessionId);
    submittedMetrics = metrics as ContinuousAttentionMetrics;
    if (invalidFirst && submitCallCount == 1) {
      return GameSession(
        id: sessionId,
        gameType: GameType.continuousAttention,
        status: 'IN_PROGRESS',
        compositeRaw: 0,
        compositeMax: 0,
        normalized: 0,
        attempts: const [],
        startedAt: DateTime.utc(2026, 7, 30),
        continuousAttentionIndicators: _invalidIndicators,
      );
    }
    return GameSession(
      id: sessionId,
      gameType: GameType.continuousAttention,
      status: 'COMPLETED',
      compositeRaw: 84,
      compositeMax: 100,
      normalized: .84,
      attempts: const [],
      startedAt: DateTime.utc(2026, 7, 30),
      completedAt: DateTime.utc(2026, 7, 30, 0, 25),
      continuousAttentionIndicators: _validIndicators,
    );
  }

  @override
  Future<EmotionalRadarFeedback> answerEmotionalRadarScene({
    required String sessionId,
    required String sceneId,
    required BasicEmotion emotion,
    required String nuanceKey,
    required int intensity,
  }) {
    throw UnsupportedError('Not used by this test');
  }

  @override
  Future<EmotionalRadarSceneSet> emotionalRadarScenes(String sessionId) {
    throw UnsupportedError('Not used by this test');
  }
}

final _validIndicators = ContinuousAttentionIndicators(
  protocolVersion: ContinuousAttentionConfig.protocolVersion,
  completed: true,
  sessionValid: true,
  interrupted: false,
  provisionalAccuracyScore: 84,
  xPhase: ContinuousAttentionPhaseIndicators(
    phase: ContinuousAttentionPhase.xTest,
    targetCount: 160,
    nonTargetCount: 460,
    hitCount: 120,
    omissionCount: 40,
    commissionCount: 46,
    correctRejectionCount: 414,
    hitRatePercent: 75,
    omissionRatePercent: 25,
    falseAlarmRatePercent: 10,
    correctRejectionRatePercent: 90,
    balancedAccuracyPercent: 82.5,
    averageHitReactionTimeMs: 420,
    medianHitReactionTimeMs: 410,
    stdDevHitReactionTimeMs: 45,
    reactionTimeCoefficientOfVariation: .107,
    dPrime: 1.9462343855,
    responseBiasC: .3035058635,
  ),
  axPhase: ContinuousAttentionPhaseIndicators(
    phase: ContinuousAttentionPhase.axTest,
    targetCount: 120,
    nonTargetCount: 500,
    hitCount: 108,
    omissionCount: 12,
    commissionCount: 100,
    correctRejectionCount: 400,
    hitRatePercent: 90,
    omissionRatePercent: 10,
    falseAlarmRatePercent: 20,
    correctRejectionRatePercent: 80,
    balancedAccuracyPercent: 85,
    averageHitReactionTimeMs: 455,
    medianHitReactionTimeMs: 450,
    stdDevHitReactionTimeMs: 50,
    reactionTimeCoefficientOfVariation: .11,
    dPrime: 2.1024219831,
    responseBiasC: -.2117267076,
  ),
  epochs: [],
  axTargetCount: 120,
  ayCount: 100,
  bxCount: 100,
  byCount: 300,
  extraResponseCount: 0,
  backgroundEventCount: 0,
  droppedFrameCount: 0,
  timingDeviationCount: 0,
  validityIssues: [],
);

final _invalidIndicators = ContinuousAttentionIndicators(
  protocolVersion: ContinuousAttentionConfig.protocolVersion,
  completed: true,
  sessionValid: false,
  interrupted: false,
  provisionalAccuracyScore: 0,
  xPhase: _validIndicators.xPhase,
  axPhase: _validIndicators.axPhase,
  epochs: const [],
  axTargetCount: 120,
  ayCount: 100,
  bxCount: 100,
  byCount: 300,
  extraResponseCount: 0,
  backgroundEventCount: 0,
  droppedFrameCount: 0,
  timingDeviationCount: 1,
  validityIssues: const ['TIMING_DEVIATION'],
);
