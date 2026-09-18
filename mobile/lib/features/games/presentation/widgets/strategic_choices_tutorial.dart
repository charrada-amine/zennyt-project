import 'package:flutter/material.dart';

import '../../domain/config/strategic_choices_content.dart';
import 'game_tutorial_deck.dart';

const List<String> kStrategicChoicesTutorialAssets = [
  'assets/games icons/Strategic Choices Tutorial Read.png',
  'assets/games icons/Strategic Choices Tutorial Reflect.png',
  'assets/games icons/Strategic Choices Tutorial Choose.png',
  'assets/games icons/Strategic Choices Tutorial Validate.png',
  'assets/games icons/Strategic Choices Tutorial Review.png',
];

/// Explications pédagogiques, sans stratégie recommandée ni clé de cotation.
/// PROVISOIRE — illustrations à valider visuellement sur appareil.
class StrategicChoicesTutorial extends StatelessWidget {
  const StrategicChoicesTutorial({
    super.key,
    required this.leading,
    required this.onComplete,
    required this.totalSituations,
    this.reviewing = false,
  });

  final Widget leading;
  final VoidCallback onComplete;
  final int totalSituations;
  final bool reviewing;

  @override
  Widget build(BuildContext context) {
    Widget image(int index) => Image.asset(
      kStrategicChoicesTutorialAssets[index],
      key: ValueKey('strategic-tutorial-image-$index'),
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
          title: 'Lis la situation',
          description:
              'Lis le message ou la description de la scène. '
              'Les vidéos sont encore en préparation.',
          illustration: image(0),
          illustrationLabel:
              'Un message et une scène écrite à observer attentivement.',
        ),
        GameTutorialStep(
          title: 'Lance la réflexion',
          description:
              'Appuie sur « Start reflection ». '
              'Tu peux choisir pendant le compte à rebours.',
          illustration: image(1),
          illustrationLabel:
              'Un bouton lance manuellement le compte à rebours.',
        ),
        GameTutorialStep(
          title: 'Choisis une stratégie',
          description:
              'Parmi les ${StrategicChoicesContent.strategies.length} '
              'stratégies, choisis celle qui te paraît la plus adaptée à la situation.',
          illustration: image(2),
          illustrationLabel:
              'Une seule stratégie sélectionnée parmi huit propositions.',
        ),
        GameTutorialStep(
          title: 'Valide après la pause',
          description:
              'À la fin du compte à rebours, valide ton choix '
              'pour l’enregistrer et passer à la situation suivante.',
          illustration: image(3),
          illustrationLabel:
              'Une réponse enregistrée lorsque le compte à rebours est terminé.',
        ),
        GameTutorialStep(
          title: 'Découvre tes tendances',
          description:
              'Après $totalSituations situations, consulte ton score '
              'provisoire et tes tendances. Aucune correction immédiate pendant la partie.',
          illustration: image(4),
          illustrationLabel:
              'Un bilan des stratégies choisies à la fin du parcours.',
        ),
      ],
    );
  }
}
