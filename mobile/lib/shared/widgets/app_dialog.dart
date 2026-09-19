import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import 'primary_button.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

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
      icon: HugeIcons.strokeRoundedCancel01,
      sfSymbol: 'xmark.circle.fill',
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
      icon: HugeIcons.strokeRoundedCancel01,
      sfSymbol: 'wifi.exclamationmark',
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
      icon: HugeIcons.strokeRoundedTick02,
      sfSymbol: 'checkmark.circle.fill',
      iconColor: context.colors.success,
      title: title,
      message: message,
      buttonLabel: buttonLabel,
    );
  }

  /// Confirmation (oui / non) : alerte native sur iOS (Liquid Glass sur
  /// iOS 26+), AlertDialog Material sur Android. Renvoie `true` si l'action
  /// de confirmation a été choisie.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    String? message,
    required String confirmLabel,
    String? cancelLabel,
    bool destructive = false,
  }) async {
    var confirmed = false;
    await AdaptiveAlertDialog.show(
      context: context,
      title: title,
      message: message,
      actions: [
        AlertAction(
          title:
              cancelLabel ??
              MaterialLocalizations.of(context).cancelButtonLabel,
          style: AlertActionStyle.cancel,
          onPressed: () {},
        ),
        AlertAction(
          title: confirmLabel,
          style: destructive
              ? AlertActionStyle.destructive
              : AlertActionStyle.primary,
          onPressed: () => confirmed = true,
        ),
      ],
    );
    return confirmed;
  }

  /// Message simple avec un seul bouton (règles, informations).
  static Future<void> info(
    BuildContext context, {
    required String title,
    required String message,
    String? buttonLabel,
    VoidCallback? onDismissed,
  }) {
    return AdaptiveAlertDialog.show(
      context: context,
      title: title,
      message: message,
      actions: [
        AlertAction(
          title: buttonLabel ?? MaterialLocalizations.of(context).okButtonLabel,
          style: AlertActionStyle.primary,
          onPressed: onDismissed ?? () {},
        ),
      ],
    );
  }

  /// Saisie d'un texte court (e-mail d'invitation…). Renvoie le texte saisi,
  /// ou `null` si l'utilisateur annule.
  static Future<String?> input(
    BuildContext context, {
    required String title,
    String? message,
    required String placeholder,
    required String confirmLabel,
    String? cancelLabel,
    TextInputType? keyboardType,
  }) async {
    var confirmed = false;
    final value = await AdaptiveAlertDialog.inputShow(
      context: context,
      title: title,
      message: message,
      input: AdaptiveAlertDialogInput(
        placeholder: placeholder,
        keyboardType: keyboardType,
      ),
      actions: [
        AlertAction(
          title:
              cancelLabel ??
              MaterialLocalizations.of(context).cancelButtonLabel,
          style: AlertActionStyle.cancel,
          onPressed: () {},
        ),
        AlertAction(
          title: confirmLabel,
          style: AlertActionStyle.primary,
          onPressed: () => confirmed = true,
        ),
      ],
    );
    return confirmed ? value?.trim() : null;
  }

  static Future<void> _show(
    BuildContext context, {
    required AppIconData icon,
    required String sfSymbol,
    required Color iconColor,
    required String title,
    required String message,
    required String buttonLabel,
    bool showButton = true,
  }) {
    // iOS : alerte native (Liquid Glass sur iOS 26+, CupertinoAlertDialog
    // avant). Une alerte native ne se ferme pas d'un tap à l'extérieur, d'où
    // un bouton OK quand la version Material n'en a pas.
    if (PlatformInfo.isIOS) {
      return AdaptiveAlertDialog.show(
        context: context,
        title: title,
        message: message.isEmpty ? null : message,
        icon: sfSymbol,
        iconColor: iconColor,
        actions: [
          AlertAction(
            title: showButton
                ? buttonLabel
                : MaterialLocalizations.of(context).okButtonLabel,
            style: AlertActionStyle.primary,
            onPressed: () {},
          ),
        ],
      );
    }

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
                    child: AppIcon(icon, color: Colors.white, size: 32),
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
              if (message.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
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
