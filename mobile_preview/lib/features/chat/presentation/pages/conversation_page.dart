import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/opportunity_remote_datasource.dart';
import '../../domain/entities/chat_summary.dart';
import '../bloc/conversation_bloc.dart';
import '../widgets/job_opportunity_card.dart';
import '../widgets/message_bubble.dart';

class ConversationPage extends StatefulWidget {
  final ChatSummary chat;
  const ConversationPage({super.key, required this.chat});
  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    context.read<ConversationBloc>().add(MessageSent(text));
    _controller.clear();
  }

  /// Confirme l'offre d'opportunité pour de vrai (envoi recruteur → confirm
  /// candidat → vérification OTP), puis met à jour l'UI de la conversation.
  Future<void> _confirmOffer(ConversationBloc bloc) async {
    String? error;
    try {
      await sl<OpportunityRemoteDataSource>().confirm();
    } catch (_) {
      error = 'Confirmation hors-ligne (UI seulement)';
    }
    if (!mounted) return;
    bloc.add(const OfferConfirmed());
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Offre confirmée ✅')));
  }

  /// Rejette l'offre d'opportunité côté backend, puis met à jour l'UI.
  Future<void> _rejectOffer(ConversationBloc bloc) async {
    try {
      await sl<OpportunityRemoteDataSource>().reject();
    } catch (_) {
      // Non bloquant : on bascule quand même l'UI.
    }
    if (!mounted) return;
    bloc.add(const OfferRejected());
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.navy,
        elevation: 0.5,
        titleSpacing: 0,
        leading: IconButton(
            icon: const Icon(Icons.chevron_left), onPressed: () => context.pop()),
        title: Row(children: [
          CircleAvatar(radius: 16, backgroundImage: NetworkImage(chat.avatarUrl)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(chat.name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.navy)),
              Text(chat.kind == ChatKind.jobOffer ? 'Recruiter' : 'Professional',
                  style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
            ],
          ),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: AppTheme.brandBlue, size: 20),
            onPressed: () => context.push('/call', extra: chat),
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: AppTheme.brandBlue, size: 22),
            onPressed: () => context.push('/call', extra: chat),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.muted),
            onSelected: (v) => ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('$v — à venir'))),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'Report', child: Text('Report')),
              PopupMenuItem(value: 'Block', child: Text('Block')),
            ],
          ),
        ],
      ),
      body: BlocBuilder<ConversationBloc, ConversationState>(
        builder: (context, state) {
          final bloc = context.read<ConversationBloc>();
          return Column(
            children: [
              if (chat.hasOffer && state.offerStatus == OfferStatus.pending)
                JobOpportunityCard(
                  chat: chat,
                  onConfirm: () => _showConfirmationSms(context, bloc),
                  onReject: () => _rejectOffer(bloc),
                ),
              Expanded(
                child: state.status == ConvStatus.loading ||
                        state.status == ConvStatus.initial
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        itemCount: state.messages.length,
                        itemBuilder: (context, i) =>
                            MessageBubble(message: state.messages[i]),
                      ),
              ),
              _inputBar(),
            ],
          );
        },
      ),
    );
  }

  void _showConfirmationSms(BuildContext context, ConversationBloc bloc) {
    const code = ['7', '4', '5', '5', '5', '8'];
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Text('Confirmation SMS',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.brandBlue)),
          const Spacer(),
          InkWell(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, size: 18, color: AppTheme.muted)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'A confirmation code has been sent to your mobile number as '
                'electronic signature. Enter it to continue.',
                style: TextStyle(color: AppTheme.muted, fontSize: 12)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final d in code)
                  Container(
                    width: 38,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF22A06B)),
                    ),
                    child: Text(d,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.navy)),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          Center(
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.brandBlue),
              onPressed: () {
                Navigator.pop(context);
                _confirmOffer(bloc);
              },
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.hairline)),
        ),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Send message…',
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF4F5F8),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.mic_none, color: AppTheme.muted),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.send, color: AppTheme.brandBlue),
            onPressed: _send,
          ),
        ]),
      ),
    );
  }
}
