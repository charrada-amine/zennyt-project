import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/localization/l10n_extension.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../shared/widgets/screen_top_bar.dart';
import '../../../../../shared/widgets/language_toggle.dart';
import '../../../../../core/utils/responsive.dart';
import '../../widgets/auth_desktop_shell.dart';

class ForgotPasswordMethodScreen extends StatelessWidget {
  const ForgotPasswordMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    final formContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ScreenTopBar(trailing: LanguageToggle()),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.forgotPasswordTitle,
          style: AppTypography.headlineMedium.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.chooseResetMethod,
          style: AppTypography.bodyMedium.copyWith(
            color: colors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // Email option
        _ResetMethodCard(
          icon: Icons.email_outlined,
          iconColor: colors.primary,
          title: l10n.resetViaEmail,
          subtitle: l10n.resetViaEmailDesc,
          colors: colors,
          onTap: () => context.push(AppRoutes.forgotPasswordEmail),
        ),
        const SizedBox(height: AppSpacing.md),

        // SMS option (Coming soon)
        _ResetMethodCard(
          icon: Icons.sms_outlined,
          iconColor: colors.textMuted,
          title: l10n.resetViaSms,
          subtitle: l10n.resetViaSmsDesc,
          colors: colors,
          enabled: false,
          badge: l10n.comingSoon,
          onTap: () {},
        ),
      ],
    );

    return ResponsiveBuilder(
      mobile: (context) => Scaffold(
        backgroundColor: colors.scaffoldBg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: AppSpacing.lg,
            ),
            child: formContent,
          ),
        ),
      ),
      desktop: (context) => AuthDesktopShell(
        formContent: formContent,
      ),
    );
  }
}

class _ResetMethodCard extends StatelessWidget {
  const _ResetMethodCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
    this.enabled = true,
    this.badge,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final AppColorScheme colors;
  final VoidCallback onTap;
  final bool enabled;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          color: colors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled
                ? colors.primary.withValues(alpha: 0.2)
                : colors.divider,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: AppTypography.titleSmall.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (badge != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.textMuted.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  badge!,
                                  style: AppTypography.caption.copyWith(
                                    color: colors.textMuted,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (enabled)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: colors.chevron,
                      size: 16,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
