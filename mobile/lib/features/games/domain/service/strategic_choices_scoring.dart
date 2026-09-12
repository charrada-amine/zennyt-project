import '../config/strategic_choices_content.dart';
import '../entities/strategic_choices_bank.dart';
import '../entities/strategic_choices_metrics.dart';

/// Barème « Choix Stratégiques » — miroir exact de
/// `StrategicChoicesConfig.java` et `StrategicChoicesScoringService.java`.
///
/// Le score vaut la somme des cotations retenues, sur `situations × 3`. Le
/// maximum est donc DYNAMIQUE : il suit le nombre de situations réellement
/// jouées, comme pour Emotional Radar.
///
/// Ce miroir sert au mode hors ligne. Avec le backend réel, le serveur reste
/// l'unique autorité : lui seul détient la cotation, le client n'envoie que la
/// situation vue et la stratégie retenue.
const int kStrategicMaxPointsPerSituation = 3;

/// Seuils sur l'indice CORRIGÉ du hasard, jamais sur le pourcentage brut.
const double kStrategicAdaptiveThresholdPercent = 25.0;
const double kStrategicHighlyAdaptiveThresholdPercent = 60.0;

/// Famille de coping au sens de Carver (1989/1997).
///
/// Carver **regroupe** ses échelles — centrées problème, centrées émotion,
/// dysfonctionnelles — il ne les ordonne jamais : chez Lazarus & Folkman
/// (1984), l'efficacité d'une stratégie dépend du contexte. Le profil décrit
/// donc une conduite là où le score la classe.
enum CopingFamily {
  problemFocused('PROBLEM_FOCUSED'),
  emotionFocused('EMOTION_FOCUSED'),
  dysfunctional('DYSFUNCTIONAL'),

  /// Correspondance non tranchée avec le Brief COPE.
  ///
  /// « Seek support » recouvre chez Carver DEUX échelles rangées dans deux
  /// familles différentes — soutien émotionnel et soutien instrumental ; et
  /// « Breathe / pause » relève plutôt de la modulation de la réponse chez
  /// Gross (1998) que d'une échelle du COPE. Les ranger d'office fausserait le
  /// profil.
  unresolved('UNRESOLVED');

  const CopingFamily(this.wire);

  final String wire;
}

CopingFamily strategicCopingFamily(StrategicChoiceStrategy strategy) =>
    switch (strategy) {
      StrategicChoiceStrategy.assertiveCommunication ||
      StrategicChoiceStrategy.directAction => CopingFamily.problemFocused,
      StrategicChoiceStrategy.cognitiveReappraisal ||
      StrategicChoiceStrategy.humor => CopingFamily.emotionFocused,
      StrategicChoiceStrategy.avoidFlee ||
      StrategicChoiceStrategy.ruminate => CopingFamily.dysfunctional,
      StrategicChoiceStrategy.seekSupport ||
      StrategicChoiceStrategy.breathePause => CopingFamily.unresolved,
    };

/// Indice corrigé du hasard, en pourcentage.
///
/// `(obtenu − hasard) / (maximum − hasard)`. Le score brut seul ne veut rien
/// dire : répondre au hasard rapporte déjà 38 % du maximum. Plancher à 0 —
/// « moins bien que le hasard » est du bruit, pas une performance négative.
double strategicChanceCorrectedPercent(
  int rawPoints,
  int maxPoints,
  double chanceBaseline,
) {
  final range = maxPoints - chanceBaseline;
  if (range <= 0) return 0;
  final value = (rawPoints - chanceBaseline) * 100.0 / range;
  return value < 0 ? 0 : value;
}

int strategicChoicesMaxPoints(int situations) =>
    situations * kStrategicMaxPointsPerSituation;

/// Interprétation, sur l'indice CORRIGÉ.
///
/// Seuils tirés de la distribution mesurée : le hasard vaut 0, une stratégie
/// constante 46 % en moyenne. Le palier haut est donc à 60 %, au-dessus de ce
/// qu'une stratégie constante rapporte.
String strategicChoicesInterpret(double chanceCorrectedPercent) {
  if (chanceCorrectedPercent >= kStrategicHighlyAdaptiveThresholdPercent) {
    return 'Highly adaptive strategies';
  }
  if (chanceCorrectedPercent >= kStrategicAdaptiveThresholdPercent) {
    return 'Adaptive strategies';
  }
  return 'Reactive strategies';
}

/// Retour pédagogique d'une partie, calculé depuis la banque.
class StrategicChoicesReport {
  const StrategicChoicesReport({
    required this.situationsPlayed,
    required this.rawPoints,
    required this.maxPoints,
    required this.optimalChoices,
    required this.counterProductiveChoices,
    required this.mostUsedStrategy,
    required this.distinctStrategiesUsed,
    required this.averageResponseTimeMs,
    required this.chanceBaseline,
    required this.chanceCorrectedPercent,
    required this.copingProfile,
    required this.situationsAwaitingReview,
    required this.level,
  });

  final int situationsPlayed;
  final int rawPoints;
  final int maxPoints;
  final int optimalChoices;
  final int counterProductiveChoices;
  final StrategicChoiceStrategy? mostUsedStrategy;

  /// Nombre de stratégies différentes mobilisées.
  ///
  /// Seul signal qui trahit une partie menée avec un unique libellé : aucun
  /// seuil de score ne peut le faire, « Assertive communication » valant 3
  /// dans 23 fiches sur 60.
  final int distinctStrategiesUsed;

  final int averageResponseTimeMs;

  /// Score qu'une réponse au hasard obtiendrait sur les situations tirées.
  final double chanceBaseline;

  /// Écart au hasard ramené sur 100 — 0 = pas mieux qu'au hasard.
  final double chanceCorrectedPercent;

  /// Répartition des réponses par famille de coping.
  final Map<CopingFamily, int> copingProfile;

  /// Part des réponses relevant de [family], en pourcentage.
  double sharePercent(CopingFamily family) => situationsPlayed <= 0
      ? 0
      : (copingProfile[family] ?? 0) * 100.0 / situationsPlayed;

  /// Fiches jouées dont le document demande une validation du psychologue.
  final List<String> situationsAwaitingReview;

  final String level;

  /// Le barème est reconstruit par inférence : il reste provisoire.
  bool get provisionalScoring => true;
}

StrategicChoicesReport strategicChoicesReport(
  StrategicChoicesMetrics metrics,
  StrategicChoicesBank bank,
) {
  var raw = 0;
  var optimal = 0;
  var counterProductive = 0;
  var chance = 0.0;
  final uses = <StrategicChoiceStrategy, int>{};
  final profile = <CopingFamily, int>{};
  final awaiting = <String>[];

  for (final answer in metrics.answers) {
    final situation = bank.byId(answer.situationId);
    final points = situation.byStrategy(answer.selectedStrategy).score;
    raw += points;
    if (points == situation.bestScore) optimal++;
    if (points == 0) counterProductive++;
    chance += situation.chanceBaseline;
    profile.update(
      strategicCopingFamily(answer.selectedStrategy),
      (n) => n + 1,
      ifAbsent: () => 1,
    );
    uses.update(answer.selectedStrategy, (n) => n + 1, ifAbsent: () => 1);
    if (situation.needsPsychologistValidation) awaiting.add(situation.id);
  }

  final max = strategicChoicesMaxPoints(metrics.answers.length);
  final corrected = strategicChanceCorrectedPercent(raw, max, chance);
  StrategicChoiceStrategy? mostUsed;
  var best = -1;
  // À égalité, l'ordre de l'énumération tranche : il faut un résultat
  // reproductible, et non celui que le parcours d'une table donne.
  for (final strategy in StrategicChoiceStrategy.values) {
    final count = uses[strategy] ?? 0;
    if (count > best) {
      best = count;
      mostUsed = count == 0 ? null : strategy;
    }
  }

  final totalMs = metrics.answers.fold<int>(0, (s, a) => s + a.responseTimeMs);
  return StrategicChoicesReport(
    situationsPlayed: metrics.answers.length,
    rawPoints: raw,
    maxPoints: max,
    optimalChoices: optimal,
    counterProductiveChoices: counterProductive,
    mostUsedStrategy: mostUsed,
    distinctStrategiesUsed: uses.length,
    averageResponseTimeMs: metrics.answers.isEmpty
        ? 0
        : (totalMs / metrics.answers.length).round(),
    chanceBaseline: chance,
    chanceCorrectedPercent: corrected,
    copingProfile: profile,
    situationsAwaitingReview: awaiting,
    level: strategicChoicesInterpret(corrected),
  );
}
