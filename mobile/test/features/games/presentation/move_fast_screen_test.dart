import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/games_mock_repository.dart';
import 'package:zennyt/features/games/domain/config/move_fast_config.dart';
import 'package:zennyt/features/games/presentation/games_providers.dart';
import 'package:zennyt/features/games/presentation/view/move_fast_screen.dart';
import 'package:zennyt/features/games/presentation/widgets/game_system_components.dart';

/// « Je bouge » — trois retours client tenus par ces tests :
///
/// 1. plusieurs avions à la fois (4, 5 ou 6, tirés au sort) et plus petits ;
/// 2. échéance de 2 000 ms : sans réponse, l'avion change et l'essai est perdu ;
/// 3. un déplacement d'entrée accompagne chaque changement, et l'avion PIVOTE
///    lui-même vers sa nouvelle direction.
void main() {
  /// Grand écran : le plateau doit être assez haut pour que les avions ne se
  /// marchent pas dessus, sinon on mesure des chevauchements et non la règle.
  void useLargeSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// Monte l'écran avec une graine fixe et le mène jusqu'au jeu : intro, puis
  /// les deux écrans de règles, qui attendent tous deux la flèche « droite ».
  ///
  /// Le mock de repository simule le réseau (`Future.delayed` de 150 ms) et
  /// l'écran n'ouvre le jeu qu'une fois la session confirmée : les minuteries —
  /// attente d'acrobatie, échéance de 2 000 ms — ne démarrent qu'après cette
  /// attente. On la consomme ICI, une fois pour toutes, pour que les échéanciers
  /// des tests restent relatifs au début réel du jeu.
  Future<void> startGameplay(WidgetTester tester, {int seed = 4242}) async {
    useLargeSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gamesRepositoryProvider.overrideWithValue(GamesMockRepository()),
        ],
        child: MaterialApp(home: MoveFastScreen(seed: seed)),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Commencer'));
    await tester.pump();
    await tester.tap(find.text('Droite'));
    await tester.pump();
    await tester.tap(find.text('Droite'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
  }

  /// Démonte l'arbre. Toutes les minuteries de l'écran — session, échéance
  /// d'essai, passage à l'avion suivant — sont annulées par son `dispose`.
  Future<void> tearDownScreen(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  List<MoveFastPlane> planes(WidgetTester tester) =>
      tester.widgetList<MoveFastPlane>(find.byType(MoveFastPlane)).toList();

  /// La formation ne « respire » plus d'un essai à l'autre.
  ///
  /// Chaque avion recevait un facteur de taille aléatoire de ±14 %, retiré à
  /// chaque essai : même les avions qui ne quittaient pas leur voie changeaient
  /// de taille en permanence, sans que rien ne le justifie. La taille ne dépend
  /// plus que du NOMBRE d'avions — la seule variation qui ait un sens, le
  /// plateau ne grandissant pas quand la formation s'étoffe.
  testWidgets('à nombre égal, tous les avions ont la MÊME taille', (
    tester,
  ) async {
    await startGameplay(tester);

    // La taille suit désormais la figure ENTIÈRE, décalage de vague compris —
    // 900 ms + 5 × 55 ms pour la dernière voie. On échantillonne après, sinon
    // on relève des tailles en cours d'interpolation.
    const settled = Duration(milliseconds: 1300);
    Future<void> settle() => tester.pump(settled);

    // Taille relevée pour chaque effectif rencontré.
    final byCount = <int, Set<double>>{};
    await settle();
    for (var trial = 0; trial < 10; trial++) {
      final formation = planes(tester);
      byCount
          .putIfAbsent(formation.length, () => <double>{})
          .addAll(formation.map((p) => p.size));
      await tester.pump(const Duration(milliseconds: 2650) - settled);
      await settle();
    }

    byCount.forEach((count, sizes) {
      expect(
        sizes.length,
        1,
        reason:
            'une formation de $count avions doit leur donner UNE taille, pas '
            '${sizes.length} — relevé : $sizes',
      );
    });

    // Et plus il y en a, plus ils sont petits : le plateau ne grandit pas.
    final ordered = byCount.keys.toList()..sort();
    for (var i = 1; i < ordered.length; i++) {
      expect(
        byCount[ordered[i]]!.single,
        lessThan(byCount[ordered[i - 1]]!.single),
        reason:
            '${ordered[i]} avions doivent être plus petits que '
            '${ordered[i - 1]}',
      );
    }

    await tearDownScreen(tester);
  });

  testWidgets('la formation compte 4 à 6 avions, et elle change d\'un essai à '
      'l\'autre', (tester) async {
    await startGameplay(tester);

    // La figure de transition dure `turnDuration` : pendant ce temps, les voies
    // qui s'allument et celles qui s'éteignent sont toutes deux partiellement
    // visibles. On échantillonne une fois la figure posée, sinon on compte les
    // avions des DEUX essais.
    const settled = Duration(milliseconds: 800); // > turnDuration (700 ms)
    Future<void> settle() => tester.pump(settled);

    final counts = <int>[];
    final sizes = <double>[];
    await settle();
    for (var trial = 0; trial < 8; trial++) {
      final formation = planes(tester);
      counts.add(formation.length);
      sizes.addAll(formation.map((p) => p.size));

      // Essai suivant : on laisse l'échéance de 2 000 ms tomber, puis les
      // 650 ms de retour visuel. Le total doit valoir EXACTEMENT un cycle
      // (2 650 ms) : sinon le point d'échantillonnage dérive d'essai en essai
      // et finit par tomber au milieu d'une figure, où les voies qui changent
      // sont à demi visibles — on compterait alors toutes les voies.
      await tester.pump(const Duration(milliseconds: 2650) - settled);
      await settle();
    }

    expect(
      counts.every((c) => c >= 4 && c <= 6),
      isTrue,
      reason: 'entre 4 et 6 avions à chaque essai — relevé : $counts',
    );
    expect(
      counts.toSet().length,
      greaterThan(1),
      reason:
          'le nombre varie d\'un essai à l\'autre : c\'est la demande — « pas '
          'un même scénario qui se répète ». Relevé : $counts',
    );
    expect(
      sizes.reduce(math.max),
      lessThan(105),
      reason:
          'avions réduits. L\'ancienne formation en tenait trois, de 110 à '
          '122 px : aucun n\'aurait passé ce seuil',
    );
    expect(sizes.reduce(math.min), greaterThan(55), reason: 'mais lisibles');

    await tearDownScreen(tester);
  });

  testWidgets('sans réponse, l\'avion change au bout de 2 000 ms et l\'essai '
      'est compté faux', (tester) async {
    await startGameplay(tester);
    await tester.pump(const Duration(milliseconds: 400));

    // Le bandeau de série annonce ce que la prochaine bonne réponse déclenche.
    expect(find.text('upgrade'), findsOneWidget);
    expect(find.text('reset'), findsNothing);

    // L'échéance ne court qu'à partir du moment où la formation est posée : le
    // joueur a TOUJOURS ses 2 000 ms pleines, l'acrobatie ne les entame pas.
    // Premier avion de la partie : il ne manœuvre pas, son attente est celle
    // du seul élan d'entrée.
    final settle = MoveFastPlane.formationSettle(6, manoeuvring: false);
    await tester.pump(settle - const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 1900));
    expect(
      find.text('reset'),
      findsNothing,
      reason:
          'l\'échéance est de ${MoveFastConfig.trialTimeoutMs} ms, pas moins',
    );

    // …et elle tombe.
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      find.text('reset'),
      findsOneWidget,
      reason:
          'même sanction qu\'une mauvaise flèche : la série est brisée. Sans '
          'cela, rester immobile serait gratuit',
    );

    await tearDownScreen(tester);
  });

  // Retour client : « ajuste pour avoir toujours 2 000 ms pour répondre ; si
  // l'animation prend de ce temps, ajuste ça. »
  testWidgets('l\'acrobatie n\'entame pas les 2 000 ms de réponse', (
    tester,
  ) async {
    await startGameplay(tester);

    // On laisse tomber le premier essai — celui-là ne manœuvre pas — pour
    // mesurer sur le second, qui joue une vraie acrobatie. On se cale à l'image
    // près sur son démarrage : le retour visuel s'efface pile à cet instant,
    // et le bandeau repasse de « reset » à « upgrade ».
    const frame = Duration(milliseconds: 16);
    await tester.pump(
      MoveFastPlane.formationSettle(6, manoeuvring: false) +
          const Duration(milliseconds: 2100),
    );
    expect(find.text('reset'), findsOneWidget, reason: 'premier essai perdu');
    var elapsed = Duration.zero;
    while (find.text('reset').evaluate().isNotEmpty &&
        elapsed < const Duration(seconds: 2)) {
      await tester.pump(frame);
      elapsed += frame;
    }
    // Le second essai vient de commencer, à moins d'une image près.
    final settle = MoveFastPlane.formationSettle(6);

    // Pendant la manœuvre, l'écran n'accepte rien : la direction n'est pas
    // encore lisible et le chronomètre ne tourne pas. Une réponse donnée là
    // serait une anticipation, pas une réaction — et elle ne doit surtout pas
    // être comptée contre le joueur.
    await tester.pump(settle ~/ 2);
    await tester.tap(find.text('Gauche')); // volontairement la mauvaise flèche
    await tester.pump();
    expect(
      find.text('reset'),
      findsNothing,
      reason:
          'une réponse donnée pendant l\'acrobatie a été enregistrée : le '
          'joueur est pénalisé pour un stimulus qu\'il ne pouvait pas lire',
    );

    // Une fois la formation posée, les 2 000 ms courent, ENTIÈRES.
    await tester.pump(settle - settle ~/ 2);
    await tester.pump(const Duration(milliseconds: 1900));
    expect(find.text('reset'), findsNothing);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('reset'), findsOneWidget);

    await tearDownScreen(tester);
  });

  testWidgets('le menu pause ne consomme pas l\'échéance de l\'essai', (
    tester,
  ) async {
    await startGameplay(tester);
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Reprendre'), findsOneWidget);

    // Trois secondes dans le menu : bien au-delà des 2 000 ms de l'essai.
    await tester.pump(const Duration(seconds: 3));
    expect(
      find.text('reset'),
      findsNothing,
      reason: 'le jeu est en pause : aucun essai ne peut être perdu',
    );

    await tester.tap(find.text('Reprendre'));
    await tester.pump();
    // La reprise rejoue l'attente d'acrobatie PUIS réarme une échéance
    // ENTIÈRE : elle ne reprend pas un reliquat.
    await tester.pump(MoveFastPlane.formationSettle(6, manoeuvring: false));
    await tester.pump(const Duration(milliseconds: 1900));
    expect(find.text('reset'), findsNothing);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('reset'), findsOneWidget);

    await tearDownScreen(tester);
  });

  /// Retour client : « ajouter une animation de mouvement de l'avion au moment
  /// du changement de couleur […] rendre la transition plus dynamique ».
  ///
  /// Le plateau faisait déjà défiler les avions en boucle, à vitesse constante :
  /// un changement de règle ne se voyait qu'à la couleur. On vérifie donc qu'à
  /// l'apparition d'une formation, les avions parcourent nettement PLUS de
  /// chemin qu'en croisière — c'est exactement ce que « petite animation de
  /// déplacement » veut dire, et c'est mesurable.
  testWidgets('un élan de déplacement lance la formation', (tester) async {
    await startGameplay(tester);

    /// Position de chaque avion telle que le plateau la pose : le `Positioned`
    /// le plus proche porte `left`/`top`, c'est-à-dire exactement la valeur que
    /// l'élan modifie.
    ///
    /// On lit ces coordonnées plutôt que les rectangles à l'écran : l'avion
    /// pivote pendant son entrée, ce qui fait respirer son rectangle englobant.
    /// On mesurerait alors le virage au lieu de l'élan.
    List<Offset> slots() {
      final out = <Offset>[];
      for (final element in find.byType(MoveFastPlane).evaluate()) {
        Positioned? slot;
        element.visitAncestorElements((ancestor) {
          if (ancestor.widget is Positioned) {
            slot = ancestor.widget as Positioned;
            return false;
          }
          return true;
        });
        out.add(Offset(slot?.left ?? 0, slot?.top ?? 0));
      }
      return out;
    }

    /// Chemin parcouru par la formation entre deux instants, projeté sur un axe.
    ///
    /// Un avion qui boucle (il ressort par le bord opposé) fait un saut de la
    /// longueur du plateau : ce n'est pas un déplacement, on l'écarte. Le seuil
    /// se prend sur l'axe mesuré — l'écran est deux fois plus haut que large, un
    /// seuil unique laisserait passer les bouclages verticaux.
    double travelled(List<Offset> a, List<Offset> b, {required bool onX}) {
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      final wrap = (onX ? screen.width : screen.height) * 0.6;
      var total = 0.0;
      for (var i = 0; i < math.min(a.length, b.length); i++) {
        final d = onX ? (b[i].dx - a[i].dx).abs() : (b[i].dy - a[i].dy).abs();
        if (d < wrap) total += d;
      }
      return total;
    }

    // Fenêtre d'entrée, depuis la première image de la formation.
    await tester.pump(const Duration(milliseconds: 16));
    final entryStart = slots();
    await tester.pump(const Duration(milliseconds: 600));
    final entryEnd = slots();

    // Fenêtre de croisière : même durée, plus aucune animation d'entrée.
    await tester.pump(const Duration(milliseconds: 100));
    final cruiseStart = slots();
    await tester.pump(const Duration(milliseconds: 600));
    final cruiseEnd = slots();

    // L'axe de vol est celui sur lequel la croisière déplace les avions ; on le
    // déduit au lieu de le supposer, la trajectoire étant tirée au sort.
    final cruiseX = travelled(cruiseStart, cruiseEnd, onX: true);
    final cruiseY = travelled(cruiseStart, cruiseEnd, onX: false);
    final onX = cruiseX > cruiseY;
    final cruise = onX ? cruiseX : cruiseY;
    final entry = travelled(entryStart, entryEnd, onX: onX);

    expect(
      entry,
      greaterThan(cruise * 1.6),
      reason:
          'à durée égale, l\'entrée doit pousser les avions bien plus loin que '
          'le défilement seul (entrée $entry px, croisière $cruise px)',
    );

    await tearDownScreen(tester);
  });

  // ── Continuité d'un essai à l'autre ───────────────────────────────────────
  //
  // Retour client : « quand je change de couleur ou de règle de mouvement — par
  // exemple de droite-à-gauche à haut-en-bas — il ne faut pas une apparition
  // rapide comme une transition très rapide ; ce sera une animation complète
  // qui contient le changement de couleur ».
  //
  // Deux dispositifs avaient été essayés et refusés, tous deux du même défaut :
  // ils REMPLAÇAIENT la formation. Une bascule 3D d'abord, un fondu croisé de
  // 220 ms ensuite. Les avions vivent maintenant toute la partie ; ce qui
  // change entre deux essais est interpolé sur eux.
  group('continuité', () {
    /// Chaque avion à l'écran, indexé par sa VOIE.
    ///
    /// La voie est portée par une `ValueKey<int>` posée sur l'avion défilant :
    /// c'est le seul repère stable quand la formation passe de 6 avions à 4 et
    /// que les positions dans l'arbre se décalent.
    Map<int, ({Offset at, Color color})> fleet(WidgetTester tester) {
      final out = <int, ({Offset at, Color color})>{};
      for (final element in find.byType(MoveFastPlane).evaluate()) {
        Positioned? slot;
        int? lane;
        element.visitAncestorElements((ancestor) {
          if (slot == null && ancestor.widget is Positioned) {
            slot = ancestor.widget as Positioned;
          }
          if (ancestor.widget.key case final ValueKey<int> k) {
            lane = k.value;
            return false;
          }
          return true;
        });
        if (lane == null) continue;
        out[lane!] = (
          at: Offset(slot?.left ?? 0, slot?.top ?? 0),
          color: (element.widget as MoveFastPlane).color,
        );
      }
      return out;
    }

    /// Suit la flotte image par image jusqu'à ce que la couleur change, puis
    /// pendant toute la figure qui suit.
    Future<List<Map<int, ({Offset at, Color color})>>> acrossTrialChange(
      WidgetTester tester,
    ) async {
      const frame = Duration(milliseconds: 16);
      Color colorOf(Map<int, ({Offset at, Color color})> f) =>
          f.values.first.color;

      // On se cale d'abord en croisière, loin de l'élan d'entrée.
      await tester.pump(const Duration(milliseconds: 900));
      final before = colorOf(fleet(tester));

      final track = <Map<int, ({Offset at, Color color})>>[fleet(tester)];
      var elapsed = Duration.zero;
      var changed = false;
      // Jusqu'au changement de couleur, puis 800 ms de figure complète.
      while (elapsed < const Duration(seconds: 12)) {
        await tester.pump(frame);
        elapsed += frame;
        final now = fleet(tester);
        track.add(now);
        if (!changed && colorOf(now) != before) changed = true;
        if (changed && elapsed > const Duration(milliseconds: 800)) {
          if (colorOf(now) != before &&
              colorOf(track[track.length - 2]) == colorOf(now)) {
            break;
          }
        }
      }
      expect(changed, isTrue, reason: 'aucun changement d\'essai en 12 s');
      return track;
    }

    testWidgets('la couleur se déverse, elle ne bascule pas', (tester) async {
      await startGameplay(tester);
      final track = await acrossTrialChange(tester);

      final colors = [for (final f in track) f.values.first.color];
      final first = colors.first;
      final last = colors.last;
      expect(last, isNot(first), reason: 'la couleur a bien changé');

      // Le cœur du retour : il existe des images où la couleur n'est NI
      // l'ancienne NI la nouvelle. Un fondu croisé entre deux formations n'en
      // produirait aucune — chaque avion y garde sa couleur pleine, c'est la
      // formation entière qui s'efface.
      final between = colors.where((c) => c != first && c != last).length;
      expect(
        between,
        greaterThan(8),
        reason:
            'la couleur passe de $first à $last en $between images '
            'intermédiaires : c\'est une bascule, pas une animation',
      );

      await tearDownScreen(tester);
    });

    testWidgets('aucun avion n\'apparaît ni ne disparaît d\'un coup', (
      tester,
    ) async {
      await startGameplay(tester);
      final track = await acrossTrialChange(tester);

      for (var i = 1; i < track.length; i++) {
        expect(
          track[i].length,
          lessThanOrEqualTo(6),
          reason:
              'plus de 6 avions à l\'image $i : deux formations se superposent, '
              'donc l\'une remplace l\'autre',
        );
        expect(
          track[i],
          isNotEmpty,
          reason: 'le plateau se vide à l\'image $i',
        );
      }

      await tearDownScreen(tester);
    });

    // LE défaut que ce groupe avait laissé passer.
    //
    // Un essai peut s'achever AVANT sa figure : le joueur répond, l'essai
    // suivant arrive 650 ms plus tard, or la figure en demande près du double.
    // Elle était alors coupée et la suivante repartait de l'attitude NOMINALE —
    // ailes à plat, cap de l'essai précédent. L'avion, qui pouvait être sur la
    // tranche, sautait à l'horizontale. Le client l'a vu : « une apparition très
    // rapide dans quelques transitions, pas toutes » — seulement celles où il
    // avait répondu vite.
    testWidgets('une réponse rapide n\'interrompt pas la figure', (
      tester,
    ) async {
      await startGameplay(tester);

      /// Attitude de chaque avion, lue À LA SOURCE.
      ///
      /// On lit les valeurs que le plateau DONNE à l'avion, et non celles
      /// reconstruites depuis sa matrice : près du couteau, l'envergure est
      /// bornée à `minWingspan` et son signe bascule d'un coup, si bien que
      /// l'angle relu par `rollOf` saute de 0,6 rad là où le roulis réel est
      /// parfaitement continu. On mesurerait le garde-fou, pas l'animation.
      ///
      /// Le roulis lu ici s'accumule (0 → −2π → −4π) : c'est voulu, une
      /// différence brute suffit et il n'y a rien à replier.
      Map<int, ({double heading, double roll})> attitude() {
        final out = <int, ({double heading, double roll})>{};
        for (final element in find.byType(MoveFastPlane).evaluate()) {
          int? lane;
          element.visitAncestorElements((ancestor) {
            if (ancestor.widget.key case final ValueKey<int> k) {
              lane = k.value;
              return false;
            }
            return true;
          });
          if (lane == null) continue;
          final plane = element.widget as MoveFastPlane;
          out[lane!] = (
            heading:
                plane.heading ?? MoveFastPlane.angleFor(plane.noseDirection),
            roll: plane.roll,
          );
        }
        return out;
      }

      // On répond au bout de 200 ms : bien avant la fin de la figure d'entrée.
      // L'essai suivant tombera donc en plein tonneau.
      await tester.pump(const Duration(milliseconds: 200));

      // Un segment par réponse. On échantillonne à cadence RÉGULIÈRE à
      // l'intérieur d'un segment seulement : `tester.tap` insère une image sans
      // avancer l'horloge, et l'intervalle qui la suit vaudrait le double — on
      // mesurerait le test au lieu de l'animation. Le changement d'essai, lui,
      // tombe 650 ms après la réponse, donc bien à l'intérieur du segment :
      // c'est exactement la couture qu'on veut voir.
      const frame = Duration(milliseconds: 16);
      const segment = 56; // ≈ 900 ms, la durée d'une figure
      var worstRoll = 0.0;
      var worstHeading = 0.0;

      for (var pass = 0; pass < 3; pass++) {
        await tester.tap(find.text('Droite'));
        await tester.pump(frame);
        var previous = attitude();
        for (var i = 1; i < segment; i++) {
          await tester.pump(frame);
          final now = attitude();
          for (final lane in now.keys) {
            final was = previous[lane];
            if (was == null) continue; // voie qui vient de se rallumer
            worstRoll = math.max(worstRoll, (now[lane]!.roll - was.roll).abs());
            worstHeading = math.max(
              worstHeading,
              gap(now[lane]!.heading, was.heading),
            );
          }
          previous = now;
        }
      }

      // Le roulis avance vite — un tour en 900 ms — mais jamais par sauts. Au
      // régime le plus rapide de la figure il parcourt ~0,21 rad par image ;
      // au-delà de 0,35, c'est une couture, pas une rotation.
      expect(
        worstRoll,
        lessThan(0.35),
        reason:
            'le roulis bondit de $worstRoll rad en une image : une figure a été '
            'coupée et la suivante est repartie de l\'attitude nominale',
      );
      // Le cap va vite lui aussi, et le plafond doit être celui de la PHYSIQUE
      // de la figure, pas celui des virages que la graine tire.
      //
      // `headingProgress` est une easeInOutCubic étalée sur 63 % de la figure :
      // sa pente maximale vaut 3, donc 3 / 0,63 ≈ 4,76 par unité de figure. À
      // 60 images/s, une image couvre 16/900 de la figure, soit 8,5 % du virage
      // au régime le plus rapide. Un DEMI-TOUR — le plus grand virage possible,
      // `shortestTurnFrom` bornant le trajet à π — parcourt donc 0,266 rad par
      // image. C'est du mouvement rapide, pas une couture.
      //
      // Le seuil valait 0,2 : entre le quart de tour (0,133) et le demi-tour.
      // Il ne tenait que tant que la graine ne tirait aucun demi-tour dans ces
      // trois passes. Une modification sans rapport, ailleurs dans le tirage
      // aléatoire, en a fait sortir un — et le test a crié sur une animation
      // parfaitement continue, dont la vitesse montait par paliers réguliers
      // (0,127 · 0,159 · 0,184 · 0,218 · 0,242).
      //
      // Le défaut que ce test protège reste attrapé de très loin : une figure
      // coupée fait repartir l'avion de l'attitude NOMINALE, soit un saut de
      // l'ordre du radian — cinq fois ce plafond.
      expect(
        worstHeading,
        lessThan(0.32),
        reason: 'le cap bondit de $worstHeading rad en une image',
      );

      await tearDownScreen(tester);
    });

    // Retour client : « quand je passe d'une transition à l'autre, l'avion fait
    // juste l'acrobatie vers cette direction — c'est ça l'animation, sans
    // aucune disparition ni apparition ultra rapide. »
    testWidgets('rien ne s\'estompe jamais en cours de partie', (tester) async {
      await startGameplay(tester);
      // L'élan d'entrée du tout premier plateau monte l'opacité de 0,4 à 1 :
      // on le laisse finir, c'est l'ouverture, pas une transition.
      await tester.pump(const Duration(milliseconds: 900));

      double worst = 1;
      const frame = Duration(milliseconds: 16);
      for (var t = Duration.zero; t < const Duration(seconds: 9); t += frame) {
        await tester.pump(frame);
        for (final element in find.byType(MoveFastPlane).evaluate()) {
          element.visitAncestorElements((ancestor) {
            if (ancestor.widget case final Opacity o) {
              worst = math.min(worst, o.opacity);
              return false;
            }
            return true;
          });
        }
      }

      expect(
        worst,
        closeTo(1, 1e-6),
        reason:
            'un avion est descendu à $worst d\'opacité : quelque chose '
            's\'estompe encore, et le client le voit comme une disparition',
      );

      await tearDownScreen(tester);
    });

    testWidgets('un avion qui quitte la formation sort par le bord', (
      tester,
    ) async {
      await startGameplay(tester);
      await tester.pump(const Duration(milliseconds: 900));

      /// Rectangle du plateau, celui qui découpe les avions.
      final board = tester.getRect(
        find
            .descendant(
              of: find.byType(MoveFastScreen),
              matching: find.byWidgetPredicate(
                (w) => w is Container && w.clipBehavior != Clip.none,
              ),
            )
            .first,
      );

      Map<int, Rect> onBoard() {
        final out = <int, Rect>{};
        for (final element in find.byType(MoveFastPlane).evaluate()) {
          int? lane;
          element.visitAncestorElements((ancestor) {
            if (ancestor.widget.key case final ValueKey<int> k) {
              lane = k.value;
              return false;
            }
            return true;
          });
          if (lane == null) continue;
          final box = element.renderObject as RenderBox?;
          if (box == null || !box.hasSize) continue;
          out[lane!] = box.localToGlobal(Offset.zero) & box.size;
        }
        return out;
      }

      const frame = Duration(milliseconds: 16);
      var previous = onBoard();
      var checked = 0;
      for (var t = Duration.zero; t < const Duration(seconds: 12); t += frame) {
        await tester.pump(frame);
        final now = onBoard();
        for (final lane in previous.keys) {
          if (now.containsKey(lane)) continue;
          // Cet avion vient de quitter l'arbre : à l'image d'avant, il devait
          // déjà être hors du plateau. Sinon il s'est évaporé sur place.
          checked++;
          expect(
            previous[lane]!.overlaps(board),
            isFalse,
            reason:
                'la voie $lane a disparu alors qu\'elle était encore sur le '
                'plateau (${previous[lane]} dans $board)',
          );
        }
        previous = now;
      }

      expect(
        checked,
        greaterThan(0),
        reason:
            'aucune voie ne s\'est retirée en 12 s : le test n\'a rien vérifié',
      );

      await tearDownScreen(tester);
    });

    testWidgets('la trajectoire se courbe, elle ne saute pas', (tester) async {
      await startGameplay(tester);
      final track = await acrossTrialChange(tester);

      // Le seul saut légitime est le bouclage — l'avion ressort par le bord
      // opposé — et il fait au moins une demi-longueur de plateau.
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      final wrap = math.min(screen.width, screen.height) * 0.5;

      // Pas de seuil ABSOLU : la surface de test fait 2400 px de haut, un
      // changement d'axe y déplace légitimement un avion de 50 px par image.
      // Ce qu'on mesure est la RÉPARTITION du déplacement — une courbe étale
      // son chemin sur toute la figure, un saut le concentre sur une image.
      final steps = <int, List<double>>{};
      for (var i = 1; i < track.length; i++) {
        for (final lane in track[i].keys) {
          final was = track[i - 1][lane];
          if (was == null) continue; // voie qui vient de se rallumer
          final step = (track[i][lane]!.at - was.at).distance;
          if (step >= wrap) continue; // bouclage
          (steps[lane] ??= <double>[]).add(step);
        }
      }

      expect(steps, isNotEmpty);
      steps.forEach((lane, path) {
        final total = path.reduce((a, b) => a + b);
        final worst = path.reduce(math.max);
        expect(
          worst / total,
          lessThan(0.1),
          reason:
              'la voie $lane concentre ${(worst / total * 100).round()} % de son '
              'chemin sur une seule image (${worst.round()} px sur '
              '${total.round()}) : le changement de règle de mouvement se voit '
              'comme un saut, pas comme une courbe',
        );
      });

      await tearDownScreen(tester);
    });
  });

  // ── Virage ────────────────────────────────────────────────────────────────
  //
  // Retour client : « quand l'avion change de couleur, il fait une animation et
  // change — par exemple une disparition très très rapide, puis il s'affiche à
  // nouveau. Moi je veux que, quand il change de direction, il fasse lui-même
  // l'animation du changement de direction, par exemple une petite rotation
  // pour montrer qu'il change réellement de direction. »
  //
  // La « disparition très rapide » était une bascule 3D de 90° sur l'axe X,
  // jouée à l'apparition de chaque formation : vue de face, elle écrase les
  // avions jusqu'à l'épaisseur d'un trait. Elle masquait le changement au lieu
  // de le montrer, et aucun virage n'était jamais visible — l'avion était
  // reconstruit déjà tourné.

  testWidgets('l\'avion pivote lui-même vers sa nouvelle direction', (
    tester,
  ) async {
    await startGameplay(tester);

    /// Les avions qui ont un virage à jouer, avec l'angle qu'ils affichent.
    ///
    /// Le filtre est indispensable : pendant les 220 ms de fondu entre deux
    /// essais, les DEUX formations sont à l'écran. Les avions sortants n'ont
    /// rien à tourner et fausseraient la mesure.
    List<({MoveFastPlane plane, double angle, double roll})> turning() => [
      for (final element in find.byType(MoveFastPlane).evaluate())
        if (element.widget case final MoveFastPlane p
            when p.turnFrom != null && p.turnFrom != p.noseDirection)
          (plane: p, angle: angleOf(element), roll: rollOf(element)),
    ];

    // On avance à la frame près jusqu'au premier virage : le tirage peut
    // reproduire le même nez deux fois de suite, et il n'y a alors — à juste
    // titre — rien à animer. Sans cette recherche pas à pas, on tomberait au
    // milieu d'un virage déjà entamé, voire déjà fini.
    const frame = Duration(milliseconds: 16);
    var elapsed = Duration.zero;
    while (turning().isEmpty && elapsed < const Duration(seconds: 20)) {
      await tester.pump(frame);
      elapsed += frame;
    }

    final start = turning();
    expect(
      start,
      isNotEmpty,
      reason: 'aucun changement de direction en 20 s de jeu : tirage suspect',
    );

    final before = start.first.plane.turnFrom!;
    final after = start.first.plane.noseDirection;
    final from = MoveFastPlane.angleFor(before);
    final to = MoveFastPlane.shortestTurn(from: before, to: after);
    // La figure ne dure pas pareil pour tout le monde : chaque voie attend son
    // tour dans la vague. La dernière finit `laneStagger × (maxLanes − 1)`
    // après la première.
    const figure = MoveFastPlane.turnDuration;
    final wave = MoveFastPlane.staggerFor(5);

    for (final p in start) {
      expect(
        gap(p.angle, from),
        lessThan(0.1),
        reason:
            'l\'avion apparaît en regardant encore dans son ANCIENNE direction '
            '($before) : sans cela il n\'y a aucun virage à voir',
      );
      expect(
        p.roll.abs(),
        lessThan(0.05),
        reason: 'à l\'entrée dans la figure, il est encore à plat',
      );
    }

    // À mi-figure, au moins un avion n'est ni parti ni arrivé : il tourne, et
    // il est sur l'aile. « Au moins un » et non « tous » : les voies retardées
    // n'ont pas encore commencé — c'est précisément la vague.
    await tester.pump(figure ~/ 2);
    final mid = turning();
    expect(mid, isNotEmpty);
    final moving = [
      for (final p in mid)
        if (gap(p.angle, from) > 0.3 && gap(p.angle, to) > 0.3) p,
    ];
    expect(
      moving,
      isNotEmpty,
      reason: 'à mi-figure, aucun avion n\'est en train de virer',
    );
    for (final p in moving) {
      expect(
        p.roll.abs(),
        greaterThan(0.2),
        reason:
            'le cap tourne mais l\'avion reste à plat : c\'est une aiguille de '
            'boussole, pas un chasseur qui manœuvre',
      );
    }

    // Puis TOUS accrochent leur nouvelle direction, ailes à plat — la vague
    // comprise.
    await tester.pump(figure + wave);
    for (final p in turning()) {
      expect(gap(p.angle, to), lessThan(0.02), reason: 'posé pile sur $after');
      expect(
        p.roll.abs(),
        lessThan(0.02),
        reason:
            'la figure se termine ailes à plat : au moment de répondre, la '
            'silhouette doit être pleinement lisible',
      );
    }

    await tearDownScreen(tester);
  });

  // Retour client : « je veux une rotation complète de l'avion, un tour entier,
  // une acrobatie en 3D comme un avion militaire ».
  //
  // La contrainte qui commande tout le reste : dans « Je bouge », la direction
  // du nez EST la réponse attendue. Une figure qui met le nez ailleurs que sur
  // le cap d'arrivée fabrique une fausse réponse. Le tour se joue donc
  // entièrement sur le ROULIS — un axe que la réponse n'utilise pas — pendant
  // que le cap, lui, va de A à B proprement et sans dépassement.
  group('acrobatie', () {
    /// Échantillonne le roulis sur toute la figure.
    List<double> rollTrack({
      required GameDirection from,
      required GameDirection to,
      int steps = 200,
    }) => [
      for (var i = 0; i <= steps; i++)
        MoveFastPlane.rollAt(t: i / steps, from: from, to: to),
    ];

    test('TOUT changement de direction fait un tour complet', () {
      // Y compris le quart de tour, qui est le cas le plus fréquent : deux
      // directions sur trois. Une version antérieure n'y mettait qu'une
      // inclinaison sur l'aile — le client l'a refusée, il veut l'acrobatie
      // partout.
      for (final from in GameDirection.values) {
        for (final to in GameDirection.values) {
          if (from == to) continue;
          final track = rollTrack(from: from, to: to);

          expect(
            track.first,
            closeTo(0, 1e-9),
            reason: '$from → $to : ailes à plat au départ',
          );
          expect(
            track.last.abs(),
            closeTo(2 * math.pi, 1e-6),
            reason:
                '$from → $to : un tour entier autour du fuselage — et donc, '
                'mod 2π, de nouveau à plat pour la réponse',
          );
          // Une fois l'élan lâché, le tonneau ne revient pas sur lui-même : le
          // roulis est monotone jusqu'au bout. (Avant ce point, il part À
          // L'ENVERS — c'est l'anticipation, testée séparément.)
          final afterWindUp = track.sublist(
            track.indexWhere((r) => r * track.last > 0),
          );
          for (var i = 1; i < afterWindUp.length; i++) {
            expect(
              afterWindUp[i].abs(),
              greaterThanOrEqualTo(afterWindUp[i - 1].abs() - 1e-9),
              reason: '$from → $to : le tour s\'inverse en cours de route',
            );
          }
          // Il passe bien par le vol dos. Le milieu de la course n'est PAS le
          // milieu du temps : `Curves.easeInOutCubic` est une bézier, elle vaut
          // 0,517 à t = 0,5 et non 0,5. On cherche le passage, pas l'instant.
          expect(
            track.any((r) => (r.abs() - math.pi).abs() < 0.05),
            isTrue,
            reason: '$from → $to : il ne passe jamais sur le dos',
          );
        }
      }
    });

    test('l\'avion tourne DANS le sens de son virage, pas contre', () {
      // `right` → `down` vire dans le sens horaire, `right` → `up` dans
      // l'autre : les deux tonneaux doivent s'enrouler en sens opposés.
      const t = 0.5;
      final clockwise = MoveFastPlane.rollAt(
        t: t,
        from: GameDirection.right,
        to: GameDirection.down,
      );
      final counter = MoveFastPlane.rollAt(
        t: t,
        from: GameDirection.right,
        to: GameDirection.up,
      );
      expect(clockwise * counter, lessThan(0));
    });

    test('l\'avion s\'incline d\'abord À L\'ENVERS : c\'est l\'élan', () {
      // Anticipation : le geste se ramasse avant de partir. Sans elle la
      // rotation démarre de nulle part et paraît subie.
      final track = rollTrack(
        from: GameDirection.right,
        to: GameDirection.down,
      );
      final end = track.last;

      final windUp = track.takeWhile((r) => r * end <= 0).toList();
      expect(
        windUp.length,
        greaterThan(4),
        reason: 'aucun contre-roulis avant le tour',
      );
      final deepest = windUp.map((r) => r.abs()).reduce(math.max);
      expect(
        deepest,
        inInclusiveRange(0.08, 0.35),
        reason:
            'l\'élan fait $deepest rad : trop peu il ne se voit pas, trop il se '
            'lit comme un départ dans le mauvais sens',
      );
      // Et il se paie sur le début de la figure, pas sur la fin.
      expect(windUp.length / track.length, lessThan(0.25));
    });

    test('le cap suit le roulis, et se pose avant lui', () {
      // L'ordre fait la lecture : l'avion s'incline, DONC il vire. Et sa
      // direction — la réponse — est acquise avant la fin de la figure.
      expect(
        MoveFastPlane.headingProgress(0.05),
        0,
        reason: 'le cap ne bouge pas tant que l\'avion ne s\'est pas incliné',
      );
      expect(
        MoveFastPlane.headingProgress(0.8),
        1,
        reason:
            'la direction doit être lisible avant que la figure ne s\'achève, '
            'sinon le joueur attend la fin de l\'acrobatie pour répondre',
      );
      // Monotone, et sans dépassement : la direction porte la réponse.
      var previous = 0.0;
      for (var i = 0; i <= 100; i++) {
        final p = MoveFastPlane.headingProgress(i / 100);
        expect(p, inInclusiveRange(0, 1));
        expect(p, greaterThanOrEqualTo(previous - 1e-9));
        previous = p;
      }
    });

    test('un avion qui rejoint la formation prend toute la figure', () {
      // Le défaut corrigé : l'arrivée était branchée sur `headingProgress`, qui
      // est plat avant 0,12 et après 0,75. L'avion couvrait donc plus d'une
      // longueur de plateau en 567 ms des 900 de la figure — il ne rejoignait
      // pas la formation, il y surgissait.
      expect(MoveFastPlane.joinProgress(0), 0);
      expect(MoveFastPlane.joinProgress(1), 1);
      expect(
        MoveFastPlane.joinProgress(0.05),
        greaterThan(0),
        reason: 'l\'arrivée commence AVEC la figure, elle n\'attend pas le cap',
      );
      expect(
        MoveFastPlane.joinProgress(0.9),
        lessThan(1),
        reason: 'et elle se termine AVEC elle, sans se poser en avance',
      );

      // Monotone : un avion ne recule pas vers l'extérieur de la formation.
      var previous = 0.0;
      for (var i = 0; i <= 200; i++) {
        final p = MoveFastPlane.joinProgress(i / 200);
        expect(p, inInclusiveRange(0, 1));
        expect(p, greaterThanOrEqualTo(previous - 1e-9));
        previous = p;
      }

      // Elle DÉCÉLÈRE : un avion se range dans une formation en ralentissant,
      // il ne freine pas à mi-chemin pour repartir. La première moitié du temps
      // doit donc couvrir bien plus que la moitié du trajet.
      expect(MoveFastPlane.joinProgress(0.5), greaterThan(0.6));

      // Et l'entrée visible dure PLUS LONGTEMPS qu'avec l'ancienne courbe :
      // c'est la comparaison qui définit la correction.
      double firstAbove(double Function(double) curve, double target) {
        for (var i = 0; i <= 1000; i++) {
          if (curve(i / 1000) >= target) return i / 1000;
        }
        return 1;
      }

      // L'avion part à 1,2 longueur de plateau : il entre dans le cadre quand
      // il a couvert 1/1,2 de cet écart, et son entrée dure jusqu'à ce que la
      // courbe soit pleine. C'est CETTE portion-là que le joueur voit.
      const enters = 1 - 1 / 1.2;
      double visibleSpan(double Function(double) curve) =>
          firstAbove(curve, 0.9999) - firstAbove(curve, enters);

      expect(
        visibleSpan(MoveFastPlane.joinProgress),
        greaterThan(visibleSpan(MoveFastPlane.headingProgress) * 1.8),
        reason: 'l\'entrée visible doit durer près du double',
      );

      // Et surtout : la POINTE de vitesse dans le cadre doit baisser. C'est
      // elle que le joueur lit comme « brusque » — une entrée longue mais qui
      // garde un à-coup n'aurait rien réglé.
      double peakInFrame(double Function(double) curve) {
        var peak = 0.0;
        var previous = double.nan;
        for (var i = 0; i <= 1000; i++) {
          final off = (1 - curve(i / 1000)) / (1 - enters);
          if (!previous.isNaN && off <= 1) {
            final v = previous - off;
            if (v > peak) peak = v;
          }
          previous = off;
        }
        return peak;
      }

      expect(
        peakInFrame(MoveFastPlane.joinProgress),
        lessThan(peakInFrame(MoveFastPlane.headingProgress)),
      );
    });

    test('un avion grossit en arrivant, et rien ne bouge pour les autres', () {
      // La taille fait partie du mouvement : sans elle, l'avion traverse le
      // plateau à sa taille définitive et se lit comme une image qu'on glisse.
      expect(
        MoveFastPlane.approachScale(1),
        1,
        reason: 'un avion qui RESTE dans la formation garde sa taille',
      );
      expect(MoveFastPlane.approachScale(0), lessThan(1));

      var previous = MoveFastPlane.approachScale(0);
      for (var i = 1; i <= 100; i++) {
        final scale = MoveFastPlane.approachScale(i / 100);
        expect(scale, greaterThan(previous));
        expect(scale, inInclusiveRange(0, 1));
        previous = scale;
      }
    });

    test('l\'élan pousse l\'avion, puis le rend', () {
      // La poussée ne doit rien laisser derrière elle : l'avion reprend
      // exactement sa place de croisière, sinon la formation dériverait d'essai
      // en essai.
      expect(MoveFastPlane.surgeAt(0), closeTo(0, 1e-9));
      expect(MoveFastPlane.surgeAt(1), closeTo(0, 1e-9));
      expect(MoveFastPlane.surgeAt(0.5), closeTo(1, 1e-9));
    });

    test('la formation manœuvre en vague, pas en bloc', () {
      // Six tonneaux simultanés font une machine ; décalés, ils font une
      // patrouille.
      expect(MoveFastPlane.staggerFor(0), Duration.zero);
      for (var slot = 1; slot < 6; slot++) {
        expect(
          MoveFastPlane.staggerFor(slot),
          greaterThan(MoveFastPlane.staggerFor(slot - 1)),
        );
      }
      // La vague reste courte : les avions affichent des caps différents tant
      // qu'elle passe. Ils convergent tous vers la même direction — personne ne
      // peut se tromper à cause du décalage — mais on ne fait pas attendre.
      expect(
        MoveFastPlane.staggerFor(5).inMilliseconds,
        lessThan(MoveFastPlane.turnDuration.inMilliseconds ~/ 2),
      );
    });

    test('la figure ne mord plus du tout sur la fenêtre de réponse', () {
      // Le dernier avion de la vague est celui qui compte : c'est lui qui fixe
      // le moment où le plateau est enfin stable, et donc où l'échéance part.
      expect(
        MoveFastPlane.formationSettle(6),
        MoveFastPlane.staggerFor(5) + MoveFastPlane.turnDuration,
      );
      // Elle reste néanmoins bornée : chaque essai coûte au joueur l'acrobatie
      // EN PLUS de son temps de réponse, donc une figure qui s'allonge réduit
      // le nombre d'essais d'une partie — et avec lui la finesse de la mesure.
      expect(
        MoveFastPlane.formationSettle(6).inMilliseconds,
        lessThan(MoveFastConfig.trialTimeoutMs),
        reason:
            'l\'acrobatie dure plus longtemps que la réponse elle-même : une '
            'partie de 15 minutes y perdrait la moitié de ses essais',
      );
    });

    // Vérification EXHAUSTIVE des douze rotations — haut→gauche, gauche→bas,
    // bas→haut et les neuf autres. Demandée nommément par le client ; elle
    // remplace l'inspection à l'œil, qui ne peut pas distinguer un quart de
    // tour horaire d'un trois-quarts de tour antihoraire sur une image fixe.
    test('les douze rotations, une par une', () {
      const quarter = math.pi / 2;
      final report = StringBuffer();

      for (final from in GameDirection.values) {
        for (final to in GameDirection.values) {
          if (from == to) continue;
          final label = '${from.name} → ${to.name}';
          final start = MoveFastPlane.angleFor(from);
          final end = MoveFastPlane.shortestTurnFrom(fromAngle: start, to: to);
          final travel = end - start;

          // 1. On part exactement de l'ancienne direction.
          expect(
            MoveFastPlane.headingProgress(0),
            0,
            reason: '$label : la figure ne part pas de $from',
          );

          // 2. On arrive exactement sur la nouvelle, pas à 2π près.
          expect(
            gap(end, MoveFastPlane.angleFor(to)),
            lessThan(1e-9),
            reason: '$label : n\'atterrit pas sur $to',
          );

          // 3. Par le PLUS COURT chemin : un quart de tour, ou un demi-tour
          //    pour les directions opposées. Jamais trois quarts.
          final expected = (MoveFastPlane.angleFor(to) - start).abs() > math.pi
              ? quarter
              : (MoveFastPlane.angleFor(to) - start).abs();
          expect(
            travel.abs(),
            closeTo(expected, 1e-9),
            reason:
                '$label : parcourt ${travel.abs()} rad au lieu de $expected — '
                'l\'avion fait le tour par le mauvais côté',
          );
          expect(travel.abs(), lessThanOrEqualTo(math.pi + 1e-9));

          // 4. Le cap ne recule ni ne dépasse : c'est lui qui porte la réponse.
          var previous = start;
          for (var i = 1; i <= 200; i++) {
            final h = start + travel * MoveFastPlane.headingProgress(i / 200);
            final advanced = (h - start) * travel.sign;
            final before = (previous - start) * travel.sign;
            expect(
              advanced,
              greaterThanOrEqualTo(before - 1e-9),
              reason: '$label : le cap recule à f = ${i / 200}',
            );
            expect(
              advanced,
              lessThanOrEqualTo(travel.abs() + 1e-9),
              reason: '$label : le cap DÉPASSE $to à f = ${i / 200}',
            );
            previous = h;
          }

          // 5. Le tonneau : un tour entier, dans le sens du virage, et il
          //    passe bien par le vol dos.
          final way = travel.isNegative ? -1.0 : 1.0;
          final roll = [
            for (var i = 0; i <= 200; i++)
              MoveFastPlane.rollFigure(from: 0, way: way, f: i / 200),
          ];
          expect(
            roll.first,
            closeTo(0, 1e-9),
            reason: '$label : roulis initial',
          );
          expect(
            roll.last,
            closeTo(way * 2 * math.pi, 1e-6),
            reason: '$label : le tour n\'est pas complet',
          );
          expect(
            roll.any((r) => (r.abs() - math.pi).abs() < 0.05),
            isTrue,
            reason: '$label : ne passe pas sur le dos',
          );
          // L'élan part à l'envers du tour.
          expect(
            roll.any((r) => r * way < -0.05),
            isTrue,
            reason: '$label : pas de contre-roulis d\'élan',
          );

          report.writeln(
            '$label : ${(travel.abs() / quarter).round()} quart(s) de tour '
            '${travel.isNegative ? "antihoraire" : "horaire"}, '
            'tonneau ${way > 0 ? "horaire" : "antihoraire"}',
          );
        }
      }

      // Trace lisible : `flutter test -r expanded` l'affiche en cas d'échec.
      printOnFailure(report.toString());
    });

    test('l\'avion ne s\'efface jamais complètement, même à la tranche', () {
      // Le couteau — l'avion parfaitement de profil — le réduirait à un trait.
      // C'est ce que le client avait signalé sur l'ancienne bascule 3D : « une
      // disparition très très rapide ». Le tonneau y passe deux fois par tour,
      // il faut donc que le plancher d'envergure tienne.
      expect(MoveFastPlane.minWingspan, greaterThan(0.25));
      expect(
        MoveFastPlane.minWingspan,
        lessThan(0.5),
        reason: 'au-delà, la rotation ne se lit plus comme une rotation',
      );
    });
  });

  test('le virage passe toujours par le plus court chemin', () {
    // « gauche » (π) → « haut » (−π/2) : interpoler les angles bruts ferait
    // parcourir trois quarts de tour à rebours. Le virage réel est d'un quart
    // de tour, dans l'autre sens.
    expect(
      MoveFastPlane.shortestTurn(
        from: GameDirection.left,
        to: GameDirection.up,
      ),
      closeTo(math.pi + math.pi / 2, 1e-9),
      reason: 'π → 3π/2, soit un quart de tour dans le sens horaire',
    );
    expect(
      MoveFastPlane.shortestTurn(
        from: GameDirection.up,
        to: GameDirection.left,
      ),
      closeTo(-math.pi, 1e-9),
      reason: '−π/2 → −π : le quart de tour symétrique',
    );

    // Aucun virage ne doit dépasser un demi-tour.
    for (final from in GameDirection.values) {
      for (final to in GameDirection.values) {
        final travel =
            (MoveFastPlane.shortestTurn(from: from, to: to) -
                    MoveFastPlane.angleFor(from))
                .abs();
        expect(
          travel,
          lessThanOrEqualTo(math.pi + 1e-9),
          reason: '$from → $to fait faire $travel rad à l\'avion',
        );
      }
    }
  });
}

/// Écart entre deux angles, mesuré sur le cercle.
///
/// `Transform` ne conserve pas les tours : la matrice ne retient que le cosinus
/// et le sinus, donc `atan2` rend toujours un angle réduit à ]−π, π]. Comparer
/// des angles bruts ferait échouer le demi-tour, où −π et +π désignent la même
/// direction.
/// Angle de rotation réellement appliqué à un avion, lu dans la matrice du
/// `Transform` que [MoveFastPlane] pose autour de son dessin.
Float64List matrixOf(Element planeElement) {
  Transform? found;
  void visit(Element el) {
    if (found != null) return;
    if (el.widget is Transform) {
      found = el.widget as Transform;
      return;
    }
    el.visitChildren(visit);
  }

  planeElement.visitChildren(visit);
  return found!.transform.storage;
}

/// Cap réellement affiché par un avion.
///
/// La matrice de la manœuvre est `Rz(cap) · Rx(roulis)` : sa première colonne
/// vaut (cos cap, sin cap, 0), le roulis n'y entre pas. Le cap se lit donc
/// tel quel, que l'avion soit à plat ou sur la tranche.
double angleOf(Element planeElement) {
  final m = matrixOf(planeElement);
  return math.atan2(m[1], m[0]);
}

/// Roulis réellement affiché par un avion, ramené dans ]−π, π].
///
/// Deuxième colonne de `Rz(cap) · Rx(roulis)` : (−sin cap · cos roulis,
/// cos cap · cos roulis, **sin roulis**). L'élément (ligne 2, colonne 1) donne
/// donc `sin roulis` seul, et la combinaison avec la première colonne rend
/// `cos roulis` — de quoi reconstruire l'angle sans que le cap n'y entre.
///
/// Lire le seul sinus ne suffirait pas : à mi-tonneau l'avion est sur le dos,
/// `sin π = 0`, et on conclurait à tort qu'il vole à plat.
double rollOf(Element planeElement) {
  final m = matrixOf(planeElement);
  return math.atan2(m[6], m[0] * m[5] - m[1] * m[4]);
}

double gap(double a, double b) {
  var d = (a - b) % (2 * math.pi);
  if (d > math.pi) d -= 2 * math.pi;
  if (d < -math.pi) d += 2 * math.pi;
  return d.abs();
}
