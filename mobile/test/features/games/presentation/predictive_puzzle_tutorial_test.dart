import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/core/audio/sound_service.dart';
import 'package:zennyt/features/games/data/games_mock_repository.dart';
import 'package:zennyt/features/games/domain/entities/game_session.dart';
import 'package:zennyt/features/games/domain/entities/game_type.dart';
import 'package:zennyt/features/games/presentation/games_providers.dart';
import 'package:zennyt/features/games/presentation/view/predictive_puzzle_screen.dart';

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
                key: const ValueKey('predictive-tutorial-capture'),
                child: PredictivePuzzleTutorial(
                  leading: const BackButton(),
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

  testWidgets('deux cartes, balayage et retour ; démarrage à la fin', (
    tester,
  ) async {
    var completions = 0;
    await showTutorial(tester, onComplete: () => completions++);
    expect(find.text('Étape 1 sur 2'), findsOneWidget);
    expect(find.text('Commencer à planifier'), findsNothing);
    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(find.text('Étape 2 sur 2'), findsOneWidget);
    expect(completions, 0);
    await tester.tap(find.byTooltip('Carte précédente'));
    await tester.pumpAndSettle();
    expect(find.text('Étape 1 sur 2'), findsOneWidget);
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commencer à planifier'));
    expect(completions, 1);
  });

  testWidgets('petit écran et texte à 200 %, boutons accessibles', (
    tester,
  ) async {
    await showTutorial(tester, size: const Size(360, 600), scale: 2);
    for (var page = 0; page < 2; page++) {
      final label = page == 0 ? 'Suivant' : 'Commencer à planifier';
      expect(tester.getRect(find.text(label)).bottom, lessThan(600));
      expect(tester.takeException(), isNull);
      if (page == 0) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
    }
  });

  testWidgets('captures des deux schémas natifs sans agrandissement du PNG', (
    tester,
  ) async {
    await showTutorial(tester);
    for (var page = 0; page < 2; page++) {
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('predictive-tutorial-capture')),
        matchesGoldenFile('goldens/predictive-puzzle-tutorial-${page + 1}.png'),
      );
      if (page == 0) {
        await tester.tap(find.text('Suivant'));
        await tester.pumpAndSettle();
      }
    }
  });

  testWidgets('parcours réel : une session seulement après les deux cartes', (
    tester,
  ) async {
    final repository = _CountingRepository();
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [gamesRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: PredictivePuzzleScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.text('Étape 1 sur 2'), findsOneWidget);
    expect(repository.starts, 0);
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.text('Étape 2 sur 2'), findsOneWidget);
    expect(repository.starts, 0);
    await tester.tap(find.text('Commencer à planifier'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(repository.starts, 1);
    expect(find.text('TOWER A'), findsOneWidget);
    expect(find.text('TOWER C'), findsOneWidget);
    expect(find.text('Add Move'), findsOneWidget);
    expect(find.byType(PredictivePuzzleTutorial), findsNothing);
    await tester.tap(find.text('TOWER A'));
    await tester.pump();
    await tester.tap(find.text('TOWER C'));
    await tester.pump();
    await tester.tap(find.text('Add Move'));
    await tester.pump();
    expect(find.textContaining('1/7 MOVES PLANNED'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _CountingRepository extends GamesMockRepository {
  int starts = 0;

  @override
  Future<GameSession> startSession(GameType gameType) {
    starts++;
    return super.startSession(gameType);
  }
}

class _SilentStreamHandler extends MockStreamHandler {
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {}
  @override
  void onCancel(Object? arguments) {}
}
