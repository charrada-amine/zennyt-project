import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/jobs/domain/entities/hired_candidate.dart';

void main() {
  group('HiredCandidate.fromJson', () {
    test('parses a confirmed hire inside probation (cancellable)', () {
      final hire = HiredCandidate.fromJson({
        'id': 'h1',
        'candidateId': 'c1',
        'fullName': 'Anna Mary',
        'avatarUrl': null,
        'title': 'UX/UI Designer',
        'status': 'CONFIRMED',
        'hiredAt': '2026-08-01T10:00:00Z',
        'probationEndsAt': '2026-10-30T10:00:00Z',
        'daysRemaining': 60,
        'cancellable': true,
      });

      expect(hire.displayName, 'Anna Mary');
      expect(hire.isCancelled, isFalse);
      expect(hire.cancellable, isTrue);
      expect(hire.daysRemaining, 60);
    });

    test('a cancelled hire is not cancellable', () {
      final hire = HiredCandidate.fromJson({
        'id': 'h2',
        'candidateId': 'c2',
        'title': 'Designer',
        'status': 'CANCELLED',
        'cancellable': false,
      });

      expect(hire.isCancelled, isTrue);
      expect(hire.cancellable, isFalse);
      expect(hire.displayName, 'Candidate');
    });
  });
}
