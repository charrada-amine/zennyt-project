import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/domain/config/game_presentation_timing.dart';
import 'package:zennyt/features/games/domain/entities/game_runtime_snapshot.dart';

void main() {
  test('legacy snapshots preserve all eight historical defaults', () {
    const timing = GamePresentationTiming(GameRuntimeSnapshot());
    expect(timing.memoryDigitVisibleMs, 900);
    expect(timing.memoryDigitGapMs, 1000);
    expect(timing.memoryManipulationStepMs, 750);
    expect(timing.memoryRetentionMs, 3000);
    expect(timing.puzzlePlaybackStepMs, 420);
    expect(timing.responseFeedbackMs, 650);
    expect(timing.reflectiveThinkingTimeMs, 3000);
    expect(timing.reflectiveTransitionMs, 700);
  });

  test('published settings override only their own session snapshot', () {
    final source = {
      'memoryDigitVisibleMs': 1500,
      'reflectiveThinkingTimeMs': 6000,
    };
    final timing = GamePresentationTiming(
      GameRuntimeSnapshot.fromJson({'settings': source}),
    );
    source['memoryDigitVisibleMs'] = 2000;
    expect(timing.memoryDigitVisibleMs, 1500);
    expect(timing.reflectiveThinkingTimeMs, 6000);
    expect(timing.memoryDigitGapMs, 1000);
  });

  test('defends bounds and the protected 3-second reflection minimum', () {
    const timing = GamePresentationTiming(
      GameRuntimeSnapshot(
        settings: {
          'reflectiveThinkingTimeMs': 1,
          'memoryRetentionMs': -1,
          'puzzlePlaybackStepMs': 999999,
        },
      ),
    );
    expect(timing.reflectiveThinkingTimeMs, 3000);
    expect(timing.memoryRetentionMs, 0);
    expect(timing.puzzlePlaybackStepMs, 2000);
  });

  test('malformed timing values fall back without throwing', () {
    for (final value in [
      null,
      '900',
      true,
      950.5,
      double.nan,
      double.infinity,
    ]) {
      final timing = GamePresentationTiming(
        GameRuntimeSnapshot(settings: {'memoryDigitVisibleMs': value}),
      );
      expect(timing.memoryDigitVisibleMs, 900);
    }
  });
}
