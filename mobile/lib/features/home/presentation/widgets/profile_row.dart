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

    void openCreatePost() {
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
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: colors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: openCreatePost,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InitialsAvatar(
                        url: avatarUrl,
                        size: 36,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.newProject,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textSecondary,
                            fontFamily: 'inter',
                            fontWeight: AppWeights.medium,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // bottom left icons
                      Icon(Icons.image_outlined,
                          size: 18, color: colors.primary.withValues(alpha: 0.9)),
                      const SizedBox(width: 10),
                      Icon(Icons.emoji_events_outlined,
                          size: 18, color: colors.primary.withValues(alpha: 0.9)),
                      const SizedBox(width: 10),
                      Icon(Icons.add, size: 18, color: colors.primary.withValues(alpha: 0.9)),
                      const Spacer(),
                      SizedBox(
                        height: 28,
                        child: ElevatedButton(
                          onPressed: openCreatePost,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.brandNavy,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: const Size(0, 28),
                          ),
                          child: Text(
                            l10n.postAction,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

