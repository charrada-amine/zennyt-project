import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/post_repository.dart';

class UploadFile {
  final PostRepository repository;
  UploadFile(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(
      Uint8List bytes, String fileName) {
    return repository.uploadFile(bytes, fileName);
  }
}
