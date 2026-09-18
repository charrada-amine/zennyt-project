import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:zennyt/features/billing/data/store_iap_service.dart';
import 'package:zennyt/features/billing/domain/entities/billing.dart';
import 'package:zennyt/features/billing/presentation/providers/billing_providers.dart';
import 'package:zennyt/shared/widgets/custom_app_bar.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

/// Plans & Pricing (maquettes 261/263/316). Le paiement est géré par
/// App Store / Google Play : pas de saisie de carte ici, l'app ouvre la feuille
/// d'achat du store puis vérifie le reçu côté serveur.
class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  List<ProductDetails> _products = const [];
  bool _loadingProducts = false;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProducts());
  }

  Future<void> _loadProducts() async {
    setState(() => _loadingProducts = true);
    try {
      final plans = await ref.read(plansProvider.future);
      final products = await ref.read(storeIapServiceProvider).loadProducts(plans);
      if (mounted) setState(() => _products = products);
    } catch (_) {
      // Store unavailable (simulator without StoreKit config / offline).
    } finally {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  Future<void> _buy(BillingPlan plan) async {
    final service = ref.read(storeIapServiceProvider);
    if (!await service.isAvailable()) {
      _toast('Purchases are handled by the App Store / Google Play on a real device.');
      return;
    }
    ProductDetails? product;
    for (final candidate in _products) {
      if (candidate.id == plan.productId) {
        product = candidate;
        break;
      }
    }
    if (product == null) {
      _toast('This product is not available in the store yet.');
      return;
    }
    setState(() => _purchasing = true);
    try {
      await service.purchase(plan, product);
    } on PurchaseCanceledException {
      return;
    } catch (_) {
      _toast('Purchase could not be verified yet. It will be retried automatically.');
      return;
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
    if (mounted) ref.read(mySubscriptionProvider.notifier).refresh();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(plansProvider);
    final subscription = ref.watch(mySubscriptionProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFF),
      appBar: CustomAppBar(title: 'Plans & Pricing', onBack: () => context.pop()),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(plansProvider);
          await _loadProducts();
        },
        child: plansAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => ListView(
            children: [
              const SizedBox(height: 120),
              const Center(child: Text('Could not load plans.', style: TextStyle(color: Color(0xFFE53935)))),
              Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(plansProvider),
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
          data: (plans) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              if (subscription != null && subscription.isActive)
                _ActiveBanner(subscription: subscription),
              if (_loadingProducts)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
                ),
              for (final plan in plans)
                _PlanCard(
                  plan: plan,
                  active: subscription?.planCode == plan.code && subscription!.isActive,
                  busy: _purchasing,
                  onBuy: () => _buy(plan),
                ),
              const SizedBox(height: 8),
              const Text(
                'Subscriptions renew automatically and are managed in your '
                'App Store / Google Play account. Prices are set by the store.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8), height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveBanner extends StatelessWidget {
  final Subscription subscription;
  const _ActiveBanner({required this.subscription});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          const AppIcon(HugeIcons.strokeRoundedCheckmarkBadge01, color: Color(0xFF22C55E), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Active plan: ${subscription.planCode}'
              '${subscription.expiresAt != null ? ' · renews ${subscription.expiresAt!.toLocal().toString().split(' ').first}' : ''}',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final BillingPlan plan;
  final bool active;
  final bool busy;
  final VoidCallback onBuy;
  const _PlanCard({
    required this.plan,
    required this.active,
    required this.busy,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: plan.popular ? const Color(0xFF11428D) : const Color(0xFFE6ECF7),
          width: plan.popular ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(plan.name,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B))),
              ),
              if (plan.popular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Most Popular',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF11428D))),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(plan.description, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(plan.priceDisplay,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8))),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(plan.periodLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ),
              const Spacer(),
              FilledButton(
                onPressed: active || busy ? null : onBuy,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF11428D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(active ? 'Current' : (plan.isSubscription ? 'Upgrade' : 'Buy')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
