import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/theme.dart';

/// OTP confirmation dialog for an account change (e-mail or phone).
///
/// The code is delivered by e-mail (Resend) for both types — SMS is not
/// integrated yet. Returns `true` once [onVerify] succeeds; `false`/`null` when
/// the user cancels. Verification errors keep the dialog open with a message.
class AccountChangeOtpDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final Future<void> Function(String code) onVerify;
  final Future<void> Function() onResend;

  const AccountChangeOtpDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onVerify,
    required this.onResend,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Future<void> Function(String code) onVerify,
    required Future<void> Function() onResend,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AccountChangeOtpDialog(
        title: title,
        subtitle: subtitle,
        onVerify: onVerify,
        onResend: onResend,
      ),
    );
  }

  @override
  State<AccountChangeOtpDialog> createState() => _AccountChangeOtpDialogState();
}

class _AccountChangeOtpDialogState extends State<AccountChangeOtpDialog> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _resent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _controller.text.trim();
    if (code.length < 4) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onVerify(code);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Invalid or expired code. Try again.';
        });
      }
    }
  }

  Future<void> _resend() async {
    try {
      await widget.onResend();
      if (mounted) setState(() => _resent = true);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not resend the code.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: colors.scaffoldBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: AppTypography.titleLarge.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTypography.titleLarge.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 10,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '••••••',
                filled: true,
                fillColor: colors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: colors.error),
              ),
            ],
            if (_resent && _error == null) ...[
              const SizedBox(height: 8),
              Text(
                'A new code has been sent.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: colors.success),
              ),
            ],
            const SizedBox(height: 12),
            TextButton(
              onPressed: _busy ? null : _resend,
              child: const Text('Resend code'),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _busy ? null : _verify,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
              ),
            ),
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
