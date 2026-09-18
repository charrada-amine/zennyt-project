import 'package:flutter/material.dart';

import '../../../../core/audio/sound_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'game_system_components.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

/// Modèle commun — et **unique** — des écrans de score final des jeux.
///
/// Reprend à l'identique l'écran de « Je Bouge », retenu comme référence par
/// le client, et l'impose : un jeu ne décrit que ses DONNÉES, jamais la mise en
/// page. Le contrat est volontairement fermé pour que deux jeux ne puissent
/// plus diverger :
///
/// - titre « Results », sous-titre « ‹jeu› completed » (ou synchronisation) ;
/// - carte de score bleue, score **en %** animé, légende des points serveur ;
/// - **exactement trois** tuiles de synthèse ;
/// - un encart « Summary insight » ;
/// - deux actions côte à côte.
///
/// Les barres de synthèse restent dans l'encart ; le détail d'un jeu vit dans son écran
/// d'insights ou de comparaison. Seul [notice] reste, réservé aux états
/// d'exception (envoi échoué, score provisoire).
///
/// Le son du tableau de score est lancé par l'écran à l'arrivée du résultat
/// (`SoundService.playScoreboard`) ; ce modèle le coupe quand le comptage
/// atteint sa valeur.
class GameResultsTemplate extends StatelessWidget {
  const GameResultsTemplate({
    super.key,
    required this.gameName,
    required this.scoreLabel,
    required this.scorePercent,
    required this.stats,
    required this.insight,
    this.insightBars = const [],
    this.insightTitle = 'Synthèse',
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    this.points,
    this.maxPoints,
    this.pending = false,
    this.notice,
    this.onBack,
    this.titleKey,
    this.scoreKey,
    this.scoreSemanticsLabel,
    this.primaryKey,
  }) : assert(stats.length == 3, 'Un écran de score montre trois tuiles.');

  /// Nom du jeu, repris dans le sous-titre « ‹jeu› completed ».
  final String gameName;

  /// Libellé de la carte de score (« Cognitive score »…).
  final String scoreLabel;

  /// Score sur 100, affiché en %. `null` tant qu'il n'est pas connu.
  final int? scorePercent;

  /// Points bruts du barème et leur maximum, repris dans la légende.
  final int? points;
  final int? maxPoints;

  /// Vrai pendant la remontée du résultat au serveur.
  final bool pending;

  /// Les trois tuiles de synthèse.
  final List<GameResultStat> stats;

  /// Synthèse tirée des résultats ; `null` masque l'encart.
  final String? insight;

  /// Barres de la synthèse (une mesure par ligne), sous le texte.
  final List<GameResultInsightBar> insightBars;

  /// Titre de la synthèse, configurable sans changer les autres jeux.
  final String insightTitle;

  /// Mention d'exception sous l'encart (envoi échoué, score provisoire…).
  final Widget? notice;

  final String primaryLabel;

  /// `null` désactive le bouton (envoi en cours…).
  final VoidCallback? onPrimary;
  final String secondaryLabel;
  final VoidCallback? onSecondary;
  final VoidCallback? onBack;

  final Key? titleKey;
  final Key? scoreKey;
  final String? scoreSemanticsLabel;
  final Key? primaryKey;

  String get _subtitle =>
      pending ? 'Synchronisation du score…' : '$gameName terminé';

  String get _caption {
    if (pending) return 'Score en cours de calcul.';
    final raw = points;
    if (raw == null) return 'Aucun score enregistré pour cette session.';
    final max = maxPoints;
    return max == null
        ? '$raw points calculés par le serveur.'
        : '$raw / $max points calculés par le serveur.';
  }

  @override
  Widget build(BuildContext context) {
    final scoreStyle = AppTypography.displayLarge.copyWith(
      color: Colors.white,
      fontSize: 56,
      letterSpacing: 0,
    );
    final percent = pending ? null : scorePercent;
    // Tout le contenu tient sur un écran, sans défilement : sur un téléphone
    // court, l'écran se réduit d'un bloc au lieu de cacher ses boutons.
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: GameFitToScreen(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onBack != null)
              Align(
                alignment: Alignment.centerLeft,
                child: GameResultsBackButton(onPressed: onBack!),
              ),
            Text(
              'Résultats',
              key: titleKey,
              style: AppTypography.displaySmall.copyWith(
                color: ZennytGamePalette.blue,
                letterSpacing: 0,
              ),
            ),
            Text(
              _subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: ZennytGamePalette.muted,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: ZennytGamePalette.gameBlue,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: Column(
                children: [
                  Text(
                    scoreLabel,
                    textAlign: TextAlign.center,
                    style: AppTypography.titleSmall.copyWith(
                      color: Colors.white,
                      letterSpacing: 0,
                    ),
                  ),
                  Semantics(
                    label: scoreSemanticsLabel,
                    excludeSemantics: scoreSemanticsLabel != null,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: percent == null
                          ? Text('—', key: scoreKey, style: scoreStyle)
                          : AnimatedCountText(
                              value: percent,
                              suffix: '%',
                              textKey: scoreKey,
                              onCompleted: SoundService.instance.stopScoreboard,
                              style: scoreStyle,
                            ),
                    ),
                  ),
                  Text(
                    _caption,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < stats.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ResultStatTile(
                      label: stats[i].label,
                      value: stats[i].value,
                      valueColor: stats[i].color,
                    ),
                  ),
                ],
              ],
            ),
            if (insight != null || insightBars.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xxl),
              GamePanel(
                backgroundColor: ZennytGamePalette.mist,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insightTitle,
                      style: AppTypography.titleMedium.copyWith(
                        color: ZennytGamePalette.blue,
                        letterSpacing: 0,
                      ),
                    ),
                    for (final bar in insightBars) ...[
                      const SizedBox(height: AppSpacing.md),
                      GameResultInsightMeter(bar: bar),
                    ],
                    if (insight != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        insight!,
                        style: AppTypography.bodyLarge.copyWith(
                          color: ZennytGamePalette.muted,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (notice != null) ...[
              const SizedBox(height: AppSpacing.lg),
              notice!,
            ],
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(
                  child: GamePrimaryButton(
                    key: primaryKey,
                    label: primaryLabel,
                    onPressed: onPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: GameOutlineButton(
                    label: secondaryLabel,
                    onPressed: onSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Score sur 100 à partir de points bruts, arrondi une seule fois.
int? gameResultPercent(int? points, int? maxPoints) {
  if (points == null || maxPoints == null || maxPoints <= 0) return null;
  return (points * 100 / maxPoints).round().clamp(0, 100);
}

/// Une mesure de la synthèse : libellé et remplissage de 0 à 1.
class GameResultInsightBar {
  const GameResultInsightBar({
    required this.label,
    required this.fraction,
    this.color = ZennytGamePalette.success,
  });

  final String label;

  /// Part remplie, de 0 à 1.
  final double fraction;
  final Color color;
}

/// Jauge de résultat commune : compacte dans la synthèse, pleine largeur dans les insights.
class GameResultInsightMeter extends StatelessWidget {
  const GameResultInsightMeter({
    super.key,
    required this.bar,
    this.compact = true,
    this.valueLabel,
    this.icon,
  });

  final GameResultInsightBar bar;
  final bool compact;
  final String? valueLabel;
  final AppIconData? icon;

  @override
  Widget build(BuildContext context) {
    final target = bar.fraction.clamp(0.0, 1.0).toDouble();
    final progress = ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: target),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, fill, _) => LinearProgressIndicator(
          value: fill,
          minHeight: compact ? 7 : 10,
          backgroundColor: ZennytGamePalette.border,
          valueColor: AlwaysStoppedAnimation(bar.color),
        ),
      ),
    );
    final label = Text(
      bar.label,
      style: AppTypography.bodyMedium.copyWith(
        color: ZennytGamePalette.muted,
        fontWeight: compact ? FontWeight.normal : FontWeight.w700,
        letterSpacing: 0,
      ),
    );
    return Semantics(
      label: '${bar.label} : ${valueLabel ?? '${(target * 100).round()} %'}',
      excludeSemantics: true,
      child: compact
          ? Row(
              children: [
                Expanded(child: label),
                const SizedBox(width: AppSpacing.md),
                SizedBox(width: 104, child: progress),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      AppIcon(icon, size: 22, color: bar.color),
                      const SizedBox(width: 10),
                    ],
                    Expanded(child: label),
                    const SizedBox(width: 10),
                    Text(
                      valueLabel ?? '${(target * 100).round()} %',
                      style: AppTypography.titleMedium.copyWith(
                        color: ZennytGamePalette.blue,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                progress,
              ],
            ),
    );
  }
}

/// Tuile de synthèse d'un écran de résultats.
class GameResultStat {
  const GameResultStat({
    required this.label,
    required this.value,
    this.color = ZennytGamePalette.blue,
  });

  final String label;
  final String value;
  final Color color;
}

/// Bouton retour carré des écrans de résultats (celui de « Je Bouge »).
class GameResultsBackButton extends StatelessWidget {
  const GameResultsBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        tooltip: 'Retour',
        onPressed: () {
          SoundService.instance.playSfx(GameSfx.buttonClick);
          onPressed();
        },
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: ZennytGamePalette.blue,
          side: const BorderSide(color: ZennytGamePalette.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        icon: const AppIcon(HugeIcons.strokeRoundedArrowLeft01),
      ),
    );
  }
}
