import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/core/error/api_exception.dart';
import 'package:zennyt/features/games/data/games_repository_impl.dart';
import 'package:zennyt/features/games/domain/entities/emotional_radar_v2.dart';

void main() {
  test('GET parses the player-safe adaptive state', () async {
    final adapter = _RecordingAdapter(_stateBody);
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = GamesRepositoryImpl(dio);

    final state = await repository.emotionalRadarV2State('session-1');

    expect(
      adapter.lastOptions!.path,
      '/games/sessions/session-1/emotional-radar/v2/state',
    );
    expect(state.totalScenes, 15);
    expect(state.currentScene!.choices, hasLength(6));
    expect(state.currentScene!.usesVideoPlaceholder, isTrue);
    expect(state.currentScene!.contextualCaption, isNull);
    expect(state.currentScene!.remainingResponseTimeMs, 6250);
    expect(state.measurementAvailable, isFalse);
    expect(state.report, isNull);
  });

  test('POST sends observations only and parses server-owned result', () async {
    final adapter = _RecordingAdapter(_answerBody);
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = GamesRepositoryImpl(dio);

    final result = await repository.answerEmotionalRadarV2Scene(
      sessionId: 'session-1',
      sceneOrder: 1,
      selectedEmotionKey: 'JOY',
      selectedIntensity: EmotionalRadarV2Intensity.low,
      explanation: 'Visible facial cues.',
    );

    expect(
      adapter.lastOptions!.path,
      '/games/sessions/session-1/emotional-radar/v2/scenes/1/answers',
    );
    expect(adapter.lastOptions!.data, {
      'selectedEmotionKey': 'JOY',
      'selectedIntensity': 0,
      'explanation': 'Visible facial cues.',
    });
    expect(result.feedback.correct, isTrue);
    expect(result.feedback.responseTimeMs, 1250);
    expect(result.state.answeredScenes, 1);
    expect(result.state.currentScene, isNull);
  });

  test('POST next activates a scene through the dedicated route', () async {
    final adapter = _RecordingAdapter(_stateBody);
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = GamesRepositoryImpl(dio);

    final state = await repository.activateNextEmotionalRadarV2Scene(
      'session-1',
    );

    expect(
      adapter.lastOptions!.path,
      '/games/sessions/session-1/emotional-radar/v2/scenes/next',
    );
    expect(adapter.lastOptions!.method, 'POST');
    expect(adapter.lastOptions!.data, isNull);
    expect(state.currentScene!.sceneOrder, 1);
  });

  test('completed report parses all public player dimensions', () {
    final report = EmotionalRadarV2Report.fromJson({
      'totalScenes': 15,
      'startingLevel': 1,
      'finalLevel': 4,
      'levelTransitions': ['↑ 1→2'],
      'correctEmotions': 12,
      'emotionAccuracyPercent': 80,
      'accuracyByLevel': {'1': 100, '4': 75},
      'accuracyByChoiceCount': {'6': 90, '9': 70},
      'accuracyBySemanticDistance': <String, double>{},
      'semanticDistanceScoringAvailable': false,
      'semanticProximityErrorScore': 0,
      'intensityMatchPercent': 73.3,
      'intensityErrorDirection': {
        'Sous-estimée': 2,
        'Correcte': 11,
        'Sur-estimée': 2,
      },
      'accuracyByStimulusIntensity': {'Faible': 80, 'Intense': 70},
      'stimulusTypePerformance': <String, double>{},
      'stimulusTypeScoringAvailable': false,
      'justificationScore': null,
      'justificationScoringAvailable': false,
      'averageResponseTimeMs': 3200,
      'impulsiveResponsesPercent': 6.7,
      'radarEmotionScore': 8,
      'emotionalLevel': 'Élevé',
    });

    expect(report.radarEmotionScore, 8);
    expect(report.accuracyByLevel[4], 75);
    expect(report.justificationScoringAvailable, isFalse);
    expect(report.semanticDistanceScoringAvailable, isFalse);
    expect(report.stimulusTypeScoringAvailable, isFalse);
    expect(report.accuracyBySemanticDistance, isEmpty);
    expect(report.stimulusTypePerformance, isEmpty);
  });

  test('maps backend failures to typed ApiException', () async {
    final dio = Dio()
      ..httpClientAdapter = _RecordingAdapter(
        jsonEncode({'message': 'Session closed'}),
        statusCode: 409,
      );
    final repository = GamesRepositoryImpl(dio);

    expect(
      () => repository.emotionalRadarV2State('session-1'),
      throwsA(
        isA<ConflictException>().having(
          (error) => error.message,
          'message',
          'Session closed',
        ),
      ),
    );
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.body, {this.statusCode = 200});

  final String body;
  final int statusCode;
  RequestOptions? lastOptions;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

final _choices = List.generate(
  6,
  (index) => {
    'key': ['JOY', 'SADNESS', 'ANGER', 'FEAR', 'DISGUST', 'SURPRISE'][index],
    'labelFr': [
      'Joie',
      'Tristesse',
      'Colère',
      'Peur',
      'Dégoût',
      'Surprise',
    ][index],
    'labelEn': [
      'Joy',
      'Sadness',
      'Anger',
      'Fear',
      'Disgust',
      'Surprise',
    ][index],
  },
);

String get _stateBody => jsonEncode({
  'totalScenes': 15,
  'answeredScenes': 0,
  'startingLevel': 1,
  'currentLevel': 1,
  'completed': false,
  'mediaLibraryReady': false,
  'measurementAvailable': false,
  'scoringProvisional': true,
  'fitScorePublished': false,
  'currentScene': {
    'sceneOrder': 1,
    'level': 1,
    'choicesCount': 6,
    'choices': _choices,
    'mediaStatus': 'PLACEHOLDER_PENDING',
    'mediaUrl': null,
    'contextualCaption': null,
    'maxResponseTimeMs': 8000,
    'remainingResponseTimeMs': 6250,
    'impulsiveThresholdMs': 400,
  },
  'report': null,
});

String get _answerBody => jsonEncode({
  'feedback': {
    'sceneOrder': 1,
    'correct': true,
    'timedOut': false,
    'responseTimeMs': 1250,
    'impulsive': false,
    'expectedEmotionKey': 'JOY',
    'expectedIntensity': 0,
    'semanticErrorDistance': 0,
  },
  'state': jsonDecode(_stateBody)
    ..['answeredScenes'] = 1
    ..['currentScene'] = null,
});
