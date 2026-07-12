import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/core/error/api_exception.dart';
import 'package:zennyt/core/upload/cv_file_validation.dart';
import 'package:zennyt/core/upload/picked_file.dart';
import 'package:zennyt/core/upload/upload_service.dart';

void main() {
  group('CV upload validation', () {
    test('accepts a PDF at the API size limit', () {
      expect(
        () => CvFileValidation.validateUploadBytes(
          'candidate.pdf',
          Uint8List(CvFileValidation.maximumSizeBytes),
        ),
        returnsNormally,
      );
    });

    test('rejects a file above the API size limit', () {
      expect(
        () => CvFileValidation.validateUploadBytes(
          'candidate.pdf',
          Uint8List(CvFileValidation.maximumSizeBytes + 1),
        ),
        throwsA(isA<CvFileValidationException>()),
      );
    });

    test('rejects an unsupported CV format', () {
      expect(
        () =>
            CvFileValidation.validateUploadBytes('candidate.png', Uint8List(1)),
        throwsA(isA<CvFileValidationException>()),
      );
    });
  });

  group('DioUploadService', () {
    test('returns the cvUrl returned by the profile endpoint', () async {
      final dio = Dio()
        ..httpClientAdapter = _Adapter(
          200,
          '{"cvUrl":"https://example.test/cv.pdf"}',
        );
      final service = DioUploadService(dio);

      final url = await service.upload(
        PickedFile(name: 'candidate.pdf', bytes: Uint8List.fromList([1, 2])),
        kind: UploadKind.cv,
      );

      expect(url, 'https://example.test/cv.pdf');
    });

    test(
      'maps a failed upload to an ApiException instead of hiding it',
      () async {
        final dio = Dio()
          ..httpClientAdapter = _Adapter(
            500,
            '{"message":"Storage unavailable"}',
          );
        final service = DioUploadService(dio);

        expect(
          () => service.upload(
            PickedFile(name: 'candidate.pdf', bytes: Uint8List.fromList([1])),
            kind: UploadKind.cv,
          ),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
