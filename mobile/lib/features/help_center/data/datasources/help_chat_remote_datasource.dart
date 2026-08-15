import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/help_chat_model.dart';
import '../models/help_message_model.dart';

abstract class HelpChatRemoteDataSource {
  Future<List<HelpChatModel>> getHelpChats(String userId);
  Future<List<HelpMessageModel>> getHelpMessages(String helpChatId,String userId);
}

class HelpChatRemoteDataSourceImpl implements HelpChatRemoteDataSource {
  final Dio dio;

  HelpChatRemoteDataSourceImpl(this.dio);

  @override
  Future<List<HelpChatModel>> getHelpChats(String userId) async {
    try {
      final res = await dio.get(
        '/api/v1/help-chats',
      );

      return (res.data as List<dynamic>)
          .map((e) => HelpChatModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }

  @override
  Future<List<HelpMessageModel>> getHelpMessages(String helpChatId,String userId) async {
    try {
      final res = await dio.get(
        '/api/v1/help-chats/$helpChatId/messages',
      );
      return (res.data as List<dynamic>)
          .map((e) => HelpMessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }
}
