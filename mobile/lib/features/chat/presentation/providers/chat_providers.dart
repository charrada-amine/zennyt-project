import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../domain/usecases/get_chats.dart';
import '../../domain/usecases/get_messages.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/mark_conversation_read.dart';
import '../../domain/entities/chat.dart';
import '../../domain/entities/message.dart';
import '../../data/models/message_model.dart';

// --- Use Cases ---
final getConversationsUseCaseProvider = Provider<GetConversations>((ref) {
  return sl();
});

final getMessagesUseCaseProvider = Provider<GetMessages>((ref) {
  return sl();
});

final sendMessageUseCaseProvider = Provider<SendMessage>((ref) {
  return sl();
});

final markConversationReadUseCaseProvider =
    Provider<MarkConversationRead>((ref) {
  return sl();
});

// --- Providers ---

/// Conversations de l'utilisateur connecté.
final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  final usecase = ref.watch(getConversationsUseCaseProvider);
  final result = await usecase(currentUser.id);

  return result.fold(
    (failure) => throw failure,
    (conversations) => conversations,
  );
});

/// Messages d'une conversation spécifique.
///
/// Notifier avec état : l'historique est chargé par HTTP (`GetMessages`), puis
/// les messages reçus en temps réel (WebSocket) sont insérés directement via
/// [ConversationMessagesNotifier.addIncoming] sans refetch. Côté expéditeur,
/// la réponse du POST d'envoi est également insérée de la même façon.
final messagesProvider = AsyncNotifierProvider.family<
    ConversationMessagesNotifier,
    List<Message>,
    String>(ConversationMessagesNotifier.new);

/// Notifier avec état des messages d'une conversation : charge l'historique par
/// HTTP puis reçoit les messages temps réel via [addIncoming] (WebSocket pour le
/// destinataire, réponse du POST pour l'expéditeur) sans refetch.
///
/// L'attribution des bulles ne se fait pas ici : c'est [Conversation.myRole]
/// (fourni par le backend) comparé au `senderRole` du message.
class ConversationMessagesNotifier extends AsyncNotifier<List<Message>> {
  ConversationMessagesNotifier(this.conversationId);

  /// Identifiant de la conversation (argument du family).
  final String conversationId;

  /// Messages reçus hors de l'historique HTTP (WebSocket ou réponse de POST).
  /// Conservés séparément pour être fusionnés lors de chaque `build`/`addIncoming`.
  final List<Message> _injected = [];

  @override
  Future<List<Message>> build() async {
    final currentUser = await ref.watch(currentUserProvider.future);
    final usecase = ref.watch(getMessagesUseCaseProvider);
    final result = await usecase(GetMessagesParams(
        conversationId: conversationId, userId: currentUser.id));

    final history = result.fold(
      (failure) => throw failure,
      (messages) => messages,
    );
    return _merged(history);
  }

  /// Insère un message (WebSocket ou réponse du POST) sans relancer le fetch.
  void addIncoming(Message message) {
    if (_injected.any((m) => m.id == message.id)) return;
    _injected.add(message);
    if (!ref.mounted) return;
    state = AsyncData(_merged(state.value ?? const []));
  }

  /// Fusionne l'historique HTTP et les messages injectés, sans doublon,
  /// triés du plus récent au plus ancien (ordre attendu par la ListView reverse).
  List<Message> _merged(List<Message> history) {
    final byId = <String, Message>{for (final m in history) m.id: m};
    for (final m in _injected) {
      byId.putIfAbsent(m.id, () => m);
    }
    final merged = byId.values.toList();
    merged.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return merged;
  }
}

/// Flux temps réel des messages entrants, abonné à la file STOMP
/// `/user/queue/messages` (cf. `WebSocketService._subscribeToUserQueues`).
///
/// Le payload est un `Message` conforme au contrat OpenAPI. Le provider est
/// auto-disposable : il reste vivant tant qu'une page l'écoute et libère
/// l'abonnement quand plus personne ne l'observe.
final realtimeMessageStreamProvider =
    StreamProvider<Message>((ref) {
  final controller = StreamController<Message>();
  final ws = WebSocketService();

  void onMessage(Map<String, dynamic> payload) {
    try {
      controller.add(MessageModel.fromJson(payload).toEntity());
    } catch (e) {
      debugPrint('⚠️ Realtime message parse failed: $e');
    }
  }

  ws.subscribe('messages', onMessage);
  ref.onDispose(() {
    controller.close();
    ws.unsubscribeCallback('messages');
  });

  return controller.stream;
});

// --- UI State Providers ---
final chatFilterProvider = StateProvider<int>((ref) => 0);
