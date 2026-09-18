import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/router/app_router.dart' show kLot1DemoBuild;
import '../../../../core/theme/app_typography.dart';
import '../../../navigation/presentation/viewmodel/nav_tab_provider.dart';
import '../../domain/entities/games_progress.dart';
import '../games_providers.dart';
import '../games_progress_provider.dart' as local_progress;

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
const _logoJeCoordonne = 'assets/games icons/Je Coordonne.png';
const _logoMemoryQuest = 'assets/games icons/Memory Quest transparent.png';
const _logoJePlace = 'assets/games icons/Je Place.png';
const _logoJeDecide = 'assets/games icons/Je Decide transparent.png';
const _logoBart = 'assets/games/bart_logo.svg';
const _logoIst = 'assets/games/ist_logo.svg';
const _logoOptimalPath = 'assets/games icons/Optimal Path menu original.png';
const _logoTaskScheduling =
    'assets/games icons/Task Scheduling transparent.png';
const _logoPredictivePuzzle =
    'assets/games icons/Predictive Puzzle transparent.png';
// Logo Emotional Radar : nom SANS espace avant « .png » (convention des logos
// de jeu, contrairement aux icônes de catégorie qui en portent une).
const _logoEmotionalRadar = 'assets/games icons/Emotional Radar.png';
const _logoReflectivePause = 'assets/games icons/Reflective Pause.png';
const _logoStrategicChoices = 'assets/games icons/Strategic Choices.png';

/// Libellé de couverture du catalogue.
///
/// Pendant un rechargement, la dernière valeur connue reste affichée plutôt
/// qu'un tiret qui clignoterait à chaque retour sur le hub. Tant qu'aucune
/// valeur n'est connue (serveur injoignable), un tiret : afficher 0 % laisserait
/// croire qu'aucune partie n'a été jouée.
String _coverageLabel(AsyncValue<GamesProgress?> progress) {
  final percent = progress.value?.coveragePercent;
  return percent == null ? 'Couverture —' : 'Couverture $percent %';
}

/// Nombre de jeux d'une catégorie, calculé depuis sa liste : ajouter ou
/// retirer un jeu met le libellé à jour sans autre retouche.
@visibleForTesting
String gameCountLabel(int count) => count <= 1 ? '$count jeu' : '$count jeux';

/// Ouvre un jeu, puis relit la progression au retour : la partie qui vient de
/// se terminer doit apparaître aussitôt dans la couverture.
Future<void> _openGame(BuildContext context, String route) async {
  final container = ProviderScope.containerOf(context, listen: false);
  await context.push(route);
  container.invalidate(gamesProgressProvider);
}

/// Hub des jeux sérieux, aligné sur l'écran Progress / Games de la maquette.
class GamesHubScreen extends ConsumerWidget {
  const GamesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverProgress = ref.watch(gamesProgressProvider).value;
    // Jeux terminés d'après le serveur : une catégorie n'est « terminée »
    // qu'une fois TOUS ses jeux jouables finis.
    final completedGames = serverProgress?.completed ?? const <CatalogGame>{};
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
                    kLot1DemoBuild
                        ? 'Démo des jeux'
                        : _coverageLabel(ref.watch(gamesProgressProvider)),
                    key: const ValueKey('games-coverage'),
                    style: AppTypography.headlineLarge.copyWith(
                      color: _magenta,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  if (kLot1DemoBuild) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Sessions d’entraînement · résultats d’exemple',
                      style: TextStyle(color: _muted, fontSize: 13),
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    if (serverProgress != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value:
                              serverProgress.completedGames /
                              serverProgress.totalGames,
                          minHeight: 6,
                          backgroundColor: _softGray,
                          color: _magenta,
                        ),
                      ),
                  ],
                  const SizedBox(height: 26),
                  _GameCategoryCard(
                    key: const ValueKey('game-category-cognitive-flexibility'),
                    title: 'Flexibilité cognitive',
                    completedGames: completedGames,
                    iconAsset: _iconFlexibility,
                    durationLabel: '2–25 min',
                    games: const [
                      _GameEntry(
                        label: 'Move Fast',
                        game: CatalogGame.moveFast,
                        subtitle: 'Changement de règle · Je bouge',
                        route: AppRoutes.gamesMoveFast,
                        logoAsset: _logoMoveFast,
                        fallbackIcon: Icons.near_me_rounded,
                      ),
                      _GameEntry(
                        label: 'Je continue',
                        game: CatalogGame.continuousAttention,
                        subtitle: 'Attention soutenue · 25 min',
                        route: AppRoutes.gamesJeContinue,
                        enabled: false,
                        logoAsset: _logoJeContinue,
                        fallbackIcon: Icons.all_inclusive_rounded,
                      ),
                      _GameEntry(
                        label: 'Je coordonne',
                        game: CatalogGame.coordinationTracking,
                        subtitle: 'Coordination œil-main · 3 min',
                        route: AppRoutes.gamesJeCoordonne,
                        enabled: false,
                        logoAsset: _logoJeCoordonne,
                        fallbackIcon: Icons.track_changes_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _GameCategoryCard(
                    key: const ValueKey('game-category-working-memory'),
                    title: 'Mémoire de travail',
                    completedGames: completedGames,
                    iconAsset: _iconMemory,
                    durationLabel: '5–13 min',
                    games: const [
                      // « J'investigue » scindé en deux jeux sur retour client :
                      // l'empan de chiffres et la mémoire des images se jouent
                      // et se valident séparément.
                      _GameEntry(
                        label: 'Memory Quest · Digits',
                        game: CatalogGame.memoryQuestDigits,
                        subtitle: 'Empan de chiffres · J\'investigue',
                        route: AppRoutes.gamesInvestigateDigits,
                        logoAsset: _logoMemoryQuest,
                        fallbackIcon: Icons.pin_rounded,
                      ),
                      _GameEntry(
                        label: 'Memory Quest · Images',
                        game: CatalogGame.memoryQuestImages,
                        subtitle: 'Empan d\'objets · J\'investigue',
                        route: AppRoutes.gamesInvestigateImages,
                        logoAsset: _logoMemoryQuest,
                        fallbackIcon: Icons.image_rounded,
                      ),
                      _GameEntry(
                        label: 'Je place',
                        game: CatalogGame.objectLocation,
                        subtitle: 'Mémoire des emplacements · 5 min',
                        route: AppRoutes.gamesJePlace,
                        enabled: false,
                        logoAsset: _logoJePlace,
                        fallbackIcon: Icons.grid_view_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Decision-Making : « Je Décide » reste distinct de
                  // Predictive Puzzle, qui appartient à Planifik.
                  _GameCategoryCard(
                    key: const ValueKey('game-category-decision-making'),
                    title: 'Prise de décision',
                    completedGames: completedGames,
                    iconAsset: _iconDecision,
                    games: const [
                      _GameEntry(
                        label: 'Je Décide',
                        game: CatalogGame.decision,
                        subtitle: 'Choix du quotidien · style de décision',
                        route: AppRoutes.gamesJeDecide,
                        logoAsset: _logoJeDecide,
                        fallbackIcon: Icons.alt_route_rounded,
                      ),
                      // BART + IST — décision comportementale (DECISION_BEHAVIORAL).
                      // Barèmes PROVISOIRES : l'événement Fit Score reste suspendu.
                      _GameEntry(
                        label: 'BART',
                        game: CatalogGame.bart,
                        subtitle: 'Prise de risque · gonfler ou collecter',
                        route: AppRoutes.gamesBart,
                        logoAsset: _logoBart,
                        fallbackIcon: Icons.bubble_chart_rounded,
                      ),
                      _GameEntry(
                        label: 'IST',
                        game: CatalogGame.informationSampling,
                        subtitle:
                            'Recueil d\'informations · observer puis décider',
                        route: AppRoutes.gamesIst,
                        logoAsset: _logoIst,
                        fallbackIcon: Icons.grid_on_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Executive Planning (Planifik) : 3 mini-jeux → menu de sélection.
                  _GameCategoryCard(
                    key: const ValueKey('game-category-executive-planning'),
                    title: 'Planification exécutive',
                    completedGames: completedGames,
                    iconAsset: _iconPlanning,
                    games: const [
                      _GameEntry(
                        label: 'Optimal Path',
                        game: CatalogGame.optimalPath,
                        subtitle: 'Path Mind · trajet le plus court',
                        route: AppRoutes.gamesPlanifik,
                        logoAsset: _logoOptimalPath,
                        fallbackIcon: Icons.route_rounded,
                      ),
                      _GameEntry(
                        label: 'Day Stack',
                        game: CatalogGame.taskScheduling,
                        subtitle:
                            'Planification des tâches · dépendances et échéances',
                        route: AppRoutes.gamesTaskScheduling,
                        logoAsset: _logoTaskScheduling,
                        fallbackIcon: Icons.event_note_rounded,
                      ),
                      _GameEntry(
                        label: 'Predictive Puzzle',
                        game: CatalogGame.predictivePuzzle,
                        subtitle: 'Tour de Hanoï · anticipation',
                        route: AppRoutes.gamesPredictivePuzzle,
                        logoAsset: _logoPredictivePuzzle,
                        fallbackIcon: Icons.extension_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _GameCategoryCard(
                    key: const ValueKey('game-category-emotional-regulation'),
                    title: 'Régulation émotionnelle',
                    completedGames: completedGames,
                    iconAsset: _iconEmotion,
                    games: const [
                      _GameEntry(
                        label: 'Emotional Radar',
                        game: CatalogGame.emotionalRadar,
                        subtitle:
                            'Reconnaître les émotions en situation réelle',
                        route: AppRoutes.gamesEmotionalRadar,
                        logoAsset: _logoEmotionalRadar,
                        fallbackIcon: Icons.favorite_rounded,
                      ),
                      _GameEntry(
                        label: 'Reflective Pause',
                        game: CatalogGame.reflectivePause,
                        subtitle:
                            'Contrôle de l\'impulsivité · moments de pression',
                        route: AppRoutes.gamesReflectivePause,
                        logoAsset: _logoReflectivePause,
                        fallbackIcon: Icons.timer_outlined,
                      ),
                      _GameEntry(
                        label: 'Strategic Choices',
                        game: CatalogGame.strategicChoices,
                        subtitle: 'Réfléchir · choisir · répondre',
                        route: AppRoutes.gamesStrategicChoices,
                        logoAsset: _logoStrategicChoices,
                        fallbackIcon: Icons.call_split_rounded,
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
      'Joue et découvre\nton talent',
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
      label: 'Retour',
      child: Tooltip(
        message: 'Retour',
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

/// Un jeu au sein d'une catégorie (une carte peut en regrouper plusieurs).
class _GameEntry {
  const _GameEntry({
    required this.label,
    required this.game,
    required this.route,
    required this.logoAsset,
    required this.fallbackIcon,
    this.subtitle,
    this.enabled = true,
  });

  final String label;

  /// Jeu du catalogue serveur, pour savoir s'il a été terminé.
  final CatalogGame game;
  final String route;
  final String logoAsset;
  final IconData fallbackIcon;
  final String? subtitle;

  /// Jeu ouvert à ce build de test.
  ///
  /// Les jeux désactivés restent **visibles et à leur place** : le menu qu'on
  /// fait valider doit être celui du produit, avec ses catégories complètes.
  /// Ils sont seulement grisés et inertes, le temps que leur contenu soit validé.
  final bool enabled;
}

class _GameCategoryCard extends ConsumerWidget {
  const _GameCategoryCard({
    super.key,
    required this.title,
    required this.iconAsset,
    this.completedGames = const {},
    this.games = const [],
    this.durationLabel = '10–13 min',
  });

  final String title;
  final String iconAsset;

  /// Jeux terminés au moins une fois, d'après le serveur.
  final Set<CatalogGame> completedGames;
  final String durationLabel;

  /// Jeux de la catégorie. Vide → module non implémenté (carte inactive).
  /// 1 jeu → navigation directe. Plusieurs → petit menu de sélection.
  final List<_GameEntry> games;

  /// Jeux ouverts à ce build. Une catégorie dont aucun jeu n'est ouvert reste
  /// affichée, mais inactive.
  List<_GameEntry> get _playable =>
      games.where((g) => g.enabled).toList(growable: false);

  /// Catégorie terminée : chacun de ses jeux jouables a été fini au moins une
  /// fois. Ouvrir un jeu puis revenir ne suffit plus. Les jeux encore fermés
  /// (« Bientôt ») ne comptent pas : ils ne peuvent pas être terminés.
  bool get completed {
    final playable = _playable;
    return playable.isNotEmpty &&
        playable.every((g) => completedGames.contains(g.game));
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    final playable = _playable;
    if (playable.isEmpty) return;

    // Design screen 76 — anti-fraud monitoring consent, asked once.
    if (!ref.read(local_progress.gamesProgressProvider).consentGiven) {
      final agreed = await _showGamesConsentDialog(context);
      if (agreed != true) return;
      ref.read(local_progress.gamesProgressProvider.notifier).setConsent(true);
    }

    if (!context.mounted) return;
    if (games.length == 1) {
      await _openGame(context, playable.first.route);
    } else {
      final route = await _showGamePicker(context, title: title, games: games);
      if (route == null || !context.mounted) return;
      await _openGame(context, route);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Carte inactive quand la catégorie n'a aucun jeu, ou aucun jeu ouvert.
    final enabled = _playable.isNotEmpty;
    final onTap = enabled ? () => _handleTap(context, ref) : null;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
    final titleRow = _CategoryTitleRow(
      title: title,
      enabled: enabled,
      completed: completed,
    );
    final logos = _CategoryGameLogos(games: games);
    final illustration = _CategoryIllustration(
      asset: iconAsset,
      width: largeText ? 76 : 94,
      height: largeText ? 72 : 88,
    );
    final metadata = _CategoryMetadata(
      durationLabel: durationLabel,
      aptitudeLabel: gameCountLabel(games.length),
      stacked: largeText,
    );

    final content = Container(
      constraints: const BoxConstraints(minHeight: 116),
      padding: const EdgeInsets.fromLTRB(24, 12, 10, 10),
      decoration: BoxDecoration(
        color: completed ? const Color(0xFFF3E8F6) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: completed ? _magenta : _blue,
          width: completed ? 1.6 : 1.2,
        ),
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
  const _CategoryTitleRow({
    required this.title,
    required this.enabled,
    this.completed = false,
  });

  final String title;
  final bool enabled;
  final bool completed;

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
        if (completed)
          const Icon(Icons.check_circle_rounded, color: _magenta, size: 22)
        else if (enabled)
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

/// Anti-fraud monitoring consent (design screen 76). Returns `true` only when
/// the user ticked the agreement and confirmed. Asked once, then remembered in
/// [local_progress.gamesProgressProvider].
Future<bool?> _showGamesConsentDialog(BuildContext context) {
  var agreed = false;
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Important !',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(dialogContext).pop(false),
                    child: const Icon(
                      Icons.close_rounded,
                      color: _muted,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Pour préserver l’intégrité des évaluations, des technologies de surveillance peuvent '
                'collecter des captures d’écran, des images de la webcam et la dynamique de frappe '
                'pendant les tests. Ces données servent uniquement à détecter l’usurpation '
                'd’identité, la triche ou la fraude.',
                style: TextStyle(color: _muted, fontSize: 13.5, height: 1.45),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: agreed,
                    activeColor: _blue,
                    onChanged: (v) => setState(() => agreed = v ?? false),
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'Je comprends et j’accepte les conditions de surveillance.',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: agreed
                      ? () => Navigator.of(dialogContext).pop(true)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continuer',
                    style: TextStyle(fontWeight: FontWeight.w700),
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

/// Petit menu (bottom sheet) pour choisir un jeu quand la catégorie en regroupe
/// plusieurs. Retourne la route choisie (ou `null`), que l'appelant pousse.
Future<String?> _showGamePicker(
  BuildContext context, {
  required String title,
  required List<_GameEntry> games,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.88,
          ),
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
                  'Choisis un jeu',
                  style: TextStyle(
                    color: _muted,
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: games.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) => _GamePickerTile(
                      game: games[index],
                      onTap: () =>
                          Navigator.of(sheetContext).pop(games[index].route),
                    ),
                  ),
                ),
              ],
            ),
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
    final on = game.enabled;
    // Grisé et inerte, mais toujours lisible : le joueur voit ce que la
    // catégorie contiendra, sans pouvoir l'ouvrir.
    final tile = Material(
      color: on ? Colors.white : _softGray,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: on ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: on ? _blue : _muted.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Opacity(
                opacity: on ? 1 : 0.45,
                child: _GameLogoBadge(
                  game: game,
                  contextName: 'picker',
                  size: 56,
                  iconSize: 27,
                  radius: 13,
                ),
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
                        color: on ? _blue : _muted,
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
              if (on)
                const Icon(Icons.chevron_right_rounded, color: _blue, size: 24)
              else
                const _ComingSoonBadge(),
            ],
          ),
        ),
      ),
    );

    // L'état est annoncé aux lecteurs d'écran : un simple gris ne se « voit »
    // pas en synthèse vocale.
    return Semantics(
      enabled: on,
      button: on,
      label: on ? game.label : '${game.label}, bientôt disponible',
      child: tile,
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
      label: 'Logo ${game.label}',
      child: SizedBox(
        key: ValueKey('$contextName-game-logo-${game.label}'),
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: game.logoAsset.endsWith('.svg')
              ? SvgPicture.asset(game.logoAsset, fit: BoxFit.contain)
              : Image.asset(
                  game.logoAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) => ColoredBox(
                    color: const Color(0xFFF1F4FA),
                    child: Icon(
                      game.fallbackIcon,
                      color: _blue,
                      size: iconSize,
                    ),
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
