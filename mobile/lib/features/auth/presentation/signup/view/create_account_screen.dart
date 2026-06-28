import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_locations.dart';
import '../../../../../core/localization/l10n_extension.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../shared/widgets/app_back_button.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../shared/widgets/auth_header.dart';
import '../../../../../shared/widgets/language_toggle.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../../shared/widgets/screen_top_bar.dart';
import '../../../../../core/theme/theme.dart';
import '../viewmodel/signup_viewmodel.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _city = TextEditingController();

  String? _country;
  bool _acceptedTerms = false;
  bool _termsTouched = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    _city.dispose();
    super.dispose();
  }

  String? _required(String? v, String field) => (v == null || v.trim().isEmpty)
      ? context.l10n.fieldRequired(field)
      : null;

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return context.l10n.emailRequired;
    final re = RegExp(r'^[\w.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!re.hasMatch(v.trim())) return context.l10n.emailInvalid;
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return context.l10n.phoneRequired;
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7) return context.l10n.phoneInvalid;
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return context.l10n.passwordRequired;
    if (v.length < 8) return context.l10n.passwordTooShort;
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return context.l10n.confirmPasswordRequired;
    if (v != _password.text) return context.l10n.passwordsDoNotMatch;
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _termsTouched = true);
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid || !_acceptedTerms) return;

    final ok = ref
        .read(signupViewModelProvider.notifier)
        .saveAccountDetails(
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          password: _password.text,
          city: _city.text.trim(),
          country: _country,
          termsAccepted: _acceptedTerms,
        );
    if (ok && mounted) context.push(AppRoutes.otp);
  }

  @override
  Widget build(BuildContext context) {
    // We only need [isLoading] from the view model here; selecting avoids
    // rebuilding the whole form when unrelated signup state changes.
    final isLoading = ref.watch(
      signupViewModelProvider.select((s) => s.isLoading),
    );
    final hPadding = Responsive.horizontalPadding(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: SafeArea(
        child: CenteredConstrainedBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenTopBar(
                leading: AppBackButton(
                  onPressed: () => context.go(AppRoutes.login),
                ),
                trailing: const LanguageToggle(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    hPadding,
                    AppSpacing.xs,
                    hPadding,
                    AppSpacing.xl,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AuthHeader(title: context.l10n.createAccountTitle),
                        const SizedBox(height: AppSpacing.xl),
                        AppTextField(
                          hint: context.l10n.firstName,
                          controller: _firstName,
                          textInputAction: TextInputAction.next,
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (v) =>
                              _required(v, context.l10n.firstName),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          hint: context.l10n.lastName,
                          controller: _lastName,
                          textInputAction: TextInputAction.next,
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (v) => _required(v, context.l10n.lastName),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          hint: context.l10n.emailHyphen,
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          prefixIcon: Icons.mail_outline_rounded,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          hint: context.l10n.phone,
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          prefixIcon: Icons.phone_outlined,
                          validator: _validatePhone,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _CountryField(
                          value: _country,
                          onChanged: (v) => setState(() => _country = v),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          hint: context.l10n.city,
                          controller: _city,
                          textInputAction: TextInputAction.next,
                          prefixIcon: Icons.location_city_outlined,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? context.l10n.cityRequired
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          hint: context.l10n.password,
                          controller: _password,
                          obscureText: true,
                          textInputAction: TextInputAction.next,
                          prefixIcon: Icons.lock_outline_rounded,
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          hint: context.l10n.confirmPassword,
                          controller: _confirm,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          prefixIcon: Icons.lock_outline_rounded,
                          validator: _validateConfirm,
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _TermsCheckbox(
                          value: _acceptedTerms,
                          showError: _termsTouched && !_acceptedTerms,
                          onChanged: (v) =>
                              setState(() => _acceptedTerms = v ?? false),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Center(
                          child: SizedBox(
                            width: 190,
                            child: PrimaryButton(
                              label: context.l10n.continueLabel,
                              loading: isLoading,
                              onPressed: _submit,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.base),
                        _LoginRow(onTap: () => context.go(AppRoutes.login)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryField extends StatelessWidget {
  const _CountryField({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: context.colors.textSecondary,
      ),
      style: AppTypography.bodyMedium.copyWith(
        color: context.colors.textPrimary,
      ),
      decoration: appInputDecoration(
        context,
        hint: context.l10n.country,
        prefixIcon: const AppInputIcon(Icons.public_outlined),
      ),
      hint: Text(
        context.l10n.country,
        style: AppTypography.bodyMedium.copyWith(
          color: context.colors.textMuted,
        ),
      ),
      validator: (v) => v == null ? context.l10n.countryRequired : null,
      items: [
        for (final c in AppLocations.countries)
          DropdownMenuItem(value: c, child: Text(c)),
      ],
      onChanged: onChanged,
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.value,
    required this.showError,
    required this.onChanged,
  });

  final bool value;
  final bool showError;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(!value),
                child: Text.rich(
                  TextSpan(
                    style: AppTypography.bodySmall.copyWith(
                      color: context.colors.textSecondary,
                    ),
                    children: [
                      TextSpan(text: context.l10n.acceptPrefix),
                      TextSpan(
                        text: context.l10n.termsAndConditions,
                        style: AppTypography.bodySmall.copyWith(
                          color: context.colors.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: context.colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs, left: 2),
            child: Text(
              context.l10n.termsRequired,
              style: AppTypography.bodySmall.copyWith(
                color: context.colors.error,
              ),
            ),
          ),
      ],
    );
  }
}

class _LoginRow extends StatelessWidget {
  const _LoginRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          context.l10n.haveAccount,
          style: AppTypography.bodyMedium.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            context.l10n.signIn,
            style: AppTypography.titleSmall.copyWith(
              color: context.colors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
