import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/chat_summary.dart';

class ChatTile extends StatelessWidget {
  final ChatSummary chat;
  final VoidCallback onTap;
  const ChatTile({super.key, required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(radius: 22, backgroundImage: NetworkImage(chat.avatarUrl)),
      title: Row(children: [
        Flexible(
          child: Text(chat.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppTheme.navy)),
        ),
        if (chat.hiringContact) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: const Color(0xFFFBE9F0),
                borderRadius: BorderRadius.circular(20)),
            child: const Text('Hiring contact',
                style: TextStyle(fontSize: 10, color: AppTheme.brandPink)),
          ),
        ],
      ]),
      subtitle: Text(chat.lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.muted),
    );
  }
}
