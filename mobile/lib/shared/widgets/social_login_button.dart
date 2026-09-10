import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../core/audio/sound_service.dart';
import 'app_motion.dart';

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
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppPressScale(
      enabled: onPressed != null,
      child: Material(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onPressed == null
              ? null
              : () {
                  SoundService.instance.vibrateSelection();
                  onPressed!();
                },
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: colors.cardSurface,
              borderRadius: BorderRadius.circular(18),
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
                        color: onPressed == null
                            ? colors.textMuted
                            : colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
