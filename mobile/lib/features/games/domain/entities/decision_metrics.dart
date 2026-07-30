import 'game_metrics.dart';

/// Dimension cognitive de « Je Décide » (fiche « JE DÉCIDE »). Aligné sur
/// DecisionDimension du contrat games.openapi.yaml.
enum DecisionDimension {
  ii('II'),
  er('ER'),
  dt('DT'),
  cs('CS'),
  re('RE');

  final String wire;
  const DecisionDimension(this.wire);

  static DecisionDimension fromWire(String value) =>
      DecisionDimension.values.firstWhere((d) => d.wire == value);
}

/// Mode de passation. Aligné sur AdministrationMode du contrat.
enum AdministrationMode {
  supervised('SUPERVISED'),
  unsupervised('UNSUPERVISED');

  final String wire;
  const AdministrationMode(this.wire);
}

/// Réponse mesurée à UN item « Je Décide ». Le client envoie l'option choisie
/// et le temps — jamais de qualité ni de points (décidés serveur/mock via le
/// catalogue). Miroir de DecisionItemResponse (backend).
class DecisionItemResponse {
  const DecisionItemResponse({
    required this.itemId,
    required this.dimension,
    required this.responseTimeMs,
    this.selectedOptionId,
    this.answered = true,
    this.decisionChangesCount = 0,
  });

  final String itemId;
  final DecisionDimension dimension;
  final String? selectedOptionId;
  final int responseTimeMs;
  final bool answered;
  final int decisionChangesCount;

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'dimension': dimension.wire,
    if (selectedOptionId != null) 'selectedOptionId': selectedOptionId,
    'responseTimeMs': responseTimeMs,
    'answered': answered,
    'decisionChangesCount': decisionChangesCount,
  };
}

/// Mesures brutes de « Je Décide ». Miroir de DecisionMetrics (backend) et de
/// DecisionMetrics du contrat. Le client n'envoie jamais de points.
class DecisionMetrics extends GameMetrics {
  const DecisionMetrics({
    required this.items,
    this.sessionLanguage,
    this.administrationMode = AdministrationMode.supervised,
    this.age,
    this.educationLevel,
    this.fatigue,
    this.motivation,
  });

  final List<DecisionItemResponse> items;
  final String? sessionLanguage;
  final AdministrationMode administrationMode;
  final int? age;
  final String? educationLevel;
  final int? fatigue;
  final int? motivation;

  List<DecisionItemResponse> get answeredItems =>
      items.where((i) => i.answered).toList();

  @override
  Map<String, dynamic> toJson() => {
    'items': items.map((i) => i.toJson()).toList(),
    if (sessionLanguage != null) 'sessionLanguage': sessionLanguage,
    'administrationMode': administrationMode.wire,
    if (age != null) 'age': age,
    if (educationLevel != null) 'educationLevel': educationLevel,
    if (fatigue != null) 'fatigue': fatigue,
    if (motivation != null) 'motivation': motivation,
  };
}
