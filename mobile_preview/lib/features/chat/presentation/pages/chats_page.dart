import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../domain/entities/chat_summary.dart';
import '../bloc/chat_list_bloc.dart';
import '../widgets/chat_tile.dart';

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

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
        title: const Text('All chats',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: -1),
      body: BlocBuilder<ChatListBloc, ChatListState>(
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(children: [
                  _pill(context, 'All', null, state.kind),
                  const SizedBox(width: 8),
                  _pill(context, 'Job Offers', ChatKind.jobOffer, state.kind),
                  const SizedBox(width: 8),
                  _pill(context, 'Professionnels', ChatKind.professional, state.kind),
                ]),
              ),
              Expanded(child: _list(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _pill(BuildContext context, String label, ChatKind? kind, ChatKind? selected) {
    final active = kind == selected;
    return GestureDetector(
      onTap: () => context.read<ChatListBloc>().add(ChatTabChanged(kind)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppTheme.brandBlue : const Color(0xFFEDEEFB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppTheme.brandBlue)),
      ),
    );
  }

  Widget _list(BuildContext context, ChatListState state) {
    if (state.status == ChatListStatus.loading ||
        state.status == ChatListStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == ChatListStatus.error) {
      return Center(child: Text(state.message));
    }
    if (state.items.isEmpty) {
      return const Center(child: Text('Aucune conversation.'));
    }
    return ListView.separated(
      itemCount: state.items.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 72, color: AppTheme.hairline),
      itemBuilder: (context, i) {
        final chat = state.items[i];
        return ChatTile(
          chat: chat,
          onTap: () => context.push('/conversation', extra: chat),
        );
      },
    );
  }
}
