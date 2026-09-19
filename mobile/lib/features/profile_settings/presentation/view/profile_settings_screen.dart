import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/user_role.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/theme/theme.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../widgets/profile_action_cards.dart';
import '../widgets/profile_header_section.dart';
import '../widgets/settings_menu_list.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/app_motion.dart';

/// The main Profile & Settings screen. Shows the user header, action cards, and
/// the settings menu.
class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final hPadding = Responsive.horizontalPadding(context);
    final colors = context.colors;

    final isRecruiter =
        ref.watch(authControllerProvider).value?.role == UserRole.recruiter;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: CustomAppBar(title: l10n.profileAndSettings),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPadding),
                child: const AppReveal(child: ProfileHeaderSection()),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Maquette : les deux cartes d'action juste sous l'en-tête, pour
              // tous les rôles (le portefeuille sert aussi aux recruteurs).
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPadding),
                child: const AppReveal(child: ProfileActionCards()),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPadding),
                child: SettingsMenuList(recruiter: isRecruiter),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
