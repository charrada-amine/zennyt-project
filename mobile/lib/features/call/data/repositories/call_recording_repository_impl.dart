import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/recording_chunk.dart';
import '../../domain/repositories/call_recording_repository.dart';
import '../datasources/recording_local_datasource.dart';
import '../datasources/recording_remote_datasource.dart';

class CallRecordingRepositoryImpl implements CallRecordingRepository {
  final RecordingLocalDataSource _local;
  final RecordingRemoteDataSource _remote;

  CallRecordingRepositoryImpl({
    required RecordingLocalDataSource local,
    required RecordingRemoteDataSource remote,
  })  : _local = local,
        _remote = remote;

  @override
  Future<Either<Failure, void>> saveChunk(RecordingChunk chunk) async {
    try {
      await _local.insertChunk(chunk);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to save chunk: $e'));
    }
  }

  @override
  Future<Either<Failure, List<RecordingChunk>>> getPendingChunks() async {
    try {
      final pending = await _local.getChunksByStatus(ChunkStatus.pending);
      final failed = await _local.getChunksByStatus(ChunkStatus.failed);
      final all = [...pending, ...failed];
      all.sort((a, b) => a.sequenceNumber.compareTo(b.sequenceNumber));
      return Right(all);
    } catch (e) {
      return Left(CacheFailure('Failed to read chunks: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markChunkSent(int chunkId) async {
    try {
      await _local.updateStatus(chunkId, ChunkStatus.sent);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to update chunk status: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteChunk(int chunkId) async {
    try {
      final all = await _local.getAllChunks();
      final chunk = all.firstWhere((c) => c.id == chunkId);
      final file = File(chunk.localFilePath);
      if (await file.exists()) {
        await file.delete();
      }
      await _local.deleteChunk(chunkId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to delete chunk: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> uploadChunk(RecordingChunk chunk) async {
    try {
      await _local.updateStatus(chunk.id, ChunkStatus.uploading);
      await _remote.uploadChunk(
        sessionId: chunk.sessionId,
        sequenceNumber: chunk.sequenceNumber,
        filePath: chunk.localFilePath,
      );
      await _deleteChunkAndEntry(chunk.id, chunk.localFilePath);
      return const Right(null);
    } on Failure {
      await _local.updateStatus(chunk.id, ChunkStatus.failed);
      rethrow;
    } catch (e) {
      await _local.updateStatus(chunk.id, ChunkStatus.failed);
      return Left(ServerFailure('Upload failed: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> getRecordingStoragePath() async {
    try {
      final dir = Directory(
          '${(await _getBaseDir()).path}/call_recordings');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return Right(dir.path);
    } catch (e) {
      return Left(CacheFailure('Failed to get storage path: $e'));
    }
  }

  Future<Directory> _getBaseDir() async {
    // Use app documents directory via path_provider
    return Directory('${Platform.environment['HOME']}/.call_records');
  }

  Future<void> _deleteChunkAndEntry(int chunkId, String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Log but don't fail
    }
    await _local.deleteChunk(chunkId);
  }
}
