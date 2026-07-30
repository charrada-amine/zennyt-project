import '../../domain/entities/continuous_attention_metrics.dart';
import '../../domain/entities/game_score.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/game_type.dart';
import '../../domain/entities/mini_game.dart';
import '../../domain/entities/reflective_pause_metrics.dart';
import '../../domain/entities/score_breakdown.dart';

/// DTO de la couche data : parse la réponse GameSession du contrat
/// games.openapi.yaml et la mappe vers l'entité domaine. Séparé de l'entité
/// pour que le domaine ne dépende pas du format de l'API.
class GameSessionDto {
  const GameSessionDto({
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
  final String gameType;
  final String status;
  final int compositeRaw;
  final int compositeMax;
  final double normalized;
  final List<GameAttempt> attempts;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<ScoreBreakdownLine> scoreBreakdown;
  final ReflectivePauseIndicators? reflectivePauseIndicators;
  final ContinuousAttentionIndicators? continuousAttentionIndicators;

  factory GameSessionDto.fromJson(Map<String, dynamic> json) {
    return GameSessionDto(
      id: json['id'] as String,
      gameType: json['gameType'] as String,
      status: json['status'] as String,
      compositeRaw: (json['compositeRaw'] as num?)?.toInt() ?? 0,
      compositeMax: (json['compositeMax'] as num?)?.toInt() ?? 0,
      normalized: (json['normalized'] as num?)?.toDouble() ?? 0.0,
      attempts:
          (json['attempts'] as List<dynamic>?)
              ?.map((e) => _attemptFromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      scoreBreakdown:
          (json['scoreBreakdown'] as List<dynamic>?)
              ?.map(
                (e) => ScoreBreakdownLine.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      reflectivePauseIndicators: json['reflectivePauseIndicators'] == null
          ? null
          : ReflectivePauseIndicators.fromJson(
              json['reflectivePauseIndicators'] as Map<String, dynamic>,
            ),
      continuousAttentionIndicators:
          json['continuousAttentionIndicators'] == null
          ? null
          : ContinuousAttentionIndicators.fromJson(
              json['continuousAttentionIndicators'] as Map<String, dynamic>,
            ),
    );
  }

  GameSession toEntity() => GameSession(
    id: id,
    gameType: GameType.fromWire(gameType),
    status: status,
    compositeRaw: compositeRaw,
    compositeMax: compositeMax,
    normalized: normalized,
    attempts: attempts,
    startedAt: startedAt,
    completedAt: completedAt,
    scoreBreakdown: scoreBreakdown,
    reflectivePauseIndicators: reflectivePauseIndicators,
    continuousAttentionIndicators: continuousAttentionIndicators,
  );

  static GameAttempt _attemptFromJson(Map<String, dynamic> json) {
    final score = json['score'] as Map<String, dynamic>;
    return GameAttempt(
      miniGame: MiniGame.fromWire(json['miniGame'] as String),
      score: GameScore(
        rawPoints: (score['rawPoints'] as num).toInt(),
        maxPoints: (score['maxPoints'] as num).toInt(),
        normalized: (score['normalized'] as num).toDouble(),
        level: score['level'] as String,
      ),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
    );
  }
}
