import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zennyt/features/games/domain/config/decision_config.dart';
import 'package:zennyt/features/games/domain/entities/decision_form.dart';
import 'package:zennyt/features/games/presentation/decision_milestones.dart';
import 'package:zennyt/features/games/domain/entities/decision_metrics.dart';
import 'package:zennyt/features/games/presentation/view/je_decide_gameplay.dart';
import 'package:zennyt/features/games/presentation/widgets/game_system_components.dart';

/// Boucle de gameplay « Je Décide » : mesure du temps de réponse, indicateur de
/// changement d'avis, et règles de pause du cahier des charges (fenêtre unique
/// de 30 s, aucune pause dans le module chronométré).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  DecisionFormItem item(
    String id,
    DecisionDimension dimension, {
    DecisionItemFormat format = DecisionItemFormat.standard,
    int? timeLimitMs,
  }) => DecisionFormItem(
    itemId: id,
    dimension: dimension,
    format: format,
    vignette: 'Situation $id.',
    task: 'Consigne $id.',
    timeLimitMs: timeLimitMs,
    options: [
      DecisionFormOption(optionId: '$id-o1', label: 'Option 1'),
      DecisionFormOption(optionId: '$id-o2', label: 'Option 2'),
      DecisionFormOption(optionId: '$id-o3', label: 'Option 3'),
    ],
  );

  /// Forme minimale : un item libre puis un item chronométré à 7 s. On garde
  /// `itemsPerDimension` à 2 pour qu'aucun écran de transition ne s'intercale.
  DecisionForm form() => DecisionForm(
    formCode: 'A',
    itemsPerDimension: 2,
    items: [
      item('ER-1', DecisionDimension.er),
      item(
        'DT-7',
        DecisionDimension.dt,
        format: DecisionItemFormat.temporalDecision,
        timeLimitMs: 7000,
      ),
    ],
  );

  Future<List<DecisionItemResponse>?> pumpJourney(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    List<DecisionItemResponse>? submitted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DecisionGameplayView(
            form: form(),
            onClose: () {},
            onComplete: (responses) => submitted = responses,
          ),
        ),
      ),
    );
    await tester.pump();
    return submitted;
  }

  // ── Chronomètre d'une minute par question ──────────────────────────────────

  /// Aucune question n'était bornée hors du module sous contrainte : 24 items
  /// sur 30 restaient ouverts indéfiniment. Une minute les cadre.
  testWidgets('chaque question porte un chronomètre, la minute par défaut', (
    tester,
  ) async {
    await pumpJourney(tester);

    expect(find.byType(GameTimerBar), findsOneWidget);
    expect(
      find.text('${DecisionConfig.questionTimeLimitS} sec'),
      findsOneWidget,
    );
    // Le nombre de secondes vit dans l'en-tête, la barre reste nue : c'est la
    // disposition de « Je bouge », et elle ne coûte aucune hauteur au scénario.
    expect(
      find.descendant(
        of: find.byType(GameTimerBar),
        matching: find.byType(Text),
      ),
      findsNothing,
    );

    // Et il descend vraiment.
    await tester.pump(const Duration(seconds: 3));
    expect(
      find.text('${DecisionConfig.questionTimeLimitS - 3} sec'),
      findsOneWidget,
    );
  });

  /// Le point du retour client : « si le candidat répond à 12 secondes, on
  /// affiche la question suivante ». Le temps restant n'est ni attendu, ni
  /// reporté sur la question d'après.
  testWidgets('répondre avant la fin passe tout de suite à la suite', (
    tester,
  ) async {
    await pumpJourney(tester);

    await tester.pump(const Duration(seconds: 12));
    expect(
      find.text('${DecisionConfig.questionTimeLimitS - 12} sec'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('decision-option-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('decision-continue')));
    await tester.pump();

    // Item suivant (sous contrainte) : son propre budget, reparti de zéro.
    expect(
      find.text('7 sec'),
      findsOneWidget,
      reason: 'les 48 s non consommées ne se reportent pas',
    );
  });

  /// Le rebours de la minute couvre la question ENTIÈRE, lecture comprise —
  /// contrairement à celui des items sous contrainte, qui attend l'écran de
  /// choix parce qu'il mesure la décision et non la vitesse de lecture.
  testWidgets('une question ordinaire qui expire est comptée manquée', (
    tester,
  ) async {
    List<DecisionItemResponse>? submitted;
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DecisionGameplayView(
            form: DecisionForm(
              formCode: 'A',
              itemsPerDimension: 2,
              items: [item('ER-1', DecisionDimension.er)],
            ),
            onClose: () {},
            onComplete: (r) => submitted = r,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.pump(
      const Duration(seconds: DecisionConfig.questionTimeLimitS),
    );
    expect(
      find.byKey(const ValueKey('decision-timeout-title')),
      findsOneWidget,
      reason: 'l\'écran d\'expiration ne servait qu\'aux items sous contrainte',
    );

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    expect(submitted, isNotNull);
    expect(submitted!.single.answered, isFalse);
  });

  /// Un choix déjà posé n'est pas perdu si la minute s'achève : il est validé
  /// tel quel. Le perdre punirait un candidat qui a décidé mais pas confirmé.
  testWidgets('un choix posé est validé quand la minute s\'achève', (
    tester,
  ) async {
    List<DecisionItemResponse>? submitted;
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DecisionGameplayView(
            form: DecisionForm(
              formCode: 'A',
              itemsPerDimension: 2,
              items: [item('ER-1', DecisionDimension.er)],
            ),
            onClose: () {},
            onComplete: (r) => submitted = r,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('decision-option-1')));
    await tester.pump();
    await tester.pump(
      const Duration(seconds: DecisionConfig.questionTimeLimitS),
    );
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!.single.answered, isTrue);
    expect(submitted!.single.selectedOptionId, 'ER-1-o2');
  });

  // ── La reprise a été retirée ──────────────────────────────────────────────

  /// Le point de reprise ne conservait que l'index de la question, jamais les
  /// réponses : reprendre un parcours renvoyait au serveur toutes les questions
  /// précédentes comme « non répondues » — un test l'a mesuré à 3 perdues sur 4
  /// — pendant que l'écran affirmait « Your previous choices are saved ».
  ///
  /// Plutôt que de persister des réponses de test psychométrique en clair sur
  /// l'appareil, la reprise a été retirée. Ce test empêche son retour silencieux.
  testWidgets('aucun écran de reprise, aucun point de sauvegarde', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'games.je_decide.saved_checkpoint': true,
      'games.je_decide.saved_item_index': 15,
    });
    await pumpJourney(tester);

    // Un point de reprise résiduel dans les préférences ne doit plus rien
    // déclencher : le parcours commence au premier scénario.
    expect(find.text('Welcome back'), findsNothing);
    expect(find.text('Your previous choices are saved.'), findsNothing);
    expect(
      find.byKey(const ValueKey('decision-resume-continue')),
      findsNothing,
    );
    expect(find.text('Scenario 01 / 2'), findsOneWidget);
  });

  /// Le bouton « Take a short pause » du point d'étape écrivait ce point de
  /// reprise. Il n'a plus rien à écrire.
  testWidgets('le point d\'étape ne propose plus de sauvegarder', (
    tester,
  ) async {
    await pumpJourney(tester);
    expect(
      find.byKey(const ValueKey('decision-checkpoint-pause')),
      findsNothing,
    );
  });

  // ── Écrans de jalon : la dimension réellement franchie ────────────────────

  /// Les écrans de transition annonçaient un jalon ÉCRIT EN DUR : le médaillon
  /// « RN », le titre « Risk Navigator » et deux pastilles sur cinq, quelle que
  /// soit la dimension terminée. Relevé sur une capture au scénario 25 sur 30 —
  /// quatre dimensions franchies, la deuxième annoncée.
  testWidgets('le jalon nomme la dimension franchie et compte les pastilles', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Deux items par dimension : l'écran de jalon tombe au 4ᵉ palier, donc
    // après CS — la quatrième dimension, pas la deuxième.
    final ordered = [
      for (final d in DecisionDimension.values) ...[
        item('${d.wire}-1', d),
        item('${d.wire}-2', d),
      ],
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DecisionGameplayView(
            form: DecisionForm(
              formCode: 'A',
              itemsPerDimension: 2,
              items: ordered,
            ),
            onClose: () {},
            onComplete: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    // On avance jusqu'à l'écran de jalon, en balayant les écrans de transition
    // que le rythme intercale à chaque frontière de dimension.
    const continues = [
      'decision-next-scenario',
      'decision-checkpoint-continue',
      'decision-badge-continue',
      'decision-encouragement-continue',
    ];
    for (var step = 0; step < 40; step++) {
      if (find
          .byKey(const ValueKey('decision-dimension-complete'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
      var moved = false;
      for (final key in continues) {
        final f = find.byKey(ValueKey(key));
        if (f.evaluate().isNotEmpty) {
          await tester.tap(f.first);
          moved = true;
          break;
        }
      }
      if (!moved) {
        // `.first` : la transition garde brièvement les cartes des deux items.
        await tester.tap(find.byKey(const ValueKey('decision-option-0')).first);
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('decision-continue')).first);
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    expect(
      find.byKey(const ValueKey('decision-dimension-complete')),
      findsOneWidget,
      reason: 'le 4ᵉ palier du rythme est l\'écran de jalon',
    );
    expect(find.text('Risk Navigator'), findsNothing);
    expect(
      find.text(milestoneOf(DecisionDimension.cs).name),
      findsOneWidget,
      reason: 'CS vient d\'être franchie',
    );

    // Trois axes actifs franchis ; II archivé ne produit plus de pastille.
    expect(find.byKey(const ValueKey('milestone-AE-on')), findsNothing);
    for (final d in DecisionConfig.dimensions) {
      final code = milestoneOf(d).code;
      final on = d != DecisionDimension.re;
      expect(
        find.byKey(ValueKey('milestone-$code-${on ? 'on' : 'off'}')),
        findsOneWidget,
        reason: '$code doit être ${on ? 'allumée' : 'éteinte'}',
      );
    }

    await tester.tap(find.byKey(const ValueKey('decision-dimension-continue')));
    await tester.pump();
  });

  /// Item COURT à deux options — un cas favorable, pas un cas représentatif.
  ///
  /// La version précédente de ce commentaire le présentait comme « la médiane
  /// des 96 scénarios ». C'était faux et ça a coûté cher : les 30 items du build
  /// de démo ont TOUS quatre options, et la banque serveur n'a d'items à deux
  /// options que dans trois dimensions sur cinq. Les tests bâtis sur cette
  /// fixture passaient au vert pendant que le client voyait 27 items sur 27
  /// défiler.
  ///
  /// Le réalisme est désormais couvert par `je_decide_no_scroll_test.dart`, qui
  /// parcourt les banques réellement servies. Cette fixture ne sert plus qu'aux
  /// tests de comportement, où le contenu n'est pas le sujet.
  DecisionFormItem typicalItem() => DecisionFormItem(
    itemId: 'RE-3',
    dimension: DecisionDimension.re,
    format: DecisionItemFormat.standard,
    vignette:
        'Un collègue vous reproche publiquement une erreur que vous n\'avez '
        'pas commise, pendant la réunion hebdomadaire de service.',
    task: 'Que faites-vous dans l\'immédiat ?',
    options: [
      DecisionFormOption(
        optionId: 'RE-3-o1',
        label: 'Je réponds calmement et propose d\'en reparler après.',
      ),
      DecisionFormOption(
        optionId: 'RE-3-o2',
        label: 'Je rectifie immédiatement devant tout le monde.',
      ),
    ],
  );

  /// Le pire cas réel de la banque (item II-18) : 1167 caractères, quatre
  /// Contenu archivé utilisé uniquement pour vérifier le texte agrandi et le gel de densité.
  DecisionFormItem oversizedAccessibilityFixture() => DecisionFormItem(
    itemId: 'ACCESSIBILITY-LONG',
    dimension: DecisionDimension.er,
    format: DecisionItemFormat.standard,
    vignette:
        'Vous choisissez un ordinateur portable pour un graphiste de votre '
        'équipe (travail sur logiciels de retouche photo et montage vidéo). '
        'Trois options : A (moins cher, RAM 8 Go, GPU intégré, performances '
        'insuffisantes pour le montage vidéo 4K), B (dans le budget, RAM 16 '
        'Go, GPU dédié 4 Go, compatible avec les logiciels métiers), C (cher, '
        'hors budget, RAM 32 Go, GPU dédié 8 Go, performances maximales). '
        'Budget plafonné ; performances compatibles avec les logiciels métiers '
        'obligatoires.',
    task:
        'Classez les trois options du plus au moins adapté, puis choisissez la '
        'justification qui reflète le mieux votre raisonnement.',
    options: [
      DecisionFormOption(
        optionId: 'II-18-o1',
        label:
            'Je choisis B : le tarif est dans le budget et les spécifications '
            '(16 Go RAM, GPU 4 Go) sont suffisantes pour les logiciels de '
            'retouche et montage utilisés. A est éliminé par des performances '
            'insuffisantes pour le montage 4K, C par le dépassement budgétaire.',
      ),
      DecisionFormOption(
        optionId: 'II-18-o2',
        label:
            'Je choisis B car les performances couvrent les besoins '
            'professionnels du graphiste.',
      ),
      DecisionFormOption(
        optionId: 'II-18-o3',
        label:
            'Je choisis C : investir dans la meilleure configuration réduit '
            'les risques de lenteur et prolonge la durée de vie utile de la '
            'machine.',
      ),
      DecisionFormOption(
        optionId: 'II-18-o4',
        label:
            'Je choisis A car le design est plus léger, ce qui est pratique '
            'pour les déplacements.',
      ),
    ],
  );

  /// Monte une passation entière. La densité étant gelée SUR LE FORMULAIRE, tout
  /// test qui compare deux scénarios entre eux doit les mettre dans le même.
  Future<void> pumpForm(
    WidgetTester tester,
    List<DecisionFormItem> items, {
    required Size screen,
  }) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Repompe-t-on le même écran à une autre taille dans le même test ? Alors
    // il faut d'abord vider l'arbre : sans cela le `MediaQuery` conserve les
    // dimensions du pompage précédent et la mesure porte sur le mauvais écran.
    await tester.pumpWidget(const SizedBox.shrink());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DecisionGameplayView(
            form: DecisionForm(
              formCode: 'A',
              // Assez grand pour qu'aucun écran intercalaire ne s'intercale.
              itemsPerDimension: items.length + 1,
              items: items,
            ),
            onClose: () {},
            onComplete: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Monte un item seul. À réserver aux tests où le contenu des AUTRES items
  /// n'entre pas en jeu : la densité est calibrée sur le formulaire, donc deux
  /// appels successifs produisent deux calibrages indépendants.
  Future<void> pumpItem(
    WidgetTester tester,
    DecisionFormItem single, {
    required Size screen,
  }) => pumpForm(tester, [single], screen: screen);

  /// Choisit la première option et valide, pour arriver à l'item suivant.
  Future<void> goToNextItem(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('decision-option-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('decision-continue')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Ce que le client mesure des yeux : y a-t-il quelque chose à faire défiler ?
  ///
  /// On n'assène pas « aucun widget défilable » : le conteneur reste défilable
  /// par sécurité, pour qu'une erreur de prédiction de quelques pixels coûte un
  /// défilement plutôt qu'un débordement. Ce qui compte est qu'il n'ait rien à
  /// faire défiler.
  double scrollExtent(WidgetTester tester) {
    final scrollables = find.byType(Scrollable);
    if (scrollables.evaluate().isEmpty) return 0;
    return tester
        .state<ScrollableState>(scrollables.first)
        .position
        .maxScrollExtent;
  }

  /// Retour client : « il faut adapter le UI selon la taille de l'écran afin
  /// que le scénario et les choix s'affichent entièrement sans défilement. Le
  /// défilement ajoute de la friction et une perte de temps ».
  ///
  /// Sur un jeu qui mesure le temps de réponse, ce n'est pas qu'une question de
  /// confort : le temps passé à faire défiler l'écran pour découvrir une option
  /// entre dans la mesure.
  group('mise en page sans défilement', () {
    testWidgets('un item courant tient entièrement, sans zone défilante', (
      tester,
    ) async {
      await pumpItem(tester, typicalItem(), screen: const Size(390, 844));

      expect(
        scrollExtent(tester),
        0,
        reason: 'rien à faire défiler : tout tient d\'un coup d\'œil',
      );

      // Les deux choix ET le bouton de validation sont dans l'écran.
      for (final key in ['decision-option-0', 'decision-option-1']) {
        expect(tester.getRect(find.byKey(ValueKey(key))).bottom, lessThan(844));
      }
      expect(
        tester.getRect(find.byKey(const ValueKey('decision-continue'))).bottom,
        lessThanOrEqualTo(844.0),
      );
    });

    testWidgets(
      'le même item se compacte au lieu de déborder sur petit écran',
      (tester) async {
        await pumpItem(tester, typicalItem(), screen: const Size(390, 844));
        final roomy = tester
            .getSize(find.byKey(const ValueKey('decision-option-0')))
            .height;

        await pumpItem(tester, typicalItem(), screen: const Size(320, 568));
        final tight = tester
            .getSize(find.byKey(const ValueKey('decision-option-0')))
            .height;

        expect(
          tight,
          lessThan(roomy),
          reason:
              'le plancher fixe de 92 px réservait 300 px aux choix avant même '
              'que l\'énoncé ait sa place — c\'était la cause du défilement',
        );
        expect(scrollExtent(tester), 0);
        expect(tester.takeException(), isNull);
      },
    );

    /// La compaction a une limite : quand le candidat a agrandi la police de son
    /// téléphone, plus rien ne tient. Le comportement attendu n'est alors pas de
    /// rétrécir le texte — ce serait annuler son réglage d'accessibilité — mais
    /// de défiler proprement.
    testWidgets('à 200 % de taille de police, on défile sans rien tronquer', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: DecisionGameplayView(
                form: DecisionForm(
                  formCode: 'A',
                  itemsPerDimension: 1,
                  items: [oversizedAccessibilityFixture()],
                ),
                onClose: () {},
                onComplete: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull, reason: 'aucun débordement');
      expect(
        scrollExtent(tester),
        greaterThan(0),
        reason: 'le contenu dépasse : il doit être atteignable en défilant',
      );
    });

    /// La taille du texte est GELÉE sur la banque, pas ajustée à chaque
    /// scénario.
    ///
    /// « Je décide » mesure des temps de réponse. Si le corps de texte passait
    /// de 15,5 px sur un scénario court à 13,3 px sur un scénario long, la
    /// vitesse de lecture varierait avec lui, et cette variation entrerait dans
    /// le temps mesuré sans rien mesurer de la décision. C'est un biais de
    /// mesure, pas un détail d'esthétique.
    /// Le gel vaut à l'intérieur d'UNE passation, sur le contenu réellement
    /// servi. Les deux items doivent donc appartenir au même formulaire : monter
    /// deux formulaires distincts, comme le faisait la version précédente de ce
    /// test, revient à calibrer deux fois et ne prouve rien.
    testWidgets('la taille du texte ne change pas d\'un scénario à l\'autre', (
      tester,
    ) async {
      double optionFontSize() => tester
          .widget<Text>(
            find
                .descendant(
                  of: find.byKey(const ValueKey('decision-option-0')),
                  matching: find.byKey(const ValueKey('decision-option-label')),
                )
                .first,
          )
          .style!
          .fontSize!;

      await pumpForm(tester, [
        typicalItem(),
        oversizedAccessibilityFixture(),
      ], screen: const Size(390, 844));
      final onShort = optionFontSize();

      await goToNextItem(tester);
      final reveal = find.byKey(const ValueKey('decision-reveal-choices'));
      if (reveal.evaluate().isNotEmpty) {
        await tester.tap(reveal);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }
      final onLong = optionFontSize();

      expect(
        onLong,
        onShort,
        reason:
            'le scénario le plus long et le plus court doivent se lire à la '
            'même taille — sinon la présentation devient une variable',
      );
    });

    /// Le chronomètre du module « Décision sous Contrainte Temporelle » ne doit
    /// pas non plus changer la taille du texte.
    ///
    /// Il occupe une bande en haut de l'écran, donc réduit la place offerte au
    /// scénario. Sans réservation permanente de cette bande, un item chronométré
    /// se lisait plus petit qu'un item libre sur le même téléphone — 16,4 px
    /// contre 16,7 px sur un 360×640 — ce qui rétablissait par la bande ce que
    /// le gel supprime par ailleurs.
    testWidgets(
      'un item chronométré se lit à la même taille qu\'un item libre',
      (tester) async {
        double optionFontSize() => tester
            .widget<Text>(
              find
                  .descendant(
                    of: find.byKey(const ValueKey('decision-option-0')),
                    matching: find.byType(Text),
                  )
                  .first,
            )
            .style!
            .fontSize!;

        DecisionFormItem chronometre() => DecisionFormItem(
          itemId: 'DT-1',
          dimension: DecisionDimension.dt,
          format: DecisionItemFormat.temporalDecision,
          timeLimitMs: 7000,
          vignette: typicalItem().vignette,
          task: typicalItem().task,
          options: typicalItem().options,
        );

        // 360×640 : le gabarit où l'écart se manifestait. Les deux items sont
        // dans le MÊME formulaire — c'est là que le gel doit tenir.
        await pumpForm(tester, [
          typicalItem(),
          chronometre(),
        ], screen: const Size(360, 640));
        final libre = optionFontSize();

        await goToNextItem(tester);
        expect(optionFontSize(), libre);
      },
    );

    /// Le client ne distingue pas « défiler sur un scénario » de « défiler dans
    /// Je décide ». Ce test parcourt donc TOUT le jeu sur les deux plus petits
    /// gabarits — écrans intercalaires compris — et vérifie qu'aucun n'a quoi
    /// que ce soit à faire défiler.
    ///
    /// Les intercalaires n'étaient pas couverts par la refonte : l'écran de
    /// récompense défilait de 52 px et le checkpoint de 86 px sur un 320×568.
    for (final screen in const [Size(320, 568), Size(360, 640)]) {
      testWidgets(
        'aucun écran du parcours ne défile en ${screen.width.toInt()}x${screen.height.toInt()}',
        (tester) async {
          DecisionFormItem item(int i, DecisionDimension d) => DecisionFormItem(
            itemId: 'X$i',
            dimension: d,
            format: DecisionItemFormat.standard,
            vignette: typicalItem().vignette,
            task: typicalItem().task,
            options: typicalItem().options,
          );

          SharedPreferences.setMockInitialValues({});
          tester.view.physicalSize = screen;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: DecisionGameplayView(
                  form: DecisionForm(
                    formCode: 'A',
                    itemsPerDimension: 8,
                    items: [
                      for (var i = 0; i < 8; i++) item(i, DecisionDimension.re),
                      for (var i = 8; i < 16; i++)
                        item(i, DecisionDimension.cs),
                      for (var i = 16; i < 24; i++)
                        item(i, DecisionDimension.er),
                      for (var i = 24; i < 32; i++)
                        item(i, DecisionDimension.dt),
                    ],
                  ),
                  onClose: () {},
                  onComplete: (_) {},
                ),
              ),
            ),
          );
          await tester.pump();

          for (var step = 0; step < 90; step++) {
            expect(scrollExtent(tester), 0, reason: 'étape $step');
            expect(tester.takeException(), isNull, reason: 'étape $step');

            final option = find.byKey(const ValueKey('decision-option-0'));
            if (option.evaluate().isNotEmpty) {
              await tester.tap(option.first);
              await tester.pump();
              await tester.tap(
                find.byKey(const ValueKey('decision-continue')).first,
              );
            } else {
              // Écran intercalaire : un seul bouton principal fait avancer.
              final suivant = find.byType(FilledButton);
              if (suivant.evaluate().isEmpty) break;
              await tester.tap(suivant.first, warnIfMissed: false);
            }
            await tester.pump(const Duration(milliseconds: 400));
            await tester.pump(const Duration(milliseconds: 400));
          }
        },
      );
    }

    /// Écran d'expiration du module chronométré : atteint par tout candidat qui
    /// laisse filer les 7 secondes. Il défilait de 87 px sur un 320×568 et de
    /// 15 px sur un 360×640 — un gabarit très courant.
    for (final screen in const [Size(320, 568), Size(360, 640)]) {
      testWidgets(
        'l\'écran d\'expiration tient en ${screen.width.toInt()}x${screen.height.toInt()}',
        (tester) async {
          await pumpItem(
            tester,
            DecisionFormItem(
              itemId: 'DT-1',
              dimension: DecisionDimension.dt,
              format: DecisionItemFormat.temporalDecision,
              timeLimitMs: 7000,
              vignette: 'Une décision doit être prise immédiatement.',
              task: 'Choisissez sans attendre.',
              options: [
                DecisionFormOption(optionId: 'a', label: 'Option A'),
                DecisionFormOption(optionId: 'b', label: 'Option B'),
              ],
            ),
            screen: screen,
          );
          await tester.pump(const Duration(seconds: 7));
          await tester.pump();

          expect(
            find.byKey(const ValueKey('decision-timeout-title')),
            findsOneWidget,
          );
          expect(scrollExtent(tester), 0);
        },
      );
    }

    /// Le pire item n'est ni rapetissé jusqu'à l'illisible, ni rendu défilant :
    /// il est découpé. Aucun de ses deux écrans ne défile.
  });

  testWidgets(
    'le temps de réponse est mesuré à la validation, pas au premier tap',
    (tester) async {
      List<DecisionItemResponse>? submitted;
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DecisionGameplayView(
              form: form(),
              onClose: () {},
              onComplete: (responses) => submitted = responses,
            ),
          ),
        ),
      );
      await tester.pump();

      // Item 1 : on choisit tout de suite, puis on délibère 4 s avant de valider.
      await tester.tap(find.byKey(const ValueKey('decision-option-0')));
      await tester.pump(const Duration(seconds: 4));
      // Puis on change d'avis — c'est permis, et compté.
      await tester.tap(find.byKey(const ValueKey('decision-option-2')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('decision-continue')));
      await tester.pump();

      // Item 2 (chronométré) : on ne répond pas, le temps s'écoule.
      expect(find.text('7 sec'), findsOneWidget);
      await tester.pump(const Duration(seconds: 7));
      expect(
        find.byKey(const ValueKey('decision-timeout-title')),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      expect(submitted, isNotNull);
      final first = submitted!.first;
      expect(
        first.selectedOptionId,
        'ER-1-o3',
        reason: 'la réponse validée est le dernier choix',
      );
      expect(
        first.decisionChangesCount,
        1,
        reason: 'le changement d\'avis est un indicateur mesuré, pas une faute',
      );
      expect(
        first.responseTimeMs,
        greaterThanOrEqualTo(4000),
        reason:
            'choisir vite puis délibérer doit produire un temps LONG — sinon la '
            'contrainte de temps se contourne',
      );

      final timed = submitted!.last;
      expect(
        timed.answered,
        isFalse,
        reason: 'item manqué → imputation serveur',
      );
      expect(timed.selectedOptionId, isNull);
    },
  );

  /// « Décision sous Contrainte Temporelle » : aucune pause, sans exception.
  ///
  /// C'est l'un des deux cas déjà tranchés du cahier des charges « pause »
  /// (§3-4). La contrainte de 7 s **est** la mesure de ce module : pouvoir la
  /// suspendre reviendrait à la supprimer. Le test précédent verrouillait
  /// l'inverse — il vérifiait que la pause gelait bien le compte à rebours.
  testWidgets('aucune pause n\'est offerte sur un item chronométré', (
    tester,
  ) async {
    await pumpJourney(tester);

    // Item libre : le bouton pause est bien là.
    expect(
      find.byKey(const ValueKey('decision-pause-button')),
      findsOneWidget,
      reason: 'hors module chronométré, la fenêtre de pause reste offerte',
    );

    // Passe le premier item pour atteindre l'item chronométré.
    await tester.tap(find.byKey(const ValueKey('decision-option-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('decision-continue')));
    await tester.pump();

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('4 sec'), findsOneWidget);

    expect(
      find.byKey(const ValueKey('decision-pause-button')),
      findsNothing,
      reason:
          'le module chronométré ne propose NI pause NI sortie : c\'est le seul '
          'endroit où le bouton disparaît encore complètement. Une boîte de '
          'dialogue modale, fût-elle une confirmation de sortie, offrirait un '
          'temps de réflexion pendant les 7 s — il suffirait de l\'ouvrir puis '
          'de l\'annuler. L\'absence dure sept secondes, pas toute la partie.',
    );

    // Et le compte à rebours continue de courir : rien ne le gèle.
    await tester.pump(const Duration(seconds: 5));
    expect(
      find.byKey(const ValueKey('decision-timeout-title')),
      findsOneWidget,
      reason: 'les 7 s s\'écoulent jusqu\'au bout',
    );
  });

  /// La fenêtre de pause ne s'ouvre qu'UNE fois par passation (CdC §2-3).
  testWidgets('« Resume » éteint le droit de pause, même après 2 secondes', (
    tester,
  ) async {
    await pumpJourney(tester);

    final pauseButton = find.byKey(const ValueKey('decision-pause-button'));
    await tester.tap(pauseButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('decision-pause-dialog')), findsOneWidget);
    expect(find.textContaining('Menu closes in'), findsOneWidget);

    // Deux secondes suffisent : la durée de la pause n'entre pas en compte,
    // c'est l'OUVERTURE qui consomme le droit.
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(
      find.byKey(const ValueKey('decision-pause-dialog-resume')),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<IconButton>(pauseButton).tooltip,
      'Exit mission',
      reason:
          'une seule ouverture par partie : le menu ne doit plus rester '
          'disponible après « Resume »',
    );

    // Et il ouvre bien la confirmation de sortie, pas le menu de pause.
    await tester.tap(pauseButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('decision-pause-dialog')), findsNothing);
    expect(find.text('Leave journey?'), findsOneWidget);
  });

  testWidgets('les trois cartes d’aide conservent le choix et le chrono', (
    tester,
  ) async {
    await pumpJourney(tester);
    await tester.tap(find.byKey(const ValueKey('decision-option-1')));
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.byKey(const ValueKey('decision-pause-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('decision-view-rules')));
    await tester.pumpAndSettle();
    expect(find.text('Étape 1 sur 3'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    for (var page = 0; page < 2; page++) {
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Reprendre la partie'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('decision-pause-dialog')), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('decision-pause-dialog-resume')),
    );
    await tester.pumpAndSettle();
    expect(find.text('57 sec'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('decision-continue')));
    await tester.pumpAndSettle();
    expect(find.text('7 sec'), findsOneWidget);
  });

  /// À l'expiration des 30 s, le menu se referme tout seul et la partie repart.
  testWidgets('la fenêtre de pause se referme d\'elle-même au bout de 30 s', (
    tester,
  ) async {
    await pumpJourney(tester);

    await tester.tap(find.byKey(const ValueKey('decision-pause-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('decision-pause-dialog')), findsOneWidget);

    await tester.pump(kGamePauseWindow);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('decision-pause-dialog')),
      findsNothing,
      reason: 'délai écoulé : le menu disparaît sans action du joueur',
    );
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey('decision-pause-button')),
          )
          .tooltip,
      'Exit mission',
      reason: 'la fenêtre est consommée : le bouton bascule sur la sortie',
    );
  });
}
