import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the index of the currently selected bottom-navigation tab for the
/// main app navigation.
class NavTabNotifier extends Notifier<int> {
  @override
  int build() {
    if (kIsWeb) {
      return 2; // Web uses same default as Windows (desktop)
    }
    if (!kIsWeb && Platform.isWindows) {
      return 2; // Default to Progress tab on Windows
    }
    return 0; // Default to Home tab on mobile
  }

  void select(int index) => state = index;
}

final navTabProvider = NotifierProvider<NavTabNotifier, int>(
  NavTabNotifier.new,
);
