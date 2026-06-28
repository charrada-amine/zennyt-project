import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/zennyt_switch.dart';

class AccountCenterScreen extends ConsumerStatefulWidget {
  const AccountCenterScreen({super.key});

  @override
  ConsumerState<AccountCenterScreen> createState() => _AccountCenterScreenState();
}

class _AccountCenterScreenState extends ConsumerState<AccountCenterScreen> {
  bool _securityMonitoring = false;
  bool _analyticsCookies = false;
  bool _marketingCookies = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(title: l10n.accountCenter),
              const SizedBox(height: AppSpacing.xl),
              
              _AccountCard(
                title: l10n.personalInformations,
                hideHeaderTitle: true,
                onTap: () => context.push(AppRoutes.personalInformations),
                trailing: _buildChevron(colors),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              _AccountCard(
                title: l10n.changePassword,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.currentPassword,
                          style: AppTypography.bodyMedium.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        _buildChevron(colors),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.lastUpdated('Jun 9, 2024'),
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                onTap: () => _showChangePasswordModal(context, colors, l10n),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              _AccountCard(
                title: l10n.privacyPolicy,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            l10n.securityMonitoring,
                            style: AppTypography.bodyMedium.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 28,
                          child: ZennytSwitch(
                            value: _securityMonitoring,
                            onChanged: (val) {
                              setState(() {
                                _securityMonitoring = val;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.securityMonitoringDesc,
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => context.push(AppRoutes.privacyPolicy),
                        child: Text(
                          l10n.viewPrivacyPolicy,
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              _AccountCard(
                title: l10n.cookiesPreferences,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CookiePreferenceRow(
                      title: l10n.necessaryCookies,
                      description: l10n.necessaryCookiesDesc,
                      value: true,
                      onChanged: (v) {},
                      colors: colors,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: colors.divider),
                    ),
                    _CookiePreferenceRow(
                      title: l10n.analyticsCookies,
                      description: l10n.analyticsCookiesDesc,
                      value: _analyticsCookies,
                      onChanged: (v) {
                        setState(() => _analyticsCookies = v);
                      },
                      colors: colors,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: colors.divider),
                    ),
                    _CookiePreferenceRow(
                      title: l10n.marketingCookies,
                      description: l10n.marketingCookiesDesc,
                      value: _marketingCookies,
                      onChanged: (v) {
                        setState(() => _marketingCookies = v);
                      },
                      colors: colors,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: () => _showDeleteAccountModal(context, colors, l10n),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF9E9E9E), // Grey from mockup
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.deleteAccount,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChevron(AppColorScheme colors) {
    return Icon(
      Icons.arrow_forward_ios_rounded,
      color: colors.chevron,
      size: 16,
    );
  }

  void _showChangePasswordModal(BuildContext context, AppColorScheme colors, dynamic l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: colors.scaffoldBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
            top: AppSpacing.lg,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.backButtonBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.backButtonBorder, width: 1),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: colors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      l10n.changePassword,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleLarge.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 60),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Password Last updated: Jun 9, 2024',
                style: AppTypography.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                decoration: BoxDecoration(
                  color: colors.cardSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.divider),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Current password',
                    hintStyle: AppTypography.bodyMedium.copyWith(color: colors.textMuted),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color: colors.cardSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.divider),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'New password',
                    hintStyle: AppTypography.bodyMedium.copyWith(color: colors.textMuted),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color: colors.cardSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.divider),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Confirm new password',
                    hintStyle: AppTypography.bodyMedium.copyWith(color: colors.textMuted),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Update Password',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteAccountModal(BuildContext context, AppColorScheme colors, dynamic l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: colors.scaffoldBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
            top: AppSpacing.xl,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE4EC), // Light pink/red background
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: const Color(0xFFE91E63), // Pink/red icon
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Delete Account',
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEEEEEE), // Light grey background
                    foregroundColor: colors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Yes, Delete Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD81B60), // Pink/red background
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CookiePreferenceRow extends StatelessWidget {
  const _CookiePreferenceRow({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.colors,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.primary, // Dark blue in mockup
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              height: 28,
              child: ZennytSwitch(
                value: value,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: AppTypography.bodySmall.copyWith(
            color: colors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.title,
    this.hideHeaderTitle = false,
    this.content,
    this.trailing,
    this.onTap,
  });

  final String title;
  final bool hideHeaderTitle;
  final Widget? content;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!hideHeaderTitle)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: AppTypography.titleSmall.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: colors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.divider),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: content ??
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: AppTypography.bodyMedium.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (trailing != null) trailing!,
                      ],
                    ),
              ),
            ),
          ),
        ),
      ],
    );
    
    return body;
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colors.backButtonBg,
            shape: BoxShape.circle,
            border: Border.all(color: colors.backButtonBorder, width: 1),
          ),
          child: IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: colors.backButtonIcon,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleLarge.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 60),
      ],
    );
  }
}
