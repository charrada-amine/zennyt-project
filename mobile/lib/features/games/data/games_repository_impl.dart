import 'package:dio/dio.dart';

import '../../../core/error/api_exception.dart';
import '../domain/entities/device_calibration.dart';
import '../domain/entities/game_session.dart';
import '../domain/entities/game_type.dart';
import '../domain/entities/game_metrics.dart';
import '../domain/entities/mini_game.dart';
import '../domain/repositories/games_repository.dart';
import 'dtos/game_session_dto.dart';

/// [GamesRepository] adossé à Dio, parlant à l'API Games (`/api/v1/games`).
///
/// Tous les échecs Dio sont convertis en [ApiException] typées pour la couche
/// présentation, exactement comme les autres repositories de l'app.
class GamesRepositoryImpl implements GamesRepository {
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

  /// Runs [action], converting any [DioException] into a typed [ApiException].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
