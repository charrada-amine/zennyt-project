import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/core/audio/sound_service.dart';
import 'package:zennyt/features/games/data/games_mock_repository.dart';
import 'package:zennyt/features/games/domain/config/memory_quest_config.dart';
import 'package:zennyt/features/games/domain/entities/memory_object.dart';
import 'package:zennyt/features/games/presentation/games_providers.dart';
import 'package:zennyt/features/games/presentation/view/investigate_screen.dart';
import 'package:zennyt/features/games/presentation/view/move_fast_screen.dart';
import 'package:zennyt/features/games/presentation/widgets/game_system_components.dart';

/// Captures d'écran des états touchés par les retours client.
///
/// Ce fichier ne teste pas un comportement : il **fige une image** de chaque
/// écran modifié, sur un grand et un petit gabarit, pour que la revue visuelle
/// se fasse sur des captures réelles plutôt que sur du code.
///
/// Régénérer après un changement d'UI assumé :
///   flutter test test/features/games/presentation/feedback_screenshots_test.dart \
///     --update-goldens
///
/// Les images atterrissent dans `test/features/games/presentation/goldens/`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Le menu pause lit SoundService.instance, dont les champs construisent des
  // AudioPlayer : sans plugin natif, le canal jette et fait échouer la capture.
  // On répond « rien » à audioplayers — aucune capture ne dépend du son.
  setUpAll(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in const [
      MethodChannel('xyz.luan/audioplayers'),
      MethodChannel('xyz.luan/audioplayers.global'),
      MethodChannel('flutter_tts'),
    ]) {
      messenger.setMockMethodCallHandler(channel, (_) async => null);
    }
    // audioplayers ouvre aussi un EventChannel par lecteur : les identifiants
    // sont ceux fixés dans SoundService (+ le canal global).
    for (final name in const [
      'xyz.luan/audioplayers.global/events',
      'xyz.luan/audioplayers/events/zennyt-bg-music',
      'xyz.luan/audioplayers/events/zennyt-scoreboard',
    ]) {
      messenger.setMockStreamHandler(
        EventChannel(name),
        _SilentStreamHandler(),
      );
    }
    // Chaque SFX ouvre un AudioPlayer JETABLE dont l'identifiant est un UUID :
    // ses canaux d'événements ne peuvent pas être enregistrés à l'avance. On
    // coupe donc les effets — `playSfx` sort alors avant de créer le lecteur.
    // Aucune capture ne dépend du son.
    SoundService.instance.setSfxEnabled(false);
    SoundService.instance.setMusicEnabled(false);
  });

  /// Gabarits de capture : le grand est celui des maquettes, le petit est le
  /// plus petit écran encore supporté (iPhone SE 1ʳᵉ génération).
  const large = Size(390, 844);
  const small = Size(320, 568);

  Future<void> sized(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  /// Amène la cible à l'écran avant de taper : sur un gabarit téléphone, les
  /// boutons de bas de page sortent souvent du viewport.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder, warnIfMissed: false);
    await tester.pump();
  }

  Future<void> shoot(WidgetTester tester, String name) async {
    // Les `Image.asset` se décodent de façon asynchrone : sous l'horloge
    // simulée des tests, elles restent vides et la capture perd justement ce
    // qu'on veut relire. [runAsync] rend la main au vrai event loop le temps
    // de précharger chaque image affichée.
    await tester.runAsync(() async {
      // Contexte pris sur la racine : `find.byType(Image)` en désigne plusieurs
      // et `tester.element` exige un résultat unique.
      final context = tester.element(find.byType(MaterialApp));
      for (final image in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(image.image, context);
      }
    });
    // `pump` et non `pumpAndSettle` : le plateau de « Je bouge » fait boucler
    // ses avions en permanence, donc l'arbre n'atteint jamais le repos.
    await tester.pump();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  // ── « Je bouge » : libellés sous les boutons directionnels ────────────────
  //
  // Le retour demandait le texte sous chaque bouton, en petite taille. La croix
  // est capturée seule : c'est le composant partagé, et l'isoler évite de faire
  // dépendre la capture du hasard d'une manche jouée.
  for (final entry in {'large': large, 'small': small}.entries) {
    testWidgets('capture — croix directionnelle Je bouge (${entry.key})',
        (tester) async {
      await sized(tester, entry.value);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: ZennytGamePalette.gameBlue,
            body: Center(
              child: GameDirectionControls(onDirection: (_) {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await shoot(tester, 'je-bouge-dpad-${entry.key}');
    });
  }

  // ── Menu pause partagé (référence « 11 Pause Overlay ») ───────────────────
  testWidgets('capture — menu pause partagé', (tester) async {
    await sized(tester, small);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: ZennytGamePalette.blue,
          body: GamePauseScaffold(
            inputMode: GamePauseInputModeToggle(
              buttonsSelected: true,
              onChanged: (_) {},
            ),
            buttons: [
              GamePrimaryButton(label: 'Resume', onPressed: () {}),
              GameOutlineButton(
                label: 'View rules / Help',
                onPressed: () {},
              ),
              GamePauseExitButton(onPressed: () {}),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await shoot(tester, 'menu-pause-small');
  });

  // ── « Je bouge » : écran d'intro (mode d'entrée + HUD) ────────────────────
  testWidgets('capture — Je bouge intro (small)', (tester) async {
    await sized(tester, small);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gamesRepositoryProvider.overrideWithValue(GamesMockRepository()),
        ],
        child: const MaterialApp(home: MoveFastScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await shoot(tester, 'je-bouge-intro-small');
  });

  // ── « Je bouge » : mode tactile, consigne puis plateau nu ─────────────────
  //
  // Maquettes « 04B Gameplay Waiting – Tactile » (flèches + libellé) puis
  // « 04C Gameplay – Tactile Mode » (plateau nu). La consigne doit s'effacer
  // à la première réponse donnée au doigt.
  testWidgets('capture — Je bouge mode tactile (consigne puis plateau)',
      (tester) async {
    await sized(tester, large);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gamesRepositoryProvider.overrideWithValue(GamesMockRepository()),
        ],
        // Graine fixe : sans elle les avions sont tirés au hasard et la
        // capture de référence ne peut jamais être recomparée.
        child: const MaterialApp(home: MoveFastScreen(seed: 4242)),
      ),
    );
    await tester.pumpAndSettle();

    // Une fois en jeu, les avions bouclent : on avance par pas fixes plutôt
    // que d'attendre un repos qui n'arrive jamais.
    Future<void> settle() async {
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
    }

    // Intro → les deux écrans de tutoriel attendent la direction « droite ».
    await tapVisible(tester, find.text('Start'));
    await settle();
    // Les libellés ajoutés sous les flèches servent aussi de prise de test.
    await tapVisible(tester, find.text('Right'));
    await settle();
    await tapVisible(tester, find.text('Right'));
    await settle();

    // Bascule en tactile via le menu pause.
    await tapVisible(tester, find.byTooltip('Mettre en pause'));
    await settle();
    await tapVisible(tester, find.text('Tactile'));
    await settle();
    await tapVisible(tester, find.text('Resume'));
    await settle();

    expect(find.text('Tactile mode'), findsOneWidget);
    await shoot(tester, 'je-bouge-tactile-consigne');

    // Une réponse au doigt : appui franc hors de la zone morte centrale.
    final board = tester.getRect(find.byType(GameHud));
    await tester.tapAt(Offset(board.center.dx, board.bottom + 180));
    await settle();

    expect(find.text('Tactile mode'), findsNothing);
    await shoot(tester, 'je-bouge-tactile-plateau');

    // Ménage de fin. La réponse a armé un `Future.delayed` de 650 ms (feedback
    // → stimulus suivant) qu'aucun `dispose` n'annule : on le laisse échoir.
    // Ensuite seulement on démonte l'arbre, ce qui annule le Timer.periodic de
    // la session — sans quoi le teardown échoue sur un timer en vol.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  // ── « J'investigue » : restauration côte à côte, cartes réduites ──────────
  //
  // Pilote le jeu jusqu'à la phase « Restore the STARTING order » — la seule où
  // les emplacements et la réserve coexistent, donc la seule que le passage en
  // côte à côte modifie.
  for (final entry in {'large': large, 'small': small}.entries) {
    testWidgets("capture — J'investigue restauration (${entry.key})",
        (tester) async {
      await sized(tester, entry.value);

      const seed = 12345;
      final r = math.Random(seed);
      final level1Seq = List<int>.generate(
        MemoryQuestConfig.sequenceLengthForLevel(1),
        (_) => r.nextInt(10),
      );

      List<MemoryObject> initialObjects = const [];
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: InvestigateScreen(
              seed: seed,
              onMissionBReady: (order) => initialObjects = order,
            ),
          ),
        ),
      );

      await tapVisible(tester, find.text('Start mission'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('I am ready'));

      // Observation des chiffres, puis les deux rappels (même ordre / inverse).
      await tester.pump(const Duration(milliseconds: 6300));

      for (final d in level1Seq) {
        await tapVisible(tester, find.byKey(ValueKey('kp-$d')));
      }
      await tapVisible(tester, find.text('Validate'));
      for (final d in level1Seq.reversed) {
        await tapVisible(tester, find.byKey(ValueKey('kp-$d')));
      }
      await tapVisible(tester, find.text('Validate'));

      // Feedback → mission B : observation, manipulations, rétention.
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 5200));
      await tester.pump(const Duration(milliseconds: 6200));
      expect(find.text('Restore the STARTING order'), findsOneWidget);
      expect(initialObjects, isNotEmpty);

      await shoot(tester, 'j-investigue-restore-${entry.key}');

      // Un objet posé : montre l'emplacement rempli ET la réserve amputée,
      // côte à côte. `tapVisible` fait défiler jusqu'à la tuile : sur le petit
      // gabarit la réserve peut tomber sous la ligne de flottaison, et un `tap`
      // brut viserait alors hors de l'écran.
      await tapVisible(tester, find.text(initialObjects.first.labelEn).first);
      await shoot(tester, 'j-investigue-restore-${entry.key}-place');
    });
  }
}

/// Flux d'événements audio vide : le lecteur s'abonne, rien n'arrive, aucune
/// `MissingPluginException` ne fait échouer la capture.
class _SilentStreamHandler extends MockStreamHandler {
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {}

  @override
  void onCancel(Object? arguments) {}
}
