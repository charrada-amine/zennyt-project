import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zennyt/core/storage/shared_preferences_provider.dart';
import 'package:zennyt/features/games/domain/entities/decision_form.dart';
import 'package:zennyt/features/games/domain/entities/decision_metrics.dart';
import 'package:zennyt/features/games/domain/entities/device_calibration.dart';
import 'package:zennyt/features/games/domain/entities/emotional_radar.dart';
import 'package:zennyt/features/games/domain/entities/game_metrics.dart';
import 'package:zennyt/features/games/domain/entities/game_score.dart';
import 'package:zennyt/features/games/domain/entities/game_session.dart';
import 'package:zennyt/features/games/domain/entities/game_type.dart';
import 'package:zennyt/features/games/domain/entities/mini_game.dart';
import 'package:zennyt/features/games/domain/entities/score_breakdown.dart';
import 'package:zennyt/features/games/domain/repositories/games_repository.dart';
import 'package:zennyt/features/games/presentation/games_providers.dart';
import 'package:zennyt/features/games/presentation/view/je_decide_screen.dart';
import 'package:zennyt/features/navigation/presentation/widgets/app_bottom_nav.dart';


import 'package:flutter/gestures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const devices = [
    ('Redmi 360x800 3 boutons', Size(360, 800), EdgeInsets.only(top: 32, bottom: 48)),
    ('360x640', Size(360, 640), EdgeInsets.only(top: 24)),
    ('iPhone 17 Pro Max', Size(440, 956), EdgeInsets.only(top: 62, bottom: 34)),
  ];

  Future<_FakeGamesRepository> mount(WidgetTester tester, Size size, EdgeInsets insets, {EdgeInsets keyboard = EdgeInsets.zero}) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = _FakeGamesRepository();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = FakeViewPadding(top: insets.top, bottom: insets.bottom);
    tester.view.viewPadding = FakeViewPadding(top: insets.top, bottom: insets.bottom);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        gamesRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: JeDecideScreen()),
    ));
    await tester.pumpAndSettle();
    return repository;
  }

  String visible(Finder f, WidgetTester tester) {
    if (f.evaluate().isEmpty) return 'ABSENT';
    return f.hitTestable().evaluate().isEmpty ? 'NOT-HITTABLE' : 'ok';
  }

  Future<bool> tapIfVisible(WidgetTester tester, Finder f, String label) async {
    final v = visible(f, tester);
    if (v != 'ok') { debugPrint('  [$label] $v'); return false; }
    await tester.tap(f); await tester.pumpAndSettle();
    return true;
  }

  double scrollExtent(WidgetTester tester) {
    var worst = 0.0;
    for (final s in tester.stateList<ScrollableState>(find.byType(Scrollable))) {
      if (!s.position.hasContentDimensions) continue;
      if (s.position.axis == Axis.vertical && s.position.maxScrollExtent > worst) worst = s.position.maxScrollExtent;
    }
    return worst;
  }

  for (final (name, size, insets) in devices) {
    testWidgets('INV $name', timeout: const Timeout(Duration(seconds: 90)), (tester) async {
      final errors = <String>[];
      final old = FlutterError.onError;
      FlutterError.onError = (d) => errors.add(d.exceptionAsString().split('\n').first);
      addTearDown(() => FlutterError.onError = old);
      await mount(tester, size, insets);
      debugPrint('=== $name');
      debugPrint('welcome extent=${scrollExtent(tester)} start=${visible(find.byKey(const ValueKey('welcome-start')), tester)}');
      await tester.ensureVisible(find.byKey(const ValueKey('welcome-start'))); await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('welcome-start'))); await tester.pumpAndSettle();
      debugPrint('onboarding extent=${scrollExtent(tester)} next=${visible(find.byKey(const ValueKey('onboarding-next')), tester)} errors=$errors');
      // back on page 0
      await tester.tap(find.byTooltip('Back')); await tester.pumpAndSettle();
      debugPrint('after back p0: welcome? ${find.text('Je Décide').evaluate().isNotEmpty} onboarding? ${find.text('Onboarding').evaluate().isNotEmpty}');
      await tester.ensureVisible(find.byKey(const ValueKey('welcome-start'))); await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('welcome-start'))); await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) { await tester.tap(find.byKey(const ValueKey('onboarding-next'))); await tester.pumpAndSettle(); }
      debugPrint('playerCard extent=${scrollExtent(tester)} continue=${visible(find.byKey(const ValueKey('player-continue')), tester)} errors=$errors');
      // back from player card → onboarding → back x3
      await tester.tap(find.byTooltip('Back')); await tester.pumpAndSettle();
      final pageTitle = ['Every choice tells a\nstory','No pressure','Your decision profile'].where((t) => find.text(t).hitTestable().evaluate().isNotEmpty).toList();
      debugPrint('back to onboarding shows: $pageTitle');
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byTooltip('Back')); await tester.pumpAndSettle();
        final t = ['Every choice tells a\nstory','No pressure','Your decision profile'].where((t) => find.text(t).hitTestable().evaluate().isNotEmpty).toList();
        debugPrint('  back #$i -> onboarding page $t welcome=${find.byKey(const ValueKey('welcome-start')).evaluate().isNotEmpty}');
        if (find.byKey(const ValueKey('welcome-start')).evaluate().isNotEmpty) break;
      }
      // swipe onboarding by gesture then back
      await tester.ensureVisible(find.byKey(const ValueKey('welcome-start'))); await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('welcome-start'))); await tester.pumpAndSettle();
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000); await tester.pumpAndSettle();
      await tester.fling(find.byType(PageView), const Offset(300, 0), 1000); await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back')); await tester.pumpAndSettle();
      debugPrint('swipe fwd/back then back -> welcome=${find.byKey(const ValueKey('welcome-start')).evaluate().isNotEmpty}');
      // player card with keyboard
      await tester.ensureVisible(find.byKey(const ValueKey('welcome-start'))); await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('welcome-start'))); await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) { await tester.tap(find.byKey(const ValueKey('onboarding-next'))); await tester.pumpAndSettle(); }
      await tester.tap(find.byType(TextField)); await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Amine le très long pseudo du joueur');
      await tester.pumpAndSettle();
      debugPrint('playerCard+keyboard extent=${scrollExtent(tester)} field=${visible(find.byType(TextField), tester)} errors=$errors');
      tester.view.resetViewInsets(); await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('player-continue'))); await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('player-continue'))); await tester.pumpAndSettle();
      debugPrint('avatar extent=${scrollExtent(tester)} continue=${visible(find.byKey(const ValueKey('avatar-continue')), tester)} errors=$errors');
      errors.clear();
    });
  }
}
/// Backend simulé : « Je Décide » ne peut pas être joué hors ligne (la banque de
/// 120 items et sa clé de correction restent serveur), donc les tests d'écran
/// servent eux-mêmes une forme et un score.
class _FakeGamesRepository implements GamesRepository {
  /// Taille de la forme servie — celle de la passation réelle.
  static const itemCount = 30;

  DecisionMetrics? submitted;

  static const _dimensions = [
    DecisionDimension.ii,
    DecisionDimension.er,
    DecisionDimension.dt,
    DecisionDimension.cs,
    DecisionDimension.re,
  ];

  @override
  Future<GameSession> startSession(GameType gameType) async => GameSession(
    id: 'fake-session',
    gameType: gameType,
    status: 'IN_PROGRESS',
    compositeRaw: 0,
    compositeMax: 100,
    normalized: 0,
    attempts: const [],
    startedAt: DateTime(2026),
  );

  @override
  Future<DecisionForm> decisionItems(
    String sessionId, {
    String language = 'fr',
  }) async {
    final perDimension = itemCount ~/ _dimensions.length;
    return DecisionForm(
      formCode: 'A',
      itemsPerDimension: perDimension,
      items: [
        for (var i = 0; i < itemCount; i++)
          DecisionFormItem(
            itemId: 'IT-$i',
            dimension: _dimensions[i ~/ perDimension],
            format: DecisionItemFormat.standard,
            vignette: 'Situation numéro $i.',
            task: 'Consigne numéro $i.',
            options: [
              DecisionFormOption(optionId: 'IT-$i-o1', label: 'Option A du $i'),
              DecisionFormOption(optionId: 'IT-$i-o2', label: 'Option B du $i'),
            ],
          ),
      ],
    );
  }

  @override
  Future<GameSession> submitResult({
    required String sessionId,
    required MiniGame miniGame,
    required GameMetrics metrics,
    DeviceCalibration? deviceCalibration,
  }) async {
    submitted = metrics as DecisionMetrics;
    return GameSession(
      id: sessionId,
      gameType: GameType.decision,
      status: 'COMPLETED',
      compositeRaw: 71,
      compositeMax: 100,
      normalized: 71,
      startedAt: DateTime(2026),
      completedAt: DateTime(2026),
      attempts: [
        GameAttempt(
          miniGame: MiniGame.decisionCore,
          recordedAt: DateTime(2026),
          score: const GameScore(
            rawPoints: 71,
            maxPoints: 100,
            normalized: 71,
            level: 'Normal',
          ),
        ),
      ],
      scoreBreakdown: const [
        ScoreBreakdownLine(
          kind: ScoreBreakdownKind.criterion,
          label: 'II',
          detail: '6 items',
          points: 14,
          maxPoints: 18,
        ),
        ScoreBreakdownLine(
          kind: ScoreBreakdownKind.criterion,
          label: 'ER',
          detail: '6 items',
          points: 11,
          maxPoints: 18,
        ),
        ScoreBreakdownLine(
          kind: ScoreBreakdownKind.criterion,
          label: 'DT',
          detail: '6 items',
          points: 15,
          maxPoints: 18,
        ),
        ScoreBreakdownLine(
          kind: ScoreBreakdownKind.criterion,
          label: 'CS',
          detail: '6 items — notation provisoire (ne discrimine pas)',
          points: 12,
          maxPoints: 18,
        ),
        ScoreBreakdownLine(
          kind: ScoreBreakdownKind.criterion,
          label: 'RE',
          detail: '6 items — notation provisoire (ne discrimine pas)',
          points: 12,
          maxPoints: 18,
        ),
      ],
    );
  }

  @override
  Future<EmotionalRadarSceneSet> emotionalRadarScenes(String sessionId) =>
      throw UnimplementedError();

  @override
  Future<EmotionalRadarFeedback> answerEmotionalRadarScene({
    required String sessionId,
    required String sceneId,
    required BasicEmotion emotion,
    required String nuanceKey,
    required int intensity,
  }) => throw UnimplementedError();
}
