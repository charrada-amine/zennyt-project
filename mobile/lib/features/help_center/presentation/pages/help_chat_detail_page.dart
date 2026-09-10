// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import '../../../../core/constants.dart';
import '../../../../shared/widgets/platform_scaffold.dart';
import '../../../../shared/widgets/platform_app_bar.dart';
import '../../domain/entities/help_chat.dart';
import '../providers/help_center_providers.dart';
import '../widgets/help_message_bubble.dart';
import '../widgets/rate_experience_dialog.dart';
import '../widgets/feedback_bottom_sheet.dart';

enum _PostChatStage { hidden, rating, sent, thankYou }

class HelpChatDetailPage extends ConsumerStatefulWidget {
  final HelpChat helpChat;

  const HelpChatDetailPage({super.key, required this.helpChat});

  @override
  ConsumerState<HelpChatDetailPage> createState() => _HelpChatDetailPageState();
}

class _HelpChatDetailPageState extends ConsumerState<HelpChatDetailPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  bool _showTypingIndicator = false;
  bool _sending = false;
  _PostChatStage _postChatStage = _PostChatStage.hidden;
  HelpChatRating? _selectedRating;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showTypingIndicator = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showTypingIndicator = false;
              _postChatStage = _PostChatStage.rating;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// La note part au serveur. L'affichage bascule immediatement sur « envoye » — faire
  /// attendre l'utilisateur devant trois emojis serait absurde — mais un echec est dit,
  /// et l'etat revient en arriere pour qu'il puisse reessayer.
  Future<void> _selectRating(HelpChatRating rating) async {
    final precedent = _selectedRating;
    setState(() {
      _selectedRating = rating;
      _postChatStage = _PostChatStage.sent;
    });
    try {
      await ref.read(helpCenterActionsProvider).rate(widget.helpChat.id, rating, null);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selectedRating = precedent;
        _postChatStage = _PostChatStage.rating;
      });
      _signaler("Votre note n'a pas pu etre envoyee.");
    }
  }

  void _signaler(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Envoie le message saisi. Le champ n'est vide qu'apres confirmation du serveur :
  /// perdre un texte parce que le reseau a laché est la pire facon d'echouer ici.
  Future<void> _sendMessage() async {
    final texte = _messageController.text.trim();
    if (texte.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await ref.read(helpCenterActionsProvider).sendMessage(widget.helpChat.id, texte);
      if (!mounted) return;
      _messageController.clear();
      _scrollToBottom();
    } catch (_) {
      _signaler("Votre message n'a pas pu etre envoye.");
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _dismissOverlay() {
    setState(() => _postChatStage = _PostChatStage.hidden);
  }

  void _showFeedbackSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FeedbackBottomSheet(
        onSubmit: (feedback) async {
          setState(() => _postChatStage = _PostChatStage.thankYou);
          final rating = _selectedRating;
          if (rating == null) return;
          try {
            await ref
                .read(helpCenterActionsProvider)
                .rate(widget.helpChat.id, rating, feedback);
          } catch (_) {
            _signaler("Votre commentaire n'a pas pu etre envoye.");
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(helpMessagesProvider(widget.helpChat.id));
    final l10n = AppLocalizations.of(context);

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.helpCenter,
                  style: const TextStyle(
                fontSize: 20,
                fontFamily: 'inter',
                fontWeight: AppWeights.semiBold,
                color: AppColors.chipSelected,
              ),
                ),
                Text(
                  l10n.customerService,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: AppWeights.regular,
                    color: AppColors.subtitleColor,
                    fontFamily: 'inter',
                  ),
                ),
              ],
            ),
          ],
        ),
        showBack: true,
        onLeadingPressed: () => context.pop(),
      ),
      bottomNavigationBar: null,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  messagesAsync.when(
                    data: (messages) {
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        itemCount:
                            messages.length + (_showTypingIndicator ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < messages.length) {
                            final msg = messages[index];
                            final bool showLabel = !msg.isFromUser &&
                                (index == 0 || messages[index - 1].isFromUser);
                            return HelpMessageBubble(
                              message: msg,
                              showAssistantLabel: showLabel,
                            );
                          }

                          if (_showTypingIndicator &&
                              index == messages.length) {
                            return _buildTypingIndicator();
                          }

                          return const SizedBox.shrink();
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

                  if (_postChatStage != _PostChatStage.hidden)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 12,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _postChatStage == _PostChatStage.rating
                              ? RateExperienceDialog(
                                  key: const ValueKey('rating'),
                                  onRatingSelected: _selectRating,
                                  onClose: _dismissOverlay,
                                )
                              : _postChatStage == _PostChatStage.sent
                                  ? _buildSentPill(key: const ValueKey('sent'))
                                  : _buildThankYouConfirmation(
                                      key: const ValueKey('thankYou'),
                                    ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            _buildInputBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Text(
            'Discussion assistant is typing ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.chipSelected.withOpacity(0.7),
              fontFamily: 'inter',
              fontStyle: FontStyle.italic,
            ),
          ),
          _buildDotAnimation(),
        ],
      ),
    );
  }

  Widget _buildDotAnimation() {
    return SizedBox(
      width: 24,
      height: 16,
      child: _TypingDots(),
    );
  }

  Widget _buildSentPill({Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F0FE),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 18),
          const SizedBox(width: 6),
          const Text(
            'Sent',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
              fontFamily: 'inter',
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 1,
            height: 16,
            color: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _showFeedbackSheet,
            child: const Text(
              'Tell us more',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.chipSelected,
                decoration: TextDecoration.underline,
                fontFamily: 'inter',
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _dismissOverlay,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 14,
                color: context.colors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThankYouConfirmation({Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F0FE),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 18),
          const SizedBox(width: 6),
          Text(
            AppLocalizations.of(context).thankYouForYourOpinion,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDarkest,
              fontFamily: 'inter',
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _dismissOverlay,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 14,
                color: context.colors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: context.colors.cardSurface,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.itemDivider,
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
                    ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.mic_none_rounded,
              size: 26,
              color: AppColors.chipSelected,
            ),
            const SizedBox(width: 12),
            // Il n'y avait ici qu'un micro et un « + » decoratifs : on pouvait ecrire,
            // jamais envoyer.
            _sending
                ? const SizedBox(
                    width: 26,
                    height: 26,
                    child: Padding(
                      padding: EdgeInsets.all(3),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : GestureDetector(
                    onTap: _sendMessage,
                    child: const Icon(
                      Icons.send_rounded,
                      size: 26,
                      color: AppColors.chipSelected,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.25;
            final value = ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity = (value < 0.5)
                ? (value * 2).clamp(0.3, 1.0)
                : ((1.0 - value) * 2).clamp(0.3, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration:const BoxDecoration(
                    color: AppColors.chipSelected,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
