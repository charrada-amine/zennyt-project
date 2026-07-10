import 'package:dio/dio.dart';
import '../../../../../core/error/api_exception.dart';
import '../domain/cv_parsed_data.dart';

class CvParseApiService {
  final Dio _dio;

  CvParseApiService(this._dio);

  Future<CvParsedData> parseCvData(String text, String languageCode) async {
    try {
      final response = await _dio.post(
        '/profiles/me/cv/parse',
        data: {
          'text': text,
          'language': languageCode,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        ),
      );

      return CvParsedData.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
