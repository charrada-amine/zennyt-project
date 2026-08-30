import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/config/emotional_radar_config.dart';
import '../../domain/entities/emotional_radar.dart';
import '../widgets/emotional_radar_components.dart';

/// Carte de la scène : type de média, énoncé, consigne.
///
/// Pour une scène IMAGE/VIDEO, l'équivalent textuel (`altText`) est affiché
/// **à côté** du média, pas seulement dans l'arbre d'accessibilité : la planche
/// « Responsive » impose « Scene media always keeps a text alternative directly
/// nearby ».
class SceneCard extends StatelessWidget {
  const SceneCard({
    super.key,
    required this.scene,
    required this.onOpenFullscreen,
  });

  final EmotionalRadarScene scene;
  final VoidCallback onOpenFullscreen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EmotionalRadarPalette.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SceneTypeChip(mediaType: scene.mediaType),
          const SizedBox(height: 14),
          if (scene.mediaType.isMedia) ...[
            _ScenePreview(scene: scene, onTap: onOpenFullscreen),
            const SizedBox(height: 12),
          ],
          Text(
            scene.promptText,
            style: const TextStyle(
              fontSize: 19,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: EmotionalRadarPalette.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            scene.instructionText,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: EmotionalRadarPalette.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenePreview extends StatelessWidget {
  const _ScenePreview({required this.scene, required this.onTap});

  final EmotionalRadarScene scene;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          image: true,
          label: scene.altText ?? 'Scene image',
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: EmotionalRadarSceneImage(
                  scene: scene,
                  fit: BoxFit.cover,
                  fallback: const _MediaPlaceholder(),
                ),
              ),
            ),
          ),
        ),
        if (scene.altText != null) ...[
          const SizedBox(height: 8),
          Text(
            'Alt text: ${scene.altText}',
            style: const TextStyle(
              fontSize: 12,
              color: EmotionalRadarPalette.muted,
            ),
          ),
        ],
      ],
    );
  }
}

/// Renders authenticated admin assets already hydrated by the Games repository.
class EmotionalRadarSceneImage extends StatelessWidget {
  const EmotionalRadarSceneImage({
    super.key,
    required this.scene,
    required this.fit,
    required this.fallback,
    this.width,
  });

  final EmotionalRadarScene scene;
  final BoxFit fit;
  final Widget fallback;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final bytes = scene.mediaBytes;
    if (bytes != null) {
      if (scene.mediaMimeType?.contains('svg') ?? false) {
        return SvgPicture.memory(bytes, fit: fit, width: width);
      }
      return Image.memory(
        bytes,
        fit: fit,
        width: width,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    final url = scene.mediaUrl;
    if (url == null || url.startsWith('/api/v1/games/assets/')) return fallback;
    return Image.network(
      url,
      fit: fit,
      width: width,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEEF2F9),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 36,
        color: EmotionalRadarPalette.muted,
      ),
    );
  }
}

/// Zone de réponse : les trois étapes en révélation progressive.
///
/// Règle de la planche « Developer handoff » :
/// - l'étape 2 n'apparaît qu'une fois l'émotion choisie ;
/// - l'étape 3 n'apparaît qu'une fois la nuance choisie ;
/// - `Validate` ne s'active que lorsque les trois sont renseignées.
class AnswerPanel extends StatelessWidget {
  const AnswerPanel({
    super.key,
    required this.sceneSet,
    required this.selectedEmotion,
    required this.selectedNuance,
    required this.selectedIntensity,
    required this.validating,
    required this.onSelectEmotion,
    required this.onSelectNuance,
    required this.onSelectIntensity,
    required this.onValidate,
  });

  final EmotionalRadarSceneSet sceneSet;
  final BasicEmotion? selectedEmotion;
  final EmotionalNuance? selectedNuance;
  final int? selectedIntensity;
  final bool validating;
  final ValueChanged<BasicEmotion> onSelectEmotion;
  final ValueChanged<EmotionalNuance> onSelectNuance;
  final ValueChanged<int> onSelectIntensity;
  final VoidCallback onValidate;

  bool get _canValidate =>
      selectedEmotion != null &&
      selectedNuance != null &&
      selectedIntensity != null;

  @override
  Widget build(BuildContext context) {
    final emotion = selectedEmotion;
    final nuance = selectedNuance;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EmotionalRadarPalette.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Étape 1 : famille d'émotion ────────────────────────────────
          if (nuance == null) ...[
            _StepHeader(
              title: '1 Basic emotion',
              hint: emotion == null
                  ? 'Select one emotion family.'
                  : '${emotion.label} selected. Choose the best nuance.',
            ),
            const SizedBox(height: 12),
            _EmotionGrid(selected: emotion, onSelect: onSelectEmotion),
          ] else
            CompletedStepRow(
              step: 1,
              title: 'Basic emotion',
              value: emotion!.label,
            ),

          // ── Étape 2 : nuance ───────────────────────────────────────────
          const SizedBox(height: 16),
          if (emotion == null)
            const LockedStepRow(
              step: 2,
              title: 'Nuance',
              hint: 'Select an emotion first.',
            )
          else if (selectedIntensity == null || nuance == null) ...[
            _StepHeader(
              title: '2 Nuance',
              hint: nuance == null
                  ? 'Refine the emotional label.'
                  : '${nuance.label} selected.',
              inline: true,
            ),
            const SizedBox(height: 12),
            _NuanceWrap(
              nuances: sceneSet.nuancesFor(emotion),
              selected: nuance,
              onSelect: onSelectNuance,
            ),
          ] else
            CompletedStepRow(step: 2, title: 'Nuance', value: nuance.label),

          // ── Étape 3 : intensité ────────────────────────────────────────
          const SizedBox(height: 16),
          if (nuance == null)
            const LockedStepRow(
              step: 3,
              title: 'Intensity',
              hint: 'Choose a nuance first.',
            )
          else ...[
            if (selectedIntensity != null)
              _StepHeader(
                title: '3 Intensity',
                hint:
                    'Level $selectedIntensity, '
                    '${EmotionalRadarConfig.intensityLabel(selectedIntensity!)}, '
                    'is selected.',
              ),
            if (selectedIntensity != null) const SizedBox(height: 12),
            IntensitySelector(
              selected: selectedIntensity,
              onSelect: onSelectIntensity,
            ),
          ],

          const SizedBox(height: 20),
          _ValidateButton(
            enabled: _canValidate && !validating,
            validating: validating,
            onPressed: onValidate,
          ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.title,
    required this.hint,
    this.inline = false,
  });

  final String title;
  final String hint;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final titleWidget = Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: EmotionalRadarPalette.ink,
      ),
    );
    final hintWidget = Text(
      hint,
      style: const TextStyle(fontSize: 14, color: EmotionalRadarPalette.muted),
    );

    if (inline) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          titleWidget,
          const SizedBox(width: 12),
          Flexible(child: hintWidget),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [titleWidget, const SizedBox(height: 4), hintWidget],
    );
  }
}

class _EmotionGrid extends StatelessWidget {
  const _EmotionGrid({required this.selected, required this.onSelect});

  final BasicEmotion? selected;
  final ValueChanged<BasicEmotion> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final itemWidth = (constraints.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final emotion in EmotionalRadarConfig.emotionGridOrder)
              SizedBox(
                width: itemWidth,
                child: EmotionButton(
                  emotion: emotion,
                  selected: selected == emotion,
                  onTap: () => onSelect(emotion),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _NuanceWrap extends StatelessWidget {
  const _NuanceWrap({
    required this.nuances,
    required this.selected,
    required this.onSelect,
  });

  final List<EmotionalNuance> nuances;
  final EmotionalNuance? selected;
  final ValueChanged<EmotionalNuance> onSelect;

  @override
  Widget build(BuildContext context) {
    if (nuances.isEmpty) {
      // Ne devrait pas arriver : les six familles ont une taxonomie. Message
      // calme plutôt qu'une impasse silencieuse si le catalogue évolue.
      return const Text(
        'No nuance is available for this emotion yet.',
        style: TextStyle(fontSize: 13, color: EmotionalRadarPalette.muted),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final itemWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final nuance in nuances)
              SizedBox(
                width: itemWidth,
                child: NuanceChip(
                  nuance: nuance,
                  selected: selected?.key == nuance.key,
                  onTap: () => onSelect(nuance),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ValidateButton extends StatelessWidget {
  const _ValidateButton({
    required this.enabled,
    required this.validating,
    required this.onPressed,
  });

  final bool enabled;
  final bool validating;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: enabled
          ? 'Validate my answer'
          : 'Validate answer, disabled until all choices are complete',
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: EmotionalRadarPalette.magenta,
            foregroundColor: Colors.white,
            // L'état désactivé garde un texte lisible et un motif de gris clair :
            // jamais du gris très peu contrasté (planche d'accessibilité).
            disabledBackgroundColor: const Color(0xFFEAEFF7),
            disabledForegroundColor: EmotionalRadarPalette.muted,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            validating ? 'Validating…' : 'Validate my answer',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

/// Carte de correction affichée après validation.
///
/// Corrections apportées aux maquettes (divergences clair/sombre) :
/// - la ligne « Best answer » affiche `famille / nuance / niveau`, comme
///   « Your answer », alors que la maquette omettait l'intensité d'un côté ;
/// - la copie de succès reprend la voix active du mode clair ;
/// - le CTA est « Next scene » partout (le mode sombre disait « Continue »).
class FeedbackCard extends StatelessWidget {
  const FeedbackCard({
    super.key,
    required this.feedback,
    required this.selectedEmotion,
    required this.selectedNuance,
    required this.selectedIntensity,
  });

  final EmotionalRadarFeedback feedback;
  final BasicEmotion selectedEmotion;
  final EmotionalNuance selectedNuance;
  final int selectedIntensity;

  @override
  Widget build(BuildContext context) {
    final correct = feedback.correct;
    final expectedTriplet =
        '${feedback.expectedEmotion.label} / ${_pretty(feedback.expectedNuance)} '
        '/ ${feedback.suggestedIntensity}';

    return Semantics(
      liveRegion: true,
      label: correct
          ? 'Correct feedback. Expected answer: $expectedTriplet.'
          : 'Incorrect answer. Best answer: $expectedTriplet.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: correct
              ? EmotionalRadarPalette.successBg
              : EmotionalRadarPalette.errorBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: correct
                ? EmotionalRadarPalette.successFg.withValues(alpha: 0.4)
                : EmotionalRadarPalette.errorFg.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: correct
                        ? EmotionalRadarPalette.successFg
                        : EmotionalRadarPalette.errorFg,
                    shape: BoxShape.circle,
                  ),
                  // Icône + titre + texte : la couleur n'est jamais le seul signal.
                  child: Icon(
                    correct ? Icons.check : Icons.priority_high,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        correct
                            ? 'Correct!'
                            : 'Good try - here is the best answer',
                        style: const TextStyle(
                          fontSize: 20,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: EmotionalRadarPalette.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        correct
                            ? 'You identified the emotional pattern accurately.'
                            : 'The best match is '
                                  '${feedback.expectedEmotion.label.toLowerCase()} with '
                                  '${_pretty(feedback.expectedNuance).toLowerCase()}.',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: EmotionalRadarPalette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (correct) ...[
              FeedbackDetailRow(
                label: 'Expected emotion',
                value: feedback.expectedEmotion.label,
              ),
              FeedbackDetailRow(
                label: 'Expected nuance',
                value: _pretty(feedback.expectedNuance),
              ),
            ] else ...[
              FeedbackDetailRow(
                label: 'Your answer',
                value:
                    '${selectedEmotion.label} / ${selectedNuance.label} '
                    '/ $selectedIntensity',
              ),
              FeedbackDetailRow(
                label: 'Best answer',
                value:
                    '${feedback.expectedEmotion.label} / '
                    '${_pretty(feedback.expectedNuance)} / '
                    '${feedback.suggestedIntensity}',
              ),
            ],
            FeedbackDetailRow(
              label: 'Suggested intensity',
              value:
                  '${feedback.suggestedIntensity} '
                  '${EmotionalRadarConfig.intensityLabel(feedback.suggestedIntensity)}',
            ),
            const SizedBox(height: 10),
            Text(
              feedback.explanation,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: EmotionalRadarPalette.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// « EMPATHIC_PAIN » → « Empathic pain ».
  static String _pretty(String nuanceKey) {
    final words = nuanceKey.toLowerCase().replaceAll('_', ' ');
    return words.isEmpty ? words : words[0].toUpperCase() + words.substring(1);
  }
}
