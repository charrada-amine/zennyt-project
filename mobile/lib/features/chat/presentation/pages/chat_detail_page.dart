// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/message.dart' show SenderRole;
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
import '../../../../core/enums/user_role.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../billing/presentation/widgets/video_interview_paywall.dart';

import 'package:zennyt/shared/icons/app_icons.dart';
import 'package:zennyt/shared/widgets/app_popup_menu.dart';

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
      final result = await ref.read(sendMessageUseCaseProvider)(
        SendMessageParams(
          conversationId: widget.conversation.id,
          userId: userId,
          content: text,
        ),
      );
      result.fold(
        (failure) {
          // Erreur silencieuse pour l'instant : le message n'est pas inséré.
          debugPrint('SendMessage failed: $failure');
        },
        (message) {
          // Insertion directe côté expéditeur (le destinataire la reçoit par WS).
          ref
              .read(messagesProvider(widget.conversation.id).notifier)
              .addIncoming(message);
          ref.invalidate(conversationsProvider);
        },
      );
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

    // Insertion temps réel : un message reçu sur `/user/queue/messages` pour
    // cette conversation est ajouté directement à la liste, sans refetch.
    ref.listen(realtimeMessageStreamProvider, (previous, next) {
      final message = next.value;
      if (message != null && message.conversationId == conversation.id) {
        ref.read(messagesProvider(conversation.id).notifier).addIncoming(message);
      }
    });

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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Qui est en face (selon mon rôle) et pour quelle offre : une
                    // conversation est ouverte par match, donc par poste.
                    Text(
                      [
                        conversation.myRole == SenderRole.recruiter
                            ? l10n.counterpartCandidate
                            : l10n.recruiter,
                        if (conversation.jobTitle?.trim().isNotEmpty ?? false)
                          conversation.jobTitle!.trim(),
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                      ? const AppIcon(
                          HugeIcons.strokeRoundedCall,
                          size: 22,
                          color: AppColors.primaryBlue,
                        )
                      : const AppIcon(
                          HugeIcons.strokeRoundedCall,
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
                onTap: () async {
                  final isRecruiter =
                      ref.read(authControllerProvider).value?.role == UserRole.recruiter;
                  if (isRecruiter) {
                    final paid = await VideoInterviewPaywall.show(
                      context,
                      counterpartName: conversation.counterpartName,
                    );
                    if (!paid || !context.mounted) return;
                  }
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
                      ? const AppIcon(
                          HugeIcons.strokeRoundedVideo01,
                          size: 24,
                          color: AppColors.primaryBlue,
                        )
                      : const AppIcon(
                          HugeIcons.strokeRoundedVideo01,
                          color: AppColors.primaryBlue,
                        ),
                ),
              ),
            ),
            AppPopupMenu.icon(
              icon: HugeIcons.strokeRoundedMoreVertical,
              iconColor: context.colors.textMuted,
              iconSize: 22,
              entries: [
                AppMenuAction(
                  label: l10n.report,
                  sfSymbol: 'flag',
                  icon: HugeIcons.strokeRoundedFlag02,
                ),
                AppMenuAction(
                  label: l10n.block,
                  sfSymbol: 'nosign',
                  icon: HugeIcons.strokeRoundedBlocked,
                  destructive: true,
                ),
              ],
            ),
          ],
          showBack: true,
        ),
        bottomNavigationBar: null,
        backgroundColor: context.colors.scaffoldBg,
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
                        return MessageBubble(
                          message: messages[index],
                          isFromCurrentUser: messages[index].senderRole ==
                              conversation.myRole,
                        );
                      },
                    );
                  },
                  loading: () => Center(
                    child: AppConstants.isCupertino
                        ? const CupertinoActivityIndicator()
                        : const CircularProgressIndicator.adaptive(),
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
                        child: AppIcon(
                          _isSending
                              ? HugeIcons.strokeRoundedHourglass
                              : HugeIcons.strokeRoundedSent,
                          size: 26,
                          color: AppColors.chipSelected,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const AppIcon(
                        HugeIcons.strokeRoundedAddCircle,
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
            : const CircularProgressIndicator.adaptive(),
      ),
      error: (error, _) => Center(child: Text('Erreur: $error')),
    );
  }
}
