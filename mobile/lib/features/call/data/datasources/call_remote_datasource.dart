import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/call.dart';
import '../models/call_model.dart';

abstract class CallRemoteDataSource {
  Future<CallModel> getCall(String id);
  Future<String> startCall(CallModel call);
  Future<void> endCall(String id);
  Future<void> joinCall(String callId);
}

class CallRemoteDataSourceImpl implements CallRemoteDataSource {
  final Dio dio;

  CallRemoteDataSourceImpl(this.dio);

  @override
  Future<CallModel> getCall(String id) async {
    throw ServerException(
      'GET /api/v1/calls/{id} is not supported by the backend',
      statusCode: 405,
    );
  }

  @override
  Future<String> startCall(CallModel call) async {
    try {
      final res = await dio.post(
        '/calls/start',
        data: {
          'conversationId': call.id,
          'type': call.type == CallType.audio ? 'AUDIO' : 'VIDEO',
          'webrtcOffer': 'dummy_offer',
        },
      );
      final data = res.data as Map<String, dynamic>;
      return data['id'] as String;
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }

  @override
  Future<void> endCall(String id) async {
    try {
      await dio.post('/calls/$id/end');
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }

  @override
  Future<void> joinCall(String callId) async {
    try {
      await dio.post(
        '/calls/$callId/join',
        data: {
          'webrtcAnswer': 'dummy_answer',
        },
      );
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }
}