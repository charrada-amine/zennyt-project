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

// ── Sidebar dimensions & animation config ──
const double _kSidebarExpandedWidth = 260;
const double _kSidebarCollapsedWidth = 78;
const Duration _kSidebarAnimDuration = Duration(milliseconds: 300);
const Curve _kSidebarAnimCurve = Curves.easeInOutCubicEmphasized;

/// The main app navigation shown after authentication. Hosts the
/// destinations in an [IndexedStack] (state is preserved across tab
/// switches). Renders a collapsible left sidebar on Windows/desktop
/// and [AppBottomNav] on mobile.
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key, this.initialTab});

  final int? initialTab;

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int? _localTab;
  bool _sidebarExpanded = true;

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

  void _toggleSidebar() =>
      setState(() => _sidebarExpanded = !_sidebarExpanded);

  @override
  Widget build(BuildContext context) {
    final tab = _localTab ?? ref.watch(navTabProvider);
    final colors = context.colors;
    final user = ref.watch(authControllerProvider).value;
    final isDesktop = Responsive.isDesktop(context);

    if (isDesktop) {
      final isExpanded = _sidebarExpanded;
      final sidebarWidth =
          isExpanded ? _kSidebarExpandedWidth : _kSidebarCollapsedWidth;

      return Scaffold(
        backgroundColor: colors.scaffoldBg,
        body: Stack(
          children: [
            Row(
              children: [
                // ── Collapsible Left Sidebar ──────────────────────────────────
                AnimatedContainer(
              duration: _kSidebarAnimDuration,
              curve: _kSidebarAnimCurve,
              width: sidebarWidth,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: colors.sidebarNav,
                border: Border(
                  right: BorderSide(
                    color: colors.divider.withValues(alpha: 0.6),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadowColor.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // ── Header: Logo ──
                  _SidebarHeader(
                    isExpanded: isExpanded,
                  ),

                  const SizedBox(height: 28),

                  // ── Navigation Items ──
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isExpanded ? 14 : 8,
                      ),
                      children: [
                        _DesktopNavItem(
                          label: 'Progress',
                          iconPath: 'assets/images/progress_unselected.png',
                          selectedIconPath:
                              'assets/images/progress_selected.png',
                          isSelected: tab == 2,
                          isCollapsed: !isExpanded,
                          onTap: () => _onTabSelect(2),
                        ),
                        const SizedBox(height: 4),
                        _DesktopNavItem(
                          label: 'Home',
                          iconPath: 'assets/images/home_unselected.png',
                          selectedIconPath: 'assets/images/home_selected.png',
                          isSelected: tab == 0,
                          isCollapsed: !isExpanded,
                          onTap: () => _onTabSelect(0),
                        ),
                        const SizedBox(height: 4),
                        _DesktopNavItem(
                          label: 'Fits',
                          iconPath: 'assets/images/fits_unselected.png',
                          selectedIconPath: 'assets/images/fits_selected.png',
                          isSelected: tab == 1,
                          isCollapsed: !isExpanded,
                          onTap: () => _onTabSelect(1),
                        ),
                        const SizedBox(height: 4),
                        _DesktopNavItem(
                          label: 'Search',
                          iconPath: 'assets/images/search_unselected.png',
                          selectedIconPath:
                              'assets/images/search_selected.png',
                          isSelected: tab == 3,
                          isCollapsed: !isExpanded,
                          onTap: () => _onTabSelect(3),
                        ),
                        const SizedBox(height: 4),
                        _DesktopNavItem(
                          label: 'Messages',
                          iconPath: 'assets/images/chat.png',
                          selectedIconPath: 'assets/images/chat.png',
                          isSelected: tab == 4,
                          isCollapsed: !isExpanded,
                          onTap: () => _onTabSelect(4),
                        ),
                        const SizedBox(height: 4),
                        _DesktopNavItem(
                          label: 'Notifications',
                          iconPath:
                              'assets/images/notification_unselected.png',
                          selectedIconPath:
                              'assets/images/notification_selected.png',
                          isSelected: tab == 7,
                          isCollapsed: !isExpanded,
                          onTap: () => _onTabSelect(7),
                        ),
                      ],
                    ),
                  ),

                  // ── Divider ──
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isExpanded ? 20 : 12,
                    ),
                    child: Divider(
                      color: colors.divider.withValues(alpha: 0.5),
                      height: 1,
                      thickness: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Bottom items: Settings and Log out ──
                  Padding(
                    padding: EdgeInsets.only(
                      left: isExpanded ? 14 : 8,
                      right: isExpanded ? 14 : 8,
                      bottom: 20,
                    ),
                    child: Column(
                      children: [
                        _DesktopBottomItem(
                          label: 'Settings',
                          iconData: Icons.settings_outlined,
                          isSelected: tab == 6,
                          isCollapsed: !isExpanded,
                          onTap: () => _onTabSelect(6),
                        ),
                        const SizedBox(height: 4),
                        _DesktopBottomItem(
                          label: 'Log out',
                          iconData: Icons.logout_outlined,
                          isSelected: false,
                          isCollapsed: !isExpanded,
                          isDestructive: true,
                          onTap: () {
                            ref
                                .read(authControllerProvider.notifier)
                                .logout();
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
                                final async =
                                    ref.watch(notificationsProvider);
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
                                          borderRadius:
                                              BorderRadius.circular(10),
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
                                    color: colors.inputFill,
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
                                if (ref
                                    .watch(notificationsProvider)
                                    .maybeWhen(
                                      data: (list) =>
                                          list.any((n) => !n.isRead),
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
                                      ? NetworkImage(
                                          user.effectiveAvatarUrl)
                                      : null,
                                  backgroundColor: colors.border,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          user?.fullName ?? 'Millie Brown',
                                          style: AppTypography.titleSmall
                                              .copyWith(
                                            color: colors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons
                                              .keyboard_arrow_down_rounded,
                                          size: 16,
                                          color: colors.textSecondary,
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Online',
                                      style:
                                          AppTypography.bodySmall.copyWith(
                                        color: colors.textSecondary
                                            .withValues(alpha: 0.7),
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
                        HomePage(), // 0
                        FitsScreen(), // 1
                        ProgressScreen(), // 2
                        SearchScreen(), // 3
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
        
        // ── Floating Toggle Arrow ──
        AnimatedPositioned(
          duration: _kSidebarAnimDuration,
          curve: _kSidebarAnimCurve,
          top: 25, // roughly centered with the logo height
          left: sidebarWidth - 13, // exactly half the 26 width outside the sidebar
          child: _SidebarToggleFloating(
            isExpanded: isExpanded,
            onToggle: _toggleSidebar,
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

// ─────────────────────────────────────────────────────────────────────────────
// SIDEBAR HEADER — Logo with crossfade
// Shows full "progress_logo.png" when expanded, "Logo.png" icon when collapsed.
// ─────────────────────────────────────────────────────────────────────────────
class _SidebarHeader extends StatefulWidget {
  const _SidebarHeader({
    required this.isExpanded,
  });

  final bool isExpanded;

  @override
  State<_SidebarHeader> createState() => _SidebarHeaderState();
}

class _SidebarHeaderState extends State<_SidebarHeader> {

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isExpanded = widget.isExpanded;

    return AnimatedPadding(
      duration: _kSidebarAnimDuration,
      curve: _kSidebarAnimCurve,
      padding: EdgeInsets.symmetric(horizontal: isExpanded ? 18 : 10),
      child: Center(
        child: ClipRect(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: isExpanded
                ? Padding(
                    key: const ValueKey('expanded-logo'),
                    padding: const EdgeInsets.only(left: 4),
                    child: Image.asset(
                      'assets/images/progress_logo.png',
                      height: 44,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Text(
                        'PROGRESS',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: colors.accent,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  )
                : Padding(
                    key: const ValueKey('collapsed-logo'),
                    padding: EdgeInsets.zero,
                    child: Image.asset(
                      'assets/images/progress_selected.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colors.accent,
                              colors.primary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'P',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SIDEBAR FLOATING TOGGLE
// A floating circular button on the border of the sidebar to expand/collapse.
// ─────────────────────────────────────────────────────────────────────────────
class _SidebarToggleFloating extends StatefulWidget {
  const _SidebarToggleFloating({
    required this.isExpanded,
    required this.onToggle,
  });

  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  State<_SidebarToggleFloating> createState() => _SidebarToggleFloatingState();
}

class _SidebarToggleFloatingState extends State<_SidebarToggleFloating> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onToggle,
        child: Tooltip(
          message: widget.isExpanded ? 'Collapse sidebar' : 'Expand sidebar',
          waitDuration: const Duration(milliseconds: 600),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: colors.scaffoldBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: _hovered ? colors.accent : colors.divider.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                if (_hovered)
                  BoxShadow(
                    color: colors.accent.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                else
                  BoxShadow(
                    color: colors.shadowColor.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Icon(
              widget.isExpanded ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
              size: 18,
              color: _hovered ? colors.accent : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DESKTOP NAV ITEM — adapts between expanded (icon + label) and collapsed
// (icon only with tooltip). Includes hover scale + highlight.
// ─────────────────────────────────────────────────────────────────────────────
class _DesktopNavItem extends StatefulWidget {
  const _DesktopNavItem({
    required this.label,
    required this.iconPath,
    required this.selectedIconPath,
    required this.isSelected,
    required this.onTap,
    this.isCollapsed = false,
  });

  final String label;
  final String iconPath;
  final String selectedIconPath;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCollapsed;

  @override
  State<_DesktopNavItem> createState() => _DesktopNavItemState();
}

class _DesktopNavItemState extends State<_DesktopNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isCollapsed = widget.isCollapsed;
    final isSelected = widget.isSelected;

    final content = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered && !isSelected ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: _kSidebarAnimDuration,
            curve: _kSidebarAnimCurve,
            height: 46,
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.accent.withValues(alpha: 0.08)
                  : _hovered
                      ? colors.textSecondary.withValues(alpha: 0.06)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Selected accent indicator bar ──
                if (isSelected)
                  Positioned(
                    left: 0,
                    child: Container(
                      width: 3.5,
                      height: 22,
                      decoration: BoxDecoration(
                        color: colors.accent,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(3),
                          bottomRight: Radius.circular(3),
                        ),
                      ),
                    ),
                  ),
                // ── Icon and label row ──
                AnimatedPadding(
                  duration: _kSidebarAnimDuration,
                  curve: _kSidebarAnimCurve,
                  padding: EdgeInsets.symmetric(
                    horizontal: isCollapsed ? 0 : 14,
                  ),
                  child: Row(
                    mainAxisAlignment: isCollapsed
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      if (!isCollapsed) const SizedBox(width: 6),
                      Image.asset(
                        isSelected
                            ? widget.selectedIconPath
                            : widget.iconPath,
                        width: 22,
                        height: 22,
                      ),
                      if (!isCollapsed) ...[
                        const SizedBox(width: 14),
                        Flexible(
                          child: Text(
                            widget.label,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: AppTypography.bodyMedium.copyWith(
                              color: isSelected
                                  ? colors.textPrimary
                                  : _hovered
                                      ? colors.textPrimary
                                          .withValues(alpha: 0.85)
                                      : colors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (isCollapsed) {
      return Tooltip(
        message: widget.label,
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 400),
        child: content,
      );
    }

    return content;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DESKTOP BOTTOM ITEM — Settings, Log out — same collapse logic.
// Supports isDestructive for logout styling.
// ─────────────────────────────────────────────────────────────────────────────
class _DesktopBottomItem extends StatefulWidget {
  const _DesktopBottomItem({
    required this.label,
    required this.iconData,
    required this.isSelected,
    required this.onTap,
    this.isCollapsed = false,
    this.isDestructive = false,
  });

  final String label;
  final IconData iconData;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCollapsed;
  final bool isDestructive;

  @override
  State<_DesktopBottomItem> createState() => _DesktopBottomItemState();
}

class _DesktopBottomItemState extends State<_DesktopBottomItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isCollapsed = widget.isCollapsed;
    final isSelected = widget.isSelected;

    // Destructive items (e.g. Log out) turn red on hover
    final hoverColor = widget.isDestructive
        ? colors.error.withValues(alpha: 0.08)
        : colors.textSecondary.withValues(alpha: 0.06);
    final iconColor = isSelected
        ? colors.accent
        : widget.isDestructive && _hovered
            ? colors.error
            : colors.textSecondary;
    final textColor = isSelected
        ? colors.textPrimary
        : widget.isDestructive && _hovered
            ? colors.error
            : colors.textSecondary;

    final content = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: _kSidebarAnimDuration,
          curve: _kSidebarAnimCurve,
          height: 44,
          padding: EdgeInsets.symmetric(
            horizontal: isCollapsed ? 0 : 14,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.accent.withValues(alpha: 0.08)
                : _hovered
                    ? hoverColor
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: isCollapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                widget.iconData,
                size: 21,
                color: iconColor,
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 14),
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: AppTypography.bodyMedium.copyWith(
                      color: textColor,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (isCollapsed) {
      return Tooltip(
        message: widget.label,
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 400),
        child: content,
      );
    }

    return content;
  }
}
