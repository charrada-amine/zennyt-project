import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/user_role.dart';
import '../../../core/error/api_exception.dart';
import '../../../core/network/auth_events.dart';
import '../../../core/storage/token_storage.dart';
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
      debugPrint('Auth bootstrap: secure storage timed out; starting signed out.');
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
    String? profileImageUrl,
    // Candidate / student onboarding
    String? school,
    String? educationLevel,
    String? fieldOfWork,
    String? lastPositionHeld,
    int? yearsOfExperience,
    String? cvFileUrl,
    // Recruiter onboarding
    String? jobTitle,
    String? companyName,
    String? companySize,
    String? companyLocation,
    String? companyRegistrationNumber,
    String? companyLogoUrl,
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

    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      try {
        user = await repo.updateMe(
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
          city: city,
          country: country,
          profileImageUrl: profileImageUrl,
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
          companyLogoUrl: companyLogoUrl,
        );
      } else {
        await repo.submitCandidateStudentOnboarding(
          school: school,
          educationLevel: educationLevel,
          fieldOfWork: fieldOfWork,
          lastPositionHeld: lastPositionHeld,
          yearsOfExperience: yearsOfExperience,
          cvFileUrl: cvFileUrl,
        );
      }
    } on ApiException {
      // Onboarding can be completed later from the profile screens.
    }

    return user;
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
    } on ApiException {
      // Keep the cached user; interceptor governs token validity.
    }
  }

  Future<void> _onSessionExpired() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AsyncData(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AppUser?>(AuthController.new);
