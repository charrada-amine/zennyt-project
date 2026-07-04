import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../fits/presentation/view/fits_screen.dart';
import '../../../home/presentation/view/home_screen.dart';
import '../../../notifications/presentation/view/notifications_screen.dart';
import '../../../progress/presentation/view/progress_screen.dart';
import '../../../search/presentation/view/search_screen.dart';
import '../../../../core/theme/theme.dart';
import '../viewmodel/nav_tab_provider.dart';
import '../widgets/app_bottom_nav.dart';

/// The main app navigation shown after authentication. Hosts the five
/// bottom-nav destinations in an [IndexedStack] (state is preserved across tab
/// switches) and renders the shared [AppBottomNav].
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key, this.initialTab});

  final int? initialTab;

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int? _localTab;

  @override
  void initState() {
    super.initState();
    _localTab = widget.initialTab;
  }

  @override
  void didUpdateWidget(covariant MainNavigationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final initialTab = widget.initialTab;
    if (initialTab != null && initialTab != oldWidget.initialTab) {
      _localTab = initialTab;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tab = _localTab ?? ref.watch(navTabProvider);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: IndexedStack(
        index: tab,
        children: const [
          HomeScreen(),
          FitsScreen(),
          ProgressScreen(),
          SearchScreen(),
          NotificationsScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        selectedTab: tab,
        onSelect: (index) {
          setState(() => _localTab = null);
          ref.read(navTabProvider.notifier).select(index);
        },
      ),
    );
  }
}
