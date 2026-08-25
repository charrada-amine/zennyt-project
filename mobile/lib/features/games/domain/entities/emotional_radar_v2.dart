/// API-facing domain models for Emotional Radar v2.
///
/// The correction key is intentionally absent from [EmotionalRadarV2Scene].
/// It is revealed only in [EmotionalRadarV2Feedback], after the backend has
/// accepted an immutable answer. Sensitive target metadata and server-only
/// decision metrics are deliberately absent from the player contract.
library;

enum EmotionalRadarV2Intensity {
  low(0, 'Faible'),
  moderate(1, 'Modérée'),
  intense(2, 'Intense');

  const EmotionalRadarV2Intensity(this.wire, this.label);

  final int wire;
  final String label;

  static EmotionalRadarV2Intensity fromWire(int value) =>
      EmotionalRadarV2Intensity.values.firstWhere(
        (intensity) => intensity.wire == value,
      );
}

class EmotionalRadarV2Choice {
  const EmotionalRadarV2Choice({
    required this.key,
    required this.labelFr,
    required this.labelEn,
  });

  final String key;
  final String labelFr;
  final String labelEn;

  factory EmotionalRadarV2Choice.fromJson(Map<String, dynamic> json) =>
      EmotionalRadarV2Choice(
        key: json['key'] as String,
        labelFr: json['labelFr'] as String,
        labelEn: json['labelEn'] as String,
      );
}

class EmotionalRadarV2Scene {
  const EmotionalRadarV2Scene({
    required this.sceneOrder,
    required this.level,
    required this.choicesCount,
    required this.choices,
    required this.mediaStatus,
    required this.maxResponseTimeMs,
    required this.remainingResponseTimeMs,
    required this.impulsiveThresholdMs,
    this.mediaUrl,
    this.contextualCaption,
  });

  final int sceneOrder;
  final int level;
  final int choicesCount;
  final List<EmotionalRadarV2Choice> choices;
  final String mediaStatus;
  final String? mediaUrl;
  final String? contextualCaption;
  final int maxResponseTimeMs;
  final int remainingResponseTimeMs;
  final int impulsiveThresholdMs;

  bool get usesVideoPlaceholder =>
      mediaStatus == 'PLACEHOLDER_PENDING' || mediaUrl == null;

  factory EmotionalRadarV2Scene.fromJson(Map<String, dynamic> json) {
    final choices = (json['choices'] as List<dynamic>? ?? const [])
        .map(
          (choice) =>
              EmotionalRadarV2Choice.fromJson(choice as Map<String, dynamic>),
        )
        .toList(growable: false);
    final declaredCount = (json['choicesCount'] as num).toInt();
    if (choices.length != declaredCount) {
      throw const FormatException(
        'Emotional Radar scene choices do not match choicesCount.',
      );
    }
    final maxResponseTimeMs = (json['maxResponseTimeMs'] as num).toInt();
    final remainingResponseTimeMs = (json['remainingResponseTimeMs'] as num)
        .toInt();
    if (maxResponseTimeMs <= 0 ||
        remainingResponseTimeMs < 0 ||
        remainingResponseTimeMs > maxResponseTimeMs) {
      throw const FormatException(
        'Emotional Radar scene remaining time is outside its response budget.',
      );
    }
    return EmotionalRadarV2Scene(
      sceneOrder: (json['sceneOrder'] as num).toInt(),
      level: (json['level'] as num).toInt(),
      choicesCount: declaredCount,
      choices: choices,
      mediaStatus: json['mediaStatus'] as String,
      mediaUrl: json['mediaUrl'] as String?,
      contextualCaption: json['contextualCaption'] as String?,
      maxResponseTimeMs: maxResponseTimeMs,
      remainingResponseTimeMs: remainingResponseTimeMs,
      impulsiveThresholdMs: (json['impulsiveThresholdMs'] as num).toInt(),
    );
  }
}

class EmotionalRadarV2Feedback {
  const EmotionalRadarV2Feedback({
    required this.sceneOrder,
    required this.correct,
    required this.timedOut,
    required this.responseTimeMs,
    required this.impulsive,
    required this.expectedEmotionKey,
    required this.expectedIntensity,
    required this.semanticErrorDistance,
  });

  final int sceneOrder;
  final bool correct;
  final bool timedOut;
  final int responseTimeMs;
  final bool impulsive;
  final String expectedEmotionKey;
  final EmotionalRadarV2Intensity expectedIntensity;
  final double semanticErrorDistance;

  factory EmotionalRadarV2Feedback.fromJson(Map<String, dynamic> json) =>
      EmotionalRadarV2Feedback(
        sceneOrder: (json['sceneOrder'] as num).toInt(),
        correct: json['correct'] as bool,
        timedOut: json['timedOut'] as bool,
        responseTimeMs: (json['responseTimeMs'] as num).toInt(),
        impulsive: json['impulsive'] as bool,
        expectedEmotionKey: json['expectedEmotionKey'] as String,
        expectedIntensity: EmotionalRadarV2Intensity.fromWire(
          (json['expectedIntensity'] as num).toInt(),
        ),
        semanticErrorDistance: (json['semanticErrorDistance'] as num)
            .toDouble(),
      );
}

class EmotionalRadarV2Report {
  const EmotionalRadarV2Report({
    required this.totalScenes,
    required this.startingLevel,
    required this.finalLevel,
    required this.levelTransitions,
    required this.correctEmotions,
    required this.emotionAccuracyPercent,
    required this.accuracyByLevel,
    required this.accuracyByChoiceCount,
    required this.accuracyBySemanticDistance,
    required this.semanticDistanceScoringAvailable,
    required this.semanticProximityErrorScore,
    required this.intensityMatchPercent,
    required this.intensityErrorDirection,
    required this.accuracyByStimulusIntensity,
    required this.stimulusTypePerformance,
    required this.stimulusTypeScoringAvailable,
    required this.justificationScoringAvailable,
    required this.averageResponseTimeMs,
    required this.impulsiveResponsesPercent,
    required this.radarEmotionScore,
    required this.emotionalLevel,
    this.justificationScore,
  });

  final int totalScenes;
  final int startingLevel;
  final int finalLevel;
  final List<String> levelTransitions;
  final int correctEmotions;
  final double emotionAccuracyPercent;
  final Map<int, double> accuracyByLevel;
  final Map<int, double> accuracyByChoiceCount;
  final Map<String, double> accuracyBySemanticDistance;
  final bool semanticDistanceScoringAvailable;
  final double semanticProximityErrorScore;
  final double intensityMatchPercent;
  final Map<String, int> intensityErrorDirection;
  final Map<String, double> accuracyByStimulusIntensity;
  final Map<String, double> stimulusTypePerformance;
  final bool stimulusTypeScoringAvailable;
  final double? justificationScore;
  final bool justificationScoringAvailable;
  final int averageResponseTimeMs;
  final double impulsiveResponsesPercent;
  final int radarEmotionScore;
  final String emotionalLevel;

  factory EmotionalRadarV2Report.fromJson(
    Map<String, dynamic> json,
  ) => EmotionalRadarV2Report(
    totalScenes: (json['totalScenes'] as num).toInt(),
    startingLevel: (json['startingLevel'] as num).toInt(),
    finalLevel: (json['finalLevel'] as num).toInt(),
    levelTransitions: (json['levelTransitions'] as List<dynamic>? ?? const [])
        .cast<String>(),
    correctEmotions: (json['correctEmotions'] as num).toInt(),
    emotionAccuracyPercent: (json['emotionAccuracyPercent'] as num).toDouble(),
    accuracyByLevel: _intDoubleMap(json['accuracyByLevel']),
    accuracyByChoiceCount: _intDoubleMap(json['accuracyByChoiceCount']),
    accuracyBySemanticDistance: _stringDoubleMap(
      json['accuracyBySemanticDistance'],
    ),
    semanticDistanceScoringAvailable:
        json['semanticDistanceScoringAvailable'] as bool,
    semanticProximityErrorScore: (json['semanticProximityErrorScore'] as num)
        .toDouble(),
    intensityMatchPercent: (json['intensityMatchPercent'] as num).toDouble(),
    intensityErrorDirection: _stringIntMap(json['intensityErrorDirection']),
    accuracyByStimulusIntensity: _stringDoubleMap(
      json['accuracyByStimulusIntensity'],
    ),
    stimulusTypePerformance: _stringDoubleMap(json['stimulusTypePerformance']),
    stimulusTypeScoringAvailable: json['stimulusTypeScoringAvailable'] as bool,
    justificationScore: (json['justificationScore'] as num?)?.toDouble(),
    justificationScoringAvailable:
        json['justificationScoringAvailable'] as bool? ??
        json['justificationScore'] != null,
    averageResponseTimeMs: (json['averageResponseTimeMs'] as num).toInt(),
    impulsiveResponsesPercent: (json['impulsiveResponsesPercent'] as num)
        .toDouble(),
    radarEmotionScore: (json['radarEmotionScore'] as num).toInt(),
    emotionalLevel: json['emotionalLevel'] as String,
  );
}

class EmotionalRadarV2State {
  const EmotionalRadarV2State({
    required this.totalScenes,
    required this.answeredScenes,
    required this.startingLevel,
    required this.currentLevel,
    required this.completed,
    required this.mediaLibraryReady,
    required this.measurementAvailable,
    required this.scoringProvisional,
    required this.fitScorePublished,
    this.currentScene,
    this.report,
  });

  final int totalScenes;
  final int answeredScenes;
  final int startingLevel;
  final int currentLevel;
  final bool completed;
  final bool mediaLibraryReady;
  final bool measurementAvailable;
  final bool scoringProvisional;
  final bool fitScorePublished;
  final EmotionalRadarV2Scene? currentScene;
  final EmotionalRadarV2Report? report;

  factory EmotionalRadarV2State.fromJson(Map<String, dynamic> json) =>
      EmotionalRadarV2State(
        totalScenes: (json['totalScenes'] as num).toInt(),
        answeredScenes: (json['answeredScenes'] as num).toInt(),
        startingLevel: (json['startingLevel'] as num).toInt(),
        currentLevel: (json['currentLevel'] as num).toInt(),
        completed: json['completed'] as bool,
        mediaLibraryReady: json['mediaLibraryReady'] as bool,
        measurementAvailable: json['measurementAvailable'] as bool,
        scoringProvisional: json['scoringProvisional'] as bool,
        fitScorePublished: json['fitScorePublished'] as bool,
        currentScene: json['currentScene'] == null
            ? null
            : EmotionalRadarV2Scene.fromJson(
                json['currentScene'] as Map<String, dynamic>,
              ),
        report: json['report'] == null
            ? null
            : EmotionalRadarV2Report.fromJson(
                json['report'] as Map<String, dynamic>,
              ),
      );
}

class EmotionalRadarV2AnswerResult {
  const EmotionalRadarV2AnswerResult({
    required this.feedback,
    required this.state,
  });

  final EmotionalRadarV2Feedback feedback;
  final EmotionalRadarV2State state;

  factory EmotionalRadarV2AnswerResult.fromJson(Map<String, dynamic> json) =>
      EmotionalRadarV2AnswerResult(
        feedback: EmotionalRadarV2Feedback.fromJson(
          json['feedback'] as Map<String, dynamic>,
        ),
        state: EmotionalRadarV2State.fromJson(
          json['state'] as Map<String, dynamic>,
        ),
      );
}

Map<int, double> _intDoubleMap(dynamic value) =>
    (value as Map<String, dynamic>? ?? const {}).map(
      (key, item) => MapEntry(int.parse(key), (item as num).toDouble()),
    );

Map<String, double> _stringDoubleMap(dynamic value) =>
    (value as Map<String, dynamic>? ?? const {}).map(
      (key, item) => MapEntry(key, (item as num).toDouble()),
    );

Map<String, int> _stringIntMap(dynamic value) =>
    (value as Map<String, dynamic>? ?? const {}).map(
      (key, item) => MapEntry(key, (item as num).toInt()),
    );
