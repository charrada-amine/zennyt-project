import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/current_user_provider.dart';
import '../viewmodel/nav_tab_provider.dart';
import 'app_nav_item.dart';
import '../../../../core/audio/sound_service.dart';

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
    final isRecruiter =
        ref.watch(currentUserProvider)?.role == UserRole.recruiter;
    final thirdTabLabel = isRecruiter
        ? AppStrings.tabCareers
        : AppStrings.tabProgress;

    void select(int i) {
      // Build de démo « Lot 1 » : seul l'onglet qui porte les jeux répond.
      // Les autres restent VISIBLES (la barre doit rester celle du vrai
      // produit, c'est ce qu'on fait valider) mais inertes : le livrable sert
      // à valider l'UI et le gameplay des jeux, pas des écrans encore en
      // chantier. Verrou posé ici, au point de passage unique, pour qu'aucun
      // item de la barre ne puisse le contourner.
      if (kLot1DemoBuild && i != kLot1DemoTabIndex) return;

      if (i == tab) return;
      SoundService.instance.vibrateSelection();
      final overrideSelect = onSelect;
      if (overrideSelect != null) {
        overrideSelect(i);
        return;
      }
      ref.read(navTabProvider.notifier).select(i);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: colors.navBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.navBorder),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: .08),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
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
