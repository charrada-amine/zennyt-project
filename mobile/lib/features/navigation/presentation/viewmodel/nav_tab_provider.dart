import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the index of the currently selected bottom-navigation tab for the
/// main app navigation.
class NavTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final navTabProvider = NotifierProvider<NavTabNotifier, int>(
  NavTabNotifier.new,
);
