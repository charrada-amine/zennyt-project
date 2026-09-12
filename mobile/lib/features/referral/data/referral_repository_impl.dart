import 'package:dio/dio.dart';

import 'package:zennyt/core/error/api_exception.dart';
import 'package:zennyt/features/referral/domain/entities/referral.dart';
import 'package:zennyt/features/referral/domain/repositories/referral_repository.dart';

class ReferralRepositoryImpl implements ReferralRepository {
  ReferralRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Referral>> getMyReferrals() {
    return _guard(() async {
      final res = await _dio.get<List<dynamic>>('/referrals/me');
      return res.data!
          .map((e) => Referral.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<Referral> invite(String email) {
    return _guard(() async {
      final res = await _dio.post<Map<String, dynamic>>(
        '/referrals/invite',
        data: {'email': email},
      );
      return Referral.fromJson(res.data!);
    });
  }

  @override
  Future<ReferralLink> getMyLink() {
    return _guard(() async {
      final res = await _dio.get<Map<String, dynamic>>('/referrals/me/link');
      return ReferralLink.fromJson(res.data!);
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
