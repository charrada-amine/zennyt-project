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
class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(navTabProvider);
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
      bottomNavigationBar: const AppBottomNav(),
    );
  }
}
