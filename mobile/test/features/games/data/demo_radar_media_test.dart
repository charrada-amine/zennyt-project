import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/demo_games_repository.dart';
import 'package:zennyt/features/games/data/games_mock_repository.dart';
import 'package:zennyt/features/games/domain/entities/emotional_radar.dart';
import 'package:zennyt/features/games/domain/entities/game_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'demo clips are bundled, described and preserve the original scene catalogue',
    () async {
      final demo = DemoGamesRepository();
      final standard = GamesMockRepository();
      final session = await demo.startSession(GameType.emotionalRegulation);
      final demoSet = await demo.emotionalRadarScenes(session.id);
      final original = await standard.emotionalRadarScenes(session.id);
      expect(demoSet.totalScenes, original.totalScenes);
      expect(demoSet.maxPoints, original.maxPoints);
      for (var i = 0; i < demoSet.scenes.length; i++) {
        final scene = demoSet.scenes[i];
        expect(scene.id, original.scenes[i].id);
        expect(scene.promptText, original.scenes[i].promptText);
        expect(scene.mediaType, SceneMediaType.video);
        expect(scene.altText, isNotEmpty);
        expect(scene.transcript, contains('not an exact reenactment'));
        final bytes = await rootBundle.load(scene.mediaUrl!);
        expect(bytes.lengthInBytes, greaterThan(1000));
        expect(String.fromCharCodes(bytes.buffer.asUint8List(4, 4)), 'ftyp');
      }
      expect(original.scenes.first.mediaType, SceneMediaType.dialogue);
    },
  );

  test(
    'demo media leave Radar grading identical for correct and incorrect answers',
    () async {
      final demo = DemoGamesRepository();
      final standard = GamesMockRepository();
      final demoSession = await demo.startSession(GameType.emotionalRegulation);
      final standardSession = await standard.startSession(
        GameType.emotionalRegulation,
      );
      final scenes = (await demo.emotionalRadarScenes(demoSession.id)).scenes;
      final choices = [
        (BasicEmotion.sadness, 'DISAPPOINTMENT', 3),
        (BasicEmotion.fear, 'ANXIETY', 4),
        (BasicEmotion.sadness, 'EMPATHIC_PAIN', 3),
      ];
      for (var i = 0; i < scenes.length; i++) {
        for (final choice in [
          choices[i],
          (BasicEmotion.joy, 'EXCITEMENT', 1),
        ]) {
          final a = await demo.answerEmotionalRadarScene(
            sessionId: demoSession.id,
            sceneId: scenes[i].id,
            emotion: choice.$1,
            nuanceKey: choice.$2,
            intensity: choice.$3,
          );
          final b = await standard.answerEmotionalRadarScene(
            sessionId: standardSession.id,
            sceneId: scenes[i].id,
            emotion: choice.$1,
            nuanceKey: choice.$2,
            intensity: choice.$3,
          );
          expect(a.scenePoints, b.scenePoints);
          expect(a.totalPoints, b.totalPoints);
          expect(a.expectedEmotion, b.expectedEmotion);
          expect(a.expectedNuance, b.expectedNuance);
        }
      }
    },
  );
}
