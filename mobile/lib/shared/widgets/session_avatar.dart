import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/current_user_provider.dart';

import 'package:zennyt/shared/icons/app_icons.dart';
import 'app_popup_menu.dart';

/// Avatar de l'utilisateur connecté (photo ou initiales) avec le menu de
/// session : identité + « Se déconnecter ».
class SessionAvatar extends ConsumerWidget {
  const SessionAvatar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final photo = user?.profileImageUrl;
    final initials = user == null
        ? '?'
        : ((user.firstName.isNotEmpty ? user.firstName[0] : '') +
                (user.lastName.isNotEmpty ? user.lastName[0] : ''))
            .toUpperCase();

    return AppPopupMenu(
      tooltip: 'Compte',
      entries: [
        AppMenuAction(
          label: user?.fullName ?? '',
          subtitle: user?.email,
          enabled: false,
        ),
        const AppMenuDivider(),
        AppMenuAction(
          label: 'Se déconnecter',
          sfSymbol: 'rectangle.portrait.and.arrow.right',
          icon: HugeIcons.strokeRoundedLogout01,
          destructive: true,
          onSelected: () async {
            await ref.read(authControllerProvider.notifier).logout();
            if (context.mounted) context.go(AppRoutes.login);
          },
        ),
      ],
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFE2E8F0),
              backgroundImage: photo != null ? NetworkImage(photo) : null,
              child: photo == null
                  ? Text(initials,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B3B7B)))
                  : null,
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFF21438A),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Center(
                child: AppIcon(HugeIcons.strokeRoundedMenu01, size: 10, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
