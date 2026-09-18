import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Saves every `binding.takeScreenshot(name)` to
/// `docs/e2e/screenshots/<name>.png`.
Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final file = File('../docs/e2e/screenshots/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    },
  );
}
