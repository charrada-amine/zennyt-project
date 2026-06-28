import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/theme/theme.dart';
import '../widgets/profile_action_cards.dart';
import '../widgets/profile_header_section.dart';
import '../widgets/settings_menu_list.dart';

/// The main Profile & Settings screen. Shows the user header, action cards, and
/// the settings menu.
class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hPadding = Responsive.horizontalPadding(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
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
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPadding),
                child: const ProfileActionCards(),
              ),
              const SizedBox(height: AppSpacing.lg),
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
            color: colors.backButtonBg,
            shape: BoxShape.circle,
            border: Border.all(color: colors.backButtonBorder, width: 1),
          ),
          child: IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: colors.backButtonIcon,
              size: 20,
            ),
          ),
        ),
        const Spacer(),
        Text(
          title,
          style: AppTypography.titleLarge.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 44), // Balance the back button
      ],
    );
  }
}
