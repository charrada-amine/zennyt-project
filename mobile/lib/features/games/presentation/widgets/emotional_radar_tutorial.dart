import 'package:flutter/material.dart';

import '../../domain/config/emotional_radar_v2_config.dart';
import 'game_tutorial_deck.dart';

/// Images pédagogiques uniquement : aucune scène ni clé de correction du jeu.
const List<String> kEmotionalRadarTutorialAssets = [
  'assets/games icons/Emotional Radar Tutorial Observe.png',
  'assets/games icons/Emotional Radar Tutorial Choose.png',
  'assets/games icons/Emotional Radar Tutorial Intensity.png',
  'assets/games icons/Emotional Radar Tutorial Time.png',
  'assets/games icons/Emotional Radar Tutorial Validate.png',
];

/// Tutoriel du parcours V2 : émotion directe + intensité à trois niveaux.
/// Réutilise la pile de cartes approuvée pour Day Stack et son fond clair.
class EmotionalRadarTutorial extends StatelessWidget {
  const EmotionalRadarTutorial({
    super.key,
    required this.leading,
    required this.onComplete,
    this.reviewing = false,
  });

  final Widget leading;
  final VoidCallback onComplete;
  final bool reviewing;

  @override
  Widget build(BuildContext context) {
    final seconds = EmotionalRadarV2Config.maxResponseTimeMs ~/ 1000;
    final choices = EmotionalRadarV2Config.levels
        .map((level) => level.choicesCount)
        .toSet()
        .join(' ou ');
    final intensities = EmotionalRadarV2Config.intensityScale;
    return GameTutorialDeck(
      leading: leading,
      onComplete: onComplete,
      completionLabel: reviewing
          ? 'Reprendre la partie'
          : 'Commencer la partie',
      steps: [
        GameTutorialStep(
          title: 'Observe la scène',
          description:
              'Regarde la vidéo : le visage, les gestes et le contexte '
              'donnent des indices.',
          illustration: const _TutorialImage(index: 0),
          illustrationLabel:
              'Une vidéo et une loupe pour observer les indices.',
        ),
        GameTutorialStep(
          title: 'Choisis l’émotion',
          description:
              'Choisis l’émotion qui correspond à la scène parmi '
              '$choices propositions. La difficulté évolue avec ta progression.',
          illustration: const _TutorialImage(index: 1),
          illustrationLabel:
              'Choisir une émotion dans une grille de propositions.',
        ),
        GameTutorialStep(
          title: 'Évalue son intensité',
          description:
              'Choisis ${intensities[0]}, ${intensities[1]} '
              'ou ${intensities[2]} : à quel point cette émotion est-elle forte ?',
          illustration: const _TutorialImage(index: 2),
          illustrationLabel: 'Trois niveaux de force pour la même émotion.',
        ),
        GameTutorialStep(
          title: 'Garde un œil sur le temps',
          description:
              '$seconds secondes couvrent la vidéo et la réponse. '
              'Hors délai, la scène est manquée : réponds quand même.',
          illustration: const _TutorialImage(index: 3),
          illustrationLabel: 'Un seul chronomètre pour regarder et répondre.',
        ),
        GameTutorialStep(
          title: 'Valide puis continue',
          description:
              'Choisis une émotion et une intensité, puis valide. '
              'Le parcours comporte ${EmotionalRadarV2Config.totalScenes} scènes.',
          illustration: const _TutorialImage(index: 4),
          illustrationLabel: 'Deux choix complétés, puis leur validation.',
        ),
      ],
    );
  }
}

class _TutorialImage extends StatelessWidget {
  const _TutorialImage({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Image.asset(
      kEmotionalRadarTutorialAssets[index],
      key: ValueKey('radar-tutorial-image-$index'),
      fit: BoxFit.contain,
      cacheWidth:
          (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
              .ceil(),
      excludeFromSemantics: true,
    ),
  );
}
