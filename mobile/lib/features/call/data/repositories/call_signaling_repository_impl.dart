import '../../../../core/network/websocket_service.dart';
import '../../domain/repositories/call_signaling_repository.dart';

class CallSignalingRepositoryImpl implements CallSignalingRepository {
  final WebSocketService webSocketService;

  CallSignalingRepositoryImpl({required this.webSocketService});

  String _dest(String conversationId, String action) =>
      '/app/call/$conversationId/$action';

  @override
  void sendCallInvite({
    required String conversationId,
    required String senderId,
    String? counterpartId,
    required String channelName,
    required bool isVideoCall,
  }) {
    webSocketService.send(_dest(conversationId, 'invite'), {
      'senderId': senderId,
      'counterpartId': counterpartId,
      'channelName': channelName,
      'callType': isVideoCall ? 'video' : 'audio',
      'isVideoCall': isVideoCall,
    });
  }

  @override
  void sendAccept({
    required String conversationId,
    required String senderId,
    String? counterpartId,
  }) {
    webSocketService.send(_dest(conversationId, 'accept'), {
      'senderId': senderId,
      'counterpartId': counterpartId,
    });
  }

  @override
  void sendReject({
    required String conversationId,
    required String senderId,
    String? counterpartId,
  }) {
    webSocketService.send(_dest(conversationId, 'reject'), {
      'senderId': senderId,
      'counterpartId': counterpartId,
    });
  }

  @override
  void sendEndCall({
    required String conversationId,
    required String senderId,
    String? counterpartId,
  }) {
    webSocketService.send(_dest(conversationId, 'end'), {
      'senderId': senderId,
      'counterpartId': counterpartId,
    });
  }

  @override
  void onCallInvite(void Function(Map<String, dynamic> data) callback) {
    webSocketService.subscribe('call/invite', callback);
  }

  @override
  void onAccept(void Function(Map<String, dynamic> data) callback) {
    webSocketService.subscribe('call/accept', callback);
  }

  @override
  void onReject(void Function(Map<String, dynamic> data) callback) {
    webSocketService.subscribe('call/reject', callback);
  }

  @override
  void onEndCall(void Function(Map<String, dynamic> data) callback) {
    webSocketService.subscribe('call/end', callback);
  }

  @override
  void dispose() {
    // Ne retire PAS `call/invite` : ce callback appartient au notifier global
    // de l'overlay d'appel entrant (incomingCallProvider), pas à la page d'appel.
    webSocketService.unsubscribeCallback('call/accept');
    webSocketService.unsubscribeCallback('call/reject');
    webSocketService.unsubscribeCallback('call/end');
  }
}
