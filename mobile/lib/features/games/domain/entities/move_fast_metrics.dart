import 'game_metrics.dart';

/// Règle active sur un essai « Je bouge ». Aligné sur l'enum MoveFastRule de
/// contracts/games.openapi.yaml.
enum MoveFastRule {
  orientation('ORIENTATION'),
  movement('MOVEMENT');

  final String wire;
  const MoveFastRule(this.wire);
}

/// Un essai « Je bouge » mesuré (essais d'échauffement compris, marqués
/// [practiceTrial]). Le backend exclut l'échauffement du scoring et des stats,
/// puis dérive les indicateurs de flexibilité — le client ne calcule rien.
class MoveFastResponse {
  const MoveFastResponse({
    required this.correct,
    required this.reactionTimeMs,
    required this.ruleActive,
    this.practiceTrial = false,
    this.isSwitchTrial = false,
    this.appliedOldRule = false,
  });

  final bool practiceTrial;
  final bool correct;
  final int reactionTimeMs;
  final MoveFastRule ruleActive;
  final bool isSwitchTrial;
  final bool appliedOldRule;

  Map<String, dynamic> toJson() => {
    'practiceTrial': practiceTrial,
    'correct': correct,
    'reactionTimeMs': reactionTimeMs,
    'ruleActive': ruleActive.wire,
    'isSwitchTrial': isSwitchTrial,
    'appliedOldRule': appliedOldRule,
  };
}

/// Raw metrics for « Je bouge / Move Fast ».
///
/// The backend excludes practice trials, replays the scored responses to
/// calculate the escalation score, and derives the cognitive-flexibility
/// indicators.
class MoveFastMetrics extends GameMetrics {
  const MoveFastMetrics({
    required this.practiceTrialExcludedCount,
    required this.responses,
  });

  final int practiceTrialExcludedCount;
  final List<MoveFastResponse> responses;

  /// Essais notés (échauffement exclu) — miroir de MoveFastMetrics.scoredResponses().
  List<MoveFastResponse> get scoredResponses =>
      responses.where((r) => !r.practiceTrial).toList();

  /// Séquence correct/incorrect des essais notés (pour rejouer le barème mock).
  List<bool> get correctResponses =>
      scoredResponses.map((r) => r.correct).toList();

  @override
  Map<String, dynamic> toJson() => {
    'practiceTrialExcludedCount': practiceTrialExcludedCount,
    'responses': responses.map((r) => r.toJson()).toList(),
  };
}
