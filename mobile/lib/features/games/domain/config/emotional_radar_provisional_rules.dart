import '../entities/emotional_radar.dart';

/// Couche **PROVISOIRE** d'« Emotional Radar » — miroir Dart de
/// `backend/.../domain/config/EmotionalRadarProvisionalRules.java`.
///
/// ⚠️ PARITÉ MOCK ⇄ BACKEND (AGENTS.md §7.7).
///
/// **Fourni par la maquette (ne pas écraser sans arbitrage)** : la liste complète
/// des nuances de `sadness`, ainsi que `fear → Anxiety` et
/// `joy → Excitement/Triumph`.
///
/// **Provisoire** : les nuances d'`anger`, `disgust` et `surprise` — absentes de
/// toutes les planches alors que les six familles sont sélectionnables dès
/// l'étape 1 — reprennent les sous-catégories usuelles du modèle d'Ekman.
/// Chacune est marquée [NuanceSource.provisional] et affichée comme telle.
const Map<BasicEmotion, List<EmotionalNuance>> emotionalRadarNuanceCatalog = {
  // Fournie intégralement par l'écran « 04 Emotion Selected ».
  BasicEmotion.sadness: [
    EmotionalNuance(key: 'DISAPPOINTMENT', label: 'Disappointment', source: NuanceSource.figma),
    EmotionalNuance(key: 'NOSTALGIA', label: 'Nostalgia', source: NuanceSource.figma),
    EmotionalNuance(key: 'EMPATHIC_PAIN', label: 'Empathic pain', source: NuanceSource.figma),
    EmotionalNuance(key: 'SYMPATHY', label: 'Sympathy', source: NuanceSource.figma),
    EmotionalNuance(key: 'GUILT', label: 'Guilt', source: NuanceSource.figma),
  ],
  // Seule « Anxiety » est attestée (carte de feedback scène 2).
  BasicEmotion.fear: [
    EmotionalNuance(key: 'ANXIETY', label: 'Anxiety', source: NuanceSource.figma),
    EmotionalNuance(key: 'APPREHENSION', label: 'Apprehension', source: NuanceSource.provisional),
    EmotionalNuance(key: 'NERVOUSNESS', label: 'Nervousness', source: NuanceSource.provisional),
    EmotionalNuance(key: 'DREAD', label: 'Dread', source: NuanceSource.provisional),
    EmotionalNuance(key: 'PANIC', label: 'Panic', source: NuanceSource.provisional),
  ],
  // « Excitement » et « Triumph » attestées sur les cartes de feedback.
  BasicEmotion.joy: [
    EmotionalNuance(key: 'EXCITEMENT', label: 'Excitement', source: NuanceSource.figma),
    EmotionalNuance(key: 'TRIUMPH', label: 'Triumph', source: NuanceSource.figma),
    EmotionalNuance(key: 'CONTENTMENT', label: 'Contentment', source: NuanceSource.provisional),
    EmotionalNuance(key: 'PRIDE', label: 'Pride', source: NuanceSource.provisional),
    EmotionalNuance(key: 'RELIEF', label: 'Relief', source: NuanceSource.provisional),
  ],
  // Aucune nuance sur les planches — tout est provisoire.
  BasicEmotion.anger: [
    EmotionalNuance(key: 'IRRITATION', label: 'Irritation', source: NuanceSource.provisional),
    EmotionalNuance(key: 'FRUSTRATION', label: 'Frustration', source: NuanceSource.provisional),
    EmotionalNuance(key: 'INDIGNATION', label: 'Indignation', source: NuanceSource.provisional),
    EmotionalNuance(key: 'RESENTMENT', label: 'Resentment', source: NuanceSource.provisional),
    EmotionalNuance(key: 'RAGE', label: 'Rage', source: NuanceSource.provisional),
  ],
  BasicEmotion.disgust: [
    EmotionalNuance(key: 'DISTASTE', label: 'Distaste', source: NuanceSource.provisional),
    EmotionalNuance(key: 'AVERSION', label: 'Aversion', source: NuanceSource.provisional),
    EmotionalNuance(key: 'REVULSION', label: 'Revulsion', source: NuanceSource.provisional),
    EmotionalNuance(key: 'CONTEMPT', label: 'Contempt', source: NuanceSource.provisional),
    EmotionalNuance(key: 'DISAPPROVAL', label: 'Disapproval', source: NuanceSource.provisional),
  ],
  BasicEmotion.surprise: [
    EmotionalNuance(key: 'ASTONISHMENT', label: 'Astonishment', source: NuanceSource.provisional),
    EmotionalNuance(key: 'AMAZEMENT', label: 'Amazement', source: NuanceSource.provisional),
    EmotionalNuance(key: 'STARTLE', label: 'Startle', source: NuanceSource.provisional),
    EmotionalNuance(key: 'CONFUSION', label: 'Confusion', source: NuanceSource.provisional),
    EmotionalNuance(key: 'CURIOSITY', label: 'Curiosity', source: NuanceSource.provisional),
  ],
};
