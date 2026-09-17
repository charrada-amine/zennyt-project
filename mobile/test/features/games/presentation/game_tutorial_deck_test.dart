import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/core/audio/sound_service.dart';
import 'package:zennyt/features/games/presentation/widgets/game_tutorial_deck.dart';

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

  Future<void> showDeck(
    WidgetTester tester, {
    VoidCallback? onComplete,
    Size size = const Size(390, 844),
    double scale = 1,
    bool reducedMotion = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(scale),
                disableAnimations: reducedMotion,
              ),
              child: GameTutorialDeck(
                leading: const BackButton(),
                onComplete: onComplete ?? () {},
                steps: List.generate(
                  3,
                  (index) => GameTutorialStep(
                    title: 'Action ${index + 1}',
                    description:
                        'Une courte explication pour comprendre '
                        'cette action et savoir quoi faire.',
                    illustrationLabel: 'Schéma de l’action ${index + 1}',
                    illustration: const Icon(
                      Icons.touch_app_outlined,
                      size: 64,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'balayage, retour et validation uniquement sur la dernière carte',
    (tester) async {
      var completions = 0;
      await showDeck(tester, onComplete: () => completions++);
      expect(find.text('Étape 1 sur 3'), findsOneWidget);
      expect(find.text('Je suis prêt'), findsNothing);
      await tester.drag(find.byType(PageView), const Offset(-320, 0));
      await tester.pumpAndSettle();
      expect(find.text('Étape 2 sur 3'), findsOneWidget);
      await tester.tap(find.byTooltip('Carte précédente'));
      await tester.pumpAndSettle();
      expect(find.text('Étape 1 sur 3'), findsOneWidget);
      expect(completions, 0);
      for (var page = 0; page < 2; page++) {
        await tester.tap(find.text('Suivant'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Étape 3 sur 3'), findsOneWidget);
      expect(find.text('Suivant'), findsNothing);
      await tester.tap(find.text('Je suis prêt'));
      expect(completions, 1);
    },
  );

  testWidgets('navigation immédiate lorsque les animations sont désactivées', (
    tester,
  ) async {
    await showDeck(tester, reducedMotion: true);
    await tester.tap(find.text('Suivant'));
    await tester.pump();
    expect(find.text('Étape 2 sur 3'), findsOneWidget);
    // L'étape change en une image, sans attendre les 240 ms du défilement.
    expect(find.text('Action 2'), findsOneWidget);
  });

  for (final size in [const Size(320, 568), const Size(568, 320)]) {
    testWidgets('texte agrandi sans débordement, contrôles accessibles $size', (
      tester,
    ) async {
      await showDeck(tester, size: size, scale: 2);
      expect(find.text('Suivant').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      final verticalScroll = find.descendant(
        of: find.byKey(const ValueKey('game-tutorial-card-0')),
        matching: find.byType(SingleChildScrollView),
      );
      await tester.drag(verticalScroll, const Offset(0, -250));
      await tester.pumpAndSettle();
      expect(find.text('Étape 1 sur 3'), findsOneWidget);
      expect(find.text('Suivant').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('une description sémantique du schéma et un repère d’étape', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await showDeck(tester);
    expect(find.bySemanticsLabel('Schéma de l’action 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Étape 1 sur 3'), findsOneWidget);
    expect(find.bySemanticsLabel('Schéma de l’action 3'), findsNothing);
    semantics.dispose();
  });
}

class _SilentStreamHandler extends MockStreamHandler {
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {}

  @override
  void onCancel(Object? arguments) {}
}
