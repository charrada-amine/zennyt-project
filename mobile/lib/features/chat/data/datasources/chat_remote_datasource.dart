import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/chat_model.dart';

/// Source distante pour les conversations.
abstract class ConversationRemoteDataSource {
  /// GET /conversations — les conversations de l'utilisateur connecté.
  Future<List<ConversationModel>> getConversations(String userId);

  /// POST /conversations — démarrer une conversation liée à une candidature.
  Future<ConversationModel> createConversation(
      String applicationId, String userId);

  /// POST /conversations/{conversationId}/read — marquer comme lue.
  Future<void> markConversationRead(String conversationId, String userId);
}

class ConversationRemoteDataSourceImpl implements ConversationRemoteDataSource {
  final Dio dio;

  ConversationRemoteDataSourceImpl(this.dio);

  @override
  Future<List<ConversationModel>> getConversations(String userId) async {
    try {
      final res = await dio.get('/conversations');
      final data = res.data;
      final List<dynamic> items = data is Map<String, dynamic>
          ? (data['content'] as List<dynamic>? ?? [])
          : (data as List<dynamic>);
      return items
          .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }

  @override
  Future<ConversationModel> createConversation(
      String applicationId, String userId) async {
    try {
      final res = await dio.post(
        '/conversations',
        data: {
          'applicationId': applicationId,
        },
      );
      return ConversationModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }

  @override
  Future<void> markConversationRead(
      String conversationId, String userId) async {
    try {
      await dio.post('/conversations/$conversationId/read');
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }
}
