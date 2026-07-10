import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/domain/config/memory_quest_config.dart';
import 'package:zennyt/features/games/domain/entities/memory_object.dart';
import 'package:zennyt/features/games/presentation/view/investigate_screen.dart';

/// « J'investigue » — système de niveaux : 3 tâches réussies au niveau 1 →
/// niveau 2 (longueur 4) ; distraction ABSENTE aux niveaux 1-2.
void main() {
  const seed = 12345;
  // Séquence du niveau 1 : longueur = 3 (initial_sequence_length), graine fixe.
  final r = math.Random(seed);
  final level1Seq = List<int>.generate(
    MemoryQuestConfig.sequenceLengthForLevel(1),
    (_) => r.nextInt(10),
  );

  Future<void> typeDigits(WidgetTester tester, List<int> digits) async {
    for (final d in digits) {
      await tester.tap(find.byKey(ValueKey('kp-$d')));
      await tester.pump();
    }
  }

  testWidgets(
      '3 réussites au niveau 1 → niveau 2 (longueur 4) ; distraction absente au niveau 1',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    // Intro → Tutorial → observation (niveau 1).
    await tester.tap(find.text('Start mission'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I am ready'));
    await tester.pump();

    // On est au niveau 1.
    expect(find.text('Level 1'), findsOneWidget);

    // Observation des 3 chiffres (900 ms + ISI 250 + amorce 350).
    await tester.pump(const Duration(milliseconds: 4200));

    // Rappel MÊME ordre (parfait → tâche réussie #1).
    expect(find.textContaining('SAME order'), findsOneWidget);
    await typeDigits(tester, level1Seq);
    await tester.tap(find.text('Validate'));
    await tester.pump();

    // Rappel INVERSE (parfait → tâche réussie #2).
    expect(find.textContaining('REVERSE order'), findsOneWidget);
    await typeDigits(tester, level1Seq.reversed.toList());
    await tester.tap(find.text('Validate'));

    // Feedback → Mission B (observation d'objets), 4 objets au niveau 1.
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('Memorize the starting order'), findsOneWidget);
    expect(initialObjects, hasLength(4));

    // Observation (5 s) + manipulations auto (2 × 1500 ms) → restauration.
    await tester.pump(const Duration(milliseconds: 5200));
    await tester.pump(const Duration(milliseconds: 3200));
    expect(find.text('Restore the STARTING order'), findsOneWidget);

    // Restauration parfaite (tâche réussie #3) → 3 réussites → montée de niveau.
    for (final obj in initialObjects) {
      await tester.tap(find.text(obj.labelEn).first);
      await tester.pump();
    }
    await tester.tap(find.text('Validate'));
    await tester.pump();

    // Niveau 1 : PAS de distraction (gatée au niveau ≥ 3) — on enchaîne le niveau 2.
    expect(find.textContaining('Quick check'), findsNothing);
    // Montée de niveau : niveau 2, longueur de séquence = 4.
    expect(find.text('Level 2'), findsOneWidget);
    expect(MemoryQuestConfig.sequenceLengthForLevel(2), 4);

    // Laisse l'observation du niveau 2 se dérouler (évite les timers en attente).
    await tester.pump(const Duration(milliseconds: 5200));
    expect(find.textContaining('SAME order'), findsOneWidget);
  });
}
