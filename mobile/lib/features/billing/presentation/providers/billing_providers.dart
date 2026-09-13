import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zennyt/core/network/dio_client.dart';
import 'package:zennyt/features/billing/data/billing_repository_impl.dart';
import 'package:zennyt/features/billing/data/store_iap_service.dart';
import 'package:zennyt/features/billing/domain/entities/billing.dart';
import 'package:zennyt/features/billing/domain/repositories/billing_repository.dart';

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepositoryImpl(ref.watch(dioProvider));
});

/// StoreKit / Google Play purchase bridge. The subscription stream starts as
/// soon as this provider is first read and is cancelled on dispose.
final storeIapServiceProvider = Provider<StoreIapService>((ref) {
  final service = StoreIapService(ref.read(billingRepositoryProvider));
  service.start();
  ref.onDispose(service.dispose);
  return service;
});

final plansProvider = FutureProvider<List<BillingPlan>>((ref) {
  return ref.read(billingRepositoryProvider).getPlans();
});

class MySubscriptionNotifier extends AsyncNotifier<Subscription?> {
  @override
  Future<Subscription?> build() {
    return ref.read(billingRepositoryProvider).getMySubscription();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(billingRepositoryProvider).getMySubscription(),
    );
  }
}

final mySubscriptionProvider =
    AsyncNotifierProvider<MySubscriptionNotifier, Subscription?>(MySubscriptionNotifier.new);
