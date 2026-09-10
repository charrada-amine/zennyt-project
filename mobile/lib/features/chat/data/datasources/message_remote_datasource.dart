import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/message.dart';
import '../models/message_model.dart';

/// Source distante pour les messages d'une conversation.
abstract class MessageRemoteDataSource {
  /// GET /conversations/{conversationId}/messages
  Future<List<MessageModel>> getMessages(String conversationId, String userId);

  /// POST /conversations/{conversationId}/messages
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String userId,
    required String content,
    MessageContentType contentType = MessageContentType.text,
    String? attachmentUrl,
  });
}

class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  final Dio dio;

  MessageRemoteDataSourceImpl(this.dio);

  @override
  Future<List<MessageModel>> getMessages(
      String conversationId, String userId) async {
    try {
      final res = await dio.get(
        '/conversations/$conversationId/messages',
      );
      final data = res.data;
      final List<dynamic> items = data is List<dynamic> ? data : [];
      return items
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }

  @override
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String userId,
    required String content,
    MessageContentType contentType = MessageContentType.text,
    String? attachmentUrl,
  }) async {
    try {
      final body = MessageCreateModel(
        content: content,
        contentType: contentType,
        attachmentUrl: attachmentUrl,
      );
      final res = await dio.post(
        '/conversations/$conversationId/messages',
        data: body.toJson(),
      );
      return MessageModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }
}
