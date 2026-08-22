// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/call_ui_providers.dart';
import '../providers/call_recording_provider.dart';
import '../widgets/call_background.dart';
import '../widgets/call_consent_gate.dart';
import '../widgets/call_bottom_sheet.dart';
import '../widgets/call_local_pip.dart';
import '../widgets/call_overlays.dart';
import '../widgets/call_remote_video.dart';
import 'call_page_controller.dart';

class CallPage extends ConsumerStatefulWidget {
  final String contactName;
  final String? conversationId;
  final String? counterpartId;
  final String? myUserId;
  final Map<String, dynamic>? incomingOffer;
  final bool startWithCameraOn;

  final bool isVideoCall;

  const CallPage({
    super.key,
    required this.contactName,
    this.conversationId,
    this.counterpartId,
    this.myUserId,
    this.incomingOffer,
    this.startWithCameraOn = false,
    this.isVideoCall =false,
  });

  @override
  ConsumerState<CallPage> createState() => _CallPageState();
}

class _CallPageState extends ConsumerState<CallPage> {
  late final CallPageController _ctrl;

  /// Null tant que la personne n'a pas repondu : l'appel n'a alors pas commence.
  ///
  /// L'ecran de consentement passe AVANT `init()`, donc avant qu'Agora ne soit
  /// initialise et avant toute demande d'acces au micro. C'est la difference entre
  /// demander la permission et demander l'accord.
  bool? _consentement;
  final DraggableScrollableController _draggableController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _ctrl = CallPageController(
      ref: ref,
      context: context,
      contactName: widget.contactName,
      conversationId: widget.conversationId,
      counterpartId: widget.counterpartId,
      myUserId: widget.myUserId,
      incomingOffer: widget.incomingOffer,
      startWithCameraOn: widget.startWithCameraOn,
      isVideoCall: widget.isVideoCall,
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  /// Demarre reellement l'appel, une fois la personne informee.
  void _demarrer({required bool enregistre}) {
    setState(() => _consentement = enregistre);
    _ctrl.consentementEnregistrement = enregistre;
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.init());
  }

  @override
  void dispose() {
    _ctrl.cleanup();
    _ctrl.disposeRenderers();
    _draggableController.dispose();
    super.dispose();
  }

  void _applyVirtualBackground({
    required VirtualBgType type,
    String? imagePath,
  }) {
    _ctrl.applyVirtualBackground(
      type,
      imagePath: imagePath,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_consentement == null) {
      return CallConsentGate(
        onAccepte: () => _demarrer(enregistre: true),
        onRefuse: () => _demarrer(enregistre: false),
      );
    }

    final showAlert = ref.watch(showAlertProvider);
    final isCameraOff = ref.watch(isCameraOffProvider);
    final isFrontCamera = ref.watch(isFrontCameraProvider);
    final showVirtualBgPanel = ref.watch(showVirtualBgPanelProvider);
    final isRecording = ref.watch(isRecordingProvider);

    final bool showRemoteVideo = widget.isVideoCall &&
        _ctrl.renderersInitialized &&
        _ctrl.remoteUid != null;
    final bool showLocalPip = widget.isVideoCall &&
        _ctrl.renderersInitialized &&
        _ctrl.isRendering &&
        !isCameraOff;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CallBackground(
            contactName: widget.contactName,
            remoteHasVideo: widget.isVideoCall ,
          ),


          if (showRemoteVideo)
            CallRemoteVideo(
              engine: _ctrl.engine,
              channelName: _ctrl.channelName,
              remoteUid: _ctrl.remoteUid!,
              remoteHasVideo: _ctrl.remoteHasVideo,
            ),


          if (showLocalPip)
            CallLocalPip(
              engine: _ctrl.engine,
              isFrontCamera: isFrontCamera,
            ),


          const CallInfoButton(),


          if (showAlert) const CallAlertOverlay(),


          if (showVirtualBgPanel && widget.isVideoCall)
            CallVirtualBackgroundPanel(
              onApplyVirtualBackground: _applyVirtualBackground,
            ),

          // 6. Recording indicator (top-left)
          if (isRecording)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'REC',
                    style: TextStyle(
                      color: Colors.red.shade300,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // 7. Bottom controls
          CallBottomSheet(
            controller: _draggableController,
            isRendering: _ctrl.isRendering,
            onEndCall: _ctrl.endCall,
            onSwitchCamera: _ctrl.switchCamera,
            onToggleMute: _ctrl.toggleMute,
            onToggleCamera: _ctrl.toggleCamera,
            onToggleSpeaker: _ctrl.toggleSpeaker,
          ),
        ],
      ),
    );
  }
}
