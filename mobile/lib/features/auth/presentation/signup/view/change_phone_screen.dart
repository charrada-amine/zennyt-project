import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../shared/widgets/app_back_button.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../../core/theme/theme.dart';
import '../viewmodel/signup_viewmodel.dart';

class ChangePhoneScreen extends ConsumerStatefulWidget {
  const ChangePhoneScreen({super.key});

  @override
  ConsumerState<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends ConsumerState<ChangePhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phone = TextEditingController(
    text: ref.read(signupViewModelProvider).phone,
  );

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required.';
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7) return 'Enter a valid phone number.';
    return null;
  }

  void _confirm() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref.read(signupViewModelProvider.notifier).updatePhone(_phone.text.trim());
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final hPadding = Responsive.horizontalPadding(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: SafeArea(
        child: CenteredConstrainedBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppBackButton(),
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
                        Text(
                          AppStrings.changePhoneTitle,
                          textAlign: TextAlign.center,
                          style: AppTypography.headlineMedium.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        AppTextField(
                          hint: AppStrings.phoneNumber,
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          prefixIcon: Icons.phone_outlined,
                          validator: _validatePhone,
                          onSubmitted: (_) => _confirm(),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Center(
                          child: SizedBox(
                            width: 190,
                            child: PrimaryButton(
                              label: AppStrings.confirm,
                              onPressed: _confirm,
                            ),
                          ),
                        ),
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
