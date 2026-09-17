import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/core/audio/sound_service.dart';
import 'package:zennyt/features/games/presentation/widgets/reflective_pause_tutorial.dart';

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

  Future<void> showTutorial(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double scale = 1,
    bool reviewing = false,
    VoidCallback? onComplete,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(scale),
              ),
              child: RepaintBoundary(
                key: const ValueKey('reflective-tutorial-capture'),
                child: ReflectivePauseTutorial(
                  leading: const BackButton(),
                  reviewing: reviewing,
                  onComplete: onComplete ?? () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'les cinq illustrations sont déclarées et décodables dans le bundle',
    (tester) async {
      for (final path in kReflectivePauseTutorialAssets) {
        final bytes = await rootBundle.load(path);
        expect(bytes.lengthInBytes, greaterThan(0));
        await tester.runAsync(() async {
          final image = await decodeImageFromList(bytes.buffer.asUint8List());
          expect(image.width, greaterThan(0));
          expect(image.height, image.width);
          image.dispose();
        });
      }
    },
  );

  testWidgets(
    'balayage et précédent, démarrage uniquement après la dernière carte',
    (tester) async {
      var completions = 0;
      await showTutorial(tester, onComplete: () => completions++);
      expect(find.text('Commencer la partie'), findsNothing);
      await tester.drag(find.byType(PageView), const Offset(-320, 0));
      await tester.pumpAndSettle();
      expect(find.text('Étape 2 sur 5'), findsOneWidget);
      await tester.tap(find.byTooltip('Carte précédente'));
      await tester.pumpAndSettle();
      expect(find.text('Étape 1 sur 5'), findsOneWidget);
      for (var page = 0; page < 4; page++) {
        await tester.tap(find.text('Suivant'));
        await tester.pumpAndSettle();
      }
      expect(completions, 0);
      await tester.tap(find.text('Commencer la partie'));
      expect(completions, 1);
    },
  );

  testWidgets(
    'texte à 200 % sur petit écran, commandes accessibles sur chaque carte',
    (tester) async {
      await showTutorial(
        tester,
        size: const Size(360, 600),
        scale: 2,
        reviewing: true,
      );
      for (var page = 0; page < 5; page++) {
        final label = page == 4 ? 'Reprendre la partie' : 'Suivant';
        expect(tester.getRect(find.text(label)).bottom, lessThan(600));
        expect(tester.takeException(), isNull);
        if (page < 4) {
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
        }
      }
      expect(find.text('Commencer la partie'), findsNothing);
    },
  );

  testWidgets(
    'cinq cartes illustrées, captures avec images réellement chargées',
    (tester) async {
      await showTutorial(tester);
      final context = tester.element(find.byType(ReflectivePauseTutorial));
      for (var page = 0; page < 5; page++) {
        await tester.runAsync(() async {
          final provider = tester
              .widget<Image>(
                find.byKey(ValueKey('reflective-tutorial-image-$page')),
              )
              .image;
          await precacheImage(provider, context);
        });
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<RawImage>(
                find.descendant(
                  of: find.byKey(ValueKey('reflective-tutorial-image-$page')),
                  matching: find.byType(RawImage),
                ),
              )
              .image,
          isNotNull,
        );
        await expectLater(
          find.byKey(const ValueKey('reflective-tutorial-capture')),
          matchesGoldenFile(
            'goldens/reflective-pause-tutorial-${page + 1}.png',
          ),
        );
        if (page < 4) {
          await tester.tap(find.text('Suivant'));
          await tester.pumpAndSettle();
        }
      }
    },
  );
}

class _SilentStreamHandler extends MockStreamHandler {
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {}
  @override
  void onCancel(Object? arguments) {}
}
