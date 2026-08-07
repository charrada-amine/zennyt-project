import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/current_user_provider.dart';

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

    return PopupMenuButton<String>(
      tooltip: 'Compte',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) async {
        if (value == 'logout') {
          await ref.read(authControllerProvider.notifier).logout();
          if (context.mounted) context.go(AppRoutes.login);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(user?.fullName ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: Color(0xFF1E1B4B))),
              Text(user?.email ?? '',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF7A869A))),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: Color(0xFFE53935)),
              SizedBox(width: 8),
              Text('Se déconnecter',
                  style: TextStyle(color: Color(0xFFE53935))),
            ],
          ),
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
                child: Icon(Icons.menu, size: 10, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
