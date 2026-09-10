import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/help_chat_model.dart';
import '../models/help_message_model.dart';

abstract class HelpChatRemoteDataSource {
  Future<List<HelpChatModel>> getHelpChats(String userId);
  Future<List<HelpMessageModel>> getHelpMessages(String helpChatId, String userId);
  Future<HelpChatModel> openHelpChat({String? title, String? subtitle});
  Future<HelpMessageModel> sendHelpMessage(String helpChatId, String text);
  Future<HelpChatModel> rateHelpChat(String helpChatId, String rating, String? comment);
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

  @override
  Future<HelpChatModel> openHelpChat({String? title, String? subtitle}) async {
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '/api/v1/help-chats',
        data: {
          if (title != null) 'title': title,
          if (subtitle != null) 'subtitle': subtitle,
        },
      );
      return HelpChatModel.fromJson(res.data!);
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }

  @override
  Future<HelpMessageModel> sendHelpMessage(String helpChatId, String text) async {
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '/api/v1/help-chats/$helpChatId/messages',
        data: {'text': text},
      );
      return HelpMessageModel.fromJson(res.data!);
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }

  @override
  Future<HelpChatModel> rateHelpChat(
      String helpChatId, String rating, String? comment) async {
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '/api/v1/help-chats/$helpChatId/rating',
        data: {'rating': rating, if (comment != null) 'comment': comment},
      );
      return HelpChatModel.fromJson(res.data!);
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }
}
