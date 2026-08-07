import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_summary.dart';

abstract class ChatLocalDataSource {
  Future<List<ChatSummary>> getChats(ChatKind? kind);
  Future<List<ChatMessage>> getMessages(String chatId);
}

/// Mock — liste de chats + messages par conversation.
class ChatMockDataSource implements ChatLocalDataSource {
  static const _chats = <ChatSummary>[
    ChatSummary(
        id: 'c1',
        name: 'Kristin Watson',
        avatarUrl: 'https://i.pravatar.cc/150?img=31',
        lastMessage: 'Kristin reply to your assessment',
        kind: ChatKind.jobOffer,
        hiringContact: true,
        hasOffer: true,
        offerRole: 'UI/UX Designer',
        offerSalary: '\$15K/Mo'),
    ChatSummary(
        id: 'c2',
        name: 'Alberta Flores',
        avatarUrl: 'https://i.pravatar.cc/150?img=47',
        lastMessage: 'We were impressed with your profile…',
        kind: ChatKind.professional),
    ChatSummary(
        id: 'c3',
        name: 'William Gabel',
        avatarUrl: 'https://i.pravatar.cc/150?img=12',
        lastMessage: 'Hello! We received your application…',
        kind: ChatKind.jobOffer),
    ChatSummary(
        id: 'c4',
        name: 'Alberta Flores',
        avatarUrl: 'https://i.pravatar.cc/150?img=45',
        lastMessage: 'Alberta reply to your assessment',
        kind: ChatKind.professional),
  ];

  static const _messages = <String, List<ChatMessage>>{
    'c1': [
      ChatMessage(id: 'm1', text: 'Hello 👋 We\'ve received your application.', fromMe: false, time: '09:00'),
      ChatMessage(id: 'm2', text: 'Can you please tell us if you still available?', fromMe: false, time: '09:00'),
      ChatMessage(id: 'm3', text: 'We were impressed with your profile and would like to deal with you.', fromMe: false, time: '09:02'),
      ChatMessage(id: 'm4', text: 'We need to start at 20/06?', fromMe: false, time: '09:02'),
      ChatMessage(id: 'm5', text: 'Hello dear, yes I am still available', fromMe: true, time: '09:05'),
    ],
  };

  @override
  Future<List<ChatSummary>> getChats(ChatKind? kind) async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (kind == null) return _chats;
    return _chats.where((c) => c.kind == kind).toList();
  }

  @override
  Future<List<ChatMessage>> getMessages(String chatId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _messages[chatId] ??
        const [
          ChatMessage(id: 'd1', text: 'Hello 👋', fromMe: false, time: '08:00'),
          ChatMessage(id: 'd2', text: 'Hi! Thanks for reaching out.', fromMe: true, time: '08:02'),
        ];
  }
}
