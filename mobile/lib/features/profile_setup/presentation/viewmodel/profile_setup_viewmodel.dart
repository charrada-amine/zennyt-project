import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/upload/picked_file.dart';
import '../../data/field_of_work_repository.dart';

final fieldOfWorkRepositoryProvider = Provider<FieldOfWorkRepository>(
  (ref) => const FieldOfWorkRepository(),
);

/// Semantic onboarding field a text row maps to in the backend. [ignored] is
/// for maquette-only fields with no backend counterpart.
enum ProfileField {
  school,
  educationLevel,
  lastPositionHeld,
  jobTitle,
  companyName,
  companySize,
  companyLocation,
  companyRegistrationNumber,
  about,
  mission,
  vision,
  keyDifferentiators,
  cultureWorkEnvironment,
  whyJoinUs,
  ignored,
}

/// Describes a single row of the role-based "Add your informations" form.
sealed class ProfileFormItem {
  const ProfileFormItem();
}

class TextFormItem extends ProfileFormItem {
  const TextFormItem(this.hint, this.field);
  final String hint;
  final ProfileField field;
}

class FieldOfWorkFormItem extends ProfileFormItem {
  const FieldOfWorkFormItem();
}

class UploadFormItem extends ProfileFormItem {
  const UploadFormItem(this.label, this.kind);
  final String label;
  final UploadItemKind kind;
}

/// Which file an [UploadFormItem] collects.
enum UploadItemKind { cv, companyLogo }

@immutable
class ProfileSetupState {
  const ProfileSetupState({
    this.role = UserRole.student,
    this.fieldOfWork,
    this.cvFile,
    this.companyLogoFile,
  });

  final UserRole role;
  final String? fieldOfWork;

  /// Locally picked files (uploaded at submit; URLs depend on a backend
  /// upload endpoint).
  final PickedFile? cvFile;
  final PickedFile? companyLogoFile;

  /// Ordered list of form items shown for the currently selected [role].
  List<ProfileFormItem> get formItems {
    switch (role) {
      case UserRole.student:
        return const [
          TextFormItem(AppStrings.schoolName, ProfileField.school),
          TextFormItem(AppStrings.education, ProfileField.ignored),
          TextFormItem(AppStrings.educationLevel, ProfileField.educationLevel),
          FieldOfWorkFormItem(),
          TextFormItem(AppStrings.lastPosition, ProfileField.lastPositionHeld),
          UploadFormItem(AppStrings.uploadCv, UploadItemKind.cv),
        ];
      case UserRole.candidate:
        return const [
          TextFormItem(AppStrings.universityName, ProfileField.school),
          TextFormItem(AppStrings.degree, ProfileField.educationLevel),
          TextFormItem(AppStrings.masterDegree, ProfileField.ignored),
          FieldOfWorkFormItem(),
          TextFormItem(AppStrings.lastPosition, ProfileField.lastPositionHeld),
          UploadFormItem(AppStrings.uploadCv, UploadItemKind.cv),
        ];
      case UserRole.recruiter:
        return const [
          TextFormItem(AppStrings.jobTitle, ProfileField.jobTitle),
          FieldOfWorkFormItem(),
          TextFormItem(AppStrings.companyName, ProfileField.companyName),
          TextFormItem(AppStrings.companySize, ProfileField.companySize),
          UploadFormItem(
            AppStrings.uploadCompanyLogo,
            UploadItemKind.companyLogo,
          ),
          TextFormItem(
            AppStrings.companyLocation,
            ProfileField.companyLocation,
          ),
          TextFormItem(
            AppStrings.companyRegistrationNumber,
            ProfileField.companyRegistrationNumber,
          ),
          // ── Company detail (second step) — still in single list for backward compat,
          // but split UI will use recruiterCompanyDetailItems
          TextFormItem('About — Who we are?', ProfileField.about),
          TextFormItem('Mission', ProfileField.mission),
          TextFormItem('Vision', ProfileField.vision),
          TextFormItem('What makes us different?', ProfileField.keyDifferentiators),
          TextFormItem('Culture & work environment', ProfileField.cultureWorkEnvironment),
          TextFormItem('Why join us?', ProfileField.whyJoinUs),
        ];
    }
  }

  /// Step 1 — Recruiter itself (personal info) — fieldOfWork belongs to recruiter
  List<ProfileFormItem> get recruiterStep1Items => const [
        TextFormItem(AppStrings.jobTitle, ProfileField.jobTitle),
        FieldOfWorkFormItem(),
      ];

  /// Step 2 — Company information (all company fields + new detail fields)
  List<ProfileFormItem> get recruiterCompanyStep2Items => const [
        TextFormItem(AppStrings.companyName, ProfileField.companyName),
        TextFormItem(AppStrings.companySize, ProfileField.companySize),
        UploadFormItem(AppStrings.uploadCompanyLogo, UploadItemKind.companyLogo),
        TextFormItem(AppStrings.companyLocation, ProfileField.companyLocation),
        TextFormItem(AppStrings.companyRegistrationNumber, ProfileField.companyRegistrationNumber),
        TextFormItem('About — Who we are?', ProfileField.about),
        TextFormItem('Mission', ProfileField.mission),
        TextFormItem('Vision', ProfileField.vision),
        TextFormItem('What makes us different?', ProfileField.keyDifferentiators),
        TextFormItem('Culture & work environment', ProfileField.cultureWorkEnvironment),
        TextFormItem('Why join us?', ProfileField.whyJoinUs),
      ];

  ProfileSetupState copyWith({
    UserRole? role,
    String? fieldOfWork,
    PickedFile? cvFile,
    PickedFile? companyLogoFile,
  }) {
    return ProfileSetupState(
      role: role ?? this.role,
      fieldOfWork: fieldOfWork ?? this.fieldOfWork,
      cvFile: cvFile ?? this.cvFile,
      companyLogoFile: companyLogoFile ?? this.companyLogoFile,
    );
  }
}

class ProfileSetupViewModel extends Notifier<ProfileSetupState> {
  @override
  ProfileSetupState build() => const ProfileSetupState();

  void setRole(UserRole role) => state = state.copyWith(role: role);

  void setFieldOfWork(String field) =>
      state = state.copyWith(fieldOfWork: field);

  void setCvFile(PickedFile file) => state = state.copyWith(cvFile: file);

  void setCompanyLogoFile(PickedFile file) =>
      state = state.copyWith(companyLogoFile: file);
}

final profileSetupViewModelProvider =
    NotifierProvider<ProfileSetupViewModel, ProfileSetupState>(
      ProfileSetupViewModel.new,
    );
