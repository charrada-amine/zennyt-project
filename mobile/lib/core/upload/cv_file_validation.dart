import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// Validation shared by each mobile CV upload entry point.
///
/// The values mirror the identity API contract: PDF, DOC and DOCX up to 5 MB.
class CvFileValidation {
  const CvFileValidation._();

  static const int maximumSizeBytes = 5 * 1024 * 1024;
  static const Set<String> uploadExtensions = {'.pdf', '.doc', '.docx'};
  static const Set<String> ocrExtensions = {
    '.pdf',
    '.png',
    '.jpg',
    '.jpeg',
    '.webp',
  };

  static Future<void> validateUploadPath(String path) async {
    final file = File(path);
    _validate(
      name: p.basename(path),
      length: await file.length(),
      allowedExtensions: uploadExtensions,
      purpose: 'upload',
    );
  }

  static Future<void> validateOcrPath(String path) async {
    final file = File(path);
    _validate(
      name: p.basename(path),
      length: await file.length(),
      allowedExtensions: ocrExtensions,
      purpose: 'OCR',
    );
  }

  static void validateUploadBytes(String name, Uint8List bytes) {
    _validate(
      name: name,
      length: bytes.lengthInBytes,
      allowedExtensions: uploadExtensions,
      purpose: 'upload',
    );
  }

  static String uploadContentType(String name) {
    switch (p.extension(name).toLowerCase()) {
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        throw const CvFileValidationException('Unsupported upload format.');
    }
  }

  static void _validate({
    required String name,
    required int length,
    required Set<String> allowedExtensions,
    required String purpose,
  }) {
    final extension = p.extension(name).toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      final formats = allowedExtensions
          .map((item) => item.substring(1).toUpperCase())
          .join(', ');
      throw CvFileValidationException(
        'Unsupported $purpose format. Use $formats.',
      );
    }
    if (length > maximumSizeBytes) {
      throw const CvFileValidationException('Your CV must be 5 MB or smaller.');
    }
  }
}

class CvFileValidationException implements Exception {
  const CvFileValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
