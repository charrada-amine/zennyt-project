import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zennyt/core/constants/app_constants.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import 'package:zennyt/core/theme/theme.dart';
import 'package:zennyt/core/avatar/avatar_service.dart';
import 'package:zennyt/features/auth/presentation/auth_controller.dart';
import 'package:zennyt/core/utils/responsive.dart';
import 'package:zennyt/features/home/presentation/pages/create_post_page.dart';
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
          onTap: () {
            if (Responsive.isDesktop(context)) {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 600,
                      maxHeight: 700,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: const CreatePostPage(),
                    ),
                  ),
                ),
              );
            } else {
              context.push('/create-post');
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                InitialsAvatar(
                  url: avatarUrl,
                  size: 48,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    l10n.newProject,
                    style: TextStyle(
                      fontSize: 16,
                      color: colors.textSecondary,
                      fontFamily: 'inter',
                      fontWeight: AppWeights.medium,
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

