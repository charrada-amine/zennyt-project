import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/error/api_exception.dart';
import '../domain/entities/decision_form.dart';
import '../domain/entities/device_calibration.dart';
import '../domain/entities/emotional_radar.dart';
import '../domain/entities/emotional_radar_v2.dart';
import '../domain/entities/game_session.dart';
import '../domain/entities/game_type.dart';
import '../domain/entities/game_metrics.dart';
import '../domain/entities/mini_game.dart';
import '../domain/repositories/games_repository.dart';
import '../domain/repositories/emotional_radar_v2_repository.dart';
import 'dtos/game_session_dto.dart';

/// [GamesRepository] adossé à Dio, parlant à l'API Games (`/api/v1/games`).
///
/// Tous les échecs Dio sont convertis en [ApiException] typées pour la couche
/// présentation, exactement comme les autres repositories de l'app.
class GamesRepositoryImpl
    implements GamesRepository, EmotionalRadarV2Repository {
  GamesRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<GameSession> startSession(GameType gameType) {
    return _guard(() async {
      final res = await _dio.post<Map<String, dynamic>>(
        '/games/sessions',
        data: {'gameType': gameType.wire},
      );
      return GameSessionDto.fromJson(res.data!).toEntity();
    });
  }

  @override
  Future<GameSession> submitResult({
    required String sessionId,
    required MiniGame miniGame,
    required GameMetrics metrics,
    DeviceCalibration? deviceCalibration,
  }) {
    return _guard(() async {
      final res = await _dio.post<Map<String, dynamic>>(
        '/games/sessions/$sessionId/results',
        data: {
          'miniGame': miniGame.wire,
          'metrics': metrics.toJson(),
          if (deviceCalibration != null)
            'deviceCalibration': deviceCalibration.toJson(),
        },
      );
      return GameSessionDto.fromJson(res.data!).toEntity();
    });
  }

  @override
  Future<DecisionForm> decisionItems(
    String sessionId, {
    String language = 'fr',
  }) {
    return _guard(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        '/games/sessions/$sessionId/decision/items',
        queryParameters: {'language': language},
      );
      return DecisionForm.fromJson(res.data!);
    });
  }

  @override
  Future<EmotionalRadarSceneSet> emotionalRadarScenes(String sessionId) {
    return _guard(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        '/games/sessions/$sessionId/emotional-radar/scenes',
      );
      final sceneSet = EmotionalRadarSceneSet.fromJson(res.data!);
      final hydratedScenes = await Future.wait(
        sceneSet.scenes.map(_hydratePublishedAsset),
      );
      return EmotionalRadarSceneSet(
        totalScenes: sceneSet.totalScenes,
        maxPoints: sceneSet.maxPoints,
        emotions: sceneSet.emotions,
        scenes: hydratedScenes,
      );
    });
  }

  Future<EmotionalRadarScene> _hydratePublishedAsset(
    EmotionalRadarScene scene,
  ) async {
    final url = scene.mediaUrl;
    if (url == null || !url.startsWith('/api/v1/games/assets/')) return scene;
    try {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) return scene;
      return scene.withMediaBytes(
        Uint8List.fromList(bytes),
        response.headers.value(Headers.contentTypeHeader),
      );
    } on DioException {
      // The nearby transcript/alt text keeps the scene playable offline.
      return scene;
    }
  }

  @override
  Future<EmotionalRadarFeedback> answerEmotionalRadarScene({
    required String sessionId,
    required String sceneId,
    required BasicEmotion emotion,
    required String nuanceKey,
    required int intensity,
  }) {
    return _guard(() async {
      final res = await _dio.post<Map<String, dynamic>>(
        '/games/sessions/$sessionId/emotional-radar/scenes/$sceneId/answers',
        data: {
          'selectedEmotion': emotion.wire,
          'selectedNuance': nuanceKey,
          'selectedIntensity': intensity,
        },
      );
      return EmotionalRadarFeedback.fromJson(res.data!);
    });
  }

  @override
  Future<EmotionalRadarV2State> emotionalRadarV2State(String sessionId) {
    return _guard(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        '/games/sessions/$sessionId/emotional-radar/v2/state',
      );
      return EmotionalRadarV2State.fromJson(res.data!);
    });
  }

  @override
  Future<EmotionalRadarV2State> activateNextEmotionalRadarV2Scene(
    String sessionId,
  ) {
    return _guard(() async {
      final res = await _dio.post<Map<String, dynamic>>(
        '/games/sessions/$sessionId/emotional-radar/v2/scenes/next',
      );
      return EmotionalRadarV2State.fromJson(res.data!);
    });
  }

  @override
  Future<EmotionalRadarV2AnswerResult> answerEmotionalRadarV2Scene({
    required String sessionId,
    required int sceneOrder,
    required String selectedEmotionKey,
    required EmotionalRadarV2Intensity selectedIntensity,
    required String explanation,
  }) {
    return _guard(() async {
      final res = await _dio.post<Map<String, dynamic>>(
        '/games/sessions/$sessionId/emotional-radar/v2/scenes/'
        '$sceneOrder/answers',
        data: {
          'selectedEmotionKey': selectedEmotionKey,
          'selectedIntensity': selectedIntensity.wire,
          'explanation': explanation,
        },
      );
      return EmotionalRadarV2AnswerResult.fromJson(res.data!);
    });
  }

  /// Runs [action], converting any [DioException] into a typed [ApiException].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
