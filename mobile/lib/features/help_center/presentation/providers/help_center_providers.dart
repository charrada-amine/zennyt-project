import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zennyt/features/home/presentation/providers/home_providers.dart';
import '../../../../core/di/injection.dart';
import '../../domain/usecases/get_help_chats.dart';
import '../../domain/usecases/get_help_messages.dart';
import '../../domain/usecases/open_help_chat.dart';
import '../../domain/usecases/rate_help_chat.dart';
import '../../domain/usecases/send_help_message.dart';
import '../../domain/entities/help_chat.dart';
import '../../domain/entities/help_message.dart';

final getHelpChatsProvider = Provider<GetHelpChats>((ref) {
  return sl();
});

final getHelpMessagesUseCaseProvider = Provider<GetHelpMessages>((ref) {
  return sl();
});

final openHelpChatProvider = Provider<OpenHelpChat>((ref) => sl());
final sendHelpMessageProvider = Provider<SendHelpMessage>((ref) => sl());
final rateHelpChatProvider = Provider<RateHelpChat>((ref) => sl());

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

/// Actions du centre d'aide — ouvrir, envoyer, noter.
///
/// Regroupees dans un controleur plutot qu'appelees depuis l'ecran : chaque action doit
/// rafraichir la liste ou les messages une fois terminee, et disperser ces invalidations
/// dans les widgets finit toujours par en laisser une de cote.
class HelpCenterActions {
  const HelpCenterActions(this._ref);
  final Ref _ref;

  Future<HelpChat> openChat({String? title, String? subtitle}) async {
    final result =
        await _ref.read(openHelpChatProvider)(title: title, subtitle: subtitle);
    return result.fold((failure) => throw failure, (chat) {
      _ref.invalidate(helpChatsProvider);
      return chat;
    });
  }

  Future<HelpMessage> sendMessage(String helpChatId, String text) async {
    final result = await _ref.read(sendHelpMessageProvider)(helpChatId, text);
    return result.fold((failure) => throw failure, (message) {
      _ref.invalidate(helpMessagesProvider(helpChatId));
      _ref.invalidate(helpChatsProvider);
      return message;
    });
  }

  Future<HelpChat> rate(String helpChatId, HelpChatRating rating, String? comment) async {
    final result = await _ref.read(rateHelpChatProvider)(helpChatId, rating, comment);
    return result.fold((failure) => throw failure, (chat) {
      _ref.invalidate(helpChatsProvider);
      return chat;
    });
  }
}

final helpCenterActionsProvider =
    Provider<HelpCenterActions>((ref) => HelpCenterActions(ref));
