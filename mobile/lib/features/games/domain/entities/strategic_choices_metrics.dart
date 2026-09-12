import '../config/strategic_choices_content.dart';
import 'game_metrics.dart';
import 'strategic_choices_bank.dart';

/// Réponse brute à une situation de « Choix Stratégiques ».
///
/// Aucune cotation ne circule : le client dit quelle situation il a vue et
/// quelle stratégie il a retenue, le serveur note d'après son catalogue. C'est
/// ce qui empêche un client de s'attribuer les points de son choix.
class StrategicChoiceAnswerMetric {
  const StrategicChoiceAnswerMetric({
    required this.situationId,
    required this.selectedStrategy,
    required this.responseTimeMs,
    this.medium,
  });

  final String situationId;
  final StrategicChoiceStrategy selectedStrategy;

  /// Temps entre l'affichage de la situation et la validation.
  final int responseTimeMs;

  /// Support de présentation — facultatif, la banque ne décrit aujourd'hui que
  /// des mini-vidéos.
  final StrategicChoiceMedium? medium;

  Map<String, dynamic> toJson() => {
    'situationId': situationId,
    'selectedStrategy': selectedStrategy.wire,
    'responseTimeMs': responseTimeMs,
    if (medium != null) 'medium': medium!.wire,
  };
}

/// Partie complète de « Choix Stratégiques » envoyée au serveur.
class StrategicChoicesMetrics implements GameMetrics {
  const StrategicChoicesMetrics({required this.answers});

  final List<StrategicChoiceAnswerMetric> answers;

  @override
  Map<String, dynamic> toJson() => {
    'strategicChoiceAnswers': answers.map((a) => a.toJson()).toList(),
  };
}
