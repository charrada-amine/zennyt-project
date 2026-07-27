import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/call.dart';
import '../models/call_model.dart';

abstract class CallRemoteDataSource {
  Future<CallModel> getCall(String id);
  Future<void> startCall(CallModel call);
  Future<void> endCall(String id);
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
  Future<void> startCall(CallModel call) async {
    try {
      await dio.post(
        '/api/v1/calls/start',
        data: {
          'conversationId': call.id,
          'type': call.type == CallType.audio ? 'AUDIO' : 'VIDEO',
          'webrtcOffer': '',
        },
      );
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }

  @override
  Future<void> endCall(String id) async {
    try {
      await dio.post('/api/v1/calls/$id/end');
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }
}