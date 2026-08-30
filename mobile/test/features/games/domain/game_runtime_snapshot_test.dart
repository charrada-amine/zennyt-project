import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/domain/entities/game_runtime_snapshot.dart';

void main() {
  test('parses and exposes snapshotted non-scoring controls', () {
    final accessibility = <String, dynamic>{'reducedMotion': true};
    final snapshot = GameRuntimeSnapshot.fromJson({
      'settingsVersion': 2,
      'modifiersVersion': 1,
      'settings': {'helpEnabled': false, 'accessibility': accessibility},
      'modifiers': {'answerFeedback': false, 'transitionDurationMs': 7500},
    });

    expect(snapshot.settingsVersion, 2);
    expect(snapshot.modifiersVersion, 1);
    expect(snapshot.settingBool('helpEnabled', fallback: true), isFalse);
    expect(snapshot.modifierBool('answerFeedback', fallback: true), isFalse);
    accessibility['reducedMotion'] = false;
    final frozenAccessibility =
        snapshot.settings['accessibility'] as Map<String, dynamic>;
    expect(frozenAccessibility['reducedMotion'], isTrue);
    expect(
      () => frozenAccessibility['reducedMotion'] = false,
      throwsUnsupportedError,
    );
    expect(
      snapshot.modifierInt(
        'transitionDurationMs',
        fallback: 900,
        minimum: 0,
        maximum: 5000,
      ),
      5000,
    );
  });
}
