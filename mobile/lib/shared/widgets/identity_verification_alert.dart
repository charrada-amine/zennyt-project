// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../l10n/gen/app_localizations.dart';

class IdentityVerificationAlert extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onVerify;

  const IdentityVerificationAlert({
    super.key,
    required this.onClose,
    required this.onVerify,
  });

  static const _titleColor = Color(0xFF001B48);
  static const _bodyColor = Color(0xFF4A4A4A);
  static const _linkColor = Color(0xFF5E5CE6);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  l10n.identityVerificationRequired,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    height: 1.3,
                    color: _titleColor,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEEEEE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.identityVerificationDescription,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: _bodyColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.prepareYourId,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _titleColor,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: onVerify,
              child: Text(
                l10n.verifyNow,
                style: const TextStyle(
                  color: _linkColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  decoration: TextDecoration.underline,
                  decorationColor: _linkColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
