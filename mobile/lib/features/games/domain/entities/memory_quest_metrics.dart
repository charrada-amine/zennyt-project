import 'game_metrics.dart';

/// Mesures brutes de « J'investigue » (mémoire de travail). Le client n'envoie
/// que des mesures ; le serveur (ou le mock) note chaque tâche 0–5 puis calcule
/// le composite /100. Aligné sur MemoryQuestMetrics du contrat games.openapi.yaml.
class MemoryQuestMetrics extends GameMetrics {
  const MemoryQuestMetrics({
    required this.observedDigits,
    required this.correctSameDigits,
    required this.correctReverseDigits,
    required this.highestSequenceLength,
    this.objectCount = 0,
    this.restoreCorrect = 0,
    this.manipulationCount = 0,
    this.distractionPlayed = false,
    this.afterDistractionObserved = 0,
    this.afterDistractionCorrect = 0,
    this.distractionQuestionCorrect = false,
  });

  final int observedDigits;
  final int correctSameDigits;
  final int correctReverseDigits;
  final int highestSequenceLength;
  final int objectCount;
  final int restoreCorrect;
  final int manipulationCount;
  final bool distractionPlayed;
  final int afterDistractionObserved;
  final int afterDistractionCorrect;
  final bool distractionQuestionCorrect;

  bool get missionBPlayed => objectCount > 0;
  double get sameAccuracy =>
      observedDigits == 0 ? 0 : correctSameDigits / observedDigits;
  double get reverseAccuracy =>
      observedDigits == 0 ? 0 : correctReverseDigits / observedDigits;
  double get restoreAccuracy =>
      objectCount == 0 ? 0 : restoreCorrect / objectCount;
  double get afterDistractionAccuracy => afterDistractionObserved == 0
      ? 0
      : afterDistractionCorrect / afterDistractionObserved;

  @override
  Map<String, dynamic> toJson() => {
    'observedDigits': observedDigits,
    'correctSameDigits': correctSameDigits,
    'correctReverseDigits': correctReverseDigits,
    'highestSequenceLength': highestSequenceLength,
    'objectCount': objectCount,
    'restoreCorrect': restoreCorrect,
    'manipulationCount': manipulationCount,
    'distractionPlayed': distractionPlayed,
    'afterDistractionObserved': afterDistractionObserved,
    'afterDistractionCorrect': afterDistractionCorrect,
    'distractionQuestionCorrect': distractionQuestionCorrect,
  };
}
