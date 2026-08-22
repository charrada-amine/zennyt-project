// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import '../services/fraud_detection_service.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zennyt/features/call/domain/entities/call.dart';
import 'package:zennyt/features/call/domain/repositories/call_signaling_repository.dart';
import 'package:zennyt/features/call/presentation/providers/call_provider.dart';
import 'package:zennyt/features/call/presentation/providers/call_recording_provider.dart';
import 'package:zennyt/features/call/presentation/services/call_recording_service.dart';
import 'package:zennyt/features/call/data/repositories/call_recording_repository_impl.dart';

import '../providers/call_ui_providers.dart';

// Platform-specific permission handling
Future<void> _requestCallPermissions(bool isVideoCall) async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Desktop platforms handle permissions differently, skip explicit request
    return;
  }
  if (isVideoCall) {
    await Permission.camera.request();
    await Permission.microphone.request();
  } else {
    await Permission.microphone.request();
  }
}

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
  String? currentCallId;

  bool get isOutgoing => incomingOffer == null;

  String get channelName =>
      dotenv.env['AGORA_TEST_CHANNEL'] ??
      conversationId ??
      'call_${DateTime.now().millisecondsSinceEpoch}';

  /// Reponse de la personne a l'ecran de consentement, posee par CallPage avant `init()`.
  ///
  /// Faux ne coupe pas l'appel : il coupe l'enregistrement et la detection. Refuser ne
  /// doit jamais couter un entretien.
  bool consentementEnregistrement = false;

  // ─── Detection de fraude ───────────────────────────────────────────────────
  FraudDetectionService? _fraudService;
  FraudDetectionService? get fraudService => _fraudService;

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
      await _engine!.initialize(
        RtcEngineContext(
          appId: kAgoraAppId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      await _engine!.enableAudio();
      if (isVideoCall) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      } else {
        await _engine!.disableVideo();
      }

      _registerEventHandler();
      //_setupSignalingListeners();

      renderersInitialized = true;
      isRendering = true;
      onStateChanged();

      // ─── Request microphone/camera permissions ────────────────────────────
      await _requestCallPermissions(isVideoCall);

      // ─── Apply initial camera/mute state ────────────────────────────────
      if (isVideoCall) {
        ref.read(isCameraOffProvider.notifier).state = !startWithCameraOn;
        await _engine!.muteLocalVideoStream(!startWithCameraOn);
      } else {
        ref.read(isCameraOffProvider.notifier).state = true;
      }

      // ─── Ensure WebSocket is connected before making/receiving calls ────────
      final ws = ref.read(webSocketServiceProvider);
      int retryCount = 0;
      while (!ws.isConnected && retryCount < 10) {
        debugPrint(
          '⚠️ WebSocket not connected, waiting... (attempt ${retryCount + 1})',
        );
        await Future.delayed(const Duration(milliseconds: 500));
        retryCount++;
      }
      if (!ws.isConnected) {
        debugPrint('⚠️ WebSocket not connected after retries, call may fail');
      } else {
        debugPrint('✅ WebSocket connected, proceeding with call');
      }

      _setupSignalingListeners();

      if (isOutgoing) {
        debugPrint('📞 Initiating outgoing call as $myResolvedUserId');
        if (conversationId != null) {
          currentCallId = await _startCallOnBackend(conversationId!);
          debugPrint('📞 Outgoing call session created: callId=$currentCallId');
        }
      } else {
        await _joinAgoraChannel();
        final incomingCallId = incomingOffer?['callId'] as String?;
        if (incomingCallId != null) {
          currentCallId = incomingCallId;
          await _acceptCallOnBackend(incomingCallId);
        }
      }
    } catch (e) {
      debugPrint('Error during initialization: $e');
    }
  }

  /// Call after channel join (from onJoinChannelSuccess or onUserJoined) to
  /// start recording the call.
  void _startRecordingIfNeeded() {
    // Sans accord explicite, rien n'est ni enregistre ni analyse. L'appel, lui, continue.
    if (!consentementEnregistrement) {
      debugPrint('🎥 Enregistrement et detection desactives : consentement refuse');
      return;
    }
    _demarrerDetectionFraude();
    if (!isVideoCall) {
      debugPrint('🎥 Recording skipped (audio call, isVideoCall=false)');
      return;
    }
    if (_recordingService != null) return;
    if (_engine == null || channelName.isEmpty) {
      debugPrint('🎥 Recording skipped (engine/channel not ready)');
      return;
    }

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

    debugPrint('🎥 Starting recording for channel $channelName');
    // Start recording in the background
    service.startRecording(sessionId: channelName);
    service.startRetryService();

    _recordingService = service;
  }

  /// Derive le micro local vers le module de detection.
  ///
  /// Volontairement sans `await` : une panne du module — eteint, injoignable, lent — ne
  /// doit pas retarder d'une milliseconde le debut de l'entretien. La detection observe,
  /// elle ne conditionne rien.
  void _demarrerDetectionFraude() {
    if (_fraudService != null || _engine == null) return;
    final base = dotenv.env['FRAUD_WS_URL'];
    if (base == null || base.isEmpty) {
      debugPrint('[Fraude] FRAUD_WS_URL absent : detection non configuree');
      return;
    }

    final service = FraudDetectionService(
      engine: _engine!,
      baseUrl: base,
      // L'identifiant de l'appel, pas le canal Agora : le canal peut etre partage par
      // plusieurs entretiens (voir AGORA_TEST_CHANNEL), l'appel non.
      sessionId: currentCallId ?? channelName,
      // « candidate » / « recruiter » : les seuls roles que le module accepte
      // (app/sessions.py, ROLES). En francais il repondrait « role inconnu ».
      role: isOutgoing ? 'recruiter' : 'candidate',
    );
    _fraudService = service;
    service.demarrer();
  }

  Future<void> _joinAgoraChannel() async {
    // Use Agora RTC token (can be from env or generated by backend)
    final agoraToken = dotenv.env['AGORA_RTC_TOKEN']!;

    await _engine!.joinChannel(
      token: agoraToken,
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

  Future<String?> _startCallOnBackend(String conversationId) async {
    final call = Call(
      id: conversationId,
      contactName: contactName,
      type: isVideoCall ? CallType.video : CallType.audio,
      status: CallStatus.outgoing,
      startTime: DateTime.now(),
    );
    final result = await ref.read(callRepositoryProvider).startCall(call);
    return result.fold(
      (failure) {
        debugPrint('❌ startCall failed: ${failure.message}');
        return null;
      },
      (callId) => callId,
    );
  }

  Future<bool> _acceptCallOnBackend(String callId) async {
    final result = await ref.read(callRepositoryProvider).joinCall(callId);
    return result.fold(
      (failure) {
        debugPrint('❌ joinCall failed: ${failure.message}');
        return false;
      },
      (_) => true,
    );
  }

  void _registerEventHandler() {
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          _joined = true;
          debugPrint('✅ Joined Agora channel: ${connection.channelId}');
          onStateChanged();
        },
        onUserJoined: (connection, uid, elapsed) {
          remoteUid = uid;
          debugPrint('👥 Remote user joined (uid=$uid), isVideoCall=$isVideoCall');
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
          final active =
              state == RemoteVideoState.remoteVideoStateStarting ||
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

    /* // Écouter l'invitation d'appel entrante (pour les appels entrants)
    _signaling.onCallInvite((data) {
      if (!isOutgoing && !_joined) {
        debugPrint('📞 Incoming call invite received: $data');
        _joinAgoraChannel();
        // Envoyer accept automatiquement
        _signaling.sendAccept(
          conversationId: conversationId!,
          senderId: myResolvedUserId,
          counterpartId: counterpartId,
        );
      }
    }); */

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
        '${(await getTemporaryDirectory()).path}/${assetPath.split('/').last}',
      );
      await file.writeAsBytes(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
      );
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
        segproperty: const SegmentationProperty(
          modelType: SegModelType.segModelAi,
        ),
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
    if (currentCallId != null) {
      final result =
          await ref.read(callRepositoryProvider).endCall(currentCallId!);
      result.fold(
        (failure) => debugPrint('❌ endCall failed: ${failure.message}'),
        (_) => debugPrint('📞 Call ended on backend: $currentCallId'),
      );
    }
    await Future.delayed(const Duration(milliseconds: 200));
    await cleanup(navigateBack: true);
  }

  Future<void> cleanup({bool navigateBack = false}) async {
    if (isCallEnded) return;
    isCallEnded = true;

    // La detection s'arrete avant le moteur : `arreter()` desenregistre l'observateur
    // audio et envoie la derniere phrase, qui peut etre celle qui compte.
    final fraude = _fraudService;
    _fraudService = null;
    if (fraude != null) {
      try {
        await fraude.arreter();
      } catch (e) {
        debugPrint('[Fraude] arret imparfait : $e');
      }
    }

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
    _engine?.release();
    _engine = null;
  }
}
