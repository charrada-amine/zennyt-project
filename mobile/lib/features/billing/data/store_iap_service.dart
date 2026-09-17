import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:zennyt/features/billing/domain/entities/billing.dart';
import 'package:zennyt/features/billing/domain/repositories/billing_repository.dart';

/// Passerelle vers les achats in-app (App Store / Google Play).
///
/// Le reçu est envoyé au backend (`POST /purchases/verify`) ; la transaction
/// store n'est clôturée qu'après une vérification réussie. Un achat dont la
/// vérification échoue reste en attente (le store re-notifie au prochain
/// lancement) et le paywall ne débloque pas l'appel. Aucune donnée de carte ne
/// transite par l'application : le paiement est entièrement géré par le store.
class StoreIapService {
  StoreIapService(this._repository, {InAppPurchase? iap})
      : _iap = iap ?? InAppPurchase.instance;

  final BillingRepository _repository;
  final InAppPurchase _iap;
  final Map<String, Completer<PurchaseOutcome>> _outcomes = {};
  StreamSubscription<void>? _subscription;
  final Set<String> _finishedTransactions = {};
  bool _listening = false;
  bool _disposed = false;

  Future<bool> isAvailable() => _iap.isAvailable();

  void start() {
    if (_listening) return;
    _listening = true;
    _subscription = _iap.purchaseStream.asyncMap(_onPurchases).listen(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        for (final completer in _outcomes.values) {
          if (!completer.isCompleted) completer.completeError(error, stackTrace);
        }
        _outcomes.clear();
      },
      cancelOnError: false,
    );
  }

  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _subscription = null;
    _listening = false;
    for (final completer in _outcomes.values) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('Purchase flow disposed.'));
      }
    }
    _outcomes.clear();
  }

  Future<List<ProductDetails>> loadProducts(List<BillingPlan> plans) async {
    if (!await _iap.isAvailable()) return const [];
    final ids = plans.map((p) => p.productId).where((id) => id.isNotEmpty).toSet();
    if (ids.isEmpty) return const [];
    final response = await _iap.queryProductDetails(ids);
    return response.productDetails;
  }

  Future<PurchaseOutcome> purchase(BillingPlan plan, ProductDetails product) {
    if (_disposed) return Future.error(StateError('Purchase flow disposed.'));
    start();
    final param = PurchaseParam(productDetails: product);
    final key = product.id;
    final existing = _outcomes[key];
    if (existing != null && !existing.isCompleted) return existing.future;
    final completer = Completer<PurchaseOutcome>();
    _outcomes[key] = completer;
    Future<void>(() async {
      if (_disposed || completer.isCompleted) return;
      try {
        final initiated = plan.isConsumable
            ? await _iap.buyConsumable(purchaseParam: param, autoConsume: false)
            : await _iap.buyNonConsumable(purchaseParam: param);
        if (!initiated) {
          throw StateError('Store rejected the purchase request.');
        }
      } catch (error) {
        _outcomes.remove(key);
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      }
    });
    return completer.future;
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
          await _verifyAndSettle(purchase, restored: false);
          break;
        case PurchaseStatus.restored:
          await _verifyAndSettle(purchase, restored: true);
          break;
        case PurchaseStatus.canceled:
          _settle(purchase.productID, PurchaseOutcome.canceled);
          if (purchase.pendingCompletePurchase) {
            try {
              await _iap.completePurchase(purchase);
            } catch (_) {}
          }
          break;
        case PurchaseStatus.error:
          _settle(purchase.productID, PurchaseOutcome.failed);
          if (purchase.pendingCompletePurchase) {
            try {
              await _iap.completePurchase(purchase);
            } catch (_) {}
          }
          break;
        case PurchaseStatus.pending:
          break;
      }
    }
  }

  Future<void> _verifyAndSettle(
    PurchaseDetails purchase, {
    required bool restored,
  }) async {
    if (_disposed) return;
    final transactionKey = '${purchase.productID}:${purchase.purchaseID ?? purchase.verificationData.serverVerificationData}';
    if (_finishedTransactions.contains(transactionKey)) return;
    final completer = _outcomes[purchase.productID];
    try {
      await _repository.verifyPurchase(
        productId: purchase.productID,
        store: _storeName(),
        receipt: purchase.verificationData.serverVerificationData,
        transactionId:
            purchase.purchaseID ?? purchase.verificationData.serverVerificationData,
      );
    } catch (error) {
      if (identical(_outcomes[purchase.productID], completer)) {
        _outcomes.remove(purchase.productID);
      }
      if (restored) {
        if (completer != null && !completer.isCompleted) {
          completer.completeError(const RestoredPurchaseNotUnlockedException());
        }
        return;
      }
      if (completer != null && !completer.isCompleted) {
        completer.completeError(error);
      }
      return;
    }
    if (_disposed) return;
    if (purchase.pendingCompletePurchase) {
      try {
        await _iap.completePurchase(purchase);
      } catch (error) {
        if (identical(_outcomes[purchase.productID], completer)) {
          _outcomes.remove(purchase.productID);
        }
        if (completer != null && !completer.isCompleted) {
          completer.completeError(error);
        }
        return;
      }
    }
    _finishedTransactions.add(transactionKey);
    if (identical(_outcomes[purchase.productID], completer)) {
      _outcomes.remove(purchase.productID);
    }
    if (completer != null && !completer.isCompleted) {
      completer.complete(
        restored ? PurchaseOutcome.restored : PurchaseOutcome.purchased,
      );
    }
  }

  void _settle(String productId, PurchaseOutcome outcome) {
    final completer = _outcomes.remove(productId);
    if (completer != null && !completer.isCompleted) {
      completer.complete(outcome);
    }
  }

  String _storeName() {
    if (kIsWeb) return 'GOOGLE';
    return defaultTargetPlatform == TargetPlatform.iOS ? 'APPLE' : 'GOOGLE';
  }
}

enum PurchaseOutcome { purchased, restored, canceled, failed }

class PurchaseCanceledException implements Exception {
  const PurchaseCanceledException();
}

class RestoredPurchaseNotUnlockedException implements Exception {
  const RestoredPurchaseNotUnlockedException();
}
