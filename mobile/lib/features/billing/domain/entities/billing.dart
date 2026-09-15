import 'package:equatable/equatable.dart';

/// Offre du catalogue (maquette 261/316). Les prix font foi dans les stores.
class BillingPlan extends Equatable {
  final String code;
  final String productId;
  final String name;
  final String description;
  final int priceCents;
  final String currency;
  final String period; // MONTHLY | NONE
  final bool popular;

  const BillingPlan({
    required this.code,
    required this.productId,
    required this.name,
    required this.description,
    required this.priceCents,
    required this.currency,
    required this.period,
    required this.popular,
  });

  bool get isSubscription => period == 'MONTHLY';
  bool get isConsumable => period == 'NONE';

  String get priceDisplay {
    final symbol = switch (currency) {
      'EUR' => '€',
      'USD' => '\$',
      'GBP' => '£',
      _ => '$currency ',
    };
    final value = priceCents % 100 == 0
        ? (priceCents ~/ 100).toString()
        : (priceCents / 100).toStringAsFixed(2);
    return '$symbol$value';
  }

  String get periodLabel => isSubscription ? '/month' : 'one-off';

  factory BillingPlan.fromJson(Map<String, dynamic> json) => BillingPlan(
        code: json['code'] as String? ?? '',
        productId: json['productId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        priceCents: (json['priceCents'] as num?)?.toInt() ?? 0,
        currency: json['currency'] as String? ?? 'EUR',
        period: json['period'] as String? ?? 'NONE',
        popular: json['popular'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [code, priceCents, period];
}

class Subscription extends Equatable {
  final String planCode;
  final String status;
  final String store;
  final DateTime? purchasedAt;
  final DateTime? expiresAt;
  final bool autoRenewing;

  const Subscription({
    required this.planCode,
    required this.status,
    required this.store,
    this.purchasedAt,
    this.expiresAt,
    this.autoRenewing = false,
  });

  bool get isActive => status == 'ACTIVE';

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        planCode: json['planCode'] as String? ?? '',
        status: json['status'] as String? ?? 'ACTIVE',
        store: json['store'] as String? ?? 'APPLE',
        purchasedAt: json['purchasedAt'] != null
            ? DateTime.tryParse(json['purchasedAt'] as String)
            : null,
        expiresAt: json['expiresAt'] != null
            ? DateTime.tryParse(json['expiresAt'] as String)
            : null,
        autoRenewing: json['autoRenewing'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [planCode, status, expiresAt];
}
