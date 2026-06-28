import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import 'primary_button.dart';

/// Branded modal dialogs matching the design (a colored circular icon, title,
/// message and a dismiss button). Used for the login error state and reusable
/// for success / info dialogs.
class AppDialog {
  AppDialog._();

  static Future<void> error(
    BuildContext context, {
    String title = 'Oops!',
    required String message,
    String buttonLabel = 'Try again',
  }) {
    return _show(
      context,
      icon: Icons.close_rounded,
      iconColor: context.colors.error,
      title: title,
      message: message,
      buttonLabel: buttonLabel,
    );
  }

  /// Connection error matching the design: red ✕ badge, title + message and no
  /// action button (dismissed by tapping outside).
  static Future<void> connection(
    BuildContext context, {
    String title = 'Error connecting',
    required String message,
  }) {
    return _show(
      context,
      icon: Icons.close_rounded,
      iconColor: context.colors.error,
      title: title,
      message: message,
      buttonLabel: '',
      showButton: false,
    );
  }

  static Future<void> success(
    BuildContext context, {
    String title = 'Success',
    required String message,
    String buttonLabel = 'Continue',
  }) {
    return _show(
      context,
      icon: Icons.check_rounded,
      iconColor: context.colors.success,
      title: title,
      message: message,
      buttonLabel: buttonLabel,
    );
  }

  static Future<void> _show(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String buttonLabel,
    bool showButton = true,
  }) {
    final colors = context.colors;
    return showDialog<void>(
      context: context,
      barrierColor: AppColors.overlay,
      builder: (context) => Dialog(
        backgroundColor: colors.cardSurface,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.headlineSmall.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              if (showButton) ...[
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: buttonLabel,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
