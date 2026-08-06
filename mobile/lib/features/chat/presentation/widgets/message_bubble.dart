// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../domain/entities/message.dart';
import '../../../../core/constants.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  /// True si ce message provient de l'utilisateur courant de la conversation.
  ///
  /// ATTENTION : ce n'est PAS `senderRole == candidate`. Le rôle de l'utilisateur
  /// courant dépend de la conversation (`Conversation.myRole`, renvoyé par le
  /// backend) : un recruteur envoie des messages avec le rôle RECRUITER.
  /// La bulle est donc à droite ssi le rôle de l'expéditeur == notre propre rôle.
  final bool isFromCurrentUser;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isFromCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isFromCurrentUser ? AppColors.chipSelected : Colors.white;
    final textColor = isFromCurrentUser ? Colors.white : Colors.black87;

    return Padding(
      padding: EdgeInsets.only(
        left: isFromCurrentUser ? 60 : 0,
        right: isFromCurrentUser ? 0 : 60,
        top: 4,
        bottom: 4,
      ),
      child: Row(
        mainAxisAlignment:
            isFromCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isFromCurrentUser ? 16 : 0),
                  bottomRight: Radius.circular(isFromCurrentUser ? 0 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      message.content,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.sentAt),
                    style: TextStyle(
                      color: textColor.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime datetime) {
    return '${datetime.hour.toString().padLeft(2, '0')}:${datetime.minute.toString().padLeft(2, '0')}';
  }
}