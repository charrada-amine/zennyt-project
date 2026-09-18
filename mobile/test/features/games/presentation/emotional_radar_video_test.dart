import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/app_icon_finders.dart';
import 'package:zennyt/shared/icons/app_icons.dart';

// video_player's federated interface is provided by the approved player dependency.
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:zennyt/features/games/presentation/widgets/emotional_radar_video.dart';
import 'package:zennyt/features/games/presentation/widgets/game_system_components.dart';

class _VideoPlatform extends VideoPlayerPlatform {
  final streams = <int, StreamController<VideoEvent>>{};
  final played = <int>[];
  final paused = <int>[];
  final disposed = <int>[];
  final sources = <DataSource>[];
  final seeks = <Duration>[];
  bool fail = false;

  @override
  Future<void> init() async {}
  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final id = streams.length;
    final stream = StreamController<VideoEvent>();
    streams[id] = stream;
    sources.add(options.dataSource);
    if (fail) {
      stream.addError(
        PlatformException(
          code: 'video-failed',
          message: 'Unable to load video',
        ),
      );
    } else {
      stream.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          size: const Size(1280, 720),
          duration: const Duration(seconds: 6),
        ),
      );
    }
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => streams[playerId]!.stream;
  @override
  Future<void> dispose(int playerId) async {
    disposed.add(playerId);
    await streams[playerId]?.close();
  }

  @override
  Future<void> play(int playerId) async {
    played.add(playerId);
  }

  @override
  Future<void> pause(int playerId) async {
    paused.add(playerId);
  }

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    seeks.add(position);
  }

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> setPreventsDisplaySleepDuringVideoPlayback(
    int playerId,
    bool preventsDisplaySleepDuringVideoPlayback,
  ) async {}
  @override
  Widget buildView(int playerId) => const ColoredBox(color: Colors.black);
}

void main() {
  late _VideoPlatform platform;
  setUp(() {
    platform = _VideoPlatform();
    VideoPlayerPlatform.instance = platform;
  });

  Future<void> pumpVideo(
    WidgetTester tester, {
    bool enabled = true,
    VoidCallback? fullscreen,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 350,
            child: EmotionalRadarVideo(
              source: 'assets/demo.mp4',
              playbackEnabled: enabled,
              onFullscreen: fullscreen,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'loads a bundled asset without autoplay and pauses for overlays',
    (tester) async {
      await pumpVideo(tester);
      expect(platform.sources.single.sourceType, DataSourceType.asset);
      expect(platform.played, isEmpty);
      await tester.tap(find.byTooltip('Play video'));
      await tester.pump();
      expect(platform.played, [0]);
      await pumpVideo(tester, enabled: false);
      expect(platform.paused, contains(0));
      expect(
        tester
            .widget<IconButton>(
              findWidgetWithAppIcon(IconButton, HugeIcons.strokeRoundedPlay),
            )
            .onPressed,
        isNull,
      );
      await pumpVideo(tester);
      expect(platform.played, [
        0,
      ], reason: 'closing an overlay must not autoplay');
    },
  );

  testWidgets('pauses on background and disposes when leaving the screen', (
    tester,
  ) async {
    await pumpVideo(tester);
    await tester.tap(find.byTooltip('Play video'));
    await tester.pump();
    final count = platform.paused.length;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(platform.paused.length, greaterThan(count));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 10));
    expect(platform.disposed, contains(0));
  });

  testWidgets('fullscreen pauses inline video before opening', (tester) async {
    var opened = false;
    await pumpVideo(tester, fullscreen: () => opened = true);
    await tester.tap(find.byTooltip('Play video'));
    await tester.pump();
    final count = platform.paused.length;
    await tester.tap(find.byTooltip('Fullscreen video'));
    await tester.pump();
    expect(opened, isTrue);
    expect(platform.paused.length, greaterThan(count));
  });

  testWidgets('failed loading leaves a usable retry and recovers', (
    tester,
  ) async {
    platform.fail = true;
    await pumpVideo(tester);
    expect(find.textContaining('written scene'), findsOneWidget);
    expect(find.text('Retry video'), findsOneWidget);
    platform.fail = false;
    // Invoke the retry action without the shared button's native audio plugin.
    tester
        .widget<GameOutlineButton>(find.byType(GameOutlineButton))
        .onPressed!();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Play video'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 10));
    expect(platform.disposed, contains(0));
  });

  testWidgets('completed footage can replay from the beginning', (
    tester,
  ) async {
    await pumpVideo(tester);
    platform.streams[0]!.add(VideoEvent(eventType: VideoEventType.completed));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Replay video'), findsOneWidget);
    await tester.tap(find.byTooltip('Replay video'));
    await tester.pump();
    expect(platform.seeks.last, Duration.zero);
    expect(platform.played, contains(0));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
