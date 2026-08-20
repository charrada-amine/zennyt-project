// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';

import '../../../../core/constants.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../domain/entities/chat.dart';
import '../../domain/usecases/send_message.dart';

import '../providers/chat_providers.dart';
import '../widgets/chat_list_item.dart';
import '../widgets/message_bubble.dart';
import '../widgets/job_opportunity_card.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';


class DesktopChatsPage extends ConsumerStatefulWidget {
  const DesktopChatsPage({super.key});

  @override
  ConsumerState<DesktopChatsPage> createState() => _DesktopChatsPageState();
}

class _DesktopChatsPageState extends ConsumerState<DesktopChatsPage> {
  Conversation? _selectedConversation;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _searchController.dispose();
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
    if (text.isEmpty || _isSending || _selectedConversation == null) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final result = await ref.read(sendMessageUseCaseProvider)(
        SendMessageParams(
          conversationId: _selectedConversation!.id,
          userId: userId,
          content: text,
        ),
      );
      result.fold(
        (failure) => debugPrint('SendMessage failed: $failure'),
        (message) {
          ref
              .read(messagesProvider(_selectedConversation!.id).notifier)
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
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    // Real-time message stream
    ref.listen(realtimeMessageStreamProvider, (previous, next) {
      if (next.hasValue) {
        ref.invalidate(conversationsProvider);
        ref.invalidate(notificationsProvider);
        final msg = next.value;
        if (msg != null && _selectedConversation != null &&
            msg.conversationId == _selectedConversation!.id) {
          ref
              .read(messagesProvider(_selectedConversation!.id).notifier)
              .addIncoming(msg);
        }
      }
    });

    return Row(
      children: [
        // ── Left Panel: Conversations ──────────────────────────────────
        Container(
          width: 380,
          decoration: BoxDecoration(
            color: colors.cardSurface,
            border: Border(
              right: BorderSide(color: colors.divider),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.inputFill,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(Icons.search, size: 20, color: colors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search conversations',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: colors.textMuted,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Filter Chips
              _buildFilterChips(colors, l10n),

              const SizedBox(height: 8),

              // Conversation List
              Expanded(
                child: _buildConversationList(colors, l10n),
              ),
            ],
          ),
        ),

        // ── Right Panel: Chat Detail ───────────────────────────────────
        Expanded(
          child: _selectedConversation == null
              ? _buildEmptyState(colors)
              : _buildChatDetail(colors, l10n),
        ),
      ],
    );
  }

  Widget _buildFilterChips(AppColorScheme colors, AppLocalizations l10n) {
    final selectedFilter = ref.watch(chatFilterProvider);
    final filters = [
      l10n.filterAll,
      l10n.filterJobOffers,
      l10n.filterProfessionals,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (i) {
          final isSelected = selectedFilter == i;
          return Padding(
            padding: EdgeInsets.only(right: i == filters.length - 1 ? 0 : 8),
            child: GestureDetector(
              onTap: () =>
                  ref.read(chatFilterProvider.notifier).state = i,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primary
                      : colors.surfaceRaised,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  filters[i],
                  style: TextStyle(
                    color: isSelected
                        ? colors.cardSurface
                        : colors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildConversationList(AppColorScheme colors, AppLocalizations l10n) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final selectedFilter = ref.watch(chatFilterProvider);

    return conversationsAsync.when(
      data: (conversations) {
        final filtered = selectedFilter == 0
            ? conversations
            : selectedFilter == 1
                ? conversations.where((c) => c.isHiringContact).toList()
                : conversations
                    .where((c) => !c.isHiringContact)
                    .toList();

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              l10n.noChats,
              style: TextStyle(color: colors.textMuted),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: filtered.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: 0.5,
            indent: 16,
            endIndent: 16,
            color: colors.divider,
          ),
          itemBuilder: (context, index) {
            final conversation = filtered[index];
            final isActive =
                _selectedConversation?.id == conversation.id;

            return Container(
              decoration: BoxDecoration(
                color: isActive
                    ? colors.primary.withOpacity(0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ChatListItem(
                conversation: conversation,
                onTap: () {
                  setState(() {
                    _selectedConversation = conversation;
                  });
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildEmptyState(AppColorScheme colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 80,
            color: colors.textMuted.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Select a conversation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a conversation from the list to start messaging',
            style: TextStyle(
              fontSize: 14,
              color: colors.textMuted.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatDetail(AppColorScheme colors, AppLocalizations l10n) {
    final conversation = _selectedConversation!;
    final currentUserAsync = ref.watch(currentUserProvider);
    final messagesAsync = ref.watch(messagesProvider(conversation.id));
    final avatarColor = _colorFromName(conversation.counterpartName);

    return currentUserAsync.when(
      data: (currentUser) => Column(
        children: [
          // ── Chat Header ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: colors.cardSurface,
              border: Border(
                bottom: BorderSide(color: colors.divider),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
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
                            fontSize: 13,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.counterpartName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        l10n.recruiter,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action buttons
                _chatActionButton(
                  icon: Icons.phone,
                  onTap: () {
                    context.push('/call', extra: {
                      'contactName': conversation.counterpartName,
                      'conversationId': conversation.id,
                      'counterpartId': conversation.counterpartId,
                      'myUserId': currentUser.id,
                      'isVideoCall': false,
                    });
                  },
                ),
                const SizedBox(width: 8),
                _chatActionButton(
                  icon: Icons.videocam,
                  onTap: () {
                    context.push('/video-call', extra: {
                      'contactName': conversation.counterpartName,
                      'conversationId': conversation.id,
                      'counterpartId': conversation.counterpartId,
                      'myUserId': currentUser.id,
                      'isVideoCall': true,
                    });
                  },
                ),
                const SizedBox(width: 8),
                PopupMenuButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.more_vert,
                    color: colors.textMuted,
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
            ),
          ),

          // ── Job Opportunity Card ─────────────────────────────────
          if (conversation.jobOpportunity != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: JobOpportunityCard(
                opportunity: conversation.jobOpportunity!,
                onConfirm: () {},
                onReject: () {},
                onExploreOffer: () {},
              ),
            ),

          // ── Messages ─────────────────────────────────────────────
          Expanded(
            child: Container(
              color: colors.scaffoldBg,
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages yet',
                        style: TextStyle(color: colors.textMuted),
                      ),
                    );
                  }
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
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
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('Error: $error')),
              ),
            ),
          ),

          // ── Input Bar ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: colors.cardSurface,
              border: Border(
                top: BorderSide(color: colors.divider),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: colors.inputFill,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Send message...',
                        hintStyle: TextStyle(color: colors.textMuted),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(currentUser.id),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _sendMessage(currentUser.id),
                    child: Icon(
                      _isSending
                          ? Icons.hourglass_empty
                          : Icons.send_rounded,
                      size: 24,
                      color: AppColors.chipSelected,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.add_circle_outline_rounded,
                    size: 24,
                    color: AppColors.chipSelected,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _chatActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        splashColor: AppColors.chipSelected.withOpacity(0.3),
        highlightColor: AppColors.chipSelected.withOpacity(0.1),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: AppColors.primaryBlue,
            size: 22,
          ),
        ),
      ),
    );
  }
}
