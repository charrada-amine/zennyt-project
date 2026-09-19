import 'package:flutter/material.dart';
import 'package:zennyt/shared/icons/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zennyt/core/constants/app_constants.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import 'package:zennyt/core/theme/theme.dart';
import 'package:zennyt/core/avatar/avatar_service.dart';
import 'package:zennyt/features/auth/presentation/auth_controller.dart';
import '../../../../shared/widgets/initials_avatar.dart';

class ProfileRow extends ConsumerWidget {
  const ProfileRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).value;
    final avatarUrl = user?.effectiveAvatarUrl ??
        const AvatarService().defaultFor('zennyt');
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/create-post'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                InitialsAvatar(
                  url: avatarUrl,
                  size: 44,
                ),
                const SizedBox(width: 12),
                // Un vrai champ de publication plutôt qu'un libellé « New Project »
                // flottant : on comprend qu'on peut écrire ici.
                Expanded(
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: colors.inputFill,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text(
                      l10n.composerPrompt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: colors.textSecondary,
                        fontWeight: AppWeights.medium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AppIcon(
                  HugeIcons.strokeRoundedImage01,
                  color: colors.accent,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

