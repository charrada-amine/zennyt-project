// Audit d'affichage — défilement indésirable et débordement, jeu par jeu,
// écran par écran, sur sept gabarits d'appareil.
//
// Ce fichier NE FAIT PAS ÉCHOUER la suite : il MESURE. Chaque sonde relève
// l'extension de défilement maximale de l'arbre et la première exception de
// rendu (RenderFlex overflowed…), puis le tout est écrit en JSON pour être
// dépouillé. Les assertions de non-régression vivent dans les tests dédiés de
// chaque jeu.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zennyt/core/audio/sound_service.dart';
import 'package:zennyt/core/storage/shared_preferences_provider.dart';
import 'package:zennyt/features/auth/presentation/current_user_provider.dart';
import 'package:zennyt/features/games/data/games_mock_repository.dart';
import 'package:zennyt/features/games/data/reflective_pause_bank_loader.dart';
import 'package:zennyt/features/games/data/strategic_choices_bank_loader.dart';
import 'package:zennyt/features/games/presentation/games_providers.dart';
import 'package:zennyt/features/games/presentation/view/continuous_attention_screen.dart';
import 'package:zennyt/features/games/presentation/view/coordination_tracking_screen.dart';
import 'package:zennyt/features/games/presentation/view/emotional_radar_screen.dart';
import 'package:zennyt/features/games/presentation/view/investigate_screen.dart';
import 'package:zennyt/features/games/presentation/view/je_decide_screen.dart';
import 'package:zennyt/features/games/presentation/view/je_place_screen.dart';
import 'package:zennyt/features/games/presentation/view/move_fast_screen.dart';
import 'package:zennyt/features/games/presentation/view/planifik_screen.dart';
import 'package:zennyt/features/games/presentation/view/predictive_puzzle_screen.dart';
import 'package:zennyt/features/games/presentation/view/reflective_pause_screen.dart';
import 'package:zennyt/features/games/presentation/view/strategic_choices_screen.dart';
import 'package:zennyt/features/games/presentation/view/task_scheduling_screen.dart';

// ── Le parc d'appareils ────────────────────────────────────────────────────

const devices = <(String, Size, EdgeInsets)>[
  ('320x568', Size(320, 568), EdgeInsets.zero),
  ('360x640', Size(360, 640), EdgeInsets.zero),
  ('360x800 nu', Size(360, 800), EdgeInsets.zero),
  ('360x800 gestes', Size(360, 800), EdgeInsets.only(top: 24, bottom: 24)),
  ('360x800 3 boutons', Size(360, 800), EdgeInsets.only(top: 24, bottom: 48)),
  ('390x844 iPhone 14', Size(390, 844), EdgeInsets.only(top: 47, bottom: 34)),
  ('412x915 Pixel 7', Size(412, 915), EdgeInsets.only(top: 24, bottom: 24)),
  ('768x1024 tablette', Size(768, 1024), EdgeInsets.only(top: 24)),
];

// ── Le journal ─────────────────────────────────────────────────────────────

final probes = <Map<String, dynamic>>[];

class Recorder {
  Recorder(this.tester, this.game, this.device);
  final WidgetTester tester;
  final String game;
  final String device;

  /// Détail de CHAQUE zone défilante de l'arbre : axe, débordement et nature.
  ///
  /// Le carrousel horizontal d'un deck de tutoriel défile par construction —
  /// c'est le geste attendu. Seul l'axe vertical raconte un contenu qui ne
  /// tient pas dans l'écran.
  List<Map<String, dynamic>> _scrollables() {
    final out = <Map<String, dynamic>>[];
    for (final state in tester.stateList<ScrollableState>(
      find.byType(Scrollable),
    )) {
      if (!state.position.hasContentDimensions) continue;
      final pageView = state.context
          .findAncestorWidgetOfExactType<PageView>();
      out.add({
        'axis': state.position.axis.name,
        'extent': double.parse(
          state.position.maxScrollExtent.toStringAsFixed(1),
        ),
        'viewport': double.parse(
          state.position.viewportDimension.toStringAsFixed(1),
        ),
        'pageView': pageView != null,
      });
    }
    return out;
  }

  /// Boutons d'action dessinés en dehors de la zone sûre : visibles sur la
  /// maquette, rognés ou sous une barre système sur l'appareil.
  List<String> _clippedButtons() {
    final out = <String>[];
    for (final element in find.bySubtype<ButtonStyleButton>().evaluate()) {
      final box = element.renderObject;
      if (box is! RenderBox || !box.hasSize || box.size.isEmpty) continue;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      if (rect.bottom <= safeArea.bottom + 0.5 &&
          rect.top >= safeArea.top - 0.5) {
        continue;
      }
      final label = find
          .descendant(
            of: find.byWidget(element.widget),
            matching: find.byType(Text),
          )
          .evaluate()
          .map((e) => (e.widget as Text).data)
          .whereType<String>()
          .join(' ');
      out.add(
        '${label.isEmpty ? element.widget.runtimeType : label} · '
        'bas=${rect.bottom.toStringAsFixed(0)} '
        '(zone sûre ${safeArea.bottom.toStringAsFixed(0)})',
      );
    }
    return out;
  }

  double _worstVertical() {
    var worst = 0.0;
    for (final s in _scrollables()) {
      if (s['axis'] != 'vertical') continue;
      final e = s['extent'] as double;
      if (e > worst) worst = e;
    }
    return worst;
  }

  bool _hasScrollable() => find.byType(Scrollable).evaluate().isNotEmpty;

  void call(String screen) {
    final error = tester.takeException();
    final offScreen = offScreenControl;
    offScreenControl = null;
    probes.add({
      'game': game,
      'device': device,
      'screen': screen,
      'scroll': _worstVertical(),
      'scrollable': _hasScrollable(),
      'detail': _scrollables(),
      'offScreen': offScreen,
      'clipped': _clippedButtons(),
      'texts': tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .where((t) => t.trim().isNotEmpty)
          .take(8)
          .toList(),
      'error': error == null ? null : error.toString().split('\n').first,
    });
  }

  void note(String screen, String message) {
    probes.add({
      'game': game,
      'device': device,
      'screen': screen,
      'scroll': -1,
      'scrollable': false,
      'error': message,
    });
  }
}

// ── Outillage ──────────────────────────────────────────────────────────────

Future<void> mount(
  WidgetTester tester,
  Size size,
  EdgeInsets insets,
  Widget home,
) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  safeArea = Rect.fromLTRB(
    0,
    insets.top,
    size.width,
    size.height - insets.bottom,
  );
  await tester.pumpWidget(const SizedBox.shrink());
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gamesRepositoryProvider.overrideWithValue(GamesMockRepository()),
        sharedPreferencesProvider.overrideWithValue(preferences),
        currentUserProvider.overrideWithValue(null),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size, padding: insets),
          child: home,
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> settle(WidgetTester tester, [int frames = 6]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// Dernier contrôle tapé hors écran, s'il y en a eu un.
String? offScreenControl;

/// Zone réellement utilisable de l'appareil courant : la dalle MOINS les
/// encoches et barres système. Un contrôle dessiné en dessous n'est pas
/// seulement laid — il est rogné, donc intouchable.
Rect safeArea = Rect.zero;

Future<bool> tapText(WidgetTester tester, String label) async {
  var finder = find.text(label);
  if (finder.evaluate().isEmpty) {
    // Liste paresseuse : le contrôle n'est pas seulement hors écran, il n'est
    // pas construit. C'est le pire cas — rien ne signale au joueur qu'il existe.
    final scroller = find.byType(Scrollable);
    if (scroller.evaluate().isEmpty) return false;
    try {
      await tester.scrollUntilVisible(finder, 120, scrollable: scroller.first);
    } catch (_) {
      return false;
    }
    await settle(tester, 3);
    finder = find.text(label);
    if (finder.evaluate().isEmpty) return false;
    offScreenControl = '« $label » non construit : la liste paresseuse de '
        'l\'écran ne le crée qu\'une fois défilée jusqu\'à lui';
    await tester.tap(finder.first, warnIfMissed: false);
    await settle(tester);
    return true;
  }
  final rect = tester.getRect(finder.first);
  if (rect.top < safeArea.top - 0.5 || rect.bottom > safeArea.bottom + 0.5) {
    offScreenControl =
        '« $label » hors zone sûre (bas = ${rect.bottom.toStringAsFixed(0)} px '
        'pour ${safeArea.bottom.toStringAsFixed(0)} px utilisables)';
    await tester.ensureVisible(finder.first);
    await settle(tester, 3);
  }
  await tester.tap(finder.first, warnIfMissed: false);
  await settle(tester);
  return true;
}

/// Parcourt un deck `GameTutorialDeck` carte par carte et sonde chacune.
/// Rend le nombre de cartes parcourues.
Future<int> walkDeck(
  WidgetTester tester,
  Recorder rec, {
  required String completionLabel,
  String label = 'Tutoriel',
  int maxCards = 10,
}) async {
  var card = 0;
  while (card < maxCards) {
    rec('$label — carte ${card + 1}');
    if (find.text(completionLabel).evaluate().isNotEmpty) {
      await tapText(tester, completionLabel);
      return card + 1;
    }
    if (!await tapText(tester, 'Suivant')) return card + 1;
    card++;
  }
  return card;
}

Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void silenceAudio() {
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
  SoundService.instance.setSfxEnabled(false);
  SoundService.instance.setMusicEnabled(false);
}

// ── Le balayage ────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    silenceAudio();
    ReflectivePauseBankLoader.resetForTest();
    await ReflectivePauseBankLoader.load();
    StrategicChoicesBankLoader.resetForTest();
    await StrategicChoicesBankLoader.load();
  });

  tearDownAll(() {
    final out = File('build/ui_audit.json');
    out.parent.createSync(recursive: true);
    out.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(probes));
    // ignore: avoid_print
    print('AUDIT_JSON_AT ${out.absolute.path} (${probes.length} sondes)');
  });

  void sweep(
    String game,
    Future<void> Function(WidgetTester, Recorder, Size, EdgeInsets) walk,
  ) {
    for (final (device, size, insets) in devices) {
      testWidgets('$game · $device', (tester) async {
        addTearDown(tester.view.reset);
        final rec = Recorder(tester, game, device);
        offScreenControl = null;
        try {
          await walk(tester, rec, size, insets);
        } catch (e) {
          rec.note('PARCOURS INTERROMPU', e.toString().split('\n').first);
        }
        await unmount(tester);
      });
    }
  }

  // ── Je planifie #1 — Chemin optimal ──────────────────────────────────────
  sweep('Planifik / Chemin optimal', (tester, rec, size, insets) async {
    await mount(tester, size, insets, const PlanifikScreen());
    await settle(tester);
    rec('Intro / couverture');
    await tapText(tester, 'Commencer');
    await walkDeck(tester, rec, completionLabel: 'Commencer le parcours');
    await settle(tester);
    rec('Jeu (plateau)');
  });

  // ── Je planifie #2 — Day Stack ───────────────────────────────────────────
  sweep('Planifik / Day Stack', (tester, rec, size, insets) async {
    await mount(tester, size, insets,
        const TaskSchedulingScreen(universeIndex: 0, variantSeed: 1, levelCount: 1));
    for (var i = 0; i < 25 && find.text('Commencer').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    rec('Intro / couverture');
    await tapText(tester, 'Commencer');
    await walkDeck(tester, rec, completionLabel: 'Je suis prêt');
    await settle(tester);
    rec('Jeu (planning)');
  });

  // ── Je planifie #3 — Tour de Hanoï ───────────────────────────────────────
  sweep('Planifik / Tour de Hanoi', (tester, rec, size, insets) async {
    await mount(tester, size, insets, const PredictivePuzzleScreen());
    await settle(tester);
    rec('Intro / couverture');
    await tapText(tester, 'Commencer');
    await walkDeck(tester, rec, completionLabel: 'Commencer à planifier');
    await settle(tester);
    rec('Jeu (planification)');
  });

  // ── Je bouge ─────────────────────────────────────────────────────────────
  sweep('Je bouge / Move Fast', (tester, rec, size, insets) async {
    await mount(tester, size, insets, const MoveFastScreen(seed: 4242));
    await settle(tester);
    rec('Intro / couverture');
    await tapText(tester, 'Commencer');
    rec('Tutoriel — règle Orientation');
    await tapText(tester, 'Droite');
    rec('Tutoriel — règle Mouvement');
    await tapText(tester, 'Droite');
    await settle(tester);
    rec('Jeu (plateau)');
  });

  // ── Je continue ──────────────────────────────────────────────────────────
  sweep('Je continue / Focus Stream', (tester, rec, size, insets) async {
    await mount(tester, size, insets, const ContinuousAttentionScreen());
    await settle(tester);
    rec('Couverture');
    await tapText(tester, 'Start the journey');
    rec('Format du parcours');
    await tapText(tester, 'Learn the first rule');
    rec('Tutoriel — règle X');
    await tapText(tester, 'Start practice');
    await settle(tester);
    rec('Jeu (flux)');
  });

  // ── Je coordonne ─────────────────────────────────────────────────────────
  sweep('Je coordonne / Sync Square', (tester, rec, size, insets) async {
    await mount(tester, size, insets, const CoordinationTrackingScreen());
    await settle(tester);
    rec('Couverture');
    await tapText(tester, 'Start the journey');
    await settle(tester);
    rec('Tutoriel — carte 1');
    await tapText(tester, 'Next');
    rec('Tutoriel — carte 2');
    await tapText(tester, 'Next');
    rec('Tutoriel — carte 3');
    await tapText(tester, 'Begin practice');
    await settle(tester);
    rec('Jeu (poursuite)');
  });

  // ── J'investigue ─────────────────────────────────────────────────────────
  sweep('J\'investigue / Memory Quest', (tester, rec, size, insets) async {
    await mount(tester, size, insets, const InvestigateScreen());
    await settle(tester);
    rec('Intro / couverture');
    await tapText(tester, 'Commencer la mission');
    await walkDeck(tester, rec, completionLabel: 'Je suis prêt');
    await settle(tester);
    rec('Jeu (observation)');
    // L'observation d'une séquence s'enchaîne par `Future.delayed`, qu'aucun
    // `dispose` ne peut annuler. On la laisse se terminer, sinon le binding
    // signale une minuterie en attente qui n'a rien à voir avec l'affichage.
    await tester.pump(const Duration(seconds: 3));
    await settle(tester, 20);
  });

  // ── Je place ─────────────────────────────────────────────────────────────
  sweep('Je place / Place & Bind', (tester, rec, size, insets) async {
    await mount(tester, size, insets, const JePlaceScreen());
    await settle(tester);
    rec('Couverture');
    await tapText(tester, 'Start the journey');
    await settle(tester);
    rec('Tutoriel — carte 1');
    await tapText(tester, 'Next');
    rec('Tutoriel — carte 2');
    await tapText(tester, 'Next');
    rec('Tutoriel — carte 3');
    await tapText(tester, 'Begin practice');
    await settle(tester);
    rec('Jeu (encodage)');
  });

  // ── Je décide ────────────────────────────────────────────────────────────
  sweep('Je décide', (tester, rec, size, insets) async {
    await mount(tester, size, insets, const JeDecideScreen());
    await settle(tester);
    rec('Accueil / couverture');
    await tapText(tester, 'Commencer');
    await settle(tester);
    await walkDeck(tester, rec, completionLabel: 'Essayer l’exemple');
    await settle(tester);
    rec('Scénario d\'entraînement (questions-réponses)');
  });

  // ── Je gère #1 — Emotional Radar ─────────────────────────────────────────
  sweep('Je gère / Emotional Radar', (tester, rec, size, insets) async {
    await mount(tester, size, insets, const EmotionalRadarScreen());
    await settle(tester);
    rec('Couverture');
    await tapText(tester, 'Commencer le tutoriel');
    await walkDeck(tester, rec, completionLabel: 'Commencer la partie');
    await settle(tester, 10);
    rec('Scène (questions-réponses)');
  });

  // ── Je gère #2 — Reflective Pause ────────────────────────────────────────
  sweep('Je gère / Reflective Pause', (tester, rec, size, insets) async {
    await mount(tester, size, insets, const ReflectivePauseScreen());
    await settle(tester);
    rec('Couverture');
    await tapText(tester, 'View tutorial');
    await settle(tester);
    rec('Intro');
    await tapText(tester, 'Continuer');
    await walkDeck(tester, rec, completionLabel: 'Commencer la partie');
    await settle(tester, 10);
    rec('Situation (questions-réponses)');
  });

  // ── Je gère #3 — Strategic Choices ───────────────────────────────────────
  sweep('Je gère / Strategic Choices', (tester, rec, size, insets) async {
    await mount(tester, size, insets, const StrategicChoicesScreen());
    await settle(tester);
    rec('Couverture');
    await tapText(tester, 'View tutorial');
    await settle(tester);
    rec('Intro');
    await tapText(tester, 'Continuer');
    await walkDeck(tester, rec, completionLabel: 'Commencer la partie');
    await settle(tester, 10);
    rec('Situation (questions-réponses)');
  });
}
