import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/domain/config/memory_quest_config.dart';
import 'package:zennyt/features/games/domain/entities/memory_object.dart';
import 'package:zennyt/features/games/presentation/view/investigate_screen.dart';

/// « J'investigue » — système de niveaux : **un seul tour par niveau**. Après
/// le tour du niveau 1 on passe au niveau 2 (longueur 4) ; distraction ABSENTE
/// aux niveaux 1-2.
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
      'un tour au niveau 1 joue la distraction (active dès le niveau 1)',
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

    // Observation des 3 chiffres (900 ms + ISI 1000 + amorce 350) = ~6050 ms.
    await tester.pump(const Duration(milliseconds: 6300));

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

    // Observation (5 s) + manipulations auto (2 × 2 × 750 ms) + rétention 3 s
    // avant le rappel → restauration.
    await tester.pump(const Duration(milliseconds: 5200));
    await tester.pump(const Duration(milliseconds: 6200));
    expect(find.text('Restore the STARTING order'), findsOneWidget);

    // Restauration → fin du tour du niveau 1 → montée automatique au niveau 2.
    for (final obj in initialObjects) {
      await tester.tap(find.text(obj.labelEn).first);
      await tester.pump();
    }
    await tester.tap(find.text('Validate'));
    await tester.pump();

    // La distraction est désormais jouée DÈS le niveau 1 (retour client : elle
    // ne se voyait jamais quand elle était gatée au niveau ≥ 3).
    expect(MemoryQuestConfig.distractionActiveAtLevel(1), isTrue);
    // Sa phase d'encodage précède la question : amorce 350 ms puis, pour chacun
    // des 4 chiffres, 900 ms d'affichage + 1000 ms d'intervalle.
    await tester.pump(const Duration(milliseconds: 8200));
    expect(find.textContaining('Quick check'), findsOneWidget);

    // Ce test s'arrête ici : il verrouille la PRÉSENCE de la distraction au
    // niveau 1. La suite du parcours (réponse à la question, rappel après
    // distraction, montée au niveau 2) est couverte par le déroulé complet du
    // jeu, pas par ce garde-fou.
    //
    // Démonter l'arbre annule les timers de la phase de distraction ; les
    // laisser en vol ferait échouer le teardown.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
