import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Visual state of the OTP entry boxes.
enum OtpStatus { normal, invalid, valid }

@immutable
class SignupState {
  const SignupState({
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.phone = '+1 555 0100',
    this.password = '',
    this.city,
    this.country,
    this.termsAccepted = false,
    this.isLoading = false,
    this.errorMessage,
    this.registered = false,
    this.otpStatus = OtpStatus.normal,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  /// Held in memory only until the deferred register call at profile setup.
  final String password;

  /// Separate location fields, matching the backend (`city`, `country`).
  final String? city;
  final String? country;
  final bool termsAccepted;

  final bool isLoading;
  final String? errorMessage;

  /// True once the account form has been completed (data captured locally).
  final bool registered;
  final OtpStatus otpStatus;

  bool get verified => otpStatus == OtpStatus.valid;

  SignupState copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? password,
    String? city,
    String? country,
    bool? termsAccepted,
    bool? isLoading,
    String? errorMessage,
    bool? registered,
    OtpStatus? otpStatus,
    bool clearError = false,
  }) {
    return SignupState(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      city: city ?? this.city,
      country: country ?? this.country,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      registered: registered ?? this.registered,
      otpStatus: otpStatus ?? this.otpStatus,
    );
  }
}

/// Shared ViewModel across the multi-step sign-up flow (create account -> OTP
/// -> change phone -> profile setup).
///
/// Registration is deferred: the account form only captures data locally; the
/// actual `POST /auth/register` (+ onboarding) happens at the end of profile
/// setup once the role is known. The OTP step is visual-only (the backend has
/// no SMS/email verification endpoint).
class SignupViewModel extends Notifier<SignupState> {
  @override
  SignupState build() => const SignupState();

  /// Captures the account form data locally (no network call yet).
  bool saveAccountDetails({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    String? city,
    String? country,
    bool termsAccepted = false,
  }) {
    state = state.copyWith(
      clearError: true,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      password: password,
      city: city,
      country: country,
      termsAccepted: termsAccepted,
      registered: true,
    );
    return true;
  }

  /// Visual-only OTP check: any complete 6-digit code is accepted.
  Future<bool> verifyOtp(String code) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      otpStatus: OtpStatus.normal,
    );
    // Small delay to mirror a real verification round-trip.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (code.length == 6) {
      state = state.copyWith(isLoading: false, otpStatus: OtpStatus.valid);
      return true;
    }
    state = state.copyWith(isLoading: false, otpStatus: OtpStatus.invalid);
    return false;
  }

  /// Visual-only resend (no backend endpoint).
  Future<void> resendOtp() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  /// Resets the OTP boxes to their neutral state (e.g. while the user edits).
  void resetOtpStatus() {
    if (state.otpStatus != OtpStatus.normal || state.errorMessage != null) {
      state = state.copyWith(otpStatus: OtpStatus.normal, clearError: true);
    }
  }

  void updatePhone(String phone) => state = state.copyWith(phone: phone);

  void clearError() => state = state.copyWith(clearError: true);
}

final signupViewModelProvider = NotifierProvider<SignupViewModel, SignupState>(
  SignupViewModel.new,
);
