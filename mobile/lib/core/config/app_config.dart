import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralised runtime configuration.
///
/// The API base URL can be injected at build/run time:
///
/// ```
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8080/api/v1
/// ```
///
/// When no override is provided, a sensible per-platform default is used so the
/// app talks to a backend running locally via `docker compose up` (port 8080):
/// - Android emulator reaches the host machine through `10.0.2.2`.
/// - iOS simulator, desktop and web reach it through `localhost`.
class AppConfig {
  const AppConfig._();

  static String get _envBaseUrl {
    final dotEnvVal = dotenv.env['API_BASE_URL'];
    if (dotEnvVal != null && dotEnvVal.isNotEmpty) {
      return dotEnvVal;
    }
    return const String.fromEnvironment('API_BASE_URL');
  }

  /// Fully-qualified API base URL including the `/api/v1` prefix.
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    return _defaultBaseUrl;
  }

  static String get _defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:8080/api/v1';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8080/api/v1';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://localhost:8080/api/v1';
    }
  }

  /// Network timeout applied to connect/receive/send phases.
  static const Duration networkTimeout = Duration(seconds: 20);

  /// DEV ONLY — skip the signup verification step.
  ///
  /// The signup OTP screen is visual-only today (the backend exposes no e-mail/
  /// SMS verification for registration), so for development this flag routes the
  /// user straight to profile setup. Enable with either:
  ///
  /// ```
  /// flutter run --dart-define=SKIP_SIGNUP_VERIFICATION=true
  /// ```
  /// or `SKIP_SIGNUP_VERIFICATION=true` in `mobile/.env`.
  ///
  /// Never enable this in a production build.
  static bool get skipSignupVerification {
    if (dotenv.isInitialized) {
      final fromDotEnv = dotenv.env['SKIP_SIGNUP_VERIFICATION'];
      if (fromDotEnv != null && fromDotEnv.trim().isNotEmpty) {
        return fromDotEnv.trim().toLowerCase() == 'true';
      }
    }
    return const bool.fromEnvironment('SKIP_SIGNUP_VERIFICATION', defaultValue: false);
  }
}
