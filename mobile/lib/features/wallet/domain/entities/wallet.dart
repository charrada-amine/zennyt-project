import 'package:equatable/equatable.dart';

class WalletCard extends Equatable {
  final String last4;
  final String brand;
  final int expiryMonth;
  final int expiryYear;
  final String cardholderName;

  const WalletCard({
    required this.last4,
    required this.brand,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cardholderName,
  });

  String get masked => '•••• $last4';
  String get expiryDisplay =>
      '${expiryMonth.toString().padLeft(2, '0')}/${(expiryYear % 100).toString().padLeft(2, '0')}';

  factory WalletCard.fromJson(Map<String, dynamic> json) => WalletCard(
        last4: json['last4'] as String? ?? '',
        brand: json['brand'] as String? ?? 'UNKNOWN',
        expiryMonth: (json['expiryMonth'] as num?)?.toInt() ?? 1,
        expiryYear: (json['expiryYear'] as num?)?.toInt() ?? 0,
        cardholderName: json['cardholderName'] as String? ?? '',
      );

  @override
  List<Object?> get props => [last4, brand, expiryMonth, expiryYear, cardholderName];
}

class Wallet extends Equatable {
  final int balanceCents;
  final String currency;
  final WalletCard? card;

  const Wallet({required this.balanceCents, required this.currency, this.card});

  double get balance => balanceCents / 100;

  static String formatAmount(double amount, String currency) {
    final symbol = switch (currency) {
      'EUR' => '€',
      'USD' => '\$',
      'GBP' => '£',
      _ => '$currency ',
    };
    final value = amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    return '$symbol$value';
  }

  String get balanceDisplay => formatAmount(balance, currency);

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        balanceCents: (json['balanceCents'] as num?)?.toInt() ?? 0,
        currency: json['currency'] as String? ?? 'EUR',
        card: json['card'] != null
            ? WalletCard.fromJson(json['card'] as Map<String, dynamic>)
            : null,
      );

  @override
  List<Object?> get props => [balanceCents, currency, card];
}

enum WalletTransactionKind {
  credit('CREDIT'),
  debit('DEBIT'),
  withdrawal('WITHDRAWAL');

  final String value;
  const WalletTransactionKind(this.value);

  static WalletTransactionKind fromString(String? v) => WalletTransactionKind.values
      .firstWhere((e) => e.value == v, orElse: () => WalletTransactionKind.debit);
}

class WalletTransaction extends Equatable {
  final String id;
  final int amountCents;
  final String currency;
  final WalletTransactionKind kind;
  final String label;
  final DateTime? createdAt;

  const WalletTransaction({
    required this.id,
    required this.amountCents,
    required this.currency,
    required this.kind,
    required this.label,
    this.createdAt,
  });

  String get amountDisplay {
    final sign = amountCents >= 0 ? '+' : '−';
    return '$sign${Wallet.formatAmount((amountCents.abs()) / 100, currency)}';
  }

  factory WalletTransaction.fromJson(Map<String, dynamic> json) => WalletTransaction(
        id: json['id']?.toString() ?? '',
        amountCents: (json['amountCents'] as num?)?.toInt() ?? 0,
        currency: json['currency'] as String? ?? 'EUR',
        kind: WalletTransactionKind.fromString(json['kind'] as String?),
        label: json['label'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  @override
  List<Object?> get props => [id, amountCents, kind, label];
}
