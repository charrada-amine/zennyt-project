import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zennyt/core/network/dio_client.dart';
import 'package:zennyt/features/referral/data/referral_repository_impl.dart';
import 'package:zennyt/features/referral/domain/entities/referral.dart';
import 'package:zennyt/features/referral/domain/repositories/referral_repository.dart';

final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  return ReferralRepositoryImpl(ref.watch(dioProvider));
});

class ReferralsNotifier extends AsyncNotifier<List<Referral>> {
  @override
  Future<List<Referral>> build() {
    return ref.read(referralRepositoryProvider).getMyReferrals();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(referralRepositoryProvider).getMyReferrals(),
    );
  }

  Future<Referral> invite(String email) async {
    final referral = await ref.read(referralRepositoryProvider).invite(email);
    final current = state.value ?? [];
    state = AsyncData([referral, ...current]);
    return referral;
  }
}

final referralsProvider = AsyncNotifierProvider<ReferralsNotifier, List<Referral>>(
  ReferralsNotifier.new,
);

final referralLinkProvider = FutureProvider<ReferralLink>((ref) {
  return ref.read(referralRepositoryProvider).getMyLink();
});
