import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/api_exception.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../domain/entities/recruiter_profile.dart';

final recruiterProfileProvider = AsyncNotifierProvider<
    RecruiterProfileViewModel, RecruiterProfile?>(
  RecruiterProfileViewModel.new,
);

class RecruiterProfileViewModel
    extends AsyncNotifier<RecruiterProfile?> {
  @override
  Future<RecruiterProfile?> build() async {
    return _fetchProfile();
  }

  Future<RecruiterProfile?> _fetchProfile() async {
    try {
      final repo = ref.read(authRepositoryProvider);
      return await repo.getRecruiterProfile();
    } catch (e) {
      if (e is NotFoundException) return null;
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String jobTitle,
    required String companyName,
    required String companySize,
    required String fieldOfWork,
    required String companyLocation,
    required String companyRegistrationNumber,
    String? companyLogoUrl,
    String? aboutMe,
  }) async {
    final prev = state;
    state = const AsyncLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      
      final currentProfile = prev.value;
      
      if (currentProfile != null) {
        // Update existing via PUT (if we wanted to use PUT directly, but submitRecruiterOnboarding is currently POST in backend wait, updateRecruiterOnboarding is PUT)
        // Let's use the new updateRecruiterProfile method if it exists or use submitRecruiterOnboarding which may be a POST/PUT based on implementation
        final updated = currentProfile.copyWith(
          jobTitle: jobTitle,
          companyName: companyName,
          companySize: companySize,
          fieldOfWork: fieldOfWork,
          companyLocation: companyLocation,
          companyRegistrationNumber: companyRegistrationNumber,
          companyLogoUrl: companyLogoUrl ?? currentProfile.companyLogoUrl,
          aboutMe: aboutMe,
        );
        final result = await repo.updateRecruiterProfile(updated);
        state = AsyncData(result);
      } else {
        // Use POST
        await repo.submitRecruiterOnboarding(
          jobTitle: jobTitle,
          companyName: companyName,
          companySize: companySize,
          fieldOfWork: fieldOfWork,
          companyLocation: companyLocation,
          companyRegistrationNumber: companyRegistrationNumber,
          companyLogoUrl: companyLogoUrl,
          aboutMe: aboutMe,
        );
        state = AsyncData(await _fetchProfile());
      }
    } catch (e) {
      state = prev; // rollback
      rethrow;
    }
  }
}
