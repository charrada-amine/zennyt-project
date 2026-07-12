import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';

import '../error/api_exception.dart';
import '../network/dio_client.dart';
import 'cv_file_validation.dart';
import 'picked_file.dart';

/// What a picked file represents, so a real upload backend can route it.
enum UploadKind { avatar, cv, companyLogo }

/// Turns a locally [PickedFile] into a hosted URL the backend can store.
///
/// A failed upload throws an [ApiException] so callers never report success for
/// a file that was not persisted by the identity backend.
abstract class UploadService {
  Future<String?> upload(PickedFile file, {required UploadKind kind});
}

class DioUploadService implements UploadService {
  DioUploadService(this._dio);

  final Dio _dio;

  @override
  Future<String?> upload(PickedFile file, {required UploadKind kind}) async {
    if (file.bytes == null) {
      throw const CvFileValidationException(
        'The selected file could not be read.',
      );
    }
    if (kind == UploadKind.cv) {
      CvFileValidation.validateUploadBytes(file.name, file.bytes!);
    }

    final multipartFile = MultipartFile.fromBytes(
      file.bytes!,
      filename: file.name,
      contentType: kind == UploadKind.cv
          ? MediaType.parse(CvFileValidation.uploadContentType(file.name))
          : null,
    );
    final formData = FormData.fromMap({'file': multipartFile});

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
      final data = res.data ?? const <String, dynamic>{};
      if (data.containsKey('profileImageUrl')) {
        return data['profileImageUrl'] as String?;
      }
      if (data.containsKey('cvUrl')) {
        return data['cvUrl'] as String?;
      }
      if (data.containsKey('companyLogoUrl')) {
        return data['companyLogoUrl'] as String?;
      }

      return null; // Fallback
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final uploadServiceProvider = Provider<UploadService>(
  (ref) => DioUploadService(ref.watch(dioProvider)),
);
