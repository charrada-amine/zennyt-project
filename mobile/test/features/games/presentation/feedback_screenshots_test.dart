import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zennyt/core/audio/sound_service.dart';
import 'package:zennyt/features/games/data/games_mock_repository.dart';
import 'package:zennyt/features/games/domain/config/memory_quest_config.dart';
import 'package:zennyt/features/games/domain/entities/decision_form.dart';
import 'package:zennyt/features/games/domain/entities/decision_metrics.dart';
import 'package:zennyt/features/games/domain/entities/memory_object.dart';
import 'package:zennyt/features/games/presentation/games_providers.dart';
import 'package:zennyt/features/games/presentation/view/investigate_screen.dart';
import 'package:zennyt/features/games/presentation/view/je_decide_gameplay.dart';
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
    testWidgets('capture — croix directionnelle Je bouge (${entry.key})', (
      tester,
    ) async {
      await sized(tester, entry.value);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: ZennytGamePalette.gameBlue,
            body: Center(child: GameDirectionControls(onDirection: (_) {})),
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
            actions: [
              GamePauseMenuAction.resume(onPressed: () {}),
              GamePauseMenuAction.rules(onPressed: () {}),
              GamePauseMenuAction.exit(onPressed: () {}),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await shoot(tester, 'menu-pause-small');
  });

  // ── Nouvelles règles de pause (CdC « Harmonisation ») ─────────────────────
  //
  // Deux captures à montrer au client : la fenêtre unique avec son compte à
  // rebours de 30 s, puis la confirmation qui prévient qu'une sortie annule la
  // tentative.
  testWidgets('capture — menu pause avec compte à rebours 30 s', (
    tester,
  ) async {
    await sized(tester, small);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: ZennytGamePalette.blue,
          body: GamePauseScaffold(
            countdown: kGamePauseWindow,
            inputMode: GamePauseInputModeToggle(
              buttonsSelected: true,
              onChanged: (_) {},
            ),
            actions: [
              GamePauseMenuAction.resume(onPressed: () {}),
              GamePauseMenuAction.rules(onPressed: () {}),
              GamePauseMenuAction.exit(onPressed: () {}),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await shoot(tester, 'menu-pause-compte-a-rebours');
  });

  testWidgets('capture — confirmation avant Quitter la mission', (tester) async {
    await sized(tester, small);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: ZennytGamePalette.blue,
          body: GameExitConfirmDialog(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await shoot(tester, 'confirmation-exit-mission');
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
  testWidgets('capture — Je bouge mode tactile (consigne puis plateau)', (
    tester,
  ) async {
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
    await tapVisible(tester, find.text('Commencer'));
    await settle();
    // Les libellés ajoutés sous les flèches servent aussi de prise de test.
    await tapVisible(tester, find.text('Droite'));
    await settle();
    await tapVisible(tester, find.text('Droite'));
    await settle();

    // Bascule en tactile via le menu pause.
    // « Pause » et non plus « Mettre en pause » : l'infobulle était le dernier
    // libellé français d'une interface entièrement anglaise, et elle vient d'un
    // enum partagé qui porte aussi « Quitter la mission ».
    await tapVisible(tester, find.byTooltip('Pause'));
    await settle();
    await tapVisible(tester, find.text('Tactile'));
    await settle();
    await tapVisible(tester, find.text('Reprendre'));
    await settle();

    expect(find.text('Tactile mode'), findsOneWidget);
    await shoot(tester, 'je-bouge-tactile-consigne');

    // Une réponse au doigt : appui franc hors de la zone morte centrale.
    final board = tester.getRect(find.byType(GameHud));
    await tester.tapAt(Offset(board.center.dx, board.bottom + 180));
    await settle();

    expect(find.text('Tactile mode'), findsNothing);
    await shoot(tester, 'je-bouge-tactile-plateau');

    // Ménage de fin : le démontage annule toutes les minuteries de l'écran —
    // chrono de session, échéance de l'essai, passage à l'avion suivant.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  // ── « J'investigue » : restauration côte à côte, cartes réduites ──────────
  //
  // Pilote le jeu jusqu'à la phase « Retrouve l’ordre de DÉPART » — la seule où
  // les emplacements et la réserve coexistent, donc la seule que le passage en
  // côte à côte modifie.
  for (final entry in {'large': large, 'small': small}.entries) {
    testWidgets("capture — J'investigue restauration (${entry.key})", (
      tester,
    ) async {
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

      await tapVisible(tester, find.text('Commencer la mission'));
      await tester.pumpAndSettle();
      while (find.text('Suivant').evaluate().isNotEmpty) {
        await tapVisible(tester, find.text('Suivant'));
        await tester.pumpAndSettle();
      }
      await tapVisible(tester, find.text('Je suis prêt'));

      // Observation des chiffres, puis les deux rappels (même ordre / inverse).
      await tester.pump(const Duration(milliseconds: 6300));

      for (final d in level1Seq) {
        await tapVisible(tester, find.byKey(ValueKey('kp-$d')));
      }
      await tapVisible(tester, find.text('Valider'));
      for (final d in level1Seq.reversed) {
        await tapVisible(tester, find.byKey(ValueKey('kp-$d')));
      }
      await tapVisible(tester, find.text('Valider'));

      // Feedback → mission B : observation, manipulations, rétention.
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 5200));
      await tester.pump(const Duration(milliseconds: 6200));
      expect(find.text('Retrouve l’ordre de DÉPART'), findsOneWidget);
      expect(initialObjects, isNotEmpty);

      await shoot(tester, 'j-investigue-restore-${entry.key}');

      // Un objet classé : montre la pastille de rang et la carte mise en avant.
      // `tapVisible` fait défiler jusqu'à la carte : sur le petit gabarit la
      // grille peut tomber sous la ligne de flottaison, et un `tap` brut
      // viserait alors hors de l'écran.
      await tapVisible(tester, find.text(initialObjects.first.labelEn).first);
      await shoot(tester, 'j-investigue-restore-${entry.key}-place');
    });
  }

  // ── « Je décide » : mise en page selon la taille de l'écran ───────────────
  //
  // Retour client : « il faut adapter le UI selon la taille de l'écran afin que
  // le scénario et les choix s'affichent entièrement sans défilement ».
  //
  // Ces captures existent pour trancher à l'œil ce qu'aucun test ne dit : le
  // texte reste-t-il agréable à lire une fois compacté ? Elles montrent aussi la
  // limite honnête du travail — le dernier gabarit porte un item de la dimension
  // Intégration d'Information, qui ne tient sur aucun téléphone.
  group('Je décide — mise en page', () {
    /// Item représentatif : 240 caractères, deux options. C'est le profil des
    /// 66 items sur 96 qui doivent tenir partout.
    DecisionFormItem courant() => DecisionFormItem(
      itemId: 'CS-12b',
      dimension: DecisionDimension.cs,
      format: DecisionItemFormat.standard,
      vignette:
          'Une panne touche votre réseau. Plan A : 200 000 foyers sur 300 000 '
          'subiront une coupure de façon certaine. Plan B : 1 chance sur 3 '
          'qu\'aucun foyer ne subisse de coupure, 2 chances sur 3 que les '
          '300 000 la subissent.',
      task: 'Choisissez le Plan A ou le Plan B.',
      options: [
        DecisionFormOption(optionId: 'a', label: 'Plan / Option A'),
        DecisionFormOption(optionId: 'b', label: 'Plan / Option B'),
      ],
    );

    /// Le pire item réel de la banque : 1167 caractères, quatre justifications.
    DecisionFormItem long() => DecisionFormItem(
      itemId: 'II-18',
      dimension: DecisionDimension.ii,
      format: DecisionItemFormat.standard,
      vignette:
          'Vous choisissez un ordinateur portable pour un graphiste de votre '
          'équipe (travail sur logiciels de retouche photo et montage vidéo). '
          'Trois options : A (moins cher, RAM 8 Go, GPU intégré, performances '
          'insuffisantes pour le montage vidéo 4K), B (dans le budget, RAM 16 '
          'Go, GPU dédié 4 Go, compatible avec les logiciels métiers), C (cher, '
          'hors budget, RAM 32 Go, GPU dédié 8 Go, performances maximales). '
          'Budget plafonné ; performances compatibles avec les logiciels '
          'métiers obligatoires.',
      task:
          'Classez les trois options du plus au moins adapté, puis choisissez '
          'la justification qui reflète le mieux votre raisonnement.',
      options: [
        DecisionFormOption(
          optionId: 'a',
          label:
              'Je choisis B : le tarif est dans le budget et les '
              'spécifications (16 Go RAM, GPU 4 Go) sont suffisantes pour les '
              'logiciels de retouche et montage utilisés.',
        ),
        DecisionFormOption(
          optionId: 'b',
          label:
              'Je choisis B car les performances couvrent les besoins '
              'professionnels du graphiste.',
        ),
        DecisionFormOption(
          optionId: 'c',
          label:
              'Je choisis C : investir dans la meilleure configuration réduit '
              'les risques de lenteur.',
        ),
        DecisionFormOption(
          optionId: 'd',
          label:
              'Je choisis A car le design est plus léger, pratique pour les '
              'déplacements.',
        ),
      ],
    );

    Future<void> pumpScenario(
      WidgetTester tester,
      DecisionFormItem item,
      Size size,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await sized(tester, size);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DecisionGameplayView(
              form: DecisionForm(
                formCode: 'A',
                itemsPerDimension: 1,
                items: [item],
              ),
              onClose: () {},
              onComplete: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
    }

    // Quatre gabarits, du plus petit encore supporté au grand format courant.
    const gabarits = {
      '320': Size(320, 568),
      '360': Size(360, 740),
      '390': Size(390, 844),
      '412': Size(412, 915),
    };

    for (final entry in gabarits.entries) {
      testWidgets('capture — scénario courant (${entry.key})', (tester) async {
        await pumpScenario(tester, courant(), entry.value);
        await shoot(tester, 'je-decide-scenario-${entry.key}');
      });
    }

    for (final entry in {
      '320': gabarits['320']!,
      '412': gabarits['412']!,
    }.entries) {
      testWidgets('capture — scénario long, dimension II (${entry.key})', (
        tester,
      ) async {
        await pumpScenario(tester, long(), entry.value);
        await shoot(tester, 'je-decide-scenario-long-${entry.key}');
      });

      /// Second temps du même item : la consigne rappelée et les quatre choix,
      /// sans la situation. C'est l'écran que le découpage rend possible — et
      /// celui qu'il faut regarder pour juger si le rappel suffit à choisir.
      testWidgets('capture — scénario long, écran de choix (${entry.key})', (
        tester,
      ) async {
        await pumpScenario(tester, long(), entry.value);
        final reveal = find.byKey(const ValueKey('decision-reveal-choices'));
        if (reveal.evaluate().isNotEmpty) {
          await tester.tap(reveal);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
        }
        await shoot(tester, 'je-decide-scenario-long-choix-${entry.key}');
      });
    }
  });
}

/// Flux d'événements audio vide : le lecteur s'abonne, rien n'arrive, aucune
/// `MissingPluginException` ne fait échouer la capture.
class _SilentStreamHandler extends MockStreamHandler {
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {}

  @override
  void onCancel(Object? arguments) {}
}
