import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:zennyt/features/billing/domain/entities/billing.dart';
import 'package:zennyt/features/billing/domain/repositories/billing_repository.dart';

/// Passerelle vers les achats in-app (App Store / Google Play).
///
/// Le reçu est envoyé au backend (`POST /purchases/verify`) puis la transaction
/// est clôturée. Aucune donnée de carte ne transite par l'application : le
/// paiement est entièrement géré par le store.
class StoreIapService {
  StoreIapService(this._repository);

  final BillingRepository _repository;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _listening = false;

  Future<bool> isAvailable() => _iap.isAvailable();

  void start() {
    if (_listening) return;
    _listening = true;
    _subscription = _iap.purchaseStream.listen(_onPurchases, onError: (_) {});
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _listening = false;
  }

  Future<List<ProductDetails>> loadProducts(List<BillingPlan> plans) async {
    if (!await _iap.isAvailable()) return const [];
    final ids = plans.map((p) => p.productId).where((id) => id.isNotEmpty).toSet();
    if (ids.isEmpty) return const [];
    final response = await _iap.queryProductDetails(ids);
    return response.productDetails;
  }

  Future<void> purchase(BillingPlan plan, ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    if (plan.isConsumable) {
      await _iap.buyConsumable(purchaseParam: param, autoConsume: false);
    } else {
      await _iap.buyNonConsumable(purchaseParam: param);
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        try {
          await _repository.verifyPurchase(
            productId: purchase.productID,
            store: _storeName(),
            receipt: purchase.verificationData.serverVerificationData,
            transactionId: purchase.purchaseID ??
                purchase.verificationData.serverVerificationData,
          );
        } catch (_) {
          // Best-effort: the store already charged; keep the transaction
          // open so it can be retried on the next app launch.
        }
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  String _storeName() {
    if (kIsWeb) return 'GOOGLE';
    return defaultTargetPlatform == TargetPlatform.iOS ? 'APPLE' : 'GOOGLE';
  }
}
