import 'package:zennyt/features/games/domain/config/decision_config.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zennyt/features/games/data/demo_games_repository.dart';
import 'package:zennyt/core/audio/sound_service.dart';
import 'package:zennyt/features/games/domain/entities/decision_form.dart';
import 'package:zennyt/features/games/domain/entities/decision_metrics.dart';
import 'package:zennyt/features/games/presentation/view/je_decide_gameplay.dart';

/// Le test qui manquait — et dont l'absence a laissé passer DEUX fois la même
/// remarque client : « il faut adapter le UI selon la taille de l'écran afin que
/// le scénario et les choix s'affichent entièrement sans défilement ».
///
/// Les tests existants se servaient d'items ÉCRITS À LA MAIN : deux options
/// courtes, trois au plus. Or les 24 items du build de démo en ont tous QUATRE,
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
    ('390×844 iPhone 14', Size(390, 844), EdgeInsets.only(top: 47, bottom: 34)),
    ('412×915 Pixel 7', Size(412, 915), EdgeInsets.only(top: 24, bottom: 24)),
  ];

  // ── Outillage ────────────────────────────────────────────────────────────

  Future<void> mount(
    WidgetTester tester,
    DecisionForm form,
    Size size,
    EdgeInsets insets, {
    double scale = 1,
  }) async {
    // Repartir d'un arbre vide : une nouvelle `physicalSize` posée en cours de
    // test ne se propage pas tant que l'ancien `MediaQuery` est monté.
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            padding: insets,
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(
            body: RepaintBoundary(
              key: const ValueKey('decision-gameplay-capture'),
              child: DecisionGameplayView(
                form: form,
                onClose: () {},
                onComplete: (_) {},
              ),
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

      check('$device · $itemId (choix)', itemId);
      expect(
        find.byKey(const ValueKey('decision-reveal-choices')),
        findsNothing,
      );
      expect(find.text(form.items[i].vignette), findsOneWidget);
      for (final option in form.items[i].options) {
        expect(find.text(option.label), findsOneWidget);
      }
      final last = find.byKey(
        ValueKey('decision-option-${form.items[i].options.length - 1}'),
      );
      await tester.ensureVisible(last);
      await tester.pump();
      expect(
        tester.getRect(last).bottom,
        lessThanOrEqualTo(
          tester.getRect(find.byKey(const ValueKey('decision-continue'))).top,
        ),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('decision-option-0')),
      );
      await tester.pump();

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

  group('banque de démo (24 items, celle du build client)', () {
    for (final (device, size, insets) in devices) {
      testWidgets('une seule page accessible sur $device', (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await mount(tester, demoForm, size, insets);
        final offenders = await playWholeForm(
          tester,
          form: demoForm,
          device: device,
        );
        if (size.width >= 390 || (size.height >= 800 && insets.vertical == 0)) {
          expect(
            offenders,
            isEmpty,
            reason:
                'les gabarits de référence affichent tous les choix sans défilement : '
                '${describe(offenders)}',
          );
        }
      });
    }
  });

  // ── La banque serveur : le pire de chaque dimension ───────────────────────

  group('banque serveur active : 24 questions sur un seul écran', () {
    final form = _serverWorstCaseForm();
    for (final (device, size, insets) in devices) {
      testWidgets(
        'banque active sur une seule page accessible sur $device',
        (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          expect(form!.totalItems, 24);
          expect(
            form.items.any((item) => item.dimension == DecisionDimension.ii),
            isFalse,
          );
          await mount(tester, form, size, insets);
          final offenders = await playWholeForm(
            tester,
            form: form,
            device: device,
          );
          if (size.width >= 390 ||
              (size.height >= 800 && insets.vertical == 0)) {
            expect(offenders, isEmpty, reason: describe(offenders));
          }
          expect(
            find.byKey(const ValueKey('decision-reveal-choices')),
            findsNothing,
          );
        },
        skip: form == null,
      );
    }
  });

  testWidgets('un écran unique présente situation et réponses ; capture', (
    tester,
  ) async {
    final form = _serverWorstCaseForm();
    expect(form, isNotNull);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(
      tester,
      form!,
      const Size(390, 844),
      const EdgeInsets.only(top: 47, bottom: 34),
    );
    expect(find.text(form.items.first.vignette), findsOneWidget);
    for (final option in form.items.first.options) {
      expect(find.text(option.label), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('decision-reveal-choices')), findsNothing);
    expect(
      find.byKey(const ValueKey('decision-reading-progress')),
      findsNothing,
    );
    expect(find.text('Relire'), findsNothing);
    await expectLater(
      find.byKey(const ValueKey('decision-gameplay-capture')),
      matchesGoldenFile('goldens/je-decide-active-question.png'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'texte à 200 % : situation et réponses restent accessibles sur la même page',
    (tester) async {
      final form = _serverWorstCaseForm();
      expect(form, isNotNull);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(
        tester,
        form!,
        const Size(360, 600),
        EdgeInsets.zero,
        scale: 2,
      );
      expect(find.text(form.items.first.vignette), findsOneWidget);
      expect(
        find.byKey(const ValueKey('decision-reveal-choices')),
        findsNothing,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('decision-option-3')),
      );
      await settle(tester);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

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

/// Forme de 24 items bâtie sur les SIX PIRES items de chaque dimension de la
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
  for (final dimension in DecisionConfig.dimensions) {
    final ofDimension =
        raw.where((i) => i['dimension'] == dimension.wire).map(toItem).toList()
          ..sort((a, b) => weight(b).compareTo(weight(a)));
    items.addAll(ofDimension.take(6));
  }

  return DecisionForm(
    formCode: 'SERVER-WORST',
    itemsPerDimension: 6,
    items: items,
  );
}

class _SilentStreamHandler extends MockStreamHandler {
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {}
  @override
  void onCancel(Object? arguments) {}
}
