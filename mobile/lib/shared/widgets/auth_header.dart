import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import 'zennyt_logo.dart';

/// Shared header used at the top of auth / sign-up screens: the centered
/// ZENNYT logo, a title and an optional subtitle.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showLogo = true,
  });

  final String title;
  final String? subtitle;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showLogo) ...[
          const ZennytLogo(size: 44, showTagline: true),
          const SizedBox(height: AppSpacing.xl),
        ],
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
