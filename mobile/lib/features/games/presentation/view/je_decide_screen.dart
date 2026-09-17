import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/audio/sound_service.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/config/decision_config.dart';
import '../../domain/entities/decision_form.dart';
import '../../domain/entities/decision_metrics.dart';
import '../../domain/entities/game_type.dart';
import '../../domain/entities/mini_game.dart';
import '../games_controller.dart';
import '../games_providers.dart';
import '../../../navigation/presentation/viewmodel/nav_tab_provider.dart';
import '../../../navigation/presentation/widgets/app_bottom_nav.dart';
import 'je_decide_gameplay.dart';
import 'je_decide_results.dart';
import '../widgets/game_system_components.dart';
import '../widgets/je_decide_tutorial.dart';
import '../widgets/zennyt_loader.dart';

/// Durée annoncée sur la fiche d'introduction, en minutes.
///
/// Dérivée, pas estimée : chaque question est bornée par
/// [DecisionConfig.questionTimeLimitS], et la forme en compte
/// [DecisionConfig.totalItems]. C'est le seul plafond que le code garantisse.
const int _maxDurationMin =
    DecisionConfig.totalItems * DecisionConfig.questionTimeLimitS ~/ 60;

const _ink = Color(0xFF28234F);
const _muted = Color(0xFF7E8DB2);
const _border = Color(0xFFD8E2F6);
const _canvas = Color(0xFFF7F8FE);
const _magenta = Color(0xFFD52E83);
const _violet = Color(0xFF4E46E8);
const _cyan = Color(0xFF17B2C6);
const _orange = Color(0xFFFF963A);
const _softPink = Color(0xFFFFF1F7);

const _welcomeAsset = 'assets/games icons/Je Decide transparent.png';
const _avatarRoot = 'assets/04 Je Décide/07 Mobile/Avatar Selection';

enum _DecisionStage {
  welcome,
  playerCard,
  avatar,
  practiceIntro,
  practiceScenario,
  gameplay,
  results,
}

/// Parcours mobile de « Je Décide ».
///
/// Les écrans et transitions suivent les maquettes Phases 1–4. Le CONTENU, lui,
/// vient du backend : la session est ouverte après l’exemple, la forme
/// de passation (30 items sur les 120 de la banque) est récupérée par
/// `GET /decision/items`, et le score est calculé serveur à la soumission. Aucun
/// barème ne vit côté client — voir l'exception de parité en tête de
/// `games_mock_repository.dart`.
class JeDecideScreen extends ConsumerStatefulWidget {
  const JeDecideScreen({super.key});

  @override
  ConsumerState<JeDecideScreen> createState() => _JeDecideScreenState();
}

class _JeDecideScreenState extends ConsumerState<JeDecideScreen> {
  final _nicknameController = TextEditingController();

  /// Réponses effectivement données, et longueur de la forme jouée.
  int _answeredCount = 0;
  int _submittedCount = 0;

  _DecisionStage _stage = _DecisionStage.welcome;
  int _selectedTheme = 0;
  int _selectedAvatar = 0;
  int? _selectedChoice;
  DecisionForm? _form;
  bool _loadingForm = false;
  Object? _formError;

  static const _themes = [_magenta, _violet, _cyan, _orange];

  @override
  void initState() {
    super.initState();
  }

  /// Ouvre la session puis récupère les 30 items de sa forme.
  ///
  /// L'ordre est imposé : la forme est tirée serveur à la création de session,
  /// donc il n'y a rien à demander avant d'avoir un identifiant de session.
  Future<void> _openSessionAndLoadForm() async {
    if (_loadingForm || _form != null) return;
    setState(() {
      _loadingForm = true;
      _formError = null;
    });
    try {
      await ref.read(gamesControllerProvider.notifier).start(GameType.decision);
      final session = ref.read(gamesControllerProvider).value;
      if (session == null) {
        throw StateError('Session « Je Décide » non ouverte.');
      }
      final form = await ref
          .read(gamesRepositoryProvider)
          .decisionItems(session.id);
      if (!mounted) return;
      setState(() {
        _form = form;
        _loadingForm = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _formError = error;
        _loadingForm = false;
      });
    }
  }

  /// Fin de partie : les 30 réponses partent au serveur, qui note.
  Future<void> _submitJourney(List<DecisionItemResponse> responses) async {
    // Retenu pour l'écran de fin, qui annonçait « 30 / 30 » en dur — donc un
    // sans-faute même quand des questions avaient expiré.
    _answeredCount = responses.where((r) => r.answered).length;
    _submittedCount = responses.length;
    // Langue capturée AVANT le premier await : le contexte peut disparaître.
    final language = Localizations.localeOf(context).languageCode;
    await ref
        .read(gamesControllerProvider.notifier)
        .submit(
          miniGame: MiniGame.decisionCore,
          metrics: DecisionMetrics(items: responses, sessionLanguage: language),
        );
    if (!mounted) return;
    setState(() => _stage = _DecisionStage.results);
  }

  void _finishResults() => context.go(AppRoutes.games);

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  bool get _showBottomNav =>
      _stage != _DecisionStage.practiceScenario &&
      _stage != _DecisionStage.gameplay &&
      _stage != _DecisionStage.results;

  ({String eyebrow, String title}) get _headerCopy => switch (_stage) {
    _DecisionStage.welcome => (
      eyebrow: 'Decision Journey',
      title: 'Zennyt Games',
    ),
    _DecisionStage.playerCard => (
      eyebrow: 'Zennyt Games',
      title: 'Create your player card',
    ),
    _DecisionStage.avatar => (
      eyebrow: 'Zennyt Games',
      title: 'Choose your avatar',
    ),
    _DecisionStage.practiceIntro => (
      eyebrow: 'Decision Journey',
      title: 'Comment jouer',
    ),
    _DecisionStage.practiceScenario => (
      eyebrow: 'Je Décide',
      title: 'Entraînement',
    ),
    _DecisionStage.gameplay => (eyebrow: 'Decision Journey', title: 'Gameplay'),
    _DecisionStage.results => (
      eyebrow: 'Decision Journey',
      title: 'Your profile',
    ),
  };

  void _setStage(_DecisionStage stage) {
    setState(() => _stage = stage);
  }

  void _back() {
    switch (_stage) {
      case _DecisionStage.welcome:
        context.go(AppRoutes.games);
      case _DecisionStage.playerCard:
        _setStage(_DecisionStage.welcome);
      case _DecisionStage.avatar:
        _setStage(_DecisionStage.playerCard);
      case _DecisionStage.practiceIntro:
        _setStage(_DecisionStage.welcome);
      case _DecisionStage.practiceScenario:
        _setStage(_DecisionStage.practiceIntro);
      case _DecisionStage.gameplay:
        context.go(AppRoutes.games);
      case _DecisionStage.results:
        context.go(AppRoutes.games);
    }
  }

  void _selectMainTab(int index) {
    ref.read(navTabProvider.notifier).select(index);
    context.go(AppRoutes.home);
  }

  Future<void> _openJourneyMenu() async {
    SoundService.instance.playSfx(GameSfx.pauseClick);
    final action = await showGamePauseMenu<DecisionPauseAction>(
      context,
      builder: (_) => const DecisionPauseDialog(gameplayActive: false),
    );
    if (!mounted) return;
    switch (action) {
      case DecisionPauseAction.rules:
        await showDialog<void>(
          context: context,
          builder: (_) => const DecisionRulesDialog(),
        );
        if (mounted) await _openJourneyMenu();
        return;
      case DecisionPauseAction.exit:
        context.go(AppRoutes.games);
        return;
      case DecisionPauseAction.resume || null:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_stage == _DecisionStage.gameplay) {
      final form = _form;
      return Scaffold(
        backgroundColor: _canvas,
        body: form == null
            ? _DecisionLoadingView(
                error: _formError,
                onRetry: _openSessionAndLoadForm,
                onBack: () => context.go(AppRoutes.games),
              )
            : GameplayMusic(
                child: DecisionGameplayView(
                  form: form,
                  onClose: () => context.go(AppRoutes.games),
                  onComplete: _submitJourney,
                ),
              ),
      );
    }
    if (_stage == _DecisionStage.results) {
      final session = ref.watch(gamesControllerProvider).value;
      return Scaffold(
        backgroundColor: _canvas,
        body: DecisionResultsFlow(
          profile: session == null
              ? const DecisionProfile(score: 0, level: '—', dimensions: [])
              : DecisionProfile.fromSession(session),
          answered: _answeredCount,
          totalItems: _submittedCount,
          onClose: () => context.go(AppRoutes.games),
          onDone: _finishResults,
        ),
      );
    }
    final header = _headerCopy;
    return PopScope(
      canPop: _stage == _DecisionStage.welcome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor:
            _stage == _DecisionStage.practiceIntro ||
                _stage == _DecisionStage.welcome
            ? Colors.white
            : _canvas,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                key: const ValueKey('decision-journey-header'),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _DecisionHeader(
                  eyebrow: header.eyebrow,
                  title: header.title,
                  onBack: _back,
                  onMore: _openJourneyMenu,
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  key: const ValueKey('decision-stage-switcher'),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: _buildStageTransition,
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      for (final child in previous)
                        ExcludeSemantics(child: IgnorePointer(child: child)),
                      ?current,
                    ],
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_stage),
                    child: _buildStage(),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _showBottomNav
            ? AppBottomNav(selectedTab: 2, onSelect: _selectMainTab)
            : null,
      ),
    );
  }

  /// Même cadre pendant l’entrée et le retour ; faible déplacement des cartes.
  /// PROVISOIRE — continuité visuelle à valider sur appareil.
  Widget _buildStageTransition(Widget child, Animation<double> animation) {
    final fade = FadeTransition(opacity: animation, child: child);
    if (child.key != const ValueKey(_DecisionStage.welcome) &&
        child.key != const ValueKey(_DecisionStage.practiceIntro)) {
      return fade;
    }
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(
          child.key == const ValueKey(_DecisionStage.welcome) ? -0.06 : 0.06,
          0,
        ),
        end: Offset.zero,
      ).animate(animation),
      child: fade,
    );
  }

  Widget _buildStage() {
    return switch (_stage) {
      _DecisionStage.welcome => _WelcomeView(
        onStart: () => _setStage(_DecisionStage.practiceIntro),
        onCustomize: () => _setStage(_DecisionStage.playerCard),
      ),
      _DecisionStage.playerCard => _PlayerCardView(
        nicknameController: _nicknameController,
        selectedTheme: _selectedTheme,
        themes: _themes,
        onThemeSelected: (index) => setState(() => _selectedTheme = index),
        onChanged: (_) => setState(() {}),
        onContinue: () => _setStage(_DecisionStage.avatar),
      ),
      _DecisionStage.avatar => _AvatarView(
        selected: _selectedAvatar,
        onSelected: (index) => setState(() => _selectedAvatar = index),
        onContinue: () => _setStage(_DecisionStage.practiceIntro),
      ),
      _DecisionStage.practiceIntro => _PracticeIntroView(
        onStart: () => _setStage(_DecisionStage.practiceScenario),
      ),
      _DecisionStage.practiceScenario => _PracticeScenarioView(
        selectedChoice: _selectedChoice,
        onSelected: (index) => setState(() => _selectedChoice = index),
        onContinue: _selectedChoice == null
            ? null
            : () {
                _setStage(_DecisionStage.gameplay);
                unawaited(_openSessionAndLoadForm());
              },
      ),
      _DecisionStage.gameplay => const SizedBox.shrink(),
      _DecisionStage.results => const SizedBox.shrink(),
    };
  }
}

class _DecisionHeader extends StatelessWidget {
  const _DecisionHeader({
    required this.eyebrow,
    required this.title,
    required this.onBack,
    required this.onMore,
  });

  final String eyebrow;
  final String title;
  final VoidCallback onBack;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 72),
      child: Row(
        children: [
          _HeaderButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: Icons.chevron_left_rounded,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(color: _muted),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleLarge.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _HeaderMoreButton(onPressed: onMore),
        ],
      ),
    );
  }
}

class _HeaderMoreButton extends StatelessWidget {
  const _HeaderMoreButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open journey menu',
      child: IconButton(
        key: const ValueKey('decision-more-menu'),
        tooltip: 'Journey menu',
        // Ce bouton ouvre les règles/aide : il doit cliquer comme les autres.
        // `IconButton` brut n'hérite pas du clic des boutons partagés.
        onPressed: () {
          SoundService.instance.playSfx(GameSfx.buttonClick);
          onPressed();
        },
        icon: const Icon(Icons.more_horiz_rounded, color: _ink, size: 28),
        style: IconButton.styleFrom(
          fixedSize: const Size(48, 48),
          backgroundColor: Colors.white,
          side: const BorderSide(color: _border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: IconButton(
        tooltip: tooltip,
        // Flèche retour de l'en-tête, présente sur presque tous les écrans du
        // parcours : `IconButton` brut n'hérite pas du clic des boutons
        // partagés, elle était donc muette partout.
        onPressed: () {
          SoundService.instance.playSfx(GameSfx.buttonClick);
          onPressed();
        },
        icon: Icon(icon, color: _ink, size: 28),
        style: IconButton.styleFrom(
          fixedSize: const Size(48, 48),
          backgroundColor: Colors.white,
          side: const BorderSide(color: _border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}

class _WelcomeView extends StatelessWidget {
  const _WelcomeView({required this.onStart, required this.onCustomize});

  final VoidCallback onStart;
  final VoidCallback onCustomize;

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      _welcomeAsset,
      key: const ValueKey('je-decide-welcome-logo'),
      width: 124,
      height: 148,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      excludeFromSemantics: true,
    );
    final introduction = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Je Décide',
          style: AppTypography.displayMedium.copyWith(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choisis face à des situations du quotidien pour découvrir ton style de décision.',
          style: AppTypography.bodyLarge.copyWith(
            color: Colors.white,
            height: 1.35,
          ),
        ),
      ],
    );
    return GameContentFrame(
      child: _ScrollableStage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _violet,
                borderRadius: BorderRadius.circular(24),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 280 ||
                      MediaQuery.textScalerOf(context).scale(16) > 24) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: logo),
                        const SizedBox(height: 16),
                        introduction,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: introduction),
                      const SizedBox(width: 12),
                      logo,
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Plafond dérivé du nombre d’items et de leur délai ordinaire.
            const _SurfaceCard(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Durée',
                    value: 'Jusqu’à $_maxDurationMin min',
                  ),
                  _InfoRow(
                    label: 'Parcours',
                    value: '${DecisionConfig.totalItems} questions',
                    divider: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'À la fin : un profil en ${DecisionConfig.capabilitiesCount} dimensions. '
              'Les cotations encore provisoires sont signalées.',
              style: AppTypography.bodySmall.copyWith(color: _ink, height: 1.4),
            ),
            const SizedBox(height: 12),
            const _PrivacyNote(),
            const SizedBox(height: 16),
            GamePrimaryButton(
              key: const ValueKey('welcome-start'),
              label: 'Commencer',
              onPressed: onStart,
            ),
            const SizedBox(height: 10),
            GameOutlineButton(
              key: const ValueKey('welcome-customize'),
              label: 'Personnaliser (facultatif)',
              onPressed: onCustomize,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.divider = true,
  });

  final String label;
  final String value;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        border: divider
            ? const Border(bottom: BorderSide(color: _border))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: _muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: _ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerCardView extends StatelessWidget {
  const _PlayerCardView({
    required this.nicknameController,
    required this.selectedTheme,
    required this.themes,
    required this.onThemeSelected,
    required this.onChanged,
    required this.onContinue,
  });

  final TextEditingController nicknameController;
  final int selectedTheme;
  final List<Color> themes;
  final ValueChanged<int> onThemeSelected;
  final ValueChanged<String> onChanged;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final nickname = nicknameController.text.trim();
    return _ScrollableStage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose how you want to appear during this journey.',
            style: AppTypography.bodyLarge.copyWith(
              color: _muted,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 18),
          _SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel('Nickname'),
                const SizedBox(height: 10),
                TextField(
                  controller: nicknameController,
                  onChanged: onChanged,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Your nickname',
                    hintStyle: AppTypography.bodyLarge.copyWith(
                      color: _muted.withValues(alpha: 0.65),
                    ),
                    filled: true,
                    fillColor: _canvas,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 20,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: _border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: _magenta, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                const _FieldLabel('Avatar preview'),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _canvas,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      _PlayerMark(color: themes[selectedTheme]),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nickname.isEmpty ? 'Your player card' : nickname,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleLarge.copyWith(
                                color: _ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Private nickname and guide\nfor the journey.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const _FieldLabel('Color theme'),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 18,
                  children: List.generate(
                    themes.length,
                    (index) => Semantics(
                      button: true,
                      selected: index == selectedTheme,
                      label: 'Color theme ${index + 1}',
                      child: InkWell(
                        // Pastille de couleur : c'est un choix, il doit
                        // s'entendre comme les autres sélections.
                        onTap: () {
                          SoundService.instance.playSfx(GameSfx.buttonClick);
                          onThemeSelected(index);
                        },
                        customBorder: const CircleBorder(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: themes[index],
                            shape: BoxShape.circle,
                            border: index == selectedTheme
                                ? Border.all(color: _ink, width: 4)
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 34),
                const _PrivacyNote(),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GamePrimaryButton(
            key: const ValueKey('player-continue'),
            label: 'Continue',
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.titleMedium.copyWith(
        color: _ink,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PlayerMark extends StatelessWidget {
  const _PlayerMark({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4FF),
        shape: BoxShape.circle,
        border: Border.all(color: _border),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Container(
              width: 13,
              height: 13,
              decoration: const BoxDecoration(
                color: _cyan,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarView extends StatelessWidget {
  const _AvatarView({
    required this.selected,
    required this.onSelected,
    required this.onContinue,
  });

  final int selected;
  final ValueChanged<int> onSelected;
  final VoidCallback onContinue;

  static const _avatars = [
    (
      label: 'Navigator',
      icon: '$_avatarRoot/Icon_Avatar_Navigator.png',
      card: null,
    ),
    (
      label: 'Analyst',
      icon: null,
      card: '$_avatarRoot/Avatar card/Analyst.png',
    ),
    (
      label: 'Explorer',
      icon: '$_avatarRoot/Icon_Avatar_Explorer.png',
      card: null,
    ),
    (
      label: 'Strategist',
      icon: '$_avatarRoot/Icon_Avatar_Strategist.png',
      card: null,
    ),
    (
      label: 'Pathfinder',
      icon: null,
      card: '$_avatarRoot/Avatar card/Pathfinder.png',
    ),
    (
      label: 'Observer',
      icon: '$_avatarRoot/Icon_Avatar_Observer.png',
      card: null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _ScrollableStage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pick a guide for your decision journey.',
            style: AppTypography.bodyLarge.copyWith(
              color: _muted,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 22),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _avatars.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 18,
              childAspectRatio: 176 / 124,
            ),
            itemBuilder: (context, index) {
              final avatar = _avatars[index];
              return _AvatarCard(
                key: ValueKey('avatar-$index'),
                label: avatar.label,
                iconAsset: avatar.icon,
                cardAsset: avatar.card,
                selected: selected == index,
                onTap: () => onSelected(index),
              );
            },
          ),
          const SizedBox(height: 28),
          GamePrimaryButton(
            key: const ValueKey('avatar-continue'),
            label: 'Continue',
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _AvatarCard extends StatelessWidget {
  const _AvatarCard({
    super.key,
    required this.label,
    required this.iconAsset,
    required this.cardAsset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? iconAsset;
  final String? cardAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label avatar',
      child: Material(
        color: selected ? _softPink : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          // Choix d'avatar : sélection sonorisée comme le reste du parcours.
          onTap: () {
            SoundService.instance.playSfx(GameSfx.buttonClick);
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (cardAsset != null)
                Padding(
                  padding: const EdgeInsets.all(1),
                  child: Image.asset(
                    cardAsset!,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                  ),
                )
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      iconAsset!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      style: AppTypography.titleMedium.copyWith(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? _magenta : _border,
                    width: selected ? 2.5 : 1,
                  ),
                ),
              ),
              if (selected)
                const Positioned(top: 12, right: 12, child: _SelectedMark()),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedMark extends StatelessWidget {
  const _SelectedMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(color: _magenta, shape: BoxShape.circle),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 19),
    );
  }
}

class _PracticeIntroView extends StatelessWidget {
  const _PracticeIntroView({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => GameContentFrame(
    child: JeDecideTutorial(
      leading: const SizedBox.shrink(),
      showHeader: false,
      onComplete: onStart,
    ),
  );
}

class _PracticeScenarioView extends StatelessWidget {
  const _PracticeScenarioView({
    required this.selectedChoice,
    required this.onSelected,
    required this.onContinue,
  });

  final int? selectedChoice;
  final ValueChanged<int> onSelected;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _SurfaceCard(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _softPink,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: _magenta.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            'Exemple d’entraînement',
                            style: AppTypography.bodyMedium.copyWith(
                              color: _magenta,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Choosing a route',
                          style: AppTypography.displaySmall.copyWith(
                            color: _ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'You’re heading to an important meeting. One route is faster but less predictable. Another is slower but more reliable. Which one would you choose?',
                          style: AppTypography.bodyLarge.copyWith(
                            color: _ink,
                            fontSize: 18,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _ChoiceCard(
                    key: const ValueKey('choice-faster'),
                    title: 'Faster route',
                    subtitle: 'Shorter travel time • Less predictable',
                    selected: selectedChoice == 0,
                    onTap: () => onSelected(0),
                  ),
                  const SizedBox(height: 18),
                  _ChoiceCard(
                    key: const ValueKey('choice-reliable'),
                    title: 'Reliable route',
                    subtitle: 'Longer travel time • More predictable',
                    selected: selectedChoice == 1,
                    onTap: () => onSelected(1),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Your choice is saved when you tap a card.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: _muted,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          GamePrimaryButton(
            key: const ValueKey('practice-continue'),
            label: 'Continue',
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$title. $subtitle',
      child: Material(
        color: selected ? _softPink : Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          // Carte de choix (mode de jeu / consentement) : même clic que les
          // boutons partagés.
          onTap: () {
            SoundService.instance.playSfx(GameSfx.buttonClick);
            onTap();
          },
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 108),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected ? _magenta : _border,
                width: selected ? 2.5 : 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D1E2857),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleLarge.copyWith(
                          color: _ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: AppTypography.bodyMedium.copyWith(
                          color: _muted,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected) const _SelectedMark(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bolt_rounded, color: _magenta, size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'Tes choix restent privés.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge.copyWith(color: _ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1E2857),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ScrollableStage extends StatelessWidget {
  const _ScrollableStage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      child: child,
    );
  }
}

/// Attente (ou échec) du chargement de la forme de passation.
///
/// « Je Décide » est le seul jeu du module qui exige le backend : sa banque de
/// 120 items et sa clé de correction ne sont pas embarquées dans l'application.
/// L'échec est donc affiché tel quel plutôt que masqué par un contenu de repli.
class _DecisionLoadingView extends StatelessWidget {
  const _DecisionLoadingView({
    required this.error,
    required this.onRetry,
    required this.onBack,
  });

  final Object? error;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    if (error == null) {
      return const Center(
        key: ValueKey('decision-loading-form'),
        child: ZennytLoader(),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          key: const ValueKey('decision-form-error'),
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: _muted),
            const SizedBox(height: 16),
            Text(
              'Journey unavailable',
              style: AppTypography.headlineSmall.copyWith(
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The decision scenarios are served by Zennyt and could not be '
              'loaded. Check your connection and try again.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: _muted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            GamePrimaryButton(
              key: const ValueKey('decision-retry-form'),
              label: 'Try again',
              onPressed: onRetry,
            ),
            const SizedBox(height: 10),
            GameOutlineButton(label: 'Back to games', onPressed: onBack),
          ],
        ),
      ),
    );
  }
}
