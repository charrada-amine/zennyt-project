import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zennyt/features/home/presentation/providers/home_providers.dart';
import '../../../../core/di/injection.dart';
import '../../domain/usecases/get_help_chats.dart';
import '../../domain/usecases/get_help_messages.dart';
import '../../domain/entities/help_chat.dart';
import '../../domain/entities/help_message.dart';

final getHelpChatsProvider = Provider<GetHelpChats>((ref) {
  return sl();
});

final getHelpMessagesUseCaseProvider = Provider<GetHelpMessages>((ref) {
  return sl();
});

final helpChatsProvider = FutureProvider<List<HelpChat>>((ref) async {
  final getHelpChats = ref.watch(getHelpChatsProvider);
  final currentUser = await ref.watch(currentUserProvider.future);
  final result = await getHelpChats(currentUser.id);
  return result.fold(
    (failure) => throw failure,
    (chats) => chats,
  );
});

final helpMessagesProvider =
    FutureProvider.family<List<HelpMessage>, String>((ref, helpChatId) async {
  final usecase = ref.watch(getHelpMessagesUseCaseProvider);
  final currentUser = await ref.watch(currentUserProvider.future);
  final result = await usecase(helpChatId, currentUser.id);
  return result.fold(
    (failure) => throw failure,
    (messages) => messages,
  );
});
