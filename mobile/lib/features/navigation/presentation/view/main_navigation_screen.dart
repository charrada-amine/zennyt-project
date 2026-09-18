import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../fits/presentation/view/fits_screen.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../progress/presentation/view/progress_screen.dart';
import '../../../search/presentation/view/search_screen.dart';
import '../viewmodel/nav_tab_provider.dart';
import '../widgets/adaptive_nav_shell.dart';

/// The main app navigation shown after authentication. Hosts the five
/// destinations in an [IndexedStack] (state is preserved across tab switches)
/// wrapped in [AdaptiveNavShell], which renders the floating bottom bar on
/// phones and the persistent side navigation on tablets/desktop, both driven
/// by [navTabProvider].
class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key, this.initialTab});

  final int? initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdaptiveNavShell(
      initialTab: initialTab,
      pages: const [
        HomePage(),
        FitsScreen(),
        ProgressScreen(),
        SearchScreen(),
        NotificationsPage()
      ],
    );
  }
}
