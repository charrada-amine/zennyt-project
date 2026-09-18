import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/domain/entities/games_progress.dart';
import 'package:zennyt/features/games/domain/entities/mini_game.dart';

void main() {
  // 13 jeux jusqu'au 2026-09-18, 15 depuis BART et IST.
  test('le catalogue compte 15 jeux, Memory Quest deux fois', () {
    expect(CatalogGame.values, hasLength(15));
    expect(GamesProgress.empty.totalGames, 15);
    expect(GamesProgress.empty.coveragePercent, 0);
  });

  test('chaque mini-jeu fait progresser au moins un jeu du catalogue', () {
    final reached = <CatalogGame>{};
    for (final miniGame in MiniGame.values) {
      final games = CatalogGame.completedBy(miniGame, null);
      expect(games, isNotEmpty, reason: '$miniGame');
      reached.addAll(games);
    }
    expect(reached, CatalogGame.values.toSet());
  });

  test('la couverture suit la part de jeux terminés, comme le serveur', () {
    const two = GamesProgress(
      completed: {CatalogGame.moveFast, CatalogGame.decision},
    );
    expect(two.completedGames, 2);
    expect(two.coveragePercent, 13, reason: '2 / 15 = 13,3 %');
    expect(
      GamesProgress(completed: CatalogGame.values.toSet()).coveragePercent,
      100,
    );
  });

  test('lecture de la réponse serveur', () {
    final progress = GamesProgress.fromJson({
      'coveragePercent': 7,
      'completedGames': 1,
      'totalGames': 15,
      'games': [
        {'game': 'MOVE_FAST', 'completed': true},
        {'game': 'DECISION', 'completed': false},
        // Un jeu inconnu de cette version de l'app est ignoré.
        {'game': 'FUTURE_GAME', 'completed': true},
      ],
    });
    expect(progress.completed, {CatalogGame.moveFast});
    expect(progress.coveragePercent, 7);
  });
}
