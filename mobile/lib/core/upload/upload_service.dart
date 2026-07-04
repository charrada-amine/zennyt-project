import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';
import 'picked_file.dart';

/// What a picked file represents, so a real upload backend can route it.
enum UploadKind { avatar, cv, companyLogo }

/// Turns a locally [PickedFile] into a hosted URL the backend can store.
///
/// The identity backend currently exposes no file-upload endpoint, so the
/// default [NoopUploadService] returns `null` (no URL). Swap the provider for a
/// real implementation (e.g. `POST /media`) once that endpoint exists — no UI
/// changes required.
abstract class UploadService {
  Future<String?> upload(PickedFile file, {required UploadKind kind});
}

class DioUploadService implements UploadService {
  DioUploadService(this._dio);

  final Dio _dio;

  @override
  Future<String?> upload(PickedFile file, {required UploadKind kind}) async {
    if (file.bytes == null) return null;

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
    });

    String endpoint;
    switch (kind) {
      case UploadKind.avatar:
        endpoint = '/users/me/avatar';
        break;
      case UploadKind.cv:
        endpoint = '/profiles/me/cv';
        break;
      case UploadKind.companyLogo:
        endpoint = '/onboarding/recruiter/me/logo';
        break;
    }

    try {
      final res = await _dio.post<Map<String, dynamic>>(
        endpoint,
        data: formData,
      );

      // The backend returns ProfileResponse, UserResponse, or RecruiterResponse
      // Depending on the endpoint, we need to extract the URL.
      // Usually, the API structure should have a uniform response, but we can look
      // into the data map for standard keys: profileImageUrl, cvFileUrl, companyLogoUrl
      final data = res.data!;
      if (data.containsKey('profileImageUrl')) {
        return data['profileImageUrl'] as String?;
      }
      if (data.containsKey('cvFileUrl')) {
        return data['cvFileUrl'] as String?;
      }
      if (data.containsKey('companyLogoUrl')) {
        return data['companyLogoUrl'] as String?;
      }

      return null; // Fallback
    } catch (e) {
      return null; // In a real app we might throw and handle in UI
    }
  }
}

final uploadServiceProvider = Provider<UploadService>(
  (ref) => DioUploadService(ref.watch(dioProvider)),
);
