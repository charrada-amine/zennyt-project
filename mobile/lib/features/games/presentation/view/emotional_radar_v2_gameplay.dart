/// Vues de jeu du Radar émotionnel v2.
///
/// Le référentiel client (Cowen & Keltner 2017, 45 émotions) impose une règle
/// que ces vues appliquent partout : **aucun texte ne doit révéler l'émotion à
/// identifier**. C'est pourquoi on n'affiche ici ni énoncé, ni consigne
/// descriptive, ni alternative textuelle du média — le contrat
/// [EmotionalRadarV2Scene] ne les transporte même pas. Seule exception prévue
/// par le référentiel : la légende contextuelle, réservée aux stimuli de type
/// contextuel et fournie par le serveur.
library;

import 'package:flutter/material.dart';

import '../../domain/config/emotional_radar_v2_config.dart';
import '../../domain/config/emotional_radar_v2_referential.dart';
import '../../domain/entities/emotional_radar_v2.dart';
import '../widgets/emotional_radar_components.dart';
import '../widgets/emotional_radar_video.dart';

/// Nombre de boutons d'émotion par ligne.
///
/// Le référentiel fixe `choices_per_level = 6 / 6 / 9 / 9` précisément pour
/// que la grille tombe juste : 2 lignes de 3, puis 3 lignes de 3. Changer
/// cette constante casserait cet alignement.
const int kRadarChoicesPerRow = 3;

// ══════════════════════════════════════════════════════════════════════════
// Scène
// ══════════════════════════════════════════════════════════════════════════

/// Le stimulus : la vidéo, son budget de réponse, et rien d'autre.
class RadarSceneStage extends StatelessWidget {
  const RadarSceneStage({
    super.key,
    required this.scene,
    required this.remainingMs,
    required this.onOpenFullscreen,
    this.playbackEnabled = true,
  });

  final EmotionalRadarV2Scene scene;

  /// Budget restant, décompté par l'écran. Le serveur reste l'autorité : ce
  /// compteur est un repère visuel, il ne décide de rien.
  final int remainingMs;

  final VoidCallback onOpenFullscreen;
  final bool playbackEnabled;

  bool get _expired => remainingMs <= 0;

  @override
  Widget build(BuildContext context) {
    final caption = scene.contextualCaption;
    return Container(
      decoration: BoxDecoration(
        color: EmotionalRadarPalette.card,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Seul le placeholder est contraint à un cadre 16:9 : il n'a pas de
          // taille propre. [EmotionalRadarVideo] en a une — il empile la vidéo
          // ET sa barre de contrôles, celle qui porte lecture, minutage et
          // plein écran. L'enfermer dans un 16:9 fixe écrasait cette barre.
          if (scene.usesVideoPlaceholder)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: const AspectRatio(
                aspectRatio: 16 / 9,
                child: RadarMediaPlaceholder(),
              ),
            )
          else
            EmotionalRadarVideo(
              source: scene.mediaUrl!,
              playbackEnabled: playbackEnabled,
              onFullscreen: onOpenFullscreen,
            ),
          // Légende contextuelle : prévue par le référentiel « uniquement pour
          // les stimuli de type contextuel », affichée dans l'interface et
          // jamais incrustée dans la vidéo. Le serveur ne la renseigne que
          // dans ce cas, l'écran se contente donc de la relayer.
          if (caption != null && caption.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: EmotionalRadarPalette.muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    caption,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: EmotionalRadarPalette.muted,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          RadarResponseBudget(
            remainingMs: remainingMs,
            totalMs: scene.maxResponseTimeMs,
          ),
          if (_expired) ...[
            const SizedBox(height: 8),
            // Le dépassement n'annule PAS la manche : le contrat exige toujours
            // une émotion et une intensité. Le serveur
            // marquera la réponse `timedOut` et la comptera fausse. On le dit
            // franchement plutôt que de verrouiller un panneau que le joueur
            // doit encore remplir.
            const Row(
              children: [
                Icon(
                  Icons.timer_off_outlined,
                  size: 18,
                  color: EmotionalRadarPalette.errorFg,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Temps écoulé — réponds quand même, la scène sera comptée '
                    'comme manquée.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      color: EmotionalRadarPalette.errorFg,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Cadre affiché tant que la vidéo de la scène n'est pas produite.
///
/// Volontairement muet sur le contenu attendu. Le référentiel classe chaque
/// émotion par type de cadrage (faciale, corporelle, relationnelle,
/// contextuelle), mais l'annoncer ici restreindrait les 6 ou 9 propositions et
/// révélerait donc une part de la réponse — ce que le référentiel interdit. Le
/// contrat serveur ne transmet d'ailleurs pas ce champ à l'écran.
class RadarMediaPlaceholder extends StatelessWidget {
  const RadarMediaPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Vidéo de la scène indisponible',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EmotionalRadarPalette.lockedTint,
          border: Border.all(color: EmotionalRadarPalette.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.movie_creation_outlined,
                size: 34,
                color: EmotionalRadarPalette.muted,
              ),
              SizedBox(height: 10),
              Text(
                'Vidéo en cours de production',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: EmotionalRadarPalette.ink,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Réponds selon ton intuition.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: EmotionalRadarPalette.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barre de budget de réponse.
class RadarResponseBudget extends StatelessWidget {
  const RadarResponseBudget({
    super.key,
    required this.remainingMs,
    required this.totalMs,
  });

  final int remainingMs;
  final int totalMs;

  @override
  Widget build(BuildContext context) {
    final ratio = totalMs <= 0
        ? 0.0
        : (remainingMs / totalMs).clamp(0.0, 1.0).toDouble();
    final seconds = (remainingMs / 1000).ceil().clamp(0, 999);
    final colour = ratio <= 0
        ? EmotionalRadarPalette.errorFg
        : ratio < 0.34
        ? const Color(0xFFF59E0B)
        : EmotionalRadarPalette.selectBlue;
    return Semantics(
      // Un compteur qui ne se lit qu'à l'œil exclut les lecteurs d'écran : on
      // annonce la valeur, pas seulement la barre.
      label: 'Temps restant : $seconds secondes',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Temps de réponse',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: EmotionalRadarPalette.muted,
                ),
              ),
              const Spacer(),
              Text(
                '$seconds s',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: colour,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: EmotionalRadarPalette.lockedTint,
              valueColor: AlwaysStoppedAnimation<Color>(colour),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Réponse
// ══════════════════════════════════════════════════════════════════════════

/// Panneau de réponse : émotion puis intensité.
class RadarAnswerPanel extends StatelessWidget {
  const RadarAnswerPanel({
    super.key,
    required this.scene,
    required this.selectedEmotionKey,
    required this.selectedIntensity,
    required this.validating,
    required this.onSelectEmotion,
    required this.onSelectIntensity,
    required this.onValidate,
  });

  final EmotionalRadarV2Scene scene;
  final String? selectedEmotionKey;
  final EmotionalRadarV2Intensity? selectedIntensity;
  final bool validating;
  final ValueChanged<String> onSelectEmotion;
  final ValueChanged<EmotionalRadarV2Intensity> onSelectIntensity;
  final VoidCallback onValidate;

  /// Émotion et intensité suffisent.
  ///
  /// La troisième question — la justification écrite — a été retirée à la
  /// demande du client. Le champ reste au contrat serveur, vide : la mesure
  /// redeviendra possible sans migration si elle revient.
  bool get _complete => selectedEmotionKey != null && selectedIntensity != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EmotionalRadarPalette.card,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _RadarStepLabel(index: 1, label: 'Quelle émotion domine ?'),
          const SizedBox(height: 12),
          RadarEmotionGrid(
            choices: scene.choices,
            selectedKey: selectedEmotionKey,
            onSelect: onSelectEmotion,
          ),
          const SizedBox(height: 20),
          const _RadarStepLabel(index: 2, label: 'À quelle intensité ?'),
          const SizedBox(height: 12),
          RadarIntensitySelector(
            selected: selectedIntensity,
            onSelect: onSelectIntensity,
          ),
          const SizedBox(height: 18),
          _RadarValidateButton(
            enabled: _complete && !validating,
            busy: validating,
            onPressed: onValidate,
          ),
        ],
      ),
    );
  }
}

class _RadarStepLabel extends StatelessWidget {
  const _RadarStepLabel({required this.index, required this.label});

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: EmotionalRadarPalette.selectTint,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: EmotionalRadarPalette.selectBlue,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: EmotionalRadarPalette.ink,
            ),
          ),
        ),
      ],
    );
  }
}

/// Grille des émotions proposées — 3 par ligne, 6 ou 9 selon le niveau.
class RadarEmotionGrid extends StatelessWidget {
  const RadarEmotionGrid({
    super.key,
    required this.choices,
    required this.selectedKey,
    required this.onSelect,
  });

  final List<EmotionalRadarV2Choice> choices;
  final String? selectedKey;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final width =
            (constraints.maxWidth - gap * (kRadarChoicesPerRow - 1)) /
            kRadarChoicesPerRow;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final choice in choices)
              SizedBox(
                width: width,
                child: RadarEmotionButton(
                  choice: choice,
                  selected: choice.key == selectedKey,
                  onTap: () => onSelect(choice.key),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Bouton d'une émotion proposée.
///
/// Sans pictogramme ni couleur par famille, contrairement à la version
/// précédente : avec 45 émotions, un code visuel par famille regrouperait
/// visuellement les distracteurs proches et donnerait un indice que le
/// référentiel ne prévoit pas. Le libellé porte seul le sens.
class RadarEmotionButton extends StatelessWidget {
  const RadarEmotionButton({
    super.key,
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final EmotionalRadarV2Choice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${choice.labelFr}, proposition d\'émotion',
      child: Material(
        color: selected
            ? EmotionalRadarPalette.selectTint
            : EmotionalRadarPalette.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            // 48 dp de haut au minimum : cible tactile accessible même pour le
            // libellé le plus court.
            constraints: const BoxConstraints(minHeight: 52),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? EmotionalRadarPalette.selectBlue
                    : EmotionalRadarPalette.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Text(
              choice.labelFr,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.2,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected
                    ? EmotionalRadarPalette.selectBlue
                    : EmotionalRadarPalette.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Échelle d'intensité perçue — Faible / Modérée / Intense.
class RadarIntensitySelector extends StatelessWidget {
  const RadarIntensitySelector({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final EmotionalRadarV2Intensity? selected;
  final ValueChanged<EmotionalRadarV2Intensity> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final intensity in EmotionalRadarV2Intensity.values) ...[
          Expanded(
            child: _RadarIntensityOption(
              intensity: intensity,
              selected: selected == intensity,
              onTap: () => onSelect(intensity),
            ),
          ),
          if (intensity != EmotionalRadarV2Intensity.values.last)
            const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _RadarIntensityOption extends StatelessWidget {
  const _RadarIntensityOption({
    required this.intensity,
    required this.selected,
    required this.onTap,
  });

  final EmotionalRadarV2Intensity intensity;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Trois barres de hauteur croissante : le sens est déjà porté par le
    // libellé, ceci n'est qu'un renfort visuel.
    final filled = intensity.wire + 1;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Intensité ${intensity.label}',
      child: Material(
        color: selected
            ? EmotionalRadarPalette.selectTint
            : EmotionalRadarPalette.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 68),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? EmotionalRadarPalette.selectBlue
                    : EmotionalRadarPalette.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var bar = 0; bar < 3; bar++) ...[
                      Container(
                        width: 6,
                        height: 8.0 + bar * 5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: bar < filled
                              ? (selected
                                    ? EmotionalRadarPalette.selectBlue
                                    : EmotionalRadarPalette.muted)
                              : EmotionalRadarPalette.border,
                        ),
                      ),
                      if (bar < 2) const SizedBox(width: 3),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  intensity.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected
                        ? EmotionalRadarPalette.selectBlue
                        : EmotionalRadarPalette.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarValidateButton extends StatelessWidget {
  const _RadarValidateButton({
    required this.enabled,
    required this.busy,
    required this.onPressed,
  });

  final bool enabled;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: EmotionalRadarPalette.magenta,
          disabledBackgroundColor: EmotionalRadarPalette.lockedTint,
          disabledForegroundColor: EmotionalRadarPalette.muted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Valider',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Correction
// ══════════════════════════════════════════════════════════════════════════

/// Correction d'une scène, telle que renvoyée par le serveur.
class RadarFeedbackCard extends StatelessWidget {
  const RadarFeedbackCard({
    super.key,
    required this.feedback,
    required this.selectedEmotionKey,
    required this.selectedIntensity,
  });

  final EmotionalRadarV2Feedback feedback;
  final String selectedEmotionKey;
  final EmotionalRadarV2Intensity selectedIntensity;

  String _label(String key) => emotionByKey(key)?.labelFr ?? key;

  @override
  Widget build(BuildContext context) {
    final ok = feedback.correct;
    final intensityMatches = selectedIntensity == feedback.expectedIntensity;
    return Container(
      decoration: BoxDecoration(
        color: ok
            ? EmotionalRadarPalette.successBg
            : EmotionalRadarPalette.errorBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ok
              ? EmotionalRadarPalette.successFg
              : EmotionalRadarPalette.errorFg,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: ok
                    ? EmotionalRadarPalette.successFg
                    : EmotionalRadarPalette.errorFg,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ok ? 'Bien vu' : 'Ce n\'était pas ça',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: ok
                        ? EmotionalRadarPalette.successFg
                        : EmotionalRadarPalette.errorFg,
                  ),
                ),
              ),
              Text(
                '${(feedback.responseTimeMs / 1000).toStringAsFixed(1)} s',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: EmotionalRadarPalette.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RadarFeedbackRow(
            label: 'Émotion attendue',
            value: _label(feedback.expectedEmotionKey),
            good: ok,
          ),
          if (!ok) ...[
            const SizedBox(height: 8),
            _RadarFeedbackRow(
              label: 'Ta réponse',
              value: _label(selectedEmotionKey),
              good: false,
            ),
            const SizedBox(height: 8),
            _RadarFeedbackRow(
              label: 'Écart sémantique',
              // Le serveur calcule cette distance dans l'espace valence/arousal
              // de Cowen & Keltner : proche de 0, l'erreur est fine ; proche de
              // 1, l'émotion choisie n'a rien à voir.
              value: feedback.semanticErrorDistance.toStringAsFixed(2),
              good: feedback.semanticErrorDistance < 0.25,
            ),
          ],
          const SizedBox(height: 8),
          _RadarFeedbackRow(
            label: 'Intensité attendue',
            value: feedback.expectedIntensity.label,
            good: intensityMatches,
          ),
          if (feedback.timedOut) ...[
            const SizedBox(height: 12),
            const _RadarFeedbackNote(
              icon: Icons.timer_off_outlined,
              text: 'Réponse hors délai : la scène est comptée comme manquée.',
            ),
          ],
          if (feedback.impulsive) ...[
            const SizedBox(height: 12),
            _RadarFeedbackNote(
              icon: Icons.bolt_outlined,
              text:
                  'Réponse en moins de '
                  '${EmotionalRadarV2Config.minImpulsiveTimeMs} ms : trop '
                  'rapide pour avoir analysé la scène.',
            ),
          ],
        ],
      ),
    );
  }
}

class _RadarFeedbackRow extends StatelessWidget {
  const _RadarFeedbackRow({
    required this.label,
    required this.value,
    required this.good,
  });

  final String label;
  final String value;
  final bool good;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              color: EmotionalRadarPalette.muted,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: good
                  ? EmotionalRadarPalette.successFg
                  : EmotionalRadarPalette.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _RadarFeedbackNote extends StatelessWidget {
  const _RadarFeedbackNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: EmotionalRadarPalette.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.3,
              color: EmotionalRadarPalette.muted,
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Bandeau de niveau
// ══════════════════════════════════════════════════════════════════════════

/// Niveau courant et sa lecture — nombre de choix et finesse demandée.
///
/// Les quatre niveaux du référentiel croisent deux axes indépendants : la
/// charge (6 ou 9 propositions) et la proximité sémantique des distracteurs.
/// Les afficher séparément permet au joueur de comprendre ce qui vient de
/// changer quand il monte ou descend.
class RadarLevelBanner extends StatelessWidget {
  const RadarLevelBanner({
    super.key,
    required this.level,
    required this.choicesCount,
  });

  final int level;
  final int choicesCount;

  @override
  Widget build(BuildContext context) {
    final descriptor = EmotionalRadarV2Config.level(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            'Niveau $level',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$choicesCount propositions · '
              '${_distanceLabel(descriptor.targetDistance)}',
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.white.withValues(alpha: 0.86),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Nommée du point de vue du joueur : une distance sémantique ÉLEVÉE rend la
  /// manche plus facile, ce que « distance élevée » ne dit pas du tout.
  static String _distanceLabel(DistanceBand distance) => switch (distance) {
    DistanceBand.high => 'émotions bien distinctes',
    DistanceBand.medium => 'émotions assez proches',
    DistanceBand.low => 'émotions très proches',
  };
}

/// Lecteur plein écran de la scène.
///
/// Construit comme un lecteur vidéo de téléphone : fond noir, image occupant
/// tout l'écran, et **tout le reste en surimpression**. La version précédente
/// empilait en-tête, vidéo, contrôles et légende dans un même flux : chacun
/// prenait sa part de hauteur et il ne restait à l'image qu'une vignette
/// entourée de marges.
///
/// Aucune alternative textuelle ici : le contrat v2 n'en transporte pas, et en
/// inventer une reviendrait à décrire la scène — donc à orienter la réponse.
class RadarFullscreenSceneView extends StatelessWidget {
  const RadarFullscreenSceneView({
    super.key,
    required this.scene,
    required this.sceneNumber,
    required this.totalScenes,
  });

  final EmotionalRadarV2Scene scene;
  final int sceneNumber;
  final int totalScenes;

  @override
  Widget build(BuildContext context) {
    final caption = scene.contextualCaption;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (scene.usesVideoPlaceholder)
            const Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: RadarMediaPlaceholder(),
              ),
            )
          else
            EmotionalRadarVideo(
              source: scene.mediaUrl!,
              immersive: true,
              onDarkBackground: true,
            ),

          // ── Bandeau haut : numéro de scène et fermeture ──────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: DecoratedBox(
              // Voile : sur une image claire, du texte blanc posé à nu
              // deviendrait illisible.
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x99000000), Color(0x00000000)],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 4, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Scene $sceneNumber / $totalScenes',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Quitter le plein écran',
                        child: IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(
                            Icons.fullscreen_exit_rounded,
                            color: Colors.white,
                          ),
                          tooltip: 'Quitter le plein écran',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Légende contextuelle, au-dessus des contrôles ────────────────
          if (caption != null && caption.trim().isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 78,
              child: SafeArea(
                top: false,
                child: Text(
                  caption,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 6, color: Color(0xCC000000))],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
