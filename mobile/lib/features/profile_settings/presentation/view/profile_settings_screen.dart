import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/user_role.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/theme/theme.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../widgets/profile_action_cards.dart';
import '../widgets/profile_header_section.dart';
import '../widgets/settings_menu_list.dart';
import '../widgets/recruiter_settings_menu_list.dart';

/// The main Profile & Settings screen. Shows the user header, action cards, and
/// the settings menu.
class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final hPadding = Responsive.horizontalPadding(context);
    final colors = context.colors;

    final isRecruiter = ref.watch(authControllerProvider).value?.role == UserRole.recruiter;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPadding),
                child: _TopBar(title: l10n.profileAndSettings),
              ),
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPadding),
                child: const ProfileHeaderSection(),
              ),
              if (!isRecruiter) ...[
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPadding),
                  child: const ProfileActionCards(),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (isRecruiter)
                const RecruiterSettingsMenuList()
              else
                const SettingsMenuList(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colors.scaffoldBg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colors.shadowColor.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: colors.divider,
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colors.textPrimary,
              size: 18,
            ),
          ),
        ),
        const Spacer(),
        Text(
          title,
          style: AppTypography.titleLarge.copyWith(
            color: colors.textDarkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 44),
      ],
    );
  }
}
