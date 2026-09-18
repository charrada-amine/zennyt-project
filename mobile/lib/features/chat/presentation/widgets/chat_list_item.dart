// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:zennyt/shared/icons/app_icons.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/chat.dart';
import '../../../../core/constants.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';

class ChatListItem extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback? onTap;

  const ChatListItem({super.key, required this.conversation, this.onTap});

  Color _colorFromName(String name) {
    final hash = name.codeUnits.fold<int>(0, (a, b) => a + b);
    final colors = [
      Colors.deepPurple,
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.blueGrey,
    ];
    return colors[hash % colors.length];
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays == 0) {
      return DateFormat.Hm().format(dateTime);
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat.E().format(dateTime);
    } else {
      return DateFormat.MMMd().format(dateTime);
    }
  }

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final avatarColor = _colorFromName(conversation.counterpartName);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
      color: Colors.transparent,
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: avatarColor.withOpacity(0.12),
            backgroundImage: conversation.counterpartPhotoUrl != null
                ? NetworkImage(conversation.counterpartPhotoUrl!)
                : null,
            child: conversation.counterpartPhotoUrl == null
                ? Text(
                    conversation.counterpartName
                        .split(' ')
                        .map((p) => p.isNotEmpty ? p[0] : '')
                        .take(2)
                        .join(),
                    style: TextStyle(
                      color: avatarColor,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              conversation.counterpartName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: context.colors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (conversation.isHiringContact) ...[
                            const SizedBox(width: 20),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.hiringTagBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const AppIcon(
                                      AppIcons.starFilled,
                                      size: 15,
                                      color: Color(0xFF4C96E6),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      l10n.hiringContact,
                                      style: const TextStyle(
                                        color: AppColors.hiringTagText,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(conversation.lastMessageAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.textMuted,
                      ),
                    ),
                  ],
                ),
                // Une conversation par offre : sans le poste, trois discussions avec
                // le même recruteur étaient indiscernables.
                if (conversation.jobTitle != null &&
                    conversation.jobTitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      AppIcon(
                        HugeIcons.strokeRoundedBriefcase01,
                        size: 13,
                        color: context.colors.accent,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          conversation.jobTitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: context.colors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        conversation.lastMessagePreview,
                        style: TextStyle(
                          fontSize: 14,
                          color: conversation.unreadCount > 0
                              ? context.colors.textPrimary
                              : context.colors.textSecondary,
                          fontWeight: conversation.unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (conversation.unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        constraints: const BoxConstraints(minWidth: 20),
                        height: 20,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: context.colors.accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${conversation.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (AppConstants.isCupertino) {
      return GestureDetector(
        onTap: onTap,
        child: _buildContent(context),
      );
    } else {
      return InkWell(
        onTap: onTap,
        child: _buildContent(context),
      );
    }
  }
}
