import 'entities/decision_metrics.dart';

/// Qualité d'une option de réponse, avec son score /3 (échelle de la fiche 0..3).
/// Libellés mot pour mot de la fiche « JE DÉCIDE ». Miroir de OptionQuality (backend).
enum OptionQuality {
  optimal(3), // optimal / cohérent
  satisfactory(2), // satisfaisant / suboptimal
  partial(1), // partiel / incohérent
  deficient(0); // déficitaire / non pertinent

  final int points;
  const OptionQuality(this.points);
}

/// Format d'un item : détermine la règle de notation. Miroir de DecisionItemFormat.
enum DecisionItemFormat { standard, temporalDecision, coherencePair }

/// Entrée d'un item dans le catalogue : dimension, format et qualité par option.
class DecisionScenarioItem {
  const DecisionScenarioItem({
    required this.itemId,
    required this.dimension,
    required this.format,
    required this.optionQualities,
  });

  final String itemId;
  final DecisionDimension dimension;
  final DecisionItemFormat format;
  final Map<String, OptionQuality> optionQualities;

  OptionQuality qualityOf(String optionId) {
    final q = optionQualities[optionId];
    if (q == null) {
      throw ArgumentError('Option inconnue pour l\'item $itemId : $optionId');
    }
    return q;
  }
}

/// Port — catalogue des scénarios « Je Décide » (miroir de DecisionScenarioCatalog).
///
/// ⚠️ EN ATTENTE DU PSYCHOLOGUE — 30 scénarios + étiquetage des options. Aucun
/// contenu de scénario n'est inventé. Tant que le catalogue est vide,
/// `MiniGame.decisionCore` n'est pas jouable (parité backend).
abstract class DecisionScenarioCatalog {
  DecisionScenarioItem? item(String itemId);
  bool get isEmpty;
}

/// Implémentation vivante VIDE (miroir de EmptyDecisionScenarioCatalog).
class EmptyDecisionScenarioCatalog implements DecisionScenarioCatalog {
  const EmptyDecisionScenarioCatalog();

  @override
  DecisionScenarioItem? item(String itemId) => null;

  @override
  bool get isEmpty => true;
}
