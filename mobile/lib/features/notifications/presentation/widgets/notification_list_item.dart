import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../../core/constants.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import '../../domain/entities/app_notification.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

/// Une notification : icône du type (ou initiales du contact), titre, heure,
/// aperçu sur deux lignes et pastille « non lu ». Glisser vers la gauche marque
/// comme lu.
class NotificationListItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkRead;

  const NotificationListItem({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkRead,
  });

  /// Icône et couleur d'accent de chaque type.
  static (AppIconData, Color) styleFor(NotificationType type) => switch (type) {
    NotificationType.newMessage => (
      HugeIcons.strokeRoundedMessage01,
      const Color(0xFF4F6BED),
    ),
    NotificationType.jobMatch => (
      HugeIcons.strokeRoundedAgreement01,
      const Color(0xFFD12E7D),
    ),
    NotificationType.newJob => (
      HugeIcons.strokeRoundedBriefcase01,
      const Color(0xFF4C96E6),
    ),
    NotificationType.interestConfirmed => (
      HugeIcons.strokeRoundedAgreement01,
      const Color(0xFF1F9D63),
    ),
    NotificationType.newComment => (
      HugeIcons.strokeRoundedComment01,
      const Color(0xFF214389),
    ),
    NotificationType.newLike => (
      HugeIcons.strokeRoundedThumbsUp,
      const Color(0xFFD12E7D),
    ),
    NotificationType.recommendedTraining => (
      HugeIcons.strokeRoundedMortarboard01,
      const Color(0xFF7C5CE0),
    ),
    NotificationType.applicationRejected => (
      HugeIcons.strokeRoundedTaskRemove01,
      const Color(0xFFE11D48),
    ),
    NotificationType.applicationApproved => (
      HugeIcons.strokeRoundedTaskDone01,
      const Color(0xFF1F9D63),
    ),
    NotificationType.applicationViewed => (
      HugeIcons.strokeRoundedView,
      const Color(0xFF4F6BED),
    ),
    NotificationType.applicationStatusChanged => (
      HugeIcons.strokeRoundedTask01,
      const Color(0xFFEE8A1E),
    ),
    NotificationType.profileViewed => (
      HugeIcons.strokeRoundedUserSearch01,
      const Color(0xFF7C5CE0),
    ),
    NotificationType.identityVerification => (
      HugeIcons.strokeRoundedSecurityBlock,
      const Color(0xFFE11D48),
    ),
    NotificationType.identityVerificationSuccess => (
      HugeIcons.strokeRoundedSecurityCheck,
      const Color(0xFF1F9D63),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final (icon, accent) = styleFor(notification.type);
    final unread = !notification.isRead;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      child: Slidable(
        key: ValueKey(notification.id),
        endActionPane: unread
            ? ActionPane(
                motion: const ScrollMotion(),
                extentRatio: 0.24,
                children: [
                  const SizedBox(width: 8),
                  CustomSlidableAction(
                    onPressed: (_) => onMarkRead?.call(),
                    backgroundColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AppIcon(
                            HugeIcons.strokeRoundedTick02,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.read,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : null,
        child: Material(
          color: unread
              ? Color.alphaBlend(
                  accent.withValues(alpha: 0.06),
                  colors.cardSurface,
                )
              : colors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.border),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (notification.contactInitials != null)
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: accent.withValues(alpha: 0.14),
                      child: Text(
                        notification.contactInitials!,
                        style: TextStyle(
                          color: accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: AppIcon(icon, color: accent, size: 22),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: unread
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(notification.createdAt),
                              style: TextStyle(
                                fontSize: 11.5,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (notification.subtitle != null &&
                            notification.subtitle!.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            notification.subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (unread) ...[
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime createdAt) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final local = createdAt.toLocal();
    return '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }
}
