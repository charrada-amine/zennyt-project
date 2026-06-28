import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';

import 'app.dart';
import 'core/storage/shared_preferences_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    DevicePreview(
      enabled: kDebugMode && kIsWeb,
      builder: (context) => ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const ZennytApp(),
      ),
    ),
  );
}
