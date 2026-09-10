import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/call_recording_repository.dart';

class SyncPendingChunks extends UseCase<void, NoParams> {
  final CallRecordingRepository _repository;

  SyncPendingChunks(this._repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    final chunksResult = await _repository.getPendingChunks();
    return chunksResult.fold(
      (failure) => Left(failure),
      (chunks) async {
        for (final chunk in chunks) {
          final uploadResult = await _repository.uploadChunk(chunk);
          if (uploadResult.isLeft()) {
            // Stop on first error; next retry will pick up remaining + current
            return uploadResult;
          }
        }
        return const Right(null);
      },
    );
  }
}
