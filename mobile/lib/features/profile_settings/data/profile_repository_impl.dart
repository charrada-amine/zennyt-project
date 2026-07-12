import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

import '../../../core/error/api_exception.dart';
import '../../../core/upload/cv_file_validation.dart';
import '../domain/entities/candidate_profile.dart';
import '../domain/repositories/profile_repository.dart';
import 'dtos/profile_input.dart';
import 'dtos/sub_resource_inputs.dart';

/// Dio-backed [ProfileRepository] talking to the identity `/profiles` API.
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<CandidateProfile?> getMyProfile() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/profiles/me');
      final data = res.data;
      return data == null ? null : CandidateProfile.fromJson(data);
    } on DioException catch (e) {
      final mapped = ApiException.fromDio(e);
      // No profile created yet is a normal state, not an error.
      if (mapped is NotFoundException) return null;
      throw mapped;
    }
  }

  @override
  Future<CandidateProfile> saveProfile(
    ProfileInput input, {
    required bool exists,
  }) async {
    try {
      final body = input.toJson();
      final res = exists
          ? await _dio.put<Map<String, dynamic>>('/profiles/me', data: body)
          : await _dio.post<Map<String, dynamic>>('/profiles', data: body);
      return CandidateProfile.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ── Skills ──────────────────────────────────────────────────────────────

  @override
  Future<ProfileSkill> addSkill(SkillInput input) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/profiles/me/skills',
        data: input.toJson(),
      );
      return ProfileSkill.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<ProfileSkill> updateSkill(String id, SkillInput input) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/profiles/me/skills/$id',
        data: input.toJson(),
      );
      return ProfileSkill.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> deleteSkill(String id) async {
    try {
      await _dio.delete('/profiles/me/skills/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ── Positions ───────────────────────────────────────────────────────────

  @override
  Future<ProfilePosition> addPosition(PositionInput input) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/profiles/me/positions',
        data: input.toJson(),
      );
      return ProfilePosition.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<ProfilePosition> updatePosition(String id, PositionInput input) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/profiles/me/positions/$id',
        data: input.toJson(),
      );
      return ProfilePosition.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> deletePosition(String id) async {
    try {
      await _dio.delete('/profiles/me/positions/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ── Certifications ──────────────────────────────────────────────────────

  @override
  Future<ProfileCertification> addCertification(
    CertificationInput input,
  ) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/profiles/me/certifications',
        data: input.toJson(),
      );
      return ProfileCertification.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<ProfileCertification> updateCertification(
    String id,
    CertificationInput input,
  ) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/profiles/me/certifications/$id',
        data: input.toJson(),
      );
      return ProfileCertification.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> deleteCertification(String id) async {
    try {
      await _dio.delete('/profiles/me/certifications/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ── Education ───────────────────────────────────────────────────────────

  @override
  Future<ProfileEducation> addEducation(EducationInput input) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/profiles/me/education',
        data: input.toJson(),
      );
      return ProfileEducation.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<ProfileEducation> updateEducation(
    String id,
    EducationInput input,
  ) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/profiles/me/education/$id',
        data: input.toJson(),
      );
      return ProfileEducation.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> deleteEducation(String id) async {
    try {
      await _dio.delete('/profiles/me/education/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> uploadCv(String filePath) async {
    try {
      await CvFileValidation.validateUploadPath(filePath);
      final fileName = p.basename(filePath);

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType: MediaType.parse(
            CvFileValidation.uploadContentType(fileName),
          ),
        ),
      });
      await _dio.post(
        '/profiles/me/cv',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> deleteCv() async {
    try {
      await _dio.delete('/profiles/me/cv');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
