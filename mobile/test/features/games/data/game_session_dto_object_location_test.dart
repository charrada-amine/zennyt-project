import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/dtos/game_session_dto.dart';
import 'package:zennyt/features/games/domain/entities/game_type.dart';
import 'package:zennyt/features/games/domain/entities/object_location_metrics.dart';

void main() {
  test('maps object-location indicators from the API response', () {
    final session = GameSessionDto.fromJson({
      'id': '00000000-0000-4000-8000-000000000004',
      'gameType': 'VISUOSPATIAL_MEMORY',
      'status': 'COMPLETED',
      'compositeRaw': 86,
      'compositeMax': 100,
      'normalized': 0.86,
      'attempts': const [],
      'startedAt': '2026-08-05T10:00:00Z',
      'objectLocationIndicators': {
        'protocolVersion': 'OBJECT_LOCATION_FINE_V1',
        'completionReason': 'MAX_LEVELS',
        'completed': true,
        'sessionValid': true,
        'technicalValid': true,
        'minimumLevelsValid': true,
        'progressionValid': true,
        'timingValid': true,
        'provisionalAccuracyScore': 86,
        'completedLevelCount': 6,
        'passedLevelCount': 5,
        'administeredObjectCount': 33,
        'exactPlacementCount': 28,
        'swapCount': 2,
        'localErrorCount': 1,
        'globalErrorCount': 1,
        'unplacedCount': 1,
        'exactAccuracyPercent': 84.85,
        'swapRatePercent': 6.06,
        'localErrorRatePercent': 3.03,
        'globalErrorRatePercent': 3.03,
        'averageDisplacementCells': 0.42,
        'span': 7,
        'loadSlope': -0.8,
        'averageFirstPlacementIntervalMs': 710.5,
        'repositionCount': 3,
        'backgroundEventCount': 0,
        'focusLossCount': 0,
        'orientationChangeCount': 0,
        'droppedFrameCount': 1,
        'timingDeviationCount': 0,
        'levels': [
          {
            'phase': 'TEST',
            'levelIndex': 1,
            'objectCount': 3,
            'completed': true,
            'timedOut': false,
            'passed': true,
            'exactCount': 3,
            'swapCount': 0,
            'localErrorCount': 0,
            'globalErrorCount': 0,
            'unplacedCount': 0,
            'exactAccuracyPercent': 100,
            'averageDisplacementCells': 0,
            'recallDurationMs': 2100,
            'actionCount': 3,
            'repositionCount': 0,
            'averageFirstPlacementIntervalMs': 700,
          },
        ],
        'validityIssues': const <String>[],
      },
    }).toEntity();

    expect(session.gameType, GameType.visuospatialMemory);
    final indicators = session.objectLocationIndicators!;
    expect(
      indicators.completionReason,
      ObjectLocationCompletionReason.maxLevels,
    );
    expect(indicators.sessionValid, isTrue);
    expect(indicators.provisionalAccuracyScore, 86);
    expect(indicators.levels, hasLength(1));
    expect(indicators.levels.single.phase, ObjectLocationPhase.test);
    expect(indicators.levels.single.averageFirstPlacementIntervalMs, 700);
  });
}
