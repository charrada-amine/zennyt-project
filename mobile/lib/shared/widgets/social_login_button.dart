import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// A polished outlined social-auth button (Google / GitHub) used on the login
/// & sign-up screens. White surface, soft border + subtle shadow, with the
/// brand glyph pinned to the left and the label optically centered.
class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Widget icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.cardSurface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            color: colors.cardSurface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.textPrimary.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(width: 54, child: Center(child: icon)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 54),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTypography.buttonMedium.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
