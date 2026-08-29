import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/domain/config/memory_quest_config.dart';
import 'package:zennyt/features/games/domain/entities/memory_object.dart';
import 'package:zennyt/features/games/presentation/view/investigate_screen.dart';

/// « J'investigue » — déroulé validé avec le client :
///
/// > niveau 1 : 3 chiffres à mémoriser, rappel direct puis inverse ; quand
/// > c'est correct on monte d'un niveau (un chiffre de plus) ; au niveau 3 —
/// > et à chaque niveau ensuite — la distraction s'ajoute ; la partie s'arrête
/// > après **2 échecs sur un même niveau**.
///
/// Ces tests verrouillent les quatre règles de ce déroulé, plus la frontière
/// entre les deux moitiés du jeu (chiffres / images).
void main() {
  const seed = 12345;

  /// Séquences successives telles que l'écran les tire en mode « chiffres ».
  ///
  /// Le générateur est déterministe et n'est consommé, dans ce mode, que par la
  /// génération de séquence d'un tour : les rejouer dans l'ordre suffit à
  /// prédire chaque manche.
  math.Random rng() => math.Random(seed);

  List<int> drawSequence(math.Random r, int level) => List<int>.generate(
        MemoryQuestConfig.sequenceLengthForLevel(level),
        (_) => r.nextInt(10),
      );

  final level1Seq = drawSequence(rng(), 1);

  Future<void> typeDigits(WidgetTester tester, List<int> digits) async {
    for (final d in digits) {
      await tester.tap(find.byKey(ValueKey('kp-$d')));
      await tester.pump();
    }
  }

  void useLargeSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> startGame(WidgetTester tester) async {
    await tester.tap(find.text('Start mission'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I am ready'));
    await tester.pump();
  }

  /// Laisse défiler l'observation d'une séquence de [length] chiffres :
  /// amorce de 350 ms, puis 900 ms d'affichage + 1000 ms d'intervalle par
  /// chiffre. On ajoute une marge.
  Future<void> watchSequence(WidgetTester tester, int length) =>
      tester.pump(Duration(milliseconds: 350 + length * 1900 + 300));

  /// Joue un tour de chiffres : observation, éventuelle question
  /// d'interférence, rappel direct, rappel inverse, puis l'attente du panneau de
  /// feedback (250 + 550 ms).
  ///
  /// [answer] permet de répondre FAUX volontairement. [quizAnswer] est la bonne
  /// réponse de la question d'interférence, à passer dès le niveau
  /// [MemoryQuestConfig.distractionMinLevel].
  Future<void> playDigitRound(
    WidgetTester tester,
    List<int> sequence, {
    List<int>? answer,
    int? quizAnswer,
  }) async {
    await watchSequence(tester, sequence.length);
    if (quizAnswer != null) {
      // L'interférence s'intercale ICI, entre la mémorisation et le rappel :
      // aucune seconde séquence n'est présentée.
      expect(find.textContaining('Quick check'), findsOneWidget);
      await tester.tap(find.byKey(ValueKey('choice-$quizAnswer')));
      await tester.pump();
    }
    final direct = answer ?? sequence;
    await typeDigits(tester, direct);
    await tester.tap(find.text('Validate'));
    await tester.pump();
    await typeDigits(tester, direct.reversed.toList());
    await tester.tap(find.text('Validate'));
    await tester.pump(const Duration(milliseconds: 900));
  }

  testWidgets('Digits : la distraction n\'arrive qu\'au niveau 3',
      (tester) async {
    useLargeSurface(tester);

    var distractionsStarted = 0;
    List<int> protectedSeq = const [];
    var quizAnswer = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: InvestigateScreen(
            seed: seed,
            mode: InvestigateMode.digits,
            onDistractionReady: (seq, answer) {
              distractionsStarted++;
              protectedSeq = seq;
              quizAnswer = answer;
            },
          ),
        ),
      ),
    );
    await startGame(tester);

    final r = rng();

    // ── Niveau 1 : 3 chiffres, réussi → montée au niveau 2 ─────────────────
    expect(find.text('Level 1'), findsOneWidget);
    await playDigitRound(tester, drawSequence(r, 1));
    expect(distractionsStarted, 0, reason: 'pas de distraction au niveau 1');
    expect(find.text('Level 2'), findsOneWidget);

    // ── Niveau 2 : 4 chiffres, réussi → montée au niveau 3 ─────────────────
    await playDigitRound(tester, drawSequence(r, 2));
    expect(distractionsStarted, 0, reason: 'pas de distraction au niveau 2');
    expect(find.text('Level 3'), findsOneWidget);

    // ── Niveau 3 : 5 chiffres — l'interférence s'ajoute ────────────────────
    //
    // Elle arrive AVEC la première mémorisation du niveau : une seule séquence
    // est présentée, la question s'intercale avant le rappel. La version
    // précédente faisait mémoriser une SECONDE séquence (figée à 4 chiffres)
    // sous le même intitulé « Level 3 » — le client y voyait un niveau rejoué,
    // et la longueur plus courte lui donnait le sentiment de reculer.
    final level3Seq = drawSequence(r, 3);
    await watchSequence(tester, level3Seq.length);

    expect(distractionsStarted, 1, reason: 'la distraction arrive dès la '
        'première mémorisation du niveau 3');
    expect(find.textContaining('Quick check'), findsOneWidget);
    expect(
      protectedSeq,
      level3Seq,
      reason: 'la séquence à protéger est CELLE du niveau, pas une nouvelle',
    );

    await tester.tap(find.byKey(ValueKey('choice-$quizAnswer')));
    await tester.pump();

    // Rappel direct puis inverse de la séquence protégée — aucune seconde
    // mémorisation ne s'est intercalée.
    await typeDigits(tester, level3Seq);
    await tester.tap(find.text('Validate'));
    await tester.pump();
    await typeDigits(tester, level3Seq.reversed.toList());
    await tester.tap(find.text('Validate'));
    await tester.pump(const Duration(milliseconds: 900));

    expect(
      find.text('Level 4'),
      findsOneWidget,
      reason: 'un niveau intégralement réussi ne doit jamais se rejouer',
    );

    // Le niveau 4 relance une observation ; on la laisse atteindre le rappel
    // (état sans minuterie en vol) avant de démonter.
    await watchSequence(tester, MemoryQuestConfig.sequenceLengthForLevel(4));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  /// Le déroulé décrit par le client, appliqué au niveau 3 : la distraction
  /// revient à CHAQUE tour du niveau, et deux échecs sur ce même niveau
  /// terminent la partie — sans jamais raccourcir la séquence.
  testWidgets('Digits : deux échecs au niveau 3 terminent la partie',
      (tester) async {
    useLargeSurface(tester);

    // À partir du niveau 3, le hook livre la séquence du tour ET la réponse de
    // la question : inutile de rejouer le générateur, dont la question et ses
    // propositions consomment un nombre variable de tirages.
    List<int> roundSeq = const [];
    var quizAnswer = 0;
    var distractions = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: InvestigateScreen(
            seed: seed,
            mode: InvestigateMode.digits,
            onDistractionReady: (seq, answer) {
              distractions++;
              roundSeq = seq;
              quizAnswer = answer;
            },
          ),
        ),
      ),
    );
    await startGame(tester);

    final r = rng();
    await playDigitRound(tester, drawSequence(r, 1));
    await playDigitRound(tester, drawSequence(r, 2));
    expect(find.text('Level 3'), findsOneWidget);

    final level3Length = MemoryQuestConfig.sequenceLengthForLevel(3);

    /// Rate volontairement le tour du niveau 3, question d'interférence incluse.
    Future<void> failLevel3(int expectedDistractions) async {
      await watchSequence(tester, level3Length);
      expect(
        distractions,
        expectedDistractions,
        reason: 'la distraction précède la mémorisation à chaque tour du niveau',
      );
      expect(roundSeq, hasLength(level3Length));

      await tester.tap(find.byKey(ValueKey('choice-$quizAnswer')));
      await tester.pump();

      final wrong = [for (final d in roundSeq) (d + 1) % 10];
      await typeDigits(tester, wrong);
      await tester.tap(find.text('Validate'));
      await tester.pump();
      await typeDigits(tester, wrong.reversed.toList());
      await tester.tap(find.text('Validate'));
      await tester.pump(const Duration(milliseconds: 900));
    }

    await failLevel3(1);
    expect(
      find.text('Level 3'),
      findsOneWidget,
      reason: 'un premier échec rejoue le niveau, il ne le fait pas reculer',
    );

    await failLevel3(2);
    expect(find.text('Results'), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('Digits : un tour raté rejoue le MÊME niveau, deux le terminent',
      (tester) async {
    useLargeSurface(tester);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: InvestigateScreen(seed: seed, mode: InvestigateMode.digits),
        ),
      ),
    );
    await startGame(tester);

    final r = rng();

    // 1ᵉʳ échec : on répond à côté (chaque chiffre décalé de 1).
    final attempt1 = drawSequence(r, 1);
    await playDigitRound(
      tester,
      attempt1,
      answer: [for (final d in attempt1) (d + 1) % 10],
    );

    // La séquence ne s'allonge pas : on rejoue le niveau 1.
    expect(
      find.text('Level 1'),
      findsOneWidget,
      reason: 'un tour raté ne doit pas faire monter de niveau',
    );

    // 2ᵉ échec sur ce même niveau → fin de partie.
    final attempt2 = drawSequence(r, 1);
    await playDigitRound(
      tester,
      attempt2,
      answer: [for (final d in attempt2) (d + 1) % 10],
    );

    expect(find.text('Results'), findsOneWidget);

    // La soumission au dépôt de démo est asynchrone (latence simulée) : on la
    // laisse aboutir, sinon sa minuterie reste en vol au teardown.
    await tester.pumpAndSettle();
  });

  /// Déroulé d'un tour d'images : observation, manipulations, rétention.
  ///
  /// Le nombre d'objets fixe la durée d'observation (≈ 1,25 s par objet, 5 s au
  /// minimum), suivie de 2 × 2 × 750 ms de manipulations et de 3 s de rétention.
  Future<void> watchObjects(WidgetTester tester, int objectCount) async {
    final observationMs = MemoryQuestConfig.objectObservationMs(objectCount);
    await tester.pump(Duration(milliseconds: observationMs + 300));
    await tester.pump(const Duration(milliseconds: 3000 + 3000 + 300));
  }

  /// Le jeu des IMAGES ne présente que des objets — jamais de chiffres, la tâche
  /// parasite comprise. Il empruntait auparavant la question arithmétique du jeu
  /// des chiffres.
  testWidgets('Images : aucun chiffre, et l\'interférence arrive au niveau 2',
      (tester) async {
    useLargeSurface(tester);

    var missionBCount = 0;
    List<MemoryObject> objects = const [];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: InvestigateScreen(
            seed: seed,
            mode: InvestigateMode.images,
            onMissionBReady: (order) {
              missionBCount++;
              objects = order;
            },
          ),
        ),
      ),
    );
    await startGame(tester);

    /// Restaure l'ordre initial — parfait, donc le niveau monte.
    Future<void> restore() async {
      for (final obj in objects) {
        await tester.tap(find.text(obj.labelEn).first);
        await tester.pump();
      }
      await tester.tap(find.text('Validate'));
      await tester.pump();
    }

    // ── Niveau 1 : aucune interférence ─────────────────────────────────────
    expect(find.text('Level 1'), findsOneWidget);
    expect(objects, hasLength(3), reason: 'le jeu démarre à 3 objets');
    await watchObjects(tester, 3);
    expect(find.text('Restore the STARTING order'), findsOneWidget);
    expect(find.text('Find the odd one out'), findsNothing);
    expect(find.text('Complete the pattern'), findsNothing);
    await restore();

    // ── Niveau 2 : l'interférence s'intercale AVANT la restauration ────────
    // Le jeu des images l'introduit dès le second palier, plus tôt que le jeu
    // des chiffres (niveau 3).
    expect(find.text('Level 2'), findsOneWidget);
    expect(objects, hasLength(4), reason: 'un objet de plus par niveau');
    await watchObjects(tester, 4);

    // L'une des deux épreuves visuelles est présentée — jamais un calcul.
    final isOddOneOut = find.text('Find the odd one out').evaluate().isNotEmpty;
    expect(
      isOddOneOut || find.text('Complete the pattern').evaluate().isNotEmpty,
      isTrue,
      reason: 'une tâche parasite visuelle doit être à l\'écran',
    );
    expect(find.textContaining('+'), findsNothing,
        reason: 'aucun calcul : c\'est le jeu des images');
    expect(
      find.text('Restore the STARTING order'),
      findsNothing,
      reason: 'la tâche parasite précède la restauration',
    );
    // Le bandeau de charge compte des OBJETS : il affichait « 0 digits ».
    expect(find.text('4 objects'), findsOneWidget);

    // Répondre à l'épreuve (juste ou faux, peu importe ici) rend la main à la
    // restauration après un court retour visuel.
    await tester.tap(
      find
          .byKey(ValueKey(isOddOneOut ? 'odd-cell-0' : 'puzzle-option-0'))
          .first,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Restore the STARTING order'), findsOneWidget);
    await restore();

    expect(find.text('Level 3'), findsOneWidget);
    expect(missionBCount, 3, reason: 'un tour d\'objets par niveau, sans rejeu');

    await watchObjects(tester, 5);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Images : la restauration ne demande jamais l\'ordre inverse',
      (tester) async {
    useLargeSurface(tester);

    List<MemoryObject> initialObjects = const [];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: InvestigateScreen(
            seed: seed,
            mode: InvestigateMode.images,
            onMissionBReady: (order) => initialObjects = order,
          ),
        ),
      ),
    );
    await startGame(tester);

    // La manche commence directement par les objets.
    expect(find.text('Memorize the starting order'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 5200));
    await tester.pump(const Duration(milliseconds: 6200));
    expect(find.text('Restore the STARTING order'), findsOneWidget);

    for (final obj in initialObjects) {
      await tester.tap(find.text(obj.labelEn).first);
      await tester.pump();
    }
    await tester.tap(find.text('Validate'));
    await tester.pump();

    // Contrairement au jeu des chiffres, aucun rappel inversé ne suit : le tour
    // se termine sur la restauration et le niveau monte.
    expect(find.textContaining('REVERSE'), findsNothing);
    expect(find.text('Level 2'), findsOneWidget);

    // Le niveau 2 relance une mission d'objets, désormais suivie d'une tâche
    // parasite : on s'y arrête. Son compte à rebours est un `Timer` annulé au
    // dispose, donc le démontage y est propre.
    await tester.pump(const Duration(milliseconds: 6300));
    await tester.pump(const Duration(milliseconds: 6200));
    expect(find.textContaining('REVERSE'), findsNothing,
        reason: 'jamais d\'ordre inverse dans le jeu des images');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  /// Mode historique : les deux missions s'enchaînent dans une seule partie.
  testWidgets('Full : mission A puis mission B, sans distraction au niveau 1',
      (tester) async {
    useLargeSurface(tester);

    List<MemoryObject> initialObjects = const [];
    var distractionStarted = false;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: InvestigateScreen(
            seed: seed,
            onMissionBReady: (order) => initialObjects = order,
            onDistractionReady: (_, _) => distractionStarted = true,
          ),
        ),
      ),
    );
    await startGame(tester);

    expect(find.text('Level 1'), findsOneWidget);
    await watchSequence(tester, level1Seq.length);

    expect(find.textContaining('SAME order'), findsOneWidget);
    await typeDigits(tester, level1Seq);
    await tester.tap(find.text('Validate'));
    await tester.pump();

    expect(find.textContaining('REVERSE order'), findsOneWidget);
    await typeDigits(tester, level1Seq.reversed.toList());
    await tester.tap(find.text('Validate'));

    // Feedback → mission d'objets (3 objets au niveau 1).
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('Memorize the starting order'), findsOneWidget);
    expect(initialObjects, hasLength(MemoryQuestConfig.objectCountForLevel(1)));

    await tester.pump(const Duration(milliseconds: 5200));
    await tester.pump(const Duration(milliseconds: 6200));
    expect(find.text('Restore the STARTING order'), findsOneWidget);

    for (final obj in initialObjects) {
      await tester.tap(find.text(obj.labelEn).first);
      await tester.pump();
    }
    await tester.tap(find.text('Validate'));
    await tester.pump();

    // Niveau 1 : la distraction est gatée, le tour réussi mène au niveau 2.
    expect(distractionStarted, isFalse);
    expect(find.text('Level 2'), findsOneWidget);

    // Le niveau 2 relance une observation de 4 chiffres ; on la laisse arriver
    // au rappel — état sans minuterie en vol — avant de démonter.
    await watchSequence(tester, MemoryQuestConfig.sequenceLengthForLevel(2));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
