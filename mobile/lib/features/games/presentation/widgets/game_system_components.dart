import 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show AdaptiveSegmentedControl, AdaptiveSwitch;
import 'dart:async';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

import '../../../../core/audio/sound_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

class ZennytGamePalette {
  ZennytGamePalette._();

  static const Color blue = Color(0xFF26224D);
  static const Color magenta = Color(0xFFD12E7D);
  static const Color mist = Color(0xFFF6F8FF);
  static const Color ink = Color(0xFF071333);
  static const Color muted = Color(0xFF7C87A6);
  static const Color border = Color(0xFFE2E8F4);
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF5B5B);
  static const Color cyan = Color(0xFF00A9D6);
  static const Color ruleOrange = Color(0xFFFF9F43);
  static const Color gameBlue = Color(0xFF4E46E8);
  static const Color gamePanel = Color(0xFF675DE6);
}

/// Keeps text and controls readable on tablets while using the full phone width.
class GameContentFrame extends StatelessWidget {
  const GameContentFrame({super.key, required this.child, this.maxWidth = 760});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}

/// Accueil des jeux : logo officiel, mission, contexte et aperçu du parcours.
/// Les règles détaillées restent dans le tutoriel. Les éléments s’adaptent à la
/// hauteur ; en texte agrandi, le groupe défile ensemble.
class GameWelcomePage extends StatelessWidget {
  const GameWelcomePage({
    super.key,
    required this.title,
    required this.logoAsset,
    required this.mission,
    required this.onStart,
    this.leading,
    this.contextText,
    this.contextDetail,
    this.journey = const [],
    this.startLabel = 'Commencer',
    this.startKey,
    this.logoKey,
    this.logoScale = 1,
  }) : assert(logoScale > 0);

  final String title;
  final String logoAsset;
  final String mission;
  final VoidCallback onStart;
  final Widget? leading;
  final String? contextText;
  final String? contextDetail;
  final List<String> journey;
  final String startLabel;
  final Key? startKey;
  final Key? logoKey;
  final double logoScale;

  @override
  Widget build(BuildContext context) => GameContentFrame(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (leading != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
            child: Align(alignment: Alignment.centerLeft, child: leading),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final padding = EdgeInsets.fromLTRB(
                24,
                leading == null ? 18 : 0,
                24,
                22,
              );
              final compact = constraints.maxHeight < 560;
              final panelPadding = compact ? 12.0 : 20.0;
              final logoSize = math.min(
                (compact ? 64.0 : 168.0) * logoScale,
                math.max(
                  0.0,
                  constraints.maxWidth - padding.horizontal - panelPadding * 2,
                ),
              );
              final gap = compact ? 6.0 : 16.0;
              return SingleChildScrollView(
                padding: padding,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(
                      0,
                      constraints.maxHeight - padding.vertical,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GamePanel(
                        padding: EdgeInsets.all(panelPadding),
                        backgroundColor: ZennytGamePalette.gameBlue,
                        child: Column(
                          children: [
                            Image.asset(
                              logoAsset,
                              key: logoKey,
                              width: logoSize,
                              height: logoSize,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              semanticLabel: '$title logo',
                            ),
                            SizedBox(height: compact ? 6 : 16),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: AppTypography.displaySmall.copyWith(
                                color: Colors.white,
                                fontSize: compact ? 24 : 28,
                                height: 1.15,
                                letterSpacing: 0,
                              ),
                            ),
                            SizedBox(height: compact ? 6 : 12),
                            Text(
                              mission,
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyLarge.copyWith(
                                color: Colors.white,
                                fontSize: compact ? 14 : 16,
                                height: 1.35,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (contextText != null) ...[
                        SizedBox(height: gap),
                        Text(
                          compact || contextDetail == null
                              ? contextText!
                              : '$contextText $contextDetail',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyLarge.copyWith(
                            color: ZennytGamePalette.ink,
                            fontSize: compact ? 14 : 16,
                            height: 1.35,
                          ),
                        ),
                      ],
                      if (journey.isNotEmpty) ...[
                        SizedBox(height: gap),
                        Row(
                          key: const ValueKey('welcome-journey'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var index = 0; index < journey.length; index++)
                              Expanded(
                                child: Semantics(
                                  label:
                                      'Étape ${index + 1} : ${journey[index]}',
                                  excludeSemantics: true,
                                  child: Column(
                                    children: [
                                      Text(
                                        '${index + 1}'.padLeft(2, '0'),
                                        style: AppTypography.titleLarge
                                            .copyWith(
                                              color: ZennytGamePalette.magenta,
                                              fontSize: compact ? 18 : 22,
                                            ),
                                      ),
                                      Text(
                                        journey[index],
                                        textAlign: TextAlign.center,
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                              color: ZennytGamePalette.ink,
                                              fontSize: compact ? 12 : 14,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      SizedBox(height: gap),
                      GamePrimaryButton(
                        key: startKey,
                        label: startLabel,
                        onPressed: onStart,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

enum GameDirection {
  up(HugeIcons.strokeRoundedArrowUp02, 'haut', 'Haut'),
  right(HugeIcons.strokeRoundedArrowRight02, 'droite', 'Droite'),
  down(HugeIcons.strokeRoundedArrowDown02, 'bas', 'Bas'),
  left(HugeIcons.strokeRoundedArrowLeft02, 'gauche', 'Gauche');

  const GameDirection(this.icon, this.label, this.shortLabel);

  final AppIconData icon;

  /// Libellé français, utilisé par les annonces d'accessibilité
  /// (« Répondre droite »).
  final String label;

  /// Libellé court AFFICHÉ sous la flèche du bouton directionnel.
  final String shortLabel;
}

class GamePrimaryButton extends StatelessWidget {
  const GamePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = ZennytGamePalette.magenta,
    this.foregroundColor = Colors.white,
    this.playClickSound = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppIconData? icon;
  final Color color;

  /// Couleur du libellé. Blanc par défaut ; à fixer quand [color] est clair
  /// (bouton blanc « Collecter » du BART), sinon le libellé disparaît.
  final Color foregroundColor;

  /// Joue le clic générique de bouton. À désactiver quand l'action déclenche
  /// déjà son propre son (ex. « Add Move » du Predictive-Puzzle → son de disque).
  final bool playClickSound;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(icon, size: AppSpacing.iconMd),
              const SizedBox(width: AppSpacing.sm),
              // Le libellé doit pouvoir se rétrécir : à sa largeur naturelle,
              // icône + texte dépassaient le bouton (débordement observé de
              // 7,2 px) dès que l'intitulé s'allongeait ou que la police
              // grossissait.
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    return FilledButton(
      onPressed: onPressed == null
          ? null
          : () {
              if (playClickSound) {
                SoundService.instance.playSfx(GameSfx.buttonClick);
              }
              onPressed!();
            },
      style: FilledButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: ZennytGamePalette.border,
        foregroundColor: foregroundColor,
        disabledForegroundColor: ZennytGamePalette.muted,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        textStyle: AppTypography.buttonLarge.copyWith(letterSpacing: 0),
      ),
      child: child,
    );
  }
}

class GameOutlineButton extends StatelessWidget {
  const GameOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = ZennytGamePalette.blue,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppIconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed == null
          ? null
          : () {
              SoundService.instance.playSfx(GameSfx.buttonClick);
              onPressed!();
            },
      icon: icon == null ? const SizedBox.shrink() : AppIcon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: const BorderSide(color: ZennytGamePalette.border, width: 1.5),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        textStyle: AppTypography.buttonMedium.copyWith(letterSpacing: 0),
      ),
    );
  }
}

class GamePanel extends StatelessWidget {
  const GamePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.backgroundColor = Colors.white,
    this.borderColor = ZennytGamePalette.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class GameRuleChip extends StatelessWidget {
  const GameRuleChip({
    super.key,
    required this.label,
    required this.color,
    this.filled = false,
  });

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Règle active: $label',
      child: Container(
        height: 38,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: filled ? color : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: color, width: 2),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.titleSmall.copyWith(
            color: filled && color == Colors.white
                ? ZennytGamePalette.blue
                : filled
                ? Colors.white
                : color,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.score,
    required this.timeLabel,
    required this.progress,
    required this.onPause,
    this.progressColor = ZennytGamePalette.success,
    this.affordance = GameMenuAffordance.pause,
  });

  final int score;
  final String timeLabel;
  final double progress;
  final VoidCallback onPause;
  final Color progressColor;

  /// Ce que le bouton propose : mettre en pause, ou quitter.
  ///
  /// Le bouton ne disparaît plus une fois la fenêtre de pause consommée — il
  /// devient « Exit mission ». Voir [GameMenuAffordance] pour la raison.
  final GameMenuAffordance affordance;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _HudTile(label: 'Score', value: '$score'),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: _HudTile(label: 'Temps', value: timeLabel),
            ),
            const SizedBox(width: AppSpacing.base),
            SizedBox(
              width: 56,
              height: 52,
              child: Semantics(
                button: true,
                label: affordance.semanticsLabel,
                child: IconButton.filled(
                  tooltip: affordance.tooltip,
                  onPressed: onPause,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                  icon: AppIcon(affordance.icon),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        GameTimerBar(progress: progress, color: progressColor),
      ],
    );
  }
}

/// Bandeau de temps restant des mini-jeux — la barre du HUD de « Je bouge »,
/// sortie de [GameHud] pour que les phases chronométrées des autres jeux
/// montrent le temps de la MÊME façon. Un joueur qui passe d'un jeu à l'autre
/// n'a pas à réapprendre à lire le temps qu'il lui reste.
///
/// [progress] est la fraction de temps RESTANTE, dans [0, 1] : la barre se vide.
/// Passer la fraction écoulée la remplirait — l'inverse de ce que le joueur
/// attend d'un compte à rebours.
class GameTimerBar extends StatelessWidget {
  const GameTimerBar({
    super.key,
    required this.progress,
    this.color = ZennytGamePalette.success,
    this.label,
  });

  final double progress;
  final Color color;

  /// Texte facultatif posé au-dessus de la barre (ex. « 6s »). La barre seule
  /// donne l'ordre de grandeur, le texte donne la valeur : les deux ensemble
  /// servent aussi les joueurs qui distinguent mal les couleurs.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final safe = progress.isNaN ? 0.0 : progress.clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            textAlign: TextAlign.center,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Semantics(
          label: label == null ? 'Temps restant' : 'Temps restant, $label',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: safe,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}

class _HudTile extends StatelessWidget {
  const _HudTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              letterSpacing: 0,
            ),
          ),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bandeau de série : « Series ① ② ③ ④ — 4/4 upgrade — ×5 ».
///
/// Calé sur la maquette Figma, où pastilles, compteur et multiplicateur sont
/// nettement plus grands que dans la première implémentation : les chiffres des
/// pastilles y étaient illisibles (10 px dans un cercle de 20).
///
/// La rangée de pastilles occupe l'espace restant et se réduit d'elle-même via
/// un [FittedBox] : à pleine largeur elle rend les tailles de la maquette, et
/// sur un écran étroit elle rétrécit au lieu de déborder — c'est la seule partie
/// élastique du bandeau, le reste garde ses proportions.
class SeriesRibbon extends StatelessWidget {
  const SeriesRibbon({
    super.key,
    required this.current,
    required this.multiplier,
    required this.color,
    this.statusValue,
    this.statusCaption,
  });

  final int current;
  final int multiplier;
  final Color color;

  /// Compteur mis en avant (« 4/4 »).
  final String? statusValue;

  /// Légende sous le compteur (« upgrade », « reset »…).
  final String? statusCaption;

  /// Diamètre d'une pastille dans la maquette.
  ///
  /// Les libellés qui l'entourent sont volontairement modestes : à 390 px de
  /// large, la rangée n'a qu'une petite centaine de pixels, et chaque point de
  /// police pris par « Series » ou le multiplicateur est un point retiré aux
  /// pastilles par le [FittedBox].
  static const double _dotSize = 32;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: ZennytGamePalette.mist,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        children: [
          Text(
            'Série',
            textScaler: TextScaler.noScaling,
            style: AppTypography.bodyLarge.copyWith(
              color: ZennytGamePalette.muted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Les pastilles prennent la place restante et ne rétrécissent que si
          // l'écran l'impose — jamais de débordement, jamais de troncature.
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 1; i <= 4; i++) ...[
                    if (i > 1) const SizedBox(width: AppSpacing.sm),
                    _SeriesDot(index: i, active: i <= current, color: color),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (statusValue != null)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Le compteur est l'information, la légende la commente : la
                // maquette les empile et hiérarchise nettement leurs tailles.
                Text(
                  statusValue!,
                  maxLines: 1,
                  textScaler: TextScaler.noScaling,
                  style: AppTypography.titleMedium.copyWith(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                    height: 1.1,
                  ),
                ),
                if (statusCaption != null)
                  Text(
                    statusCaption!,
                    maxLines: 1,
                    textScaler: TextScaler.noScaling,
                    style: AppTypography.labelSmall.copyWith(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                      height: 1.2,
                    ),
                  ),
              ],
            ),
          const SizedBox(width: AppSpacing.sm),
          _AnimatedMultiplier(
            multiplier: multiplier,
            style: AppTypography.headlineLarge.copyWith(
              color: ZennytGamePalette.blue,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Multiplicateur qui double de taille (×2) instantanément quand sa valeur
/// change, puis redescend à l'échelle 1 sur ~500 ms (fiche « Je bouge »).
///
/// Le pic est volontairement franc : c'est la seule récompense visuelle d'une
/// série de 4 réussies, et à ×1.25 elle passait inaperçue.
class _AnimatedMultiplier extends StatefulWidget {
  const _AnimatedMultiplier({required this.multiplier, required this.style});

  final int multiplier;
  final TextStyle style;

  @override
  State<_AnimatedMultiplier> createState() => _AnimatedMultiplierState();
}

class _AnimatedMultiplierState extends State<_AnimatedMultiplier>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
    value: 1,
  );

  @override
  void didUpdateWidget(_AnimatedMultiplier oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.multiplier != widget.multiplier) {
      // Agrandissement instantané puis retour animé vers l'échelle 1.
      _controller
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // 1 → 2 au déclenchement, retour à 1 en fin d'animation.
        final scale =
            1 + 1.0 * (1 - Curves.easeOut.transform(_controller.value));
        return Transform.scale(scale: scale, child: child);
      },
      child: Text('x${widget.multiplier}', style: widget.style),
    );
  }
}

class _SeriesDot extends StatelessWidget {
  const _SeriesDot({
    required this.index,
    required this.active,
    required this.color,
  });

  final int index;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: SeriesRibbon._dotSize,
      height: SeriesRibbon._dotSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? color : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? color : ZennytGamePalette.border,
          width: 1.5,
        ),
      ),
      child: Text(
        '$index',
        // Le chiffre ne suit pas le textScale système : la pastille est un
        // cercle de taille fixe, un texte agrandi en déborderait. Sa lisibilité
        // vient de sa taille de base, portée de 10 à 18 px d'après la maquette.
        textScaler: TextScaler.noScaling,
        style: AppTypography.titleMedium.copyWith(
          color: active ? Colors.white : ZennytGamePalette.muted,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          height: 1,
        ),
      ),
    );
  }
}

class GameDirectionControls extends StatelessWidget {
  const GameDirectionControls({
    super.key,
    required this.onDirection,
    this.enabled = true,
    this.correctDirection,
    this.wrongDirection,
    this.compact = false,
  });

  final ValueChanged<GameDirection> onDirection;
  final bool enabled;
  final GameDirection? correctDirection;
  final GameDirection? wrongDirection;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final buttonSize = compact ? 64.0 : 72.0;
    final gap = compact ? 14.0 : 18.0;
    // Croix compacte (D-pad) centrée comme la maquette Figma : les boutons
    // gauche/droite restent proches du centre au lieu d'être collés aux bords.
    final crossExtent = buttonSize * 3 + gap * 2;
    return Center(
      child: SizedBox(
        width: crossExtent,
        height: crossExtent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: _DirectionButton(
                direction: GameDirection.up,
                size: buttonSize,
                enabled: enabled,
                state: _buttonState(GameDirection.up),
                onTap: onDirection,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: _DirectionButton(
                direction: GameDirection.left,
                size: buttonSize,
                enabled: enabled,
                state: _buttonState(GameDirection.left),
                onTap: onDirection,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _DirectionButton(
                direction: GameDirection.right,
                size: buttonSize,
                enabled: enabled,
                state: _buttonState(GameDirection.right),
                onTap: onDirection,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _DirectionButton(
                direction: GameDirection.down,
                size: buttonSize,
                enabled: enabled,
                state: _buttonState(GameDirection.down),
                onTap: onDirection,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _DirectionButtonState _buttonState(GameDirection direction) {
    if (direction == correctDirection) return _DirectionButtonState.correct;
    if (direction == wrongDirection) return _DirectionButtonState.wrong;
    return _DirectionButtonState.neutral;
  }
}

enum _DirectionButtonState { neutral, correct, wrong }

class _DirectionButton extends StatelessWidget {
  const _DirectionButton({
    required this.direction,
    required this.size,
    required this.enabled,
    required this.state,
    required this.onTap,
  });

  final GameDirection direction;
  final double size;
  final bool enabled;
  final _DirectionButtonState state;
  final ValueChanged<GameDirection> onTap;

  @override
  Widget build(BuildContext context) {
    final bg = switch (state) {
      _DirectionButtonState.correct => ZennytGamePalette.success,
      _DirectionButtonState.wrong => ZennytGamePalette.error.withValues(
        alpha: 0.12,
      ),
      _DirectionButtonState.neutral => Colors.white,
    };
    final border = switch (state) {
      _DirectionButtonState.correct => ZennytGamePalette.success,
      _DirectionButtonState.wrong => ZennytGamePalette.error,
      _DirectionButtonState.neutral => ZennytGamePalette.border,
    };
    final iconColor = switch (state) {
      _DirectionButtonState.correct => Colors.white,
      _DirectionButtonState.wrong => ZennytGamePalette.error,
      _DirectionButtonState.neutral => ZennytGamePalette.blue,
    };

    return Semantics(
      button: true,
      label: 'Répondre ${direction.label}',
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: enabled ? () => onTap(direction) : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: border, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // La flèche rétrécit (34 → 26) pour dégager la place du
                // libellé sans agrandir le bouton : la croix directionnelle
                // garde exactement l'encombrement de la maquette.
                AppIcon(direction.icon, size: size * 0.36, color: iconColor),
                const SizedBox(height: 2),
                // Libellé demandé sous chaque bouton, volontairement petit :
                // il nomme l'action sans concurrencer la flèche.
                Text(
                  direction.shortLabel,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  textAlign: TextAlign.center,
                  // Le libellé ne suit pas le textScale système : à 200 % il
                  // ferait éclater la croix, alors que la flèche porte déjà
                  // l'information — l'annonce Semantics reste, elle, complète.
                  textScaler: TextScaler.noScaling,
                  style: AppTypography.labelSmall.copyWith(
                    color: iconColor,
                    fontSize: 10,
                    height: 1,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
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

class MoveFastPlane extends StatelessWidget {
  const MoveFastPlane({
    super.key,
    required this.noseDirection,
    required this.color,
    this.size = 120,
    this.opacity = 1,
    this.turnFrom,
    this.heading,
    this.roll = 0,
  });

  final GameDirection noseDirection;
  final Color color;
  final double size;
  final double opacity;

  /// Direction que l'avion regardait à l'essai précédent.
  ///
  /// Purement DESCRIPTIF : l'avion n'anime plus rien tout seul. Ce champ dit
  /// « celui-ci est en train de manœuvrer, il vient de là » — ce dont les
  /// tests, et un futur libellé d'accessibilité, ont besoin. La figure
  /// elle-même est conduite par le plateau, qui seul survit d'un essai à
  /// l'autre et peut donc l'enchaîner sans couture.
  final GameDirection? turnFrom;

  /// Cap affiché, en radians. Nul : l'angle nominal de [noseDirection].
  final double? heading;

  /// Roulis affiché, en radians. Zéro : l'avion est à plat.
  final double roll;

  /// Durée du tonneau, une fois qu'il démarre.
  ///
  /// Une révolution complète expédiée en 400 ms se lit comme un scintillement,
  /// pas comme une figure. 900 ms laisse voir l'élan, le tour et la sortie —
  /// c'est le raffinement demandé, et ça reste sous la moitié de la fenêtre de
  /// réponse.
  static const Duration turnDuration = Duration(milliseconds: 900);

  /// Décalage d'une voie à la suivante dans la vague.
  ///
  /// Assez pour que l'œil suive la vague le long de la formation, assez peu
  /// pour que les avions n'affichent pas des caps contradictoires trop
  /// longtemps — ils convergent tous vers la même direction, donc un joueur
  /// pressé ne peut pas se tromper à cause du décalage, il attend juste un peu.
  static const Duration laneStagger = Duration(milliseconds: 55);

  /// Fin du contre-roulis d'élan, en part de figure.
  ///
  /// L'avion s'incline d'abord À L'ENVERS du tour qu'il va faire, comme un
  /// gymnaste qui se ramasse avant de sauter. C'est le principe d'anticipation :
  /// sans lui, la rotation démarre de nulle part et paraît subie.
  static const double _windUpEnd = 0.14;

  /// Amplitude de ce contre-roulis, en radians (≈ 11°).
  static const double _windUp = 0.2;

  /// Fenêtre pendant laquelle le CAP change, en part de figure.
  ///
  /// Le cap démarre APRÈS le roulis et se pose AVANT lui : l'avion s'incline,
  /// donc il vire, puis il achève son tour sur son nouveau cap. Cet ordre est
  /// ce qui fait lire une cause plutôt qu'un mouvement rigide — et il rend la
  /// réponse lisible avant la fin de la figure.
  static const double _headingStart = 0.12;
  static const double _headingEnd = 0.75;

  /// Part d'envergure toujours visible, même à la tranche (0 = l'avion se
  /// réduit à un trait).
  ///
  /// À mi-roulis, une rotation rigide met l'avion parfaitement de profil : il
  /// s'efface. C'est précisément ce que le client avait signalé sur l'ancienne
  /// bascule 3D — « une disparition très très rapide ». On triche donc de
  /// quelques degrés autour du couteau : la silhouette reste lisible, la
  /// figure garde son relief, et personne ne compte les degrés.
  static const double minWingspan = 0.32;

  /// Profondeur de la perspective appliquée à la figure.
  ///
  /// C'est elle qui fait la 3D : sans elle, tourner autour du fuselage ne
  /// serait qu'un écrasement vertical. Avec, l'aile qui vient vers l'œil
  /// grossit pendant que l'autre s'éloigne — le tour se voit comme un tour.
  static const double _perspective = 0.004;

  @override
  Widget build(BuildContext context) {
    final plane = CustomPaint(
      size: Size.square(size),
      painter: _PlanePainter(color),
    );
    final angle = heading ?? _angleFor(noseDirection);

    // À plat, une rotation plane suffit — et évite la matrice à perspective sur
    // tous les écrans fixes (intro, règles, indices).
    if (roll == 0) {
      return Opacity(
        opacity: opacity,
        child: Transform.rotate(angle: angle, child: plane),
      );
    }

    return Opacity(
      opacity: opacity,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, _perspective)
          ..rotateZ(angle)
          // Le roulis s'applique APRÈS le cap dans l'écriture, donc AVANT lui
          // sur le dessin (`Matrix4` post-multiplie) : il tourne bien autour de
          // l'axe longitudinal de l'avion, quel que soit son cap.
          ..multiply(_rollMatrix(roll)),
        child: plane,
      ),
    );
  }

  /// Rotation autour du fuselage, à l'envergure bornée.
  ///
  /// C'est un `rotateX` — dans le dessin, X est le fuselage et Y l'envergure,
  /// donc tourner autour de X est bien un roulis et non un tangage — à ceci
  /// près que l'écrasement de l'envergure ne descend jamais sous
  /// [minWingspan]. La profondeur, elle, reste celle de la vraie rotation :
  /// c'est elle qui, avec la perspective, donne son relief à la figure.
  static Matrix4 _rollMatrix(double roll) {
    final cos = math.cos(roll);
    final wingspan =
        (cos.isNegative ? -1.0 : 1.0) * math.max(cos.abs(), minWingspan);
    return Matrix4.identity()
      ..setEntry(1, 1, wingspan)
      ..setEntry(2, 1, math.sin(roll));
  }

  /// Où en est la FIGURE quand l'horloge de l'avion en est à [raw], sachant
  /// qu'il attend [delay] avant de commencer.
  ///
  /// Vaut 0 pendant toute l'attente, puis court de 0 à 1 sur [turnDuration].
  static double figureProgress(double raw, Duration delay) {
    final total = (delay + turnDuration).inMicroseconds;
    final elapsed = raw * total - delay.inMicroseconds;
    return (elapsed / turnDuration.inMicroseconds).clamp(0.0, 1.0);
  }

  /// Retard de la voie [slot] dans la vague.
  static Duration staggerFor(int slot) => laneStagger * slot;

  /// Temps au bout duquel une formation de [lanes] avions est ENTIÈREMENT
  /// posée : le dernier de la vague a fini sa figure.
  ///
  /// C'est de ce moment-là que part la fenêtre de réponse. Le client demande
  /// « toujours 2 000 ms pour répondre » : si le chronomètre partait avec la
  /// figure, l'acrobatie mangerait plus de la moitié du temps accordé — et,
  /// pire pour la mesure, chaque temps de réaction serait gonflé de la durée de
  /// l'animation, ce qui les rendrait incomparables aux normes du barème.
  /// Élan d'entrée du tout premier plateau d'une partie.
  ///
  /// C'est l'attente qui précède la fenêtre de réponse quand il n'y a AUCUNE
  /// acrobatie à jouer : au premier avion, il n'existe pas de direction
  /// précédente à quitter.
  static const Duration entryDuration = Duration(milliseconds: 620);

  static Duration formationSettle(int lanes, {bool manoeuvring = true}) =>
      manoeuvring ? staggerFor(lanes - 1) + turnDuration : entryDuration;

  /// Part du virage déjà parcourue par le CAP à l'instant [f] de la figure.
  ///
  /// Nulle tant que l'avion n'a fait que s'incliner, pleine avant la fin du
  /// tonneau : la direction — la réponse — se pose avant que la figure ne
  /// s'achève, et l'avion termine son tour sur son nouveau cap.
  static double headingProgress(double f) {
    if (f <= _headingStart) return 0;
    if (f >= _headingEnd) return 1;
    return Curves.easeInOutCubic.transform(
      (f - _headingStart) / (_headingEnd - _headingStart),
    );
  }

  /// Part du trajet d'ARRIVÉE (ou de départ) parcourue à l'instant [f].
  ///
  /// Distincte de [headingProgress], et c'est tout l'objet de cette fonction.
  /// Le cap est plat avant `_headingStart` et après `_headingEnd` : brancher
  /// l'entrée d'un avion dessus lui laissait 567 ms des 900 de la figure pour
  /// couvrir plus d'une longueur de plateau — près de 1 500 px/s en moyenne et
  /// 2 200 au pic de la cubique. L'avion ne « rejoignait » pas la formation, il
  /// y apparaissait d'un coup.
  ///
  /// Ce trajet-là n'a aucune raison d'être calé sur le cap : il ne porte pas la
  /// réponse, il porte l'arrivée. Il occupe donc la figure ENTIÈRE, et décélère
  /// à la fin plutôt qu'au milieu — un avion qui se range dans une formation
  /// ralentit en s'y insérant, il ne freine pas à mi-chemin.
  ///
  /// Sinus et non cubique : les deux décélèrent, mais la cubique se jette dans
  /// le cadre. Sur un plateau de 700 px, elle y entre à 5 500 px/s — plus vite
  /// que le défaut qu'on corrige. Le sinus entre à 2 700 et finit à zéro, ce qui
  /// donne l'entrée la plus longue des deux À VITESSE TENUE. Une rampe linéaire
  /// serait plus douce encore, mais elle s'arrête net à l'arrivée : l'avion se
  /// poserait dans la formation comme une image qu'on repose.
  static double joinProgress(double f) =>
      Curves.easeOutSine.transform(f.clamp(0.0, 1.0));

  /// Échelle d'un avion selon la part d'arrivée déjà faite.
  ///
  /// Il ne se contente pas de glisser jusqu'à sa place : il GROSSIT en
  /// s'approchant, et rétrécit en s'éloignant. Sans cela, un avion qui rejoint
  /// la formation traverse le plateau à sa taille définitive, ce qui le fait
  /// lire comme un objet posé sur l'image plutôt que comme un avion qui arrive.
  ///
  /// Vaut exactement 1 à [presence] = 1 : un avion qui reste dans la formation
  /// n'est pas touché.
  static double approachScale(double presence) =>
      _minApproachScale + (1 - _minApproachScale) * presence.clamp(0.0, 1.0);

  /// Taille d'un avion au plus loin de son approche, en part de sa taille de
  /// croisière.
  static const double _minApproachScale = 0.62;

  /// Élan de la figure à l'instant [f] : 0 aux deux bouts, 1 au sommet.
  ///
  /// Le plateau s'en sert pour pousser l'avion dans son axe de vol et le
  /// grossir un peu au passage. Un avion qui enroule un tonneau accélère ; sans
  /// cette poussée, la rotation a l'air posée sur un objet immobile.
  static double surgeAt(double f) => math.sin(math.pi * f.clamp(0.0, 1.0));

  /// Roulis de la figure à l'instant [f] (0 → 1) d'un virage de [travel]
  /// radians.
  ///
  /// **Un tonneau complet, à chaque changement de direction** — quart de tour
  /// comme demi-tour : l'avion fait une révolution entière autour de son
  /// fuselage pendant que son cap va de l'ancienne direction à la nouvelle.
  ///
  /// En deux temps :
  ///
  /// 1. **l'élan** — l'avion s'incline d'abord À L'ENVERS, de [_windUp]
  ///    radians. C'est l'anticipation du dessin animé : le geste se ramasse
  ///    avant de partir, et le départ cesse d'avoir l'air subi ;
  /// 2. **le tour** — il repart de là et enroule ses 2π, vite d'abord puisqu'il
  ///    a déjà de l'élan, puis en décélérant jusqu'à se poser à plat.
  ///
  /// Le roulis revient à 0 modulo 2π en fin de course : au moment où le joueur
  /// doit répondre, l'avion est de nouveau à plat et son envergure pleinement
  /// lisible. C'est la règle qui rend la figure gratuite — elle se joue sur le
  /// roulis, jamais sur le cap, qui porte la réponse.
  /// Roulis à l'instant [f] d'une figure qui part du roulis [from] et enroule
  /// un tour complet dans le sens [way].
  ///
  /// Le départ est un PARAMÈTRE, et c'est tout l'enjeu : une figure peut être
  /// interrompue par une réponse rapide, et la suivante doit reprendre l'avion
  /// là où il est — sur la tranche, sur le dos — au lieu de le remettre à plat
  /// d'un coup. C'est ce saut-là que le client voyait comme « une apparition
  /// très rapide » sur certaines transitions et pas sur d'autres : il ne se
  /// produisait que lorsqu'il répondait assez vite pour couper la figure.
  static double rollFigure({
    required double from,
    required double way,
    required double f,
  }) => from + _rollAt(f, travel: way);

  static double _rollAt(double f, {required double travel}) {
    // On tourne DANS le sens du virage : le roulis suit le cap.
    final way = travel.isNegative ? -1.0 : 1.0;
    if (f <= _windUpEnd) {
      return -way * _windUp * Curves.easeOutSine.transform(f / _windUpEnd);
    }
    // `easeOutSine` et pas `easeOutCubic` : le cube expédiait 80 % du tour dans
    // la première moitié de la figure, et la seconde moitié n'était plus qu'un
    // traînage. Le sinus part avec l'élan déjà acquis, tient un régime franc au
    // milieu, et ne décélère que pour se poser — c'est l'allure d'un vrai
    // tonneau.
    final released = Curves.easeOutSine.transform(
      (f - _windUpEnd) / (1 - _windUpEnd),
    );
    return -way * _windUp + way * (2 * math.pi + _windUp) * released;
  }

  /// Roulis affiché à l'instant [t] pour un virage de [from] vers [to].
  @visibleForTesting
  static double rollAt({
    required double t,
    required GameDirection from,
    required GameDirection to,
  }) => _rollAt(
    t,
    travel: _shortestTurn(from: from, to: to) - _angleFor(from),
  );

  static double _angleFor(GameDirection direction) {
    return switch (direction) {
      GameDirection.up => -math.pi / 2,
      GameDirection.right => 0,
      GameDirection.down => math.pi / 2,
      GameDirection.left => math.pi,
    };
  }

  /// Angle du nez, en radians, pour une direction donnée.
  static double angleFor(GameDirection direction) => _angleFor(direction);

  /// Angle d'arrivée équivalent à [to], mais atteint par le plus court chemin
  /// depuis [from].
  ///
  /// Les quatre angles sont fixes (−π/2 … π) : les interpoler tels quels ferait
  /// parcourir trois quarts de tour à un avion qui passe de « gauche » (π) à
  /// « haut » (−π/2), alors que le virage réel est d'un quart de tour dans
  /// l'autre sens. On ramène donc l'écart dans [−π, π].
  @visibleForTesting
  static double shortestTurn({
    required GameDirection from,
    required GameDirection to,
  }) => _shortestTurn(from: from, to: to);

  /// Angle d'arrivée équivalent à [to], atteint par le plus court chemin depuis
  /// l'angle **courant** [fromAngle] — lequel n'est pas forcément l'un des
  /// quatre caps : une figure interrompue laisse l'avion entre deux.
  static double shortestTurnFrom({
    required double fromAngle,
    required GameDirection to,
  }) {
    var delta = _angleFor(to) - fromAngle;
    while (delta > math.pi) {
      delta -= 2 * math.pi;
    }
    while (delta < -math.pi) {
      delta += 2 * math.pi;
    }
    return fromAngle + delta;
  }

  static double _shortestTurn({
    required GameDirection from,
    required GameDirection to,
  }) {
    final start = _angleFor(from);
    var delta = _angleFor(to) - start;
    while (delta > math.pi) {
      delta -= 2 * math.pi;
    }
    while (delta < -math.pi) {
      delta += 2 * math.pi;
    }
    return start + delta;
  }
}

class _PlanePainter extends CustomPainter {
  const _PlanePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final silhouette = Path()
      ..moveTo(w * 0.03, h * 0.39)
      ..quadraticBezierTo(w * 0.04, h * 0.35, w * 0.08, h * 0.37)
      ..lineTo(w * 0.17, h * 0.45)
      ..lineTo(w * 0.32, h * 0.45)
      ..lineTo(w * 0.20, h * 0.21)
      ..quadraticBezierTo(w * 0.18, h * 0.16, w * 0.24, h * 0.18)
      ..lineTo(w * 0.64, h * 0.40)
      ..lineTo(w * 0.79, h * 0.42)
      ..lineTo(w * 0.97, h * 0.49)
      ..quadraticBezierTo(w, h * 0.50, w * 0.97, h * 0.51)
      ..lineTo(w * 0.79, h * 0.58)
      ..lineTo(w * 0.64, h * 0.60)
      ..lineTo(w * 0.24, h * 0.82)
      ..quadraticBezierTo(w * 0.18, h * 0.84, w * 0.20, h * 0.79)
      ..lineTo(w * 0.32, h * 0.55)
      ..lineTo(w * 0.17, h * 0.55)
      ..lineTo(w * 0.08, h * 0.63)
      ..quadraticBezierTo(w * 0.04, h * 0.65, w * 0.03, h * 0.61)
      ..lineTo(w * 0.08, h * 0.50)
      ..close();
    final upperWingPanel = Path()
      ..moveTo(w * 0.29, h * 0.26)
      ..lineTo(w * 0.61, h * 0.42)
      ..lineTo(w * 0.76, h * 0.45)
      ..lineTo(w * 0.38, h * 0.43)
      ..close();
    final lowerWingPanel = Path()
      ..moveTo(w * 0.38, h * 0.57)
      ..lineTo(w * 0.76, h * 0.55)
      ..lineTo(w * 0.61, h * 0.58)
      ..lineTo(w * 0.29, h * 0.74)
      ..close();
    final upperTailPanel = Path()
      ..moveTo(w * 0.07, h * 0.40)
      ..lineTo(w * 0.18, h * 0.47)
      ..lineTo(w * 0.29, h * 0.47)
      ..lineTo(w * 0.12, h * 0.39)
      ..close();
    final lowerTailPanel = Path()
      ..moveTo(w * 0.12, h * 0.61)
      ..lineTo(w * 0.29, h * 0.53)
      ..lineTo(w * 0.18, h * 0.53)
      ..lineTo(w * 0.07, h * 0.60)
      ..close();

    final shadow = Paint()
      ..color = const Color(0xFF574BFF).withValues(alpha: 0.28)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.018);
    final outline = Paint()
      ..color = const Color(0xFF4C46FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final white = Paint()..color = const Color(0xFFFDFDFF);
    final panel = Paint()..color = const Color(0xFFD9D9EF);
    final accent = Paint()..color = color;
    final underBody = Paint()..color = const Color(0xFFD8D9E4);
    final cockpit = Paint()..color = const Color(0xFF343052);

    canvas.save();
    canvas.translate(-w * 0.012, h * 0.035);
    canvas.drawPath(silhouette, shadow);
    canvas.restore();

    canvas.drawPath(silhouette, white);
    canvas.drawPath(silhouette, outline);
    canvas.drawPath(upperTailPanel, panel);
    canvas.drawPath(lowerTailPanel, panel);
    canvas.drawPath(upperWingPanel, accent);
    canvas.drawPath(lowerWingPanel, accent);

    final fuselage = Path()
      ..moveTo(w * 0.08, h * 0.43)
      ..lineTo(w * 0.74, h * 0.43)
      ..quadraticBezierTo(w * 0.86, h * 0.43, w * 0.97, h * 0.50)
      ..quadraticBezierTo(w * 0.86, h * 0.57, w * 0.74, h * 0.57)
      ..lineTo(w * 0.08, h * 0.57)
      ..lineTo(w * 0.14, h * 0.50)
      ..close();
    canvas.drawPath(fuselage, white);
    final lowerFuselage = Path()
      ..moveTo(w * 0.11, h * 0.51)
      ..lineTo(w * 0.77, h * 0.51)
      ..quadraticBezierTo(w * 0.86, h * 0.51, w * 0.92, h * 0.50)
      ..quadraticBezierTo(w * 0.84, h * 0.56, w * 0.74, h * 0.56)
      ..lineTo(w * 0.08, h * 0.56)
      ..close();
    canvas.drawPath(lowerFuselage, underBody);

    final centerStripe = Path()
      ..moveTo(w * 0.15, h * 0.485)
      ..lineTo(w * 0.80, h * 0.485)
      ..quadraticBezierTo(w * 0.88, h * 0.485, w * 0.94, h * 0.50)
      ..quadraticBezierTo(w * 0.88, h * 0.515, w * 0.80, h * 0.515)
      ..lineTo(w * 0.15, h * 0.515)
      ..close();
    canvas.drawPath(centerStripe, accent);

    final canopyPath = Path()
      ..moveTo(w * 0.69, h * 0.43)
      ..lineTo(w * 0.82, h * 0.43)
      ..quadraticBezierTo(w * 0.87, h * 0.44, w * 0.89, h * 0.47)
      ..lineTo(w * 0.68, h * 0.47)
      ..close();
    canvas.drawPath(canopyPath, cockpit);
  }

  @override
  bool shouldRepaint(covariant _PlanePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class ResultStatTile extends StatelessWidget {
  const ResultStatTile({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = ZennytGamePalette.blue,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelMedium.copyWith(
              color: ZennytGamePalette.muted,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // La VALEUR ne doit jamais être tronquée : c'est l'information de la
          // tuile. Trois tuiles côte à côte n'accordent qu'une centaine de
          // pixels chacune, et les valeurs longues (« 2 missions »,
          // « Flexibility », « 8-10 min ») s'y affichaient « 2 missi… ».
          // `scaleDown` rétrécit le texte juste assez pour tenir, et ne fait
          // rien quand la place suffit — donc aucun rendu existant ne change.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: _AnimatedStatValue(
              value: value,
              style: AppTypography.titleLarge.copyWith(
                color: valueColor,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Valeur d'une tuile de résultat : si le texte contient **exactement un**
/// nombre (ex. `97%`, `+2`, `0.42s`, `3 series`), il s'anime de 0 → valeur en
/// préservant le préfixe/suffixe et le nombre de décimales. Sinon (`Flexibility`,
/// `8-10 min`, `Mobile`…), le texte est affiché tel quel.
class _AnimatedStatValue extends StatelessWidget {
  const _AnimatedStatValue({required this.value, required this.style});

  final String value;
  final TextStyle style;

  static final RegExp _single = RegExp(r'^(\D*?)(-?\d+(?:\.\d+)?)(\D*)$');

  @override
  Widget build(BuildContext context) {
    final match = _single.firstMatch(value);
    final text = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
    if (match == null) return text;

    final prefix = match.group(1)!;
    final numberStr = match.group(2)!;
    final suffix = match.group(3)!;
    final target = double.parse(numberStr);
    final dotIndex = numberStr.indexOf('.');
    final decimals = dotIndex < 0 ? 0 : numberStr.length - dotIndex - 1;

    return TweenAnimationBuilder<double>(
      key: ValueKey<String>(value),
      tween: Tween<double>(begin: 0, end: target),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) => Text(
        '$prefix${animated.toStringAsFixed(decimals)}$suffix',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}

/// Nombre qui s'anime de 0 jusqu'à [value] au montage (écrans de score des jeux).
///
/// Rejoue l'animation si [value] change. [prefix]/[suffix] encadrent le nombre
/// (ex. `%`). [style] et [textAlign] sont transmis au [Text] final.
class AnimatedCountText extends StatelessWidget {
  const AnimatedCountText({
    super.key,
    required this.value,
    required this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 900),
    this.textAlign,
    this.onCompleted,
    this.textKey,
  });

  final int value;

  /// Clé posée sur le [Text] affiché — la clé du widget, elle, ne désigne que
  /// l'animation : un test qui lit la valeur finale a besoin de celle-ci.
  final Key? textKey;
  final TextStyle style;
  final String prefix;
  final String suffix;
  final Duration duration;
  final TextAlign? textAlign;

  /// Appelé une fois quand le comptage 0 → [value] atteint sa valeur finale.
  /// Utilisé pour couper le son du tableau de score en fin d'animation.
  final VoidCallback? onCompleted;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      // La clé force un redémarrage à 0 quand la cible change.
      key: ValueKey<int>(value),
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      onEnd: onCompleted,
      builder: (context, animated, _) => Text(
        '$prefix${animated.round()}$suffix',
        key: textKey,
        style: style,
        textAlign: textAlign,
      ),
    );
  }
}

/// Action renvoyée par le menu pause partagé ([GamePauseScaffold]).
enum GamePauseAction { resume, help, exit, restart }

/// Fenêtre pendant laquelle le menu pause reste ouvert — CdC « Harmonisation
/// des règles de pause », §2.
///
/// 30 s, et non 10 ou 15 : la durée est calibrée sur les candidats à mobilité
/// réduite (balayage, contacteur, commande adaptée), pour qui atteindre puis
/// activer un bouton prend sensiblement plus de temps.
const Duration kGamePauseWindow = Duration(seconds: 30);

/// Droit de pause d'**une** partie : **une seule ouverture**, d'au plus
/// [kGamePauseWindow].
///
/// Le CdC part d'une contradiction : « une interruption annule la session »
/// cohabitait avec un menu pause ouvrable autant de fois qu'on voulait. Plutôt
/// que deux modes (Entraînement / Test), la règle retenue est une ouverture
/// unique et courte, réservée aux réglages (mode de saisie, son, musique).
///
/// **Une ouverture, pas un budget rechargeable.** Le droit s'éteint dès que le
/// candidat referme le menu, quelle qu'ait été la durée de sa pause : deux
/// secondes suffisent à le consommer. Les 30 s sont un PLAFOND, pas une réserve
/// à dépenser en plusieurs fois.
///
/// Une version intermédiaire avait fait des 30 s un budget cumulatif,
/// réouvrable tant qu'il en restait. Refusé au test : « le menu pause n'est
/// accessible qu'une seule fois ; après Resume ou View Rules, il ne doit plus
/// rester disponible. »
///
/// « View Rules » fait exception, et c'est la seule : c'est un aller-retour
/// À L'INTÉRIEUR de la même ouverture ([canReopen]), pas une seconde ouverture.
/// Le temps continue d'y courir — sans quoi il suffirait de passer par les
/// règles pour obtenir une pause sans fin.
///
/// La confirmation de sortie proposée par le bouton « Exit mission » ne met
/// rien en pause et ne touche donc pas à ce droit.
///
/// Mesuré sur l'horloge ambiante (`package:clock`) pour rester vérifiable par un
/// test déterministe.
class GamePauseAllowance {
  GamePauseAllowance({this.window = kGamePauseWindow});

  final Duration window;

  /// Le droit a été utilisé : plus aucune ouverture, même s'il restait du temps.
  bool _consumed = false;

  /// Début de l'ouverture en cours, `null` quand le jeu tourne.
  DateTime? _openedAt;

  /// Vrai pendant que le jeu est en pause.
  bool get isPaused => _openedAt != null;

  /// Temps restant sur l'ouverture en cours ; le plafond entier avant la
  /// première ouverture, zéro une fois le droit consommé.
  Duration get remaining {
    final openedAt = _openedAt;
    if (openedAt == null) return _consumed ? Duration.zero : window;
    final left = window - clock.now().difference(openedAt);
    return left.isNegative ? Duration.zero : left;
  }

  /// Vrai tant que le menu n'a jamais été ouvert de la partie.
  bool get canOpen => !_consumed;

  /// Aller-retour interne — retour de l'écran de règles vers le menu.
  ///
  /// Ce n'est PAS une seconde ouverture : l'ouverture court toujours, et il lui
  /// reste du temps. Après un « Resume », [close] a été appelé et ceci est faux.
  bool get canReopen => _openedAt != null && remaining > Duration.zero;

  /// Ouvre le menu — ou le rouvre au retour des règles — et rend le temps
  /// restant.
  ///
  /// Idempotent : le retour des règles ne relance pas le décompte.
  Duration open() {
    if (_consumed && _openedAt == null) return Duration.zero;
    _consumed = true;
    _openedAt ??= clock.now();
    return remaining;
  }

  /// Referme l'ouverture : le jeu repart et le droit est éteint.
  ///
  /// À appeler au moment où le jeu REPART, pas quand la boîte de dialogue se
  /// dépile — un aller-retour par l'écran de règles ne referme rien, le jeu y
  /// est toujours en pause.
  void close() => _openedAt = null;

  /// Rend le droit — uniquement au démarrage d'une **nouvelle** partie.
  void reset() {
    _consumed = false;
    _openedAt = null;
  }

  /// Ce que le bouton de menu propose : la pause tant que le droit est intact,
  /// la sortie une fois qu'il est consommé.
  GameMenuAffordance get affordance =>
      canOpen ? GameMenuAffordance.pause : GameMenuAffordance.exit;
}

/// Ce que propose le bouton de menu d'une partie.
///
/// Le cahier des charges dit que le menu de pause disparaît après les 30 s.
/// Pris au pied de la lettre, cela retirait aussi « Exit mission », qui vit
/// DEDANS : une fois la fenêtre consommée, le candidat n'avait plus aucun moyen
/// volontaire de quitter. Il ne lui restait qu'à fermer l'application, ce que le
/// jeu traite comme une interruption subie — tentative annulée, sans écran de
/// confirmation, donc sans qu'il sache ce qu'il perdait.
///
/// Arbitrage du chef de projet (5 septembre 2026) : le bouton ne disparaît pas,
/// **il devient « Exit mission » et change d'icône**. La règle de fond est
/// intacte — plus de réglages, plus de « Resume », plus de temps gelé — mais la
/// sortie volontaire reste offerte, avec sa confirmation.
enum GameMenuAffordance {
  pause(
    icon: HugeIcons.strokeRoundedPause,
    tooltip: 'Pause',
    semanticsLabel: 'Mettre la mission en pause',
  ),
  exit(
    // Même icône que le titre de [GameExitConfirmDialog] : le bouton annonce
    // exactement la boîte qu'il ouvre.
    icon: HugeIcons.strokeRoundedLogout01,
    tooltip: 'Quitter la mission',
    semanticsLabel: 'Quitter la mission',
  );

  const GameMenuAffordance({
    required this.icon,
    required this.tooltip,
    required this.semanticsLabel,
  });

  final AppIconData icon;
  final String tooltip;
  final String semanticsLabel;

  bool get isExit => this == GameMenuAffordance.exit;
}

/// Compte à rebours de la fenêtre de pause, affiché sous le titre du menu.
///
/// Appelle [onExpired] une seule fois à zéro : c'est l'appelant qui referme sa
/// propre boîte de dialogue, puisque chaque jeu a son propre type d'action.
class _GamePauseCountdown extends StatefulWidget {
  const _GamePauseCountdown({required this.remaining, this.onExpired});

  final Duration remaining;
  final VoidCallback? onExpired;

  @override
  State<_GamePauseCountdown> createState() => _GamePauseCountdownState();
}

/// Seuil des dernières secondes : bandeau rouge ET tic sonore.
///
/// Le rouge existait déjà, le son manquait — un candidat qui règle le volume
/// dans le menu, tête baissée, ne voyait rien venir et se faisait renvoyer au
/// jeu sans préavis. Même seuil que le rouge, pour que les deux signaux disent
/// la même chose.
const int _kPauseUrgentSeconds = 10;

class _GamePauseCountdownState extends State<_GamePauseCountdown> {
  Timer? _ticker;
  late Duration _left = widget.remaining;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    if (_left <= Duration.zero) {
      _expire();
      return;
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final next = _left - const Duration(seconds: 1);
      setState(() => _left = next.isNegative ? Duration.zero : next);
      // Tic sur chacune des dix dernières secondes, zéro exclu : à zéro le menu
      // se referme, et le jeu a ses propres sons de reprise.
      final seconds = _left.inSeconds;
      if (seconds > 0 && seconds <= _kPauseUrgentSeconds) {
        SoundService.instance.playSfx(GameSfx.timerDecrease);
      }
      if (_left <= Duration.zero) _expire();
    });
  }

  void _expire() {
    if (_fired) return;
    _fired = true;
    _ticker?.cancel();
    final callback = widget.onExpired;
    if (callback == null) return;
    // Post-frame : `initState` peut être atteint avec une fenêtre déjà écoulée,
    // et on ne dépile pas une route pendant sa propre construction.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) callback();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = _left.inSeconds;
    final urgent = seconds <= _kPauseUrgentSeconds;
    final color = urgent ? ZennytGamePalette.error : ZennytGamePalette.muted;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(HugeIcons.strokeRoundedTimer02, size: 18, color: color),
          const SizedBox(width: AppSpacing.xs),
          // Texte agrandi sur petit écran : le libellé rétrécit plutôt que de
          // déborder de la pastille.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Fermeture du menu dans $seconds s',
                style: AppTypography.labelMedium.copyWith(
                  color: color,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Confirmation avant « Exit mission » — CdC §3, dernière ligne, et maquette
/// p. 2.
///
/// Sortir volontairement annule la tentative : sans cet écran, le candidat
/// quittait en pensant que son score serait quand même comptabilisé. Renvoie
/// `true` si le joueur confirme la sortie.
class GameExitConfirmDialog extends StatelessWidget {
  const GameExitConfirmDialog({super.key, this.missionLabel = 'la mission'});

  /// Groupe nominal avec son article : « la mission » par défaut, « le
  /// parcours » ou « la session » selon le jeu.
  final String missionLabel;

  static Future<bool> show(
    BuildContext context, {
    String missionLabel = 'la mission',
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: ZennytGamePalette.ink.withValues(alpha: 0.82),
      builder: (_) => GameExitConfirmDialog(missionLabel: missionLabel),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
      ),
      // Défilement de secours : à 200 % de texte, le message ne tient plus
      // dans la hauteur d'un téléphone et masquait les deux boutons.
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: ZennytGamePalette.magenta.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const AppIcon(
                HugeIcons.strokeRoundedLogout01,
                color: ZennytGamePalette.magenta,
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              'Quitter $missionLabel ?',
              textAlign: TextAlign.center,
              style: AppTypography.headlineLarge.copyWith(
                color: ZennytGamePalette.blue,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Si tu quittes maintenant, ta tentative sera annulée et aucun score '
              'ne sera enregistré.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: ZennytGamePalette.muted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Pour valider ton score, termine tous les niveaux ou continue '
              'à jouer jusqu’à la fin du temps imparti.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: ZennytGamePalette.muted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            GamePrimaryButton(
              label: 'Continuer $missionLabel',
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(height: AppSpacing.md),
            GamePauseExitButton(
              label: 'Quitter sans enregistrer',
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ouvre un menu pause — **le seul point d'entrée** des jeux.
///
/// Fixe ce qui divergeait d'un jeu à l'autre : couleur du voile et fermeture
/// au toucher extérieur. Le menu ne se referme que par une de ses actions ou
/// par l'expiration de sa fenêtre ([GamePauseScaffold.onCountdownExpired]).
Future<T?> showGamePauseMenu<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: false,
    barrierColor: ZennytGamePalette.ink.withValues(alpha: 0.82),
    builder: builder,
  );
}

/// Nature d'une action du menu pause : elle fixe son icône et son style, pour
/// qu'une même action se présente de la même façon dans tous les jeux.
enum GamePauseActionKind {
  resume(HugeIcons.strokeRoundedPlay),
  restart(HugeIcons.strokeRoundedReload),
  rules(HugeIcons.strokeRoundedHelpCircle),
  exit(HugeIcons.strokeRoundedLogout01);

  const GamePauseActionKind(this.icon);

  final AppIconData icon;
}

/// Une action du menu pause. Le jeu ne fournit que le libellé et le geste ; le
/// rendu est celui de [GamePauseScaffold].
class GamePauseMenuAction {
  const GamePauseMenuAction({
    required this.kind,
    required this.label,
    required this.onPressed,
    this.key,
  });

  const GamePauseMenuAction.resume({
    required this.onPressed,
    this.label = 'Reprendre',
    this.key,
  }) : kind = GamePauseActionKind.resume;

  const GamePauseMenuAction.restart({
    required this.onPressed,
    this.label = 'Recommencer',
    this.key,
  }) : kind = GamePauseActionKind.restart;

  const GamePauseMenuAction.rules({
    required this.onPressed,
    this.label = 'Règles / Aide',
    this.key,
  }) : kind = GamePauseActionKind.rules;

  const GamePauseMenuAction.exit({
    required this.onPressed,
    this.label = 'Quitter la mission',
    this.key,
  }) : kind = GamePauseActionKind.exit;

  final GamePauseActionKind kind;
  final String label;
  final VoidCallback onPressed;
  final Key? key;
}

/// Coquille visuelle **unique** du menu pause, identique dans tous les jeux :
/// carte blanche arrondie, titre « Pause », compte à rebours, une section
/// optionnelle (ex. « Input mode »), une description optionnelle, les options
/// de retour (son, musique, vibration) puis les actions.
///
/// Chaque jeu garde son propre enum/handler et ne décrit que ses [actions] :
/// le style des boutons n'appartient qu'à ce widget.
///
/// **Jamais de défilement.** Le menu est mis en page à la largeur disponible,
/// puis réduit si besoin pour tenir dans la hauteur de l'écran — petit
/// téléphone, paysage, tablette ou texte agrandi. Un menu qui défile cachait
/// « Exit mission » sous la ligne de flottaison sans que rien ne le signale.
class GamePauseScaffold extends StatelessWidget {
  const GamePauseScaffold({
    super.key,
    this.title = 'Pause',
    this.titleKey,
    this.inputMode,
    this.description,
    this.showAudioOptions = true,
    this.countdown,
    this.onCountdownExpired,
    required this.actions,
  });

  final String title;
  final Key? titleKey;

  /// Temps restant sur la fenêtre de pause ([GamePauseAllowance.remaining]).
  ///
  /// Null ⇒ pas de compte à rebours (écrans hors partie mesurée, tests de
  /// rendu). Les jeux passent la valeur de leur allocation.
  final Duration? countdown;

  /// Appelé quand [countdown] atteint zéro : l'écran referme son menu sur son
  /// action « resume », puis la partie reprend sans autre pause possible.
  final VoidCallback? onCountdownExpired;

  /// Section optionnelle affichée entre le titre et les options de retour
  /// (ex. le sélecteur « Input mode » de Je bouge / Emotional Radar).
  final Widget? inputMode;

  /// Texte d'aide/avertissement optionnel (ex. phase mesurée non reprenable).
  final String? description;

  /// Affiche le bloc des options de retour (effets, musique, vibration).
  final bool showAudioOptions;

  /// Actions, dans l'ordre (Resume, Restart, View rules, Exit…). La première
  /// action qui n'est pas une sortie est mise en avant.
  final List<GamePauseMenuAction> actions;

  /// Hauteur disponible sous laquelle les espacements se resserrent, avant
  /// même toute réduction d'échelle.
  static const double _compactHeight = 700;

  /// Largeur à partir de laquelle un écran en paysage répartit le menu sur deux
  /// colonnes : réglages à gauche, actions à droite.
  static const double _twoColumnWidth = 600;

  /// Largeur maximale de la carte : sur tablette, un menu étiré sur toute la
  /// largeur n'est plus lisible d'un coup d'œil.
  static const double _maxWidth = 440;
  static const double _maxWidthTwoColumns = 760;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final compact = screen.height < _compactHeight;
    final twoColumns =
        screen.width > screen.height && screen.width >= _twoColumnWidth;
    final gapLarge = compact ? AppSpacing.md : AppSpacing.xl;
    final gapMedium = compact ? AppSpacing.sm : AppSpacing.lg;
    final gapButtons = compact ? AppSpacing.sm : AppSpacing.md;
    final padding = compact ? AppSpacing.base : AppSpacing.xl;
    final inset = compact ? 16.0 : 32.0;

    final header = <Widget>[
      Text(
        title,
        key: titleKey,
        textAlign: TextAlign.center,
        style:
            (compact
                    ? AppTypography.headlineLarge
                    : AppTypography.displayMedium)
                .copyWith(color: ZennytGamePalette.blue, letterSpacing: 0),
      ),
      if (countdown != null) ...[
        SizedBox(height: gapButtons),
        _GamePauseCountdown(
          remaining: countdown!,
          onExpired: onCountdownExpired,
        ),
      ],
    ];

    final settings = <Widget>[
      if (inputMode != null) ...[SizedBox(height: gapLarge), inputMode!],
      if (description != null) ...[
        SizedBox(height: inputMode != null ? gapMedium : gapLarge),
        Text(
          description!,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: ZennytGamePalette.muted,
            height: 1.45,
          ),
        ),
      ],
      if (showAudioOptions) ...[
        SizedBox(
          height: (inputMode != null || description != null)
              ? gapMedium
              : gapLarge,
        ),
        GamePauseAudioOptions(compact: compact),
      ],
    ];

    final primaryIndex = actions.indexWhere(
      (action) => action.kind != GamePauseActionKind.exit,
    );
    final buttons = <Widget>[
      for (var i = 0; i < actions.length; i++) ...[
        if (i > 0) SizedBox(height: gapButtons),
        _GamePauseActionButton(action: actions[i], primary: i == primaryIndex),
      ],
    ];

    final Widget content = twoColumns
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [...header, ...settings],
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: buttons,
                ),
              ),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...header,
              ...settings,
              SizedBox(height: gapButtons),
              ...buttons,
            ],
          );

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.all(inset),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: twoColumns ? _maxWidthTwoColumns : _maxWidth,
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: LayoutBuilder(
            builder: (context, constraints) => FittedBox(
              // Réduit, n'agrandit jamais : sur un grand écran le menu garde sa
              // taille nominale ; sur un petit il rétrécit au lieu de défiler.
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: SizedBox(width: constraints.maxWidth, child: content),
            ),
          ),
        ),
      ),
    );
  }
}

class _GamePauseActionButton extends StatelessWidget {
  const _GamePauseActionButton({required this.action, required this.primary});

  final GamePauseMenuAction action;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    if (action.kind == GamePauseActionKind.exit) {
      return GamePauseExitButton(
        key: action.key,
        label: action.label,
        icon: action.kind.icon,
        onPressed: action.onPressed,
      );
    }
    return primary
        ? GamePrimaryButton(
            key: action.key,
            label: action.label,
            icon: action.kind.icon,
            onPressed: action.onPressed,
          )
        : GameOutlineButton(
            key: action.key,
            label: action.label,
            icon: action.kind.icon,
            onPressed: action.onPressed,
          );
  }
}

/// Bloc « Audio options » commun : deux interrupteurs (effets sonores +
/// musique) reliés **directement** au [SoundService]. Auto-géré : aucun état à
/// tenir côté écran, l'état initial reflète le service.
class GamePauseAudioOptions extends StatefulWidget {
  const GamePauseAudioOptions({super.key, this.compact = false});

  /// Resserre les interlignes sur les écrans courts (voir [GamePauseScaffold]).
  final bool compact;

  @override
  State<GamePauseAudioOptions> createState() => _GamePauseAudioOptionsState();
}

class _GamePauseAudioOptionsState extends State<GamePauseAudioOptions> {
  late bool _soundEffects = SoundService.instance.sfxEnabled;
  late bool _music = SoundService.instance.musicEnabled;
  late bool _haptics = SoundService.instance.hapticsEnabled;

  @override
  Widget build(BuildContext context) {
    final gap = widget.compact ? AppSpacing.xs : AppSpacing.sm;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Options de retour',
          style: AppTypography.titleMedium.copyWith(
            color: ZennytGamePalette.blue,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: gap),
        GamePauseSwitchTile(
          label: 'Effets sonores',
          value: _soundEffects,
          compact: widget.compact,
          onChanged: (value) {
            setState(() => _soundEffects = value);
            SoundService.instance.setSfxEnabled(value);
          },
        ),
        SizedBox(height: gap),
        GamePauseSwitchTile(
          label: 'Musique',
          value: _music,
          compact: widget.compact,
          onChanged: (value) {
            setState(() => _music = value);
            // Met en pause plutôt qu'arrêter : réactiver reprend le morceau où
            // il en était, au lieu de le relancer depuis le début.
            SoundService.instance.setMusicEnabled(value);
          },
        ),
        SizedBox(height: gap),
        GamePauseSwitchTile(
          label: 'Vibration',
          value: _haptics,
          compact: widget.compact,
          onChanged: (value) {
            setState(() => _haptics = value);
            SoundService.instance.setHapticsEnabled(value);
          },
        ),
      ],
    );
  }
}

/// Ligne d'interrupteur bordée du menu pause (label + « On/Off » + [Switch]).
class GamePauseSwitchTile extends StatelessWidget {
  const GamePauseSwitchTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.md : AppSpacing.base,
        vertical: compact ? AppSpacing.xxs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: ZennytGamePalette.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.titleSmall.copyWith(
                color: ZennytGamePalette.blue,
                letterSpacing: 0,
              ),
            ),
          ),
          Text(
            value ? 'Activé' : 'Désactivé',
            style: AppTypography.labelMedium.copyWith(
              color: value
                  ? ZennytGamePalette.success
                  : ZennytGamePalette.muted,
              letterSpacing: 0,
            ),
          ),
          AdaptiveSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Sélecteur « Input mode » (Boutons / Tactile) commun, présenté au-dessus des
/// options audio pour les jeux qui gèrent une entrée directionnelle.
class GamePauseInputModeToggle extends StatelessWidget {
  const GamePauseInputModeToggle({
    super.key,
    required this.buttonsSelected,
    required this.onChanged,
  });

  final bool buttonsSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Mode de saisie',
          style: AppTypography.titleMedium.copyWith(
            color: ZennytGamePalette.blue,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AdaptiveSegmentedControl(
          labels: const ['Boutons', 'Tactile'],
          selectedIndex: buttonsSelected ? 0 : 1,
          shrinkWrap: true,
          onValueChanged: (index) => onChanged(index == 0),
        ),
      ],
    );
  }
}

/// Bouton « Exit … » commun (contour rouge sur fond rosé), identique partout.
class GamePauseExitButton extends StatelessWidget {
  const GamePauseExitButton({
    super.key,
    this.label = 'Quitter la mission',
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final AppIconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        // Seul bouton du menu pause qui n'était pas sonorisé : il n'utilise pas
        // [GameOutlineButton] (rouge sur fond rosé), donc il n'héritait pas du
        // clic générique.
        onPressed: () {
          SoundService.instance.playSfx(GameSfx.buttonClick);
          onPressed();
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: ZennytGamePalette.error,
          side: const BorderSide(color: ZennytGamePalette.error),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          textStyle: AppTypography.buttonMedium.copyWith(letterSpacing: 0),
        ),
        icon: icon == null ? const SizedBox.shrink() : AppIcon(icon),
        label: Text(label),
      ),
    );
  }
}

/// Texte qui réduit sa police jusqu'à tenir dans son parent, sans jamais être
/// coupé.
///
/// [FittedBox] ne convient pas aux libellés sur deux lignes : il donne à son
/// enfant une largeur infinie, donc le texte ne passe jamais à la ligne et se
/// réduit à l'excès. Ici on mesure pour de vrai : la police descend par demi-
/// points jusqu'à ce que (1) le mot le plus long tienne sur une ligne — sans
/// quoi « Appréciation » serait coupé au milieu du mot, (2) le texte tienne en
/// [maxLines] lignes et (3) sa hauteur tienne dans le parent.
class AutoFitText extends StatelessWidget {
  const AutoFitText(
    this.text, {
    super.key,
    required this.style,
    this.maxLines = 2,
    this.minFontSize = 9,
    this.textAlign = TextAlign.center,
  });

  final String text;
  final TextStyle style;
  final int maxLines;
  final double minFontSize;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = fontSizeFor(
          context,
          texts: [text],
          style: style,
          constraints: constraints,
          maxLines: maxLines,
          minFontSize: minFontSize,
          textAlign: textAlign,
        );
        return Text(
          text,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: style.copyWith(fontSize: size),
        );
      },
    );
  }

  /// Plus grande police (≤ celle de [style]) à laquelle TOUS les [texts]
  /// tiennent dans [constraints].
  ///
  /// Exposée pour les grilles : une taille commune à tous les boutons évite
  /// qu'un libellé long s'affiche visiblement plus petit que ses voisins.
  static double fontSizeFor(
    BuildContext context, {
    required List<String> texts,
    required TextStyle style,
    required BoxConstraints constraints,
    int maxLines = 2,
    double minFontSize = 9,
    TextAlign textAlign = TextAlign.center,
  }) {
    var size = style.fontSize ?? 14;
    if (!constraints.maxWidth.isFinite) return size;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.maybeOf(context) ?? TextDirection.ltr;
    bool allFit(double candidate) => texts.every(
      (text) => _fits(
        text,
        style.copyWith(fontSize: candidate),
        constraints,
        scaler,
        direction,
        maxLines,
        textAlign,
      ),
    );
    while (size > minFontSize && !allFit(size)) {
      size -= 0.5;
    }
    return size;
  }

  static bool _fits(
    String text,
    TextStyle sized,
    BoxConstraints constraints,
    TextScaler scaler,
    TextDirection direction,
    int maxLines,
    TextAlign textAlign,
  ) {
    for (final word in text.split(RegExp(r'\s+'))) {
      final painter = TextPainter(
        text: TextSpan(text: word, style: sized),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final tooWide = painter.width > constraints.maxWidth;
      painter.dispose();
      if (tooWide) return false;
    }
    final painter = TextPainter(
      text: TextSpan(text: text, style: sized),
      textDirection: direction,
      textScaler: scaler,
      maxLines: maxLines,
      textAlign: textAlign,
    )..layout(maxWidth: constraints.maxWidth);
    final fits =
        !painter.didExceedMaxLines &&
        (!constraints.maxHeight.isFinite ||
            painter.height <= constraints.maxHeight);
    painter.dispose();
    return fits;
  }
}

/// Réduit uniformément son contenu pour qu'il tienne dans la hauteur
/// disponible, sans défilement.
///
/// Le contenu garde toute la largeur du parent : seul un écran trop court le
/// fait rétrécir, et un écran assez haut l'affiche à sa taille normale.
class GameFitToScreen extends StatelessWidget {
  const GameFitToScreen({
    super.key,
    required this.child,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedHeight || !constraints.hasBoundedWidth) {
          return child;
        }
        // Contraintes serrées (Expanded) : occupe toute la place. Contraintes
        // lâches : épouse le contenu, et ne le réduit que s'il dépasse.
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment,
          child: SizedBox(width: constraints.maxWidth, child: child),
        );
      },
    );
  }
}
