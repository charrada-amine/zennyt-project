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

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/audio/sound_service.dart';
import '../../domain/config/emotional_radar_v2_config.dart';
import '../../domain/config/emotional_radar_v2_referential.dart';
import '../../domain/entities/emotional_radar_v2.dart';
import '../widgets/emotional_radar_components.dart';
import '../widgets/emotional_radar_video.dart';
import '../widgets/game_system_components.dart';

/// Nombre de boutons d'émotion par ligne.
///
/// Le référentiel fixe `choices_per_level = 6 / 6 / 9 / 9` précisément pour
/// que la grille tombe juste : 2 lignes de 3, puis 3 lignes de 3. Changer
/// cette constante casserait cet alignement.
const int kRadarChoicesPerRow = 3;

// ══════════════════════════════════════════════════════════════════════════
// Scène
// ══════════════════════════════════════════════════════════════════════════

/// Le stimulus : la vidéo, et rien d'autre.
///
/// Le compte à rebours n'est plus affiché sous la vidéo : le temps restant est
/// porté par la barre du haut de l'écran ([RadarTimeBar]). Le cadre occupe
/// toute la hauteur que le plateau lui accorde, et la vidéo s'y ajuste.
class RadarSceneStage extends StatelessWidget {
  const RadarSceneStage({
    super.key,
    required this.scene,
    required this.remainingMs,
    required this.onOpenFullscreen,
    this.playbackEnabled = true,
    this.showExpiredBadge = true,
  });

  final EmotionalRadarV2Scene scene;

  /// Masqué pendant la correction : « réponds quand même » n'a plus de sens.
  final bool showExpiredBadge;

  /// Budget restant, décompté par l'écran. Le serveur reste l'autorité : ce
  /// compteur est un repère visuel, il ne décide de rien.
  final int remainingMs;

  final VoidCallback onOpenFullscreen;
  final bool playbackEnabled;

  bool get _expired => showExpiredBadge && remainingMs <= 0;

  @override
  Widget build(BuildContext context) {
    final caption = scene.contextualCaption;
    final media = scene.usesVideoPlaceholder
        ? const Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: RadarMediaPlaceholder(),
            ),
          )
        : EmotionalRadarVideo(
            source: scene.mediaUrl!,
            playbackEnabled: playbackEnabled,
            onFullscreen: onOpenFullscreen,
          );
    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.hasBoundedHeight;
        return Container(
          decoration: BoxDecoration(
            color: EmotionalRadarPalette.card,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (bounded)
                Expanded(child: _withExpiredBadge(media))
              else
                _withExpiredBadge(media),
              // Légende contextuelle : prévue par le référentiel « uniquement
              // pour les stimuli de type contextuel », affichée dans
              // l'interface et jamais incrustée dans la vidéo. Le serveur ne la
              // renseigne que dans ce cas, l'écran se contente de la relayer.
              if (caption != null && caption.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: EmotionalRadarPalette.muted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color: EmotionalRadarPalette.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Le dépassement n'annule PAS la manche : le contrat exige toujours une
  /// émotion et une intensité, et le serveur comptera la réponse fausse. On le
  /// signale en surimpression (Stack) pour ne rien retirer à la hauteur du
  /// plateau.
  Widget _withExpiredBadge(Widget media) {
    if (!_expired) return media;
    return Stack(
      children: [
        Positioned.fill(child: media),
        Positioned(
          top: 8,
          left: 8,
          right: 8,
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: EmotionalRadarPalette.errorFg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_off_outlined, size: 15, color: Colors.white),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Temps écoulé — réponds quand même',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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

/// Secondes finales pendant lesquelles la barre passe au rouge et le décompte
/// sonore retentit à chaque seconde.
const int kRadarCountdownSfxSeconds = 5;

/// Barre de progression du haut de l'écran, synchronisée sur le temps restant
/// de la scène.
///
/// Elle se vide avec le budget de réponse, et non plus avec l'avancement
/// « scène n / 15 » : ce compteur reste affiché à part, en texte.
class RadarTimeBar extends StatelessWidget {
  const RadarTimeBar({
    super.key,
    required this.remainingMs,
    required this.totalMs,
    this.trackColor = Colors.white24,
  });

  final int remainingMs;
  final int totalMs;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final ratio = totalMs <= 0
        ? 0.0
        : (remainingMs / totalMs).clamp(0.0, 1.0).toDouble();
    final seconds = (remainingMs / 1000).ceil().clamp(0, 999);
    final urgent = seconds <= kRadarCountdownSfxSeconds;
    return Semantics(
      // Un compteur qui ne se lit qu'à l'œil exclut les lecteurs d'écran : on
      // annonce la valeur, pas seulement la barre.
      label: 'Temps restant : $seconds secondes',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: ratio,
          minHeight: 6,
          backgroundColor: trackColor,
          valueColor: AlwaysStoppedAnimation(
            urgent ? const Color(0xFFFF5A5F) : EmotionalRadarPalette.magenta,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Réponse
// ══════════════════════════════════════════════════════════════════════════

/// Panneau de réponse : émotion puis intensité.
///
/// [scale] (0,8 à 1) compacte les boutons quand l'écran est court : le
/// plateau entier doit tenir sur un seul écran, sans défilement. Voir
/// [RadarAnswerPanel.scaleFor].
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
    this.scale = 1.0,
  });

  final EmotionalRadarV2Scene scene;
  final String? selectedEmotionKey;
  final EmotionalRadarV2Intensity? selectedIntensity;
  final bool validating;
  final ValueChanged<String> onSelectEmotion;
  final ValueChanged<EmotionalRadarV2Intensity> onSelectIntensity;
  final VoidCallback onValidate;
  final double scale;

  static const double _emotionHeight = 50;
  static const double _intensityHeight = 58;
  static const double _validateHeight = 50;
  static const double _gridGap = 8;

  /// Hauteur fixe du panneau hors boutons : marges, deux intitulés, espaces.
  static const double _fixedHeight = 24 + 2 * 22 + 2 * 8 + 2 * 12;

  static int _rows(int choices) => (choices / kRadarChoicesPerRow).ceil();

  /// Échelle qui fait tenir le panneau dans [budget] pixels de haut.
  static double scaleFor({required double budget, required int choices}) {
    final rows = _rows(choices);
    final flexible = rows * _emotionHeight + _intensityHeight + _validateHeight;
    final room = budget - _fixedHeight - (rows - 1) * _gridGap;
    return (room / flexible).clamp(0.8, 1.0).toDouble();
  }

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
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _RadarStepLabel(index: 1, label: 'Quelle émotion domine ?'),
          const SizedBox(height: 8),
          RadarEmotionGrid(
            choices: scene.choices,
            selectedKey: selectedEmotionKey,
            onSelect: onSelectEmotion,
            buttonHeight: _emotionHeight * scale,
          ),
          const SizedBox(height: 12),
          const _RadarStepLabel(index: 2, label: 'À quelle intensité ?'),
          const SizedBox(height: 8),
          RadarIntensitySelector(
            selected: selectedIntensity,
            onSelect: onSelectIntensity,
            height: _intensityHeight * scale,
          ),
          const SizedBox(height: 12),
          _RadarValidateButton(
            enabled: _complete && !validating,
            busy: validating,
            onPressed: onValidate,
            height: _validateHeight * scale,
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
    return SizedBox(
      height: 22,
      child: Row(
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
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: EmotionalRadarPalette.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Grille des émotions proposées — 3 par ligne, 6 ou 9 selon le niveau.
///
/// Lignes de largeur égale ([Expanded]) et de hauteur fixe : chaque libellé
/// s'adapte à SON bouton ([AutoFitText]) au lieu de déborder ou d'être coupé.
class RadarEmotionGrid extends StatelessWidget {
  const RadarEmotionGrid({
    super.key,
    required this.choices,
    required this.selectedKey,
    required this.onSelect,
    this.buttonHeight = 50,
  });

  final List<EmotionalRadarV2Choice> choices;
  final String? selectedKey;
  final ValueChanged<String> onSelect;
  final double buttonHeight;

  /// Marges internes d'un bouton : padding horizontal 6 + bordure 2 (sélection)
  /// de chaque côté, padding vertical 4 + bordure.
  static const double _insetX = 2 * (6 + 2);
  static const double _insetY = 2 * (4 + 2);

  @override
  Widget build(BuildContext context) {
    const gap = 8.0;
    final rows = <List<EmotionalRadarV2Choice>>[
      for (var i = 0; i < choices.length; i += kRadarChoicesPerRow)
        choices.sublist(i, math.min(i + kRadarChoicesPerRow, choices.length)),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        // Une seule taille de police pour toute la grille : celle à laquelle
        // le libellé le plus exigeant tient dans son bouton.
        final cellWidth =
            (constraints.maxWidth - gap * (kRadarChoicesPerRow - 1)) /
            kRadarChoicesPerRow;
        final fontSize = AutoFitText.fontSizeFor(
          context,
          texts: [for (final choice in choices) choice.labelFr],
          style: RadarEmotionButton.labelStyle,
          constraints: BoxConstraints(
            maxWidth: math.max(0, cellWidth - _insetX),
            maxHeight: math.max(0, buttonHeight - _insetY),
          ),
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              if (r > 0) const SizedBox(height: gap),
              SizedBox(
                height: buttonHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var c = 0; c < kRadarChoicesPerRow; c++) ...[
                      if (c > 0) const SizedBox(width: gap),
                      Expanded(
                        child: c < rows[r].length
                            ? RadarEmotionButton(
                                choice: rows[r][c],
                                selected: rows[r][c].key == selectedKey,
                                fontSize: fontSize,
                                onTap: () => onSelect(rows[r][c].key),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
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
    this.fontSize,
  });

  final EmotionalRadarV2Choice choice;
  final bool selected;
  final VoidCallback onTap;

  /// Taille imposée par la grille ; à défaut, le libellé s'ajuste seul.
  final double? fontSize;

  static const TextStyle labelStyle = TextStyle(
    fontSize: 14,
    height: 1.15,
    fontWeight: FontWeight.w800,
  );

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
          onTap: () {
            SoundService.instance.playSfx(GameSfx.buttonClick);
            onTap();
          },
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? EmotionalRadarPalette.selectBlue
                    : EmotionalRadarPalette.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: AutoFitText(
              choice.labelFr,
              // Mesuré en gras : la sélection ne doit pas faire déborder.
              style: labelStyle.copyWith(
                fontSize: fontSize ?? labelStyle.fontSize,
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
    this.height = 58,
  });

  final EmotionalRadarV2Intensity? selected;
  final ValueChanged<EmotionalRadarV2Intensity> onSelect;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(width: 8),
          ],
        ],
      ),
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
          onTap: () {
            SoundService.instance.playSfx(GameSfx.buttonClick);
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? EmotionalRadarPalette.selectBlue
                    : EmotionalRadarPalette.border,
                width: selected ? 2 : 1,
              ),
            ),
            // Tout le contenu rétrécit d'un bloc si le bouton est compacté.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: 6),
                  Text(
                    intensity.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13,
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
      ),
    );
  }
}

class _RadarValidateButton extends StatelessWidget {
  const _RadarValidateButton({
    required this.enabled,
    required this.busy,
    required this.onPressed,
    this.height = 50,
  });

  final bool enabled;
  final bool busy;
  final VoidCallback onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: FilledButton(
        onPressed: enabled
            ? () {
                SoundService.instance.playSfx(GameSfx.buttonClick);
                onPressed();
              }
            : null,
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
///
/// Style de la maquette Figma « Feedback » : carte teintée affichée sous la
/// vidéo, à la place des propositions, pastille ronde pleine, titre + sous-titre, puis chaque valeur dans
/// sa propre ligne blanche bordée, et un paragraphe d'explication. Seul le
/// STYLE vient de la maquette : les contenus restent ceux du jeu — la carte
/// « Dialogue » de la maquette n'est pas reprise, car un texte de situation
/// révélerait l'émotion à identifier.
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

  static const Color _successTint = Color(0xFFF2F8F4);
  static const Color _successBorder = Color(0xFFA9D5B9);
  static const Color _successBadge = Color(0xFF3F8A5E);
  static const Color _errorTint = Color(0xFFFDF4F3);
  static const Color _errorBorder = Color(0xFFEFB8B1);
  static const Color _errorBadge = Color(0xFFC0392B);
  static const Color _title = Color(0xFF1C2230);

  String _label(String key) => emotionByKey(key)?.labelFr ?? key;

  /// Paragraphe sous les lignes : ce que la réponse appelle comme remarque.
  List<String> get _notes {
    final ok = feedback.correct;
    final intensityMatches = selectedIntensity == feedback.expectedIntensity;
    final seconds = (feedback.responseTimeMs / 1000).toStringAsFixed(1);
    return [
      if (feedback.timedOut)
        'Réponse hors délai : la scène est comptée comme manquée.'
      else if (feedback.impulsive)
        'Réponse en moins de ${EmotionalRadarV2Config.minImpulsiveTimeMs} ms : '
            'trop rapide pour avoir analysé la scène.'
      else
        'Réponse en $seconds s.',
      // L'écart sémantique (distance valence/arousal calculée par le serveur)
      // se lit ici en clair plutôt qu'en chiffre.
      if (!ok)
        feedback.semanticErrorDistance < 0.25
            ? 'Les deux émotions sont proches : la nuance était fine.'
            : 'Les deux émotions sont éloignées : observe le visage, le corps et le contexte.',
      if (!intensityMatches)
        'Tu avais évalué l\'intensité « ${selectedIntensity.label} ».',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ok = feedback.correct;
    return Container(
      decoration: BoxDecoration(
        color: ok ? _successTint : _errorTint,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: ok ? _successBorder : _errorBorder,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ok ? _successBadge : _errorBadge,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  ok ? Icons.check_rounded : Icons.close_rounded,
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
                      ok ? 'Bien vu !' : 'Ce n\'était pas ça',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _title,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ok
                          ? 'Tu as identifié l\'émotion dominante.'
                          : 'L\'émotion dominante était une autre.',
                      style: const TextStyle(
                        fontSize: 14.5,
                        height: 1.3,
                        color: EmotionalRadarPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RadarFeedbackRow(
            label: 'Émotion attendue',
            value: _label(feedback.expectedEmotionKey),
          ),
          if (!ok) ...[
            const SizedBox(height: 8),
            _RadarFeedbackRow(
              label: 'Ta réponse',
              value: _label(selectedEmotionKey),
            ),
          ],
          const SizedBox(height: 8),
          _RadarFeedbackRow(
            label: 'Intensité attendue',
            value: feedback.expectedIntensity.label,
          ),
          const SizedBox(height: 14),
          Text(
            _notes.join(' '),
            style: const TextStyle(fontSize: 15, height: 1.4, color: _title),
          ),
        ],
      ),
    );
  }
}

/// Ligne blanche bordée « libellé ··· valeur » de la maquette.
class _RadarFeedbackRow extends StatelessWidget {
  const _RadarFeedbackRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EmotionalRadarPalette.border),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: EmotionalRadarPalette.muted,
            ),
          ),
          const SizedBox(width: 12),
          // La valeur prend toute la place restante et se cale à droite, comme
          // sur la maquette ; une valeur longue passe à la ligne.
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: RadarFeedbackCard._title,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lecteur plein écran de la scène.
///
/// Suit l'orientation du téléphone : le plein écran n'impose plus le paysage,
/// l'image se centre en portrait comme en paysage.
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
    this.remainingMs,
  });

  final EmotionalRadarV2Scene scene;
  final int sceneNumber;
  final int totalScenes;

  /// Temps restant de la scène, pour garder la barre du haut synchronisée
  /// pendant le plein écran (la route n'est pas reconstruite par l'écran).
  final ValueListenable<int>? remainingMs;

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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
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
                              onPressed: () {
                                SoundService.instance.playSfx(
                                  GameSfx.buttonClick,
                                );
                                Navigator.of(context).maybePop();
                              },
                              icon: const Icon(
                                Icons.fullscreen_exit_rounded,
                                color: Colors.white,
                              ),
                              tooltip: 'Quitter le plein écran',
                            ),
                          ),
                        ],
                      ),
                      if (remainingMs != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ValueListenableBuilder<int>(
                            valueListenable: remainingMs!,
                            builder: (context, remaining, _) => RadarTimeBar(
                              remainingMs: remaining,
                              totalMs: scene.maxResponseTimeMs,
                            ),
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
