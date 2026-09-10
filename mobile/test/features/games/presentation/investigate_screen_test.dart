import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/domain/config/memory_quest_config.dart';
import 'package:zennyt/features/games/domain/entities/memory_object.dart';
import 'package:zennyt/features/games/presentation/view/investigate_screen.dart';
import 'package:zennyt/features/games/presentation/widgets/game_system_components.dart';

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
    // The game now waits for the backend snapshot before starting its clocks.
    await tester.pump(const Duration(milliseconds: 150));
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

  /// Retour client : « faire clignoter le chiffre lui-même, et non le cadre ».
  ///
  /// Le cadre blanc portait la clé de l'`AnimatedSwitcher` : il était détruit et
  /// rejoué à chaque chiffre, donc il fondait et se remettait à l'échelle en
  /// même temps que le nombre. Or c'est ce cadre qui dit au candidat OÙ
  /// regarder pendant tout l'encodage : il doit rester posé, immobile.
  testWidgets('Digits : le cadre reste fixe, seul le chiffre clignote', (
    tester,
  ) async {
    useLargeSurface(tester);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: InvestigateScreen(seed: seed, mode: InvestigateMode.digits),
        ),
      ),
    );
    await startGame(tester);

    const frame = ValueKey('digit-frame');

    // t = 400 ms : amorce de 350 ms passée, le premier chiffre est à l'écran.
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(frame), findsOneWidget);
    expect(find.text('${level1Seq[0]}'), findsOneWidget);
    final render = tester.renderObject(find.byKey(frame));
    final rect = tester.getRect(find.byKey(frame));

    // t = 1390 ms : le chiffre s'est éteint à 1250 ms, on est à 140 ms d'une
    // transition qui en dure 180. C'est l'instant précis où l'ancienne version
    // empilait DEUX cadres — un qui sortait, un qui entrait.
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 90));
    expect(
      find.byKey(frame),
      findsOneWidget,
      reason: 'un seul cadre, jamais deux en fondu croisé',
    );
    expect(
      tester.renderObject(find.byKey(frame)),
      same(render),
      reason: 'le cadre n\'est pas reconstruit : c\'est le même objet de rendu',
    );
    expect(tester.getRect(find.byKey(frame)), rect, reason: 'ni déplacé');

    // Chiffre suivant : toujours ce cadre-là.
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('${level1Seq[1]}'), findsOneWidget);
    expect(tester.renderObject(find.byKey(frame)), same(render));
    expect(tester.getRect(find.byKey(frame)), rect);

    // On laisse l'observation aller à son terme — état sans minuterie en vol —
    // avant de démonter.
    await tester.pump(const Duration(milliseconds: 4200));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  // ── Restauration : classement au clic (le drag & drop est retiré) ─────────
  //
  // Retour client : « supprimer le drag and drop — le classement se fait au
  // clic, avec un petit numéro (1, 2, 3…) affiché en haut de l'objet ; un
  // deuxième clic sur un objet ayant un rang va annuler son rang ; et un bouton
  // Validate ». Le glisser-déposer imposait deux zones (réserve +
  // emplacements) qui se partageaient l'écran : d'où des cartes de 84 px que le
  // client trouvait trop petites.

  /// Mène une partie d'IMAGES jusqu'à l'écran de restauration du niveau 1.
  Future<List<MemoryObject>> toRestore(WidgetTester tester) async {
    List<MemoryObject> initial = const [];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: InvestigateScreen(
            seed: seed,
            mode: InvestigateMode.images,
            onMissionBReady: (order) => initial = order,
          ),
        ),
      ),
    );
    await startGame(tester);
    // Mémorisation, manipulations, rétention.
    await tester.pump(const Duration(milliseconds: 5200));
    await tester.pump(const Duration(milliseconds: 6200));
    expect(find.text('Restore the STARTING order'), findsOneWidget);
    return initial;
  }

  Future<void> tapObject(WidgetTester tester, MemoryObject obj) async {
    await tester.tap(find.text(obj.labelEn));
    await tester.pump();
  }

  testWidgets('Images : plus aucun glisser-déposer sur l\'écran de restauration',
      (tester) async {
    useLargeSurface(tester);
    await toRestore(tester);

    expect(find.byType(Draggable<MemoryObject>), findsNothing);
    expect(find.byType(DragTarget<MemoryObject>), findsNothing);
    expect(
      find.textContaining('Drag'),
      findsNothing,
      reason: 'la consigne ne doit plus parler d\'un geste qui n\'existe plus',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Images : un clic pose un rang, un second l\'annule et '
      'renumérote la suite', (tester) async {
    useLargeSurface(tester);
    final initial = await toRestore(tester);
    expect(initial, hasLength(3));

    // Aucun rang au départ, et Validate est fermé.
    expect(find.text('1'), findsNothing);
    final validate = find.widgetWithText(GamePrimaryButton, 'Validate');
    expect(tester.widget<GamePrimaryButton>(validate).onPressed, isNull);

    // Trois clics, trois rangs.
    for (final obj in initial) {
      await tapObject(tester, obj);
    }
    for (final rank in ['1', '2', '3']) {
      expect(find.text(rank), findsOneWidget, reason: 'un rang $rank et un seul');
    }
    expect(
      tester.widget<GamePrimaryButton>(validate).onPressed,
      isNotNull,
      reason: 'tous les objets sont classés : on peut valider',
    );

    // Deuxième clic sur le rang 2 : il disparaît, et le 3 devient 2.
    await tapObject(tester, initial[1]);
    expect(find.text('3'), findsNothing, reason: 'un classement sans trou');
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(
      tester.widget<GamePrimaryButton>(validate).onPressed,
      isNull,
      reason: 'le classement est redevenu incomplet',
    );

    // On reclasse l'objet retiré : il repart en dernier.
    await tapObject(tester, initial[1]);
    expect(find.text('3'), findsOneWidget);

    // Le rang lu par le jeu reste bien celui des clics, pas celui de la grille :
    // l'ordre initial a été reconstitué 1, 3, 2 — donc un seul objet en place.
    await tester.tap(validate);
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('Restore the STARTING order'), findsNothing);

    // Le niveau 2 relance une mémorisation d'objets ; on la laisse atteindre la
    // restauration — état sans minuterie en vol — avant de démonter.
    await tester.pump(const Duration(milliseconds: 5200));
    await tester.pump(const Duration(milliseconds: 6200));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  // Retour client : « le vert est le plus adapté ; on peut le faire clignoter
  // une seule fois, c'est-à-dire disparaître et réapparaître, pour attirer
  // l'attention. »
  group('consigne clignotante', () {
    /// Opacité réellement appliquée à la consigne.
    double opacityOf(WidgetTester tester) {
      final fade = tester.widgetList<FadeTransition>(
        find.descendant(
          of: find.byType(MemoryPrompt),
          matching: find.byType(FadeTransition),
        ),
      );
      return fade.isEmpty ? 1.0 : fade.first.opacity.value;
    }

    Future<void> mount(WidgetTester tester, String text) => tester.pumpWidget(
      MaterialApp(home: Scaffold(body: Center(child: MemoryPrompt(text)))),
    );

    testWidgets('elle disparaît puis revient, une fois et une seule', (
      tester,
    ) async {
      await mount(tester, 'Memorize the starting order');

      // Échantillonnage image par image sur toute la durée annoncée, plus une
      // marge : c'est la marge qui prouve le « une seule fois ».
      const frame = Duration(milliseconds: 16);
      final track = <double>[opacityOf(tester)];
      for (
        var t = Duration.zero;
        t < MemoryPrompt.blinkDuration * 3;
        t += frame
      ) {
        await tester.pump(frame);
        track.add(opacityOf(tester));
      }

      expect(track.first, closeTo(1, 0.001), reason: 'elle part pleine');
      expect(
        track.reduce(math.min),
        lessThan(0.02),
        reason: 'elle disparaît vraiment — un simple estompage ne suffit pas',
      );
      expect(track.last, closeTo(1, 0.001), reason: 'et elle revient pleine');

      // Un seul aller-retour : l'opacité ne redescend plus après être remontée.
      final bottom = track.indexOf(track.reduce(math.min));
      final after = track.sublist(bottom);
      for (var i = 1; i < after.length; i++) {
        expect(
          after[i],
          greaterThanOrEqualTo(after[i - 1] - 0.001),
          reason:
              'la consigne re-clignote : un clignotement qui se répète devient '
              'un décor qu\'on cesse de voir',
        );
      }
    });

    testWidgets('chaque nouvelle consigne rejoue le clignotement', (
      tester,
    ) async {
      // Les phases d'observation et de manipulation partagent la même vue :
      // sans cela, la seconde consigne arriverait sans se signaler.
      await mount(tester, 'Memorize the starting order');
      await tester.pump(MemoryPrompt.blinkDuration * 2);
      expect(opacityOf(tester), closeTo(1, 0.001));

      await mount(tester, 'Watch the manipulations');
      await tester.pump(MemoryPrompt.blinkDuration ~/ 4);
      expect(
        opacityOf(tester),
        lessThan(0.9),
        reason: 'la consigne a changé sans que rien ne l\'annonce',
      );

      await tester.pump(MemoryPrompt.blinkDuration);
      expect(opacityOf(tester), closeTo(1, 0.001));
    });

    testWidgets('animations coupées : elle se pose, pleine', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: Center(child: MemoryPrompt('Restore the STARTING order')),
            ),
          ),
        ),
      );

      // Aucun `FadeTransition` du tout : le texte n'a jamais à s'effacer pour
      // un joueur qui a demandé moins de mouvement.
      expect(
        find.descendant(
          of: find.byType(MemoryPrompt),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
      );
      await tester.pump(MemoryPrompt.blinkDuration);
      expect(find.text('Restore the STARTING order'), findsOneWidget);
    });

    testWidgets('elle porte bien la couleur retenue', (tester) async {
      await mount(tester, 'Memorize the starting order');
      final label = tester.widget<Text>(
        find.descendant(
          of: find.byType(MemoryPrompt),
          matching: find.byType(Text),
        ),
      );
      expect(label.style?.color, kMemoryPromptColor);
      await tester.pump(MemoryPrompt.blinkDuration);
    });
  });

  group('taille des cartes', () {
    /// L'échelle était une constante par palier (1,0 jusqu'à 6 objets, puis
    /// 0,82, puis 0,68) : elle ignorait la place disponible et rapetissait les
    /// cartes même là où il y avait de quoi les agrandir.
    test('les cartes remplissent la place disponible sans la déborder', () {
      const viewports = <String, Size>{
        '320 × 568 (petit)': Size(272, 300),
        '360 × 800 (courant)': Size(312, 430),
        '390 × 844 (grand)': Size(342, 470),
      };

      for (final entry in viewports.entries) {
        for (var count = 3; count <= 12; count++) {
          final scale = memoryObjectTileScaleFor(
            count: count,
            available: entry.value,
          );
          expect(
            scale,
            greaterThan(0),
            reason: '${entry.key}, $count objets',
          );

          // Le meilleur découpage à cette échelle doit tenir en largeur ; en
          // hauteur, le plancher de lisibilité peut imposer un défilement, on
          // ne l'exige donc que tant que l'échelle n'est pas au plancher.
          final tileW = kMemoryObjectTileWidth * scale;
          final columns = ((entry.value.width + 12) / (tileW + 12)).floor();
          expect(
            columns,
            greaterThanOrEqualTo(1),
            reason:
                '${entry.key}, $count objets : une carte de $tileW px ne tient '
                'même pas seule sur une ligne',
          );
        }
      }
    });

    test('trois objets sur un écran courant donnent des cartes PLUS GRANDES '
        'qu\'avant', () {
      // Avant : échelle 1,0 figée, soit une carte de 84 × 120 — et 0,82 dès que
      // les deux zones du glisser-déposer se partageaient la largeur.
      final scale = memoryObjectTileScaleFor(
        count: 3,
        available: const Size(312, 430),
      );
      expect(
        scale,
        greaterThan(1.2),
        reason: 'c\'est la demande : « agrandir la taille des cartes »',
      );
    });

    test('douze objets restent lisibles au lieu de disparaître', () {
      final scale = memoryObjectTileScaleFor(
        count: 12,
        available: const Size(272, 300),
      );
      expect(
        kMemoryObjectTileWidth * scale,
        greaterThan(50),
        reason: 'plancher de lisibilité : en dessous, l\'objet n\'est plus '
            'identifiable et il vaut mieux faire défiler',
      );
    });
  });

  /// La restitution avait un temps ILLIMITÉ : le joueur pouvait rester sur le
  /// plateau indéfiniment, ce qui vidait de son sens la mesure de mémoire.
  testWidgets(
      'Images : la restitution est chronométrée et se valide d\'office',
      (tester) async {
    useLargeSurface(tester);

    List<MemoryObject> objects = const [];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: InvestigateScreen(
            seed: seed,
            mode: InvestigateMode.images,
            onMissionBReady: (order) => objects = order,
          ),
        ),
      ),
    );
    await startGame(tester);
    await watchObjects(tester, MemoryQuestConfig.objectCountForLevel(1));

    expect(find.text('Restore the STARTING order'), findsOneWidget);

    final limitMs = MemoryQuestConfig.restoreTimeLimitMs(objects.length);
    final startSeconds = (limitMs / 1000).ceil();
    expect(find.text('${startSeconds}s left'), findsOneWidget);

    // Le rebours descend réellement.
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('${startSeconds - 1}s left'), findsOneWidget);

    // Un seul rang posé, puis on laisse le temps filer : le tour se clôt sans
    // que le joueur touche « Validate ».
    await tester.tap(find.text(objects.first.labelEn).first);
    await tester.pump();
    await tester.pump(Duration(milliseconds: limitMs + 300));
    await tester.pump(const Duration(milliseconds: 1200)); // feedback

    expect(find.text('Restore the STARTING order'), findsNothing,
        reason: 'le temps écoulé clôt la restitution');

    // Un tour expiré compte comme raté : le MÊME niveau est rejoué. On laisse
    // filer la seconde tentative aussi, ce qui doit terminer la partie
    // (maxFailuresPerLevel = 2).
    await watchObjects(tester, MemoryQuestConfig.objectCountForLevel(1));
    expect(find.text('Restore the STARTING order'), findsOneWidget);
    await tester.pump(
      Duration(
        milliseconds:
            MemoryQuestConfig.restoreTimeLimitMs(objects.length) + 300,
      ),
    );
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('Results'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  /// Le temps restant se lisait en texte seul. Les autres mini-jeux (« Je
  /// bouge ») le montrent par une barre qui se vide : c'est la même information,
  /// elle doit se lire de la même façon d'un jeu à l'autre.
  testWidgets('Images : chaque phase chronométrée montre une barre de temps',
      (tester) async {
    useLargeSurface(tester);

    List<MemoryObject> objects = const [];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: InvestigateScreen(
            seed: seed,
            mode: InvestigateMode.images,
            onMissionBReady: (order) => objects = order,
          ),
        ),
      ),
    );
    await startGame(tester);

    double barValue() => tester
        .widget<LinearProgressIndicator>(
          find.descendant(
            of: find.byType(GameTimerBar),
            matching: find.byType(LinearProgressIndicator),
          ),
        )
        .value!;

    // 1. Mémorisation — la barre part pleine et se vide.
    expect(find.byType(GameTimerBar), findsOneWidget);
    final memoStart = barValue();
    expect(memoStart, closeTo(1, 0.05));
    await tester.pump(
      Duration(
        milliseconds:
            MemoryQuestConfig.objectObservationMs(objects.length) ~/ 2,
      ),
    );
    expect(barValue(), lessThan(memoStart));

    // 2. Restitution — même barre, et elle se vide aussi.
    await watchObjects(tester, MemoryQuestConfig.objectCountForLevel(1));
    expect(find.text('Restore the STARTING order'), findsOneWidget);
    expect(find.byType(GameTimerBar), findsOneWidget);

    // `watchObjects` avance en gros blocs, le rebours a donc déjà tourné : on
    // vérifie qu'il DESCEND, pas qu'il parte de 1.
    final restoreStart = barValue();
    expect(restoreStart, inExclusiveRange(0, 1));
    await tester.pump(const Duration(seconds: 1));
    final drained = barValue();
    expect(drained, lessThan(restoreStart));
    expect(drained, greaterThan(0));

    await tester.pump(
      Duration(
        milliseconds:
            MemoryQuestConfig.restoreTimeLimitMs(objects.length) + 300,
      ),
    );
    await tester.pump(const Duration(milliseconds: 1200));
    await watchObjects(tester, MemoryQuestConfig.objectCountForLevel(1));
    await tester.pump(
      Duration(
        milliseconds:
            MemoryQuestConfig.restoreTimeLimitMs(objects.length) + 300,
      ),
    );
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
  });
}
