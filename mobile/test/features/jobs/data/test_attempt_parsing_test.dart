import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/jobs/domain/entities/test_attempt.dart';

void main() {
  group('TestAttemptStarted.fromJson', () {
    test('keeps the presented (shuffled) order of questions and options', () {
      final attempt = TestAttemptStarted.fromJson({
        'attemptId': 'attempt-1',
        'jobOfferId': 'job-1',
        'timeLimitSeconds': 1200,
        'expiresAt': '2026-09-11T14:00:00Z',
        'questions': [
          {
            'id': 'q-1',
            'order': 1,
            'text': 'Which VCS is distributed?',
            'options': ['Docker', 'Git', 'Jenkins'],
          },
          {
            'id': 'q-2',
            'order': 2,
            'text': 'HTTP status for Not Found?',
            'options': ['404', '500'],
          },
        ],
      });

      expect(attempt.attemptId, 'attempt-1');
      expect(attempt.timeLimitSeconds, 1200);
      expect(attempt.expiresAt, DateTime.utc(2026, 9, 11, 14));
      expect(attempt.questions.length, 2);
      // The client must send back the index in THIS order, never the original.
      expect(attempt.questions.first.options, ['Docker', 'Git', 'Jenkins']);
      expect(attempt.questions.first.id, 'q-1');
    });
  });

  group('TestResult.fromJson', () {
    test('parses passing result with the fixed 70% threshold semantics', () {
      final result = TestResult.fromJson({
        'id': 'res-1',
        'jobOfferId': 'job-1',
        'hardSkillTestId': 'test-1',
        'candidateId': 'cand-1',
        'score': 8,
        'percentage': 80,
        'passed': true,
        'duration': 240,
        'status': 'COMPLETED',
        'completedAt': '2026-09-11T13:00:00Z',
      });

      expect(result.percentage, 80);
      expect(result.passed, isTrue);
      expect(result.duration, 240);
      expect(result.status, TestResultStatus.completed);
    });

    test('maps TIMEOUT / ABANDONED statuses', () {
      final timeout = TestResult.fromJson({
        'id': 'r',
        'percentage': 0,
        'passed': false,
        'status': 'TIMEOUT',
      });
      final abandoned = TestResult.fromJson({
        'id': 'r2',
        'percentage': 0,
        'passed': false,
        'status': 'ABANDONED',
      });
      expect(timeout.status, TestResultStatus.timeout);
      expect(abandoned.status, TestResultStatus.abandoned);
    });
  });

  group('TestResultDetail.fromJson', () {
    test('parses the per-question answer breakdown', () {
      final detail = TestResultDetail.fromJson({
        'id': 'res-1',
        'candidate': {'id': 'cand-1', 'fullName': 'Anna Mary', 'avatarUrl': 'https://x/y.png'},
        'score': 1,
        'percentage': 50,
        'passed': false,
        'duration': 120,
        'status': 'COMPLETED',
        'answerBreakdown': [
          {
            'questionId': 'q-1',
            'questionText': 'Which VCS?',
            'selectedAnswer': 'Git',
            'correctAnswer': 'Git',
            'isCorrect': true,
          },
          {
            'questionId': 'q-2',
            'questionText': 'HTTP 404?',
            'selectedAnswer': '500',
            'correctAnswer': '404',
            'isCorrect': false,
          },
        ],
      });

      expect(detail.candidate.fullName, 'Anna Mary');
      expect(detail.answerBreakdown.length, 2);
      expect(detail.answerBreakdown.first.isCorrect, isTrue);
      expect(detail.answerBreakdown.last.correctAnswer, '404');
    });
  });

  group('TestAttemptAnswer', () {
    test('serializes questionId + presented option index only', () {
      const answer = TestAttemptAnswer(questionId: 'q-1', selectedOptionIndex: 2);
      expect(answer.toJson(), {'questionId': 'q-1', 'selectedOptionIndex': 2});
    });
  });
}
