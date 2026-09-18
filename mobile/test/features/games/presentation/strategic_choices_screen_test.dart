import 'package:zennyt/core/audio/sound_service.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zennyt/core/storage/shared_preferences_provider.dart';
import 'package:zennyt/features/auth/presentation/current_user_provider.dart';
import 'package:zennyt/features/games/data/strategic_choices_bank_loader.dart';
import 'package:zennyt/features/games/domain/config/strategic_choices_content.dart';
import 'package:zennyt/features/games/domain/entities/strategic_choices_bank.dart';
import 'package:zennyt/features/games/presentation/view/strategic_choices_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // La banque des 80 situations vient d'un asset : on la précharge une fois
  // pour que l'écran la retrouve en cache.
  late StrategicChoicesBank bank;
  setUpAll(() async {
    StrategicChoicesBankLoader.resetForTest();
    bank = await StrategicChoicesBankLoader.load();
  });

  Future<void> pumpGame(
    WidgetTester tester, {
    double textScale = 1,
    List<StrategicChoiceScenario>? scenarios,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    // Surface haute : la carte de situation porte désormais l'emplacement du
    // média et la description de scène du client, bien plus longue que les
    // phrases inventées d'avant. Sur 844 points, la bande d'état du bas sort du
    // cadre — et une liste paresseuse ne construit pas ce qu'elle n'affiche
    // pas, si bien que le test cherchait un texte qui n'existait pas encore.
    tester.view.physicalSize = const Size(390 * 3, 1500 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          currentUserProvider.overrideWithValue(null),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: StrategicChoicesScreen(
            reflectionDuration: const Duration(milliseconds: 300),
            savedTransitionDuration: const Duration(milliseconds: 10),
            scenariosForTesting: scenarios,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> revealScrollableText(WidgetTester tester, String label) async {
    final target = find.text(label);
    // La couverture défile ; le tutoriel se parcourt par cartes.
    // Les commandes restent accessibles sans défiler jusqu’à elles.
    for (
      var attempt = 0;
      attempt < 8 &&
          target.evaluate().isEmpty &&
          find.byType(Scrollable).evaluate().isNotEmpty;
      attempt++
    ) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -220));
      await tester.pump();
    }
    expect(target, findsOneWidget);
    await tester.ensureVisible(target);
    await tester.pump();
  }

  Future<void> tapScrollableText(WidgetTester tester, String label) async {
    await revealScrollableText(tester, label);
    await tester.tap(find.text(label));
  }

  Future<void> reachGameplay(WidgetTester tester) async {
    await tapScrollableText(tester, 'Commencer la mission');
    await tester.pumpAndSettle();
    for (var page = 0; page < 4; page++) {
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
    }
    await tapScrollableText(tester, 'Commencer la partie');
    await tester.pumpAndSettle();
  }

  Future<void> completeCurrentSituation(WidgetTester tester) async {
    final startReflection = find.byKey(
      const ValueKey('strategic-start-reflection'),
    );
    await tester.tap(startReflection);
    await tester.pump();

    final choice = find.byKey(const ValueKey('strategic-choice-breathePause'));
    await tester.tap(choice);
    await tester.pump(const Duration(milliseconds: 350));

    final validate = find.byKey(const ValueKey('strategic-validate'));
    await tester.tap(validate);
    await tester.pumpAndSettle();
  }

  test('les deux banques remplacent les dix situations inventées', () {
    // L'écran jouait dix situations écrites à la main en anglais
    // (STRATEGIC_01 à 10). Elles ne venaient pas du client.
    // 60 fiches du client + 20 situations de la proposition.
    expect(bank.scenarios, hasLength(80));
    expect(bank.scenarios.map((s) => s.id).toSet(), hasLength(80));
    expect(StrategicChoicesContent.strategies, hasLength(8));
    expect(kStrategicChoicesPerJourney, 10);
    expect(bank.byId('CS-001').title, 'La réunion interrompue');
  });

  testWidgets('cover, tutorial and purple PNG follow the supplied flow', (
    tester,
  ) async {
    await pumpGame(tester);

    expect(find.text('Strategic Choices'), findsOneWidget);
    expect(find.text('Emotional Regulation'), findsNothing);
    final logo = tester.widget<Image>(
      find.byKey(const ValueKey('strategic-purple-logo')),
    );
    expect(logo.image, isA<AssetImage>());
    expect(
      (logo.image as AssetImage).assetName,
      'assets/games icons/Strategic Choices Purple.png',
    );

    await tapScrollableText(tester, 'Commencer la mission');
    await tester.pumpAndSettle();
    expect(find.text('Train the pause before action'), findsNothing);
    expect(find.text('Comment jouer'), findsOneWidget);
    expect(find.text('Lis la situation'), findsOneWidget);
    expect(
      find.textContaining('vidéos sont encore en préparation'),
      findsOneWidget,
    );
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Lancer la réflexion'), findsOneWidget);
    expect(find.textContaining('choisir pendant'), findsOneWidget);
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.textContaining('8 stratégies'), findsOneWidget);
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.textContaining('À la fin du compte à rebours'), findsOneWidget);
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Après 10 situations'), findsOneWidget);
    expect(find.textContaining('score provisoire'), findsOneWidget);
    expect(find.textContaining('Aucune correction immédiate'), findsOneWidget);
  });

  testWidgets('un écrit affiche sa bulle sans emplacement vidéo', (
    tester,
  ) async {
    const message =
        '« Bonjour, nous venons de réceptionner la livraison : la référence '
        'ne correspond pas à la commande. Que prévoyez-vous ? »';
    final videos = bank.scenarios
        .where((scenario) => scenario.medium == StrategicChoiceMedium.video)
        .take(kStrategicChoicesPerJourney - 1);
    await pumpGame(tester, scenarios: [bank.byId('CS-112'), ...videos]);
    await reachGameplay(tester);

    expect(find.text('MESSAGE REÇU'), findsOneWidget);
    expect(find.text(message), findsOneWidget);
    expect(
      find.byKey(const ValueKey('strategic-written-message')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('strategic-video-placeholder')),
      findsNothing,
    );
    expect(find.text('Vidéo à venir'), findsNothing);
  });

  testWidgets('pause freezes reflection and offers no restart action', (
    tester,
  ) async {
    await pumpGame(tester);
    await reachGameplay(tester);

    final startReflection = find.byKey(
      const ValueKey('strategic-start-reflection'),
    );
    await tester.tap(startReflection);
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();
    expect(find.text('Reprendre'), findsOneWidget);
    expect(find.text('Règles / Aide'), findsOneWidget);
    expect(find.text('Quitter la mission'), findsOneWidget);
    expect(find.textContaining('Recommencer'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Reprendre'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Temps de réflexion · choix'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      find.text('Réflexion terminée · choisis une stratégie'),
      findsOneWidget,
    );
  });

  testWidgets('l’aide conserve la sélection et gèle la réflexion', (
    tester,
  ) async {
    await pumpGame(tester);
    await reachGameplay(tester);
    await tester.tap(find.byKey(const ValueKey('strategic-start-reflection')));
    await tester.pump();
    final choice = find.byKey(const ValueKey('strategic-choice-breathePause'));
    await tester.tap(choice);
    await tester.pump(const Duration(milliseconds: 100));
    bool selected() => tester
        .widget<Semantics>(
          find
              .ancestor(
                of: choice,
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is Semantics && widget.properties.selected != null,
                ),
              )
              .first,
        )
        .properties
        .selected!;
    expect(selected(), isTrue);
    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Règles / Aide'));
    await tester.pumpAndSettle();
    expect(find.text('Lis la situation'), findsOneWidget);
    for (var page = 0; page < 4; page++) {
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Commencer la partie'), findsNothing);
    await tester.tap(find.text('Reprendre la partie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reprendre'));
    await tester.pump();
    expect(selected(), isTrue);
    expect(find.textContaining('Temps de réflexion · choix'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      find.text('Prêt à valider · une stratégie choisie'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('dix choix mènent au score du serveur et aux observations', (
    tester,
  ) async {
    await pumpGame(tester);
    await reachGameplay(tester);

    for (var index = 0; index < 10; index++) {
      await completeCurrentSituation(tester);
    }
    await tester.pumpAndSettle();

    // Écran « Bilan final » de la maquette.
    expect(find.text('Bilan final'), findsOneWidget);
    expect(
      find.text(
        'Un bilan de coaching fondé sur tes choix dans 10 situations.',
      ),
      findsOneWidget,
    );
    // Le récapitulatif n'est plus « front-only » : le serveur note la partie.
    // Le joueur coche « Respirer / pause » partout ; sur les dix situations
    // tirées, le total dépend donc de la banque — on vérifie la FORME du score
    // et sa cohérence, pas une valeur que le tirage rendrait aléatoire.
    final global = tester.widget<Text>(
      find.byKey(const ValueKey('strategic-answer-count')),
    );
    expect(global.data, matches(RegExp(r'^\d+ / 100$')));
    expect(
      int.parse(global.data!.split(' / ').first),
      inInclusiveRange(0, 100),
    );
    // Profil : trois mesures réelles du barème serveur, jamais « Pending ».
    expect(find.text('Profil d’apprentissage'), findsOneWidget);
    expect(find.text('Choix de stratégies optimales'), findsOneWidget);
    expect(find.text('Coping centré sur le problème'), findsOneWidget);
    expect(find.text('Coping non dysfonctionnel'), findsOneWidget);
    expect(find.text('Pending'), findsNothing);
    expect(find.textContaining(RegExp(r'^\d+%$')), findsNWidgets(6));

    expect(
      find.textContaining('No psychometric score is calculated'),
      findsNothing,
      reason: 'le barème est branché',
    );
    // Le barème reste provisoire, et l'écran doit le dire.
    expect(find.textContaining('PROVISOIRE'), findsOneWidget);

    // Tout tient sur l'écran, sans défilement.
    expect(find.text('Voir l’analyse détaillée').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Voir l’analyse détaillée'));
    await tester.pumpAndSettle();
    expect(find.text('Analyse détaillée'), findsOneWidget);
    expect(find.text('Stratégie la plus utilisée'), findsOneWidget);
    expect(find.text('Respirer / pause'), findsOneWidget);
    expect(find.text('Tendances pièges'), findsOneWidget);
  });

  testWidgets('aucun écran ne prétend plus que le jeu ne calcule pas de score', (
    tester,
  ) async {
    // Le jeu a longtemps été « front-only ». Ses pages de règles, son
    // récapitulatif et ses observations l'annonçaient — et le disaient encore
    // après le branchement du barème. Le plus grave était la promesse que les
    // réponses « restaient sur l'écran » : elles partent maintenant au serveur.
    const mensonges = [
      'front-only',
      'does not calculate a score',
      'leaves scoring uncalculated',
      'Not scored',
      'kept only for this on-screen recap',
      'No psychometric score',
      // La taxonomie des dix situations inventées ; la banque du client n'a
      // aucune catégorie.
      'Conflict, failure, delay, criticism, and overload',
      // Un effectif écrit en dur : il a déjà menti une fois quand la banque
      // est passée de 60 à 80 situations.
      'banque de 60 situations',
    ];

    void verifier(String etape) {
      for (final phrase in mensonges) {
        expect(
          find.textContaining(phrase),
          findsNothing,
          reason: '$etape : « $phrase » n\'est plus vrai',
        );
      }
    }

    await pumpGame(tester);
    verifier('couverture');

    await reachGameplay(tester);
    verifier('règles et gameplay');

    for (var index = 0; index < 10; index++) {
      await completeCurrentSituation(tester);
    }
    await tester.pumpAndSettle();
    verifier('récapitulatif');

    // Tout tient sur l'écran, sans défilement.
    expect(find.text('Voir l’analyse détaillée').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Voir l’analyse détaillée'));
    await tester.pumpAndSettle();
    verifier('observations');
  });

  testWidgets('390x844 at 200% text stays readable without overflow', (
    tester,
  ) async {
    await pumpGame(tester, textScale: 2);
    expect(tester.takeException(), isNull);
    await revealScrollableText(tester, 'Strategic Choices');
    expect(find.text('Strategic Choices'), findsOneWidget);

    await tapScrollableText(tester, 'Commencer la mission');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Tutoriel sur un seul écran : le bouton est visible sans défiler.
    expect(find.text('Suivant').hitTestable(), findsOneWidget);
  });

  group('écran unique, barre, sons', () {
    Future<void> useSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      await tester.pumpAndSettle();
    }

    for (final size in const [Size(360, 640), Size(390, 844)]) {
      testWidgets('tutoriel et plateau tiennent sur $size', (tester) async {
        await pumpGame(tester);
        await useSize(tester, size);
        await tapScrollableText(tester, 'Commencer la mission');
        await tester.pumpAndSettle();
        expect(find.text('Train the pause before action'), findsNothing);
        expect(find.byType(PageView), findsOneWidget);
        for (var page = 0; page < 4; page++) {
          expect(find.text('Suivant').hitTestable(), findsOneWidget);
          await tester.tap(find.text('Suivant'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        expect(find.text('Commencer la partie').hitTestable(), findsOneWidget);
        await tester.tap(find.text('Commencer la partie'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'aucun débordement');
        expect(find.byType(Scrollable), findsNothing, reason: 'plateau');
        for (final strategy in StrategicChoicesContent.strategies) {
          final card = find.byKey(
            ValueKey('strategic-choice-${strategy.name}'),
          );
          expect(card.hitTestable(), findsOneWidget);
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(of: card, matching: find.text(strategy.label)),
          );
          expect(paragraph.didExceedMaxLines, isFalse, reason: strategy.label);
        }
        expect(
          find
              .byKey(const ValueKey('strategic-start-reflection'))
              .hitTestable(),
          findsOneWidget,
        );
      });
    }

    testWidgets('la barre suit les situations', (tester) async {
      await pumpGame(tester);
      await reachGameplay(tester);
      double bar() => tester
          .widget<LinearProgressIndicator>(
            find.byKey(const ValueKey('strategic-progress')),
          )
          .value!;
      expect(bar(), closeTo(0.1, 0.001));
      await completeCurrentSituation(tester);
      expect(find.text('Situation 2 / 10'), findsOneWidget);
      expect(bar(), closeTo(0.2, 0.001));
    });

    testWidgets('sons : réflexion, choix et pause', (tester) async {
      final played = <GameSfx>[];
      SoundService.debugOnSfx = played.add;
      addTearDown(() => SoundService.debugOnSfx = null);
      // Réflexion réelle de 3 s pour entendre 3, 2, 1 puis la fin.
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            currentUserProvider.overrideWithValue(null),
          ],
          child: const MaterialApp(home: StrategicChoicesScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await reachGameplay(tester);

      played.clear();
      await tester.tap(
        find.byKey(const ValueKey('strategic-start-reflection')),
      );
      await tester.pump();
      expect(played.where((s) => s == GameSfx.timerDecrease), hasLength(1));
      expect(
        find.text('3 s'),
        findsOneWidget,
        reason: 'compteur dans la carte',
      );

      await tester.tap(
        find.byKey(const ValueKey('strategic-choice-breathePause')),
      );
      await tester.pump();
      expect(played, contains(GameSfx.buttonClick), reason: 'choix');

      for (var i = 0; i < 32; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(played.where((s) => s == GameSfx.timerDecrease), hasLength(3));
      expect(played.where((s) => s == GameSfx.timerEnd), hasLength(1));

      played.clear();
      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
      expect(played, contains(GameSfx.pauseClick));
    });
  });

  group('fond noir réservé aux vidéos, titre sur une ligne, score blanc', () {
    const navy = Color(0xFF071333);

    Color? fillOf(WidgetTester tester, Finder finder) {
      final box = tester.widget<Container>(
        find.ancestor(of: finder, matching: find.byType(Container)).first,
      );
      return (box.decoration as BoxDecoration?)?.color;
    }

    testWidgets('un message écrit n\'est pas sur fond noir', (tester) async {
      final videos = bank.scenarios
          .where((scenario) => scenario.medium == StrategicChoiceMedium.video)
          .take(kStrategicChoicesPerJourney - 1);
      await pumpGame(tester, scenarios: [bank.byId('CS-112'), ...videos]);
      await reachGameplay(tester);

      final noirs = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => (c.decoration as BoxDecoration?)?.color == navy);
      expect(noirs, isEmpty, reason: 'aucun fond noir pour un écrit');
      expect(
        fillOf(
          tester,
          find.byKey(const ValueKey('strategic-situation-prompt')),
        ),
        isNot(navy),
      );
    });

    testWidgets('seule l\'illustration vidéo est sur fond noir', (
      tester,
    ) async {
      final longTitle = bank.scenarios.reduce(
        (a, b) => a.title.length >= b.title.length ? a : b,
      );
      final others = bank.scenarios
          .where((s) => s.id != longTitle.id)
          .take(kStrategicChoicesPerJourney - 1);
      await pumpGame(tester, scenarios: [longTitle, ...others]);
      await reachGameplay(tester);

      expect(
        fillOf(
          tester,
          find.byKey(const ValueKey('strategic-situation-prompt')),
        ),
        isNot(navy),
        reason: 'le texte de la scène est sur fond clair',
      );
      final placeholder = find.byKey(
        const ValueKey('strategic-video-placeholder'),
      );
      if (placeholder.evaluate().isNotEmpty) {
        expect(fillOf(tester, find.text('Vidéo à venir')), navy);
      }

      // Titre le plus long de la banque : toujours une seule ligne.
      final title = find.text(longTitle.title);
      final paragraph = tester.renderObject<RenderParagraph>(title);
      expect(
        paragraph
            .getBoxesForSelection(
              TextSelection(
                baseOffset: 0,
                extentOffset: longTitle.title.length,
              ),
            )
            .map((b) => b.top)
            .toSet(),
        hasLength(1),
        reason: 'titre sur une seule ligne',
      );
    });

    testWidgets('la carte du score est blanche, texte sombre', (tester) async {
      await pumpGame(tester);
      await reachGameplay(tester);
      for (var index = 0; index < 10; index++) {
        await completeCurrentSituation(tester);
      }
      await tester.pumpAndSettle();

      final label = find.text('Score global');
      expect(label, findsOneWidget);
      expect(fillOf(tester, label), Colors.white);
      expect(tester.widget<Text>(label).style?.color, isNot(Colors.white));
    });
  });

  testWidgets('la scène est découpée en phrases, la décision en gras', (
    tester,
  ) async {
    final scene = bank.byId('CS-001');
    final others = bank.scenarios
        .where((s) => s.id != scene.id)
        .take(kStrategicChoicesPerJourney - 1);
    await pumpGame(tester, scenarios: [scene, ...others]);
    await reachGameplay(tester);

    final paragraphs = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('strategic-situation-prompt')),
            matching: find.byType(Text),
          ),
        )
        .toList();
    // CS-001 : contexte, action, puis « Le personnage doit décider… ».
    expect(paragraphs, hasLength(3), reason: 'une phrase par paragraphe');
    expect(paragraphs.last.data, startsWith('Le personnage doit décider'));
    expect(paragraphs.last.style?.fontWeight, FontWeight.w700);
    expect(paragraphs.first.style?.fontWeight, FontWeight.w400);
  });
}
