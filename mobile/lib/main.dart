import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:device_preview/device_preview.dart';
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
  final apiBaseUrl = dotenv.env['API_BASE_URL'];
  await initDependencies(apiBaseUrl: apiBaseUrl!);

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ScaffoldMessenger(
      key: rootScaffoldMessengerKey,
      child: DevicePreview(
        enabled: kDebugMode && kIsWeb,
        builder: (context) => ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const ZennytApp(),
        ),
      ),
    ),
  );
}
