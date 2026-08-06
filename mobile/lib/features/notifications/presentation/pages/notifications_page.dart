import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zennyt/shared/widgets/platform_scaffold.dart';
import '../providers/notification_providers.dart';
import '../../domain/usecases/mark_notification_read.dart';
import '../../../../core/constants.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/identity_verification_dialog.dart';
import '../providers/identity_verification_provider.dart';
import '../widgets/notification_list_item.dart';
import '../utils/notification_date_grouper.dart';
import '../../../../shared/widgets/platform_app_bar.dart';
import '../../domain/entities/app_notification.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../chat/domain/entities/chat.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../../navigation/presentation/viewmodel/nav_tab_provider.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  Future<void> _refreshNotifications() async {
    ref.invalidate(notificationsProvider);
    ref.invalidate(currentUserProvider);
    await ref.read(notificationsProvider.future);
  }

  void _showVerificationDialog() {
    IdentityVerificationDialog.show(
      context,
      onVerify: () {
        ref.read(identityVerificationProvider.notifier).markVerified();
      },
    );
  }

  Future<void> _onNotificationTap(
      AppNotification notification, String userId) async {
    if (notification.type == NotificationType.identityVerification) {
      _showVerificationDialog();
      return;
    }

    if (notification.type != NotificationType.newJob ||
        notification.chatId == null) {
      return;
    }

    if (!notification.isRead) {
      await ref.read(markNotificationReadUseCaseProvider)(
        MarkNotificationReadParams(id: notification.id, userId: userId),
      );
      ref.invalidate(notificationsProvider);
    }

    if (!mounted) return;

    try {
      final conversations = await ref.read(conversationsProvider.future);
      final conversation =
          conversations.firstWhere((c) => c.id == notification.chatId);
      if (mounted) {
        context.push('/chats/${conversation.id}', extra: conversation);
      }
    } catch (_) {
      if (!mounted) return;
      context.push(
        '/chats/${notification.chatId}',
        extra: Conversation(
          id: notification.chatId!,
          counterpartName: notification.contactName ?? 'Recruiter',
          lastMessagePreview: notification.subtitle ?? '',
          lastMessageAt: notification.createdAt,
          isHiringContact: true,
        ),
      );
    }
  }

  Widget _buildVerificationInfoIcon() {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: _showVerificationDialog,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Center(
            child: Icon(
              AppConstants.isCupertino
                  ? CupertinoIcons.info
                  : Icons.info_outline_rounded,
              color: context.colors.info,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    NotificationDateGroup group,
    AppLocalizations l10n,
    String localeName,
  ) {
    final label = notificationDateGroupLabel(
      group.key,
      l10n.today,
      l10n.yesterday,
      localeName,
    );

    if (group.isToday) {
      final unreadCount = group.notifications.where((n) => !n.isRead).length;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.colors.accent,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 10,
                backgroundColor: context.colors.accent,
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const Spacer(),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.showAll,
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 50,
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: context.colors.textPrimary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toString();
    final notificationsAsync = ref.watch(notificationsProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    final isVerified = ref.watch(identityVerificationProvider);

    return PlatformScaffold(
      appBar: PlatformAppBar(
        showBack: true,
        onLeadingPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            ref.read(navTabProvider.notifier).select(0);
          }
        },
        title: Text(
          l10n.notifications,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
          ),
        ),
        actions: isVerified ? null : [_buildVerificationInfoIcon()],
      ),
      backgroundColor: context.colors.scaffoldBg,
      body: currentUserAsync.when(
        data: (currentUser) => notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refreshNotifications,
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: constraints.maxHeight,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              AppConstants.isCupertino
                                  ? CupertinoIcons.bell
                                  : Icons.notifications_none,
                              size: 64,
                              color: context.colors.brandIndigo,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noNotifications,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: context.colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.stayTuned,
                              style: TextStyle(
                                fontSize: 14,
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            final groups = groupNotificationsByDate(notifications);

            return RefreshIndicator(
              onRefresh: _refreshNotifications,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final group in groups) ...[
                      _buildSectionHeader(group, l10n, localeName),
                      ...group.notifications.map(
                        (notification) => NotificationListItem(
                          notification: notification,
                          onTap: () =>
                              _onNotificationTap(notification, currentUser.id),
                          onMarkRead: () async {
                            await ref.read(markNotificationReadUseCaseProvider)(
                              MarkNotificationReadParams(
                                id: notification.id,
                                userId: currentUser.id,
                              ),
                            );
                            ref.invalidate(notificationsProvider);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
          loading: () => Center(
            child: AppConstants.isCupertino
                ? const CupertinoActivityIndicator()
                : const CircularProgressIndicator(),
          ),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
        loading: () => Center(
          child: AppConstants.isCupertino
              ? const CupertinoActivityIndicator()
              : const CircularProgressIndicator(),
        ),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
