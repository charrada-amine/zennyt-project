import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/audio/sound_service.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../shared/widgets/zennyt_logo.dart';
import '../../../../shared/widgets/session_avatar.dart';
import '../../../auth/presentation/current_user_provider.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../viewmodel/nav_tab_provider.dart';

/// Density of the persistent tablet navigation.
enum SideNavDensity { rail, expanded }

/// A single destination in the side navigation.
class SideNavItem {
  const SideNavItem({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.selected = false,
  });

  final String label;
  final Widget icon;
  final VoidCallback onSelected;
  final bool selected;
}

/// Persistent left navigation shown on tablets (>= [Responsive
/// .tabletBreakpoint]). Mirrors the tablet maquette: logo at top, navy labels,
/// magenta active stripe on the leading edge, session avatar + log out at the
/// bottom. Icons reuse the exact PNG pairs of [AppBottomNav] so the two shells
/// stay visually consistent.
class AppSideNav extends ConsumerWidget {
  const AppSideNav({super.key, this.expanded = false, this.initialTab});

  final bool expanded;
  final int? initialTab;

  static const double railWidth = 88;
  static const double expandedWidth = 232;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final isRecruiter =
        ref.watch(currentUserProvider)?.role == UserRole.recruiter;
    final thirdTabLabel =
        isRecruiter ? AppStrings.tabCareers : AppStrings.tabProgress;
    final tab = initialTab ?? ref.watch(navTabProvider);
    final width = expanded ? expandedWidth : railWidth;

    Widget navIcon(int index, bool sel) {
      const assets = [
        ['assets/images/home_selected.png', 'assets/images/home_unselected.png'],
        ['assets/images/fits_selected.png', 'assets/images/fits_unselected.png'],
        [
          'assets/images/progress_selected.png',
          'assets/images/progress_unselected.png'
        ],
        [
          'assets/images/search_selected.png',
          'assets/images/search_unselected.png'
        ],
        [
          'assets/images/notification_selected.png',
          'assets/images/notification_unselected.png'
        ],
      ];
      final pair = assets[index];
      return Image.asset(
        sel ? pair[0] : pair[1],
        width: 24,
        height: 24,
        color: !sel && isDark ? Colors.white : null,
      );
    }

    final labels = [
      AppStrings.tabHome,
      AppStrings.tabFits,
      thirdTabLabel,
      AppStrings.tabSearch,
      AppStrings.tabNotifications,
    ];

    void select(int i) {
      if (kLot1DemoBuild && i != kLot1DemoTabIndex) return;
      if (i == tab) return;
      SoundService.instance.vibrateSelection();
      ref.read(navTabProvider.notifier).select(i);
    }

    return Container(
      width: width,
      color: colors.sidebarNav,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: ZennytLogo(
                size: expanded ? 46 : 34,
                showWordmark: expanded,
                showTagline: expanded,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            for (var i = 0; i < labels.length; i++)
              _SideNavEntry(
                label: labels[i],
                icon: navIcon(i, tab == i),
                selected: tab == i,
                expanded: expanded,
                onTap: () => select(i),
              ),
            const Spacer(),
            if (expanded)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _SideAccountFooter(),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Center(child: const SessionAvatar()),
              ),
          ],
        ),
      ),
    );
  }
}

class _SideNavEntry extends StatelessWidget {
  const _SideNavEntry({
    required this.label,
    required this.icon,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final content = expanded
        ? Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 14),
            child: Row(
              children: [
                icon,
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleSmall.copyWith(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? colors.textDarkBlue : colors.navLabelUnselected,
                    ),
                  ),
                ),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? colors.textDarkBlue : colors.navLabelUnselected,
                  ),
                ),
              ],
            ),
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: selected ? colors.activeBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 10,
              bottom: 10,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: selected ? colors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            content,
          ],
        ),
      ),
    );
  }
}

class _SideAccountFooter extends ConsumerWidget {
  const _SideAccountFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 24, thickness: 1, color: colors.divider),
        Row(
          children: [
            const SessionAvatar(),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                ref.watch(currentUserProvider)?.fullName ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleSmall.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textDarkBlue,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Log out',
              onPressed: () => ref.read(authControllerProvider.notifier).logout(),
              icon: Image.asset('assets/images/logout.png',
                  width: 22, height: 22, color: colors.iconDefault),
            ),
          ],
        ),
      ],
    );
  }
}
