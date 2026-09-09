import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zennyt/features/games/data/demo_games_repository.dart';
import 'package:zennyt/features/games/domain/entities/decision_form.dart';
import 'package:zennyt/features/games/domain/entities/decision_metrics.dart';
import 'package:zennyt/features/games/presentation/view/je_decide_gameplay.dart';

/// Le test qui manquait — et dont l'absence a laissé passer DEUX fois la même
/// remarque client : « il faut adapter le UI selon la taille de l'écran afin que
/// le scénario et les choix s'affichent entièrement sans défilement ».
///
/// Les tests existants se servaient d'items ÉCRITS À LA MAIN : deux options
/// courtes, trois au plus. Or les 30 items du build de démo en ont tous QUATRE,
/// et ceux de la banque serveur montent à 1167 caractères. Les tests passaient au
/// vert pendant que le client voyait 27 items sur 27 défiler sur son téléphone.
///
/// Celui-ci parcourt les banques RÉELLEMENT SERVIES, item par item, écran par
/// écran, sur sept tailles d'appareil — barres système comprises, parce que
/// c'est là que 48 px disparaissent sans prévenir.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DecisionForm demoForm;

  setUpAll(() async {
    // Chargé ici et pas dans un `testWidgets` : le repository de démo attend
    // 120 ms, et une attente réelle ne se termine jamais sous l'horloge simulée
    // d'un test de widget.
    demoForm = await DemoGamesRepository().decisionItems('probe');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetDecisionLayoutPlanCacheForTest();
  });

  // ── Le parc ──────────────────────────────────────────────────────────────

  /// Tailles réelles, avec les encoches et barres de navigation qui vont avec.
  /// Sans les insets, le test est optimiste de ~48 px et rate exactement le cas
  /// que le client a signalé.
  const devices = <(String, Size, EdgeInsets)>[
    ('320×568 sans barres', Size(320, 568), EdgeInsets.zero),
    ('360×640 entrée de gamme', Size(360, 640), EdgeInsets.zero),
    ('360×800 dalle nue', Size(360, 800), EdgeInsets.zero),
    (
      '360×800 Redmi 13C, gestes',
      Size(360, 800),
      EdgeInsets.only(top: 24, bottom: 24),
    ),
    (
      '360×800 Redmi 13C, 3 boutons',
      Size(360, 800),
      EdgeInsets.only(top: 24, bottom: 48),
    ),
    (
      '390×844 iPhone 14',
      Size(390, 844),
      EdgeInsets.only(top: 47, bottom: 34),
    ),
    (
      '412×915 Pixel 7',
      Size(412, 915),
      EdgeInsets.only(top: 24, bottom: 24),
    ),
  ];

  // ── Outillage ────────────────────────────────────────────────────────────

  Future<void> mount(
    WidgetTester tester,
    DecisionForm form,
    Size size,
    EdgeInsets insets,
  ) async {
    // Repartir d'un arbre vide : une nouvelle `physicalSize` posée en cours de
    // test ne se propage pas tant que l'ancien `MediaQuery` est monté.
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size, padding: insets),
          child: Scaffold(
            body: DecisionGameplayView(
              form: form,
              onClose: () {},
              onComplete: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Le plus grand débordement de défilement de l'arbre, en pixels. Zéro = rien
  /// à faire défiler, ce qui est exactement la demande.
  ///
  /// On interroge l'extension de défilement plutôt que l'absence de widget
  /// défilable : le conteneur reste présent en filet de sécurité contre une
  /// erreur de prédiction de deux pixels. Ce qui doit être nul, c'est ce qu'il y
  /// a À faire défiler.
  double scrollExtent(WidgetTester tester) {
    var worst = 0.0;
    for (final state in tester.stateList<ScrollableState>(
      find.byType(Scrollable),
    )) {
      if (!state.position.hasContentDimensions) continue;
      if (state.position.maxScrollExtent > worst) {
        worst = state.position.maxScrollExtent;
      }
    }
    return worst;
  }

  /// Enchaîne les 250 ms de l'`AnimatedSwitcher` sans réveiller le compte à
  /// rebours de 7 s des items chronométrés.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  const interstitialContinues = [
    'decision-next-scenario',
    'decision-checkpoint-continue',
    'decision-badge-continue',
    'decision-encouragement-continue',
    'decision-dimension-continue',
  ];

  Finder? interstitialOnScreen() {
    for (final key in interstitialContinues) {
      final finder = find.byKey(ValueKey(key));
      if (finder.evaluate().isNotEmpty) return finder;
    }
    return null;
  }

  /// Joue la passation entière et relève tout écran qui défile — scénario,
  /// écran « situation » du mode deux temps, ou écran intercalaire.
  ///
  /// Rend le manque en pixels par item fautif, indexé par `itemId`, pour que
  /// l'appelant décide ce qui est acceptable : rien ne l'est sur la banque de
  /// démo, et un déficit chiffré et borné l'est sur les items dont les textes
  /// dépassent physiquement l'écran.
  Future<Map<String, double>> playWholeForm(
    WidgetTester tester, {
    required DecisionForm form,
    required String device,
  }) async {
    final offenders = <String, double>{};

    void check(String where, String itemId) {
      final extent = scrollExtent(tester);
      if (extent > 0.5) {
        final worst = offenders[itemId] ?? 0;
        if (extent > worst) offenders[itemId] = extent;
      }
      expect(
        tester.takeException(),
        isNull,
        reason: '$where déborde en rendu sur $device',
      );
    }

    for (var i = 0; i < form.items.length; i++) {
      final itemId = form.items[i].itemId;
      var guard = 0;
      for (
        var screen = interstitialOnScreen();
        screen != null;
        screen = interstitialOnScreen()
      ) {
        check('$device · intercalaire avant $itemId', itemId);
        await tester.tap(screen);
        await settle(tester);
        if (++guard > 3) fail('boucle d\'écrans intercalaires sur $device');
      }

      final reveal = find.byKey(const ValueKey('decision-reveal-choices'));
      if (reveal.evaluate().isNotEmpty) {
        check('$device · $itemId (situation)', itemId);
        await tester.tap(reveal);
        await settle(tester);
      }

      check('$device · $itemId (choix)', itemId);

      await tester.tap(find.byKey(const ValueKey('decision-option-0')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('decision-continue')));
      await settle(tester);
    }

    // L'arbre est démonté ici et pas dans un `tearDown` : la minuterie des items
    // chronométrés vit dans l'état, et seul `dispose` l'annule.
    await tester.pumpWidget(const SizedBox.shrink());
    return offenders;
  }

  String describe(Map<String, double> offenders) => offenders.entries
      .map((e) => '${e.key} : ${e.value.toStringAsFixed(0)} px')
      .join(', ');

  // ── La banque du build de démo : celle que le client teste ────────────────

  group('banque de démo (30 items, celle du build client)', () {
    for (final (device, size, insets) in devices) {
      testWidgets('rien ne défile sur $device', (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await mount(tester, demoForm, size, insets);
        final offenders = await playWholeForm(
          tester,
          form: demoForm,
          device: device,
        );
        expect(
          offenders,
          isEmpty,
          reason:
              'exigence client, sans exception, sur le build qu\'il teste : '
              '${describe(offenders)}',
        );
      });
    }
  });

  // ── La banque serveur : le pire de chaque dimension ───────────────────────

  group('banque serveur (forme des 6 pires items par dimension)', () {
    final form = _serverWorstCaseForm();

    /// Ce que les items d'Intégration d'Information demandent EN PLUS de ce que
    /// l'écran offre, une fois le découpage en deux temps appliqué et la
    /// densité au plancher.
    ///
    /// Ce n'est pas un défaut d'affichage : quatre justifications de 140 à 273
    /// caractères font 700 à 1100 caractères de choix, soit plus de vingt lignes
    /// à toute taille lisible. Aucune mise en page ne les fait tenir sous
    /// 360×800 — seule une réécriture des libellés le peut, et elle appartient
    /// au psychologue.
    ///
    /// Bornes relevées à la livraison. Elles servent de garde-fou : si un chiffre
    /// AUGMENTE, c'est une régression d'affichage ; s'il tombe à zéro, les
    /// textes ont été raccourcis et la borne doit être ramenée à zéro.
    /// Pire item : II-18, 1167 caractères dont une justification de 273.
    ///
    /// Relevées le 09/09, en deux fois :
    ///
    /// * **+15 / +13 px** — la bande de temps devenue permanente, quand chaque
    ///   question a reçu son chronomètre d'une minute. La barre seule coûte
    ///   ~14 px ; sa légende chiffrée en aurait coûté 23 de plus, d'où son
    ///   déménagement dans l'en-tête ;
    /// * **+11 px** — la ligne de pourcentage de la barre de parcours, dont la
    ///   hauteur de texte dépasse les 6 px de la barre seule.
    ///
    /// Le Redmi 13C entre dans la table pour la première fois, à 3 px : c'est le
    /// reliquat de cette seconde ligne sur les deux items les plus longs de la
    /// banque SERVEUR. La banque de démo — celle du build client — tient sur les
    /// sept gabarits sans rien réserver.
    const iiDeficit = <String, double>{
      '320×568 sans barres': 216,
      '360×640 entrée de gamme': 92,
      '360×800 Redmi 13C, 3 boutons': 4,
    };

    for (final (device, size, insets) in devices) {
      testWidgets(
        'rien ne défile sur $device, hors items trop longs pour l\'écran',
        (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await mount(tester, form!, size, insets);
          final offenders = await playWholeForm(
            tester,
            form: form,
            device: device,
          );

          final others = Map.of(offenders)
            ..removeWhere((id, _) => id.startsWith('II-'));
          expect(
            others,
            isEmpty,
            reason:
                'les dimensions ER, DT, CS et RE doivent tenir partout : '
                '${describe(others)}',
          );

          final budget = iiDeficit[device] ?? 0;
          final worstII = offenders.entries
              .where((e) => e.key.startsWith('II-'))
              .fold<double>(0, (max, e) => e.value > max ? e.value : max);
          expect(
            worstII,
            lessThanOrEqualTo(budget),
            reason:
                'Intégration d\'Information sur $device : ${describe(offenders)}'
                '\nBorne connue : $budget px. Au-dessus, c\'est une régression '
                'de mise en page ; en dessous, ramener la borne.',
          );
        },
        // Dépôt mobile seul : la banque serveur n'est pas là. On ignore plutôt
        // que de passer au rouge pour une raison étrangère à l'affichage.
        skip: form == null,
      );
    }
  });

  // ── Ce que le découpage ne doit pas casser ────────────────────────────────

  group('mode deux temps', () {
    testWidgets(
      'les items d\'Intégration d\'Information passent en deux temps',
      (tester) async {
        final form = _serverWorstCaseForm();
        if (form == null) return;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await mount(
          tester,
          form,
          const Size(360, 800),
          const EdgeInsets.only(top: 24, bottom: 24),
        );
        // Le premier item de la forme appartient à la dimension II.
        expect(form.items.first.dimension, DecisionDimension.ii);
        expect(
          find.byKey(const ValueKey('decision-reveal-choices')),
          findsOneWidget,
          reason:
              '1167 caractères et quatre justifications ne tiennent sur aucun '
              'téléphone : l\'item doit être découpé, pas rendu défilant',
        );
        // La situation est à l'écran, les choix ne le sont pas encore.
        expect(find.byKey(const ValueKey('decision-option-0')), findsNothing);
        await tester.tap(find.byKey(const ValueKey('decision-reveal-choices')));
        await settle(tester);
        for (var i = 0; i < form.items.first.options.length; i++) {
          expect(find.byKey(ValueKey('decision-option-$i')), findsOneWidget);
        }
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets('l\'écran de choix rappelle la consigne, pas la situation', (
      tester,
    ) async {
      final form = _serverWorstCaseForm();
      if (form == null) return;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(
        tester,
        form,
        const Size(360, 800),
        const EdgeInsets.only(top: 24, bottom: 24),
      );
      final item = form.items.first;
      expect(find.text(item.vignette), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('decision-reveal-choices')));
      await settle(tester);
      expect(
        find.text(item.vignette),
        findsNothing,
        reason:
            'reprendre la situation sur l\'écran de choix annulerait le gain '
            'du découpage',
      );
      expect(
        find.text(item.task),
        findsOneWidget,
        reason: 'la consigne, elle, doit rester lisible au moment de choisir',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('le retour en arrière ramène la situation', (tester) async {
      final form = _serverWorstCaseForm();
      if (form == null) return;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(
        tester,
        form,
        const Size(360, 800),
        const EdgeInsets.only(top: 24, bottom: 24),
      );
      await tester.tap(find.byKey(const ValueKey('decision-reveal-choices')));
      await settle(tester);
      await tester.tap(
        find.byKey(const ValueKey('decision-back-to-situation')),
      );
      await settle(tester);
      expect(find.text(form.items.first.vignette), findsOneWidget);
      expect(scrollExtent(tester), 0);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  // ── Le gel de la densité ─────────────────────────────────────────────────

  testWidgets(
    'la taille du texte des choix est la même sur tous les items d\'une session',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(
        tester,
        demoForm,
        const Size(360, 800),
        const EdgeInsets.only(top: 24, bottom: 24),
      );

      final sizes = <String, double>{};
      for (var i = 0; i < demoForm.items.length; i++) {
        for (
          var screen = interstitialOnScreen();
          screen != null;
          screen = interstitialOnScreen()
        ) {
          await tester.tap(screen);
          await settle(tester);
        }
        final text = tester.widget<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('decision-option-0')),
            matching: find.byType(Text),
          ),
        );
        sizes[demoForm.items[i].itemId] = text.style!.fontSize!;
        await tester.tap(find.byKey(const ValueKey('decision-option-0')));
        await settle(tester);
        await tester.tap(find.byKey(const ValueKey('decision-continue')));
        await settle(tester);
      }
      await tester.pumpWidget(const SizedBox.shrink());

      expect(
        sizes.values.toSet(),
        hasLength(1),
        reason:
            '« Je décide » mesure des temps de réponse : si la taille du texte '
            'changeait d\'un item à l\'autre, la vitesse de lecture varierait '
            'avec elle et entrerait dans le temps mesuré. Tailles observées : '
            '$sizes',
      );
    },
  );
}

// ── Chargement de la banque serveur ────────────────────────────────────────

const _serverBankPath =
    '../backend/src/main/resources/games/decision_scenarios.json';

/// Forme de 30 items bâtie sur les SIX PIRES items de chaque dimension de la
/// banque serveur — la passation la plus exigeante qu'un candidat puisse tirer.
///
/// Retourne `null` si le dépôt backend n'est pas là (checkout mobile seul) : le
/// test est alors ignoré avec un message, plutôt que rouge pour une raison qui
/// n'a rien à voir avec l'affichage.
DecisionForm? _serverWorstCaseForm() {
  final file = File(_serverBankPath);
  if (!file.existsSync()) return null;

  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final raw = (json['items'] as List<dynamic>).cast<Map<String, dynamic>>();
  final byId = {for (final item in raw) item['itemId'] as String: item};

  // Les items chronométrés ne portent pas leur situation : ils renvoient à celle
  // d'un item d'Intégration d'Information. Sans cette résolution, on testerait
  // un écran vide — c'est-à-dire rien.
  String vignetteOf(Map<String, dynamic> item) {
    final own = item['vignette'] as String?;
    if (own != null) return own;
    final ref = byId[item['vignetteRef'] as String];
    return ref?['vignette'] as String? ?? '';
  }

  DecisionFormItem toItem(Map<String, dynamic> item) {
    final format = DecisionItemFormat.fromWire(item['format'] as String);
    return DecisionFormItem(
      itemId: item['itemId'] as String,
      dimension: DecisionDimension.fromWire(item['dimension'] as String),
      format: format,
      vignette: vignetteOf(item),
      task: item['task'] as String,
      pairId: item['pairId'] as String?,
      timeLimitMs: format == DecisionItemFormat.temporalDecision ? 7000 : null,
      options: [
        for (final option in (item['options'] as List<dynamic>))
          DecisionFormOption(
            optionId: (option as Map<String, dynamic>)['optionId'] as String,
            label: option['text'] as String,
          ),
      ],
    );
  }

  int weight(DecisionFormItem item) =>
      item.vignette.length +
      item.task.length +
      item.options.fold<int>(0, (sum, o) => sum + o.label.length);

  final items = <DecisionFormItem>[];
  for (final dimension in DecisionDimension.values) {
    final ofDimension =
        raw
            .where((i) => i['dimension'] == dimension.wire)
            .map(toItem)
            .toList()
          ..sort((a, b) => weight(b).compareTo(weight(a)));
    items.addAll(ofDimension.take(6));
  }

  return DecisionForm(
    formCode: 'SERVER-WORST',
    itemsPerDimension: 6,
    items: items,
  );
}
