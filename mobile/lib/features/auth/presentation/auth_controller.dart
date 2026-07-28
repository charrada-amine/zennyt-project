import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/user_role.dart';
import '../../../core/error/api_exception.dart';
import '../../../core/network/auth_events.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/upload/upload_service.dart';
import '../../../core/upload/picked_file.dart';
import '../domain/entities/app_user.dart';
import 'auth_providers.dart';

/// Source of truth for the authenticated session.
///
/// `AsyncData(user)` = signed in, `AsyncData(null)` = signed out. The router
/// redirect watches this to gate access. Bootstraps from secure storage for an
/// instant startup, then revalidates against `/auth/me` in the background.
class AuthController extends AsyncNotifier<AppUser?> {
  /// Hard ceiling on the startup token read so a slow/misbehaving secure-storage
  /// backend (seen on some OEM devices) can never wedge the splash screen.
  static const _bootstrapTimeout = Duration(seconds: 6);

  @override
  Future<AppUser?> build() async {
    final bus = ref.watch(authEventBusProvider);
    final sub = bus.onSessionExpired.listen((_) => _onSessionExpired());
    ref.onDispose(sub.cancel);

    final storage = ref.watch(tokenStorageProvider);

    try {
      final token = await storage.readAccessToken().timeout(_bootstrapTimeout);
      if (token == null || token.isEmpty) return null;

      final cached = await storage.readUser().timeout(_bootstrapTimeout);
      if (cached != null) {
        unawaited(_revalidate());
        return AppUser.decode(cached);
      }
      return await ref.read(authRepositoryProvider).getMe();
    } on TimeoutException {
      debugPrint(
        'Auth bootstrap: secure storage timed out; starting signed out.',
      );
      return null;
    } on ApiException {
      return null;
    } catch (e, st) {
      debugPrint('Auth bootstrap failed: $e\n$st');
      return null;
    }
  }

  /// Whether a user is currently signed in.
  bool get isAuthenticated => state.value != null;

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final user = await ref
        .read(authRepositoryProvider)
        .login(email: email, password: password);
    state = AsyncData(user);
    return user;
  }

  /// Deferred registration: create the account, set the avatar, then submit the
  /// role-specific onboarding. The account is considered created (session set)
  /// once `register` succeeds; avatar + onboarding are best-effort so a hiccup
  /// there never blocks reaching the app.
  Future<AppUser> completeSignUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required UserRole role,
    required bool termsAccepted,
    String? phoneNumber,
    String? city,
    String? country,
    String? defaultAvatarUrl,
    PickedFile? avatarFile,
    // Candidate / student onboarding
    String? school,
    String? educationLevel,
    String? fieldOfWork,
    String? lastPositionHeld,
    int? yearsOfExperience,
    PickedFile? cvFile,
    // Recruiter onboarding
    String? jobTitle,
    String? companyName,
    String? companySize,
    String? companyLocation,
    String? companyRegistrationNumber,
    PickedFile? companyLogoFile,
  }) async {
    final repo = ref.read(authRepositoryProvider);

    var user = await repo.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      role: role,
      termsAccepted: termsAccepted,
      phoneNumber: phoneNumber,
      city: city,
      country: country,
    );
    state = AsyncData(user);

    // Now authenticated, upload files
    final upload = ref.read(uploadServiceProvider);

    String? finalAvatarUrl = defaultAvatarUrl;
    if (avatarFile != null) {
      final uploaded = await upload.upload(avatarFile, kind: UploadKind.avatar);
      if (uploaded != null) finalAvatarUrl = uploaded;
    }

    if (finalAvatarUrl != null && finalAvatarUrl.isNotEmpty) {
      try {
        user = await repo.updateMe(
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
          city: city,
          country: country,
          profileImageUrl: finalAvatarUrl,
        );
        state = AsyncData(user);
      } on ApiException {
        // Keep the registered session even if the avatar update fails.
      }
    }

    try {
      if (role == UserRole.recruiter) {
        await repo.submitRecruiterOnboarding(
          jobTitle: jobTitle ?? '',
          companyName: companyName ?? '',
          companySize: companySize ?? '',
          fieldOfWork: fieldOfWork ?? '',
          companyLocation: companyLocation ?? '',
          companyRegistrationNumber: companyRegistrationNumber ?? '',
          companyLogoUrl: null, // uploaded below
        );
        if (companyLogoFile != null) {
          await upload.upload(companyLogoFile, kind: UploadKind.companyLogo);
        }
      } else {
        await repo.submitCandidateStudentOnboarding(
          school: school,
          educationLevel: educationLevel,
          fieldOfWork: fieldOfWork,
          lastPositionHeld: lastPositionHeld,
          yearsOfExperience: yearsOfExperience,
          cvFileUrl: null, // uploaded below
        );
      }
    } on ApiException {
      // Onboarding can be completed later from the profile screens.
    }

    // A selected CV is an explicit user action. Its failure must be surfaced
    // rather than silently completing registration without the document.
    if (role != UserRole.recruiter && cvFile != null) {
      await upload.upload(cvFile, kind: UploadKind.cv);
    }

    // Refresh the user to fetch updated cvFileUrl and companyLogoUrl from the backend
    await refreshUser();
    return state.value ?? user;
  }

  Future<void> refreshUser() async {
    try {
      final user = await ref.read(authRepositoryProvider).getMe();
      state = AsyncData(user);
    } on ApiException {
      // Ignore: the interceptor handles 401 refresh / expiry.
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  Future<void> _revalidate() async {
    try {
      final user = await ref.read(authRepositoryProvider).getMe();
      state = AsyncData(user);
    } catch (_) {
      final token = await ref.read(tokenStorageProvider).readAccessToken();
      if (token == null || token.isEmpty) {
        state = const AsyncData(null);
      }
    }
  }

  Future<void> _onSessionExpired() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);
