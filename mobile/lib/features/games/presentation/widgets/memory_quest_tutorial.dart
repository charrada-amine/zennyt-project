import 'package:flutter/material.dart';

import '../../domain/config/memory_quest_config.dart';
import '../../domain/entities/memory_quest_metrics.dart';
import 'game_tutorial_deck.dart';

const kMemoryDigitsTutorialAssets = [
  'assets/games icons/Memory Quest Digits Tutorial Observe.png',
  'assets/games icons/Memory Quest Digits Tutorial Same.png',
  'assets/games icons/Memory Quest Digits Tutorial Reverse.png',
  'assets/games icons/Memory Quest Digits Tutorial Protect.png',
  'assets/games icons/Memory Quest Digits Tutorial Validate.png',
  'assets/games icons/Memory Quest Digits Tutorial Progress.png',
];

const kMemoryImagesTutorialAssets = [
  'assets/games icons/Memory Quest Image Tutorial Observe.png',
  'assets/games icons/Memory Quest Image Tutorial Moved.png',
  'assets/games icons/Memory Quest Image Tutorial Protect.png',
  'assets/games icons/Memory Quest Image Tutorial Rank.png',
  'assets/games icons/Memory Quest Image Tutorial Validate.png',
  'assets/games icons/Memory Quest Image Tutorial Progress.png',
];

/// Illustrations pédagogiques originales, distinctes des stimuli de partie.
/// PROVISOIRE — direction visuelle à valider sur appareil.
class MemoryQuestTutorial extends StatelessWidget {
  const MemoryQuestTutorial({
    super.key,
    required this.mode,
    required this.leading,
    required this.onComplete,
    this.reviewing = false,
  });

  final MemoryQuestMode mode;
  final Widget leading;
  final VoidCallback onComplete;
  final bool reviewing;

  @override
  Widget build(BuildContext context) {
    GameTutorialStep step(
      List<String> assets,
      int index,
      String title,
      String description,
      String semantics,
    ) => GameTutorialStep(
      title: title,
      description: description,
      illustration: Image.asset(
        assets[index],
        key: ValueKey(assets[index]),
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      ),
      illustrationLabel: semantics,
    );

    final digits = [
      step(
        kMemoryDigitsTutorialAssets,
        0,
        'Observe les chiffres',
        'Ils apparaissent un par un. Regarde et écoute : le clavier reste bloqué pendant la présentation.',
        'Trois chiffres révélés successivement, avec un symbole de regard et d’écoute.',
      ),
      step(
        kMemoryDigitsTutorialAssets,
        1,
        'Rappelle dans le même ordre',
        'Quand le clavier apparaît, saisis la séquence du premier chiffre au dernier.',
        'Exemple : trois, sept, deux, dans le sens de la flèche.',
      ),
      step(
        kMemoryDigitsTutorialAssets,
        2,
        'Puis dans l’ordre inverse',
        'Reprends la même séquence, du dernier chiffre au premier. Exemple : 3–7–2 devient 2–7–3.',
        'La séquence trois, sept, deux devient deux, sept, trois.',
      ),
      step(
        kMemoryDigitsTutorialAssets,
        3,
        'Protège ta séquence',
        'Dès le niveau ${MemoryQuestConfig.distractionMinLevel}, réponds à une courte question avant les rappels. Garde la séquence initiale en tête.',
        'La séquence mémorisée reste séparée de la question d’interférence.',
      ),
      step(
        kMemoryDigitsTutorialAssets,
        4,
        'Complète puis valide',
        'Saisis tous les chiffres pour activer « Validate ». La touche d’effacement corrige la dernière saisie.',
        'Trois cases remplies, une touche d’effacement et un bouton de validation.',
      ),
      step(
        kMemoryDigitsTutorialAssets,
        5,
        'Avance à ton rythme',
        'Commence avec ${MemoryQuestConfig.initialSequenceLength} chiffres. Un tour réussi en ajoute un ; ${MemoryQuestConfig.maxFailuresPerLevel} tours ratés au même niveau terminent la partie.',
        'Des séquences de plus en plus longues et deux tentatives au même niveau.',
      ),
    ];
    final images = [
      step(
        kMemoryImagesTutorialAssets,
        0,
        'Mémorise l’ordre de départ',
        'Observe les images et leur ordre initial. Tu ne peux pas encore répondre. Ces symboles illustrent seulement le tutoriel.',
        'Exemple pédagogique : coquillage, lune, plume, dans cet ordre.',
      ),
      step(
        kMemoryImagesTutorialAssets,
        1,
        'Garde le premier ordre',
        'Les images changent de place automatiquement. Retrouve ensuite leur ordre de départ, pas leur dernier arrangement.',
        'Les images sont échangées, mais le premier ordre reste celui à retenir.',
      ),
      step(
        kMemoryImagesTutorialAssets,
        2,
        'Résiste à l’interruption',
        'Dès le niveau ${MemoryQuestConfig.imagesDistractionMinLevel}, trouve l’intrus ou la pièce manquante avant la restitution. Garde l’ordre initial en tête.',
        'Un casse-tête visuel séparé des images mémorisées.',
      ),
      step(
        kMemoryImagesTutorialAssets,
        3,
        'Classe par appuis',
        'Touche les images dans l’ordre initial : chaque appui attribue le rang suivant. Retouche une image pour retirer son rang.',
        'Une main classe les images par appuis successifs, sans glisser-déposer.',
      ),
      step(
        kMemoryImagesTutorialAssets,
        4,
        'Valide avant la fin',
        'Classe toutes les images pour activer « Validate ». À la fin du chrono, ton classement est validé tel quel, même incomplet.',
        'Un classement complet, un bouton de validation et un compte à rebours.',
      ),
      step(
        kMemoryImagesTutorialAssets,
        5,
        'Un palier à la fois',
        'Commence avec ${MemoryQuestConfig.minObjectCount} images. Un tour réussi en ajoute une ; ${MemoryQuestConfig.maxFailuresPerLevel} tours ratés au même niveau terminent la partie.',
        'Des groupes d’images de plus en plus grands et deux tentatives au même niveau.',
      ),
    ];
    return GameTutorialDeck(
      leading: leading,
      onComplete: onComplete,
      completionLabel: reviewing ? 'Retour au menu pause' : 'Je suis prêt',
      steps: switch (mode) {
        MemoryQuestMode.digits => digits,
        MemoryQuestMode.images => images,
        // Le parcours historique enchaîne les deux missions. Une seule carte
        // finale explique la progression commune ; les modes séparés ont six cartes.
        MemoryQuestMode.full => [
          ...digits.take(5),
          images[0],
          images[1],
          // Dans le parcours historique, seule l’interférence des chiffres
          // est jouée : aucun casse-tête visuel supplémentaire par tour.
          images[3],
          images[4],
          step(
            kMemoryImagesTutorialAssets,
            5,
            'Progresse dans les deux missions',
            'Réussis les rappels et la restitution pour monter de niveau. ${MemoryQuestConfig.maxFailuresPerLevel} tours ratés au même niveau terminent la partie.',
            'Les deux missions progressent ensemble, avec deux tentatives par niveau.',
          ),
        ],
      },
    );
  }
}
