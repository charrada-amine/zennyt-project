import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

/// Aperçu local (PiP) affiché en haut à droite pendant un appel vidéo.
/// Le fond virtuel (flou/couleur/image) est appliqué en amont par Agora
/// directement sur le flux capturé, donc ce widget n'a plus besoin
/// d'appliquer lui-même un ColorFilter : l'aperçu affiche déjà l'effet.
class CallLocalPip extends StatelessWidget {
  final RtcEngine engine;
  final bool isFrontCamera;

  const CallLocalPip({
    super.key,
    required this.engine,
    required this.isFrontCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 100,
      right: 20,
      width: 120,
      height: 160,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: engine,
              canvas: VideoCanvas(
                uid: 0,
                renderMode: RenderModeType.renderModeHidden,
                mirrorMode: isFrontCamera
                    ? VideoMirrorModeType.videoMirrorModeEnabled
                    : VideoMirrorModeType.videoMirrorModeDisabled,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
