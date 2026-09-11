import 'game_metrics.dart';
import 'reflective_pause_bank.dart';

/// Réponse brute choisie dans « Reflective Pause ».
enum ReflectivePauseResponseType {
  respondImpulsively('RESPOND_IMPULSIVELY'),
  breatheAnalyze('BREATHE_ANALYZE'),
  wait('WAIT'),
  askForMoreInformation('ASK_FOR_MORE_INFORMATION'),
  reformulateCalmly('REFORMULATE_CALMLY');

  const ReflectivePauseResponseType(this.wire);

  final String wire;
}

/// Mesures d'un moment de pression. Aucun score n'est envoyé.
class ReflectivePauseMomentMetric {
  const ReflectivePauseMomentMetric({
    required this.momentId,
    required this.selectedResponse,
    required this.responseTimeMs,
    required this.minimumTimerReached,
    this.medium,
  });

  final String momentId;
  final ReflectivePauseResponseType selectedResponse;
  final int responseTimeMs;
  final bool minimumTimerReached;

  /// Support par lequel la situation a été présentée — `VIDEO` ou `WRITTEN`.
  ///
  /// Le client l'exige au même titre que le choix et le délai : lire un message
  /// et regarder une scène ne demandent pas le même temps, et comparer deux
  /// délais suppose de savoir lequel des deux supports le joueur a eu.
  ///
  /// Facultatif au contrat : une session enregistrée avant l'intégration de la
  /// banque n'en a pas, et l'absence se lit alors comme « non renseigné »
  /// plutôt que comme un support par défaut qui fausserait la comparaison.
  final ReflectivePauseMedium? medium;

  Map<String, dynamic> toJson() => {
    'momentId': momentId,
    'selectedResponse': selectedResponse.wire,
    'responseTimeMs': responseTimeMs,
    'minimumTimerReached': minimumTimerReached,
    if (medium != null) 'medium': medium!.wire,
  };
}

/// Parcours complet de 10 moments envoyé au serveur.
class ReflectivePauseMetrics implements GameMetrics {
  const ReflectivePauseMetrics({required this.moments});

  final List<ReflectivePauseMomentMetric> moments;

  @override
  Map<String, dynamic> toJson() => {
    'reflectivePauseMoments': moments.map((m) => m.toJson()).toList(),
  };
}

/// Indicateurs calculés par le backend (ou le mock de parité).
class ReflectivePauseIndicators {
  const ReflectivePauseIndicators({
    required this.momentsPlayed,
    required this.controlledReactionTimeScore,
    required this.nonImpulsiveResponsesScore,
    required this.abilityToStepBackScore,
    required this.impulsiveChoiceCount,
    required this.averageResponseTimeMs,
    required this.level,
  });

  final int momentsPlayed;
  final double controlledReactionTimeScore;
  final double nonImpulsiveResponsesScore;
  final double abilityToStepBackScore;
  final int impulsiveChoiceCount;
  final int averageResponseTimeMs;
  final String level;

  factory ReflectivePauseIndicators.fromJson(Map<String, dynamic> json) {
    return ReflectivePauseIndicators(
      momentsPlayed: (json['momentsPlayed'] as num?)?.toInt() ?? 0,
      controlledReactionTimeScore:
          (json['controlledReactionTimeScore'] as num?)?.toDouble() ?? 0,
      nonImpulsiveResponsesScore:
          (json['nonImpulsiveResponsesScore'] as num?)?.toDouble() ?? 0,
      abilityToStepBackScore:
          (json['abilityToStepBackScore'] as num?)?.toDouble() ?? 0,
      impulsiveChoiceCount:
          (json['impulsiveChoiceCount'] as num?)?.toInt() ?? 0,
      averageResponseTimeMs:
          (json['averageResponseTimeMs'] as num?)?.toInt() ?? 0,
      level: (json['level'] as String?) ?? '',
    );
  }
}
