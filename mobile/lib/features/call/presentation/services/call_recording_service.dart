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

  // Chunk currently being recorded. A chunk is ALWAYS active between
  // startRecording() and stopRecording(), so stopRecording() on the
  // MediaRecorder never hits Agora error -5 (ERR_REFUSED).
  String? _currentChunkPath;
  int _currentChunkSeq = 0;

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

    _recorder = await _createRecorder();
    if (_recorder == null) {
      debugPrint('Failed to create MediaRecorder');
      _isRecording = false;
      return;
    }

    // Log native recorder state/errors (e.g. no local stream to record).
    try {
      await _recorder!.setMediaRecorderObserver(MediaRecorderObserver(
        onRecorderStateChanged: (channelId, uid, state, reason) {
          debugPrint('🎙 Recorder state=${state.name} reason=${reason.name}');
        },
      ));
    } catch (e) {
      debugPrint('🎙 Could not attach recorder observer (non-fatal): $e');
    }

    // ─── Apply HIGH QUALITY video config ───────────────────────────────────
    // NOTE: we deliberately do NOT call setAudioProfile here. The recorder
    // captures the stream the engine already publishes, and re-pipelining the
    // live call's audio (music profile + game-streaming scenario) mid-call can
    // stop local mic capture until the engine is restarted.
    try {
      await _engine.setVideoEncoderConfiguration(VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 1280, height: 720),  // 720p HD
        frameRate: 30,                                          // 30 fps smooth
        bitrate: 2500,                                          // 2.5 Mbps
        orientationMode: OrientationMode.orientationModeAdaptive,
        degradationPreference: DegradationPreference.maintainQuality,
      ));
    } catch (e) {
      debugPrint('Recording quality config error (non-fatal): $e');
    }

    // ─── Start the first chunk immediately ────────────────────────────────
    // Without this, the first stopRecording() returns -5 (never started) and
    // no mp4 is ever produced. If the local stream is not ready yet (camera
    // still starting, or no camera on this device), retry briefly: recording
    // starts as soon as a stream becomes available.
    var started = false;
    for (var attempt = 0; attempt < 15 && !started; attempt++) {
      try {
        await _startNewChunk();
        started = true;
      } catch (e) {
        debugPrint('🎙 First chunk attempt ${attempt + 1} failed: $e');
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    if (!started) {
      debugPrint('🎙 Recording could not start (no local stream)');
      try {
        await _engine.destroyMediaRecorder(_recorder!);
      } catch (_) {}
      _recorder = null;
      _isRecording = false;
      return;
    }

    debugPrint('🔴 Recording started → $_storagePath');
    onRecordingStateChanged?.call(true);

    // ─── Start chunk timer every 10s (longer chunks = better compression) ─
    _chunkTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await _captureAndSaveChunk();
    });
  }

  /// Opens a new MediaRecorder session for the next chunk.
  Future<void> _startNewChunk() async {
    final seq = _sequenceNumber++;
    final path =
        '$_storagePath/${_sessionId}_${seq}_${DateTime.now().millisecondsSinceEpoch}.mp4';
    _currentChunkSeq = seq;
    _currentChunkPath = path;
    try {
      await _recorder!.startRecording(
        MediaRecorderConfiguration(
          storagePath: path,
          containerFormat: MediaRecorderContainerFormat.formatMp4,
          streamType: MediaRecorderStreamType.streamTypeBoth,
          // Safety net only: the manual stop fires at 10s via the chunk timer.
          // Kept high so the manual stop always wins the race.
          maxDurationMs: 60000,
          videoSourceType: VideoSourceType.videoSourceCameraPrimary,
        ),
      );
    } catch (e) {
      // Failed attempt: don't leave a phantom chunk (a later stopRecording()
      // on it would return Agora -5 since the recorder never started).
      _currentChunkPath = null;
      rethrow;
    }
  }

  /// Stops the active chunk (flushes the mp4 to disk) and records its metadata.
  Future<RecordingChunk> _stopAndSaveCurrentChunk() async {
    final path = _currentChunkPath;
    if (path == null) {
      throw StateError('No active chunk to stop');
    }
    final seq = _currentChunkSeq;
    await _recorder!.stopRecording();
    _currentChunkPath = null;
    final chunk = RecordingChunk(
      sessionId: _sessionId!,
      sequenceNumber: seq,
      localFilePath: path,
      createdAt: DateTime.now(),
    );
    await _repository.saveChunk(chunk);
    debugPrint('🎬 Chunk $seq saved: $path');
    return chunk;
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;
    _isRecording = false;
    _chunkTimer?.cancel();
    _chunkTimer = null;

    // Close the final chunk so its mp4 is flushed on disk.
    if (_recorder != null) {
      if (_currentChunkPath != null) {
        try {
          await _stopAndSaveCurrentChunk();
        } catch (e) {
          debugPrint('Error stopping recorder: $e');
        }
      }
      try {
        await _engine.destroyMediaRecorder(_recorder!);
      } catch (e) {
        debugPrint('Error destroying recorder: $e');
      }
      _recorder = null;
    }

    debugPrint('⏹ Recording stopped');
    onRecordingStateChanged?.call(false);
  }

  Future<void> _captureAndSaveChunk() async {
    if (!_isRecording || _sessionId == null || _recorder == null) return;
    if (_currentChunkPath == null) return;

    try {
      // Close the previous chunk (flushes mp4), then open the next one.
      await _stopAndSaveCurrentChunk();
      await _startNewChunk();

      // ─── TEST MODE: keep chunks locally, no upload ─────────────────────
      // unawaited(_uploadChunkBackground(chunk));
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