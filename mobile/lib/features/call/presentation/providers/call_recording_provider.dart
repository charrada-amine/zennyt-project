import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:zennyt/core/di/injection.dart';
import 'package:zennyt/features/call/data/datasources/recording_local_datasource.dart';
import 'package:zennyt/features/call/data/datasources/recording_remote_datasource.dart';
import 'package:zennyt/features/call/data/repositories/call_recording_repository_impl.dart';
import 'package:zennyt/features/call/domain/usecases/sync_pending_chunks.dart';

final recordingLocalDataSourceProvider = Provider<RecordingLocalDataSource>((ref) {
  return sl<RecordingLocalDataSource>();
});



final recordingRemoteDataSourceProvider = Provider<RecordingRemoteDataSource>((ref) {
  return RecordingRemoteDataSource(sl<Dio>());
});

final callRecordingRepositoryProvider = Provider<CallRecordingRepositoryImpl>((ref) {
  return CallRecordingRepositoryImpl(
    local: ref.read(recordingLocalDataSourceProvider),
    remote: ref.read(recordingRemoteDataSourceProvider),
  );
});

final syncPendingChunksProvider = Provider<SyncPendingChunks>((ref) {
  return SyncPendingChunks(ref.read(callRecordingRepositoryProvider));
});

/// Tracks whether recording is currently active (for UI indicators).
final isRecordingProvider = StateProvider<bool>((ref) => false);
