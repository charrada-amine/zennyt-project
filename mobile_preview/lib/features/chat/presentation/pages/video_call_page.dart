import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/chat_summary.dart';

/// Écran d'appel visio (interview). Vidéo distante plein écran, bandeau
/// "Important !" (enregistrement), et barre de contrôles bas.
class VideoCallPage extends StatefulWidget {
  final ChatSummary chat;
  const VideoCallPage({super.key, required this.chat});
  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  bool _bannerShown = true;
  bool _muted = false;
  bool _cameraOff = false;
  bool _speaker = true;

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // "Vidéo distante" (mock).
          Image.network(
            'https://picsum.photos/seed/${chat.id}call/800/1400',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFF222634)),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black54, Colors.transparent, Colors.black54],
              ),
            ),
          ),

          // Haut : nom + bouton info.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                Text(chat.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _bannerShown = true),
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                ),
              ]),
            ),
          ),

          // Bandeau "Important !".
          if (_bannerShown)
            Positioned(
              top: MediaQuery.of(context).padding.top + 52,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Important !',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, color: AppTheme.navy)),
                        SizedBox(height: 4),
                        Text(
                            'The video interview will be automatically recorded for '
                            'moderation purposes. Do not ask for a candidate\'s '
                            'personal contact details.',
                            style: TextStyle(color: AppTheme.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _bannerShown = false),
                    child: const Icon(Icons.close, size: 18, color: AppTheme.muted),
                  ),
                ]),
              ),
            ),

          // Bas : contrôles.
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(40)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _round(Icons.auto_awesome, 'Effects', false, () {}),
                          _round(_muted ? Icons.mic_off : Icons.mic, 'Mute', _muted,
                              () => setState(() => _muted = !_muted)),
                          _round(Icons.flip_camera_ios, 'Flip', false, () {}),
                          _round(Icons.call_end, 'End', true, () => context.pop()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _pill(_cameraOff ? 'Camera On' : 'Camera Off', Icons.videocam_off,
                          () => setState(() => _cameraOff = !_cameraOff)),
                      const SizedBox(width: 12),
                      _pill('Speaker', Icons.volume_up,
                          () => setState(() => _speaker = !_speaker),
                          active: _speaker),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _round(IconData icon, String label, bool danger, VoidCallback onTap) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Material(
        color: danger ? const Color(0xFFE53935) : Colors.white24,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
    ]);
  }

  Widget _pill(String label, IconData icon, VoidCallback onTap, {bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: active ? AppTheme.brandBlue : Colors.black.withOpacity(0.45),
            borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ]),
      ),
    );
  }
}
