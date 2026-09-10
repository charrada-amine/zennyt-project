import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'game_system_components.dart';

/// Radar media, including bundled demo clips. Playback is always user initiated.
/// Leaving the app or opening a game overlay pauses without automatic resume.
class EmotionalRadarVideo extends StatefulWidget {
  const EmotionalRadarVideo({
    super.key,
    required this.source,
    this.playbackEnabled = true,
    this.onFullscreen,
  });

  final String source;
  final bool playbackEnabled;
  final VoidCallback? onFullscreen;

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
      return GamePanel(
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
      );
    }
    if (controller == null || !controller.value.isInitialized) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
          child: CircularProgressIndicator(semanticsLabel: 'Loading video'),
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
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: value.aspectRatio > 0 ? value.aspectRatio : 16 / 9,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(controller),
                    if (value.isBuffering)
                      const CircularProgressIndicator(
                        semanticsLabel: 'Buffering video',
                      ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                IconButton(
                  tooltip: value.isPlaying
                      ? 'Pause video'
                      : finished
                      ? 'Replay video'
                      : 'Play video',
                  onPressed: widget.playbackEnabled ? _togglePlayback : null,
                  icon: Icon(
                    value.isPlaying
                        ? Icons.pause_rounded
                        : finished
                        ? Icons.replay_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  color: ZennytGamePalette.gameBlue,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
                Expanded(
                  child: Text(
                    '${_time(value.position)} / ${_time(value.duration)}',
                    style: const TextStyle(color: ZennytGamePalette.ink),
                  ),
                ),
                if (widget.onFullscreen != null)
                  IconButton(
                    tooltip: 'Fullscreen video',
                    onPressed: () {
                      unawaited(controller.pause());
                      widget.onFullscreen!();
                    },
                    icon: const Icon(Icons.fullscreen_rounded),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
