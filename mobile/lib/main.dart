import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // L'URL d'API est injectée au build : --dart-define=API_BASE_URL=...
  const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );
  await initDependencies(apiBaseUrl: apiBaseUrl);

  runApp(const ZennytApp());
}

class ZennytApp extends StatelessWidget {
  const ZennytApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Zennyt',
      theme: AppTheme.light(),
      routerConfig: AppRouter.create(),
      debugShowCheckedModeBanner: false,
    );
  }
}
