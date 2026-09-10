import 'game_metrics.dart';

/// Type d'une tâche notée. Aligné sur MemoryTaskKind du contrat.
enum MemoryTaskKind {
  sameOrder('SAME_ORDER'),
  reverseOrder('REVERSE_ORDER'),
  restore('RESTORE'),
  afterDistraction('AFTER_DISTRACTION'),

  /// Tâche parasite elle-même (intrus / pièce manquante).
  ///
  /// Notée comme les autres, mais son délai de référence est le budget de la
  /// distraction, pas [MemoryQuestConfig.maxTaskTimeMs] — voir
  /// `isDistractionTimedOut`.
  distractionChallenge('DISTRACTION_CHALLENGE');

  final String wire;
  const MemoryTaskKind(this.wire);
}

/// Moitié de « J'investigue » réellement jouée.
///
/// Le jeu a été scindé en deux : l'empan de chiffres et la mémoire des images se
/// jouent séparément. Le mode voyage avec les mesures parce que le barème et la
/// validation en dépendent — une partie d'images n'observe aucun chiffre, et le
/// serveur refusait jusqu'ici toute soumission sans chiffre observé.
enum MemoryQuestMode {
  /// Chiffres seuls : empan direct, inverse, interférence.
  digits('DIGITS'),

  /// Images seules : mémorisation d'objets, interférence visuelle, restitution.
  images('IMAGES'),

  /// Les deux missions à la suite — mode historique.
  full('FULL');

  final String wire;
  const MemoryQuestMode(this.wire);

  bool get playsDigits => this != MemoryQuestMode.images;
  bool get playsImages => this != MemoryQuestMode.digits;
}

/// Résultat mesuré d'UNE tâche (une instance de niveau) — le timeout est décidé
/// serveur à partir de responseTimeMs + offset de calibrage.
class MemoryTaskResult {
  const MemoryTaskResult({
    required this.kind,
    required this.correct,
    required this.total,
    required this.responseTimeMs,
    this.level = 1,
  });

  final MemoryTaskKind kind;
  final int correct;
  final int total;
  final int responseTimeMs;

  /// Niveau qui a produit la tâche.
  ///
  /// Nécessaire au serveur pour appliquer le bon délai à une tâche PARASITE :
  /// son budget dépend du niveau, alors que les tâches de rappel partagent un
  /// seuil unique.
  final int level;

  double get accuracy => total == 0 ? 0 : correct / total;

  Map<String, dynamic> toJson() => {
    'kind': kind.wire,
    'correct': correct,
    'total': total,
    'responseTimeMs': responseTimeMs,
    'level': level,
  };
}

/// Mesures brutes de « J'investigue » (mémoire de travail). Le client n'envoie
/// que des mesures ; le serveur (ou le mock) note chaque tâche 0–5 puis calcule
/// le composite /100. Aligné sur MemoryQuestMetrics du contrat games.openapi.yaml.
class MemoryQuestMetrics extends GameMetrics {
  const MemoryQuestMetrics({
    this.mode = MemoryQuestMode.full,
    this.observedDigits = 0,
    this.correctSameDigits = 0,
    this.correctReverseDigits = 0,
    this.highestSequenceLength = 0,
    this.distractionChallengesPlayed = 0,
    this.distractionChallengesSolved = 0,
    this.distractionTimeouts = 0,
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

  /// Moitié du jeu réellement jouée (chiffres / images / les deux).
  final MemoryQuestMode mode;

  final int observedDigits;
  final int correctSameDigits;
  final int correctReverseDigits;
  final int highestSequenceLength;

  /// Tâches parasites présentées sur la partie.
  final int distractionChallengesPlayed;

  /// Tâches parasites résolues dans les temps.
  final int distractionChallengesSolved;

  /// Tâches parasites perdues par expiration du chronomètre.
  final int distractionTimeouts;

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

  /// Part des tâches parasites résolues dans les temps.
  double get distractionSolveRate => distractionChallengesPlayed == 0
      ? 0
      : distractionChallengesSolved / distractionChallengesPlayed;

  @override
  Map<String, dynamic> toJson() => {
    'mode': mode.wire,
    'distractionChallengesPlayed': distractionChallengesPlayed,
    'distractionChallengesSolved': distractionChallengesSolved,
    'distractionTimeouts': distractionTimeouts,
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
