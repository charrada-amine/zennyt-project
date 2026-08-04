import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/current_user_provider.dart';
import '../viewmodel/nav_tab_provider.dart';
import 'app_nav_item.dart';

/// The app's main bottom navigation bar: Home, Fits, Progress, Search,
/// Notifications. Drives [navTabProvider].
class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({super.key, this.selectedTab, this.onSelect});

  final int? selectedTab;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = selectedTab ?? ref.watch(navTabProvider);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final colors = context.colors;
    final isRecruiter = ref.watch(currentUserProvider)?.role == UserRole.recruiter;
    final thirdTabLabel = isRecruiter ? AppStrings.tabCareers : AppStrings.tabProgress;

    void select(int i) {
      final overrideSelect = onSelect;
      if (overrideSelect != null) {
        overrideSelect(i);
        return;
      }
      ref.read(navTabProvider.notifier).select(i);
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.navBg,
        border: Border(top: BorderSide(color: colors.navBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              AppNavItem(
                label: AppStrings.tabHome,
                selected: tab == 0,
                onTap: () => select(0),
                iconBuilder: (sel) => Image.asset(
                  sel
                      ? 'assets/images/home_selected.png'
                      : 'assets/images/home_unselected.png',
                  width: 26,
                  height: 26,
                  color: !sel && isDark ? Colors.white : null,
                ),
              ),
              AppNavItem(
                label: AppStrings.tabFits,
                selected: tab == 1,
                onTap: () => select(1),
                iconBuilder: (sel) => Image.asset(
                  sel
                      ? 'assets/images/fits_selected.png'
                      : 'assets/images/fits_unselected.png',
                  width: 26,
                  height: 26,
                  color: !sel && isDark ? Colors.white : null,
                ),
              ),
              AppNavItem(
                label: thirdTabLabel,
                selected: tab == 2,
                onTap: () => select(2),
                iconBuilder: (sel) => Image.asset(
                  sel
                      ? 'assets/images/progress_selected.png'
                      : 'assets/images/progress_unselected.png',
                  width: 26,
                  height: 26,
                  color: !sel && isDark ? Colors.white : null,
                ),
              ),
              AppNavItem(
                label: AppStrings.tabSearch,
                selected: tab == 3,
                onTap: () => select(3),
                iconBuilder: (sel) => Image.asset(
                  sel
                      ? 'assets/images/search_selected.png'
                      : 'assets/images/search_unselected.png',
                  width: 26,
                  height: 26,
                  color: !sel && isDark ? Colors.white : null,
                ),
              ),
              AppNavItem(
                label: AppStrings.tabNotifications,
                selected: tab == 4,
                onTap: () => select(4),
                // Since the notification icon asset might already have a badge or we don't want the default badge over it, we omit showBadge.
                iconBuilder: (sel) => Image.asset(
                  sel
                      ? 'assets/images/notification_selected.png'
                      : 'assets/images/notification_unselected.png',
                  width: 26,
                  height: 26,
                  color: !sel && isDark ? Colors.white : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
