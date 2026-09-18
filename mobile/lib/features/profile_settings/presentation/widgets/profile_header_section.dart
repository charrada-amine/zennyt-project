import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/theme/theme.dart';
import '../../../auth/presentation/auth_controller.dart';
import 'profile_avatar.dart';
import '../../../../shared/widgets/app_motion.dart';
import '../../../../core/audio/sound_service.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

/// Profile header section: avatar circle, user name, and "See your profile"
/// link. Bound to the authenticated user.
class ProfileHeaderSection extends ConsumerWidget {
  const ProfileHeaderSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(authControllerProvider).value;
    final name = (user?.fullName.trim().isNotEmpty ?? false)
        ? user!.fullName.trim()
        : l10n.profileUserName;

    return ProfileIdentityCard(
      name: name,
      imageUrl: user?.profileImageUrl,
      fallbackSeed: user?.email,
      subtitle: l10n.seeYourProfile,
      onTap: () => context.pushNamed('userProfile'),
    );
  }
}

/// Shared identity surface for candidate, recruiter and settings profiles.
class ProfileIdentityCard extends StatelessWidget {
  const ProfileIdentityCard({
    super.key,
    required this.name,
    this.imageUrl,
    this.fallbackSeed,
    this.subtitle,
    this.metadata,
    this.actions,
    this.onTap,
  });

  final String name;
  final String? imageUrl, fallbackSeed, subtitle, metadata;
  final Widget? actions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppReveal(
      child: AppPressScale(
        enabled: onTap != null,
        child: Material(
          color: colors.cardSurface,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap == null
                ? null
                : () {
                    SoundService.instance.vibrateSelection();
                    onTap!();
                  },
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.primary.withValues(alpha: .18),
                            width: 2,
                          ),
                        ),
                        child: ProfileAvatar(
                          imageUrl: imageUrl,
                          size: 72,
                          fallbackSeed: fallbackSeed,
                        ),
                      ),
                      const Spacer(),
                      if (onTap != null)
                        AppIcon(
                          HugeIcons.strokeRoundedArrowUpRight01,
                          color: colors.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 28,
                      height: 1.12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.8,
                      color: colors.textDarkBlue,
                    ),
                  ),
                  if (subtitle?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 16,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                  if (metadata?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 12),
                    Text(
                      metadata!,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                  if (actions != null) ...[
                    const SizedBox(height: 22),
                    actions!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
