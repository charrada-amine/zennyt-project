import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/core/audio/sound_service.dart';
import 'package:zennyt/features/games/presentation/widgets/je_decide_tutorial.dart';

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
                key: const ValueKey('je-decide-tutorial-capture'),
                child: JeDecideTutorial(
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
    'les trois illustrations sont déclarées et décodables dans le bundle',
    (tester) async {
      for (final path in kJeDecideTutorialAssets) {
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
      expect(kJeDecideTutorialAssets, hasLength(3));
      expect(find.text('Lis, puis choisis'), findsOneWidget);
      expect(find.text('Essayer l’exemple'), findsNothing);
      await tester.drag(find.byType(PageView), const Offset(-320, 0));
      await tester.pumpAndSettle();
      expect(find.text('Étape 2 sur 3'), findsOneWidget);
      await tester.tap(find.byTooltip('Carte précédente'));
      await tester.pumpAndSettle();
      expect(find.text('Étape 1 sur 3'), findsOneWidget);
      for (var page = 0; page < 2; page++) {
        await tester.tap(find.text('Suivant'));
        await tester.pumpAndSettle();
      }
      expect(completions, 0);
      await tester.tap(find.text('Essayer l’exemple'));
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
      for (var page = 0; page < 3; page++) {
        final label = page == 2 ? 'Reprendre la partie' : 'Suivant';
        expect(tester.getRect(find.text(label)).bottom, lessThan(600));
        expect(tester.takeException(), isNull);
        if (page < 2) {
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
        }
      }
      expect(find.text('Essayer l’exemple'), findsNothing);
    },
  );

  testWidgets(
    'trois cartes illustrées, captures avec images réellement chargées',
    (tester) async {
      await showTutorial(tester);
      final context = tester.element(find.byType(JeDecideTutorial));
      for (var page = 0; page < 3; page++) {
        await tester.runAsync(() async {
          final provider = tester
              .widget<Image>(
                find.byKey(ValueKey('je-decide-tutorial-image-$page')),
              )
              .image;
          await precacheImage(provider, context);
        });
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<RawImage>(
                find.descendant(
                  of: find.byKey(ValueKey('je-decide-tutorial-image-$page')),
                  matching: find.byType(RawImage),
                ),
              )
              .image,
          isNotNull,
        );
        await expectLater(
          find.byKey(const ValueKey('je-decide-tutorial-capture')),
          matchesGoldenFile('goldens/je-decide-tutorial-${page + 1}.png'),
        );
        if (page < 2) {
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
