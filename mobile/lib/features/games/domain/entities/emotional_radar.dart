import 'dart:typed_data';

import 'game_metrics.dart';

/// Famille d'émotion de base — étape 1 d'« Emotional Radar ».
/// Miroir de `BasicEmotion` (backend) et du contrat OpenAPI.
enum BasicEmotion {
  joy('JOY', 'Joy'),
  sadness('SADNESS', 'Sadness'),
  anger('ANGER', 'Anger'),
  fear('FEAR', 'Fear'),
  disgust('DISGUST', 'Disgust'),
  surprise('SURPRISE', 'Surprise');

  const BasicEmotion(this.wire, this.label);

  final String wire;
  final String label;

  static BasicEmotion fromWire(String value) =>
      BasicEmotion.values.firstWhere((e) => e.wire == value);
}

/// Support d'une scène. Miroir de `SceneMediaType` (backend).
enum SceneMediaType {
  dialogue('DIALOGUE', 'Dialogue'),
  text('TEXT', 'Text'),
  image('IMAGE', 'Image'),
  video('VIDEO', 'Video');

  const SceneMediaType(this.wire, this.label);

  final String wire;
  final String label;

  static SceneMediaType fromWire(String value) =>
      SceneMediaType.values.firstWhere((t) => t.wire == value);

  bool get isMedia =>
      this == SceneMediaType.image || this == SceneMediaType.video;
}

/// Origine d'une nuance : maquette fournie, ou ajout provisoire à valider.
enum NuanceSource { figma, provisional }

/// Nuance sélectionnable pour une famille d'émotion.
class EmotionalNuance {
  const EmotionalNuance({
    required this.key,
    required this.label,
    required this.source,
  });

  final String key;
  final String label;
  final NuanceSource source;

  factory EmotionalNuance.fromJson(Map<String, dynamic> json) =>
      EmotionalNuance(
        key: json['key'] as String,
        label: json['label'] as String,
        source: (json['source'] as String? ?? 'PROVISIONAL') == 'FIGMA'
            ? NuanceSource.figma
            : NuanceSource.provisional,
      );
}

/// Une scène telle que reçue du backend.
///
/// ⚠️ Ne contient JAMAIS la réponse attendue : la correction est faite serveur.
/// Si un champ `expected*` apparaissait ici, le jeu deviendrait trichable.
class EmotionalRadarScene {
  const EmotionalRadarScene({
    required this.id,
    required this.sceneOrder,
    required this.mediaType,
    required this.promptText,
    required this.instructionText,
    this.mediaUrl,
    this.altText,
    this.transcript,
    this.mediaBytes,
    this.mediaMimeType,
  });

  final String id;
  final int sceneOrder;
  final SceneMediaType mediaType;
  final String promptText;
  final String instructionText;
  final String? mediaUrl;
  final String? altText;
  final String? transcript;
  final Uint8List? mediaBytes;
  final String? mediaMimeType;

  factory EmotionalRadarScene.fromJson(Map<String, dynamic> json) =>
      EmotionalRadarScene(
        id: json['id'] as String,
        sceneOrder: json['sceneOrder'] as int,
        mediaType: SceneMediaType.fromWire(json['mediaType'] as String),
        promptText: json['promptText'] as String,
        instructionText: json['instructionText'] as String,
        mediaUrl: json['mediaUrl'] as String?,
        altText: json['altText'] as String?,
        transcript: json['transcript'] as String?,
      );

  EmotionalRadarScene withMediaBytes(Uint8List bytes, String? mimeType) =>
      EmotionalRadarScene(
        id: id,
        sceneOrder: sceneOrder,
        mediaType: mediaType,
        promptText: promptText,
        instructionText: instructionText,
        mediaUrl: mediaUrl,
        altText: altText,
        transcript: transcript,
        mediaBytes: bytes,
        mediaMimeType: mimeType,
      );
}

/// Le matériel complet d'une session : scènes + taxonomie émotion → nuances.
class EmotionalRadarSceneSet {
  const EmotionalRadarSceneSet({
    required this.totalScenes,
    required this.maxPoints,
    required this.emotions,
    required this.scenes,
  });

  final int totalScenes;
  final int maxPoints;

  /// Nuances proposées par famille, dans l'ordre d'affichage des chips.
  final Map<BasicEmotion, List<EmotionalNuance>> emotions;
  final List<EmotionalRadarScene> scenes;

  factory EmotionalRadarSceneSet.fromJson(Map<String, dynamic> json) {
    final emotions = <BasicEmotion, List<EmotionalNuance>>{};
    for (final entry in (json['emotions'] as List<dynamic>)) {
      final map = entry as Map<String, dynamic>;
      emotions[BasicEmotion.fromWire(
        map['emotion'] as String,
      )] = (map['nuances'] as List<dynamic>)
          .map((n) => EmotionalNuance.fromJson(n as Map<String, dynamic>))
          .toList();
    }
    return EmotionalRadarSceneSet(
      totalScenes: json['totalScenes'] as int,
      maxPoints: json['maxPoints'] as int,
      emotions: emotions,
      scenes: (json['scenes'] as List<dynamic>)
          .map((s) => EmotionalRadarScene.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  List<EmotionalNuance> nuancesFor(BasicEmotion emotion) =>
      emotions[emotion] ?? const [];
}

/// Correction d'une scène, renvoyée par le serveur après validation.
///
/// C'est le seul moment où la réponse attendue est connue du client.
class EmotionalRadarFeedback {
  const EmotionalRadarFeedback({
    required this.correct,
    required this.expectedEmotion,
    required this.expectedNuance,
    required this.suggestedIntensity,
    required this.explanation,
    required this.emotionPoints,
    required this.nuancePoints,
    required this.intensityPoints,
    required this.scenePoints,
    required this.totalPoints,
    required this.answeredScenes,
  });

  final bool correct;
  final BasicEmotion expectedEmotion;
  final String expectedNuance;
  final int suggestedIntensity;
  final String explanation;
  final int emotionPoints;
  final int nuancePoints;
  final int intensityPoints;
  final int scenePoints;
  final int totalPoints;
  final int answeredScenes;

  factory EmotionalRadarFeedback.fromJson(Map<String, dynamic> json) =>
      EmotionalRadarFeedback(
        correct: json['correct'] as bool,
        expectedEmotion: BasicEmotion.fromWire(
          json['expectedEmotion'] as String,
        ),
        expectedNuance: json['expectedNuance'] as String,
        suggestedIntensity: json['suggestedIntensity'] as int,
        explanation: json['explanation'] as String,
        emotionPoints: json['emotionPoints'] as int,
        nuancePoints: json['nuancePoints'] as int,
        intensityPoints: json['intensityPoints'] as int,
        scenePoints: json['scenePoints'] as int,
        totalPoints: json['totalPoints'] as int,
        answeredScenes: json['answeredScenes'] as int,
      );
}

/// Mesures comportementales d'une scène — sans réponse ni points.
class EmotionalRadarSceneMetric {
  const EmotionalRadarSceneMetric({
    required this.sceneId,
    required this.responseTimeMs,
    this.helpOpened = false,
    this.fullscreenOpened = false,
    this.reducedMotion = false,
  });

  final String sceneId;
  final int responseTimeMs;
  final bool helpOpened;
  final bool fullscreenOpened;
  final bool reducedMotion;

  Map<String, dynamic> toJson() => {
    'sceneId': sceneId,
    'responseTimeMs': responseTimeMs,
    'helpOpened': helpOpened,
    'fullscreenOpened': fullscreenOpened,
    'reducedMotion': reducedMotion,
  };
}

/// Métriques finales d'« Emotional Radar ».
///
/// ⚠️ Volontairement dépourvues de réponses : le score est reconstruit serveur
/// depuis les réponses notées scène par scène (AGENTS.md §7.4).
class EmotionalRadarMetrics implements GameMetrics {
  const EmotionalRadarMetrics({required this.scenes});

  final List<EmotionalRadarSceneMetric> scenes;

  @override
  Map<String, dynamic> toJson() => {
    'emotionalRadarScenes': scenes.map((s) => s.toJson()).toList(),
  };
}
