import 'continuous_attention_metrics.dart';
import 'game_score.dart';
import 'game_type.dart';
import 'mini_game.dart';
import 'reflective_pause_metrics.dart';
import 'score_breakdown.dart';

/// Résultat enregistré d'un mini-jeu au sein d'une session.
class GameAttempt {
  const GameAttempt({
    required this.miniGame,
    required this.score,
    required this.recordedAt,
  });

  final MiniGame miniGame;
  final GameScore score;
  final DateTime recordedAt;
}

/// Session de jeu — entité racine côté mobile (miroir de l'agrégat backend).
class GameSession {
  const GameSession({
    required this.id,
    required this.gameType,
    required this.status,
    required this.compositeRaw,
    required this.compositeMax,
    required this.normalized,
    required this.attempts,
    required this.startedAt,
    this.completedAt,
    this.scoreBreakdown = const [],
    this.reflectivePauseIndicators,
    this.continuousAttentionIndicators,
  });

  final String id;
  final GameType gameType;
  final String status; // IN_PROGRESS | COMPLETED | ABANDONED
  final int compositeRaw;
  final int compositeMax;
  final double normalized;
  final List<GameAttempt> attempts;
  final DateTime startedAt;
  final DateTime? completedAt;

  /// Détail ligne par ligne du calcul du score (panneau de résultats).
  final List<ScoreBreakdownLine> scoreBreakdown;

  /// Présent après une soumission Reflective Pause.
  final ReflectivePauseIndicators? reflectivePauseIndicators;

  /// Présent après une soumission « Je continue ».
  final ContinuousAttentionIndicators? continuousAttentionIndicators;

  bool get isCompleted => status == 'COMPLETED';

  /// Dernier résultat enregistré (null si aucun mini-jeu joué).
  GameAttempt? get lastAttempt => attempts.isEmpty ? null : attempts.last;
}
