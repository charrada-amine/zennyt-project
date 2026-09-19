import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/current_user_provider.dart';
import '../viewmodel/nav_tab_provider.dart';
import 'app_nav_item.dart';
import 'package:zennyt/shared/icons/app_icons.dart';
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
    final colors = context.colors;
    final isRecruiter =
        ref.watch(currentUserProvider)?.role == UserRole.recruiter;
    final thirdTabLabel = isRecruiter
        ? AppStrings.tabCareers
        : AppStrings.tabProgress;
    final thirdTabIcon = isRecruiter
        ? HugeIcons.strokeRoundedBriefcase01
        : HugeIcons.strokeRoundedAnalyticsUp;

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

    // Barre ancrée pleine largeur (même surface d'un bord à l'autre, filet
    // en haut) : la version « pilule flottante » laissait une bande blanche
    // sous elle et coupait le contenu net au-dessus.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.navBg,
        border: Border(top: BorderSide(color: colors.navBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 6),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
          child: Row(
            children: [
              AppNavItem(
                label: AppStrings.tabHome,
                selected: tab == 0,
                onTap: () => select(0),
                icon: HugeIcons.strokeRoundedHome01,
              ),
              AppNavItem(
                label: AppStrings.tabFits,
                selected: tab == 1,
                onTap: () => select(1),
                icon: HugeIcons.strokeRoundedThumbsUp,
              ),
              AppNavItem(
                label: thirdTabLabel,
                selected: tab == 2,
                onTap: () => select(2),
                icon: thirdTabIcon,
              ),
              AppNavItem(
                label: AppStrings.tabSearch,
                selected: tab == 3,
                onTap: () => select(3),
                icon: HugeIcons.strokeRoundedSearch01,
              ),
              AppNavItem(
                label: AppStrings.tabNotifications,
                selected: tab == 4,
                onTap: () => select(4),
                icon: HugeIcons.strokeRoundedNotification01,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
