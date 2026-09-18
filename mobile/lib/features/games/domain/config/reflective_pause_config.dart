import '../entities/reflective_pause_metrics.dart';

/// Barème « Reflective Pause » — miroir exact de ReflectivePauseConfig.java.
///
/// Le gameplay n'utilise que [minimumPauseMs]. Les réponses recommandées et le
/// calcul servent au mock hors-ligne ; avec le backend réel, le serveur reste
/// l'unique autorité du score.
class ReflectivePauseConfig {
  const ReflectivePauseConfig._();

  static const totalMoments = 10;
  static const minimumPauseMs = 3000;
  static const controlledReactionMax = 3;
  static const nonImpulsiveMax = 4;
  static const stepBackMax = 3;
  static const totalMax = 10;

  /// Réaction la mieux cotée de chaque situation — miroir exact du serveur.
  ///
  /// Engendrée depuis `reflective_pause_bank.json` : la banque cote chaque
  /// réponse de 0 à 3, la « recommandée » est celle qui porte la cotation
  /// maximale de sa fiche. Neuf situations ont deux réponses à égalité, toutes
  /// deux acceptées.
  static const Map<String, Set<ReflectivePauseResponseType>> recommended = {
    'TR-001': {
      ReflectivePauseResponseType.reformulateCalmly,
    },
    'TR-002': {
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-003': {
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-004': {
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-005': {
      ReflectivePauseResponseType.reformulateCalmly,
    },
    'TR-006': {
      ReflectivePauseResponseType.wait,
      ReflectivePauseResponseType.reformulateCalmly,
    },
    'TR-007': {
      ReflectivePauseResponseType.breatheAnalyze,
    },
    'TR-008': {
      ReflectivePauseResponseType.reformulateCalmly,
    },
    'TR-009': {
      ReflectivePauseResponseType.breatheAnalyze,
    },
    'TR-010': {
      ReflectivePauseResponseType.wait,
    },
    'TR-011': {
      ReflectivePauseResponseType.reformulateCalmly,
    },
    'TR-012': {
      ReflectivePauseResponseType.reformulateCalmly,
    },
    'TR-013': {
      ReflectivePauseResponseType.breatheAnalyze,
    },
    'TR-014': {
      ReflectivePauseResponseType.breatheAnalyze,
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-015': {
      ReflectivePauseResponseType.breatheAnalyze,
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-016': {
      ReflectivePauseResponseType.reformulateCalmly,
    },
    'TR-017': {
      ReflectivePauseResponseType.reformulateCalmly,
    },
    'TR-018': {
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-019': {
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-020': {
      ReflectivePauseResponseType.breatheAnalyze,
    },
    'TR-021': {
      ReflectivePauseResponseType.reformulateCalmly,
    },
    'TR-022': {
      ReflectivePauseResponseType.reformulateCalmly,
    },
    'TR-023': {
      ReflectivePauseResponseType.reformulateCalmly,
    },
    'TR-024': {
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-025': {
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-026': {
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-027': {
      ReflectivePauseResponseType.wait,
    },
    'TR-028': {
      ReflectivePauseResponseType.wait,
    },
    'TR-029': {
      ReflectivePauseResponseType.breatheAnalyze,
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-030': {
      ReflectivePauseResponseType.reformulateCalmly,
    },
    'TR-031': {
      ReflectivePauseResponseType.breatheAnalyze,
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-032': {
      ReflectivePauseResponseType.breatheAnalyze,
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-033': {
      ReflectivePauseResponseType.wait,
    },
    'TR-034': {
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-035': {
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-036': {
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-037': {
      ReflectivePauseResponseType.breatheAnalyze,
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-038': {
      ReflectivePauseResponseType.wait,
    },
    'TR-039': {
      ReflectivePauseResponseType.reformulateCalmly,
    },
    'TR-040': {
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-041': {
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-042': {
      ReflectivePauseResponseType.breatheAnalyze,
    },
    'TR-043': {
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-044': {
      ReflectivePauseResponseType.reformulateCalmly,
    },
    'TR-045': {
      ReflectivePauseResponseType.reformulateCalmly,
    },
    'TR-046': {
      ReflectivePauseResponseType.breatheAnalyze,
    },
    'TR-047': {
      ReflectivePauseResponseType.breatheAnalyze,
    },
    'TR-048': {
      ReflectivePauseResponseType.breatheAnalyze,
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-049': {
      ReflectivePauseResponseType.reformulateCalmly,
    },
    'TR-050': {
      ReflectivePauseResponseType.wait,
    },
    'TR-051': {
      ReflectivePauseResponseType.wait,
    },
    'TR-052': {
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-053': {
      ReflectivePauseResponseType.wait,
    },
    'TR-054': {
      ReflectivePauseResponseType.reformulateCalmly,
    },
    'TR-055': {
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-056': {
      ReflectivePauseResponseType.reformulateCalmly,
    },
    'TR-057': {
      ReflectivePauseResponseType.reformulateCalmly,
    },
    'TR-058': {
      ReflectivePauseResponseType.breatheAnalyze,
    },
    'TR-059': {
      ReflectivePauseResponseType.reformulateCalmly,
    },
    'TR-060': {
      ReflectivePauseResponseType.breatheAnalyze,
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-101': {
      ReflectivePauseResponseType.reformulateCalmly,
    },
    'TR-102': {
      ReflectivePauseResponseType.breatheAnalyze,
    },
    'TR-103': {
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-104': {
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-105': {
      ReflectivePauseResponseType.breatheAnalyze,
    },
    'TR-106': {
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-107': {
      ReflectivePauseResponseType.reformulateCalmly,
    },
    'TR-108': {
      ReflectivePauseResponseType.reformulateCalmly,
    },
    'TR-109': {
      ReflectivePauseResponseType.breatheAnalyze,
    },
    'TR-110': {
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-111': {
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-112': {
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-113': {
      ReflectivePauseResponseType.reformulateCalmly,
    },
    'TR-114': {
      ReflectivePauseResponseType.reformulateCalmly,
    },
    'TR-115': {
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-116': {
      ReflectivePauseResponseType.breatheAnalyze,
    },
    'TR-117': {
      ReflectivePauseResponseType.reformulateCalmly,
    },
    'TR-118': {
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-119': {
      ReflectivePauseResponseType.wait,
    },
    'TR-120': {
      ReflectivePauseResponseType.reformulateCalmly,
    },
    'TR-121': {
      ReflectivePauseResponseType.breatheAnalyze,
    },
    'TR-122': {
      ReflectivePauseResponseType.wait,
    },
    'TR-123': {
      ReflectivePauseResponseType.askForMoreInformation,
    },
    'TR-124': {
      ReflectivePauseResponseType.breatheAnalyze,
    },
  };

  static bool isRecommended(
    String momentId,
    ReflectivePauseResponseType response,
  ) => recommended[momentId]?.contains(response) ?? false;

  static bool isNonImpulsive(ReflectivePauseResponseType response) =>
      response != ReflectivePauseResponseType.respondImpulsively;

  static double criterionScore(int successes, int total, int maxPoints) {
    if (total <= 0) return 0;
    return _roundOneDecimal(successes * maxPoints / total);
  }

  static int totalScore(
    double controlled,
    double nonImpulsive,
    double stepBack,
  ) => (controlled + nonImpulsive + stepBack).round();

  static String interpret(int score) {
    if (score <= 4) return 'Strong impulsivity';
    if (score <= 7) return 'Good stress management';
    return 'Very good self-control';
  }

  static double _roundOneDecimal(double value) =>
      (value * 10).roundToDouble() / 10;
}
