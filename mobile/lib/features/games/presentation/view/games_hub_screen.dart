import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../navigation/presentation/viewmodel/nav_tab_provider.dart';

const _ink = Color(0xFF25204A);
const _blue = Color(0xFF17458F);
const _magenta = Color(0xFFD72C83);
const _muted = Color(0xFF5D5D66);
const _softGray = Color(0xFFEDEDED);

// Logos par catégorie (fournis dans assets/games icons/).
// NB : les noms de fichiers contiennent une espace avant « .png » — à respecter.
const _iconFlexibility = 'assets/games icons/Cognitive Flexibility .png';
const _iconMemory = 'assets/games icons/Working Memory .png';
const _iconDecision = 'assets/games icons/Decision-Making .png';
const _iconPlanning = 'assets/games icons/Executive Planning .png';
const _iconEmotion = 'assets/games icons/Emotional Regulation .png';

// Logos officiels des jeux, repris des premières pages de chaque jeu.
const _logoMoveFast = 'assets/games icons/Move Fast.png';
const _logoJeContinue = 'assets/games icons/Je Continue.png';
const _logoMemoryQuest = 'assets/games icons/Memory Quest transparent.png';
const _logoJeDecide = 'assets/games icons/Je Decide transparent.png';
const _logoOptimalPath = 'assets/games icons/Optimal Path transparent.png';
const _logoTaskScheduling =
    'assets/games icons/Task Scheduling transparent.png';
const _logoPredictivePuzzle =
    'assets/games icons/Predictive Puzzle transparent.png';
// Logo Emotional Radar : nom SANS espace avant « .png » (convention des logos
// de jeu, contrairement aux icônes de catégorie qui en portent une).
const _logoEmotionalRadar = 'assets/games icons/Emotional Radar.png';
const _logoReflectivePause = 'assets/games icons/Reflective Pause.png';

/// Hub des jeux sérieux, aligné sur l'écran Progress / Games de la maquette.
class GamesHubScreen extends ConsumerWidget {
  const GamesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(36, 26, 28, 0),
              child: _GamesHeader(
                onBack: () {
                  if (context.canPop()) {
                    context.pop();
                    return;
                  }
                  ref.read(navTabProvider.notifier).select(0);
                },
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(36, 32, 31, 26),
                children: [
                  Text(
                    'Coverage 0%',
                    style: AppTypography.headlineLarge.copyWith(
                      color: _magenta,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 26),
                  _GameCategoryCard(
                    key: const ValueKey('game-category-cognitive-flexibility'),
                    title: 'Cognitive Flexibility',
                    iconAsset: _iconFlexibility,
                    durationLabel: '2–25 min',
                    aptitudeLabel: '2 games',
                    games: const [
                      _GameEntry(
                        label: 'Move Fast',
                        subtitle: 'Rule switching · Je bouge',
                        route: AppRoutes.gamesMoveFast,
                        logoAsset: _logoMoveFast,
                        fallbackIcon: Icons.near_me_rounded,
                      ),
                      _GameEntry(
                        label: 'Je continue',
                        subtitle: 'Sustained attention · 25 min',
                        route: AppRoutes.gamesJeContinue,
                        logoAsset: _logoJeContinue,
                        fallbackIcon: Icons.all_inclusive_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _GameCategoryCard(
                    key: const ValueKey('game-category-working-memory'),
                    title: 'Working Memory',
                    iconAsset: _iconMemory,
                    games: const [
                      _GameEntry(
                        label: 'Memory Quest',
                        subtitle: 'Digit & object span · J\'investigue',
                        route: AppRoutes.gamesInvestigate,
                        logoAsset: _logoMemoryQuest,
                        fallbackIcon: Icons.apps_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Decision-Making : « Je Décide » reste distinct de
                  // Predictive Puzzle, qui appartient à Planifik.
                  _GameCategoryCard(
                    key: const ValueKey('game-category-decision-making'),
                    title: 'Decision-Making',
                    iconAsset: _iconDecision,
                    games: const [
                      _GameEntry(
                        label: 'Je Décide',
                        subtitle: 'Everyday choices · decision style',
                        route: AppRoutes.gamesJeDecide,
                        logoAsset: _logoJeDecide,
                        fallbackIcon: Icons.alt_route_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Executive Planning (Planifik) : 3 mini-jeux → menu de sélection.
                  _GameCategoryCard(
                    key: const ValueKey('game-category-executive-planning'),
                    title: 'Executive Planning',
                    iconAsset: _iconPlanning,
                    games: const [
                      _GameEntry(
                        label: 'Optimal Path',
                        subtitle: 'Path Mind · shortest route',
                        route: AppRoutes.gamesPlanifik,
                        logoAsset: _logoOptimalPath,
                        fallbackIcon: Icons.route_rounded,
                      ),
                      _GameEntry(
                        label: 'Task Scheduling',
                        subtitle: 'Dependencies & deadlines',
                        route: AppRoutes.gamesTaskScheduling,
                        logoAsset: _logoTaskScheduling,
                        fallbackIcon: Icons.event_note_rounded,
                      ),
                      _GameEntry(
                        label: 'Predictive Puzzle',
                        subtitle: 'Tower of Hanoi · foresight',
                        route: AppRoutes.gamesPredictivePuzzle,
                        logoAsset: _logoPredictivePuzzle,
                        fallbackIcon: Icons.extension_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _GameCategoryCard(
                    key: const ValueKey('game-category-emotional-regulation'),
                    title: 'Emotional Regulation',
                    iconAsset: _iconEmotion,
                    games: const [
                      _GameEntry(
                        label: 'Emotional Radar',
                        subtitle: 'Recognize emotions in real situations',
                        route: AppRoutes.gamesEmotionalRadar,
                        logoAsset: _logoEmotionalRadar,
                        fallbackIcon: Icons.favorite_rounded,
                      ),
                      _GameEntry(
                        label: 'Reflective Pause',
                        subtitle: 'Impulse control · pressure moments',
                        route: AppRoutes.gamesReflectivePause,
                        logoAsset: _logoReflectivePause,
                        fallbackIcon: Icons.timer_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GamesHeader extends StatelessWidget {
  const _GamesHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final title = Text(
      'Play & discover\nyour talent',
      textAlign: TextAlign.center,
      style: AppTypography.headlineLarge.copyWith(
        color: _ink,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 1.3,
        letterSpacing: 0,
      ),
    );

    if (textScale > 1.5) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HeaderButton(onTap: onBack),
              const _ProfileBadge(),
            ],
          ),
          const SizedBox(height: 12),
          title,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _HeaderButton(onTap: onBack),
        const SizedBox(width: 12),
        Expanded(child: title),
        const SizedBox(width: 12),
        const _ProfileBadge(),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: Tooltip(
        message: 'Back',
        excludeFromSemantics: true,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          elevation: 6,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          child: InkWell(
            excludeFromSemantics: true,
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF0F0F3)),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Colors.black,
                size: 32,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 62,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF6B37E), Color(0xFF9B5ACF)],
              ),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          Positioned(
            right: -1,
            bottom: 5,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _blue, width: 2),
              ),
              child: const Icon(Icons.menu_rounded, color: _blue, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

/// Un jeu jouable au sein d'une catégorie (une carte peut en regrouper plusieurs).
class _GameEntry {
  const _GameEntry({
    required this.label,
    required this.route,
    required this.logoAsset,
    required this.fallbackIcon,
    this.subtitle,
  });

  final String label;
  final String route;
  final String logoAsset;
  final IconData fallbackIcon;
  final String? subtitle;
}

class _GameCategoryCard extends StatelessWidget {
  const _GameCategoryCard({
    super.key,
    required this.title,
    required this.iconAsset,
    this.games = const [],
    this.durationLabel = '10-13mins',
    this.aptitudeLabel = 'N° aptitudes',
  });

  final String title;
  final String iconAsset;
  final String durationLabel;
  final String aptitudeLabel;

  /// Jeux de la catégorie. Vide → module non implémenté (carte inactive).
  /// 1 jeu → navigation directe. Plusieurs → petit menu de sélection.
  final List<_GameEntry> games;

  void _handleTap(BuildContext context) {
    if (games.isEmpty) return;
    if (games.length == 1) {
      context.push(games.first.route);
      return;
    }
    _showGamePicker(context, title: title, games: games);
  }

  @override
  Widget build(BuildContext context) {
    // Une carte sans jeu = module non implémenté → visuellement inactive.
    final enabled = games.isNotEmpty;
    final onTap = enabled ? () => _handleTap(context) : null;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
    final titleRow = _CategoryTitleRow(title: title, enabled: enabled);
    final logos = _CategoryGameLogos(games: games);
    final illustration = _CategoryIllustration(
      asset: iconAsset,
      width: largeText ? 76 : 94,
      height: largeText ? 72 : 88,
    );
    final metadata = _CategoryMetadata(
      durationLabel: durationLabel,
      aptitudeLabel: aptitudeLabel,
      stacked: largeText,
    );

    final content = Container(
      constraints: const BoxConstraints(minHeight: 116),
      padding: const EdgeInsets.fromLTRB(24, 12, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _blue, width: 1.2),
      ),
      child: largeText
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                titleRow,
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: logos),
                    const SizedBox(width: 10),
                    illustration,
                  ],
                ),
                const SizedBox(height: 8),
                metadata,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [titleRow, const SizedBox(height: 8), logos],
                      ),
                    ),
                    const SizedBox(width: 10),
                    illustration,
                  ],
                ),
                const SizedBox(height: 6),
                metadata,
              ],
            ),
    );

    return Material(
      color: Colors.transparent,
      child: Semantics(
        button: enabled,
        enabled: enabled,
        label: enabled ? title : '$title — bientôt disponible',
        child: InkWell(
          // onTap == null (module non implémenté) → carte non cliquable.
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: enabled ? content : Opacity(opacity: 0.55, child: content),
        ),
      ),
    );
  }
}

class _CategoryTitleRow extends StatelessWidget {
  const _CategoryTitleRow({required this.title, required this.enabled});

  final String title;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.titleLarge.copyWith(
              color: _blue,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(width: 6),
        if (enabled)
          const Icon(Icons.keyboard_arrow_down_rounded, color: _blue, size: 24)
        else
          const _ComingSoonBadge(),
      ],
    );
  }
}

class _CategoryMetadata extends StatelessWidget {
  const _CategoryMetadata({
    required this.durationLabel,
    required this.aptitudeLabel,
    required this.stacked,
  });

  final String durationLabel;
  final String aptitudeLabel;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final duration = _CategoryMetadataItem(
      icon: Icons.timer_outlined,
      label: durationLabel,
    );
    final aptitude = _CategoryMetadataItem(
      icon: Icons.bar_chart_rounded,
      label: aptitudeLabel,
    );

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [duration, const SizedBox(height: 6), aptitude],
      );
    }

    return Wrap(
      spacing: 20,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [duration, aptitude],
    );
  }
}

class _CategoryMetadataItem extends StatelessWidget {
  const _CategoryMetadataItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MetaIcon(icon: icon),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: _muted,
            fontFamily: AppTypography.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _CategoryIllustration extends StatelessWidget {
  const _CategoryIllustration({
    required this.asset,
    required this.width,
    required this.height,
  });

  final String asset;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

/// Petit menu (bottom sheet) pour choisir un jeu quand la catégorie en regroupe
/// plusieurs. Ferme la feuille puis navigue vers le jeu sélectionné.
void _showGamePicker(
  BuildContext context, {
  required String title,
  required List<_GameEntry> games,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _softGray,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppTypography.titleLarge.copyWith(
                  color: _ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Choose a game to play',
                style: TextStyle(
                  color: _muted,
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 16),
              for (final game in games) ...[
                _GamePickerTile(
                  game: game,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.push(game.route);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// Ligne d'un jeu dans le menu de sélection.
class _GamePickerTile extends StatelessWidget {
  const _GamePickerTile({required this.game, required this.onTap});

  final _GameEntry game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _blue, width: 1.2),
          ),
          child: Row(
            children: [
              _GameLogoBadge(
                game: game,
                contextName: 'picker',
                size: 56,
                iconSize: 27,
                radius: 13,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      game.label,
                      style: AppTypography.titleLarge.copyWith(
                        color: _blue,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    if (game.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        game.subtitle!,
                        style: TextStyle(
                          color: _muted,
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: _blue, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge « Bientôt disponible » pour les cartes de domaines non implémentés.
class _ComingSoonBadge extends StatelessWidget {
  const _ComingSoonBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _muted.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Bientôt',
        style: TextStyle(
          color: _muted,
          fontFamily: AppTypography.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _CategoryGameLogos extends StatelessWidget {
  const _CategoryGameLogos({required this.games});

  final List<_GameEntry> games;

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) {
      return SizedBox(
        height: 32,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Jeux à venir',
            style: AppTypography.bodySmall.copyWith(
              color: _muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: games.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) => _GameLogoBadge(
          game: games[index],
          contextName: 'category',
          size: 36,
          iconSize: 19,
          radius: 9,
        ),
      ),
    );
  }
}

class _GameLogoBadge extends StatelessWidget {
  const _GameLogoBadge({
    required this.game,
    required this.contextName,
    required this.size,
    required this.iconSize,
    required this.radius,
  });

  final _GameEntry game;
  final String contextName;
  final double size;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: '${game.label} logo',
      child: SizedBox(
        key: ValueKey('$contextName-game-logo-${game.label}'),
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.asset(
            game.logoAsset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) => ColoredBox(
              color: const Color(0xFFF1F4FA),
              child: Icon(game.fallbackIcon, color: _blue, size: iconSize),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaIcon extends StatelessWidget {
  const _MetaIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, color: _muted, size: 22);
  }
}
