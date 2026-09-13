import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zennyt/core/network/dio_client.dart';
import 'package:zennyt/features/wallet/data/wallet_repository_impl.dart';
import 'package:zennyt/features/wallet/domain/entities/wallet.dart';
import 'package:zennyt/features/wallet/domain/repositories/wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(ref.watch(dioProvider));
});

class WalletNotifier extends AsyncNotifier<Wallet> {
  @override
  Future<Wallet> build() {
    return ref.read(walletRepositoryProvider).getMyWallet();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(walletRepositoryProvider).getMyWallet(),
    );
    ref.invalidate(walletTransactionsProvider);
  }

  Future<void> saveCard({
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required String cvv,
    required String cardholderName,
  }) async {
    final card = await ref.read(walletRepositoryProvider).saveCard(
          cardNumber: cardNumber,
          expiryMonth: expiryMonth,
          expiryYear: expiryYear,
          cvv: cvv,
          cardholderName: cardholderName,
        );
    final current = state.value;
    if (current != null) {
      state = AsyncData(Wallet(
        balanceCents: current.balanceCents,
        currency: current.currency,
        card: card,
      ));
    } else {
      await refresh();
    }
  }

  Future<void> withdraw(double amount) async {
    final wallet = await ref.read(walletRepositoryProvider).withdraw(amount);
    state = AsyncData(wallet);
    ref.invalidate(walletTransactionsProvider);
  }
}

final walletProvider = AsyncNotifierProvider<WalletNotifier, Wallet>(WalletNotifier.new);

final walletTransactionsProvider = FutureProvider<List<WalletTransaction>>((ref) {
  return ref.read(walletRepositoryProvider).getMyTransactions();
});
