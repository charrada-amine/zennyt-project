import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/audio/sound_service.dart';
import '../../../../core/theme/app_spacing.dart';
import 'game_system_components.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

/// Composants partagés par les deux jeux de décision comportementale (BART et
/// IST), d'après les planches concept « BART · Concept » et « IST · Concept ».
///
/// Tout ce qui existe déjà dans le design system jeux est réutilisé tel quel
/// ([GamePrimaryButton], [GamePauseScaffold], [ZennytGamePalette],
/// [GameContentFrame]) ; ce fichier ne porte que la mise en page propre aux deux
/// maquettes (couverture, entête d'essai, tuiles de valeur).

/// Chemins des SVG — déclarés par le dossier `assets/games/` du pubspec.
class DecisionBehavioralAssets {
  DecisionBehavioralAssets._();

  static const bartLogo = 'assets/games/bart_logo.svg';
  static const istLogo = 'assets/games/ist_logo.svg';
  static const balloonIdle = 'assets/games/bart_balloon_idle.svg';
  static const balloonInflated = 'assets/games/bart_balloon_inflated.svg';
  static const balloonCollected = 'assets/games/bart_balloon_collected.svg';
  static const balloonExploded = 'assets/games/bart_balloon_exploded.svg';
  static const pumpIdle = 'assets/games/bart_pump_idle.svg';
  static const pumpPressed = 'assets/games/bart_pump_pressed.svg';
}

/// Couleurs des planches concept qui ne figurent pas encore dans la palette.
class DecisionBehavioralColors {
  DecisionBehavioralColors._();

  /// Case IST non ouverte.
  static const closedBox = Color(0xFFA99FF5);

  /// Couleur « bleue » révélée (cyan des maquettes).
  static const revealedBlue = Color(0xFF2FD9F5);

  /// Couleur « orange » révélée.
  static const revealedOrange = ZennytGamePalette.ruleOrange;

  /// Piste des barres de progression sur fond bleu.
  static const progressTrack = Color(0xFF8A82F0);
}

/// Écran de couverture — carte bleue, puce « Decision Making », titre,
/// illustration, deux tuiles de format, consigne, bouton « Commencer ».
class DecisionGameCover extends StatelessWidget {
  const DecisionGameCover({
    super.key,
    required this.title,
    required this.subtitle,
    required this.illustrationAsset,
    required this.tiles,
    required this.instruction,
    required this.onStart,
    required this.onBack,
    this.busy = false,
    this.error,
  });

  final String title;
  final String subtitle;
  final String illustrationAsset;
  final List<DecisionCoverTile> tiles;
  final String instruction;
  final VoidCallback onStart;
  final VoidCallback onBack;
  final bool busy;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: GameContentFrame(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _SquareIconButton(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  tooltip: 'Retour',
                  onPressed: onBack,
                  outlined: true,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: ZennytGamePalette.gameBlue,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
                ),
                child: Column(
                  children: [
                    const _Pill(label: 'Decision Making'),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      height: 190,
                      child: SvgPicture.asset(
                        illustrationAsset,
                        semanticsLabel: '$title — illustration',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              Row(
                children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.md),
                    Expanded(child: tiles[i]),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                instruction,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ZennytGamePalette.ink,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: ZennytGamePalette.error),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              GamePrimaryButton(
                label: busy ? 'Préparation…' : 'Commencer',
                onPressed: busy ? null : onStart,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tuile de format de la couverture (« 30 ballons », « 2 essais pratiques »).
class DecisionCoverTile extends StatelessWidget {
  const DecisionCoverTile({
    super.key,
    required this.icon,
    required this.label,
    this.value,
  });

  final AppIconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.base,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: ZennytGamePalette.border),
      ),
      child: Column(
        children: [
          if (value != null)
            Text(
              value!,
              style: const TextStyle(
                color: ZennytGamePalette.ink,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ZennytGamePalette.muted,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppIcon(icon, color: ZennytGamePalette.gameBlue, size: 30),
        ],
      ),
    );
  }
}

/// Entête d'essai sur fond bleu : pause, « Ballon 07 / 30 », barre de progression.
class DecisionTrialHeader extends StatelessWidget {
  const DecisionTrialHeader({
    super.key,
    required this.title,
    required this.progress,
    required this.progressColor,
    required this.onPause,
  });

  final String title;
  final double progress;
  final Color progressColor;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _SquareIconButton(
              icon: HugeIcons.strokeRoundedPause,
              tooltip: 'Pause',
              onPressed: onPause,
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 52),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 12,
            color: progressColor,
            backgroundColor: DecisionBehavioralColors.progressTrack,
          ),
        ),
      ],
    );
  }
}

/// Tuile blanche « libellé + valeur » (Banque, Réserve, Gain possible…).
class DecisionValueTile extends StatelessWidget {
  const DecisionValueTile({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = ZennytGamePalette.ink,
    this.valueKey,
  });

  final String label;
  final String value;
  final Color valueColor;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: ZennytGamePalette.muted,
              fontSize: 15,
            ),
          ),
          FittedBox(
            child: Text(
              value,
              key: valueKey,
              style: TextStyle(
                color: valueColor,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pilule blanche (catégorie, condition d'essai).
class DecisionPill extends StatelessWidget {
  const DecisionPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => _Pill(label: label);
}

/// Menu pause commun : les deux tâches sont à rythme libre (aucun chronomètre),
/// la pause ne menace donc aucune mesure. Reprendre, règles, quitter.
enum DecisionPauseAction { resume, rules, exit }

Future<DecisionPauseAction?> showDecisionPause(
  BuildContext context, {
  required String rules,
}) {
  return showGamePauseMenu<DecisionPauseAction>(
    context,
    builder: (dialogCtx) => GamePauseScaffold(
      description: rules,
      actions: [
        GamePauseMenuAction.resume(
          label: 'Reprendre',
          onPressed: () =>
              Navigator.of(dialogCtx).pop(DecisionPauseAction.resume),
        ),
        GamePauseMenuAction.exit(
          label: 'Quitter la partie',
          onPressed: () =>
              Navigator.of(dialogCtx).pop(DecisionPauseAction.exit),
        ),
      ],
    ),
  );
}

/// Fond bleu plein écran des phases de jeu.
class DecisionGameplayFrame extends StatelessWidget {
  const DecisionGameplayFrame({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ZennytGamePalette.gameBlue,
      child: SafeArea(
        child: GameContentFrame(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: children,
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: ZennytGamePalette.ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.outlined = false,
  });

  final AppIconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: IconButton(
        tooltip: tooltip,
        onPressed: () {
          SoundService.instance.playSfx(GameSfx.buttonClick);
          onPressed();
        },
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: ZennytGamePalette.blue,
          side: outlined
              ? const BorderSide(color: ZennytGamePalette.border)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        icon: AppIcon(icon, size: 30),
      ),
    );
  }
}
