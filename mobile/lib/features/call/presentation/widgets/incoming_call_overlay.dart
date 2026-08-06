import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:zennyt/core/network/websocket_service.dart';
import 'package:zennyt/features/call/data/repositories/call_signaling_repository_impl.dart';
import 'package:zennyt/features/call/domain/repositories/call_signaling_repository.dart';
import 'package:zennyt/features/call/presentation/providers/call_provider.dart';
import 'package:zennyt/features/home/presentation/providers/home_providers.dart';

/// État de l'appel entrant.
class IncomingCallState {
  final bool isActive;
  final String? conversationId;
  final String? senderId;
  final String? senderName;
  final String? channelName;
  final bool isVideoCall;

  const IncomingCallState({
    this.isActive = false,
    this.conversationId,
    this.senderId,
    this.senderName,
    this.channelName,
    this.isVideoCall = false,
  });

  IncomingCallState copyWith({
    bool? isActive,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? channelName,
    bool? isVideoCall,
  }) {
    return IncomingCallState(
      isActive: isActive ?? this.isActive,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      channelName: channelName ?? this.channelName,
      isVideoCall: isVideoCall ?? this.isVideoCall,
    );
  }
}

class IncomingCallNotifier extends StateNotifier<IncomingCallState> {
  final CallSignalingRepository _signaling;
  final WebSocketService _webSocketService;
  IncomingCallNotifier(this._signaling, this._webSocketService)
    : super(const IncomingCallState()) {
       debugPrint('🎯 IncomingCallNotifier created, listening for invites');
    _listenForInvites();
  }

  void _listenForInvites() {
    _signaling.onCallInvite((data) {
      debugPrint('📞 onCallInvite fired: $data');
      final initiatorId = data['initiatorId'] as String?;
      if (initiatorId == null) return;

      state = IncomingCallState(
        isActive: true,
        conversationId: data['conversationId'] as String?,
        senderId: initiatorId,
        senderName: data['senderName'] as String? ?? 'Appelant',
        channelName:
            data['conversationId']
                as String?, // no channelName field from backend, conversationId doubles as channel
        isVideoCall: (data['type'] as String?)?.toUpperCase() == 'VIDEO',
      );
    });
  }

  void dismiss() {
    state = const IncomingCallState();
  }
}

final incomingCallProvider =
    StateNotifierProvider<IncomingCallNotifier, IncomingCallState>((ref) {
      return IncomingCallNotifier(
        ref.read(callSignalingRepositoryProvider),
        ref.read(webSocketServiceProvider),
      );
    });

/// Widget overlay qui affiche l'écran d'appel entrant par-dessus tout.
class IncomingCallOverlay extends ConsumerWidget {
  final Widget child;

  const IncomingCallOverlay({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomingCall = ref.watch(incomingCallProvider);

    ref.listen<IncomingCallState>(incomingCallProvider, (previous, next) {
      if (previous?.isActive == true && !next.isActive) {
        // L'appel entrant a été dismiss, rien à faire
      }
    });

    return Stack(
      children: [
        child,
        if (incomingCall.isActive) ...[
          Positioned.fill(
            child: Material(
              color: Colors.black87,
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    // Avatar
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        incomingCall.isVideoCall ? Icons.videocam : Icons.phone,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Nom de l'appelant
                    Text(
                      incomingCall.senderName ?? 'Appelant',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Type d'appel
                    Text(
                      incomingCall.isVideoCall
                          ? 'Appel vidéo entrant'
                          : 'Appel audio entrant',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(flex: 3),
                    // Boutons Accepter / Refuser
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Refuser
                        _CallActionButton(
                          icon: Icons.call_end,
                          color: Colors.red,
                          label: 'Refuser',
                          onTap: () {
                            final myUserId =
                                ref.read(currentUserProvider).value?.id ?? '';
                            ref
                                .read(callSignalingRepositoryProvider)
                                .sendReject(
                                  conversationId:
                                      incomingCall.conversationId ?? '',
                                  senderId: myUserId,
                                  counterpartId: incomingCall.senderId,
                                );
                            ref.read(incomingCallProvider.notifier).dismiss();
                          },
                        ),
                        // Accepter
                        _CallActionButton(
                          icon: Icons.call,
                          color: Colors.green,
                          label: 'Accepter',
                          onTap: () {
                            ref.read(incomingCallProvider.notifier).dismiss();
                            context.push(
                              '/call',
                              extra: {
                                'contactName':
                                    incomingCall.senderName ?? 'Appelant',
                                'conversationId': incomingCall.conversationId,
                                'counterpartId': incomingCall.senderId,
                                'myUserId': ref
                                    .read(currentUserProvider)
                                    .value
                                    ?.id,
                                'incomingOffer': {
                                  'isVideoCall': incomingCall.isVideoCall,
                                  'channelName': incomingCall.channelName,
                                },
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _CallActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
