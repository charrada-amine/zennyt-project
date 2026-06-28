import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/error/api_exception.dart';
import '../../auth_controller.dart';

const Object _unset = Object();

/// Language-agnostic auth error codes. The view resolves them to localized
/// text so no user-facing strings live in the view model.
enum LoginError {
  emailRequired,
  emailInvalid,
  passwordRequired,
  passwordTooShort,
  incorrectPassword,
  connectionFailed,
  unknown,
}

@immutable
class LoginState {
  const LoginState({
    this.isLoading = false,
    this.emailError,
    this.passwordError,
    this.connectionError,
    this.isSuccess = false,
  });

  final bool isLoading;

  /// Inline error shown under the email field (required / format).
  final LoginError? emailError;

  /// Inline error shown under the password field (required / incorrect).
  final LoginError? passwordError;

  /// Triggers the "Error connecting" dialog when set.
  final LoginError? connectionError;
  final bool isSuccess;

  LoginState copyWith({
    bool? isLoading,
    Object? emailError = _unset,
    Object? passwordError = _unset,
    Object? connectionError = _unset,
    bool? isSuccess,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      emailError: emailError == _unset
          ? this.emailError
          : emailError as LoginError?,
      passwordError: passwordError == _unset
          ? this.passwordError
          : passwordError as LoginError?,
      connectionError: connectionError == _unset
          ? this.connectionError
          : connectionError as LoginError?,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class LoginViewModel extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  static final _emailRegExp = RegExp(r'^[\w.\-]+@([\w\-]+\.)+[\w\-]{2,}$');

  static LoginError? validateEmail(String value) {
    final v = value.trim();
    if (v.isEmpty) return LoginError.emailRequired;
    if (!_emailRegExp.hasMatch(v)) return LoginError.emailInvalid;
    return null;
  }

  static LoginError? validatePassword(String value) {
    if (value.isEmpty) return LoginError.passwordRequired;
    // Backend enforces a minimum of 8 characters on register.
    if (value.length < 8) return LoginError.passwordTooShort;
    return null;
  }

  Future<void> signIn({required String email, required String password}) async {
    // 1) Client-side validation first.
    final emailError = validateEmail(email);
    final passwordError = validatePassword(password);
    if (emailError != null || passwordError != null) {
      state = LoginState(emailError: emailError, passwordError: passwordError);
      return;
    }

    // 2) Then the backend call via the session controller.
    state = const LoginState(isLoading: true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signIn(email: email.trim(), password: password);
      state = const LoginState(isSuccess: true);
    } on UnauthorizedException {
      // 401 — invalid email or password. Surfaced inline on the password field.
      state = const LoginState(passwordError: LoginError.incorrectPassword);
    } on ConnectionException {
      state = const LoginState(connectionError: LoginError.connectionFailed);
    } on ApiException {
      state = const LoginState(connectionError: LoginError.unknown);
    } catch (_) {
      state = const LoginState(connectionError: LoginError.unknown);
    }
  }

  void clearEmailError() {
    if (state.emailError != null) state = state.copyWith(emailError: null);
  }

  void clearPasswordError() {
    if (state.passwordError != null) {
      state = state.copyWith(passwordError: null);
    }
  }

  void clearConnectionError() {
    if (state.connectionError != null) {
      state = state.copyWith(connectionError: null);
    }
  }
}

final loginViewModelProvider = NotifierProvider<LoginViewModel, LoginState>(
  LoginViewModel.new,
);
