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
