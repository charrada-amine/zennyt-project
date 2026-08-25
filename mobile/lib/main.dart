import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'core/storage/shared_preferences_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env configuration
  await dotenv.load(fileName: ".env", isOptional: true);

  // Initialize local storage (Hive)
  await Hive.initFlutter();

  // Initialize dependency injection container
  // On web, force localhost (192.168.100.4 is LAN-only and unreachable / CORS-blocked from browser).
  final rawApiBaseUrl = dotenv.env['API_BASE_URL'];
  final apiBaseUrl = kIsWeb
      ? AppConfig.baseUrl
      : (rawApiBaseUrl != null && rawApiBaseUrl.isNotEmpty
          ? rawApiBaseUrl
          : AppConfig.baseUrl);
  await initDependencies(apiBaseUrl: apiBaseUrl);

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ScaffoldMessenger(
      key: rootScaffoldMessengerKey,
      child: ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const ZennytApp(),
      ),
    ),
  );
}
