import 'dart:typed_data';

import '../../../../core/enums/user_role.dart';
import '../../../profile_settings/domain/entities/recruiter_profile.dart';
import '../entities/app_user.dart';

/// Abstraction over authentication + identity onboarding. The presentation layer
/// depends only on this interface. Implementations handle token persistence.
abstract class AuthRepository {
  /// `POST /auth/login` then `GET /auth/me`. Persists the token pair.
  Future<AppUser> login({required String email, required String password});

  /// `POST /auth/register` then `GET /auth/me`. Persists the token pair.
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
  });

  /// `GET /auth/me` for the current access token.
  Future<AppUser> getMe();

  /// `POST /auth/logout` (best-effort) and clears local tokens + cached user.
  Future<void> logout();

  /// `PUT /users/me`. firstName/lastName are required by the contract.
  Future<AppUser> updateMe({
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? city,
    String? country,
    String? address,
    String? profileImageUrl,
  });

  /// `POST /auth/change-password` (authenticated).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// `POST /auth/forgot-password`. Sends OTP code to email.
  Future<void> forgotPassword({required String email});

  /// `POST /auth/reset-password`. Validates OTP and sets new password.
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  /// `DELETE /users/me`. Permanently deletes the account.
  Future<void> deleteAccount();

  /// `POST /users/me/avatar` with multipart/form-data.
  Future<AppUser> uploadAvatar(Uint8List bytes, String filename);

  /// `DELETE /users/me/avatar`.
  Future<AppUser> deleteAvatar();

  /// `POST /onboarding/candidate-student` (CANDIDATE/STUDENT only).
  Future<void> submitCandidateStudentOnboarding({
    String? school,
    String? educationLevel,
    String? fieldOfWork,
    String? lastPositionHeld,
    int? yearsOfExperience,
    String? cvFileUrl,
  });

  /// `POST /onboarding/recruiter` (RECRUITER only).
  Future<void> submitRecruiterOnboarding({
    required String jobTitle,
    required String companyName,
    required String companySize,
    required String fieldOfWork,
    required String companyLocation,
    required String companyRegistrationNumber,
    String? companyLogoUrl,
    String? aboutMe,
    String? about,
    String? mission,
    String? vision,
    String? keyDifferentiators,
    String? cultureWorkEnvironment,
    String? whyJoinUs,
  });

  /// `GET /onboarding/recruiter/me`
  Future<RecruiterProfile?> getRecruiterProfile();

  /// `PUT /onboarding/recruiter/me`
  Future<RecruiterProfile> updateRecruiterProfile(RecruiterProfile profile);

  /// `GET /onboarding/company/{recruiterId}` — all company infos by recruiter id
  Future<RecruiterProfile> getCompanyByRecruiterId(String recruiterId);
}
