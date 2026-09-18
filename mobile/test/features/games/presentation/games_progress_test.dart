import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/presentation/games_progress_provider.dart';

void main() {
  group('GamesProgress.coverage', () {
    test('is 0 with no completed dimension', () {
      const progress = GamesProgress();
      expect(progress.coverage, 0);
      expect(progress.consentGiven, isFalse);
    });

    test('grows with each completed cognitive dimension', () {
      final progress = GamesProgress(
        completedDimensions: {'Cognitive Flexibility', 'Working Memory'},
      );
      expect(progress.coverage, closeTo(2 / kCognitiveDimensions.length, 0.0001));
    });

    test('caps at 100% when every dimension is done', () {
      final progress = GamesProgress(completedDimensions: kCognitiveDimensions.toSet());
      expect(progress.coverage, 1.0);
    });
  });
}
