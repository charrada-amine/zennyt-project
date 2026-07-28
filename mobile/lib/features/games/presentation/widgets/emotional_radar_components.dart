import 'package:flutter/material.dart';

import '../../domain/config/emotional_radar_config.dart';
import '../../domain/entities/emotional_radar.dart';

/// Composants réutilisables d'« Emotional Radar ».
///
/// Contraintes portées ici (planche « Accessibility Compliance ») :
/// cibles ≥ 48×48 px espacées de 8 px, et **le sens n'est jamais porté par la
/// couleur seule** — chaque état sélectionné combine bordure + fond + coche +
/// libellé, et expose un `Semantics` explicite.

/// Palette dédiée au jeu (dérivée des planches Figma clair + sombre).
class EmotionalRadarPalette {
  EmotionalRadarPalette._();

  static const Color canvas = Color(0xFF4F46E5); // fond de gameplay
  static const Color ink = Color(0xFF1B1B4B);
  static const Color muted = Color(0xFF6B7A99);
  static const Color card = Colors.white;
  static const Color magenta = Color(0xFFD12E7D);
  static const Color selectBlue = Color(0xFF2563EB);
  static const Color selectTint = Color(0xFFEFF4FF);
  static const Color lockedTint = Color(0xFFEEF2F9);
  static const Color border = Color(0xFFE2E8F4);
  static const Color successBg = Color(0xFFEFF9F3);
  static const Color successFg = Color(0xFF16A34A);
  static const Color errorBg = Color(0xFFFDF3F3);
  static const Color errorFg = Color(0xFFC0392B);

  /// Couleur d'accent d'une famille (décorative — le libellé porte le sens).
  static Color accentFor(BasicEmotion emotion) => switch (emotion) {
        BasicEmotion.joy => const Color(0xFFF59E0B),
        BasicEmotion.sadness => const Color(0xFF2563EB),
        BasicEmotion.anger => const Color(0xFFEF4444),
        BasicEmotion.fear => const Color(0xFFA855F7),
        BasicEmotion.disgust => const Color(0xFF22C55E),
        BasicEmotion.surprise => const Color(0xFFEC4899),
      };

  /// Pictogramme d'une famille (repris des icônes de la maquette).
  static IconData iconFor(BasicEmotion emotion) => switch (emotion) {
        BasicEmotion.joy => Icons.wb_sunny_outlined,
        BasicEmotion.sadness => Icons.water_drop_outlined,
        BasicEmotion.anger => Icons.bolt_outlined,
        BasicEmotion.fear => Icons.show_chart,
        BasicEmotion.disgust => Icons.sentiment_very_dissatisfied_outlined,
        BasicEmotion.surprise => Icons.brightness_1_outlined,
      };
}

/// Bouton d'une famille d'émotion (grille 2×3 de l'étape 1).
class EmotionButton extends StatelessWidget {
  const EmotionButton({
    super.key,
    required this.emotion,
    required this.selected,
    required this.onTap,
  });

  final BasicEmotion emotion;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = EmotionalRadarPalette.accentFor(emotion);
    return Semantics(
      button: true,
      selected: selected,
      // Libellé conforme aux exemples de la planche d'accessibilité :
      // « Sadness emotion option, selected ».
      label: '${emotion.label} emotion option',
      child: Material(
        color: selected ? EmotionalRadarPalette.selectTint : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            // ≥ 48 px de haut (cible tactile minimale).
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? EmotionalRadarPalette.selectBlue
                    : EmotionalRadarPalette.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected)
                  const _CheckDot(color: EmotionalRadarPalette.selectBlue)
                else
                  Icon(EmotionalRadarPalette.iconFor(emotion), size: 20, color: accent),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    emotion.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: EmotionalRadarPalette.ink,
                    ),
                    overflow: TextOverflow.ellipsis,
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

class _CheckDot extends StatelessWidget {
  const _CheckDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: const Icon(Icons.check, size: 14, color: Colors.white),
    );
  }
}

/// Chip d'une nuance (étape 2).
class NuanceChip extends StatelessWidget {
  const NuanceChip({
    super.key,
    required this.nuance,
    required this.selected,
    required this.onTap,
  });

  final EmotionalNuance nuance;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${nuance.label} nuance option',
      child: Material(
        color: selected ? EmotionalRadarPalette.selectTint : Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selected
                    ? EmotionalRadarPalette.selectBlue
                    : EmotionalRadarPalette.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const _CheckDot(color: EmotionalRadarPalette.selectBlue),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    nuance.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? EmotionalRadarPalette.ink
                          : EmotionalRadarPalette.muted,
                    ),
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

/// Sélecteur d'intensité 1–5 (étape 3).
class IntensitySelector extends StatelessWidget {
  const IntensitySelector({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final int? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EmotionalRadarPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  '3 Intensity',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: EmotionalRadarPalette.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  selected == null ? 'Choose one level' : 'Level $selected selected',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        selected == null ? FontWeight.w500 : FontWeight.w700,
                    color: selected == null
                        ? EmotionalRadarPalette.muted
                        : EmotionalRadarPalette.magenta,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Les cinq niveaux se partagent la largeur : « Very strong » est
              // trop long pour une largeur fixe et faisait déborder la ligne.
              for (var level = EmotionalRadarConfig.minIntensity;
                  level <= EmotionalRadarConfig.maxIntensity;
                  level++)
                Expanded(
                  child: _IntensityDot(
                    level: level,
                    label: EmotionalRadarConfig.intensityLabel(level),
                    selected: selected == level,
                    onTap: () => onSelect(level),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IntensityDot extends StatelessWidget {
  const _IntensityDot({
    required this.level,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final int level;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      // « Intensity level 3, Moderate » — exemple de la planche d'accessibilité.
      label: 'Intensity level $level, $label',
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? EmotionalRadarPalette.magenta
                      : const Color(0xFFF1F5FC),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? EmotionalRadarPalette.magenta
                        : EmotionalRadarPalette.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Text(
                  '$level',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : EmotionalRadarPalette.ink,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? EmotionalRadarPalette.magenta
                        : EmotionalRadarPalette.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Étape encore verrouillée (révélation progressive).
class LockedStepRow extends StatelessWidget {
  const LockedStepRow({
    super.key,
    required this.step,
    required this.title,
    required this.hint,
  });

  final int step;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title. $hint. Locked.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: EmotionalRadarPalette.lockedTint,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.circle, size: 6, color: EmotionalRadarPalette.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$step $title',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: EmotionalRadarPalette.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: const TextStyle(
                      fontSize: 12,
                      color: EmotionalRadarPalette.muted,
                    ),
                  ),
                ],
              ),
            ),
            // Le mot « Locked » double l'indication visuelle : jamais la couleur seule.
            const Text(
              'Locked',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: EmotionalRadarPalette.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Étape validée, repliée en résumé (« 1 Basic emotion — Sadness ✓ »).
class CompletedStepRow extends StatelessWidget {
  const CompletedStepRow({
    super.key,
    required this.step,
    required this.title,
    required this.value,
  });

  final int step;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EmotionalRadarPalette.border),
      ),
      child: Row(
        children: [
          Text(
            '$step',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: EmotionalRadarPalette.muted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: EmotionalRadarPalette.muted,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: EmotionalRadarPalette.ink,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check, size: 18, color: EmotionalRadarPalette.selectBlue),
        ],
      ),
    );
  }
}

/// Étiquette du type de média d'une scène (« Dialogue », « Text », « Image »).
class SceneTypeChip extends StatelessWidget {
  const SceneTypeChip({super.key, required this.mediaType});

  final SceneMediaType mediaType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        mediaType.label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: EmotionalRadarPalette.selectBlue,
        ),
      ),
    );
  }
}

/// Ligne clé/valeur des cartes de feedback (« Expected emotion — Sadness »).
class FeedbackDetailRow extends StatelessWidget {
  const FeedbackDetailRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: EmotionalRadarPalette.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: EmotionalRadarPalette.muted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: EmotionalRadarPalette.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Les cinq étapes du tutoriel — source unique, réutilisée par l'écran de
/// règles ET par l'aide en pause (évite deux listes qui divergeraient).
const List<String> emotionalRadarSteps = [
  'Observe the scene.',
  'Choose the basic emotion.',
  'Choose the nuance.',
  'Rate intensity.',
  'Validate your answer.',
];
