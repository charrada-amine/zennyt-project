import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../../shared/widgets/zennyt_logo.dart';
import '../../../../../core/theme/theme.dart';
import '../../widgets/auth_desktop_shell.dart';
import '../viewmodel/signup_viewmodel.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _pinController = TextEditingController();
  Timer? _timer;
  int _secondsLeft = 0;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_pinController.text.length < 6) {
      ref.read(signupViewModelProvider.notifier).resetOtpStatus();
      return;
    }
    FocusScope.of(context).unfocus();
    final ok = await ref
        .read(signupViewModelProvider.notifier)
        .verifyOtp(_pinController.text);
    if (ok && mounted) {
      // Briefly show the green "validated" state before continuing.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (mounted) context.go(AppRoutes.profileSetup);
    }
  }

  Future<void> _resend() async {
    await ref.read(signupViewModelProvider.notifier).resendOtp();
    _startCountdown();
  }

  PinTheme _pinTheme(
    BuildContext context,
    double width,
    Color borderColor, {
    Color? fill,
    double borderWidth = 1.2,
  }) {
    final colors = context.colors;
    return PinTheme(
      width: width,
      height: 54,
      textStyle: AppTypography.headlineSmall.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: fill ?? colors.inputFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signupViewModelProvider);
    final hPadding = Responsive.horizontalPadding(context);

    final isError = state.otpStatus == OtpStatus.invalid;
    final isValid = state.otpStatus == OtpStatus.valid;

    const gap = 10.0;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final contentWidth =
        (screenWidth < Responsive.maxContentWidth
            ? screenWidth
            : Responsive.maxContentWidth) -
        hPadding * 2;
    final boxWidth = ((contentWidth - gap * 5) / 6).clamp(40.0, 56.0);

    final colors = context.colors;

    final innerForm = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xl),
        const Center(
          child: ZennytLogo(size: 48, showTagline: true),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        Text(
          AppStrings.confirmationSmsTitle,
          style: AppTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppStrings.confirmationSmsBody,
          style: AppTypography.bodyMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _OtpBoxes(
          controller: _pinController,
          isError: isError,
          isValid: isValid,
          boxWidth: boxWidth,
          gap: gap,
          pinTheme: _pinTheme,
          onChanged: (value) {
            ref
                .read(signupViewModelProvider.notifier)
                .resetOtpStatus();
            final complete = value.length == 6;
            if (complete != _isComplete) {
              setState(() => _isComplete = complete);
            }
          },
        ),
        if (isError) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: AppSpacing.iconSm,
                color: colors.error,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                AppStrings.invalidCode,
                style: AppTypography.bodySmall.copyWith(
                  color: colors.error,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: SizedBox(
            width: 190,
            child: PrimaryButton(
              label: AppStrings.continueLabel,
              loading: state.isLoading,
              onPressed: _isComplete ? _verify : null,
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
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPadding),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: innerForm,
                    ),
                  ),
                  _ResendRow(secondsLeft: _secondsLeft, onResend: _resend),
                  const SizedBox(height: AppSpacing.xxl),
                  _ChangePhoneBlock(
                    onTap: () => context.push(AppRoutes.changePhone),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
      desktop: (context) => AuthDesktopShell(
        formContent: Column(
          children: [
            innerForm,
            const SizedBox(height: AppSpacing.xxxl),
            _ResendRow(secondsLeft: _secondsLeft, onResend: _resend),
            const SizedBox(height: AppSpacing.xxl),
            _ChangePhoneBlock(
              onTap: () => context.push(AppRoutes.changePhone),
            ),
          ],
        ),
      ),
    );
  }
}

/// The six-digit code entry, distributed evenly across the available width.
class _OtpBoxes extends StatelessWidget {
  const _OtpBoxes({
    required this.controller,
    required this.isError,
    required this.isValid,
    required this.boxWidth,
    required this.gap,
    required this.pinTheme,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool isError;
  final bool isValid;
  final double boxWidth;
  final double gap;
  final PinTheme Function(
    BuildContext context,
    double width,
    Color borderColor, {
    Color? fill,
    double borderWidth,
  })
  pinTheme;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final neutralColor = isError
        ? colors.error
        : isValid
        ? colors.success
        : colors.border;

    final defaultTheme = pinTheme(context, boxWidth, neutralColor);
    final focusedTheme = (isError || isValid)
        ? defaultTheme
        : pinTheme(context, boxWidth, colors.primary, borderWidth: 1.6);
    final submittedTheme = pinTheme(context, boxWidth, neutralColor);

    return Pinput(
      length: 6,
      controller: controller,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      defaultPinTheme: defaultTheme,
      focusedPinTheme: focusedTheme,
      submittedPinTheme: submittedTheme,
      separatorBuilder: (_) => SizedBox(width: gap),
      onChanged: onChanged,
    );
  }
}

class _ResendRow extends StatelessWidget {
  const _ResendRow({required this.secondsLeft, required this.onResend});

  final int secondsLeft;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Text(
          AppStrings.didntReceiveCode,
          style: AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxs),
        secondsLeft > 0
            ? Text(
                'Resend in 0:${secondsLeft.toString().padLeft(2, '0')}',
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.textMuted,
                ),
              )
            : GestureDetector(
                onTap: onResend,
                child: Text(
                  AppStrings.resend,
                  style: AppTypography.titleSmall.copyWith(
                    color: colors.actionCardFilled, // Accent equivalent
                  ),
                ),
              ),
      ],
    );
  }
}

class _ChangePhoneBlock extends StatelessWidget {
  const _ChangePhoneBlock({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          AppStrings.changePhoneQuestion,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxs),
        GestureDetector(
          onTap: onTap,
          child: Text(
            AppStrings.changePhoneNumber,
            style: AppTypography.titleSmall.copyWith(
              color: colors.actionCardFilled,
            ),
          ),
        ),
      ],
    );
  }
}
