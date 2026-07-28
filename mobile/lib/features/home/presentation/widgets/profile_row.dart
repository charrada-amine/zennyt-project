import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import 'package:zennyt/core/constants.dart';
import 'package:zennyt/core/avatar/avatar_service.dart';
import 'package:zennyt/features/auth/presentation/auth_controller.dart';
import '../../../../shared/widgets/initials_avatar.dart';

class ProfileRow extends ConsumerWidget {
  const ProfileRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).value;
    final avatarUrl = (user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty)
        ? user.profileImageUrl!
        : const AvatarService().defaultFor(user?.email ?? 'zennyt');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          InitialsAvatar(
            url: avatarUrl,
            size: 60,
          ),
          const SizedBox(width: 20),
          AppConstants.isCupertino
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => context.push('/create-post'),
                  child: Text(
                    l10n.newProject,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primaryGrey,
                      fontFamily: 'inter',
                      fontStyle: FontStyle.normal,
                      fontWeight: AppWeights.regular,
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: () => context.push('/create-post'),
                  child: Text(
                    l10n.newProject,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primaryGrey,
                      fontFamily: 'inter',
                      fontStyle: FontStyle.normal,
                      fontWeight: AppWeights.regular,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

