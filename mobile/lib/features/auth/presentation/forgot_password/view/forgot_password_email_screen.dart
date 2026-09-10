import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/localization/l10n_extension.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../../shared/widgets/auth_header.dart';
import '../../../../../shared/widgets/app_back_button.dart';
import '../../../../../shared/widgets/screen_top_bar.dart';
import '../../../../../shared/widgets/language_toggle.dart';
import '../../auth_providers.dart';

class ForgotPasswordEmailScreen extends ConsumerStatefulWidget {
  const ForgotPasswordEmailScreen({super.key});

  @override
  ConsumerState<ForgotPasswordEmailScreen> createState() =>
      _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState
    extends ConsumerState<ForgotPasswordEmailScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = context.l10n.emailInvalid);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.forgotPassword(email: email);

      if (mounted) {
        context.push(AppRoutes.forgotPasswordOtp, extra: email);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = context.l10n.errorGeneric);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final hPadding = Responsive.horizontalPadding(context);

    return Scaffold(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ScreenTopBar(
                  leading: AppBackButton(),
                  trailing: LanguageToggle(),
                ),
                const SizedBox(height: AppSpacing.xl),

                AuthHeader(
                  title: l10n.enterYourEmail,
                  subtitle: l10n.enterEmailDesc,
                ),
                const SizedBox(height: AppSpacing.xxl),

                AppTextField(
                  hint: l10n.email,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  status: _error != null
                      ? FieldStatus.error
                      : FieldStatus.normal,
                  prefixIcon: Icons.mail_outline_rounded,
                  onSubmitted: (_) => _sendCode(),
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
                    width: double.infinity,
                    child: PrimaryButton(
                      label: l10n.sendCode,
                      loading: _isLoading,
                      onPressed: _sendCode,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
