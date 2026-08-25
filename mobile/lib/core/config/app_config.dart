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
    const defineVal = String.fromEnvironment('API_BASE_URL');
    if (defineVal.isNotEmpty) return defineVal;
    final dotEnvVal = dotenv.env['API_BASE_URL'];
    if (dotEnvVal != null && dotEnvVal.isNotEmpty) {
      return dotEnvVal;
    }
    return '';
  }

  /// Fully-qualified API base URL including the `/api/v1` prefix.
  /// Supports absolute (http://host:port/api/v1), relative (/api/v1 for same-origin proxy),
  /// and env/dart-define overrides.
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      // Relative URL = same-origin proxy → resolve against current page origin (web)
      if (_envBaseUrl.startsWith('/')) {
        if (kIsWeb) {
          final origin = Uri.base.origin;
          return '$origin$_envBaseUrl';
        }
        return _envBaseUrl;
      }
      return _envBaseUrl;
    }
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
}
