import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import 'zennyt_logo.dart';
import 'app_motion.dart';

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
    return AppReveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLogo) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.cardSurface,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: .07),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const ZennytLogo(
                size: 44,
                axis: Axis.horizontal,
                showTagline: true,
              ),
            ),
            const SizedBox(height: 32),
          ],
          Text(
            title,
            textAlign: TextAlign.start,
            style: AppTypography.displaySmall.copyWith(
              color: colors.textDarkBlue,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
              height: 1.15,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle!,
              textAlign: TextAlign.start,
              style: AppTypography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
