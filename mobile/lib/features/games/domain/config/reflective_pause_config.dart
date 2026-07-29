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

  static const Map<String, Set<ReflectivePauseResponseType>> recommended = {
    'PRESSURE_01': {ReflectivePauseResponseType.breatheAnalyze},
    'PRESSURE_02': {ReflectivePauseResponseType.askForMoreInformation},
    'PRESSURE_03': {
      ReflectivePauseResponseType.wait,
      ReflectivePauseResponseType.reformulateCalmly,
    },
    'PRESSURE_04': {ReflectivePauseResponseType.askForMoreInformation},
    'PRESSURE_05': {ReflectivePauseResponseType.breatheAnalyze},
    'PRESSURE_06': {ReflectivePauseResponseType.reformulateCalmly},
    'PRESSURE_07': {ReflectivePauseResponseType.wait},
    'PRESSURE_08': {ReflectivePauseResponseType.reformulateCalmly},
    'PRESSURE_09': {ReflectivePauseResponseType.breatheAnalyze},
    'PRESSURE_10': {ReflectivePauseResponseType.askForMoreInformation},
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
