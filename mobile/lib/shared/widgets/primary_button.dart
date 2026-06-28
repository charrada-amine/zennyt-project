import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

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
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expanded;
  final bool outlined;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final spinnerColor = outlined
        ? (foregroundColor ?? colors.primary)
        : Colors.white;

    final child = loading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation(spinnerColor),
            ),
          )
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
            onPressed: loading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: foregroundColor ?? colors.primary,
              backgroundColor: backgroundColor ?? Colors.transparent,
              side: BorderSide(
                color: foregroundColor ?? colors.primary,
                width: 1.5,
              ),
            ),
            child: child,
          )
        : ElevatedButton(
            onPressed: loading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor ?? colors.primary,
              foregroundColor: foregroundColor ?? Colors.white,
            ),
            child: child,
          );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
