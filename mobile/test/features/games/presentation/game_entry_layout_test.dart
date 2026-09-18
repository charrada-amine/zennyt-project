import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zennyt/core/audio/sound_service.dart';
import 'package:zennyt/core/storage/shared_preferences_provider.dart';
import 'package:zennyt/features/auth/presentation/current_user_provider.dart';
import 'package:zennyt/features/games/data/demo_games_repository.dart';
import 'package:zennyt/features/games/data/reflective_pause_bank_loader.dart';
import 'package:zennyt/features/games/data/strategic_choices_bank_loader.dart';
import 'package:zennyt/features/games/presentation/games_providers.dart';
import 'package:zennyt/features/games/presentation/widgets/game_system_components.dart';
import 'package:zennyt/features/games/presentation/view/emotional_radar_screen.dart';
import 'package:zennyt/features/games/presentation/view/investigate_screen.dart';
import 'package:zennyt/features/games/presentation/view/je_decide_screen.dart';
import 'package:zennyt/features/games/presentation/view/planifik_screen.dart';
import 'package:zennyt/features/games/presentation/view/predictive_puzzle_screen.dart';
import 'package:zennyt/features/games/presentation/view/reflective_pause_screen.dart';
import 'package:zennyt/features/games/presentation/view/strategic_choices_screen.dart';
import 'package:zennyt/features/navigation/presentation/widgets/app_bottom_nav.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences preferences;
  setUpAll(() async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in [
      'xyz.luan/audioplayers',
      'xyz.luan/audioplayers.global',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(name),
        (_) async => null,
      );
    }
    for (final name in [
      'xyz.luan/audioplayers.global/events',
      'xyz.luan/audioplayers/events/zennyt-bg-music',
      'xyz.luan/audioplayers/events/zennyt-scoreboard',
    ]) {
      messenger.setMockStreamHandler(
        EventChannel(name),
        _SilentStreamHandler(),
      );
    }
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    await ReflectivePauseBankLoader.load();
    await StrategicChoicesBankLoader.load();
    SoundService.instance.setSfxEnabled(false);
    SoundService.instance.setMusicEnabled(false);
  });

  const entries = <(String, Widget, String, String)>[
    (
      'memory-digits',
      InvestigateScreen(mode: InvestigateMode.digits),
      'Memory Quest · Digits',
      'Start mission',
    ),
    (
      'memory-images',
      InvestigateScreen(mode: InvestigateMode.images),
      'Memory Quest · Images',
      'Start mission',
    ),
    ('je-decide', JeDecideScreen(), 'Je Décide', 'Commencer'),
    ('optimal-path', PlanifikScreen(), 'Optimal Path', 'Start'),
    (
      'predictive-puzzle',
      PredictivePuzzleScreen(),
      'Predictive Puzzle',
      'Start',
    ),
    (
      'emotional-radar',
      EmotionalRadarScreen(),
      'Emotional Radar',
      'Start tutorial',
    ),
    (
      'reflective-pause',
      ReflectivePauseScreen(),
      'Reflective Pause',
      'Start mission',
    ),
    (
      'strategic-choices',
      StrategicChoicesScreen(),
      'Strategic Choices',
      'Start mission',
    ),
  ];

  for (final (id, screen, title, button) in entries) {
    for (final (size, scale) in const [
      (Size(360, 800), 1.0), // Capture Android 720×1600, densité 2.
      (Size(360, 640), 1.0),
      (Size(320, 568), 1.0),
      (Size(360, 800), 2.0),
    ]) {
      testWidgets('$id : $size texte $scale, titre et bouton accessibles', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              gamesRepositoryProvider.overrideWithValue(DemoGamesRepository()),
              sharedPreferencesProvider.overrideWithValue(preferences),
              currentUserProvider.overrideWithValue(null),
            ],
            child: MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  padding: const EdgeInsets.only(top: 24, bottom: 48),
                  textScaler: TextScaler.linear(scale),
                ),
                child: RepaintBoundary(
                  key: const ValueKey('entry-capture'),
                  child: screen,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(AppBottomNav), findsNothing);
        final text = find.text(title);
        expect(text, findsOneWidget);
        expect(
          tester.renderObject<RenderParagraph>(text).didExceedMaxLines,
          isFalse,
        );
        final start = find.text(button);
        expect(start, findsOneWidget);
        expect(
          tester.getRect(find.byType(GamePrimaryButton)).top -
              tester
                  .getRect(find.byKey(const ValueKey('welcome-journey')))
                  .bottom,
          inInclusiveRange(8, 20),
          reason: 'le bouton reste proche des repères du parcours',
        );
        final scrollables = tester.stateList<ScrollableState>(
          find.byType(Scrollable),
        );
        if (scale == 1) {
          for (final scroll in scrollables) {
            expect(
              scroll.position.maxScrollExtent,
              closeTo(0, 0.5),
              reason: 'accueil complet sans défilement',
            );
          }
          expect(start.hitTestable(), findsOneWidget);
          final rect = tester.getRect(start);
          expect(rect.bottom, lessThanOrEqualTo(size.height - 48));
        } else {
          // Un unique défilement de page est autorisé pour le texte agrandi.
          await tester.ensureVisible(start);
          await tester.pumpAndSettle();
          expect(start.hitTestable(), findsOneWidget);
        }
        if (size == const Size(360, 800) && scale == 1) {
          for (final image in tester.widgetList<Image>(find.byType(Image))) {
            await tester.runAsync(
              () => precacheImage(
                image.image,
                tester.element(find.byType(Image).first),
              ),
            );
          }
          await tester.pumpAndSettle();
          await expectLater(
            find.byKey(const ValueKey('entry-capture')),
            matchesGoldenFile('goldens/entry-$id.png'),
          );
        }
        await tester.tap(start);
        await tester.pumpAndSettle();
        expect(find.byType(AppBottomNav), findsNothing);
        if (id == 'strategic-choices') {
          expect(find.text('Comment jouer'), findsOneWidget);
          expect(find.text('Train the pause before action'), findsNothing);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}

class _SilentStreamHandler extends MockStreamHandler {
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {}
  @override
  void onCancel(Object? arguments) {}
}
