import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/games_mock_repository.dart';
import 'package:zennyt/features/games/domain/config/emotional_radar_v2_provisional_rules.dart';
import 'package:zennyt/features/games/domain/config/emotional_radar_v2_referential.dart';
import 'package:zennyt/features/games/domain/entities/emotional_radar_v2.dart';
import 'package:zennyt/features/games/domain/entities/game_type.dart';

/// Rattachement des 3 seules vidéos produites (sur les 135 attendues).
///
/// Deux règles distinctes se croisent ici, et les confondre serait l'erreur :
///
/// 1. **Un clip suit son émotion, jamais un numéro de scène.** La v1 posait les
///    clips sur les scènes 1-2-3 quelle qu'en soit la cible : une femme
///    inquiète pouvait illustrer une réponse « Joie ». La vidéo contredisait
///    la correction — pire qu'un placeholder.
/// 2. **En démonstration, ce sont les ÉMOTIONS filmées qu'on avance en tête de
///    session**, pas les fichiers. Les trois premières scènes montrent donc de
///    vraies vidéos, et chacune illustre bien l'émotion qu'elle demande.
///
/// La seconde règle est temporaire (`DEMO_FOOTAGE_FIRST`) ; la première est
/// permanente.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('table de footage', () {
    test('chaque clip vise une émotion réelle du référentiel des 45', () {
      for (final key in EmotionalRadarV2ProvisionalRules.demoFootage.keys) {
        expect(
          emotionByKey(key),
          isNotNull,
          reason: '$key ne fait pas partie des 45 émotions du référentiel',
        );
      }
    });

    test('un stimulus contextuel porte sa légende, les autres non', () {
      EmotionalRadarV2ProvisionalRules.demoFootage.forEach((key, footage) {
        final emotion = emotionByKey(key)!;
        if (emotion.stimulusType == StimulusType.contextual) {
          // Le référentiel : « Légende contextuelle : requise uniquement pour
          // les stimuli de type contextuel ». Côté serveur, le VO refuse une
          // scène READY contextuelle sans légende — même règle ici.
          expect(
            footage.contextualCaption,
            isNotNull,
            reason: '$key est contextuel : sa légende est requise',
          );
          expect(footage.contextualCaption, isNotEmpty);
        } else {
          expect(
            footage.contextualCaption,
            isNull,
            reason: '$key n\'est pas contextuel : une légende y serait du bruit',
          );
        }
      });
    });

    test('aucune légende ne nomme l\'émotion à identifier', () {
      // Consigne client : « Aucun texte ne doit révéler l'émotion à identifier ».
      // Une légende n'a le droit de décrire que le décor.
      final allLabels = kEmotionReferential
          .map((emotion) => emotion.labelFr.toLowerCase())
          .toList();
      EmotionalRadarV2ProvisionalRules.demoFootage.forEach((key, footage) {
        final caption = footage.contextualCaption?.toLowerCase();
        if (caption == null) return;
        for (final label in allLabels) {
          expect(
            caption.contains(label),
            isFalse,
            reason: 'la légende de $key contient « $label »',
          );
        }
      });
    });

    test('les fichiers annoncés sont de vraies vidéos embarquées', () async {
      for (final footage
          in EmotionalRadarV2ProvisionalRules.demoFootage.values) {
        final bytes = await rootBundle.load(footage.mediaUrl);
        expect(bytes.lengthInBytes, greaterThan(1000));
        // En-tête ISO-BMFF : sans ce contrôle, un pointeur Git LFS non résolu
        // passerait pour une vidéo jusqu'à la lecture à l'écran.
        expect(
          String.fromCharCodes(bytes.buffer.asUint8List(4, 4)),
          'ftyp',
          reason: '${footage.mediaUrl} n\'est pas un MP4 — pointeur LFS ?',
        );
      }
    });
  });

  group('scènes servies', () {
    Future<EmotionalRadarV2Scene> sceneAt(
      GamesMockRepository repo,
      String sessionId,
      int order,
    ) async {
      var state = await repo.activateNextEmotionalRadarV2Scene(sessionId);
      while (state.currentScene!.sceneOrder < order) {
        final scene = state.currentScene!;
        await repo.answerEmotionalRadarV2Scene(
          sessionId: sessionId,
          sceneOrder: scene.sceneOrder,
          selectedEmotionKey: scene.choices.first.key,
          selectedIntensity: EmotionalRadarV2Intensity.moderate,
          explanation: 'peu importe',
        );
        state = await repo.activateNextEmotionalRadarV2Scene(sessionId);
      }
      return state.currentScene!;
    }

    test('les trois premières scènes jouent les trois clips', () async {
      final repo = GamesMockRepository();
      final session = await repo.startSession(GameType.emotionalRegulation);

      // DÉMO : `DEMO_FOOTAGE_FIRST` place les émotions filmées en tête pour
      // qu'une démonstration les montre à coup sûr. Sans cela, une session de
      // 15 scènes tirées dans 45 émotions n'en montrerait aucune une fois sur
      // trois.
      const attendu = <int, (String, String, String?)>{
        1: (
          'SADNESS',
          'assets/games_demo/emotional_radar/phone_call.mp4',
          null,
        ),
        2: (
          'ANXIETY',
          'assets/games_demo/emotional_radar/night_apartment.mp4',
          null,
        ),
        3: (
          'LONELINESS',
          'assets/games_demo/emotional_radar/park_bench.mp4',
          'Un parc, en fin de journée.',
        ),
      };

      for (final entry in attendu.entries) {
        final scene = await sceneAt(repo, session.id, entry.key);
        final (emotionKey, url, caption) = entry.value;

        expect(scene.mediaStatus, 'READY', reason: 'scène ${entry.key}');
        expect(scene.mediaUrl, url, reason: 'scène ${entry.key}');
        expect(scene.usesVideoPlaceholder, isFalse);
        // Légende seulement pour le stimulus contextuel.
        expect(scene.contextualCaption, caption, reason: 'scène ${entry.key}');
        // La cible reste bien parmi les propositions, sans être repérable
        // autrement que par la vidéo.
        expect(
          scene.choices.map((choice) => choice.key),
          contains(emotionKey),
        );
      }
    });

    test('la quatrième scène retombe sur un placeholder', () async {
      final repo = GamesMockRepository();
      final session = await repo.startSession(GameType.emotionalRegulation);

      // Les clips épuisés, le jeu reprend son cours normal : c'est ce qui
      // montre que la mise en avant est bornée aux trois premières scènes.
      final scene = await sceneAt(repo, session.id, 4);
      expect(scene.mediaStatus, 'PLACEHOLDER_PENDING');
      expect(scene.mediaUrl, isNull);
      expect(scene.usesVideoPlaceholder, isTrue);
    });
  });
}
