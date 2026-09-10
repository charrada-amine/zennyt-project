import 'package:flutter/material.dart';
import 'identity_verification_alert.dart';

class IdentityVerificationDialog {
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onVerify,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: IdentityVerificationAlert(
            onClose: () => Navigator.of(dialogContext).pop(),
            onVerify: () {
              Navigator.of(dialogContext).pop();
              onVerify();
            },
          ),
        );
      },
    );
  }
}
