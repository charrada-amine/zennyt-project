import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/billing/domain/entities/billing.dart';

void main() {
  group('BillingPlan', () {
    test('formats a monthly subscription price', () {
      final plan = BillingPlan.fromJson({
        'code': 'recruiter_pro_monthly',
        'productId': 'recruiter_pro_monthly',
        'name': 'Recruiter Pro',
        'description': 'x',
        'priceCents': 3900,
        'currency': 'EUR',
        'period': 'MONTHLY',
        'popular': false,
      });

      expect(plan.isSubscription, isTrue);
      expect(plan.priceDisplay, '€39');
      expect(plan.periodLabel, '/month');
    });

    test('formats a one-off price with decimals', () {
      final plan = BillingPlan.fromJson({
        'code': 'video_interview_single',
        'productId': 'video_interview_single',
        'name': 'Video-interview',
        'description': 'x',
        'priceCents': 999,
        'currency': 'EUR',
        'period': 'NONE',
        'popular': false,
      });

      expect(plan.isConsumable, isTrue);
      expect(plan.priceDisplay, '€9.99');
      expect(plan.periodLabel, 'one-off');
    });
  });

  group('Subscription', () {
    test('parses an active subscription', () {
      final sub = Subscription.fromJson({
        'planCode': 'recruiter_team_monthly',
        'status': 'ACTIVE',
        'store': 'APPLE',
        'expiresAt': '2026-10-11T12:00:00Z',
        'autoRenewing': true,
      });

      expect(sub.isActive, isTrue);
      expect(sub.store, 'APPLE');
      expect(sub.autoRenewing, isTrue);
    });
  });
}
