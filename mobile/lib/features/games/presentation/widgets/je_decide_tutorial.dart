import 'package:flutter/material.dart';

import '../../domain/config/decision_config.dart';
import 'game_tutorial_deck.dart';

const List<String> kJeDecideTutorialAssets = [
  'assets/games icons/Je Decide Tutorial Choose.png',
  'assets/games icons/Je Decide Tutorial Linked.png',
  'assets/games icons/Je Decide Tutorial Time.png',
];

/// Explications du parcours existant, sans réponse ni clé de cotation.
/// PROVISOIRE — illustrations pédagogiques à valider visuellement sur appareil.
class JeDecideTutorial extends StatelessWidget {
  const JeDecideTutorial({
    super.key,
    required this.leading,
    required this.onComplete,
    this.reviewing = false,
    this.showHeader = true,
  });

  final Widget leading;
  final VoidCallback onComplete;
  final bool reviewing;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    Widget image(int index) => Image.asset(
      kJeDecideTutorialAssets[index],
      key: ValueKey('je-decide-tutorial-image-$index'),
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );
    return GameTutorialDeck(
      leading: leading,
      showHeader: showHeader,
      onComplete: onComplete,
      completionLabel: reviewing ? 'Reprendre la partie' : 'Essayer l’exemple',
      steps: [
        GameTutorialStep(
          title: 'Lis, puis choisis',
          description:
              'Lis la situation et touche l’option qui te correspond. '
              'Appuie sur « Continuer » pour avancer. '
              'Aucun message bon ou mauvais immédiat.',
          illustration: image(0),
          illustrationLabel:
              'Une option sélectionnée parmi plusieurs propositions.',
        ),
        GameTutorialStep(
          title: 'Suis le fil de l’histoire',
          description:
              'Les formats varient : comparaison, risque ou préférence. '
              'Certains scénarios se poursuivent en deux parties liées.',
          illustration: image(1),
          illustrationLabel: 'Deux parties consécutives d’une même histoire.',
        ),
        GameTutorialStep(
          title: 'Surveille le chrono',
          description:
              '${DecisionConfig.questionTimeLimitS} s pour les questions '
              'ordinaires ; moins pour les choix rapides. À zéro, ton choix est '
              'validé ou la question passe sans réponse.',
          illustration: image(2),
          illustrationLabel:
              'Le compte à rebours accompagne le passage à la question suivante.',
        ),
      ],
    );
  }
}
