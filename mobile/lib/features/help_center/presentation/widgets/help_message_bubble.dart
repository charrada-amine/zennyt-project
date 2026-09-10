// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import '../../domain/entities/help_message.dart';
import '../../../../core/constants.dart';

class HelpMessageBubble extends StatelessWidget {
  final HelpMessage message;
  final bool showAssistantLabel;

  const HelpMessageBubble({
    super.key,
    required this.message,
    this.showAssistantLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isFromUser = message.isFromUser;
    final bubbleColor = isFromUser ? AppColors.chipSelected : Colors.white;
    final textColor = isFromUser ? Colors.white : Colors.black87;

    return Padding(
      padding: EdgeInsets.only(
        left: isFromUser ? 60 : 0,
        right: isFromUser ? 0 : 60,
        top: 4,
        bottom: 4,
      ),
      child: Column(
        crossAxisAlignment:
            isFromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isFromUser && showAssistantLabel)
            Padding(
              padding: EdgeInsets.only(bottom: 6, left: 4),
              child: Text(
                l10n.discussionAssistant,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.colors.textMuted,
                  fontFamily: 'inter',
                ),
              ),
            ),
          Row(
            mainAxisAlignment:
                isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isFromUser ? 16 : 0),
                      bottomRight: Radius.circular(isFromUser ? 0 : 16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          message.text,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'inter',
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: textColor.withOpacity(0.6),
                          fontSize: 11,
                          fontFamily: 'inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime datetime) {
    return '${datetime.hour.toString().padLeft(2, '0')}:${datetime.minute.toString().padLeft(2, '0')}';
  }
}
