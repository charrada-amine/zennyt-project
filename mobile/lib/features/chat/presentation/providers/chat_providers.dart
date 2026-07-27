import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/di/injection.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../domain/usecases/get_chats.dart';
import '../../domain/usecases/get_messages.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/mark_conversation_read.dart';
import '../../domain/entities/chat.dart';
import '../../domain/entities/message.dart';

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
final messagesProvider =
    FutureProvider.family<List<Message>, String>((ref, conversationId) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  final usecase = ref.watch(getMessagesUseCaseProvider);
  final result = await usecase(GetMessagesParams(
      conversationId: conversationId, userId: currentUser.id));
  return result.fold(
    (failure) {
      throw failure;
    },
    (messages) => messages,
  );
});

// --- UI State Providers ---
final chatFilterProvider = StateProvider<int>((ref) => 0);
