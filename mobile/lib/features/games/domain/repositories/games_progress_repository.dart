import '../entities/games_progress.dart';

/// Progression du joueur dans le catalogue des jeux (« Coverage » du hub).
///
/// Séparée de [GamesRepository], comme `EmotionalRadarV2Repository` : les
/// doubles de test existants des jeux n'ont pas à implémenter un endpoint
/// qu'ils n'appellent jamais.
abstract interface class GamesProgressRepository {
  /// `GET /games/progress` — jeux du catalogue terminés par le joueur connecté.
  Future<GamesProgress> gamesProgress();
}
