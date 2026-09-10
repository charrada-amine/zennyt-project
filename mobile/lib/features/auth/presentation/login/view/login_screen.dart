import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/localization/l10n_extension.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../shared/widgets/app_dialog.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../shared/widgets/auth_header.dart';
import '../../../../../shared/widgets/language_toggle.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../../shared/widgets/screen_top_bar.dart';
import '../../../../../shared/widgets/social_login_button.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../../core/theme/theme.dart';
import '../../widgets/auth_desktop_shell.dart';
import '../viewmodel/login_viewmodel.dart';

/// Resolves a [LoginError] code to localized, user-facing text.
String loginErrorText(AppLocalizations l10n, LoginError error) {
  switch (error) {
    case LoginError.emailRequired:
      return l10n.emailRequired;
    case LoginError.emailInvalid:
      return l10n.emailInvalid;
    case LoginError.passwordRequired:
      return l10n.passwordRequired;
    case LoginError.passwordTooShort:
      return l10n.passwordTooShort;
    case LoginError.incorrectPassword:
      return l10n.incorrectPassword;
    case LoginError.connectionFailed:
      return l10n.connectionFailed;
    case LoginError.unknown:
      return l10n.errorGeneric;
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    ref
        .read(loginViewModelProvider.notifier)
        .signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LoginState>(loginViewModelProvider, (previous, next) {
      if (next.connectionError != null && previous?.connectionError == null) {
        AppDialog.connection(
          context,
          title: context.l10n.connectionErrorTitle,
          message: loginErrorText(context.l10n, next.connectionError!),
        ).then(
          (_) =>
              ref.read(loginViewModelProvider.notifier).clearConnectionError(),
        );
      }
      if (next.isSuccess && previous?.isSuccess != true) {
        context.go(AppRoutes.home);
      }
    });

    final state = ref.watch(loginViewModelProvider);
    final hPadding = Responsive.horizontalPadding(context);

    final emailStatus = state.emailError != null
        ? FieldStatus.error
        : FieldStatus.normal;

    final colors = context.colors;

    final formContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ScreenTopBar(trailing: LanguageToggle()),
        const SizedBox(height: AppSpacing.sm),
        AuthHeader(title: context.l10n.loginTitle),
        const SizedBox(height: AppSpacing.xxl),
        AppTextField(
          hint: context.l10n.email,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          status: emailStatus,
          prefixIcon: Icons.mail_outline_rounded,
          onChanged: (_) => ref
              .read(loginViewModelProvider.notifier)
              .clearEmailError(),
        ),
        if (state.emailError != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _FieldErrorText(
            message: loginErrorText(context.l10n, state.emailError!),
          ),
        ],
        const SizedBox(height: AppSpacing.base),
        // Wrap only the password field in a ValueListenableBuilder so
        // each keystroke rebuilds the field (for the valid/normal
        // border tint) instead of the entire Scaffold.
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _passwordController,
          builder: (_, value, _) {
            final passwordStatus = state.passwordError != null
                ? FieldStatus.error
                : (value.text.length >= 8
                      ? FieldStatus.valid
                      : FieldStatus.normal);
            return AppTextField(
              hint: context.l10n.password,
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              status: passwordStatus,
              prefixIcon: Icons.lock_outline_rounded,
              onChanged: (_) => ref
                  .read(loginViewModelProvider.notifier)
                  .clearPasswordError(),
              onSubmitted: (_) => _submit(),
            );
          },
        ),
        if (state.passwordError != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _FieldErrorText(
            message: loginErrorText(context.l10n, state.passwordError!),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: SizedBox(
            width: 190,
            child: PrimaryButton(
              label: context.l10n.signIn,
              loading: state.isLoading,
              onPressed: _submit,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: TextButton(
            onPressed: () =>
                context.push(AppRoutes.forgotPasswordMethod),
            child: Text(
              context.l10n.forgotPassword,
              style: AppTypography.titleSmall.copyWith(
                color: colors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _OrDivider(),
        const SizedBox(height: AppSpacing.lg),
        SocialLoginButton(
          icon: const FaIcon(
            FontAwesomeIcons.google,
            size: 20,
            color: Color(0xFF4285F4),
          ),
          label: context.l10n.continueWithGoogle,
          onPressed: () {},
        ),
        const SizedBox(height: AppSpacing.md),
        SocialLoginButton(
          icon: FaIcon(
            FontAwesomeIcons.github,
            size: 20,
            color: colors.iconDefault,
          ),
          label: context.l10n.continueWithGitHub,
          onPressed: () {},
        ),
        const SizedBox(height: AppSpacing.xl),
        _SignUpRow(onTap: () => context.go(AppRoutes.signup)),
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
                AppSpacing.xxl,
                hPadding,
                AppSpacing.xl,
              ),
              child: formContent,
            ),
          ),
        ),
      ),
      desktop: (context) => AuthDesktopShell(formContent: formContent),
    );
  }
}

class _FieldErrorText extends StatelessWidget {
  const _FieldErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: AppSpacing.iconSm,
          color: colors.error,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            message,
            style: AppTypography.bodySmall.copyWith(color: colors.error),
          ),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: context.colors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            context.l10n.orLogInWith,
            style: AppTypography.caption.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ),
        Expanded(child: Divider(color: context.colors.divider)),
      ],
    );
  }
}

class _SignUpRow extends StatelessWidget {
  const _SignUpRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Text(
          context.l10n.noAccount,
          style: AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxs),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              context.l10n.signUp,
              style: AppTypography.titleSmall.copyWith(
                color: colors.primary,
                decoration: TextDecoration.underline,
                decorationColor: colors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
