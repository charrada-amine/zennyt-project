import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../widgets/profile_action_cards.dart';
import '../widgets/settings_menu_list.dart';

// ─── Selected panel enum ───────────────────────────────────────────────────────

enum _SettingsPanel { referral, accountCenter, accessibility, notifications, theme, helpCenter, termsOfService }

// ─── Desktop Settings Screen ──────────────────────────────────────────────────

/// Two-panel Settings layout for Windows/desktop.
/// Left: menu card with action cards + GENERAL / PREFERENCES / SUPPORT.
/// Right: detail content for the selected item.
class DesktopSettingsScreen extends ConsumerStatefulWidget {
  const DesktopSettingsScreen({super.key});

  @override
  ConsumerState<DesktopSettingsScreen> createState() =>
      _DesktopSettingsScreenState();
}

class _DesktopSettingsScreenState
    extends ConsumerState<DesktopSettingsScreen> {
  _SettingsPanel _selected = _SettingsPanel.referral;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        // ── Left panel ──────────────────────────────────────────────────────
        _LeftPanel(
          selected: _selected,
          onSelect: (panel) => setState(() => _selected = panel),
        ),

        // ── Divider ─────────────────────────────────────────────────────────
        VerticalDivider(width: 1, thickness: 1, color: colors.divider),

        // ── Right panel ─────────────────────────────────────────────────────
        Expanded(
          child: _RightPanel(selected: _selected),
        ),
      ],
    );
  }
}

// ─── Left Panel ───────────────────────────────────────────────────────────────

class _LeftPanel extends ConsumerWidget {
  const _LeftPanel({required this.selected, required this.onSelect});

  final _SettingsPanel selected;
  final ValueChanged<_SettingsPanel> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final notifEnabled = ref.watch(notificationsEnabledProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return SizedBox(
      width: 320,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              l10n.profileAndSettings,
              style: AppTypography.titleLarge.copyWith(
                color: colors.textDarkBlue,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 24),

            // Action cards row
            const ProfileActionCards(),
            const SizedBox(height: 24),

            // ── GENERAL ─────────────────────────────────────────────────────
            const _SectionHeader(label: 'GENERAL'),
            const SizedBox(height: 8),
            _MenuCard(
              children: [
                _MenuItem(
                  iconAsset: 'assets/images/referral.png',
                  iconBg: AppColors.iconPurple,
                  label: l10n.referral,
                  trailing: _chevron(colors),
                  isSelected: selected == _SettingsPanel.referral,
                  onTap: () => onSelect(_SettingsPanel.referral),
                ),
                _MenuDivider(colors: colors),
                _MenuItem(
                  iconAsset: 'assets/images/account_center.png',
                  iconBg: Colors.transparent,
                  isFullIcon: true,
                  label: l10n.accountCenter,
                  trailing: _chevron(colors),
                  isSelected: selected == _SettingsPanel.accountCenter,
                  onTap: () => onSelect(_SettingsPanel.accountCenter),
                ),
                _MenuDivider(colors: colors),
                _MenuItem(
                  iconAsset: 'assets/images/accessibility.png',
                  iconBg: AppColors.iconDeepPurple,
                  label: l10n.accessibility,
                  trailing: _chevron(colors),
                  isSelected: selected == _SettingsPanel.accessibility,
                  onTap: () => onSelect(_SettingsPanel.accessibility),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── PREFERENCES ─────────────────────────────────────────────────
            const _SectionHeader(label: 'PREFERENCES'),
            const SizedBox(height: 8),
            _MenuCard(
              children: [
                _MenuItem(
                  iconAsset: 'assets/images/notification_unselected.png',
                  iconBg: AppColors.iconBlue,
                  label: l10n.notifications,
                  trailing: SizedBox(
                    height: 28,
                    child: FittedBox(
                      child: CupertinoSwitch(
                        value: notifEnabled,
                        activeTrackColor: colors.success,
                        onChanged: (val) {
                          ref
                              .read(notificationsEnabledProvider.notifier)
                              .set(val);
                        },
                      ),
                    ),
                  ),
                  isSelected: selected == _SettingsPanel.notifications,
                  onTap: () => onSelect(_SettingsPanel.notifications),
                ),
                _MenuDivider(colors: colors),
                _MenuItem(
                  iconAsset: 'assets/images/theme.png',
                  iconBg: AppColors.iconBlack,
                  label: l10n.theme,
                  trailing: SizedBox(
                    height: 28,
                    child: FittedBox(
                      child: CupertinoSwitch(
                        value: isDark,
                        activeTrackColor: colors.success,
                        onChanged: (val) {
                          ref.read(themeProvider.notifier).setMode(
                                val ? ThemeMode.dark : ThemeMode.light,
                              );
                        },
                      ),
                    ),
                  ),
                  isSelected: selected == _SettingsPanel.theme,
                  onTap: () => onSelect(_SettingsPanel.theme),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── SUPPORT ─────────────────────────────────────────────────────
            const _SectionHeader(label: 'SUPPORT'),
            const SizedBox(height: 8),
            _MenuCard(
              children: [
                _MenuItem(
                  iconAsset: 'assets/images/help_center.png',
                  iconBg: AppColors.iconMediumBlue,
                  label: l10n.helpCenter,
                  trailing: _chevron(colors),
                  isSelected: selected == _SettingsPanel.helpCenter,
                  onTap: () => onSelect(_SettingsPanel.helpCenter),
                ),
                _MenuDivider(colors: colors),
                _MenuItem(
                  iconAsset: 'assets/images/block.png',
                  iconBg: AppColors.iconGrey,
                  label: l10n.termsOfServiceAndConditions,
                  trailing: _chevron(colors),
                  isSelected: selected == _SettingsPanel.termsOfService,
                  onTap: () => onSelect(_SettingsPanel.termsOfService),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chevron(AppColorScheme colors) => Icon(
        Icons.arrow_forward_ios_rounded,
        color: colors.chevron,
        size: 14,
      );
}

// ─── Right Panel ──────────────────────────────────────────────────────────────

class _RightPanel extends ConsumerStatefulWidget {
  const _RightPanel({required this.selected});

  final _SettingsPanel selected;

  @override
  ConsumerState<_RightPanel> createState() => _RightPanelState();
}

class _RightPanelState extends ConsumerState<_RightPanel> {
  // Accessibility state
  bool _contrastEnabled = true;
  double _textSize = 18.0;

  // Account Center state
  bool _securityMonitoring = false;
  bool _necessaryCookies = true;
  bool _analyticsCookies = false;
  bool _marketingCookies = false;
  bool _showDeleteConfirmation = false;

  @override
  void didUpdateWidget(covariant _RightPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      _showDeleteConfirmation = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      color: colors.scaffoldBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(40, 32, 40, 32),
        child: _buildContent(context, colors),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppColorScheme colors) {
    if (_showDeleteConfirmation && widget.selected == _SettingsPanel.accountCenter) {
      return _buildDeleteConfirmationPanel(context, colors);
    }
    switch (widget.selected) {
      case _SettingsPanel.referral:
        return _buildReferralPanel(context, colors);
      case _SettingsPanel.accountCenter:
        return _buildAccountCenterPanel(context, colors);
      case _SettingsPanel.accessibility:
        return _buildAccessibilityPanel(context, colors);
      case _SettingsPanel.notifications:
        return _buildNotificationsPanel(context, colors);
      case _SettingsPanel.theme:
        return _buildThemePanel(context, colors);
      case _SettingsPanel.helpCenter:
        return _buildHelpCenterPanel(context, colors);
      case _SettingsPanel.termsOfService:
        return _buildTermsOfServicePanel(context, colors);
    }
  }

  // ── Referral Panel ──────────────────────────────────────────────────────────

  Widget _buildReferralPanel(BuildContext context, AppColorScheme colors) {
    final l10n = context.l10n;
    final referrals = <_ReferralItem>[];

    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.referral,
          style: AppTypography.titleLarge.copyWith(
            color: colors.textDarkBlue,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 20),
        if (referrals.isEmpty)
          SizedBox(
            height: 350,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 64,
                    color: colors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isFr ? 'Aucun parrainage pour le moment' : 'No referrals yet',
                    style: AppTypography.titleMedium.copyWith(
                      color: colors.textDarkBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isFr ? 'Invitez vos amis pour commencer à gagner.' : 'Invite your friends to start earning.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...referrals.map((item) => _buildReferralRow(context, colors, item)),
      ],
    );
  }

  Widget _buildReferralRow(
    BuildContext context,
    AppColorScheme colors,
    _ReferralItem item,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Avatar placeholder
          CircleAvatar(
            radius: 22,
            backgroundColor: colors.inputFill,
            child: Icon(Icons.person, color: colors.textSecondary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.textDarkBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.role,
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Status badge
          if (item.status == _ReferralStatus.inProgress) ...[
            _StatusBadge(
              label: 'In progress',
              bgColor: colors.inputFill,
              textColor: colors.textSecondary,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.inputFill,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'D-${item.daysLeft}',
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.access_time_rounded,
                      size: 12, color: colors.textSecondary),
                ],
              ),
            ),
          ] else
            _StatusBadge(
              label: 'Hired',
              bgColor: colors.brandIndigo,
              textColor: Colors.white,
            ),
        ],
      ),
    );
  }

  // ── Account Center Panel ────────────────────────────────────────────────────

  Widget _buildAccountCenterPanel(
      BuildContext context, AppColorScheme colors) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.accountCenter,
          style: AppTypography.titleLarge.copyWith(
            color: colors.textDarkBlue,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 20),

        // Personal Informations
        _DetailCard(
          child: InkWell(
            onTap: () => context.push(AppRoutes.personalInformations),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Text(
                    l10n.personalInformations,
                    style: AppTypography.bodyMedium.copyWith(
                      color: colors.textDarkBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: colors.chevron),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Change Password
        Text(
          l10n.changePassword,
          style: AppTypography.bodyMedium.copyWith(
            color: colors.textDarkBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _DetailCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.currentPassword,
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: colors.chevron),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.lastUpdated(
                    Localizations.localeOf(context).languageCode == 'fr'
                        ? '20 août 2026'
                        : 'Aug 20, 2026',
                  ),
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Privacy Policy
        Text(
          l10n.privacyPolicy,
          style: AppTypography.bodyMedium.copyWith(
            color: colors.textDarkBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _DetailCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.securityMonitoring,
                            style: AppTypography.bodyMedium.copyWith(
                              color: colors.textDarkBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.securityMonitoringDesc,
                            style: AppTypography.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      height: 28,
                      child: FittedBox(
                        child: CupertinoSwitch(
                          value: _securityMonitoring,
                          activeTrackColor: colors.success,
                          onChanged: (val) =>
                              setState(() => _securityMonitoring = val),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.privacyPolicy),
                  child: Text(
                    l10n.viewPrivacyPolicy,
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.linkColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Cookies preferences
        Text(
          l10n.cookiesPreferences,
          style: AppTypography.bodyMedium.copyWith(
            color: colors.textDarkBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _DetailCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _CookieRow(
                  title: l10n.necessaryCookies,
                  subtitle: l10n.necessaryCookiesDesc,
                  value: _necessaryCookies,
                  onChanged: (val) =>
                      setState(() => _necessaryCookies = val),
                  colors: colors,
                ),
                Divider(color: colors.divider, height: 16),
                _CookieRow(
                  title: l10n.analyticsCookies,
                  subtitle: l10n.analyticsCookiesDesc,
                  value: _analyticsCookies,
                  onChanged: (val) =>
                      setState(() => _analyticsCookies = val),
                  colors: colors,
                ),
                Divider(color: colors.divider, height: 16),
                _CookieRow(
                  title: l10n.marketingCookies,
                  subtitle: l10n.marketingCookiesDesc,
                  value: _marketingCookies,
                  onChanged: (val) =>
                      setState(() => _marketingCookies = val),
                  colors: colors,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Delete Account button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _showDeleteConfirmation = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.inputFill,
              foregroundColor: colors.textSecondary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l10n.deleteAccount,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteConfirmationPanel(BuildContext context, AppColorScheme colors) {
    final l10n = context.l10n;
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular trash bin icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              color: colors.error,
              size: 36,
            ),
          ),
          const SizedBox(height: 24),
          
          // Title
          Text(
            isFr ? 'Supprimer le compte' : 'Delete Account',
            style: AppTypography.titleLarge.copyWith(
              color: colors.textDarkBlue,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 16),
          
          // Message
          Text(
            isFr
                ? 'Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible et toutes vos données seront définitivement supprimées.'
                : 'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          
          // Action Buttons
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              children: [
                // Yes, Delete Account (Destructive Style)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(authControllerProvider.notifier).logout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.inputFill,
                      foregroundColor: colors.error,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isFr ? 'Oui, Supprimer le compte' : 'Yes, Delete Account',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Cancel Button (Filled Accent Color)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showDeleteConfirmation = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isFr ? 'Annuler' : 'Cancel',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Accessibility Panel ─────────────────────────────────────────────────────

  Widget _buildAccessibilityPanel(
      BuildContext context, AppColorScheme colors) {
    final l10n = context.l10n;
    final currentLanguage =
        Localizations.localeOf(context).languageCode == 'fr'
            ? 'Français'
            : 'English';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.accessibility,
          style: AppTypography.titleLarge.copyWith(
            color: colors.textDarkBlue,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 20),

        // Language row
        _DetailCard(
          child: InkWell(
            onTap: () => context.push(AppRoutes.languageSettings),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.language,
                        style: AppTypography.bodyMedium.copyWith(
                          color: colors.textDarkBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentLanguage,
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      color: colors.chevron, size: 20),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Contrast row
        _DetailCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Text(
                  l10n.contrast,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.textDarkBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 28,
                  child: FittedBox(
                    child: CupertinoSwitch(
                      value: _contrastEnabled,
                      activeTrackColor: colors.success,
                      onChanged: (val) =>
                          setState(() => _contrastEnabled = val),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Text Size
        _DetailCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.textSize,
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.textDarkBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_textSize.toInt()} px',
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.placeholderBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _SliderButton(
                        colors: colors,
                        icon: Icons.remove,
                        onTap: () {
                          if (_textSize > 10) {
                            setState(() => _textSize -= 1);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: colors.accent,
                            inactiveTrackColor: colors.divider,
                            thumbColor: colors.accent,
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                            overlayShape: SliderComponentShape.noOverlay,
                          ),
                          child: Slider(
                            value: _textSize,
                            min: 10,
                            max: 30,
                            onChanged: (val) =>
                                setState(() => _textSize = val),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SliderButton(
                        colors: colors,
                        icon: Icons.add,
                        onTap: () {
                          if (_textSize < 30) {
                            setState(() => _textSize += 1);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Preview
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.placeholderBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.preview,
                style: AppTypography.labelSmall.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.accessibilityPreviewText,
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.textDarkBlue,
                  fontSize: _textSize,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Notifications panel (preferences toggle) ─────────────────────────────

  Widget _buildNotificationsPanel(
      BuildContext context, AppColorScheme colors) {
    final l10n = context.l10n;
    final notifEnabled = ref.watch(notificationsEnabledProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.notifications,
          style: AppTypography.titleLarge.copyWith(
            color: colors.textDarkBlue,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 20),
        _DetailCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.notifications,
                        style: AppTypography.bodyMedium.copyWith(
                          color: colors.textDarkBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Receive push notifications from the app',
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 28,
                  child: FittedBox(
                    child: CupertinoSwitch(
                      value: notifEnabled,
                      activeTrackColor: colors.success,
                      onChanged: (val) {
                        ref
                            .read(notificationsEnabledProvider.notifier)
                            .set(val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Theme panel ─────────────────────────────────────────────────────────────

  Widget _buildThemePanel(BuildContext context, AppColorScheme colors) {
    final l10n = context.l10n;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.theme,
          style: AppTypography.titleLarge.copyWith(
            color: colors.textDarkBlue,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 20),
        _DetailCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.theme,
                        style: AppTypography.bodyMedium.copyWith(
                          color: colors.textDarkBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isDark ? 'Dark mode enabled' : 'Light mode enabled',
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 28,
                  child: FittedBox(
                    child: CupertinoSwitch(
                      value: isDark,
                      activeTrackColor: colors.success,
                      onChanged: (val) {
                        ref.read(themeProvider.notifier).setMode(
                              val ? ThemeMode.dark : ThemeMode.light,
                            );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Help Center Panel ─────────────────────────────────────────────────────

  Widget _buildHelpCenterPanel(BuildContext context, AppColorScheme colors) {
    final l10n = context.l10n;
    final isFr = Localizations.localeOf(context).languageCode == 'fr';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.helpCenter,
          style: AppTypography.titleLarge.copyWith(
            color: colors.textDarkBlue,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 350,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.support_agent_rounded,
                  size: 64,
                  color: colors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  isFr ? 'Aucune conversation' : 'No conversations yet',
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.textDarkBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isFr
                      ? 'Contactez notre équipe de support pour obtenir de l\'aide.'
                      : 'Contact our support team if you need help.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Terms of Service Panel ────────────────────────────────────────────────

  Widget _buildTermsOfServicePanel(BuildContext context, AppColorScheme colors) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.termsOfServiceAndConditions,
          style: AppTypography.titleLarge.copyWith(
            color: colors.textDarkBlue,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              Text(
                'Progress Careers',
                style: AppTypography.titleMedium.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Corporate Privacy Policy',
                style: AppTypography.titleMedium.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Last Updated: [30/02/2026]',
          style: AppTypography.bodySmall.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Version: Corporate International Edition',
          style: AppTypography.bodySmall.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        _buildPolicySection(colors, '1. DATA CONTROLLER',
            'Progress Careers operates through affiliated entities established in:\n'
            '- France (Paris)\n'
            '- United States (Delaware)\n'
            '- United Arab Emirates (Dubai)\n'
            'The relevant entity acting as Data Controller depends on the user\'s location and the contractual relationship established.\n'
            'For all privacy-related matters: privacy@progresscareers.com'),
        _buildPolicySection(colors, '2. SCOPE OF APPLICATION',
            'This Privacy Policy applies to Candidates, Students, Recruiters, Employers, Ambassadors, and Website Visitors.\n'
            'It covers all personal data processed through:\n'
            '- The recruitment platform\n'
            '- Psychometric (soft skills) games\n'
            '- Technical (hard skills) assessments\n'
            '- Artificial intelligence systems\n'
            '- Video interviews\n'
            '- Social networking features\n'
            '- Payment and escrow services'),
        _buildPolicySection(colors, '3. TYPES OF DATA COLLECTED',
            '- Identity data: full name, photo, nationality\n'
            '- Contact data: email, phone number, address\n'
            '- Professional data: CV, work experience, education\n'
            '- Assessment data: game scores, skill metrics\n'
            '- Technical data: IP address, device info, browser type\n'
            '- Usage data: platform interactions, feature usage'),
        _buildPolicySection(colors, '4. YOUR RIGHTS',
            'Under applicable data protection laws, you have the right to:\n'
            '- Access your personal data\n'
            '- Rectify inaccurate data\n'
            '- Delete your data ("right to be forgotten")\n'
            '- Restrict processing\n'
            '- Data portability\n'
            '- Object to processing\n'
            '- Withdraw consent at any time'),
      ],
    );
  }

  Widget _buildPolicySection(
      AppColorScheme colors, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              color: colors.textDarkBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: AppTypography.bodySmall.copyWith(
              color: colors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small helper widgets ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
      ),
      child: Column(children: children),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider({required this.colors});
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, color: colors.divider);
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    this.iconAsset,
    required this.iconBg,
    this.isFullIcon = false,
    required this.label,
    required this.trailing,
    this.isSelected = false,
    required this.onTap,
  });

  final String? iconAsset;
  final Color iconBg;
  final bool isFullIcon;
  final String label;
  final Widget trailing;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? colors.inputFill : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: iconAsset != null
                      ? Image.asset(
                          iconAsset!,
                          width: isFullIcon ? 32 : 18,
                          height: isFullIcon ? 32 : 18,
                          color: isFullIcon ? null : Colors.white,
                        )
                      : const SizedBox(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.menuLabelText,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  final String label;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _CookieRow extends StatelessWidget {
  const _CookieRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.colors,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.textDarkBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 28,
          child: FittedBox(
            child: CupertinoSwitch(
              value: value,
              activeTrackColor: colors.success,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _SliderButton extends StatelessWidget {
  const _SliderButton({
    required this.colors,
    required this.icon,
    required this.onTap,
  });

  final AppColorScheme colors;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: colors.cardSurface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colors.shadowColor.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 15, color: colors.textPrimary),
      ),
    );
  }
}

// ─── Data models ──────────────────────────────────────────────────────────────

enum _ReferralStatus { inProgress, hired }

class _ReferralItem {
  const _ReferralItem({
    required this.name,
    required this.role,
    required this.timeAgo,
    required this.status,
    this.daysLeft,
  });

  final String name;
  final String role;
  final String timeAgo;
  final _ReferralStatus status;
  final int? daysLeft;
}
