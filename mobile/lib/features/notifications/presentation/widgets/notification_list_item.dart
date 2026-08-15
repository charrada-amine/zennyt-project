import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../../core/constants.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import '../../domain/entities/app_notification.dart';

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

  Widget _getIconForType(NotificationType type, double size) {
    switch (type) {
      case NotificationType.newJob:
        return Image.asset("assets/images/star.png",
            width: size, height: size, fit: BoxFit.scaleDown);
      case NotificationType.interestConfirmed:
        return Image.asset("assets/images/handshake.png",
            width: size, height: size, fit: BoxFit.scaleDown);
      case NotificationType.newComment:
        return Image.asset("assets/images/comment.png",
            width: size, height: size, fit: BoxFit.scaleDown);
      case NotificationType.newLike:
        return Image.asset("assets/images/fits_unselected.png",
            width: size, height: size, fit: BoxFit.scaleDown);
      case NotificationType.recommendedTraining:
        return Image.asset("assets/images/training.png",
            width: size, height: size, fit: BoxFit.scaleDown);
      case NotificationType.applicationRejected:
        return Image.asset("assets/images/app_rejected.png",
            width: size, height: size, fit: BoxFit.scaleDown);
      case NotificationType.applicationApproved:
        return Image.asset("assets/images/app_approved.png",
            width: size, height: size, fit: BoxFit.scaleDown);
      case NotificationType.identityVerification:
        return Image.asset("assets/images/iden_ver.png",
            width: size, height: size, fit: BoxFit.scaleDown);
      case NotificationType.identityVerificationSuccess:
        return Image.asset("assets/images/iden_ver_success.png",
            width: size, height: size, fit: BoxFit.scaleDown);
    }
  }

  Color _getIconBackgroundColor(NotificationType type) {
    switch (type) {
      case NotificationType.newJob:
        return const Color(0xFFEDE7F6);
      case NotificationType.interestConfirmed:
        return const Color(0xFFE8F5E9);
      case NotificationType.newComment:
        return const Color(0xFFE3F2FD);
      case NotificationType.newLike:
        return const Color(0xFFFFEBEE);
      case NotificationType.recommendedTraining:
        return const Color(0xFFF3E5F5);
      case NotificationType.applicationRejected:
        return const Color(0xFFFCE4EC);
      case NotificationType.applicationApproved:
        return const Color(0xFFE8F5E9);
      case NotificationType.identityVerification:
        return const Color(0xFFFFF3E0);
      case NotificationType.identityVerificationSuccess:
        return const Color(0xFFE8F5E9);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      height: 85,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
        child: Slidable(
          key: ValueKey(notification.id),
          endActionPane: !notification.isRead
              ? ActionPane(
                  motion: const ScrollMotion(),
                  extentRatio: 0.25,
                  children: [
                    const SizedBox(width: 8),
                    CustomSlidableAction(
                      onPressed: (_) {
                        if (onMarkRead != null) onMarkRead!();
                      },
                      autoClose: true,
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      child: Container(
                        height: double.infinity,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.chipSelected,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              AppConstants.isCupertino
                                  ? CupertinoIcons.checkmark
                                  : Icons.check,
                              color: Colors.white,
                              size: 24,
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
          child: Container(
            decoration: BoxDecoration(
              color: notification.isRead
                  ? context.colors.cardSurface
                  : context.colors.primary.withOpacity(0.08),
              border: Border.all(
                color: context.colors.border,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (notification.contactInitials != null)
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: context.colors.placeholderBg,
                          child: Text(
                            notification.contactInitials!,
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getIconBackgroundColor(notification.type),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: _getIconForType(notification.type, 20),
                          ),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: context.colors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTime(notification.createdAt),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: context.colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            if (notification.subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                notification.subtitle!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.colors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime createdAt) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(createdAt.hour)}:${twoDigits(createdAt.minute)}';
  }
}
