import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/audio/sound_service.dart';
import 'game_system_components.dart';

/// Radar media, including bundled demo clips. Playback is always user initiated.
/// Leaving the app or opening a game overlay pauses without automatic resume.
class EmotionalRadarVideo extends StatefulWidget {
  const EmotionalRadarVideo({
    super.key,
    required this.source,
    this.onDarkBackground = false,
    this.immersive = false,
    this.playbackEnabled = true,
    this.onFullscreen,
  });

  final String source;
  final bool playbackEnabled;
  final VoidCallback? onFullscreen;

  /// Contrôles posés sur un fond sombre.
  ///
  /// Sans cela, le bouton de lecture et le minutage gardent leurs couleurs de
  /// carte — bleu et encre — et deviennent illisibles.
  final bool onDarkBackground;

  /// Lecture immersive : la vidéo occupe TOUTE la place disponible et les
  /// contrôles passent en surimpression, comme un lecteur plein écran.
  ///
  /// En mode carte, le lecteur empile la vidéo puis ses contrôles : chacun
  /// prend sa part de hauteur. Ici on veut l'inverse — rien ne doit rogner
  /// l'image.
  final bool immersive;

  @override
  State<EmotionalRadarVideo> createState() => _EmotionalRadarVideoState();
}

class _EmotionalRadarVideoState extends State<EmotionalRadarVideo>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  Future<void> _load() async {
    final previous = _controller;
    _controller = null;
    if (previous != null) await previous.dispose();
    if (!mounted) return;
    setState(() => _failed = false);
    // This widget owns lifecycle pausing. Disable the plugin's automatic
    // foreground resume, which would restart a clip behind a game overlay.
    final controller = widget.source.startsWith('assets/')
        ? VideoPlayerController.asset(
            widget.source,
            videoPlayerOptions: VideoPlayerOptions(
              allowBackgroundPlayback: true,
            ),
          )
        : VideoPlayerController.networkUrl(
            Uri.parse(widget.source),
            videoPlayerOptions: VideoPlayerOptions(
              allowBackgroundPlayback: true,
            ),
          );
    _controller = controller;
    try {
      await controller.initialize().timeout(const Duration(seconds: 15));
      if (!mounted || _controller != controller) return;
      await controller.setVolume(0);
      if (mounted && _controller == controller) setState(() {});
    } catch (_) {
      if (mounted && _controller == controller) setState(() => _failed = true);
    }
  }

  @override
  void didUpdateWidget(covariant EmotionalRadarVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      unawaited(_load());
    } else if (!widget.playbackEnabled) {
      unawaited(_controller?.pause());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(_controller?.pause());
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null || !widget.playbackEnabled) return;
    try {
      if (controller.value.isPlaying) {
        await controller.pause();
      } else {
        if (controller.value.position >= controller.value.duration) {
          await controller.seekTo(Duration.zero);
        }
        await controller.play();
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller?.dispose());
    super.dispose();
  }

  static String _time(Duration duration) =>
      '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed) {
      // Rétrécit si le plateau ne laisse à la vidéo qu'une faible hauteur.
      return GameFitToScreen(
        alignment: Alignment.center,
        child: GamePanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Video unavailable. You can still use the written scene.',
              ),
              const SizedBox(height: 12),
              GameOutlineButton(label: 'Retry video', onPressed: _load),
            ],
          ),
        ),
      );
    }
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(
            child: CircularProgressIndicator(semanticsLabel: 'Loading video'),
          ),
        ),
      );
    }
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        if (value.hasError) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Video unavailable. Use the written scene below.'),
          );
        }
        final finished = value.position >= value.duration;
        final ratio = value.aspectRatio > 0 ? value.aspectRatio : 16 / 9;

        if (widget.immersive) {
          return Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Colors.black),
              Center(
                child: AspectRatio(
                  aspectRatio: ratio,
                  child: VideoPlayer(controller),
                ),
              ),
              if (value.isBuffering)
                const Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: 'Buffering video',
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: DecoratedBox(
                  // Voile sombre : sur une image claire, des contrôles blancs
                  // posés à nu deviennent illisibles.
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xCC000000), Color(0x00000000)],
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 24, 16, 8),
                      child: _controlsRow(context, value, finished, dark: true),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        // Mode carte : les contrôles sont posés SUR l'image (Stack) au lieu
        // d'être empilés dessous. La vidéo garde ainsi toute la hauteur que
        // le plateau peut lui accorder, et [AspectRatio] la réduit pour
        // qu'elle tienne en largeur comme en hauteur — le plateau entier
        // reste sur un seul écran, sans défilement.
        return Center(
          child: AspectRatio(
            aspectRatio: ratio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Colors.black),
                  VideoPlayer(controller),
                  if (value.isBuffering)
                    const Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: 'Buffering video',
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xB3000000), Color(0x00000000)],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 12, 4, 0),
                        child: _controlsRow(
                          context,
                          value,
                          finished,
                          dark: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Barre de contrôles, commune au mode carte et au mode immersif.
  ///
  /// Une seule définition : c'est elle qui porte lecture, minutage et plein
  /// écran, et les voir diverger entre les deux modes serait le premier pas
  /// vers un bouton présent d'un côté et absent de l'autre.
  Widget _controlsRow(
    BuildContext context,
    VideoPlayerValue value,
    bool finished, {
    bool dark = false,
  }) {
    final light = dark || widget.onDarkBackground;
    return Row(
      children: [
        IconButton(
          tooltip: value.isPlaying
              ? 'Pause video'
              : finished
              ? 'Replay video'
              : 'Play video',
          onPressed: widget.playbackEnabled
              ? () {
                  SoundService.instance.playSfx(GameSfx.buttonClick);
                  _togglePlayback();
                }
              : null,
          icon: Icon(
            value.isPlaying
                ? Icons.pause_rounded
                : finished
                ? Icons.replay_rounded
                : Icons.play_arrow_rounded,
          ),
          color: light ? Colors.white : ZennytGamePalette.gameBlue,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
        Expanded(
          child: Text(
            '${_time(value.position)} / ${_time(value.duration)}',
            style: TextStyle(
              color: light ? Colors.white : ZennytGamePalette.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (widget.onFullscreen != null)
          IconButton(
            tooltip: 'Fullscreen video',
            onPressed: () {
              SoundService.instance.playSfx(GameSfx.buttonClick);
              unawaited(_controller?.pause());
              widget.onFullscreen!();
            },
            icon: const Icon(Icons.fullscreen_rounded),
            color: light ? Colors.white : ZennytGamePalette.gameBlue,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
      ],
    );
  }
}
