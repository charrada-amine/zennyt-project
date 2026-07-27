// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:go_router/go_router.dart';
import 'package:zennyt/features/call/domain/repositories/call_signaling_repository.dart';
import 'package:zennyt/features/call/presentation/providers/call_provider.dart';
import 'package:zennyt/features/call/presentation/providers/call_recording_provider.dart';
import 'package:zennyt/features/call/presentation/services/call_recording_service.dart';
import 'package:zennyt/features/call/data/repositories/call_recording_repository_impl.dart';

import '../providers/call_ui_providers.dart';

final String kAgoraAppId = dotenv.env['AGORA_APP_ID']!;

class CallPageController {
  final WidgetRef ref;
  final BuildContext context;

  // ─── Call params ────────────────────────────────────────────────────────────
  final String contactName;
  final String? conversationId;
  final String? counterpartId;
  final String? myUserId;

  final Map<String, dynamic>? incomingOffer;
  final bool startWithCameraOn;
  final bool isVideoCall;

  // ─── Agora ──────────────────────────────────────────────────────────────────
  RtcEngine? _engine;
  RtcEngine get engine => _engine!;

  bool renderersInitialized = false;
  bool isRendering = false;
  bool _joined = false;

  int? remoteUid;
  bool remoteHasVideo = false;
  bool isCallEnded = false;
  String myResolvedUserId = '';

  bool get isOutgoing => incomingOffer == null;

  String get channelName =>
      conversationId ?? 'call_${DateTime.now().millisecondsSinceEpoch}';

  // ─── Recording ─────────────────────────────────────────────────────────────
  CallRecordingService? _recordingService;
  CallRecordingService? get recordingService => _recordingService;

  // ─── Signaling ─────────────────────────────────────────────────────────────
  late final CallSignalingRepository _signaling;
  final VoidCallback onStateChanged;

  CallPageController({
    required this.ref,
    required this.context,
    required this.contactName,
    this.conversationId,
    this.counterpartId,
    this.myUserId,
    this.incomingOffer,
    required this.startWithCameraOn,
    this.isVideoCall = true,
    required this.onStateChanged,
  }) {
    _signaling = ref.read(callSignalingRepositoryProvider);
    myResolvedUserId = myUserId ?? '';
  }

  /// Point d'entrée public appelé depuis CallPage (post premier frame).
  Future<void> init() async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: kAgoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      await _engine!.enableAudio();
      if (isVideoCall) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      } else {
        await _engine!.disableVideo();
      }

      _registerEventHandler();
      _setupSignalingListeners();

      renderersInitialized = true;
      isRendering = true;
      onStateChanged();

      if (isVideoCall) {
        ref.read(isCameraOffProvider.notifier).state = !startWithCameraOn;
        await _engine!.muteLocalVideoStream(!startWithCameraOn);
      } else {
        ref.read(isCameraOffProvider.notifier).state = true;
      }

      if (isOutgoing) {
        // ─── APPEL SORTANT : envoyer invite, attendre accept ──────────────
        if (conversationId != null) {
          _signaling.sendCallInvite(
            conversationId: conversationId!,
            senderId: myResolvedUserId,
            counterpartId: counterpartId,
            channelName: channelName,
            isVideoCall: isVideoCall,
          );
        }
      } else {
        // ─── APPEL ENTRANT : rejoindre directement le canal ────────────────
        await _joinAgoraChannel();
        // Envoyer accept au correspondant
        if (conversationId != null) {
          _signaling.sendAccept(
            conversationId: conversationId!,
            senderId: myResolvedUserId,
            counterpartId: counterpartId,
          );
        }
      }
    } catch (e) {
      debugPrint('Error during initialization: $e');
    }
  }

  /// Call after channel join (from onJoinChannelSuccess or onUserJoined) to
  /// start recording the call.
  void _startRecordingIfNeeded() {
    if (!isVideoCall || _recordingService != null) return;
    if (_engine == null || channelName.isEmpty) return;

    final repository = CallRecordingRepositoryImpl(
      local: ref.read(recordingLocalDataSourceProvider),
      remote: ref.read(recordingRemoteDataSourceProvider),
    );

    final service = CallRecordingService(
      repository: repository,
      engine: _engine!,
    );

    // Update UI state when recording starts/stops
    service.onRecordingStateChanged = (isRecording) {
      ref.read(isRecordingProvider.notifier).state = isRecording;
    };

    // Start recording in the background
    service.startRecording(sessionId: channelName);
    service.startRetryService();

    _recordingService = service;
  }

  Future<void> _joinAgoraChannel() async {
    await _engine!.joinChannel(
      token: dotenv.env['ENGIN_TOKEN']!,
      channelId: channelName,
      uid: 0,
      options: ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishCameraTrack: isVideoCall,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      ),
    );
  }

  void _registerEventHandler() {
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          _joined = true;
          onStateChanged();
        },
        onUserJoined: (connection, uid, elapsed) {
          remoteUid = uid;
          // Start recording after the first user joins (conversation truly started)
          _startRecordingIfNeeded();
          onStateChanged();
        },
        onUserOffline: (connection, uid, reason) {
          if (remoteUid == uid) {
            remoteUid = null;
            remoteHasVideo = false;
            onStateChanged();
          }
        },
        onRemoteVideoStateChanged: (connection, uid, state, reason, elapsed) {
          if (uid != remoteUid) return;
          final active = state == RemoteVideoState.remoteVideoStateStarting ||
              state == RemoteVideoState.remoteVideoStateDecoding;
          if (active != remoteHasVideo) {
            remoteHasVideo = active;
            onStateChanged();
          }
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint('Agora error: $err - $msg');
        },
      ),
    );
  }

  void _setupSignalingListeners() {
    if (conversationId == null) return;

    // Écouter l'acceptation (appel sortant uniquement)
    _signaling.onAccept((data) {
      if (isOutgoing && !_joined) {
        _joinAgoraChannel();
      }
    });

    // Écouter le rejet (appel sortant uniquement)
    _signaling.onReject((data) {
      if (isOutgoing) {
        cleanup(navigateBack: true);
      }
    });

    // Écouter la fin d'appel
    _signaling.onEndCall((data) {
      if (isCallEnded) return;
      cleanup(navigateBack: true);
    });
  }

  Future<String> _getAbsoluteAssetPath(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final file = File(
          '${(await getTemporaryDirectory()).path}/${assetPath.split('/').last}');
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      return file.path;
    } catch (e) {
      debugPrint('Error loading asset file path: $e');
      return '';
    }
  }

  Future<void> applyVirtualBackground(
    VirtualBgType type, {
    Color? color,
    String? imagePath,
  }) async {
    if (_engine == null || !isVideoCall) return;
    ref.read(virtualBackgroundTypeProvider.notifier).state = type;

    if (type == VirtualBgType.none) {
      try {
        await _engine!.enableVirtualBackground(
          enabled: false,
          backgroundSource: const VirtualBackgroundSource(),
          segproperty: const SegmentationProperty(),
        );
      } catch (e) {
        debugPrint('Virtual background error: $e');
      }
      return;
    }

    late VirtualBackgroundSource source;
    switch (type) {
      case VirtualBgType.blur:
        source = const VirtualBackgroundSource(
          backgroundSourceType: BackgroundSourceType.backgroundBlur,
          blurDegree: BackgroundBlurDegree.blurDegreeHigh,
        );
        break;

      case VirtualBgType.image:
        if (imagePath != null && imagePath.isNotEmpty) {
          final absolutePath = await _getAbsoluteAssetPath(imagePath);
          source = VirtualBackgroundSource(
            backgroundSourceType: BackgroundSourceType.backgroundImg,
            source: absolutePath,
          );
        } else {
          return;
        }
        break;
      case VirtualBgType.none:
        return;
    }

    try {
      await _engine!.enableVirtualBackground(
        enabled: true,
        backgroundSource: source,
        segproperty:
            const SegmentationProperty(modelType: SegModelType.segModelAi),
      );
    } catch (e) {
      debugPrint('Virtual background error: $e');
    }
  }

  void switchCamera() {
    if (!isVideoCall) return;
    _engine?.switchCamera();
    final isFront = ref.read(isFrontCameraProvider);
    ref.read(isFrontCameraProvider.notifier).state = !isFront;
  }

  Future<void> toggleMute(bool isMuted) async {
    final newMuted = !isMuted;
    ref.read(isMutedProvider.notifier).state = newMuted;
    await _engine?.muteLocalAudioStream(newMuted);
  }

  Future<void> toggleCamera(bool isCameraOff) async {
    if (!isVideoCall) return;
    final newIsCameraOff = !isCameraOff;
    ref.read(isCameraOffProvider.notifier).state = newIsCameraOff;
    await _engine?.muteLocalVideoStream(newIsCameraOff);
    onStateChanged();
  }

  Future<void> toggleSpeaker(bool isSpeakerOn) async {
    final newVal = !isSpeakerOn;
    ref.read(isSpeakerOnProvider.notifier).state = newVal;
    await _engine?.setEnableSpeakerphone(newVal);
  }

  Future<void> endCall() async {
    if (conversationId != null) {
      _signaling.sendEndCall(
        conversationId: conversationId!,
        senderId: myResolvedUserId,
        counterpartId: counterpartId,
      );
    }
    await Future.delayed(const Duration(milliseconds: 200));
    await cleanup(navigateBack: true);
  }

  Future<void> cleanup({bool navigateBack = false}) async {
    if (isCallEnded) return;
    isCallEnded = true;

    // Stop recording before anything else
    _recordingService?.stopRecording();
    _recordingService?.stopRetryService();
    _recordingService?.dispose();
    _recordingService = null;

    _signaling.dispose();

    try {
      await _engine?.leaveChannel();
    } catch (e) {
      debugPrint('Error leaving channel: $e');
    }

    _joined = false;
    isRendering = false;
    remoteHasVideo = false;
    remoteUid = null;
    onStateChanged();

    if (navigateBack) {
      context.pop();
    }
  }

  void disposeRenderers() {
    _recordingService?.stopRecording();
    _recordingService?.stopRetryService();
    _recordingService?.dispose();
    _recordingService = null;
    _engine?.release();
    _engine = null;
  }
}
