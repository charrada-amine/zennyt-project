import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedFilterNotifier extends Notifier<String> {
  @override
  String build() => 'UX/UI Designer';

  void updateFilter(String newFilter) {
    state = newFilter;
  }
}

final selectedFilterProvider = NotifierProvider<SelectedFilterNotifier, String>(
  SelectedFilterNotifier.new,
);