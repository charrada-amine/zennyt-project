import 'memory_quest_metrics.dart';
import 'mini_game.dart';

/// Les jeux du catalogue tels que le joueur les voit dans le hub — base de la
/// couverture (« Coverage n % »). Miroir de `CatalogGame` côté serveur.
///
/// Memory Quest est un seul mini-jeu serveur mais deux jeux pour le joueur
/// (chiffres et images). Tous les jeux comptent, y compris ceux encore fermés
/// dans l'application.
enum CatalogGame {
  moveFast('MOVE_FAST'),
  continuousAttention('CONTINUOUS_ATTENTION'),
  coordinationTracking('COORDINATION_TRACKING'),
  memoryQuestDigits('MEMORY_QUEST_DIGITS'),
  memoryQuestImages('MEMORY_QUEST_IMAGES'),
  objectLocation('OBJECT_LOCATION'),
  decision('DECISION'),
  optimalPath('OPTIMAL_PATH'),
  taskScheduling('TASK_SCHEDULING'),
  predictivePuzzle('PREDICTIVE_PUZZLE'),
  emotionalRadar('EMOTIONAL_RADAR'),
  reflectivePause('REFLECTIVE_PAUSE'),
  strategicChoices('STRATEGIC_CHOICES'),
  bart('BART'),
  informationSampling('INFORMATION_SAMPLING');

  const CatalogGame(this.wire);

  final String wire;

  static CatalogGame? fromWire(String wire) {
    for (final game in values) {
      if (game.wire == wire) return game;
    }
    return null;
  }

  /// Jeux terminés par un résultat enregistré de [miniGame] — même règle que
  /// le serveur. Pour Memory Quest, le mode joué dit lequel des deux jeux.
  static Set<CatalogGame> completedBy(MiniGame miniGame, Object? metrics) {
    return switch (miniGame) {
      MiniGame.moveFastCore => {moveFast},
      MiniGame.continuousAttentionCore => {continuousAttention},
      MiniGame.coordinationTrackingCore => {coordinationTracking},
      MiniGame.objectLocationBindingCore => {objectLocation},
      MiniGame.decisionCore => {decision},
      MiniGame.optimalPath => {optimalPath},
      MiniGame.taskScheduling => {taskScheduling},
      MiniGame.previsionPuzzle => {predictivePuzzle},
      MiniGame.emotionalRadarCore => {emotionalRadar},
      MiniGame.reflectivePauseCore => {reflectivePause},
      MiniGame.strategicChoicesCore => {strategicChoices},
      MiniGame.memoryQuestCore => _memoryQuest(metrics),
      MiniGame.bartCore => {bart},
      MiniGame.informationSamplingCore => {informationSampling},
    };
  }

  static Set<CatalogGame> _memoryQuest(Object? metrics) {
    final mode = metrics is MemoryQuestMetrics
        ? metrics.mode
        : MemoryQuestMode.full;
    return {
      if (mode.playsDigits) memoryQuestDigits,
      if (mode.playsImages) memoryQuestImages,
    };
  }
}

/// Progression du joueur dans le catalogue des jeux.
///
/// La couverture est la part des jeux du catalogue terminés au moins une fois
/// — combien du catalogue a été parcouru, pas à quel point il a été réussi.
class GamesProgress {
  const GamesProgress({required this.completed});

  /// Jeux terminés au moins une fois.
  final Set<CatalogGame> completed;

  static const GamesProgress empty = GamesProgress(completed: {});

  int get totalGames => CatalogGame.values.length;

  int get completedGames => completed.length;

  /// Couverture 0-100, arrondie à l'entier le plus proche (comme le serveur).
  int get coveragePercent => (completedGames * 100 / totalGames).round();

  factory GamesProgress.fromJson(Map<String, dynamic> json) {
    final games = (json['games'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return GamesProgress(
      completed: {
        for (final entry in games)
          if (entry['completed'] == true)
            ?CatalogGame.fromWire(entry['game'] as String),
      },
    );
  }
}
