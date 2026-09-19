import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/core/theme/theme.dart';
import 'package:zennyt/features/wallet/domain/entities/wallet.dart';
import 'package:zennyt/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:zennyt/features/wallet/presentation/providers/wallet_providers.dart';
import 'package:zennyt/features/wallet/presentation/view/wallet_screen.dart';

class _FakeWalletRepository implements WalletRepository {
  _FakeWalletRepository({this.card});

  WalletCard? card;
  final saved = <Map<String, Object>>[];
  final withdrawals = <double>[];

  @override
  Future<Wallet> getMyWallet() async =>
      Wallet(balanceCents: 4250, currency: 'EUR', card: card);

  @override
  Future<List<WalletTransaction>> getMyTransactions() async => [
        WalletTransaction(
          id: 't1',
          amountCents: 2500,
          currency: 'EUR',
          kind: WalletTransactionKind.credit,
          label: 'Referral reward — Sarra joined Zennyt',
          createdAt: DateTime.now(),
        ),
      ];

  @override
  Future<WalletCard> saveCard({
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required String cvv,
    required String cardholderName,
  }) async {
    saved.add({
      'number': cardNumber,
      'month': expiryMonth,
      'year': expiryYear,
      'cvv': cvv,
      'name': cardholderName,
    });
    return card = WalletCard(
      last4: cardNumber.substring(cardNumber.length - 4),
      brand: 'VISA',
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      cardholderName: cardholderName,
    );
  }

  @override
  Future<Wallet> withdraw(double amount) async {
    withdrawals.add(amount);
    return Wallet(balanceCents: 4250 - (amount * 100).round(), currency: 'EUR', card: card);
  }
}

Future<_FakeWalletRepository> _pump(WidgetTester tester, {WalletCard? card, ThemeMode mode = ThemeMode.light}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repo = _FakeWalletRepository(card: card);
  await tester.pumpWidget(ProviderScope(
    overrides: [walletRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      home: const WalletScreen(),
    ),
  ));
  await tester.pumpAndSettle();
  return repo;
}

FilledButton _saveButton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byKey(const ValueKey('card-save')));

void main() {
  testWidgets('without a card, the wallet invites to add one', (tester) async {
    await _pump(tester);
    expect(find.byKey(const ValueKey('wallet-add-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('wallet-card')), findsNothing);
    expect(find.text('€42.50'), findsOneWidget);
  });

  testWidgets('card form formats input and only saves a valid card', (tester) async {
    final repo = await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('wallet-add-card')));
    await tester.pumpAndSettle();

    Finder field(String key) =>
        find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(EditableText));

    await tester.enterText(field('card-number-field'), '4242a4242424242');
    await tester.pump();
    // Digits only, grouped, and still incomplete → Save stays disabled.
    String typed(String key) =>
        tester.widget<EditableText>(field(key)).controller.text;
    expect(typed('card-number-field'), '4242 4242 4242 42');
    expect(_saveButton(tester).onPressed, isNull);

    await tester.enterText(field('card-number-field'), '4242424242424242');
    await tester.enterText(field('card-expiry-field'), '1230');
    await tester.enterText(field('card-cvc-field'), '12a3');
    await tester.enterText(field('card-name-field'), 'Yassine Trabelsi 2');
    await tester.pump();

    expect(typed('card-number-field'), '4242 4242 4242 4242');
    expect(typed('card-expiry-field'), '12/30');
    // The name filter drops digits, the CVC filter drops letters.
    expect(typed('card-cvc-field'), '123');
    expect(typed('card-name-field'), 'Yassine Trabelsi ');
    // The live preview mirrors what is typed.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('card-form-preview')),
        matching: find.text('YASSINE TRABELSI'),
      ),
      findsOneWidget,
    );
    expect(_saveButton(tester).onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('card-save')));
    await tester.pumpAndSettle();

    expect(repo.saved.single, {
      'number': '4242424242424242',
      'month': 12,
      'year': 2030,
      'cvv': '123',
      'name': 'Yassine Trabelsi',
    });
    // The saved card now shows as a card.
    expect(find.byKey(const ValueKey('wallet-card')), findsOneWidget);
    expect(find.text('•••• •••• •••• 4242'), findsOneWidget);
  });

  testWidgets('an invalid card number shows why once the field is left', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('wallet-add-card')));
    await tester.pumpAndSettle();

    Finder field(String key) =>
        find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(EditableText));
    await tester.enterText(field('card-number-field'), '4242424242424241');
    await tester.tap(field('card-expiry-field'));
    await tester.pump();

    expect(find.text('This card number is not valid'), findsOneWidget);
    expect(_saveButton(tester).onPressed, isNull);
  });

  testWidgets('withdraw never exceeds the balance', (tester) async {
    final repo = await _pump(
      tester,
      card: const WalletCard(
        last4: '4242',
        brand: 'VISA',
        expiryMonth: 12,
        expiryYear: 2030,
        cardholderName: 'Yassine Trabelsi',
      ),
    );
    await tester.tap(find.byKey(const ValueKey('wallet-withdraw')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('withdraw-amount')), '100');
    await tester.pump();
    expect(find.text('You only have €42.50'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(const ValueKey('withdraw-confirm'))).onPressed,
      isNull,
    );

    await tester.tap(find.text('Max'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('withdraw-confirm')));
    await tester.pumpAndSettle();
    expect(repo.withdrawals, [42.5]);
  });

  testWidgets('renders in dark mode without errors', (tester) async {
    await _pump(
      tester,
      mode: ThemeMode.dark,
      card: const WalletCard(
        last4: '0005',
        brand: 'AMEX',
        expiryMonth: 4,
        expiryYear: 2029,
        cardholderName: 'Sarra Ben Ali',
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('•••• •••••• •0005'), findsOneWidget);
  });
}
