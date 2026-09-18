import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/router/app_router.dart' show kLot1DemoBuild;
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/current_user_provider.dart';
import '../../../navigation/presentation/viewmodel/nav_tab_provider.dart';
import '../../domain/entities/games_progress.dart';
import '../games_providers.dart';
import '../games_progress_provider.dart' as local_progress;

import 'package:zennyt/shared/icons/app_icons.dart';
part 'games_hub_intro.dart';
part 'games_hub_picker.dart';

// Palette du hub « Play & discover your talent ».
/// Couleurs du hub, en clair et en sombre. Lues via [_hub] depuis le thème
/// courant : aucune couleur de surface ou de texte n'est figée.
@immutable
class _HubPalette {
  const _HubPalette({
    required this.isDark,
    required this.ink,
    required this.muted,
    required this.line,
    required this.surface,
    required this.card,
    required this.cardMuted,
    required this.violet,
    required this.success,
    required this.cta,
    required this.onCta,
    required this.chipSelected,
    required this.onChipSelected,
    required this.heroTop,
    required this.heroMid,
    required this.heroBottom,
    required this.ringTrack,
    required this.shadow,
    required this.barrier,
    required this.mountainBack,
    required this.mountainFront,
    required this.cloud,
  });

  final bool isDark;

  /// Texte principal.
  final Color ink;

  /// Texte secondaire.
  final Color muted;

  /// Bordures fines et puces non sélectionnées.
  final Color line;

  /// Fond de page.
  final Color surface;

  /// Cartes, feuilles et panneaux.
  final Color card;

  /// Carte inactive (jeu pas encore ouvert).
  final Color cardMuted;

  final Color violet;
  final Color success;

  /// Bouton principal (« Explore games », « Continue »…).
  final Color cta;
  final Color onCta;

  final Color chipSelected;
  final Color onChipSelected;

  /// Dégradé de l'intro, du haut vers l'illustration.
  final Color heroTop;
  final Color heroMid;
  final Color heroBottom;

  final Color ringTrack;
  final Color shadow;
  final Color barrier;
  final Color mountainBack;
  final Color mountainFront;
  final Color cloud;

  static const light = _HubPalette(
    isDark: false,
    ink: Color(0xFF1E1A4D),
    muted: Color(0xFF6B6880),
    line: Color(0xFFECE9F6),
    surface: Color(0xFFF8F7FD),
    card: Color(0xFFFFFFFF),
    cardMuted: Color(0xFFF7F7FA),
    violet: Color(0xFF6D4AE8),
    success: Color(0xFF1F9D63),
    cta: Color(0xFF1E1A4D),
    onCta: Color(0xFFFFFFFF),
    chipSelected: Color(0xFF1E1A4D),
    onChipSelected: Color(0xFFFFFFFF),
    heroTop: Color(0xFFF8F6FF),
    heroMid: Color(0xFFEAE5FE),
    heroBottom: Color(0xFFDFD9FD),
    ringTrack: Color(0xFFEFEBFB),
    shadow: Color(0xFF1E1A4D),
    barrier: Color(0x731E1A4D),
    mountainBack: Color(0xFFD9D0FC),
    mountainFront: Color(0xFFC6B7FB),
    cloud: Color(0xFFE9E4FC),
  );

  static const dark = _HubPalette(
    isDark: true,
    ink: Color(0xFFF4F2FF),
    muted: Color(0xFFA7A3C2),
    line: Color(0xFF2E2B45),
    surface: Color(0xFF121020),
    card: Color(0xFF1C1A2E),
    cardMuted: Color(0xFF17152A),
    violet: Color(0xFFA38FFF),
    success: Color(0xFF4ADE9A),
    cta: Color(0xFF7B5CF0),
    onCta: Color(0xFFFFFFFF),
    chipSelected: Color(0xFF7B5CF0),
    onChipSelected: Color(0xFFFFFFFF),
    heroTop: Color(0xFF121020),
    heroMid: Color(0xFF1D1838),
    heroBottom: Color(0xFF2B2358),
    ringTrack: Color(0xFF2E2B45),
    shadow: Color(0xFF000000),
    barrier: Color(0x99000000),
    mountainBack: Color(0xFF3A3170),
    mountainFront: Color(0xFF5242A0),
    cloud: Color(0xFF34305A),
  );

  static _HubPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  /// Fond teinté d'une catégorie : pastel en clair, lavis d'accent en sombre.
  Color tint(_GameCategory category) => isDark
      ? Color.alphaBlend(category.accent.withValues(alpha: 0.16), card)
      : category.tint;

}

_HubPalette _hub(BuildContext context) => _HubPalette.of(context);

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

/// Illustration de l'intro du hub (fond lavande uni).
const _introIllustration = 'assets/images/games_hub_girl.png';

/// Filtres du catalogue (puces sous la carte « Your journey »).
enum _HubFilter {
  all('Tous'),
  cognitive('Cognitif'),
  decision('Décision'),
  planning('Planification'),
  emotional('Émotions');

  const _HubFilter(this.label);

  final String label;
}

/// Un jeu au sein d'une catégorie (une carte peut en regrouper plusieurs).
class _GameEntry {
  const _GameEntry({
    required this.label,
    required this.route,
    required this.logoAsset,
    required this.fallbackIcon,
    required this.game,
    this.subtitle,
    this.enabled = true,
  });

  final String label;
  final String route;
  final String logoAsset;
  final AppIconData fallbackIcon;
  final String? subtitle;

  /// Jeu du catalogue serveur : sert à marquer « Played » dans le sélecteur.
  final CatalogGame game;

  /// Jeu ouvert à ce build de test.
  ///
  /// Les jeux désactivés restent **visibles et à leur place** : le menu qu'on
  /// fait valider doit être celui du produit, avec ses catégories complètes.
  /// Ils sont seulement grisés et inertes, le temps que leur contenu soit validé.
  final bool enabled;
}

/// Une dimension évaluée, avec ses jeux et sa couleur d'accent.
class _GameCategory {
  const _GameCategory({
    required this.id,
    required this.title,
    required this.tagline,
    required this.filter,
    required this.accent,
    required this.tint,
    required this.iconAsset,
    required this.games,
    this.durationLabel = '10–13 min',
  });

  /// Suffixe de la clé de carte (`game-category-<id>`).
  final String id;
  final String title;
  final String tagline;
  final _HubFilter filter;
  final Color accent;
  final Color tint;
  final String iconAsset;
  final String durationLabel;

  /// Jeux de la catégorie. 1 jeu → navigation directe ; plusieurs → sélecteur.
  final List<_GameEntry> games;

  List<_GameEntry> get playable =>
      games.where((g) => g.enabled).toList(growable: false);

  String get gamesLabel => gameCountLabel(games.length);

  /// Catégorie terminée : chacun de ses jeux jouables a été fini au moins une
  /// fois, d'après le serveur. Les jeux encore fermés (« Bientôt ») ne comptent
  /// pas : ils ne peuvent pas être terminés.
  bool isCompleted(Set<CatalogGame>? completed) {
    final open = playable;
    return completed != null &&
        open.isNotEmpty &&
        open.every((g) => completed.contains(g.game));
  }

  int playedCount(Set<CatalogGame>? completed) => completed == null
      ? 0
      : games.where((g) => completed.contains(g.game)).length;
}

const _categories = <_GameCategory>[
  _GameCategory(
    id: 'cognitive-flexibility',
    title: 'Flexibilité cognitive',
    tagline: 'S’adapter. Basculer. Penser autrement.',
    filter: _HubFilter.cognitive,
    accent: Color(0xFFE0559B),
    tint: Color(0xFFFDEDF4),
    iconAsset: _iconFlexibility,
    durationLabel: '2–25 min',
    games: [
      _GameEntry(
        label: 'Move Fast',
        subtitle: 'Changement de règle · Je bouge',
        route: AppRoutes.gamesMoveFast,
        logoAsset: _logoMoveFast,
        fallbackIcon: HugeIcons.strokeRoundedNavigation03,
        game: CatalogGame.moveFast,
      ),
      _GameEntry(
        label: 'Je continue',
        subtitle: 'Attention soutenue · 25 min',
        route: AppRoutes.gamesJeContinue,
        enabled: false,
        logoAsset: _logoJeContinue,
        fallbackIcon: HugeIcons.strokeRoundedInfinity01,
        game: CatalogGame.continuousAttention,
      ),
      _GameEntry(
        label: 'Je coordonne',
        subtitle: 'Coordination œil-main · 3 min',
        route: AppRoutes.gamesJeCoordonne,
        enabled: false,
        logoAsset: _logoJeCoordonne,
        fallbackIcon: HugeIcons.strokeRoundedTarget02,
        game: CatalogGame.coordinationTracking,
      ),
    ],
  ),
  _GameCategory(
    id: 'working-memory',
    title: 'Mémoire de travail',
    tagline: 'Retenir. Utiliser. Résoudre.',
    filter: _HubFilter.cognitive,
    accent: Color(0xFF4F6BED),
    tint: Color(0xFFEEF1FE),
    iconAsset: _iconMemory,
    durationLabel: '5–13 min',
    games: [
      // « J'investigue » scindé en deux jeux sur retour client : l'empan de
      // chiffres et la mémoire des images se jouent et se valident séparément.
      _GameEntry(
        label: 'Memory Quest · Digits',
        subtitle: 'Empan de chiffres · J\'investigue',
        route: AppRoutes.gamesInvestigateDigits,
        logoAsset: _logoMemoryQuest,
        fallbackIcon: HugeIcons.strokeRoundedPin,
        game: CatalogGame.memoryQuestDigits,
      ),
      _GameEntry(
        label: 'Memory Quest · Images',
        subtitle: 'Empan d\'objets · J\'investigue',
        route: AppRoutes.gamesInvestigateImages,
        logoAsset: _logoMemoryQuest,
        fallbackIcon: HugeIcons.strokeRoundedImage01,
        game: CatalogGame.memoryQuestImages,
      ),
      _GameEntry(
        label: 'Je place',
        subtitle: 'Mémoire des emplacements · 5 min',
        route: AppRoutes.gamesJePlace,
        enabled: false,
        logoAsset: _logoJePlace,
        fallbackIcon: HugeIcons.strokeRoundedGridView,
        game: CatalogGame.objectLocation,
      ),
    ],
  ),
  // Decision-Making : « Je Décide » reste distinct de Predictive Puzzle, qui
  // appartient à Planifik.
  _GameCategory(
    id: 'decision-making',
    title: 'Prise de décision',
    tagline: 'Analyser. Choisir. Agir.',
    filter: _HubFilter.decision,
    accent: Color(0xFFEE8A1E),
    tint: Color(0xFFFFF4E6),
    iconAsset: _iconDecision,
    games: [
      _GameEntry(
        label: 'Je Décide',
        subtitle: 'Choix du quotidien · style de décision',
        route: AppRoutes.gamesJeDecide,
        logoAsset: _logoJeDecide,
        fallbackIcon: HugeIcons.strokeRoundedRoute01,
        game: CatalogGame.decision,
      ),
      // BART + IST — décision comportementale (DECISION_BEHAVIORAL).
      // Barèmes PROVISOIRES : l'événement Fit Score reste suspendu.
      _GameEntry(
        label: 'BART',
        subtitle: 'Prise de risque · gonfler ou collecter',
        route: AppRoutes.gamesBart,
        logoAsset: _logoBart,
        fallbackIcon: HugeIcons.strokeRoundedChartBubble01,
        game: CatalogGame.bart,
      ),
      _GameEntry(
        label: 'IST',
        subtitle: 'Recueil d\'informations · observer puis décider',
        route: AppRoutes.gamesIst,
        logoAsset: _logoIst,
        fallbackIcon: HugeIcons.strokeRoundedGridTable,
        game: CatalogGame.informationSampling,
      ),
    ],
  ),
  // Executive Planning (Planifik) : 3 mini-jeux → menu de sélection.
  _GameCategory(
    id: 'executive-planning',
    title: 'Planification exécutive',
    tagline: 'Planifier. Organiser. Réussir.',
    filter: _HubFilter.planning,
    accent: Color(0xFF22A06B),
    tint: Color(0xFFE8F7EF),
    iconAsset: _iconPlanning,
    games: [
      _GameEntry(
        label: 'Optimal Path',
        subtitle: 'Path Mind · trajet le plus court',
        route: AppRoutes.gamesPlanifik,
        logoAsset: _logoOptimalPath,
        fallbackIcon: HugeIcons.strokeRoundedRoute01,
        game: CatalogGame.optimalPath,
      ),
      _GameEntry(
        label: 'Day Stack',
        subtitle: 'Planification des tâches · dépendances et échéances',
        route: AppRoutes.gamesTaskScheduling,
        logoAsset: _logoTaskScheduling,
        fallbackIcon: HugeIcons.strokeRoundedCalendar01,
        game: CatalogGame.taskScheduling,
      ),
      _GameEntry(
        label: 'Predictive Puzzle',
        subtitle: 'Tour de Hanoï · anticipation',
        route: AppRoutes.gamesPredictivePuzzle,
        logoAsset: _logoPredictivePuzzle,
        fallbackIcon: HugeIcons.strokeRoundedPuzzle,
        game: CatalogGame.predictivePuzzle,
      ),
    ],
  ),
  _GameCategory(
    id: 'emotional-regulation',
    title: 'Régulation émotionnelle',
    tagline: 'Rester calme. Garder le contrôle.',
    filter: _HubFilter.emotional,
    accent: Color(0xFF7C5CE0),
    tint: Color(0xFFF2EEFE),
    iconAsset: _iconEmotion,
    games: [
      _GameEntry(
        label: 'Emotional Radar',
        subtitle: 'Reconnaître les émotions en situation réelle',
        route: AppRoutes.gamesEmotionalRadar,
        logoAsset: _logoEmotionalRadar,
        fallbackIcon: HugeIcons.strokeRoundedFavourite,
        game: CatalogGame.emotionalRadar,
      ),
      _GameEntry(
        label: 'Reflective Pause',
        subtitle: 'Contrôle de l\'impulsivité · moments de pression',
        route: AppRoutes.gamesReflectivePause,
        logoAsset: _logoReflectivePause,
        fallbackIcon: HugeIcons.strokeRoundedTimer02,
        game: CatalogGame.reflectivePause,
      ),
      _GameEntry(
        label: 'Strategic Choices',
        subtitle: 'Réfléchir · choisir · répondre',
        route: AppRoutes.gamesStrategicChoices,
        logoAsset: _logoStrategicChoices,
        fallbackIcon: HugeIcons.strokeRoundedGitBranch,
        game: CatalogGame.strategicChoices,
      ),
    ],
  ),
];

/// Couverture du catalogue affichée dans l'anneau « Your journey ».
///
/// Pendant un rechargement, la dernière valeur connue reste affichée plutôt
/// qu'un tiret qui clignoterait à chaque retour sur le hub. Tant qu'aucune
/// valeur n'est connue (serveur injoignable), un tiret : afficher 0 % laisserait
/// croire qu'aucune partie n'a été jouée.
String _coverageLabel(AsyncValue<GamesProgress?> progress) {
  final percent = progress.value?.coveragePercent;
  return percent == null ? '—' : '$percent %';
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

/// Quitte le hub : retour à l'écran précédent, sinon à l'onglet Home.
void _leaveHub(BuildContext context, WidgetRef ref) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  ref.read(navTabProvider.notifier).select(0);
}

/// Hub des jeux sérieux : une intro « Play & discover your talent » à la
/// première visite, puis le catalogue par dimension.
class GamesHubScreen extends ConsumerWidget {
  const GamesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final introSeen = ref.watch(
      local_progress.gamesProgressProvider.select((p) => p.introSeen),
    );
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: introSeen
          ? const _GamesCatalog(key: ValueKey('games-catalog'))
          : _GamesIntro(
              key: const ValueKey('games-intro'),
              onExplore: () => ref
                  .read(local_progress.gamesProgressProvider.notifier)
                  .markIntroSeen(),
              onSkip: () => _leaveHub(context, ref),
            ),
    );
  }
}

/// Catalogue : en-tête, carte « Your journey », filtres et catégories.
class _GamesCatalog extends ConsumerStatefulWidget {
  const _GamesCatalog({super.key});

  @override
  ConsumerState<_GamesCatalog> createState() => _GamesCatalogState();
}

class _GamesCatalogState extends ConsumerState<_GamesCatalog> {
  _HubFilter _filter = _HubFilter.all;

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(gamesProgressProvider);
    final completed = progress.value?.completed;
    final visible = _categories
        .where((c) => _filter == _HubFilter.all || c.filter == _filter)
        .toList(growable: false);

    return Scaffold(
      backgroundColor: _hub(context).surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _GamesHeader(onBack: () => _leaveHub(context, ref)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: [
                  _JourneyCard(progress: progress),
                  const SizedBox(height: 18),
                  _FilterBar(
                    selected: _filter,
                    onSelected: (f) => setState(() => _filter = f),
                  ),
                  const SizedBox(height: 14),
                  for (final category in visible) ...[
                    _GameCategoryCard(
                      key: ValueKey('game-category-${category.id}'),
                      category: category,
                      completed: completed,
                    ),
                    const SizedBox(height: 12),
                  ],
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
        color: _hub(context).ink,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        height: 1.18,
        letterSpacing: -0.4,
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
          color: _hub(context).card,
          borderRadius: BorderRadius.circular(16),
          elevation: 8,
          shadowColor: _hub(context).shadow.withValues(alpha: 0.10),
          child: InkWell(
            excludeFromSemantics: true,
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _hub(context).line),
              ),
              child: AppIcon(
                HugeIcons.strokeRoundedArrowLeft02,
                color: _hub(context).ink,
                size: 24,
                strokeWidth: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatar du joueur (photo de profil, sinon pastille dégradée).
class _ProfileBadge extends ConsumerWidget {
  const _ProfileBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    const fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF6B37E), Color(0xFF9B5ACF)],
        ),
      ),
      child: Center(
        child: AppIcon(
          HugeIcons.strokeRoundedUser,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
    return ExcludeSemantics(
      child: SizedBox(
        width: 58,
        height: 52,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _hub(context).card, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: _hub(context).violet.withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: user == null
                    ? fallback
                    : Image.network(
                        user.effectiveAvatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => fallback,
                      ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _hub(context).card,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _hub(context).shadow.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: AppIcon(
                    HugeIcons.strokeRoundedMenu01,
                    color: _hub(context).ink,
                    size: 13,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte « Your journey » : anneau de couverture + petit sommet illustré.
class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.progress});

  final AsyncValue<GamesProgress?> progress;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
    final known = progress.value;
    final title = kLot1DemoBuild ? 'Démo des jeux' : 'Ton parcours';
    final subtitle = kLot1DemoBuild
        ? 'Sessions d’entraînement · résultats d’exemple'
        : known == null || known.completedGames == 0
            ? 'Termine des jeux pour débloquer ton profil complet'
            : '${known.completedGames} jeux terminés sur ${known.totalGames}';
    final ratio = known == null || kLot1DemoBuild
        ? 0.0
        : known.completedGames / known.totalGames;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      decoration: BoxDecoration(
        color: _hub(context).card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _hub(context).line),
        boxShadow: [
          BoxShadow(
            color: _hub(context).violet.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _ProgressRing(
            value: ratio,
            label: kLot1DemoBuild ? '—' : _coverageLabel(progress),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.titleLarge.copyWith(
                    color: _hub(context).ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: _hub(context).muted,
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (!largeText) ...[
            const SizedBox(width: 6),
            ExcludeSemantics(
              child: SizedBox(
                width: 96,
                height: 70,
                child: CustomPaint(painter: _SummitPainter(_hub(context))),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.value, required this.label});

  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, animated, child) => CustomPaint(
          painter: _RingPainter(animated, _hub(context)),
          child: child,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FittedBox(
            child: Text(
              label,
              key: const ValueKey('games-coverage'),
              style: TextStyle(
                color: _hub(context).ink,
                fontFamily: AppTypography.fontFamily,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.value, this.palette);

  final double value;
  final _HubPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 7.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    canvas.drawArc(
      arcRect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = palette.ringTrack,
    );
    if (value <= 0) return;
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      math.pi * 2 * value.clamp(0, 1),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: [const Color(0xFFB39BFA), palette.violet],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.palette != palette;
}

/// Sommet et drapeau de la carte « Your journey ».
class _SummitPainter extends CustomPainter {
  const _SummitPainter(this.palette);

  final _HubPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Nuage.
    final cloud = Paint()..color = palette.cloud;
    canvas
      ..drawCircle(Offset(w * 0.20, h * 0.34), 6, cloud)
      ..drawCircle(Offset(w * 0.28, h * 0.30), 8, cloud)
      ..drawCircle(Offset(w * 0.36, h * 0.35), 5.5, cloud);

    Path mountain(double left, Offset top, double right) => Path()
      ..moveTo(left, h)
      ..lineTo(top.dx, top.dy)
      ..lineTo(right, h)
      ..close();

    final summit = Offset(w * 0.62, h * 0.14);

    // Montagnes : arrière, principale (avec face éclairée), avant.
    canvas.drawPath(
      mountain(w * 0.02, Offset(w * 0.30, h * 0.42), w * 0.62),
      Paint()..color = palette.mountainBack,
    );
    canvas.drawPath(
      mountain(w * 0.24, summit, w * 1.0),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9F86F7), Color(0xFF7458EC)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      mountain(w * 0.24, summit, w * 0.52),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
    canvas.drawPath(
      mountain(w * 0.58, Offset(w * 0.84, h * 0.42), w * 1.08),
      Paint()..color = palette.mountainFront,
    );

    // Drapeau au sommet.
    final pole = Offset(summit.dx, summit.dy - h * 0.22);
    canvas.drawLine(
      summit,
      pole,
      Paint()
        ..color = palette.ink.withValues(alpha: 0.55)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      Path()
        ..moveTo(pole.dx, pole.dy)
        ..lineTo(pole.dx + 13, pole.dy + 4.5)
        ..lineTo(pole.dx, pole.dy + 9)
        ..close(),
      Paint()..color = const Color(0xFFF0569B),
    );
  }

  @override
  bool shouldRepaint(_SummitPainter oldDelegate) =>
      oldDelegate.palette != palette;
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelected});

  final _HubFilter selected;
  final ValueChanged<_HubFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final filter in _HubFilter.values) ...[
            _FilterChip(
              label: filter.label,
              selected: filter == selected,
              onTap: () => onSelected(filter),
            ),
            if (filter != _HubFilter.values.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? _hub(context).chipSelected : _hub(context).card,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: selected ? _hub(context).chipSelected : _hub(context).line),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? _hub(context).onChipSelected : _hub(context).ink,
                fontFamily: AppTypography.fontFamily,
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameCategoryCard extends ConsumerWidget {
  const _GameCategoryCard({
    super.key,
    required this.category,
    required this.completed,
  });

  final _GameCategory category;

  /// Jeux terminés selon le serveur (`null` : progression inconnue).
  final Set<CatalogGame>? completed;

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    final playable = category.playable;
    if (playable.isEmpty) return;

    // Design screen 76 — anti-fraud monitoring consent, asked once.
    if (!ref.read(local_progress.gamesProgressProvider).consentGiven) {
      final agreed = await _showGamesConsentDialog(context);
      if (agreed != true) return;
      ref.read(local_progress.gamesProgressProvider.notifier).setConsent(true);
    }

    if (!context.mounted) return;
    if (category.games.length == 1) {
      await _openGame(context, playable.first.route);
    } else {
      final route = await _showGamePicker(
        context,
        category: category,
        completed: completed,
      );
      if (route == null || !context.mounted) return;
      await _openGame(context, route);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Carte inactive quand la catégorie n'a aucun jeu ouvert.
    final enabled = category.playable.isNotEmpty;
    final played = category.playedCount(completed);
    // Terminée seulement quand le serveur a enregistré chaque jeu jouable :
    // ouvrir un jeu puis revenir ne suffit pas.
    final done = category.isCompleted(completed);

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      child: Row(
        children: [
          _CategoryIconTile(category: category, done: done),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category.title,
                  style: AppTypography.titleLarge.copyWith(
                    color: _hub(context).ink,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  category.tagline,
                  style: TextStyle(
                    color: _hub(context).muted,
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _MetaLabel(
                      icon: HugeIcons.strokeRoundedClock01,
                      label: category.durationLabel,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _GameLogoStack(games: category.games),
                        const SizedBox(width: 6),
                        Text(category.gamesLabel, style: _metaStyle(context)),
                      ],
                    ),
                    if (played > 0)
                      _MetaLabel(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                        label: '$played/${category.games.length} joués',
                        color: _hub(context).success,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (enabled)
            _ChevronBubble(color: category.accent)
          else
            const _ComingSoonBadge(),
        ],
      ),
    );

    return Semantics(
      button: enabled,
      enabled: enabled,
      label: enabled ? category.title : '${category.title} — bientôt disponible',
      child: Material(
        color: _hub(context).tint(category),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: enabled ? () => _handleTap(context, ref) : null,
          borderRadius: BorderRadius.circular(22),
          splashColor: category.accent.withValues(alpha: 0.10),
          highlightColor: category.accent.withValues(alpha: 0.06),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: category.accent.withValues(alpha: done ? 0.55 : 0.12),
                width: done ? 1.4 : 1,
              ),
            ),
            child: enabled ? content : Opacity(opacity: 0.55, child: content),
          ),
        ),
      ),
    );
  }
}

class _CategoryIconTile extends StatelessWidget {
  const _CategoryIconTile({required this.category, required this.done});

  final _GameCategory category;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 68,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 68,
            height: 68,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _hub(context).card.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _hub(context).card),
            ),
            child: Image.asset(
              category.iconAsset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
          if (done)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: category.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: _hub(context).card, width: 2),
                ),
                child: const Center(
                  child: AppIcon(
                    HugeIcons.strokeRoundedTick02,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChevronBubble extends StatelessWidget {
  const _ChevronBubble({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: AppIcon(
          HugeIcons.strokeRoundedArrowRight02,
          color: color,
          size: 20,
          strokeWidth: 2.2,
        ),
      ),
    );
  }
}

TextStyle _metaStyle(BuildContext context) => TextStyle(
  color: _hub(context).muted,
  fontFamily: AppTypography.fontFamily,
  fontSize: 12.5,
  fontWeight: FontWeight.w600,
);

class _MetaLabel extends StatelessWidget {
  const _MetaLabel({required this.icon, required this.label, this.color});

  final AppIconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? _hub(context).muted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(icon, color: c, size: 15, strokeWidth: 1.8),
        const SizedBox(width: 4),
        Text(label, style: _metaStyle(context).copyWith(color: c)),
      ],
    );
  }
}

/// Petits logos superposés des jeux d'une catégorie.
class _GameLogoStack extends StatelessWidget {
  const _GameLogoStack({required this.games});

  final List<_GameEntry> games;

  static const _size = 22.0;
  static const _step = 15.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size + (games.length - 1) * _step,
      height: _size,
      child: Stack(
        children: [
          for (var i = 0; i < games.length; i++)
            Positioned(
              left: i * _step,
              child: Container(
                width: _size,
                height: _size,
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _hub(context).shadow.withValues(alpha: 0.10),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Opacity(
                  opacity: games[i].enabled ? 1 : 0.5,
                  child: _GameLogoBadge(
                    game: games[i],
                    contextName: 'category',
                    size: _size - 3,
                    iconSize: 11,
                    radius: _size,
                  ),
                ),
              ),
            ),
        ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: _hub(context).card,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Important !',
                      style: TextStyle(
                        color: _hub(context).ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(dialogContext).pop(false),
                    child: AppIcon(
                      HugeIcons.strokeRoundedCancel01,
                      color: _hub(context).muted,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Pour préserver l’intégrité des évaluations, des technologies de surveillance peuvent '
                'collecter des captures d’écran, des images de la webcam et la dynamique de frappe '
                'pendant les tests. Ces données servent uniquement à détecter l’usurpation '
                'd’identité, la triche ou la fraude.',
                style: TextStyle(color: _hub(context).muted, fontSize: 13.5, height: 1.45),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: agreed,
                    activeColor: _hub(context).violet,
                    onChanged: (v) => setState(() => agreed = v ?? false),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'Je comprends et j’accepte les conditions de surveillance.',
                        style: TextStyle(color: _hub(context).ink, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: agreed ? () => Navigator.of(dialogContext).pop(true) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hub(context).cta,
                    foregroundColor: _hub(context).onCta,
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: const Text('Continuer', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Badge « Bientôt disponible » pour les jeux et catégories pas encore ouverts.
class _ComingSoonBadge extends StatelessWidget {
  const _ComingSoonBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _hub(context).muted.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            HugeIcons.strokeRoundedLockKey,
            color: _hub(context).muted,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            'Bientôt',
            style: _metaStyle(context).copyWith(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
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
                    child: Center(
                      child: AppIcon(
                        game.fallbackIcon,
                        color: _hub(context).violet,
                        size: iconSize,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
