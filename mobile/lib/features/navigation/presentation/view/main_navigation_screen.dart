import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../fits/presentation/view/fits_screen.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../progress/presentation/view/progress_screen.dart';
import '../../../search/presentation/view/search_screen.dart';
import '../../../chat/presentation/pages/desktop_chats_page.dart';
import '../../../profile_settings/presentation/view/user_profile_screen.dart';
import '../../../profile_settings/presentation/view/desktop_settings_screen.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../viewmodel/nav_tab_provider.dart';
import '../widgets/app_bottom_nav.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';

/// The main app navigation shown after authentication. Hosts the five
/// destinations in an [IndexedStack] (state is preserved across tab
/// switches). Renders a left sidebar on Windows/desktop and [AppBottomNav] on mobile.
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

  void _onTabSelect(int index) {
    setState(() => _localTab = null);
    ref.read(navTabProvider.notifier).select(index);
  }

  @override
  Widget build(BuildContext context) {
    final tab = _localTab ?? ref.watch(navTabProvider);
    final colors = context.colors;
    final user = ref.watch(authControllerProvider).value;
    final isDesktop = Responsive.isDesktop(context);

    if (isDesktop) {
      return Scaffold(
        backgroundColor: colors.scaffoldBg,
        body: Row(
          children: [
            // ── Left Sidebar — Windows #F9FBFF via theme sidebarNav ──
            Container(
              width: 250,
              decoration: BoxDecoration(
                color: colors.sidebarNav,
                border: Border(
                  right: BorderSide(color: colors.divider),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  // Progress Careers Logo
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Image.asset(
                      'assets/images/progress_logo.png',
                      height: 50,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Text(
                        'PROGRESS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Navigation Tabs
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _DesktopNavItem(
                          label: 'Progress',
                          iconPath: 'assets/images/progress_unselected.png',
                          selectedIconPath: 'assets/images/progress_selected.png',
                          isSelected: tab == 2,
                          onTap: () => _onTabSelect(2),
                        ),
                        const SizedBox(height: 12),
                        _DesktopNavItem(
                          label: 'Home',
                          iconPath: 'assets/images/home_unselected.png',
                          selectedIconPath: 'assets/images/home_selected.png',
                          isSelected: tab == 0,
                          onTap: () => _onTabSelect(0),
                        ),
                        const SizedBox(height: 12),
                        _DesktopNavItem(
                          label: 'Fits',
                          iconPath: 'assets/images/fits_unselected.png',
                          selectedIconPath: 'assets/images/fits_selected.png',
                          isSelected: tab == 1,
                          onTap: () => _onTabSelect(1),
                        ),
                        const SizedBox(height: 12),
                        _DesktopNavItem(
                          label: 'Search',
                          iconPath: 'assets/images/search_unselected.png',
                          selectedIconPath: 'assets/images/search_selected.png',
                          isSelected: tab == 3,
                          onTap: () => _onTabSelect(3),
                        ),
                        const SizedBox(height: 12),
                        _DesktopNavItem(
                          label: 'Messages',
                          iconPath: 'assets/images/chat.png',
                          selectedIconPath: 'assets/images/chat.png',
                          isSelected: tab == 4,
                          onTap: () => _onTabSelect(4),
                        ),
                        const SizedBox(height: 12),
                        _DesktopNavItem(
                          label: 'Notifications',
                          iconPath: 'assets/images/notification_unselected.png',
                          selectedIconPath: 'assets/images/notification_selected.png',
                          isSelected: tab == 7,
                          onTap: () => _onTabSelect(7),
                        ),
                      ],
                    ),
                  ),

                  // Bottom items: Settings and Log out
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _DesktopBottomItem(
                          label: 'Settings',
                          iconData: Icons.settings_outlined,
                          isSelected: tab == 6,
                          onTap: () => _onTabSelect(6),
                        ),
                        const SizedBox(height: 16),
                        _DesktopBottomItem(
                          label: 'Log out',
                          iconData: Icons.logout_outlined,
                          isSelected: false,
                          onTap: () {
                            ref.read(authControllerProvider.notifier).logout();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Main Content Area ───────────────────────────────────────────
            Expanded(
              child: Column(
                children: [
                  // Global Top Bar — Messages (4) & Notifications (7) show title
                  // on the left at same level as profile (reference design)
                  if (tab != 0)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: (tab == 4 || tab == 7) ? 24 : 40,
                        vertical: 14,
                      ),
                      decoration: (tab == 4 || tab == 7)
                          ? BoxDecoration(
                              color: colors.cardSurface,
                              border: Border(
                                bottom: BorderSide(color: colors.divider),
                              ),
                            )
                          : null,
                      child: Row(
                        children: [
                          if (tab == 4)
                            Text(
                              'Messages',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            )
                          else if (tab == 7)
                            Builder(
                              builder: (context) {
                                final async = ref.watch(notificationsProvider);
                                final count = async.maybeWhen(
                                  data: (list) =>
                                      list.where((n) => !n.isRead).length,
                                  orElse: () => 0,
                                );
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Notifications',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    if (count > 0) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: colors.accent,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '$count new',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            )
                          else
                            const Spacer(),
                          if (tab == 4 || tab == 7) const Spacer(),
                          // Notification icon — tapping navigates to Notifications tab (7)
                          GestureDetector(
                            onTap: () => _onTabSelect(7),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: tab == 7
                                        ? colors.inputFill
                                        : colors.inputFill,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.notifications_none_rounded,
                                    color: tab == 7
                                        ? colors.accent
                                        : colors.textSecondary,
                                    size: 24,
                                  ),
                                ),
                                if (ref.watch(notificationsProvider).maybeWhen(
                                      data: (list) => list.any((n) => !n.isRead),
                                      orElse: () => false,
                                    ))
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: colors.accent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),

                          // Profile Card
                          GestureDetector(
                            onTap: () {
                              _onTabSelect(5);
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: user != null
                                      ? NetworkImage(user.effectiveAvatarUrl)
                                      : null,
                                  backgroundColor: colors.border,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          user?.fullName ?? 'Millie Brown',
                                          style: AppTypography.titleSmall.copyWith(
                                            color: colors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 16,
                                          color: colors.textSecondary,
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Online',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: colors.textSecondary.withValues(alpha: 0.7),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // IndexedStack Page Content
                  Expanded(
                    child: IndexedStack(
                      index: tab,
                      children: const [
                        HomePage(),         // 0
                        FitsScreen(),       // 1
                        ProgressScreen(),   // 2
                        SearchScreen(),     // 3
                        DesktopChatsPage(), // 4
                        UserProfileScreen(), // 5
                        DesktopSettingsScreen(), // 6
                        NotificationsPage(), // 7
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: IndexedStack(
        index: tab,
        children: const [
          HomePage(),
          FitsScreen(),
          ProgressScreen(),
          SearchScreen(),
          NotificationsPage()
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        selectedTab: tab,
        onSelect: _onTabSelect,
      ),
    );
  }
}

class _DesktopNavItem extends StatelessWidget {
  const _DesktopNavItem({
    required this.label,
    required this.iconPath,
    required this.selectedIconPath,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String iconPath;
  final String selectedIconPath;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? colors.inputFill : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isSelected)
              Positioned(
                left: 0,
                child: Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(2),
                      bottomRight: Radius.circular(2),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Image.asset(
                    isSelected ? selectedIconPath : iconPath,
                    width: 22,
                    height: 22,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    label,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isSelected ? colors.textPrimary : colors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopBottomItem extends StatelessWidget {
  const _DesktopBottomItem({
    required this.label,
    required this.iconData,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData iconData;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? colors.inputFill : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                iconData,
                size: 22,
                color: isSelected ? colors.accent : colors.textSecondary,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: isSelected ? colors.textPrimary : colors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
