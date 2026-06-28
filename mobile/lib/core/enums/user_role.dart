import '../constants/app_strings.dart';

/// The three account types a user can register as. Drives the role-based
/// "Add your informations" wizard.
enum UserRole {
  recruiter,
  candidate,
  student;

  String get label {
    switch (this) {
      case UserRole.recruiter:
        return AppStrings.roleRecruiter;
      case UserRole.candidate:
        return AppStrings.roleCandidate;
      case UserRole.student:
        return AppStrings.roleStudent;
    }
  }

  /// Backend enum value (see `Role` in the identity contract).
  String get wireValue {
    switch (this) {
      case UserRole.recruiter:
        return 'RECRUITER';
      case UserRole.candidate:
        return 'CANDIDATE';
      case UserRole.student:
        return 'STUDENT';
    }
  }
}

/// Parses a backend role string into a [UserRole]. `ADMIN` (and any unknown
/// value) falls back to [UserRole.candidate] since the app has no admin flows.
UserRole userRoleFromWire(String? value) {
  switch (value) {
    case 'RECRUITER':
      return UserRole.recruiter;
    case 'STUDENT':
      return UserRole.student;
    case 'CANDIDATE':
    default:
      return UserRole.candidate;
  }
}
