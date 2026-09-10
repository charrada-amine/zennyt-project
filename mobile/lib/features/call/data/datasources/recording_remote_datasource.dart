import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';

class RecordingRemoteDataSource {
  final Dio dio;

  RecordingRemoteDataSource(this.dio);

  Future<void> uploadChunk({
    required String sessionId,
    required int sequenceNumber,
    required String filePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'sessionId': sessionId,
        'sequenceNumber': sequenceNumber,
        'file': await MultipartFile.fromFile(
          filePath,
          filename: '${sessionId}_$sequenceNumber.mp4',
        ),
      });

      final response = await dio.post(
        '/api/v1/calls/recording/chunks',
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          'Upload failed with status ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw handleDioException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
