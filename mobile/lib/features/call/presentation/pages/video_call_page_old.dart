/* // ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../providers/call_provider.dart';
import '../../../../core/constants.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../widgets/call_action_button.dart';
import '../widgets/call_control_button.dart';
import '../../../../shared/widgets/important_alert.dart';

class VideoCallPage extends ConsumerStatefulWidget {
  final String contactName;
  final String? conversationId;
  final String? counterpartId;
  final String? myUserId;
  final Map<String, dynamic>? incomingOffer;
  final bool startWithCameraOn;

  const VideoCallPage({
    super.key,
    required this.contactName,
    this.conversationId,
    this.counterpartId,
    this.myUserId,
    this.incomingOffer,
    this.startWithCameraOn = false,
  });

  @override
  ConsumerState<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends ConsumerState<VideoCallPage> {
  // ─── Renderers ──────────────────────────────────────────────────────────────
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _renderersInitialized = false;

  // ─── WebRTC ─────────────────────────────────────────────────────────────────
  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;
  final List<RTCIceCandidate> _pendingCandidates = [];

  // ─── UI state ───────────────────────────────────────────────────────────────
  bool _isRendering = false; // local cam active
  bool _remoteHasVideo = false; // remote stream has video track
  bool _isCallEnded = false; // guard against double cleanup

  // ─── Misc ───────────────────────────────────────────────────────────────────
  final DraggableScrollableController _draggableController =
      DraggableScrollableController();
  final WebSocketService _webSocketService = WebSocketService();

  // Holds MY real userId
  String _myUserId = '';

  final Map<String, dynamic> _rtcConfiguration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  // ─── helpers ────────────────────────────────────────────────────────────────
  Color _colorFromName(String name) {
    final hash = name.codeUnits.fold<int>(0, (a, b) => a + b);
    final colors = [
      Colors.deepPurple,
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.blueGrey,
    ];
    return colors[hash % colors.length];
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Lifecycle
  // ════════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _initRenderers();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      if (widget.myUserId != null && widget.myUserId!.isNotEmpty) {
        _myUserId = widget.myUserId!.trim().toLowerCase();
      } else {
        final currentUser = await ref.read(currentUserProvider.future);
        _myUserId = currentUser.id.trim().toLowerCase();
      }
      debugPrint('🆔 My userId: $_myUserId');

      _connectWebSocket(_myUserId);

      ref.read(isCameraOffProvider.notifier).state = !widget.startWithCameraOn;

      await _getUserMedia(video: widget.startWithCameraOn);

      // ✅ Turn speaker on immediately so audio plays without user interaction
      await Helper.setSpeakerphoneOn(true);
      ref.read(isSpeakerOnProvider.notifier).state = true;

      // Determine if we are caller or callee
      if (widget.incomingOffer != null) {
        await _processOffer(widget.incomingOffer!);
      } else {
        await _createOfferFlow();
      }
    });
  }

  @override
  void dispose() {
    _cleanup();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _draggableController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Renderer init
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    if (mounted) {
      setState(() => _renderersInitialized = true);
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // WebSocket / Signaling
  // ════════════════════════════════════════════════════════════════════════════

  void _connectWebSocket(String userId) {
    _webSocketService.connect(
      userId: userId,
      onConnect: () => _setupSignalingHandlers(),
    );
  }

  void _setupSignalingHandlers() {
    // ── OFFER (we are the callee) ────────────────────────────────────────────
    _webSocketService.subscribe('call/offer', (offer) async {
      if (_isCallEnded) return;
      debugPrint('📞 Received offer via WebSocket');

      final pc = _peerConnection;
      if (pc != null && await pc.getRemoteDescription() != null) {
        debugPrint(
            '⚠️  Offer received but remote description already set (ignoring duplicate)');
        return;
      }

      await _processOffer(offer);
    });

    // ── ANSWER (we are the caller) ───────────────────────────────────────────
    _webSocketService.subscribe('call/answer', (answer) async {
      if (_isCallEnded) return;

      final pc = _peerConnection;
      if (pc == null) {
        debugPrint('⚠️  Received answer but no PeerConnection yet — ignoring');
        return;
      }

      final signalingState = await pc.getSignalingState();
      if (signalingState != RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
        debugPrint('⚠️  Ignoring answer — state: $signalingState');
        return;
      }

      debugPrint('✅ Applying answer from remote');
      await pc.setRemoteDescription(
        RTCSessionDescription(answer['sdp'], answer['type']),
      );
      await _flushPendingCandidates();
    });

    // ── ICE CANDIDATE ────────────────────────────────────────────────────────
    _webSocketService.subscribe('call/ice-candidate', (data) async {
      if (_isCallEnded) return;

      final candidate = RTCIceCandidate(
        data['candidate'],
        data['sdpMid'],
        data['sdpMLineIndex'],
      );

      final pc = _peerConnection;
      if (pc == null) {
        _pendingCandidates.add(candidate);
        return;
      }

      final remoteDesc = await pc.getRemoteDescription();
      if (remoteDesc == null) {
        _pendingCandidates.add(candidate);
        debugPrint('🧊 Buffered ICE candidate (no remote desc yet)');
        return;
      }

      try {
        await pc.addCandidate(candidate);
      } catch (e) {
        debugPrint('⚠️  ICE addCandidate error: $e');
      }
    });

    // ── CALL END ─────────────────────────────────────────────────────────────
    _webSocketService.subscribe('call/end', (data) async {
      final senderId =
          (data['senderId'] as String?)?.trim().toLowerCase() ?? '';
      final targetId =
          (data['counterpartId'] as String?)?.trim().toLowerCase() ?? '';

      debugPrint(
          '📵 call/end received — sender=$senderId target=$targetId me=$_myUserId');

      // Ignore self-loopback
      if (senderId == _myUserId && targetId == _myUserId) {
        debugPrint('⚠️  call/end self-loopback ignored');
        return;
      }

      // Act if: we are the target, OR the sender hung up
      if (targetId == _myUserId || senderId != _myUserId) {
        await _cleanup(navigateBack: true);
      }
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  // WebRTC
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _getUserMedia({required bool video}) async {
    try {
      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) {
          track.stop();
        });
      }

      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': video ? {'facingMode': 'user'} : false,
      });

      if (!_renderersInitialized) {
        await _initRenderers();
      }

      _localRenderer.srcObject = _localStream;
      ref.read(isFrontCameraProvider.notifier).state = true;
      if (mounted) {
        setState(() {
          _isRendering = video;
        });
      }
    } catch (e) {
      debugPrint('❌ getUserMedia error: $e');
    }
  }

  Future<void> _createPeerConnection() async {
    if (_peerConnection != null) return;

    _peerConnection = await createPeerConnection(_rtcConfiguration);

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }

    _peerConnection!.onTrack = (RTCTrackEvent event) async {
      debugPrint('📡 Remote track: ${event.track.kind}');
      if (event.streams.isEmpty) return;
      final stream = event.streams[0];

      _remoteRenderer.srcObject = stream;
      if (mounted) {
        setState(() {
          _remoteHasVideo = stream.getVideoTracks().isNotEmpty;
        });
      }

      // Listen for tracks being added later to the stream
      stream.onAddTrack = (track) {
        debugPrint('📡 Track added to remote stream: ${track.kind}');
        if (mounted) {
          setState(() {
            _remoteHasVideo = stream.getVideoTracks().isNotEmpty;
          });
        }
      };
    };

    _peerConnection!.onAddStream = (MediaStream stream) {
      debugPrint('📡 Remote stream added');
      _remoteRenderer.srcObject = stream;
      if (mounted) {
        setState(() {
          _remoteHasVideo = stream.getVideoTracks().isNotEmpty;
        });
      }

      stream.onAddTrack = (track) {
        debugPrint(
            '📡 Track added to remote stream via onAddStream: ${track.kind}');
        if (mounted) {
          setState(() {
            _remoteHasVideo = stream.getVideoTracks().isNotEmpty;
          });
        }
      };
    };

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate == null) return;
      _webSocketService.send(
        '/app/call/${widget.conversationId}/ice-candidate',
        {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
          'senderId': _myUserId,
          'counterpartId': widget.counterpartId,
        },
      );
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('🔗 PeerConnection: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        if (mounted) {
          setState(() {
            _remoteHasVideo = false;
            _remoteRenderer.srcObject = null;
          });
        }
      }
    };
  }

  Future<void> _flushPendingCandidates() async {
    if (_peerConnection == null || _pendingCandidates.isEmpty) return;
    debugPrint(
        '🧊 Flushing ${_pendingCandidates.length} buffered ICE candidates');
    for (final c in List.of(_pendingCandidates)) {
      try {
        await _peerConnection!.addCandidate(c);
      } catch (e) {
        debugPrint('⚠️  Flushed ICE candidate error: $e');
      }
    }
    _pendingCandidates.clear();
  }

  Future<void> _createOfferFlow() async {
    if (_peerConnection == null) {
      await _createPeerConnection();
    }
    final offer = await _peerConnection?.createOffer();
    if (offer == null) return;
    await _peerConnection?.setLocalDescription(offer);

    _webSocketService.send(
      '/app/call/${widget.conversationId}/offer',
      {
        'sdp': offer.sdp,
        'type': offer.type,
        'senderId': _myUserId,
        'counterpartId': widget.counterpartId,
        'callType': widget.startWithCameraOn ? 'video' : 'audio',
      },
    );
  }

  Future<void> _processOffer(Map<String, dynamic> offer) async {
    try {
      debugPrint('📞 Processing incoming offer');

      if (_localStream == null) {
        await _getUserMedia(video: widget.startWithCameraOn);
      }

      if (_peerConnection == null) {
        await _createPeerConnection();
      }

      await _peerConnection?.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );
      await _flushPendingCandidates();

      final answer = await _peerConnection?.createAnswer();
      if (answer == null) return;
      await _peerConnection?.setLocalDescription(answer);

      _webSocketService.send(
        '/app/call/${widget.conversationId}/answer',
        {
          'sdp': answer.sdp,
          'type': answer.type,
          'senderId': _myUserId,
          'counterpartId': widget.counterpartId,
        },
      );
    } catch (e) {
      debugPrint('❌ Error processing offer: $e');
    }
  }

  Future<void> _switchCamera() async {
    final videoTrack = _localStream?.getVideoTracks().firstOrNull;
    if (videoTrack != null) {
      await Helper.switchCamera(videoTrack);
      ref.read(isFrontCameraProvider.notifier).state =
          !ref.read(isFrontCameraProvider);
    }
  }

  // ── Cleanup ─────────────────────────────────────────────────────────────────
  Future<void> _cleanup({bool navigateBack = false}) async {
    if (_isCallEnded) return;
    _isCallEnded = true;

    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    _localStream = null;

    await _peerConnection?.close();
    _peerConnection?.dispose();
    _peerConnection = null;

    if (_renderersInitialized) {
      _localRenderer.srcObject = null;
      _remoteRenderer.srcObject = null;
    }

    if (mounted) {
      setState(() {
        _isRendering = false;
        _remoteHasVideo = false;
      });
      if (navigateBack && context.canPop()) {
        context.pop();
      }
    }

    _webSocketService.disconnect();
  }

  Future<void> _endCall() async {
    _webSocketService.send(
      '/app/call/${widget.conversationId}/end',
      {
        'senderId': _myUserId,
        'counterpartId': widget.counterpartId,
      },
    );

    await Future.delayed(const Duration(milliseconds: 200));
    await _cleanup(navigateBack: true);
  }

  void _applyEffect(String effect) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Effect $effect applied!')));
    ref.read(showEffectsProvider.notifier).state = false;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Build
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showAlert = ref.watch(showAlertProvider);
    final isMuted = ref.watch(isMutedProvider);
    final isCameraOff = ref.watch(isCameraOffProvider);
    final isSpeakerOn = ref.watch(isSpeakerOnProvider);
    final isFrontCamera = ref.watch(isFrontCameraProvider);
    final showEffects = ref.watch(showEffectsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient / Avatar
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF7A5AF8), Color(0xFF4A3AB8)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor:
                          _colorFromName(widget.contactName).withOpacity(0.2),
                      child: Text(
                        widget.contactName
                            .split(' ')
                            .map((p) => p.isNotEmpty ? p[0] : '')
                            .take(2)
                            .join(),
                        style: TextStyle(
                          color: _colorFromName(widget.contactName),
                          fontWeight: FontWeight.w600,
                          fontSize: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(widget.contactName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      _remoteHasVideo ? l10n.videoCall : l10n.audioCall,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Remote video — FULL SCREEN background ──────────────────────────
          if (_renderersInitialized)
            Positioned.fill(
              child: Visibility(
                visible: _remoteHasVideo,
                maintainState: true,
                maintainAnimation: true,
                maintainSize: true,
                child: RTCVideoView(
                  _remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),

          // ── Local video — small PiP top-right ─────────────────────────────
          if (_renderersInitialized && _isRendering && !isCameraOff)
            Positioned(
              top: MediaQuery.of(context).padding.top + 100,
              right: 20,
              width: 120,
              height: 160,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.4), blurRadius: 8)
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: RTCVideoView(
                    _localRenderer,
                    mirror: isFrontCamera,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              ),
            ),

          // ── Info button ───────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: GestureDetector(
              onTap: () => ref.read(showAlertProvider.notifier).state = true,
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white24,
                child: Icon(Icons.info_outline, color: Colors.white, size: 20),
              ),
            ),
          ),

          // ── Alert overlay ─────────────────────────────────────────────────
          if (showAlert)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 16,
              right: 16,
              child: ImportantAlert(
                onClose: () =>
                    ref.read(showAlertProvider.notifier).state = false,
              ),
            ),

          // ── Effects panel ─────────────────────────────────────────────────
          if (showEffects)
            Positioned(
              left: 0,
              right: 0,
              bottom: 320,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _EffectButton(
                            icon: Icons.tag_faces,
                            label: 'Filter 1',
                            onTap: () => _applyEffect('Filter 1')),
                        _EffectButton(
                            icon: Icons.sentiment_satisfied,
                            label: 'Filter 2',
                            onTap: () => _applyEffect('Filter 2')),
                        _EffectButton(
                            icon: Icons.face,
                            label: 'Filter 3',
                            onTap: () => _applyEffect('Filter 3')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () =>
                          ref.read(showEffectsProvider.notifier).state = false,
                      child: const Text('Close',
                          style: TextStyle(
                              color: AppColors.chipSelected,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),

          // ── Bottom draggable controls ─────────────────────────────────────
          DraggableScrollableSheet(
            controller: _draggableController,
            initialChildSize: 0.25,
            minChildSize: 0.12,
            maxChildSize: 0.30,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Control row: effects / mute / flip / end
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CallControlButton(
                            icon: AppConstants.isCupertino
                                ? CupertinoIcons.dial
                                : Icons.light_mode_outlined,
                            label: l10n.effects,
                            onTap: () => ref
                                .read(showEffectsProvider.notifier)
                                .state = !ref.read(showEffectsProvider),
                          ),
                          CallControlButton(
                            icon: AppConstants.isCupertino
                                ? (isMuted
                                    ? CupertinoIcons.mic_slash_fill
                                    : CupertinoIcons.mic_fill)
                                : (isMuted
                                    ? Icons.mic_off_outlined
                                    : Icons.mic_none_outlined),
                            label: l10n.mute,
                            onTap: () {
                              final newMuted = !isMuted;
                              ref.read(isMutedProvider.notifier).state =
                                  newMuted;
                              _localStream
                                  ?.getAudioTracks()
                                  .forEach((t) => t.enabled = !newMuted);
                            },
                          ),
                          if (!isCameraOff && _isRendering)
                            CallControlButton(
                              icon: AppConstants.isCupertino
                                  ? CupertinoIcons.switch_camera_solid
                                  : Icons.flip_camera_ios_outlined,
                              label: l10n.flip,
                              onTap: _switchCamera,
                            ),
                          CallControlButton(
                            icon: AppConstants.isCupertino
                                ? CupertinoIcons.xmark_circle_fill
                                : Icons.close,
                            label: l10n.end,
                            backgroundColor: Colors.red,
                            onTap: _endCall,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Action row: camera / speaker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CallActionButton(
                          icon: AppConstants.isCupertino
                              ? (isCameraOff
                                  ? Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        const Icon(
                                            CupertinoIcons.video_camera_solid),
                                        Transform.rotate(
                                          angle: 0.785398,
                                          child: const Icon(
                                              CupertinoIcons.minus,
                                              size: 28,
                                              color: Colors.red),
                                        ),
                                      ],
                                    )
                                  : const Icon(
                                      CupertinoIcons.video_camera_solid))
                              : (isCameraOff
                                  ? const Icon(Icons.videocam_outlined)
                                  : const Icon(Icons.videocam_off_outlined)),
                          label: isCameraOff ? l10n.videoOn : l10n.cameraOff,
                          onTap: () async {
                            final turningOn = isCameraOff;
                            ref.read(isCameraOffProvider.notifier).state =
                                !isCameraOff;

                            if (turningOn) {
                              if (_localStream != null &&
                                  _localStream!.getVideoTracks().isEmpty) {
                                // Add video track if missing
                                final videoStream = await navigator.mediaDevices
                                    .getUserMedia({'video': true});
                                final videoTrack =
                                    videoStream.getVideoTracks().first;
                                _localStream!.addTrack(videoTrack);
                                await _peerConnection?.addTrack(
                                    videoTrack, _localStream!);
                                await _createOfferFlow(); // Renegotiate
                              } else {
                                _localStream
                                    ?.getVideoTracks()
                                    .forEach((t) => t.enabled = true);
                              }
                              setState(() => _isRendering = true);
                            } else {
                              _localStream
                                  ?.getVideoTracks()
                                  .forEach((t) => t.enabled = false);
                              if (mounted) setState(() => _isRendering = false);
                            }
                          },
                        ),
                        CallActionButton(
                          icon: AppConstants.isCupertino
                              ? (isSpeakerOn
                                  ? const Icon(CupertinoIcons.speaker_1_fill)
                                  : const Icon(CupertinoIcons.speaker_3_fill))
                              : (isSpeakerOn
                                  ? const Icon(Icons.volume_down_outlined)
                                  : const Icon(Icons.volume_up_outlined)),
                          label: isSpeakerOn ? l10n.earpiece : l10n.speaker,
                          onTap: () async {
                            final newVal = !isSpeakerOn;
                            ref.read(isSpeakerOnProvider.notifier).state =
                                newVal;
                            await Helper.setSpeakerphoneOn(newVal);
                          },
                        ),
                      ],
                    ),
                    SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 20),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _EffectButton
// ═══════════════════════════════════════════════════════════════════════════════

class _EffectButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _EffectButton(
      {super.key,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey[200],
            child: Icon(icon, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}
*/
