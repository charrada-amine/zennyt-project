import '../entities/wallet.dart';

/// Portefeuille — contrat engagement.
abstract class WalletRepository {
  /// `GET /wallet/me`
  Future<Wallet> getMyWallet();

  /// `GET /wallet/me/transactions`
  Future<List<WalletTransaction>> getMyTransactions();

  /// `PUT /wallet/me/card`
  Future<WalletCard> saveCard({
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required String cvv,
    required String cardholderName,
  });

  /// `POST /wallet/me/withdraw`
  Future<Wallet> withdraw(double amount);
}
