// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zennyt/shared/widgets/platform_app_bar.dart';
import '../providers/chat_providers.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../../../core/constants.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import '../../domain/entities/chat.dart';
import '../../domain/usecases/send_message.dart';
import '../widgets/message_bubble.dart';
import '../widgets/job_opportunity_card.dart';
import '../../../../shared/widgets/platform_scaffold.dart';

class ChatDetailPage extends ConsumerStatefulWidget {
  final Conversation conversation;

  const ChatDetailPage({super.key, required this.conversation});

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

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

  Future<void> _sendMessage(String userId) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await ref.read(sendMessageUseCaseProvider)(
        SendMessageParams(
          conversationId: widget.conversation.id,
          userId: userId,
          content: text,
        ),
      );
      ref.invalidate(messagesProvider(widget.conversation.id));
    } catch (_) {
      // Handle error silently for now
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final conversation = widget.conversation;
    final currentUserAsync = ref.watch(currentUserProvider);
    final messagesAsync = ref.watch(messagesProvider(conversation.id));
    final avatarColor = _colorFromName(conversation.counterpartName);

    return currentUserAsync.when(
      data: (currentUser) => PlatformScaffold(
        appBar: PlatformAppBar(
          title: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                child: CircleAvatar(
                  radius: 18,
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
                            fontSize: 12,
                          ),
                        )
                      : null,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      conversation.counterpartName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      l10n.recruiter,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                splashColor: AppColors.chipSelected.withOpacity(0.3),
                highlightColor: AppColors.chipSelected.withOpacity(0.1),
                onTap: () {
                  context.push('/call', extra: {
                    'contactName': conversation.counterpartName,
                    'conversationId': conversation.id,
                    'counterpartId': conversation.counterpartId,
                    'myUserId': currentUser.id,
                    'isVideoCall':false,
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: AppConstants.isCupertino
                      ? const Icon(
                          CupertinoIcons.phone_fill,
                          size: 22,
                          color: AppColors.primaryBlue,
                        )
                      : const Icon(
                          Icons.phone,
                          color: AppColors.primaryBlue,
                        ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                splashColor: AppColors.chipSelected.withOpacity(0.3),
                highlightColor: AppColors.chipSelected.withOpacity(0.1),
                onTap: () {
                  
                  context.push('/video-call', extra: {
                    'contactName': conversation.counterpartName,
                    'conversationId': conversation.id,
                    'counterpartId': conversation.counterpartId,
                    'myUserId': currentUser.id,
                    'isVideoCall': true,
                  });
                  
                  //context.push("/test-features");
                },
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: AppConstants.isCupertino
                      ? const Icon(
                          CupertinoIcons.videocam_fill,
                          size: 24,
                          color: AppColors.primaryBlue,
                        )
                      : const Icon(
                          Icons.video_call,
                          color: AppColors.primaryBlue,
                        ),
                ),
              ),
            ),
            PopupMenuButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                Icons.more_vert,
                color: context.colors.textMuted,
                size: 22,
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'report',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/flag.png',
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(l10n.report),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'block',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/block.png',
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(l10n.block),
                    ],
                  ),
                ),
              ],
            ),
          ],
          showBack: true,
        ),
        bottomNavigationBar: null,
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              if (conversation.jobOpportunity != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: JobOpportunityCard(
                    opportunity: conversation.jobOpportunity!,
                    onConfirm: () {},
                    onReject: () {},
                    onExploreOffer: () {},
                  ),
                ),
              // Messages list
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return MessageBubble(message: messages[index]);
                      },
                    );
                  },
                  loading: () => Center(
                    child: AppConstants.isCupertino
                        ? const CupertinoActivityIndicator()
                        : const CircularProgressIndicator(),
                  ),
                  error: (error, _) => Center(child: Text('Erreur: $error')),
                ),
              ),

              Container(
                width: MediaQuery.of(context).size.width,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: context.colors.cardSurface,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.colors.inputFill,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppConstants.isCupertino
                            ? CupertinoTextField(
                                controller: _messageController,
                                placeholder: 'Send message...',
                                placeholderStyle: TextStyle(
                                  color: context.colors.textMuted,
                                  fontSize: 16,
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.transparent,
                                ),
                                onSubmitted: (_) =>
                                    _sendMessage(currentUser.id),
                              )
                            : TextField(
                                controller: _messageController,
                                style: const TextStyle(fontSize: 16),
                                decoration: InputDecoration(
                                  hintText: 'Send message...',
                                  hintStyle: TextStyle(color: context.colors.textMuted),
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onSubmitted: (_) =>
                                    _sendMessage(currentUser.id),
                              ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _sendMessage(currentUser.id),
                        child: Icon(
                          _isSending
                              ? Icons.hourglass_empty
                              : Icons.send_rounded,
                          size: 26,
                          color: AppColors.chipSelected,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.add_circle_outline_rounded,
                        size: 26,
                        color: AppColors.chipSelected,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      loading: () => Center(
        child: AppConstants.isCupertino
            ? const CupertinoActivityIndicator()
            : const CircularProgressIndicator(),
      ),
      error: (error, _) => Center(child: Text('Erreur: $error')),
    );
  }
}
