import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

/// Vidéo plein écran du correspondant. Le fond virtuel du correspondant
/// (s'il en a activé un) est déjà "cuit" dans le flux qu'on reçoit : pas
/// besoin de ColorFiltered ni de provider remoteFilterType côté client.
class CallRemoteVideo extends StatelessWidget {
  final RtcEngine engine;
  final String channelName;
  final int remoteUid;
  final bool remoteHasVideo;

  const CallRemoteVideo({
    super.key,
    required this.engine,
    required this.channelName,
    required this.remoteUid,
    required this.remoteHasVideo,
  });

  @override
  Widget build(BuildContext context) {
    final videoWidget = AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: engine,
        canvas: VideoCanvas(
          uid: remoteUid,
          renderMode: RenderModeType.renderModeHidden,
        ),
        connection: RtcConnection(channelId: channelName),
      ),
    );

    // Always render the video view; Agora will show black until frames arrive.
    // The remoteHasVideo flag is used only for UI indicators, not for hiding the view.
    return Positioned.fill(child: videoWidget);
  }
}
