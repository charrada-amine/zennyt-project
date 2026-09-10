import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../core/audio/sound_service.dart';
import 'app_motion.dart';
import 'zennyt_loader.dart';

/// Primary call-to-action button matching the design's buttons.
///
/// Defaults to a filled style; set [outlined] for the bordered variant (navy
/// border + text on white). Supports an optional [loading] state and an
/// [expanded] flag (defaults to full-width as in the mockups).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.expanded = true,
    this.outlined = false,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.haptics = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expanded;
  final bool outlined;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;
  final bool haptics;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = !loading && onPressed != null;
    void activate() {
      if (haptics) SoundService.instance.vibrateSelection();
      onPressed?.call();
    }

    final child = loading
        ? const SizedBox(height: 22, width: 22, child: ZennytLoader(size: 22))
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppSpacing.iconMd),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final Widget button = outlined
        ? OutlinedButton(
            onPressed: enabled ? activate : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: foregroundColor ?? colors.primary,
              backgroundColor: backgroundColor ?? Colors.transparent,
              side: BorderSide(
                color: foregroundColor ?? colors.primary,
                width: 1.5,
              ),
            ),
            child: AnimatedSwitcher(
              duration: AppMotion.duration(context, AppMotion.settle),
              child: KeyedSubtree(key: ValueKey(loading), child: child),
            ),
          )
        : ElevatedButton(
            onPressed: enabled ? activate : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor ?? colors.primary,
              foregroundColor: foregroundColor ?? Colors.white,
            ),
            child: AnimatedSwitcher(
              duration: AppMotion.duration(context, AppMotion.settle),
              child: KeyedSubtree(key: ValueKey(loading), child: child),
            ),
          );

    return AppPressScale(
      enabled: enabled,
      child: expanded
          ? SizedBox(width: double.infinity, child: button)
          : button,
    );
  }
}
