import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
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
import '../../../../core/utils/responsive.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  AppNotification? _selectedDetail;

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

  // ── helpers matching NotificationListItem icon mapping ──
  Widget _detailIconForType(NotificationType type, double size) {
    switch (type) {
      case NotificationType.newJob:
        return Image.asset("assets/images/star.png", width: size, height: size, fit: BoxFit.scaleDown);
      case NotificationType.interestConfirmed:
        return Image.asset("assets/images/handshake.png", width: size, height: size, fit: BoxFit.scaleDown);
      case NotificationType.newComment:
        return Image.asset("assets/images/comment.png", width: size, height: size, fit: BoxFit.scaleDown);
      case NotificationType.newLike:
        return Image.asset("assets/images/fits_unselected.png", width: size, height: size, fit: BoxFit.scaleDown);
      case NotificationType.recommendedTraining:
        return Image.asset("assets/images/training.png", width: size, height: size, fit: BoxFit.scaleDown);
      case NotificationType.applicationRejected:
        return Image.asset("assets/images/app_rejected.png", width: size, height: size, fit: BoxFit.scaleDown);
      case NotificationType.applicationApproved:
        return Image.asset("assets/images/app_approved.png", width: size, height: size, fit: BoxFit.scaleDown);
      case NotificationType.identityVerification:
        return Image.asset("assets/images/iden_ver.png", width: size, height: size, fit: BoxFit.scaleDown);
      case NotificationType.identityVerificationSuccess:
        return Image.asset("assets/images/iden_ver_success.png", width: size, height: size, fit: BoxFit.scaleDown);
    }
  }

  Color _detailIconBg(NotificationType type) {
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

  String _detailDateLabel(AppNotification n) {
    final now = DateTime.now();
    final isToday = n.createdAt.year == now.year &&
        n.createdAt.month == now.month &&
        n.createdAt.day == now.day;
    final time =
        '${n.createdAt.hour.toString().padLeft(2, '0')}:${n.createdAt.minute.toString().padLeft(2, '0')}';
    if (isToday) return 'Today at $time';
    return '${n.createdAt.day.toString().padLeft(2, '0')}/${n.createdAt.month.toString().padLeft(2, '0')} at $time';
  }

  Widget _buildDetailCard(AppNotification n, String userId) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('DETAIL',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colors.textMuted,
                  letterSpacing: 0.6)),
          const SizedBox(height: 8),
          Divider(height: 1, color: colors.divider),
          const SizedBox(height: 12),
          Text(_detailDateLabel(n),
              style: TextStyle(fontSize: 11, color: colors.textMuted)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _detailIconBg(n.type),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(child: _detailIconForType(n.type, 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(n.title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary)),
              ),
            ],
          ),
          if (n.subtitle != null) ...[
            const SizedBox(height: 10),
            Text(n.subtitle!,
                style: TextStyle(fontSize: 12, color: colors.textSecondary)),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: n.isRead
                    ? null
                    : () async {
                        await ref.read(markNotificationReadUseCaseProvider)(
                          MarkNotificationReadParams(id: n.id, userId: userId),
                        );
                        ref.invalidate(notificationsProvider);
                        setState(() => _selectedDetail = AppNotification(
                              id: n.id,
                              userId: n.userId,
                              title: n.title,
                              subtitle: n.subtitle,
                              createdAt: n.createdAt,
                              type: n.type,
                              isRead: true,
                              contactName: n.contactName,
                              contactInitials: n.contactInitials,
                              actionUrl: n.actionUrl,
                              chatId: n.chatId,
                            ));
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Mark as read',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              OutlinedButton(
                onPressed: () => setState(() => _selectedDetail = null),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  side: BorderSide(color: colors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Dismiss',
                    style: TextStyle(fontSize: 12, color: colors.textPrimary)),
              ),
            ],
          ),
        ],
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
    final isDesktop = Responsive.isDesktop(context);

    // Desktop: master-detail layout like the reference
    if (isDesktop) {
      return Scaffold(
        backgroundColor: context.colors.scaffoldBg,
        body: currentUserAsync.when(
          data: (currentUser) => notificationsAsync.when(
            data: (notifications) {
              if (notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none,
                          size: 64, color: context.colors.brandIndigo),
                      const SizedBox(height: 16),
                      Text(l10n.noNotifications,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: context.colors.textPrimary)),
                    ],
                  ),
                );
              }
              final groups = groupNotificationsByDate(notifications);
              final hasDetail = _selectedDetail != null;
              Widget buildList({int flex = 1}) => Expanded(
                    flex: flex,
                    child: SlidableAutoCloseBehavior(
                      child: RefreshIndicator(
                        onRefresh: _refreshNotifications,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final group in groups) ...[
                                _buildSectionHeader(group, l10n, localeName),
                                ...group.notifications.map(
                                  (notification) => Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: NotificationListItem(
                                      notification: notification,
                                      onTap: () => setState(
                                          () => _selectedDetail = notification),
                                      onMarkRead: () async {
                                        await ref.read(
                                            markNotificationReadUseCaseProvider)(
                                          MarkNotificationReadParams(
                                              id: notification.id,
                                              userId: currentUser.id),
                                        );
                                        ref.invalidate(notificationsProvider);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );

              // Initially full-width list; when a notification is tapped, show detail and shrink list
              if (!hasDetail) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [buildList(flex: 1)],
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildList(flex: 3),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildDetailCard(_selectedDetail!, currentUser.id),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      );
    }

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

            return SlidableAutoCloseBehavior(
              child: RefreshIndicator(
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
