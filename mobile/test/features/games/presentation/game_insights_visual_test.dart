import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/shared/icons/app_icons.dart';
import 'package:zennyt/core/audio/sound_service.dart';
import 'package:zennyt/features/games/domain/config/strategic_choices_content.dart';
import 'package:zennyt/features/games/domain/entities/emotional_radar_v2.dart';
import 'package:zennyt/features/games/domain/entities/reflective_pause_metrics.dart';
import 'package:zennyt/features/games/presentation/view/strategic_choices_screen.dart';
import 'package:zennyt/features/games/presentation/view/reflective_pause_screen.dart';
import 'package:zennyt/features/games/presentation/view/emotional_radar_screen.dart';
import 'package:zennyt/features/games/presentation/widgets/game_results_template.dart';

const _indicators = ReflectivePauseIndicators(
  momentsPlayed: 10,
  controlledReactionTimeScore: 3,
  nonImpulsiveResponsesScore: 2,
  abilityToStepBackScore: 0.6,
  impulsiveChoiceCount: 5,
  averageResponseTimeMs: 5200,
  level: 'Good stress management',
);

EmotionalRadarV2Report _report({int scenes = 15}) => EmotionalRadarV2Report(
  totalScenes: scenes,
  startingLevel: 1,
  finalLevel: 2,
  levelTransitions: const ['1 → 2'],
  correctEmotions: scenes == 0 ? 0 : 10,
  emotionAccuracyPercent: scenes == 0 ? 0 : 66.7,
  accuracyByLevel: const {1: 75, 2: 50},
  accuracyByChoiceCount: const {6: 75, 9: 50},
  accuracyBySemanticDistance: const {},
  semanticDistanceScoringAvailable: false,
  semanticProximityErrorScore: 0,
  intensityMatchPercent: scenes == 0 ? 0 : 60,
  intensityErrorDirection: scenes == 0
      ? const {}
      : const {'Sur-estimée': 3, 'Correcte': 9, 'Sous-estimée': 3},
  accuracyByStimulusIntensity: const {'Faible': 80, 'Intense': 70},
  stimulusTypePerformance: const {},
  stimulusTypeScoringAvailable: false,
  justificationScoringAvailable: false,
  averageResponseTimeMs: 5200,
  impulsiveResponsesPercent: 20,
  radarEmotionScore: 7,
  emotionalLevel: 'Good emotional recognition',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in [
      'xyz.luan/audioplayers',
      'xyz.luan/audioplayers.global',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(channel),
        (_) async => null,
      );
    }
    for (final channel in [
      'xyz.luan/audioplayers.global/events',
      'xyz.luan/audioplayers/events/zennyt-bg-music',
      'xyz.luan/audioplayers/events/zennyt-scoreboard',
    ]) {
      messenger.setMockStreamHandler(
        EventChannel(channel),
        _SilentStreamHandler(),
      );
    }
    SoundService.instance.setSfxEnabled(false);
    SoundService.instance.setMusicEnabled(false);
  });

  Future<void> show(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(390, 844),
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(scale),
          ),
          child: RepaintBoundary(
            key: const ValueKey('insights-capture'),
            child: Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(child: child),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Widget choices({
    bool enabled = true,
    bool selected = false,
    bool mixed = false,
    VoidCallback? onTap,
  }) => Padding(
    padding: const EdgeInsets.all(20),
    child: GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 2.1,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        for (final strategy in StrategicChoiceStrategy.values)
          StrategicChoiceCard(
            strategy: strategy,
            enabled: mixed
                ? strategy != StrategicChoiceStrategy.directAction
                : enabled,
            selected: mixed
                ? strategy == StrategicChoiceStrategy.breathePause
                : selected,
            onTap: onTap ?? () {},
          ),
      ],
    ),
  );

  testWidgets(
    'huit icônes distinctes restent visibles sous verrouillage et sélection',
    (tester) async {
      var taps = 0;
      for (final state in [
        (enabled: false, selected: false),
        (enabled: true, selected: false),
        (enabled: true, selected: true),
      ]) {
        await show(
          tester,
          choices(
            enabled: state.enabled,
            selected: state.selected,
            onTap: () => taps++,
          ),
        );
        final icons = <AppIconData>{};
        for (final strategy in StrategicChoiceStrategy.values) {
          final icon = find.byKey(ValueKey('strategic-icon-${strategy.name}'));
          expect(icon, findsOneWidget);
          icons.add(tester.widget<AppIcon>(icon).icon!);
        }
        expect(icons, hasLength(8));
        final before = taps;
        await tester.tap(
          find.byKey(const ValueKey('strategic-choice-breathePause')),
        );
        expect(taps, before + (state.enabled ? 1 : 0));
      }
    },
  );

  testWidgets('capture des choix avec icône et indicateur d’état séparés', (
    tester,
  ) async {
    await show(tester, choices(mixed: true));
    await expectLater(
      find.byKey(const ValueKey('insights-capture')),
      matchesGoldenFile('goldens/strategic-choice-icons.png'),
    );
  });

  testWidgets(
    'insights Reflective : valeurs serveur et maxima 3/4/3 conservés',
    (tester) async {
      await show(
        tester,
        ReflectivePauseInsightsView(
          indicators: _indicators,
          onBack: () {},
          onFinish: () {},
        ),
      );
      final meters = tester
          .widgetList<GameResultInsightMeter>(
            find.byType(GameResultInsightMeter),
          )
          .toList();
      expect(meters.map((meter) => meter.valueLabel), [
        '3 / 3',
        '2 / 4',
        '0.6 / 3',
      ]);
      expect(meters.map((meter) => meter.bar.fraction), [
        1,
        0.5,
        closeTo(0.2, 0.001),
      ]);
      expect(find.text('Strongest area'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('insights-capture')),
        matchesGoldenFile('goldens/reflective-pause-insights.png'),
      );
    },
  );

  testWidgets('sans indicateurs, aucun faux point fort ni jauge à zéro', (
    tester,
  ) async {
    await show(
      tester,
      ReflectivePauseInsightsView(
        indicators: null,
        onBack: () {},
        onFinish: () {},
      ),
    );
    expect(find.byType(GameResultInsightMeter), findsNothing);
    expect(find.text('Strongest area'), findsNothing);
    expect(find.textContaining('No insights available'), findsOneWidget);
  });

  testWidgets(
    'insights à 200 % sur petit écran, contenu défilant et action accessible',
    (tester) async {
      await show(
        tester,
        ReflectivePauseInsightsView(
          indicators: _indicators,
          onBack: () {},
          onFinish: () {},
        ),
        size: const Size(360, 640),
        scale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Back to games').hitTestable(), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Recommendation'),
        350,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Recommendation'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Radar : intensité sous-estimée, correcte, surestimée selon le rapport',
    (tester) async {
      await show(
        tester,
        EmotionalRadarResultsView(
          report: _report(),
          scoringProvisional: true,
          mediaLibraryReady: false,
          onReplay: () {},
        ),
      );
      final meters = tester
          .widgetList<GameResultInsightMeter>(
            find.byType(GameResultInsightMeter),
          )
          .toList();
      expect(meters.map((meter) => meter.bar.label), [
        'Sous-estimée : 3 / 15',
        'Correcte : 9 / 15',
        'Sur-estimée : 3 / 15',
      ]);
      expect(meters.map((meter) => meter.bar.fraction), [0.2, 0.6, 0.2]);
      expect(find.text('Évaluation de l’intensité'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('insights-capture')),
        matchesGoldenFile('goldens/emotional-radar-intensity-insights.png'),
      );
    },
  );

  testWidgets(
    'jauge commune : mouvement réduit, valeur exacte dès la première image',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: GameResultInsightMeter(
                compact: false,
                bar: GameResultInsightBar(label: 'Mesure', fraction: 0.7),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        0.7,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'rapport vide : pas de division par zéro ou de répartition inventée',
    (tester) async {
      await show(
        tester,
        EmotionalRadarResultsView(
          report: _report(scenes: 0),
          scoringProvisional: false,
          mediaLibraryReady: true,
          onReplay: () {},
        ),
      );
      expect(find.byType(GameResultInsightMeter), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

class _SilentStreamHandler extends MockStreamHandler {
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {}
  @override
  void onCancel(Object? arguments) {}
}
