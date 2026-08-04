import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../domain/entities/app_notification.dart';
import '../bloc/notifications_bloc.dart';
import '../widgets/notification_tile.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.navy,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.chevron_left), onPressed: () => context.go('/home')),
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.info_outline, color: AppTheme.muted),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          if (state.status == NotifStatus.loading ||
              state.status == NotifStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == NotifStatus.error) {
            return Center(child: Text(state.message));
          }
          final bloc = context.read<NotificationsBloc>();
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(children: [
                  const Text('Today',
                      style: TextStyle(
                          color: AppTheme.brandPink,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  const SizedBox(width: 8),
                  if (state.unreadToday > 0)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                      decoration: const BoxDecoration(
                          color: AppTheme.brandPink, shape: BoxShape.circle),
                      child: Text('${state.unreadToday}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11)),
                    ),
                  const Spacer(),
                  const Text('Show all',
                      style: TextStyle(color: AppTheme.muted, fontSize: 13)),
                ]),
              ),
              for (final n in state.today)
                NotificationTile(
                  n: n,
                  onRead: () => bloc.add(NotificationMarkedRead(n.id)),
                  onTap: () => _onTap(context, n),
                ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Text('Yesterday',
                    style: TextStyle(
                        color: AppTheme.muted, fontWeight: FontWeight.w600)),
              ),
              for (final n in state.yesterday)
                NotificationTile(
                  n: n,
                  onRead: () => bloc.add(NotificationMarkedRead(n.id)),
                  onTap: () => _onTap(context, n),
                ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }

  void _onTap(BuildContext context, AppNotification n) {
    if (n.type == NotifType.identityRequired) {
      _identityDialog(context);
    } else if (n.type == NotifType.jobOpportunity) {
      context.push('/chats');
    } else {
      context.read<NotificationsBloc>().add(NotificationMarkedRead(n.id));
    }
  }

  void _identityDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Identity verification required !',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text(
            'The recruiter has requested an identity verification with face '
            'matching to ensure trust and security. Prepare your ID.',
            style: TextStyle(color: AppTheme.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Verify now',
                style: TextStyle(
                    color: AppTheme.brandBlue, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
