import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/repositories/call_recording_repository_impl.dart';
import '../../domain/entities/recording_chunk.dart';

class CallRecordingService {
  final CallRecordingRepositoryImpl _repository;
  final RtcEngine _engine;

  bool _isRecording = false;
  Timer? _chunkTimer;
  int _sequenceNumber = 0;
  String? _sessionId;
  String? _storagePath;
  MediaRecorder? _recorder;

  Timer? _retryTimer;
  bool _retryInProgress = false;

  void Function(bool isRecording)? onRecordingStateChanged;

  CallRecordingService({
    required CallRecordingRepositoryImpl repository,
    required RtcEngine engine,
  })  : _repository = repository,
        _engine = engine;

  bool get isRecording => _isRecording;

  Future<String> _ensureStoragePath() async {
    if (_storagePath != null) return _storagePath!;
    final appDir = await getApplicationDocumentsDirectory();
    final path = '${appDir.path}/call_recordings';
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _storagePath = path;
    return path;
  }

  void startRetryService() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _retryPending(allowDelay: false);
    });
  }

  void stopRetryService() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  Future<MediaRecorder?> _createRecorder() async {
    final recorder = await _engine.createMediaRecorder(
      RecorderStreamInfo(
        channelId: _sessionId,
        type: RecorderStreamType.rtc,
      ),
    );
    return recorder;
  }

  Future<void> startRecording({required String sessionId}) async {
    if (_isRecording) return;
    _isRecording = true;
    _sessionId = sessionId;
    _sequenceNumber = 0;
    await _ensureStoragePath();

    onRecordingStateChanged?.call(true);

    _recorder = await _createRecorder();
    if (_recorder == null) {
      debugPrint('Failed to create MediaRecorder');
      return;
    }

    // ─── Apply compression config ────────────────────────────────────────
    try {
      await _engine.setVideoEncoderConfiguration(VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 640, height: 360),
        frameRate: 20,
        bitrate: 200,
        orientationMode: OrientationMode.orientationModeFixedLandscape,
      ));
    } catch (e) {
      debugPrint('Recording compression config error (non-fatal): $e');
    }

    // ─── Start chunk timer every 5s ──────────────────────────────────────
    _chunkTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _captureAndSaveChunk();
    });
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;
    _isRecording = false;
    _chunkTimer?.cancel();
    _chunkTimer = null;

    // Stop current recording if active
    if (_recorder != null) {
      try {
        await _recorder!.stopRecording();
      } catch (e) {
        debugPrint('Error stopping recorder: $e');
      }
      try {
        await _engine.destroyMediaRecorder(_recorder!);
      } catch (e) {
        debugPrint('Error destroying recorder: $e');
      }
      _recorder = null;
    }

    onRecordingStateChanged?.call(false);
  }

  Future<void> _captureAndSaveChunk() async {
    if (!_isRecording || _sessionId == null || _recorder == null) return;

    final seq = _sequenceNumber++;
    final path =
        '$_storagePath/${_sessionId}_${seq}_${DateTime.now().millisecondsSinceEpoch}.mp4';

    try {
      // Stop current recording to flush the previous chunk
      await _recorder!.stopRecording();

      // Start new recording for this chunk
      await _recorder!.startRecording(
        MediaRecorderConfiguration(
          storagePath: path,
          containerFormat: MediaRecorderContainerFormat.formatMp4,
          streamType: MediaRecorderStreamType.streamTypeBoth,
          maxDurationMs: 5000,
          videoSourceType: VideoSourceType.videoSourceCamera,
        ),
      );

      // Save chunk tracking
      final chunk = RecordingChunk(
        sessionId: _sessionId!,
        sequenceNumber: seq,
        localFilePath: path,
        createdAt: DateTime.now(),
      );
      await _repository.saveChunk(chunk);

      // Immediate upload in background
      unawaited(_uploadChunkBackground(chunk));
    } catch (e) {
      debugPrint('Chunk capture error: $e');
    }
  }

  Future<void> _uploadChunkBackground(RecordingChunk chunk) async {
    final result = await _repository.uploadChunk(chunk);
    if (result.isLeft()) {
      debugPrint('Chunk ${chunk.sequenceNumber} upload queued for retry');
    }
  }

  Future<void> _retryPending({bool allowDelay = true}) async {
    if (_retryInProgress) return;
    _retryInProgress = true;

    try {
      final result = await _repository.getPendingChunks();
      await result.fold(
        (_) async {},
        (chunks) async {
          final random = Random();
          for (final chunk in chunks) {
            if (allowDelay) {
              await Future.delayed(
                Duration(seconds: random.nextInt(5) + 1),
              );
            }
            final uploadResult = await _repository.uploadChunk(chunk);
            if (uploadResult.isLeft()) {
              break;
            }
          }
        },
      );
    } finally {
      _retryInProgress = false;
    }
  }

  void dispose() {
    _chunkTimer?.cancel();
    _retryTimer?.cancel();
    _isRecording = false;
  }
}
