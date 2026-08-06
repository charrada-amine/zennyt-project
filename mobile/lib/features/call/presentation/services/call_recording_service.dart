import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:miniav_recorder/miniav_recorder.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/repositories/call_recording_repository_impl.dart';
import '../../domain/entities/recording_chunk.dart';

/// Records the call screen + microphone with [miniav_recorder] and slices the
/// session into MP4 chunks that are uploaded in the background while the call
/// is still running.
///
/// The [ClipBuffer] keeps a rolling window of encoded packets in memory, so a
/// chunk can be materialised to disk without pausing the active recording. The
/// remote party is captured through the microphone (their voice reaches it via
/// the speakers) and the local voice directly, so both sides are audible.
class CallRecordingService {
  static const Duration _chunkInterval = Duration(seconds: 30);
  static const Duration _clipWindow = Duration(seconds: 60);
  static const int _videoBitrate = 4_000_000;
  static const int _audioBitrate = 96_000;
  static const int _frameRate = 30;
  static const Duration _minChunkDuration = Duration(seconds: 1);

  final CallRecordingRepositoryImpl _repository;

  bool _isRecording = false;
  bool _captureInProgress = false;
  Timer? _chunkTimer;
  Timer? _retryTimer;
  bool _retryInProgress = false;

  String? _sessionId;
  String? _storagePath;
  Recorder? _recorder;
  ClipBuffer? _clipBuffer;
  DateTime _chunkStart = DateTime.now();
  int _sequenceNumber = 0;

  void Function(bool isRecording)? onRecordingStateChanged;

  CallRecordingService({required CallRecordingRepositoryImpl repository})
      : _repository = repository {
    Recorder.setLogLevel(RecorderLogLevel.warning);
  }

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
    _retryTimer = Timer.periodic(_chunkInterval, (_) async {
      await _retryPending();
    });
  }

  void stopRetryService() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  Future<void> startRecording({required String sessionId}) async {
    if (_isRecording) return;
    _sessionId = sessionId;
    _sequenceNumber = 0;
    _chunkStart = DateTime.now();
    await _ensureStoragePath();

    final Recorder recorder;
    try {
      recorder = await _createRecorder();
      await recorder.start();
    } catch (e, stack) {
      debugPrint('🎬 [Recording] Failed to start recorder: $e');
      debugPrint('🎬 [Recording] $stack');
      _recorder = null;
      _clipBuffer = null;
      return;
    }

    _recorder = recorder;
    _isRecording = true;
    onRecordingStateChanged?.call(true);

    _chunkTimer = Timer.periodic(_chunkInterval, (_) async {
      await _captureAndSaveChunk();
    });
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;
    _isRecording = false;
    _chunkTimer?.cancel();
    _chunkTimer = null;

    await _saveFinalChunk();

    try {
      await _recorder?.stop();
    } catch (e) {
      debugPrint('🎬 [Recording] Failed to stop recorder: $e');
    }

    _recorder = null;
    _clipBuffer = null;
    onRecordingStateChanged?.call(false);
  }

  Future<Recorder> _createRecorder() async {
    final builder = RecorderBuilder()
      ..defaultVideoBitrate = _videoBitrate
      ..defaultAudioBitrate = _audioBitrate
      ..defaultFrameRate = _frameRate;

    // Package defaults: H.264 video (hardware accelerated on Windows via
    // NVENC/AMF/QSV/MFT) and AAC audio.
    builder.addScreen(scale: ScreenScalePolicy.h264Friendly);

    final micDeviceId = await _resolveMicDevice();
    if (micDeviceId != null) {
      builder.addMic(deviceId: micDeviceId);
    } else {
      debugPrint('🎬 [Recording] No microphone found, recording screen only');
    }

    _clipBuffer = builder.addClipBuffer(maxWindow: _clipWindow);
    return builder.build();
  }

  Future<String?> _resolveMicDevice() async {
    try {
      final mics = await RecorderDevices.microphones();
      for (final mic in mics) {
        if (mic.isDefault) return mic.deviceId;
      }
      if (mics.isNotEmpty) return mics.first.deviceId;
    } catch (e) {
      debugPrint('🎬 [Recording] Failed to enumerate microphones: $e');
    }
    return null;
  }

  Future<void> _captureAndSaveChunk() async {
    if (!_isRecording || _captureInProgress || _clipBuffer == null) return;
    _captureInProgress = true;
    try {
      final now = DateTime.now();
      final duration = _clampToWindow(now.difference(_chunkStart));
      _chunkStart = now;
      if (duration < _minChunkDuration) return;
      await _materializeChunk(duration);
    } catch (e, stack) {
      debugPrint('🎬 [Recording] Chunk capture failed: $e');
      debugPrint('🎬 [Recording] $stack');
    } finally {
      _captureInProgress = false;
    }
  }

  Future<void> _saveFinalChunk() async {
    if (_clipBuffer == null) return;
    final duration = _clampToWindow(DateTime.now().difference(_chunkStart));
    if (duration < _minChunkDuration) return;
    try {
      await _materializeChunk(duration);
    } catch (e) {
      debugPrint('🎬 [Recording] Final chunk capture failed: $e');
    }
  }

  Future<void> _materializeChunk(Duration duration) async {
    final clip = _clipBuffer;
    final sessionId = _sessionId;
    final path = _storagePath;
    if (clip == null || sessionId == null || path == null) return;

    final now = DateTime.now();
    final seq = _sequenceNumber++;
    final filePath =
        '$path/${sessionId}_${seq}_${now.millisecondsSinceEpoch}.mp4';

    // The .mp4 extension selects the MP4 container for the clip.
    await clip.saveClip(filePath, duration: duration);

    final chunk = RecordingChunk(
      sessionId: sessionId,
      sequenceNumber: seq,
      localFilePath: filePath,
      createdAt: now,
    );
    await _repository.saveChunk(chunk);
    unawaited(_uploadChunkBackground(chunk));
  }

  Duration _clampToWindow(Duration duration) {
    return duration > _clipWindow ? _clipWindow : duration;
  }

  Future<void> _uploadChunkBackground(RecordingChunk chunk) async {
    final result = await _repository.uploadChunk(chunk);
    if (result.isLeft()) {
      // The chunk is persisted locally (status failed/pending) and will be
      // picked up again by the retry service.
      return;
    }
  }

  Future<void> _retryPending() async {
    if (_retryInProgress) return;
    _retryInProgress = true;
    try {
      final result = await _repository.getPendingChunks();
      await result.fold(
        (_) async {},
        (chunks) async {
          for (final chunk in chunks) {
            final uploadResult = await _repository.uploadChunk(chunk);
            if (uploadResult.isLeft()) break;
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
    _retryTimer = null;
    _isRecording = false;
  }
}