import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/core/audio/sound_service.dart';
import 'package:zennyt/features/games/presentation/widgets/memory_quest_tutorial.dart';
import 'package:zennyt/features/games/domain/entities/memory_quest_metrics.dart';
import 'package:zennyt/features/games/domain/entities/memory_object.dart';

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
    MemoryQuestMode mode = MemoryQuestMode.digits,
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
                key: const ValueKey('memory-quest-tutorial-capture'),
                child: MemoryQuestTutorial(
                  mode: mode,
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

  for (final mode in [MemoryQuestMode.digits, MemoryQuestMode.images]) {
    final assets = mode == MemoryQuestMode.digits
        ? kMemoryDigitsTutorialAssets
        : kMemoryImagesTutorialAssets;
    group(mode.name, () {
      testWidgets(
        'les six illustrations sont déclarées et décodables dans le bundle',
        (tester) async {
          for (final path in assets) {
            expect(
              kMemoryObjectLibrary.map((object) => object.assetPath),
              isNot(contains(path)),
            );
            final bytes = await rootBundle.load(path);
            expect(bytes.lengthInBytes, greaterThan(0));
            await tester.runAsync(() async {
              final image = await decodeImageFromList(
                bytes.buffer.asUint8List(),
              );
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
          await showTutorial(
            tester,
            mode: mode,
            onComplete: () => completions++,
          );
          expect(find.text('Je suis prêt'), findsNothing);
          await tester.drag(find.byType(PageView), const Offset(-320, 0));
          await tester.pumpAndSettle();
          expect(find.text('Étape 2 sur 6'), findsOneWidget);
          await tester.tap(find.byTooltip('Carte précédente'));
          await tester.pumpAndSettle();
          expect(find.text('Étape 1 sur 6'), findsOneWidget);
          for (var page = 0; page < 5; page++) {
            await tester.tap(find.text('Suivant'));
            await tester.pumpAndSettle();
          }
          expect(completions, 0);
          await tester.tap(find.text('Je suis prêt'));
          expect(completions, 1);
        },
      );

      testWidgets(
        'texte à 200 % sur petit écran, commandes accessibles sur chaque carte',
        (tester) async {
          await showTutorial(
            tester,
            mode: mode,
            size: const Size(360, 600),
            scale: 2,
            reviewing: true,
          );
          for (var page = 0; page < 6; page++) {
            final label = page == 5 ? 'Retour au menu pause' : 'Suivant';
            expect(tester.getRect(find.text(label)).bottom, lessThan(600));
            expect(tester.takeException(), isNull);
            if (page < 5) {
              await tester.tap(find.text(label));
              await tester.pumpAndSettle();
            }
          }
          expect(find.text('Je suis prêt'), findsNothing);
        },
      );

      testWidgets(
        'six cartes illustrées, captures avec images réellement chargées',
        (tester) async {
          await showTutorial(tester, mode: mode);
          final context = tester.element(find.byType(MemoryQuestTutorial));
          for (var page = 0; page < 6; page++) {
            await tester.runAsync(() async {
              final provider = tester
                  .widget<Image>(find.byKey(ValueKey(assets[page])))
                  .image;
              await precacheImage(provider, context);
            });
            await tester.pumpAndSettle();
            expect(
              tester
                  .widget<RawImage>(
                    find.descendant(
                      of: find.byKey(ValueKey(assets[page])),
                      matching: find.byType(RawImage),
                    ),
                  )
                  .image,
              isNotNull,
            );
            await expectLater(
              find.byKey(const ValueKey('memory-quest-tutorial-capture')),
              matchesGoldenFile(
                'goldens/memory-quest-${mode.name}-tutorial-${page + 1}.png',
              ),
            );
            if (page < 5) {
              await tester.tap(find.text('Suivant'));
              await tester.pumpAndSettle();
            }
          }
        },
      );
    });
  }
  testWidgets(
    'le parcours historique explique les deux missions sans démarrer',
    (tester) async {
      var completions = 0;
      await showTutorial(
        tester,
        mode: MemoryQuestMode.full,
        onComplete: () => completions++,
      );
      expect(find.text('Étape 1 sur 10'), findsOneWidget);
      for (var page = 0; page < 9; page++) {
        await tester.tap(find.text('Suivant'));
        await tester.pumpAndSettle();
        expect(find.text('Résiste à l’interruption'), findsNothing);
      }
      expect(completions, 0);
      expect(find.text('Progresse dans les deux missions'), findsOneWidget);
      await tester.tap(find.text('Je suis prêt'));
      expect(completions, 1);
    },
  );
}

class _SilentStreamHandler extends MockStreamHandler {
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {}
  @override
  void onCancel(Object? arguments) {}
}
