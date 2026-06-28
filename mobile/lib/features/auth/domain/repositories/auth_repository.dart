import '../../../../core/enums/user_role.dart';
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
  });
}
