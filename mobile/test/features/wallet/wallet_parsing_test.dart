import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/wallet/domain/entities/wallet.dart';

void main() {
  group('Wallet', () {
    test('parses balance, currency and card', () {
      final wallet = Wallet.fromJson({
        'balanceCents': 35000,
        'currency': 'EUR',
        'card': {
          'last4': '1234',
          'brand': 'VISA',
          'expiryMonth': 12,
          'expiryYear': 2030,
          'cardholderName': 'Anna Mary',
        },
      });

      expect(wallet.balance, 350);
      expect(wallet.balanceDisplay, '€350');
      expect(wallet.card!.masked, '•••• 1234');
      expect(wallet.card!.expiryDisplay, '12/30');
    });

    test('handles a wallet without a card', () {
      final wallet = Wallet.fromJson({'balanceCents': 0, 'currency': 'EUR', 'card': null});
      expect(wallet.card, isNull);
      expect(wallet.balanceDisplay, '€0');
    });
  });

  group('WalletCard.expiryDisplay', () {
    test('missing expiry stays absent instead of becoming 01/00', () {
      final card = WalletCard.fromJson({});

      expect(card.expiryMonth, isNull);
      expect(card.expiryYear, isNull);
      expect(card.expiryDisplay, isNull);
    });

    test('explicit null expiry stays absent', () {
      final card = WalletCard.fromJson({
        'expiryMonth': null,
        'expiryYear': null,
      });

      expect(card.expiryMonth, isNull);
      expect(card.expiryYear, isNull);
      expect(card.expiryDisplay, isNull);
    });

    test('partial expiry does not fabricate a date', () {
      final monthOnly = WalletCard.fromJson({'expiryMonth': 12});
      final yearOnly = WalletCard.fromJson({'expiryYear': 2030});

      expect(monthOnly.expiryMonth, 12);
      expect(monthOnly.expiryYear, isNull);
      expect(monthOnly.expiryDisplay, isNull);
      expect(yearOnly.expiryMonth, isNull);
      expect(yearOnly.expiryYear, 2030);
      expect(yearOnly.expiryDisplay, isNull);
    });

    test('valid single-digit month keeps its leading zero', () {
      final card = WalletCard.fromJson({
        'expiryMonth': 1,
        'expiryYear': 2030,
      });

      expect(card.expiryDisplay, '01/30');
    });

    test('missing expiry is distinct from a supplied date', () {
      expect(WalletCard.fromJson({}), WalletCard.fromJson({
        'expiryMonth': null,
        'expiryYear': null,
      }));
      expect(WalletCard.fromJson({}), isNot(WalletCard.fromJson({
        'expiryMonth': 1,
        'expiryYear': 2030,
      })));
    });
  });

  group('WalletTransaction.amountDisplay', () {
    test('credits are positive and debits negative', () {
      WalletTransaction t(int cents) => WalletTransaction(
            id: 't',
            amountCents: cents,
            currency: 'EUR',
            kind: cents >= 0 ? WalletTransactionKind.credit : WalletTransactionKind.withdrawal,
            label: 'x',
          );

      expect(t(50000).amountDisplay, '+€500');
      expect(t(-15000).amountDisplay, '−€150');
    });
  });
}
