/// Miroir Dart du referentiel emotionnel v2 (backend `emotional_radar_emotions.json`)
/// + logique deterministe (distance, distracteurs, difficulte adaptative, score jeu).
///
/// PROVISOIRE : base Cowen & Keltner + complements ; coordonnees valence/arousal
/// placeholder. A garder aligne avec le backend (parite mock/offline, AGENTS.md 7.7).
library;

import 'dart:math' as math;

import 'emotional_radar_v2_config.dart';
import 'emotional_radar_v2_provisional_rules.dart';

enum EmotionCategory { positive, negative, prosocial, ambivalentCognitive }

enum StimulusType { facial, body, social, contextual }

class EmotionDefinition {
  const EmotionDefinition(
    this.key,
    this.labelFr,
    this.labelEn,
    this.category,
    this.stimulusType,
    this.valence,
    this.arousal,
  );
  final String key;
  final String labelFr;
  final String labelEn;
  final EmotionCategory category;
  final StimulusType stimulusType;
  final double valence;
  final double arousal;

  /// Editorial safety flag mirrored from backend `EmotionDefinition`.
  bool get sensitiveContentFlag => key == 'SEXUAL_DESIRE';
}

/// Les 45 emotions du referentiel (18 positives / 20 negatives / 3 prosociales /
/// 4 ambivalentes-cognitives).
const List<EmotionDefinition> kEmotionReferential = [
  EmotionDefinition(
    'JOY',
    'Joie',
    'Joy',
    EmotionCategory.positive,
    StimulusType.facial,
    0.9,
    0.7,
  ),
  EmotionDefinition(
    'AMUSEMENT',
    'Amusement',
    'Amusement',
    EmotionCategory.positive,
    StimulusType.facial,
    0.8,
    0.6,
  ),
  EmotionDefinition(
    'SATISFACTION',
    'Satisfaction',
    'Satisfaction',
    EmotionCategory.positive,
    StimulusType.facial,
    0.7,
    0.4,
  ),
  EmotionDefinition(
    'INTEREST',
    'Intérêt',
    'Interest',
    EmotionCategory.positive,
    StimulusType.facial,
    0.5,
    0.5,
  ),
  EmotionDefinition(
    'SURPRISE',
    'Surprise',
    'Surprise',
    EmotionCategory.ambivalentCognitive,
    StimulusType.facial,
    0.1,
    0.8,
  ),
  EmotionDefinition(
    'SADNESS',
    'Tristesse',
    'Sadness',
    EmotionCategory.negative,
    StimulusType.facial,
    -0.8,
    0.3,
  ),
  EmotionDefinition(
    'ANGER',
    'Colère',
    'Anger',
    EmotionCategory.negative,
    StimulusType.facial,
    -0.7,
    0.8,
  ),
  EmotionDefinition(
    'FEAR',
    'Peur',
    'Fear',
    EmotionCategory.negative,
    StimulusType.facial,
    -0.8,
    0.9,
  ),
  EmotionDefinition(
    'DISGUST',
    'Dégoût',
    'Disgust',
    EmotionCategory.negative,
    StimulusType.facial,
    -0.7,
    0.5,
  ),
  EmotionDefinition(
    'HORROR',
    'Horreur',
    'Horror',
    EmotionCategory.negative,
    StimulusType.facial,
    -0.9,
    0.9,
  ),
  EmotionDefinition(
    'CONTEMPT',
    'Mépris',
    'Contempt',
    EmotionCategory.negative,
    StimulusType.facial,
    -0.6,
    0.4,
  ),
  EmotionDefinition(
    'DISAPPOINTMENT',
    'Déception',
    'Disappointment',
    EmotionCategory.negative,
    StimulusType.facial,
    -0.6,
    0.3,
  ),
  EmotionDefinition(
    'PAIN',
    'Douleur',
    'Pain',
    EmotionCategory.negative,
    StimulusType.facial,
    -0.8,
    0.6,
  ),
  EmotionDefinition(
    'EXCITEMENT',
    'Excitation',
    'Excitement',
    EmotionCategory.positive,
    StimulusType.body,
    0.8,
    0.9,
  ),
  EmotionDefinition(
    'TRIUMPH',
    'Triomphe',
    'Triumph',
    EmotionCategory.positive,
    StimulusType.body,
    0.9,
    0.8,
  ),
  EmotionDefinition(
    'PRIDE',
    'Fierté',
    'Pride',
    EmotionCategory.positive,
    StimulusType.body,
    0.7,
    0.6,
  ),
  EmotionDefinition(
    'CALMNESS',
    'Calme',
    'Calmness',
    EmotionCategory.positive,
    StimulusType.body,
    0.5,
    0.1,
  ),
  EmotionDefinition(
    'ANXIETY',
    'Anxiété',
    'Anxiety',
    EmotionCategory.negative,
    StimulusType.body,
    -0.6,
    0.7,
  ),
  EmotionDefinition(
    'BOREDOM',
    'Ennui',
    'Boredom',
    EmotionCategory.negative,
    StimulusType.body,
    -0.4,
    0.2,
  ),
  EmotionDefinition(
    'FRUSTRATION',
    'Frustration',
    'Frustration',
    EmotionCategory.negative,
    StimulusType.body,
    -0.6,
    0.6,
  ),
  EmotionDefinition(
    'SHAME',
    'Honte',
    'Shame',
    EmotionCategory.negative,
    StimulusType.body,
    -0.7,
    0.4,
  ),
  EmotionDefinition(
    'REJECTION',
    'Rejet',
    'Rejection',
    EmotionCategory.negative,
    StimulusType.body,
    -0.7,
    0.5,
  ),
  EmotionDefinition(
    'HUMILIATION',
    'Humiliation',
    'Humiliation',
    EmotionCategory.negative,
    StimulusType.social,
    -0.8,
    0.6,
  ),
  EmotionDefinition(
    'AWKWARDNESS',
    'Malaise social',
    'Awkwardness',
    EmotionCategory.ambivalentCognitive,
    StimulusType.social,
    -0.3,
    0.5,
  ),
  EmotionDefinition(
    'ENVY',
    'Envie',
    'Envy',
    EmotionCategory.negative,
    StimulusType.social,
    -0.5,
    0.5,
  ),
  EmotionDefinition(
    'JEALOUSY',
    'Jalousie',
    'Jealousy',
    EmotionCategory.negative,
    StimulusType.social,
    -0.6,
    0.6,
  ),
  EmotionDefinition(
    'ADORATION',
    'Adoration',
    'Adoration',
    EmotionCategory.positive,
    StimulusType.social,
    0.8,
    0.5,
  ),
  EmotionDefinition(
    'ROMANCE',
    'Romance',
    'Romance',
    EmotionCategory.positive,
    StimulusType.social,
    0.8,
    0.5,
  ),
  EmotionDefinition(
    'GRATITUDE',
    'Gratitude',
    'Gratitude',
    EmotionCategory.prosocial,
    StimulusType.social,
    0.8,
    0.4,
  ),
  EmotionDefinition(
    'SYMPATHY',
    'Sympathie',
    'Sympathy',
    EmotionCategory.prosocial,
    StimulusType.social,
    0.4,
    0.3,
  ),
  EmotionDefinition(
    'COMPASSION',
    'Compassion',
    'Compassion',
    EmotionCategory.prosocial,
    StimulusType.social,
    0.4,
    0.4,
  ),
  EmotionDefinition(
    'EMPATHIC_PAIN',
    'Douleur empathique',
    'Empathic pain',
    EmotionCategory.negative,
    StimulusType.social,
    -0.6,
    0.5,
  ),
  EmotionDefinition(
    'ADMIRATION',
    'Admiration',
    'Admiration',
    EmotionCategory.positive,
    StimulusType.social,
    0.7,
    0.5,
  ),
  EmotionDefinition(
    'GUILT',
    'Culpabilité',
    'Guilt',
    EmotionCategory.negative,
    StimulusType.contextual,
    -0.7,
    0.4,
  ),
  EmotionDefinition(
    'REGRET',
    'Regret',
    'Regret',
    EmotionCategory.negative,
    StimulusType.contextual,
    -0.6,
    0.3,
  ),
  EmotionDefinition(
    'LONELINESS',
    'Solitude',
    'Loneliness',
    EmotionCategory.negative,
    StimulusType.contextual,
    -0.7,
    0.3,
  ),
  EmotionDefinition(
    'NOSTALGIA',
    'Nostalgie',
    'Nostalgia',
    EmotionCategory.ambivalentCognitive,
    StimulusType.contextual,
    0.1,
    0.3,
  ),
  EmotionDefinition(
    'DOUBT',
    'Doute',
    'Doubt',
    EmotionCategory.ambivalentCognitive,
    StimulusType.contextual,
    -0.3,
    0.4,
  ),
  EmotionDefinition(
    'RELIEF',
    'Soulagement',
    'Relief',
    EmotionCategory.positive,
    StimulusType.contextual,
    0.6,
    0.3,
  ),
  EmotionDefinition(
    'AESTHETIC_APPRECIATION',
    'Appréciation esthétique',
    'Aesthetic appreciation',
    EmotionCategory.positive,
    StimulusType.contextual,
    0.7,
    0.4,
  ),
  EmotionDefinition(
    'AWE',
    'Émerveillement',
    'Awe',
    EmotionCategory.positive,
    StimulusType.contextual,
    0.6,
    0.6,
  ),
  EmotionDefinition(
    'ENTRANCEMENT',
    'Fascination',
    'Entrancement',
    EmotionCategory.positive,
    StimulusType.contextual,
    0.6,
    0.5,
  ),
  EmotionDefinition(
    'CRAVING',
    'Désir (craving)',
    'Craving',
    EmotionCategory.positive,
    StimulusType.contextual,
    0.5,
    0.6,
  ),
  EmotionDefinition(
    'HOPE',
    'Espoir',
    'Hope',
    EmotionCategory.positive,
    StimulusType.contextual,
    0.6,
    0.4,
  ),
  EmotionDefinition(
    'SEXUAL_DESIRE',
    'Désir sexuel',
    'Sexual desire',
    EmotionCategory.positive,
    StimulusType.contextual,
    0.6,
    0.7,
  ),
];

EmotionDefinition? emotionByKey(String key) {
  for (final e in kEmotionReferential) {
    if (e.key == key) return e;
  }
  return null;
}

/// Distance semantique PROVISOIRE : euclidienne valence/arousal, normalisee [0,1].
double semanticDistance(EmotionDefinition a, EmotionDefinition b) {
  final dv = a.valence - b.valence;
  final da = a.arousal - b.arousal;
  return math.sqrt(dv * dv + da * da) / math.sqrt(5.0);
}

/// Choix d'une scene : bonne reponse + distracteurs, melanges (deterministe/seed).
/// Mirroir de DistractorSelectionService.buildChoices.
List<EmotionDefinition> buildChoices(
  EmotionDefinition correct,
  DifficultyLevel level,
  int seed,
) {
  final target = level.targetDistance.target;
  final candidates =
      kEmotionReferential.where((e) => e.key != correct.key).toList()..sort(
        (x, y) => (semanticDistance(correct, x) - target).abs().compareTo(
          (semanticDistance(correct, y) - target).abs(),
        ),
      );
  final wanted = math.min(level.choicesCount - 1, candidates.length);
  final choices = candidates.sublist(0, wanted)..add(correct);
  choices.shuffle(math.Random(seed));
  return List.unmodifiable(choices);
}

/// Difficulte de scene = distance moyenne des distracteurs a la bonne reponse.
double sceneDifficulty(
  EmotionDefinition correct,
  List<EmotionDefinition> choices,
) {
  final others = choices.where((e) => e.key != correct.key).toList();
  if (others.isEmpty) return 1.0;
  final sum = others.fold<double>(
    0,
    (s, e) => s + semanticDistance(correct, e),
  );
  return sum / others.length;
}

/// Difficulte adaptative : >70%% monte, <40%% descend, fenetre glissante 3-4.
/// Mirroir de AdaptiveDifficultyService.nextLevel.
int nextLevel(int currentLevel, List<bool> recentOutcomes) {
  if (recentOutcomes.length < EmotionalRadarV2Config.evaluationWindowMin) {
    return currentLevel;
  }
  final window = math.min(
    recentOutcomes.length,
    EmotionalRadarV2Config.evaluationWindowMax,
  );
  final slice = recentOutcomes.sublist(recentOutcomes.length - window);
  final acc = slice.where((b) => b).length / slice.length;
  if (acc >= EmotionalRadarV2Config.levelUpThreshold &&
      currentLevel < EmotionalRadarV2Config.difficultyLevels) {
    return currentLevel + 1;
  }
  if (acc <= EmotionalRadarV2Config.levelDownThreshold && currentLevel > 1) {
    return currentLevel - 1;
  }
  return currentLevel;
}

/// Score « jeu » /10 (mirroir de RadarGameScoreService.score). PROVISOIRE.
int radarEmotionScore(int correctCount, int totalScenes, int finalLevel) {
  if (totalScenes <= 0) {
    throw ArgumentError.value(
      totalScenes,
      'totalScenes',
      'aucune scène notée : score impossible',
    );
  }
  final levelComponent = finalLevel / EmotionalRadarV2Config.difficultyLevels;
  final accuracyComponent = correctCount / totalScenes;
  final raw10 =
      (levelComponent * EmotionalRadarV2ProvisionalRules.gameScoreLevelWeight +
          accuracyComponent *
              EmotionalRadarV2ProvisionalRules.gameScoreAccuracyWeight) *
      10.0;
  return raw10.clamp(0.0, 10.0).round();
}
