import 'package:dio/dio.dart';

import 'package:zennyt/core/error/api_exception.dart';
import 'package:zennyt/features/billing/domain/entities/billing.dart';
import 'package:zennyt/features/billing/domain/repositories/billing_repository.dart';

class BillingRepositoryImpl implements BillingRepository {
  BillingRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<BillingPlan>> getPlans() {
    return _guard(() async {
      final res = await _dio.get<List<dynamic>>('/plans');
      return res.data!
          .map((e) => BillingPlan.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<Subscription?> getMySubscription() {
    return _guard(() async {
      final res = await _dio.get<dynamic>('/subscriptions/me');
      if (res.data == null) return null;
      return Subscription.fromJson(res.data as Map<String, dynamic>);
    });
  }

  @override
  Future<void> verifyPurchase({
    required String productId,
    required String store,
    required String receipt,
    required String transactionId,
  }) {
    return _guard(() async {
      await _dio.post<Map<String, dynamic>>('/purchases/verify', data: {
        'productId': productId,
        'store': store,
        'receipt': receipt,
        'transactionId': transactionId,
      });
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
