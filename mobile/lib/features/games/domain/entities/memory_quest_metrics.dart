import 'game_metrics.dart';

/// Type d'une tâche notée. Aligné sur MemoryTaskKind du contrat.
enum MemoryTaskKind {
  sameOrder('SAME_ORDER'),
  reverseOrder('REVERSE_ORDER'),
  restore('RESTORE'),
  afterDistraction('AFTER_DISTRACTION');

  final String wire;
  const MemoryTaskKind(this.wire);
}

/// Résultat mesuré d'UNE tâche (une instance de niveau) — le timeout est décidé
/// serveur à partir de responseTimeMs + offset de calibrage.
class MemoryTaskResult {
  const MemoryTaskResult({
    required this.kind,
    required this.correct,
    required this.total,
    required this.responseTimeMs,
  });

  final MemoryTaskKind kind;
  final int correct;
  final int total;
  final int responseTimeMs;

  double get accuracy => total == 0 ? 0 : correct / total;

  Map<String, dynamic> toJson() => {
    'kind': kind.wire,
    'correct': correct,
    'total': total,
    'responseTimeMs': responseTimeMs,
  };
}

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
    this.finalLevel = 1,
    this.sessionCompleted = true,
    this.tasks = const [],
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
  final int finalLevel;
  final bool sessionCompleted;
  final List<MemoryTaskResult> tasks;

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
    'finalLevel': finalLevel,
    'sessionCompleted': sessionCompleted,
    'tasks': tasks.map((t) => t.toJson()).toList(),
  };
}
