import 'package:dio/dio.dart';

import '../../../core/enums/user_role.dart';
import '../../../core/error/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/entities/app_user.dart';
import '../domain/repositories/auth_repository.dart';
import 'dtos/auth_tokens.dart';
import 'dtos/login_request.dart';
import 'dtos/register_request.dart';

/// Dio-backed [AuthRepository] talking to the identity API (`/api/v1`).
///
/// Persists the rotating token pair via [TokenStorage] and caches the current
/// user for instant startup. All Dio failures are mapped to typed
/// [ApiException]s for the presentation layer.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dio, this._tokenStorage);

  final Dio _dio;
  final TokenStorage _tokenStorage;

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    return _guard(() async {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: LoginRequest(email: email, password: password).toJson(),
      );
      await _persistTokens(res.data!);
      return _fetchAndCacheMe();
    });
  }

  @override
  Future<AppUser> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required UserRole role,
    required bool termsAccepted,
    String? phoneNumber,
    String? city,
    String? country,
    String? address,
  }) async {
    return _guard(() async {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: RegisterRequest(
          firstName: firstName,
          lastName: lastName,
          email: email,
          password: password,
          role: role,
          termsAccepted: termsAccepted,
          phoneNumber: phoneNumber,
          city: city,
          country: country,
          address: address,
        ).toJson(),
      );
      await _persistTokens(res.data!);
      return _fetchAndCacheMe();
    });
  }

  @override
  Future<AppUser> getMe() => _guard(_fetchAndCacheMe);

  @override
  Future<void> logout() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _dio.post<void>(
          '/auth/logout',
          data: {'refreshToken': refreshToken},
        );
      } on DioException {
        // Best-effort: revoke locally even if the server call fails.
      }
    }
    await _tokenStorage.clear();
  }

  @override
  Future<AppUser> updateMe({
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? city,
    String? country,
    String? address,
    String? profileImageUrl,
  }) async {
    return _guard(() async {
      final body = <String, dynamic>{
        'firstName': firstName,
        'lastName': lastName,
      };
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        body['phoneNumber'] = phoneNumber;
      }
      if (city != null && city.isNotEmpty) body['city'] = city;
      if (country != null && country.isNotEmpty) body['country'] = country;
      if (address != null && address.isNotEmpty) body['address'] = address;
      if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
        body['profileImageUrl'] = profileImageUrl;
      }
      final res = await _dio.put<Map<String, dynamic>>('/users/me', data: body);
      final user = AppUser.fromJson(res.data!);
      await _tokenStorage.saveUser(user.encode());
      return user;
    });
  }

  @override
  Future<void> submitCandidateStudentOnboarding({
    String? school,
    String? educationLevel,
    String? fieldOfWork,
    String? lastPositionHeld,
    int? yearsOfExperience,
    String? cvFileUrl,
  }) async {
    return _guard(() async {
      final body = <String, dynamic>{};
      void put(String key, dynamic value) {
        if (value is String && value.isEmpty) return;
        if (value != null) body[key] = value;
      }

      put('school', school);
      put('educationLevel', educationLevel);
      put('fieldOfWork', fieldOfWork);
      put('lastPositionHeld', lastPositionHeld);
      put('yearsOfExperience', yearsOfExperience);
      put('cvFileUrl', cvFileUrl);

      await _dio.post<void>('/onboarding/candidate-student', data: body);
    });
  }

  @override
  Future<void> submitRecruiterOnboarding({
    required String jobTitle,
    required String companyName,
    required String companySize,
    required String fieldOfWork,
    required String companyLocation,
    required String companyRegistrationNumber,
    String? companyLogoUrl,
  }) async {
    return _guard(() async {
      final body = <String, dynamic>{
        'jobTitle': jobTitle,
        'companyName': companyName,
        'companySize': companySize,
        'fieldOfWork': fieldOfWork,
        'companyLocation': companyLocation,
        'companyRegistrationNumber': companyRegistrationNumber,
      };
      if (companyLogoUrl != null && companyLogoUrl.isNotEmpty) {
        body['companyLogoUrl'] = companyLogoUrl;
      }
      await _dio.post<void>('/onboarding/recruiter', data: body);
    });
  }

  // --- helpers -------------------------------------------------------------

  Future<void> _persistTokens(Map<String, dynamic> json) async {
    final tokens = AuthTokens.fromJson(json);
    await _tokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
  }

  Future<AppUser> _fetchAndCacheMe() async {
    final res = await _dio.get<Map<String, dynamic>>('/auth/me');
    final user = AppUser.fromJson(res.data!);
    await _tokenStorage.saveUser(user.encode());
    return user;
  }

  /// Runs [action], converting any [DioException] into a typed [ApiException].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
