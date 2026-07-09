import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/domain/entities/memory_object.dart';
import 'package:zennyt/features/games/presentation/view/investigate_screen.dart';

/// « J'investigue » — Mission A (Digit Span). Vérifie la machine à états
/// intro → tutorial → observe → recall (même ordre) → recall (inverse) →
/// résultats, et le score mock (0–5 par tâche → composite /100).
void main() {
  const seed = 12345;
  // Séquence du 1er round (longueur de départ = 4), reproductible via la graine.
  final r = math.Random(seed);
  final sequence = List<int>.generate(4, (_) => r.nextInt(10));

  Future<void> typeDigits(WidgetTester tester, List<int> digits) async {
    for (final d in digits) {
      await tester.tap(find.byKey(ValueKey('kp-$d')));
      await tester.pump();
    }
  }

  testWidgets(
      'Flux complet A+B+distraction : digits → objets → distraction → résultats',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    List<MemoryObject> initialObjects = const [];
    List<int> distractSeq = const [];
    int distractAnswer = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: InvestigateScreen(
            seed: seed,
            onMissionBReady: (order) => initialObjects = order,
            onDistractionReady: (seq, answer) {
              distractSeq = seq;
              distractAnswer = answer;
            },
          ),
        ),
      ),
    );

    // Intro → Tutorial → observation.
    await tester.tap(find.text('Start mission'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I am ready'));
    await tester.pump(); // démarre l'observation

    // Observation verrouillée : le clavier n'est pas encore là.
    expect(find.byKey(const ValueKey('kp-1')), findsNothing);

    // Déroule les 4 chiffres (900 ms) + ISI (250 ms) + amorce (350 ms).
    await tester.pump(const Duration(milliseconds: 5200));

    // Rappel MÊME ordre.
    expect(find.textContaining('SAME order'), findsOneWidget);
    await typeDigits(tester, sequence);
    await tester.tap(find.text('Validate'));
    await tester.pump();

    // Rappel INVERSE — l'original reste caché.
    expect(find.textContaining('REVERSE order'), findsOneWidget);
    // On saisit un inverse VOLONTAIREMENT faux (1 chiffre changé) → pas parfait
    // → fin de mission (résultats) plutôt que round suivant.
    final wrongReverse = sequence.reversed.toList();
    wrongReverse[0] = (wrongReverse[0] + 1) % 10;
    await typeDigits(tester, wrongReverse);
    await tester.tap(find.text('Validate'));

    // Fin Mission A → feedback (250 ms) → Mission B (observation d'objets).
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('Memorize the starting order'), findsOneWidget);
    expect(initialObjects, hasLength(4));

    // Observation (5 s) → manipulations auto (2 × 1500 ms) → restauration.
    await tester.pump(const Duration(milliseconds: 5200));
    await tester.pump(const Duration(milliseconds: 3200));
    expect(find.text('Restore the STARTING order'), findsOneWidget);

    // Tap-to-place : on replace les objets dans l'ORDRE INITIAL (→ restore 5/5).
    for (final obj in initialObjects) {
      await tester.tap(find.text(obj.labelEn).first);
      await tester.pump();
    }
    await tester.tap(find.text('Validate'));

    // Fin Mission B → phase de DISTRACTION : encodage d'une séquence à protéger.
    await tester.pump(const Duration(milliseconds: 1000));
    expect(distractSeq, hasLength(4));
    await tester.pump(const Duration(milliseconds: 5200)); // encode → question

    // Question rapide dimmée + rappel mémoire visible.
    expect(find.textContaining('Quick check'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('choice-$distractAnswer'))); // bonne réponse
    await tester.pump();

    // Rappel APRÈS distraction : on retape la séquence protégée (→ 5/5).
    expect(find.textContaining('Now recall'), findsOneWidget);
    await typeDigits(tester, distractSeq);
    await tester.tap(find.text('Validate'));
    // Soumission au repo (mock : 2 × 150 ms) → score serveur + panneau de détail.
    await tester.pump(const Duration(milliseconds: 500));

    // Résultats + composite calculé PAR LE REPO (mock, parité backend) :
    // same 5/5, reverse 4/5, restore 5/5, after-distraction 5/5
    // → moyenne (5+4+5+5)/4 = 4.75 /5 → 95 %.
    expect(find.text('Results'), findsOneWidget);
    expect(find.text('95%'), findsOneWidget); // composite (carte principale)
    expect(find.text('Correct'), findsOneWidget); // quick check (tuile)
    // Tuiles + lignes du panneau : les scores apparaissent (au moins une fois).
    expect(find.text('4/5'), findsWidgets); // reverse
    expect(find.text('5/5'), findsWidgets); // same / restore / after-distraction
    // Panneau « détail du score » alimenté par le repo (offline via le mock).
    expect(find.text('Détail du score'), findsOneWidget);
  });
}
