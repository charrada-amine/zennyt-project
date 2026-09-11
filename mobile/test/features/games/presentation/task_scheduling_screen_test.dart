import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/games_mock_repository.dart';
import 'package:zennyt/features/games/domain/entities/device_calibration.dart';
import 'package:zennyt/features/games/domain/entities/game_metrics.dart';
import 'package:zennyt/features/games/domain/entities/game_session.dart';
import 'package:zennyt/features/games/domain/entities/game_type.dart';
import 'package:zennyt/features/games/domain/entities/mini_game.dart';
import 'package:zennyt/features/games/domain/entities/task_scheduling_metrics.dart';
import 'package:zennyt/features/games/presentation/games_providers.dart';
import 'package:zennyt/features/games/data/day_stack_bank_loader.dart';
import 'package:zennyt/features/games/presentation/view/task_scheduling_screen.dart';

class _RecordingRepository extends GamesMockRepository {
  int starts = 0;
  TaskSchedulingMetrics? submitted;

  /// Fait échouer la remontée, pour éprouver le chemin d'erreur.
  bool failSubmit = false;

  @override
  Future<GameSession> startSession(GameType gameType) {
    starts++;
    return super.startSession(gameType);
  }

  @override
  Future<GameSession> submitResult({
    required String sessionId,
    required MiniGame miniGame,
    required GameMetrics metrics,
    DeviceCalibration? deviceCalibration,
  }) {
    submitted = metrics as TaskSchedulingMetrics;
    if (failSubmit) {
      return Future<GameSession>.error(StateError('réseau indisponible'));
    }
    return super.submitResult(
      sessionId: sessionId,
      miniGame: miniGame,
      metrics: metrics,
      deviceCalibration: deviceCalibration,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // La banque vient d'un asset. Un `pump()` ne fait pas tourner cette lecture :
  // on la déclenche ici, une fois, pour que l'écran la retrouve en cache et
  // ouvre son intro dès la première image.
  setUpAll(() async {
    DayStackBankLoader.resetForTest();
    await DayStackBankLoader.load();
  });

  Future<_RecordingRepository> start(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double scale = 1,
    bool failSubmit = false,
    // `null` = on laisse l'écran décider, c'est-à-dire la vraie valeur de
    // production. Les tests qui pinnent ces réglages ne mesurent que la
    // mécanique ; ceux qui les laissent nuls mesurent le défaut par défaut.
    int? levelCount = 1,
    int? universeIndex = 0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _RecordingRepository()..failSubmit = failSubmit;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [gamesRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          // Univers et variante fixés : les sept univers comptent 11 ou 12
          // tâches, avec des horaires et des dépendances différents. Un tirage
          // aléatoire rendrait non déterministe tout ce qui suit.
          // Une seule manche : jouer les trois plannings de douze tâches à
          // chaque test les rendrait interminables. La progression a ses
          // propres tests, plus bas.
          home: TaskSchedulingScreen(
            universeIndex: universeIndex,
            variantSeed: 0,
            levelCount: levelCount,
          ),
        ),
      ),
    );
    // L'écran lit sa banque dans un asset avant d'ouvrir l'intro. Pendant ce
    // temps il affiche un indicateur qui tourne en boucle : `pumpAndSettle`
    // n'y rendrait jamais la main. On pompe donc jusqu'à voir l'intro.
    for (
      var frame = 0;
      frame < 20 && find.text('Start').evaluate().isEmpty;
      frame++
    ) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text('Start'), findsOneWidget, reason: 'banque chargée');

    for (final label in ['Start', 'I am ready']) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    return repo;
  }

  List<int> order(WidgetTester tester) {
    final dynamic state = tester.state(find.byType(TaskSchedulingScreen));
    return List<int>.from(state.slotsForTest as List<int>);
  }

  Future<void> place(WidgetTester tester, int task) async {
    final dynamic state = tester.state(find.byType(TaskSchedulingScreen));
    state.moveSlotForTest(order(tester).indexOf(task), task);
    await tester.pumpAndSettle();
  }

  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(390, 844), 2.0),
    (const Size(1024, 768), 1.0),
  ]) {
    testWidgets('full task list fits $size at text scale $scale', (
      tester,
    ) async {
      await start(tester, size: size, scale: scale);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('12 tâches'), findsOneWidget);
      expect(find.text('Valider').hitTestable(), findsOneWidget);
      await place(tester, 0);
      expect(find.byKey(const ValueKey('day-stack-progress')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  /// Remplit le planning, valide, et traverse le débrief jusqu'au score.
  ///
  /// Chaque manche passe par son débrief depuis qu'il existe : un test qui
  /// attend le score juste après « Validate » s'arrêterait sur cet écran.
  Future<void> finishGame(WidgetTester tester, {int tasks = 12}) async {
    for (var task = 0; task < tasks; task++) {
      await place(tester, task);
    }
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voir mon score'));
    await tester.pumpAndSettle();
  }

  testWidgets('toutes les tâches sont présentes et neutres avant validation', (
    tester,
  ) async {
    final repo = await start(tester);
    expect(order(tester).toSet(), Set<int>.from(List.generate(12, (i) => i)));
    expect(find.byKey(const ValueKey('day-stack-tray')), findsNothing);
    await place(tester, 0);
    expect(find.textContaining('07h00–08h00'), findsWidgets);
    expect(find.textContaining('15 min'), findsWidgets);
    final dynamic state = tester.state(find.byType(TaskSchedulingScreen));
    state.moveSlotForTest(order(tester).indexOf(1), 0);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    expect(repo.submitted, isNull);
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(
      repo.submitted,
      isNotNull,
      reason: 'le bouton Valider déclenche la soumission finale',
    );
    expect(repo.submitted!.directDependencyViolations, greaterThan(0));
  });

  testWidgets('glisser sur le corps fait défiler sans changer l’ordre', (
    tester,
  ) async {
    await start(tester);
    final before = order(tester);
    final list = find.byKey(const ValueKey('day-stack-schedule'));
    final scrollable = find.descendant(
      of: list,
      matching: find.byType(Scrollable),
    );
    final scrollState = tester.state<ScrollableState>(scrollable);
    await tester.dragFrom(tester.getCenter(list), const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(scrollState.position.pixels, greaterThan(0));
    expect(order(tester), before);
    expect(find.text('Valider').hitTestable(), findsOneWidget);
  });

  testWidgets('un appui maintenu sur la carte permet de la déplacer', (
    tester,
  ) async {
    await start(tester);
    final before = order(tester);
    final movedTask = before.first;
    final card = find.byKey(ValueKey('day-stack-task-$movedTask'));
    final destination = find.byKey(ValueKey('day-stack-task-${before[2]}'));

    // Toute la carte est la zone de prise ; aucune poignée séparée n'est
    // nécessaire.
    final gesture = await tester.startGesture(
      tester.getCenter(card) - const Offset(90, 0),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();

    // Le proxy de déplacement ne doit pas ajouter le fond rectangulaire du
    // décorateur Flutter par défaut autour de la carte arrondie.
    final proxy = tester.widget<Material>(
      find.byKey(const ValueKey('day-stack-drag-proxy')),
    );
    expect(proxy.type, MaterialType.transparency);
    expect(proxy.clipBehavior, Clip.antiAlias);

    await gesture.moveTo(
      tester.getRect(destination).bottomCenter - const Offset(0, 5),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(order(tester).indexOf(movedTask), greaterThan(0));
    expect(find.text('1 déplacement(s) · sans pénalité'), findsOneWidget);
    expect(find.byIcon(Icons.drag_indicator_rounded), findsNothing);
  });

  testWidgets('le glissement près du bord fait défiler automatiquement', (
    tester,
  ) async {
    await start(tester);
    final before = order(tester);
    final list = find.byKey(const ValueKey('day-stack-schedule'));
    final scrollable = find.descendant(
      of: list,
      matching: find.byType(Scrollable),
    );
    final scrollState = tester.state<ScrollableState>(scrollable);
    final card = find.byKey(ValueKey('day-stack-task-${before.first}'));
    final gesture = await tester.startGesture(tester.getCenter(card));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(tester.getBottomRight(list) - const Offset(25, 5));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(scrollState.position.pixels, greaterThan(100));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(order(tester).indexOf(before.first), greaterThan(1));
    expect(order(tester).toSet(), before.toSet());
    expect(find.text('Valider').hitTestable(), findsOneWidget);
  });

  testWidgets('annuler un drag réactive la validation sans déplacer', (
    tester,
  ) async {
    await start(tester);
    final before = order(tester);
    final card = find.byKey(ValueKey('day-stack-task-${before.first}'));
    final gesture = await tester.startGesture(tester.getCenter(card));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(0, 30));
    await tester.pump();
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(order(tester), before);
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(find.text('Dernière manche terminée'), findsOneWidget);
  });

  testWidgets('une remontée échouée le dit, et propose de renvoyer', (
    tester,
  ) async {
    final repo = await start(tester, failSubmit: true);
    await finishGame(tester);

    // Le score vient du serveur. Sans lui, l'écran affichait « — » : un
    // résultat vide, impossible à distinguer d'une partie sans points.
    expect(find.text('Score non calculé'), findsOneWidget);
    expect(find.text('Renvoyer le résultat'), findsOneWidget);

    // Renvoyer remonte le MÊME planning : le joueur ne rejoue pas parce que le
    // réseau a flanché.
    repo.failSubmit = false;
    await tester.tap(find.text('Renvoyer le résultat'));
    await tester.pumpAndSettle();
    expect(find.text('Score non calculé'), findsNothing);
    expect(find.textContaining('/10'), findsOneWidget);
  });

  testWidgets('la fin de partie explique le score au lieu d\'un nombre nu', (
    tester,
  ) async {
    await start(tester);
    for (var task = 0; task < 12; task++) {
      await place(tester, task);
    }
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    // Chaque manche passe par son débrief, la dernière comprise : c'est là que
    // le joueur voit ce qui n'a pas tenu — la seule chose sur laquelle il peut
    // progresser. L'ordre de la banque laisse des contraintes non tenues.
    expect(find.textContaining('Dépendances respectées'), findsOneWidget);
    expect(find.textContaining('Contraintes horaires tenues'), findsOneWidget);
    expect(find.textContaining('Temps mort'), findsOneWidget);
    expect(find.text('Ce qui n\'a pas tenu'), findsOneWidget);

    // Puis seulement le score, sur les mesures CUMULÉES.
    await tester.tap(find.text('Voir mon score'));
    await tester.pumpAndSettle();
    expect(find.textContaining('/10'), findsOneWidget);
    expect(find.textContaining('manche(s)'), findsOneWidget);
  });

  testWidgets('les règles parlent d\'heures, plus de numéros de créneau', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View rules'));
    await tester.pumpAndSettle();

    // Le jeu a une horloge depuis le lot B : « by slot n » décrivait un
    // mécanisme qui n'existe plus.
    expect(find.textContaining('by slot'), findsNothing);
    expect(find.textContaining('HEURES'), findsOneWidget);
  });

  testWidgets('une partie enchaîne plusieurs manches', (tester) async {
    // Le défaut signalé : une seule manche et la partie était finie. Un seul
    // planning ne mesurait qu'un univers — le joueur pouvait tomber sur celui
    // qui lui parle et n'être jamais confronté aux autres.
    final repo = await start(tester, levelCount: 2);
    expect(find.text('Manche 1 / 2'), findsOneWidget);

    for (var task = 0; task < 12; task++) {
      await place(tester, task);
    }
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    // Fin de MANCHE, pas fin de partie : rien n'est encore remonté.
    expect(find.text('Manche 1 terminée'), findsOneWidget);
    expect(repo.submitted, isNull);

    await tester.tap(find.text('Manche 2 / 2'));
    await tester.pumpAndSettle();
    expect(find.text('Manche 2 / 2'), findsOneWidget);
    expect(
      find.text('0 déplacement(s) · sans pénalité'),
      findsOneWidget,
      reason: 'plateau neuf',
    );
  });

  testWidgets('une partie non truquée compte bien trois manches', (
    tester,
  ) async {
    // Tous les autres tests de progression INJECTENT `levelCount`. Ils
    // prouvent donc que l'enchaînement fonctionne, jamais qu'il a lieu : un
    // retour de `kDayStackLevels` à 1 — le défaut exact qui avait été
    // signalé — les laisserait tous au vert. Ce test est le seul à regarder
    // la valeur de production.
    await start(tester, levelCount: null);
    expect(find.text('Manche 1 / 3'), findsOneWidget);
  });

  testWidgets('deux manches ne rejouent pas le même univers', (tester) async {
    // L'écran exclut les univers déjà joués. Aucun test ne l'exerçait : ils
    // pinnent tous `universeIndex`, ce qui force justement la répétition que
    // la règle doit empêcher. On laisse donc le tirage libre ici.
    final bank = await DayStackBankLoader.load();
    final noms = bank.universes.map((u) => u.name).toList();
    String universeAffiche() => noms.firstWhere(
      (nom) => find.textContaining(nom).evaluate().isNotEmpty,
      orElse: () => '(aucun)',
    );

    await start(tester, levelCount: 2, universeIndex: null);
    final premier = universeAffiche();
    expect(premier, isNot('(aucun)'), reason: 'un univers est bien affiché');

    // Le plateau fait 11 ou 12 tâches selon l'univers tiré. On lit le nombre
    // dans la banque : tester la présence de la clé ne dirait rien, une carte
    // simplement hors écran n'étant pas une carte absente.
    final combien = bank.universes
        .firstWhere((u) => u.name == premier)
        .tasks
        .length;
    for (var task = 0; task < combien; task++) {
      await place(tester, task);
    }
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manche 2 / 2'));
    await tester.pumpAndSettle();

    expect(
      universeAffiche(),
      isNot(premier),
      reason: 'rejouer le même planning ne mesurerait plus rien',
    );
  });

  testWidgets('le score porte sur les mesures CUMULÉES des manches', (
    tester,
  ) async {
    final repo = await start(tester, levelCount: 2, universeIndex: 0);

    // Manche 1
    for (var task = 0; task < 12; task++) {
      await place(tester, task);
    }
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manche 2 / 2'));
    await tester.pumpAndSettle();

    // Manche 2 — même univers forcé, donc mêmes effectifs.
    await finishGame(tester);

    final envoye = repo.submitted!.toJson();
    // Deux manches de 6 contraintes horaires : le serveur doit noter 12, pas 6.
    // Ne remonter que la dernière manche diviserait le dénominateur par deux.
    expect(envoye['timingConstraintCount'], 12);
    expect(envoye['universeId'], 'restaurant,restaurant');
  });

  testWidgets('réordonner une tâche ne compte pas comme une correction', (
    tester,
  ) async {
    // Le défaut : le placement ne remplissait que le premier créneau libre.
    // Insérer une tâche au rang 3 quand six étaient posées imposait d'en
    // retirer quatre — et le barème d'autorégulation tombe à zéro au-delà de
    // trois corrections. La rigidité de l'écran coûtait donc la composante à
    // qui réorganisait une seule fois.
    final repo = await start(tester, levelCount: 1, universeIndex: 0);

    for (var task = 0; task < 12; task++) {
      await place(tester, task);
    }

    // L'état est privé : on y accède par son type public de base, puis en
    // dynamique pour atteindre les accesseurs marqués @visibleForTesting.
    final dynamic etat = tester.state<State<TaskSchedulingScreen>>(
      find.byType(TaskSchedulingScreen),
    );
    final avant = List<int?>.from(etat.slotsForTest as List<int?>);
    // La dernière tâche remonte au rang 3 : exactement le geste qui, avant,
    // exigeait neuf retraits.
    etat.moveSlotForTest(11, 2);
    await tester.pumpAndSettle();

    final apres = etat.slotsForTest as List<int?>;
    expect(apres[2], avant[11], reason: 'la tâche a bien changé de rang');
    expect(apres.whereType<int>().length, 12, reason: 'aucune tâche perdue');
    expect(
      apres.toSet(),
      avant.toSet(),
      reason: 'un déplacement ne retire ni n\'ajoute rien',
    );

    // Et dans l'autre sens : `onReorder` livrait un index comptant encore
    // l'élément à sa place d'origine, donc toute descente atterrissait un rang
    // trop haut. Le cas montant ci-dessus ne l'aurait pas vu.
    final avantDescente = List<int?>.from(etat.slotsForTest as List<int?>);
    etat.moveSlotForTest(1, 7);
    await tester.pumpAndSettle();
    final apresDescente = etat.slotsForTest as List<int?>;
    expect(apresDescente[7], avantDescente[1]);
    expect(apresDescente.whereType<int>().length, 12);

    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voir mon score'));
    await tester.pumpAndSettle();

    final envoye = repo.submitted!.toJson();
    expect(envoye['proactiveAdjustments'], 0);
    expect(envoye['reactiveAdjustments'], 0);
  });

  testWidgets('le nombre de manches jouées part avec les mesures', (
    tester,
  ) async {
    // Les seuils d'autorégulation du référentiel valent PAR planning. Sans ce
    // nombre, le serveur appliquerait un barème de manche à un total de partie.
    final repo = await start(tester, levelCount: 2, universeIndex: 0);
    for (var task = 0; task < 12; task++) {
      await place(tester, task);
    }
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manche 2 / 2'));
    await tester.pumpAndSettle();
    await finishGame(tester);

    expect(repo.submitted!.toJson()['levelsPlayed'], 2);
  });

  testWidgets('la fin de partie ne saute pas vers un autre jeu', (
    tester,
  ) async {
    await start(tester);
    await finishGame(tester);

    // « Continue to Hanoï » était le bouton PRINCIPAL de cet écran : après un
    // seul essai, le geste le plus naturel éjectait le joueur vers Tower of
    // Hanoi, un autre jeu, sans qu'il l'ait demandé.
    expect(find.textContaining('Hano'), findsNothing);
    expect(find.text('Replay'), findsOneWidget);
    expect(find.text('Back to games'), findsOneWidget);
  });

  testWidgets('rules preserve placements and the original session', (
    tester,
  ) async {
    final repo = await start(tester);
    await place(tester, 0);
    final before = order(tester);
    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View rules'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Resume schedule'));
    await tester.tap(find.text('Resume schedule'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('day-stack-progress')), findsOneWidget);
    expect(order(tester), before);
    expect(repo.starts, 1);
  });

  testWidgets(
    'douze placements envoient les mesures brutes et affichent le score',
    (tester) async {
      final repo = await start(tester);
      await finishGame(tester);

      final envoye = repo.submitted!.toJson();

      // L'univers tiré voyage avec les mesures : sans lui, deux passations ne
      // seraient pas comparables, les univers n'ayant ni le même nombre de
      // contraintes ni les mêmes dépendances.
      expect(envoye['universeId'], 'restaurant');

      // Placer les tâches dans l'ordre de la banque satisfait toutes les
      // DÉPENDANCES — elles y précèdent toujours leurs dépendants.
      expect(envoye['dependencyEdgesRespected'], envoye['dependencyEdgeCount']);
      expect(envoye['directDependencyViolations'], 0);

      // Mais pas les HORAIRES : cet ordre laisse la marinade reposer sans rien
      // faire en parallèle, et le service ancré à 12h00 se retrouve décalé.
      // C'est voulu — un jeu dont l'ordre le plus naïf donnerait 10/10 ne
      // mesurerait rien. La recherche exhaustive de
      // `day_stack_schedule_test.dart` prouve par ailleurs qu'un plan parfait
      // existe pour cet univers.
      expect(
        envoye['timingConstraintsRespected'],
        lessThan(envoye['timingConstraintCount'] as int),
      );
      // n RÉEL de l'univers Restaurant, pas une constante.
      expect(envoye['timingConstraintCount'], 6);

      // Aucun retrait : les deux compteurs d'autorégulation restent à zéro.
      expect(envoye['proactiveAdjustments'], 0);
      expect(envoye['reactiveAdjustments'], 0);

      // La latence est mesurée dès le premier placement, et remonte hors score.
      expect(envoye['planningLatencyMs'], isA<int>());

      expect(envoye['deadTimeRatio'], inInclusiveRange(0.0, 1.0));

      // Le score vient du serveur, jamais de l'écran.
      expect(find.textContaining('/10'), findsOneWidget);
    },
  );
}
