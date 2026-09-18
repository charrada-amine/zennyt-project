import 'package:dio/dio.dart';

import 'package:zennyt/core/error/api_exception.dart';
import 'package:zennyt/features/wallet/domain/entities/wallet.dart';
import 'package:zennyt/features/wallet/domain/repositories/wallet_repository.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Wallet> getMyWallet() {
    return _guard(() async {
      final res = await _dio.get<Map<String, dynamic>>('/wallet/me');
      return Wallet.fromJson(res.data!);
    });
  }

  @override
  Future<List<WalletTransaction>> getMyTransactions() {
    return _guard(() async {
      final res = await _dio.get<List<dynamic>>('/wallet/me/transactions');
      return res.data!
          .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<WalletCard> saveCard({
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required String cvv,
    required String cardholderName,
  }) {
    return _guard(() async {
      final res = await _dio.put<Map<String, dynamic>>('/wallet/me/card', data: {
        'cardNumber': cardNumber,
        'expiryMonth': expiryMonth,
        'expiryYear': expiryYear,
        'cvv': cvv,
        'cardholderName': cardholderName,
      });
      return WalletCard.fromJson(res.data!);
    });
  }

  @override
  Future<Wallet> withdraw(double amount) {
    return _guard(() async {
      final res = await _dio.post<Map<String, dynamic>>(
        '/wallet/me/withdraw',
        data: {'amount': amount},
      );
      return Wallet.fromJson(res.data!);
    });
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
