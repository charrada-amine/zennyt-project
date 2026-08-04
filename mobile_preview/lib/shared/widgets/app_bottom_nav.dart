import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../app_mode.dart';

/// Barre de navigation inférieure de l'app (shell partagé entre les écrans).
/// Home · Fits · Progress|Careers · Search · Notifications.
///
/// L'onglet central s'adapte au mode global ([appIsRecruiter]) : "Progress"
/// pour le candidat, "Careers" pour le recruteur — les autres écrans (Home,
/// Notifications…) sont partagés entre les deux rôles.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: appIsRecruiter,
      builder: (context, recruiter, _) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.hairline)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _item(context, 0, Icons.home_filled, 'Home', route: '/home'),
                _item(context, 1, Icons.thumb_up_alt_outlined, 'Fits', route: '/fits'),
                _center(context, recruiter),
                _item(context, 3, Icons.search, 'Search', route: '/search'),
                _item(context, 4, Icons.notifications_none, 'Notifications', route: '/notifications'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int index, IconData icon, String label,
      {String? route}) {
    final active = index == currentIndex;
    final color = active ? AppTheme.brandBlue : AppTheme.muted;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (active) return;
          if (route != null) {
            context.go(route);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label — à venir'),
                duration: const Duration(milliseconds: 800),
              ),
            );
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _center(BuildContext context, bool recruiter) {
    final label = recruiter ? 'Careers' : 'Progress';
    final active = recruiter && currentIndex == 2;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (recruiter) {
            if (!active) context.go('/careers');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Progress — à venir'),
                duration: Duration(milliseconds: 800),
              ),
            );
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _LogoDot(),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: active ? AppTheme.brandBlue : AppTheme.muted,
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _LogoDot extends StatelessWidget {
  const _LogoDot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppTheme.brandBlue, AppTheme.brandPink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: const Text('G',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
    );
  }
}
