import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/app_notification.dart';

/// Ligne de notification : icône typée, titre/sous-titre, heure ou bouton "Read".
class NotificationTile extends StatelessWidget {
  final AppNotification n;
  final VoidCallback onRead;
  final VoidCallback onTap;
  const NotificationTile(
      {super.key, required this.n, required this.onRead, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _visual(n.type);
    return InkWell(
      onTap: onTap,
      child: Container(
        color: n.read ? Colors.white : const Color(0xFFF6F4FF),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.navy,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(n.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (n.read)
              Text(n.time,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 11))
            else
              GestureDetector(
                onTap: onRead,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: AppTheme.brandBlue,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Read',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _visual(NotifType t) {
    switch (t) {
      case NotifType.jobOpportunity:
        return (Icons.auto_awesome, const Color(0xFF7C5CFC));
      case NotifType.interestConfirmed:
        return (Icons.waving_hand, AppTheme.primary);
      case NotifType.comment:
        return (Icons.mode_comment_outlined, AppTheme.brandBlue);
      case NotifType.like:
        return (Icons.thumb_up_alt_outlined, AppTheme.brandBlue);
      case NotifType.training:
        return (Icons.school_outlined, AppTheme.brandPink);
      case NotifType.applicationRejected:
        return (Icons.cancel_outlined, const Color(0xFFE53935));
      case NotifType.applicationApproved:
        return (Icons.check_circle_outline, const Color(0xFF22A06B));
      case NotifType.recruited:
        return (Icons.celebration_outlined, const Color(0xFF7C5CFC));
      case NotifType.identityRequired:
        return (Icons.verified_user_outlined, AppTheme.brandPink);
      case NotifType.identitySuccess:
        return (Icons.verified_outlined, const Color(0xFF22A06B));
      case NotifType.identityFailure:
        return (Icons.gpp_bad_outlined, const Color(0xFFE53935));
    }
  }
}
