import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/presentation/flame/grid_config.dart';
import 'package:zennyt/features/games/presentation/flame/planifik_game.dart';

/// Optimal Path — tracé au glissement.
///
/// Retour client : « dans le trajet je peux avoir un glissement — tracer le
/// trajet par glissement (swipe) le long du parcours, pour avoir une meilleure
/// expérience ». Le plateau ne répondait qu'à l'appui station par station : sur
/// un niveau à huit pas, cela faisait huit appuis précis sur des cercles de la
/// taille d'un doigt.
///
/// Ces tests vérifient que le glissement obéit aux **mêmes règles** que l'appui
/// — c'est le point critique : deux gestes qui produiraient deux tracés
/// différents fausseraient la mesure (`pathLength`, zones coûteuses, bonus).
void main() {
  /// 3×3, départ (0,0), arrivée (2,2), obstacle au centre (1,1), étoile en
  /// (0,2). Contourner par le haut coûte 4 pas et rafle l'étoile.
  const board = GridConfig(
    cols: 3,
    rows: 3,
    start: 0,
    end: 8,
    obstacles: {4},
    costlyZones: {},
    objectives: {2},
    optimalLength: 4,
  );

  /// Le plateau occupe une surface connue : 300×300 → cases de 100×100, donc
  /// centre de (row, col) = (col × 100 + 50, row × 100 + 50).
  const boardSize = 300.0;
  const cell = boardSize / 3;
  Offset centerOf(int row, int col) =>
      Offset(col * cell + cell / 2, row * cell + cell / 2);

  Future<PlanifikGame> pumpGame(
    WidgetTester tester, {
    void Function()? onBlockedTap,
    void Function()? onWrongCell,
  }) async {
    final game = PlanifikGame(
      config: board,
      onBlockedTap: onBlockedTap,
      onWrongCell: onWrongCell,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: boardSize,
              height: boardSize,
              child: GameWidget(game: game),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    return game;
  }

  group('seam dragThrough — les règles du tracé', () {
    testWidgets('un glissement depuis LAB trace toute la route', (
      tester,
    ) async {
      final game = await pumpGame(tester);
      expect(game.stepCount, 0);

      game.dragThrough(const [(0, 0), (0, 1), (0, 2), (1, 2), (2, 2)]);

      expect(game.stepCount, 4, reason: 'quatre pas, comme quatre appuis');
      expect(game.isComplete, isTrue);
      expect(game.bonusCount, 1, reason: 'l\'étoile (0,2) est sur la route');
    });

    testWidgets('rebrousser chemin efface le dernier pas', (tester) async {
      final game = await pumpGame(tester);
      game.dragThrough(const [(0, 0), (0, 1), (0, 2)]);
      expect(game.stepCount, 2);

      // Le doigt revient sur ses pas, sans être relevé.
      game.dragThrough(const [(0, 2), (0, 1)]);
      expect(
        game.stepCount,
        1,
        reason: 'revenir sur l\'avant-dernière case défait le dernier pas',
      );
      // …et le tracé repart normalement.
      game.dragThrough(const [(0, 1), (1, 1)]);
      expect(game.stepCount, 1, reason: '(1,1) est un obstacle');
    });

    testWidgets('un obstacle sur la trajectoire arrête le tracé et se signale', (
      tester,
    ) async {
      var blocked = 0;
      var penalties = 0;
      final game = await pumpGame(
        tester,
        onBlockedTap: () => blocked++,
        onWrongCell: () => penalties++,
      );

      // Descente droite depuis LAB : (1,0) passe, (1,1) est l'obstacle.
      game.dragThrough(const [(0, 0), (1, 0), (1, 1), (1, 2)]);

      expect(game.stepCount, 1, reason: 'la route s\'arrête avant l\'obstacle');
      expect(blocked, 1, reason: 'son + vibration, une seule fois');
      expect(
        penalties,
        1,
        reason:
            'traverser un obstacle depuis la tête du tracé est une faute de '
            'planification, au glissement comme à l\'appui',
      );
      expect(
        game.isComplete,
        isFalse,
        reason:
            '(1,2) n\'est plus adjacent à la tête : le doigt a quitté la route '
            'et ne la raccroche pas de l\'autre côté du mur',
      );
    });

    testWidgets('le glissement ne démarre que sur la tête du tracé', (
      tester,
    ) async {
      final game = await pumpGame(tester);
      game.dragThrough(const [(0, 0), (0, 1)]);
      expect(game.stepCount, 1);

      // Doigt posé ailleurs qu'à la tête : rien ne bouge. Un geste de travers
      // ne doit pas réécrire une route déjà posée.
      game.dragThrough(const [(2, 0), (2, 1), (2, 2)]);
      expect(game.stepCount, 1);
    });

    testWidgets('pas de boucle : repasser sur une case du tracé ne fait rien', (
      tester,
    ) async {
      final game = await pumpGame(tester);
      game.dragThrough(const [(0, 0), (1, 0), (2, 0), (2, 1)]);
      expect(game.stepCount, 3);

      // (2,1) → (2,0) est un retour arrière (avant-dernière) → -1 pas ;
      // puis (2,0) → (1,0) l'est de nouveau → -1.
      game.dragThrough(const [(2, 1), (2, 0), (1, 0)]);
      expect(game.stepCount, 1);
    });
  });

  group('gestes réels sur le plateau', () {
    testWidgets('un swipe du doigt trace la route', (tester) async {
      final game = await pumpGame(tester);
      final origin = tester.getTopLeft(find.byType(GameWidget<PlanifikGame>));

      // Un seul geste, en trois mouvements : LAB → droite → bas.
      final gesture = await tester.startGesture(origin + centerOf(0, 0));
      await tester.pump();
      await gesture.moveTo(origin + centerOf(0, 2));
      await tester.pump();
      await gesture.moveTo(origin + centerOf(2, 2));
      await tester.pump();
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        game.stepCount,
        4,
        reason:
            'le mouvement saute des cases entre deux frames : le tracé suit le '
            'SEGMENT, il ne se contente pas de son point d\'arrivée',
      );
      expect(game.isComplete, isTrue);
    });

    /// Le tracé se déclenchait au `onTapDown` de la station. Poser le doigt sur
    /// la tête du tracé pour la prolonger appliquait donc d'abord la règle
    /// « retoucher la dernière case = annuler » : chaque glissement commençait
    /// par effacer un pas. Le tracé n'avance plus qu'au relâché.
    testWidgets('l\'appui station par station marche toujours', (tester) async {
      final game = await pumpGame(tester);
      final origin = tester.getTopLeft(find.byType(GameWidget<PlanifikGame>));

      Future<void> tapCell(int row, int col) async {
        await tester.tapAt(origin + centerOf(row, col));
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tapCell(0, 1);
      await tapCell(0, 2);
      expect(game.stepCount, 2);

      // Retoucher la dernière case annule le pas — seule marche arrière offerte
      // à l'appui, il n'y a pas de bouton « Undo » à l'écran.
      await tapCell(0, 2);
      expect(game.stepCount, 1);
    });

    testWidgets('un swipe qui commence hors de la tête ne trace rien', (
      tester,
    ) async {
      final game = await pumpGame(tester);
      final origin = tester.getTopLeft(find.byType(GameWidget<PlanifikGame>));

      await tester.dragFrom(
        origin + centerOf(2, 0),
        centerOf(2, 2) - centerOf(2, 0),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(game.stepCount, 0);
    });
  });
}
