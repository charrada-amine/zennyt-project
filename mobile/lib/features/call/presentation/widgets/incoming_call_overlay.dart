import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:zennyt/core/network/websocket_service.dart';
import 'package:zennyt/core/router/app_router.dart';
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
  final String? callId;

  const IncomingCallState({
    this.isActive = false,
    this.conversationId,
    this.senderId,
    this.senderName,
    this.channelName,
    this.isVideoCall = false,
    this.callId,
  });

  IncomingCallState copyWith({
    bool? isActive,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? channelName,
    bool? isVideoCall,
    String? callId,
  }) {
    return IncomingCallState(
      isActive: isActive ?? this.isActive,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      channelName: channelName ?? this.channelName,
      isVideoCall: isVideoCall ?? this.isVideoCall,
      callId: callId ?? this.callId,
    );
  }
}

class IncomingCallNotifier extends StateNotifier<IncomingCallState> {
  final CallSignalingRepository _signaling;
  final WebSocketService _webSocketService;
  final Ref _ref;
  Timer? _timeoutTimer;

  IncomingCallNotifier(this._signaling, this._webSocketService, this._ref)
    : super(const IncomingCallState()) {
       debugPrint('🎯 IncomingCallNotifier created, listening for invites');
    _listenForInvites();
  }

  void _listenForInvites() {
    _signaling.onCallInvite((data) {
      debugPrint('📞 onCallInvite fired: $data');
      final initiatorId = data['initiatorId'] as String?;
      if (initiatorId == null) return;

      _signaling.onEndCall((_) => dismiss());
      _signaling.onReject((_) => dismiss());

      final callId = data['callId'] as String?;

      state = IncomingCallState(
        isActive: true,
        conversationId: data['conversationId'] as String?,
        senderId: initiatorId,
        senderName: data['senderName'] as String? ?? 'Appelant',
        channelName:
            data['conversationId']
                as String?, // no channelName field from backend, conversationId doubles as channel
        isVideoCall: (data['type'] as String?)?.toUpperCase() == 'VIDEO',
        callId: callId,
      );

      // Start 1-minute timeout timer
      _timeoutTimer?.cancel();
      _timeoutTimer = Timer(const Duration(minutes: 1), () {
        if (state.isActive) {
          debugPrint('⏳ Incoming call timed out after 1 minute without answer');
          final myUserId = _ref.read(currentUserProvider).value?.id ?? '';
          _signaling.sendReject(
            conversationId: state.conversationId ?? '',
            senderId: myUserId,
            counterpartId: state.senderId,
          );
          if (state.callId != null) {
            _ref.read(callNotifierProvider.notifier).endCall(state.callId!);
          }
          dismiss();
        }
      });
    });

    _signaling.onEndCall((data) {
      debugPrint('📞 onEndCall fired on incoming call overlay: $data');
      dismiss();
    });

    _signaling.onReject((data) {
      debugPrint('📞 onReject fired on incoming call overlay: $data');
      dismiss();
    });
  }

  void dismiss() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    state = const IncomingCallState();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }
}

final incomingCallProvider =
    StateNotifierProvider<IncomingCallNotifier, IncomingCallState>((ref) {
      return IncomingCallNotifier(
        ref.read(callSignalingRepositoryProvider),
        ref.read(webSocketServiceProvider),
        ref,
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
                            if (incomingCall.callId != null) {
                              ref
                                  .read(callNotifierProvider.notifier)
                                  .endCall(incomingCall.callId!);
                            }
                            ref.read(incomingCallProvider.notifier).dismiss();
                          },
                        ),
                        // Accepter
                        _CallActionButton(
                          icon: Icons.call,
                          color: Colors.green,
                          label: 'Accepter',
                          onTap: () async {
                            debugPrint('📞 Accept button pressed');
                            debugPrint('📞 Incoming call data: conversationId=${incomingCall.conversationId}, senderId=${incomingCall.senderId}, callId=${incomingCall.callId}, isVideoCall=${incomingCall.isVideoCall}');
                            
                            // Check WebSocket connection
                            final ws = ref.read(webSocketServiceProvider);
                            if (!ws.isConnected) {
                              debugPrint('❌ WebSocket not connected! Cannot accept call.');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Connexion perdue. Réessayez.')),
                              );
                              return;
                            }
                            
                            ref.read(incomingCallProvider.notifier).dismiss();
                            
                            try {
                              final myUserId = ref.read(currentUserProvider).value?.id;
                              debugPrint('📞 My user ID: $myUserId');
                              
                              if (myUserId == null || myUserId.isEmpty) {
                                debugPrint('❌ No user ID available');
                                return;
                              }
                              
                              // Use router from provider instead of context.push()
                              final router = ref.read(goRouterProvider);
                              router.push(
                                '/call',
                                extra: {
                                  'contactName': incomingCall.senderName ?? 'Appelant',
                                  'conversationId': incomingCall.conversationId,
                                  'counterpartId': incomingCall.senderId,
                                  'myUserId': myUserId,
                                  'incomingOffer': {
                                    'isVideoCall': incomingCall.isVideoCall,
                                    'channelName': incomingCall.channelName,
                                    'callId': incomingCall.callId,
                                  },
                                },
                              );
                              debugPrint('✅ Navigation to call page completed');
                            } catch (e, stack) {
                              debugPrint('❌ Error navigating to call page: $e');
                              debugPrint('Stack: $stack');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur: $e')),
                              );
                            }
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
