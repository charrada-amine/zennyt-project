import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/jobs/domain/entities/public_assessment.dart';

void main() {
  group('PublicAssessment.fromJson', () {
    test('parses the public projection and exposes no answer key', () {
      final test = PublicAssessment.fromJson({
        'id': 'test-1',
        'title': 'Hard skills — Flutter',
        'questionCount': 2,
        'timeLimitSeconds': 1200,
        'questions': [
          {
            'id': 'q-1',
            'order': 1,
            'text': 'Which VCS is distributed?',
            'options': ['Docker', 'Git'],
          },
          {
            'id': 'q-2',
            'order': 2,
            'text': 'HTTP Not Found?',
            'options': ['404', '500'],
          },
        ],
      });

      expect(test.title, 'Hard skills — Flutter');
      expect(test.questionCount, 2);
      expect(test.questions.length, 2);
      expect(test.questions.first.options, ['Docker', 'Git']);
    });

    test('questionCount falls back to the questions length when absent', () {
      final test = PublicAssessment.fromJson({
        'id': 'test-2',
        'title': 'T',
        'questions': [
          {'id': 'q', 'order': 1, 'text': 'x', 'options': ['a']},
        ],
      });
      expect(test.questionCount, 1);
    });
  });
}
