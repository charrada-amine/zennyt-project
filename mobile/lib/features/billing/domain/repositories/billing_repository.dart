import '../entities/billing.dart';

/// Facturation : catalogue d'offres, abonnement courant, vérification d'achat
/// store. Les prix réels sont gérés par App Store / Google Play.
abstract class BillingRepository {
  /// `GET /plans`
  Future<List<BillingPlan>> getPlans();

  /// `GET /subscriptions/me`
  Future<Subscription?> getMySubscription();

  /// `POST /purchases/verify`
  Future<void> verifyPurchase({
    required String productId,
    required String store,
    required String receipt,
    required String transactionId,
  });
}
