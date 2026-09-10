import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/recording_chunk.dart';

abstract class CallRecordingRepository {
  Future<Either<Failure, void>> saveChunk(RecordingChunk chunk);
  Future<Either<Failure, List<RecordingChunk>>> getPendingChunks();
  Future<Either<Failure, void>> markChunkSent(int chunkId);
  Future<Either<Failure, void>> deleteChunk(int chunkId);
  Future<Either<Failure, void>> uploadChunk(RecordingChunk chunk);
  Future<Either<Failure, String>> getRecordingStoragePath();
}
