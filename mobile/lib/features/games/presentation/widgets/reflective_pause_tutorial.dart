import 'package:flutter/material.dart';

import '../../domain/config/reflective_pause_config.dart';
import '../../domain/entities/reflective_pause_metrics.dart';
import 'game_tutorial_deck.dart';

const List<String> kReflectivePauseTutorialAssets = [
  'assets/games icons/Reflective Pause Tutorial Discover.png',
  'assets/games icons/Reflective Pause Tutorial Wait.png',
  'assets/games icons/Reflective Pause Tutorial Choose.png',
  'assets/games icons/Reflective Pause Tutorial Validate.png',
  'assets/games icons/Reflective Pause Tutorial Review.png',
];

/// Cartes pédagogiques uniquement, sans réponse recommandée ni cotation.
/// PROVISOIRE — illustrations à valider visuellement sur appareil.
class ReflectivePauseTutorial extends StatelessWidget {
  const ReflectivePauseTutorial({
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
    Widget image(int index) => Image.asset(
      kReflectivePauseTutorialAssets[index],
      key: ValueKey('reflective-tutorial-image-$index'),
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );
    return GameTutorialDeck(
      leading: leading,
      onComplete: onComplete,
      completionLabel: reviewing
          ? 'Reprendre la partie'
          : 'Commencer la partie',
      steps: [
        GameTutorialStep(
          title: 'Découvre la situation',
          description:
              'Lis le message ou observe la scène vidéo. '
              'Repère ce qui se passe avant de réagir.',
          illustration: image(0),
          illustrationLabel:
              'Une situation présentée par un message ou une vidéo.',
        ),
        GameTutorialStep(
          title: 'Prends un temps de recul',
          description:
              'Les réponses se débloquent à la fin du compte à rebours. '
              'Profite de ce temps pour réfléchir.',
          illustration: image(1),
          illustrationLabel:
              'Un chronomètre et un cadenas fermé avant le choix.',
        ),
        GameTutorialStep(
          title: 'Choisis ta réaction',
          description:
              'Parmi les ${ReflectivePauseResponseType.values.length} '
              'réponses, choisis celle qui te vient naturellement. '
              'Leur ordre peut changer selon la situation.',
          illustration: image(2),
          illustrationLabel:
              'Une seule réponse sélectionnée parmi cinq propositions.',
        ),
        GameTutorialStep(
          title: 'Valide ton choix',
          description:
              'Valide pour enregistrer ta réponse et passer à la suite. '
              'La barre indique un temps conseillé, sans bloquer ta réponse.',
          illustration: image(3),
          illustrationLabel:
              'Une réponse enregistrée, sans correction immédiate.',
        ),
        GameTutorialStep(
          title: 'Découvre ton bilan',
          description:
              'Après ${ReflectivePauseConfig.totalMoments} situations, '
              'consulte tes résultats et tes tendances. '
              'Aucune correction « bon ou mauvais » pendant la partie.',
          illustration: image(4),
          illustrationLabel:
              'Le bilan global des réactions à la fin du parcours.',
        ),
      ],
    );
  }
}
