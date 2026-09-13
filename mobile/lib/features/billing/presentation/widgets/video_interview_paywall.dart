import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:zennyt/features/billing/domain/entities/billing.dart';
import 'package:zennyt/features/billing/presentation/providers/billing_providers.dart';

/// Paiement de l'entretien vidéo (maquette 282) : le recruteur règle un achat
/// unique (consommable) via l'App Store / Google Play avant l'appel.
///
/// Retourne `true` quand le paiement a été lancé (ou qu'aucun frais n'est requis)
/// pour laisser l'appel démarrer. La vérification du reçu est faite côté serveur
/// par le flux d'achat (`StoreIapService`).
class VideoInterviewPaywall extends ConsumerStatefulWidget {
  final String counterpartName;
  const VideoInterviewPaywall({super.key, required this.counterpartName});

  static Future<bool> show(BuildContext context, {required String counterpartName}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => VideoInterviewPaywall(counterpartName: counterpartName),
    );
    return result ?? false;
  }

  @override
  ConsumerState<VideoInterviewPaywall> createState() => _VideoInterviewPaywallState();
}

class _VideoInterviewPaywallState extends ConsumerState<VideoInterviewPaywall> {
  bool _busy = false;

  Future<void> _pay(BillingPlan? plan) async {
    if (plan == null) {
      _toast('The video-interview product is not available yet.');
      return;
    }
    setState(() => _busy = true);
    try {
      final service = ref.read(storeIapServiceProvider);
      if (!await service.isAvailable()) {
        _toast('In-app purchases need a real device with the store configured.');
        return;
      }
      final products = await service.loadProducts([plan]);
      ProductDetails? product;
      for (final candidate in products) {
        if (candidate.id == plan.productId) {
          product = candidate;
          break;
        }
      }
      if (product == null) {
        _toast('This product is not available in the store yet.');
        return;
      }
      await service.purchase(plan, product);
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(plansProvider).value ?? const <BillingPlan>[];
    BillingPlan? plan;
    for (final candidate in plans) {
      if (candidate.code == 'video_interview_single') {
        plan = candidate;
        break;
      }
    }
    final price = plan?.priceDisplay ?? '9.99€';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(color: Color(0xFFEEF2FF), shape: BoxShape.circle),
              child: const Icon(Icons.videocam_rounded, color: Color(0xFF11428D), size: 30),
            ),
            const SizedBox(height: 16),
            const Text(
              'Video interview',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B)),
            ),
            const SizedBox(height: 8),
            Text(
              'A $price fee applies for the videoconference with '
              '${widget.counterpartName}. Payment is handled by your '
              'App Store / Google Play account.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.45),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _busy ? null : () => _pay(plan),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF11428D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _busy
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : const Text('Pay now', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
          ],
        ),
      ),
    );
  }
}
