import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../../../core/localization/l10n_extension.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../../shared/widgets/screen_top_bar.dart';
import '../../../../../shared/widgets/language_toggle.dart';
import '../../widgets/auth_desktop_shell.dart';
import '../../auth_providers.dart';

class ForgotPasswordOtpScreen extends ConsumerStatefulWidget {
  const ForgotPasswordOtpScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ForgotPasswordOtpScreen> createState() =>
      _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState
    extends ConsumerState<ForgotPasswordOtpScreen> {
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  String? _error;

  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resendCode() async {
    setState(() => _isResending = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.forgotPassword(email: widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.sendCode),
            backgroundColor: context.colors.primary,
          ),
        );
      }
    } catch (_) {
      // Silently fail on resend
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _resetPassword() async {
    final code = _otpController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final l10n = context.l10n;

    if (code.length < 4) {
      setState(() => _error = l10n.errorGeneric);
      return;
    }
    if (newPassword.length < 8) {
      setState(() => _error = l10n.passwordTooShort);
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _error = l10n.passwordsDoNotMatch);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.resetPassword(
        email: widget.email,
        code: code,
        newPassword: newPassword,
      );

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = l10n.errorGeneric);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    final colors = context.colors;
    final l10n = context.l10n;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF4CAF50),
                size: 36,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.passwordResetSuccess,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go(AppRoutes.login);
              },
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.backToLogin,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final hPadding = Responsive.horizontalPadding(context);

    final defaultPinTheme = PinTheme(
      width: 52,
      height: 56,
      textStyle: AppTypography.headlineSmall.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
      ),
    );

    final formContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ScreenTopBar(trailing: LanguageToggle()),
        const SizedBox(height: AppSpacing.xl),

        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.lock_outline_rounded,
            color: colors.primary,
            size: 36,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        Text(
          l10n.otpVerificationTitle,
          style: AppTypography.headlineMedium.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.otpVerificationSubtitle(widget.email),
          style: AppTypography.bodyMedium.copyWith(
            color: colors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // OTP input
        Center(
          child: Pinput(
            controller: _otpController,
            length: 6,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(
                border: Border.all(color: colors.primary, width: 2),
              ),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Resend code
        Center(
          child: TextButton(
            onPressed: _isResending ? null : _resendCode,
            child: Text(
              l10n.resendCode,
              style: AppTypography.bodySmall.copyWith(
                color: _isResending ? colors.textMuted : colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // New password
        AppTextField(
          hint: l10n.newPassword,
          controller: _newPasswordController,
          obscureText: true,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.lock_outline_rounded,
        ),
        const SizedBox(height: AppSpacing.base),

        // Confirm new password
        AppTextField(
          hint: l10n.confirmNewPassword,
          controller: _confirmPasswordController,
          obscureText: true,
          textInputAction: TextInputAction.done,
          prefixIcon: Icons.lock_outline_rounded,
          onSubmitted: (_) => _resetPassword(),
        ),

        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 16,
                color: colors.error,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _error!,
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),

        Center(
          child: SizedBox(
            width: 220,
            child: PrimaryButton(
              label: l10n.resetPasswordBtn,
              loading: _isLoading,
              onPressed: _resetPassword,
            ),
          ),
        ),
      ],
    );

    return ResponsiveBuilder(
      mobile: (context) => Scaffold(
        backgroundColor: colors.scaffoldBg,
        body: SafeArea(
          child: CenteredConstrainedBox(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                hPadding,
                AppSpacing.lg,
                hPadding,
                AppSpacing.xl,
              ),
              child: formContent,
            ),
          ),
        ),
      ),
      desktop: (context) => AuthDesktopShell(
        formContent: formContent,
      ),
    );
  }
}
