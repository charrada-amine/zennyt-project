import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/referral/domain/entities/referral.dart';

void main() {
  group('Referral.fromJson', () {
    test('parses an invited referral without an invitee account yet', () {
      final referral = Referral.fromJson({
        'id': 'r1',
        'inviteeEmail': 'friend@example.com',
        'inviteeName': null,
        'status': 'INVITED',
        'createdAt': '2026-09-11T12:00:00Z',
      });

      expect(referral.status, ReferralStatus.invited);
      expect(referral.displayName, 'friend@example.com');
      expect(referral.daysRemaining, isNull);
    });

    test('parses a hired referral with a probation countdown', () {
      final referral = Referral.fromJson({
        'id': 'r2',
        'inviteeEmail': 'friend@example.com',
        'inviteeName': 'Anna Mary',
        'status': 'HIRED',
        'daysRemaining': 60,
      });

      expect(referral.status, ReferralStatus.hired);
      expect(referral.displayName, 'Anna Mary');
      expect(referral.daysRemaining, 60);
    });

    test('unknown status falls back to invited', () {
      final referral = Referral.fromJson({'id': 'r3', 'inviteeEmail': 'x@y.z', 'status': 'WHATEVER'});
      expect(referral.status, ReferralStatus.invited);
    });
  });

  group('ReferralLink.fromJson', () {
    test('parses the configurable bonus', () {
      final link = ReferralLink.fromJson({
        'code': 'abc',
        'url': 'https://www.zennyt.com/invite/abc',
        'bonusAmount': 800,
        'bonusCurrency': 'USD',
      });

      expect(link.code, 'abc');
      expect(link.bonusAmount, 800);
      expect(link.bonusCurrency, 'USD');
    });
  });
}
