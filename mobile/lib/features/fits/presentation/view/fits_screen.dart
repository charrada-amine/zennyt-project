import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/session_avatar.dart';
import '../../../../core/enums/user_role.dart';
import '../../../auth/presentation/current_user_provider.dart';
import '../../../jobs/domain/entities/job.dart';
import '../../domain/entities/candidate_profile.dart';
import '../providers/swipe_deck_provider.dart';
import '../widgets/fit_card_data.dart';
import '../widgets/fit_scores_grid.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/audio/sound_service.dart';
import '../../../../core/router/app_routes.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/zennyt_loader.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/tinder_action_buttons.dart';
import '../widgets/tinder_card.dart';

/// Écran Fits — porté depuis REC-04 (mobile/zennyt), branché sur le backend
/// intégré. Deck bidirectionnel : offres pour le candidat, candidats
/// fit-scorés pour le recruteur.
class FitsScreen extends ConsumerStatefulWidget {
  const FitsScreen({super.key});

  @override
  ConsumerState<FitsScreen> createState() => _FitsScreenState();
}

class _FitsScreenState extends ConsumerState<FitsScreen> {
  final PageController _pageController = PageController();
  String _query = '';
  bool _showAll = false;
  int _mode = 0;

  void _selectMode(int mode) {
    if (_mode == mode) return;
    SoundService.instance.vibrateSelection();
    setState(() => _mode = mode);
    if (AppMotion.reduced(context)) {
      _pageController.jumpToPage(mode);
    } else {
      _pageController.animateToPage(
        mode,
        duration: AppMotion.navigation,
        curve: AppMotion.curve,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    return user.role == UserRole.recruiter
        ? _buildRecruiterView(context)
        : _buildCandidateView(context);
  }

  /// Affiche la célébration quand un swipe crée un match mutuel.
  void _listenForMatch<T>(
    dynamic provider,
    FitCardData Function(T) toCardData,
  ) {
    ref.listen<AsyncValue<SwipeDeckState<T>>>(provider, (previous, next) {
      final match = next.asData?.value.pendingMatch;
      final before = previous?.asData?.value.pendingMatch;
      if (match != null && before == null) {
        final card = toCardData(match);
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "🎉  It's a Match !",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF21438A),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFFE2E8F0),
                  backgroundImage: card.avatarUrl.isNotEmpty
                      ? NetworkImage(card.avatarUrl)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  card.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Vous vous êtes mutuellement sélectionnés.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF7A869A)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continuer'),
              ),
            ],
          ),
        );
      }
    });
  }

  Widget _buildRecruiterView(BuildContext context) {
    _listenForMatch<CandidateProfile>(
      recruiterSwipeDeckProvider,
      FitCardData.fromCandidate,
    );
    final jobsAsync = ref.watch(jobOffersProvider);
    final jobs = jobsAsync.asData?.value ?? [];

    if (jobsAsync.isLoading) {
      return const Scaffold(body: Center(child: ZennytLoader()));
    }

    if (jobsAsync.hasError) {
      return _buildEmptyPrompt(
        title: 'Could not load your offers',
        message: 'Please try again.',
        actionLabel: 'Try again',
        onAction: () => ref.invalidate(jobOffersProvider),
      );
    }

    if (jobs.isEmpty) {
      return _buildEmptyPrompt(
        title: 'No job offers yet',
        message: 'Create a job offer first to start sourcing candidates.',
        actionLabel: 'Create a job offer',
        onAction: () => context.push(AppRoutes.createJob),
      );
    }

    final deckAsync = ref.watch(recruiterSwipeDeckProvider);

    return _buildScaffold(
      context: context,
      jobContextChips: _JobContextSelector(jobs: jobs),
      deckAsync: deckAsync,
      toCardData: (c) => FitCardData.fromCandidate(c),
      suggestionsTitle: 'Fit Scores',
      onSwipeLeft: () =>
          ref.read(recruiterSwipeDeckProvider.notifier).swipeLeft(),
      onSwipeRight: () =>
          ref.read(recruiterSwipeDeckProvider.notifier).swipeRight(),
      onUndo: () => ref.read(recruiterSwipeDeckProvider.notifier).undo(),
      onForward: () => ref.read(recruiterSwipeDeckProvider.notifier).skip(),
      onReload: () => ref.read(recruiterSwipeDeckProvider.notifier).reload(),
    );
  }

  Widget _buildCandidateView(BuildContext context) {
    _listenForMatch<JobOffer>(
      candidateSwipeDeckProvider,
      FitCardData.fromJobOffer,
    );
    final deckAsync = ref.watch(candidateSwipeDeckProvider);

    return _buildScaffold(
      context: context,
      jobContextChips: null,
      deckAsync: deckAsync,
      toCardData: (j) => FitCardData.fromJobOffer(j),
      suggestionsTitle: 'Recommended for you',
      onSwipeLeft: () =>
          ref.read(candidateSwipeDeckProvider.notifier).swipeLeft(),
      onSwipeRight: () =>
          ref.read(candidateSwipeDeckProvider.notifier).swipeRight(),
      onUndo: () => ref.read(candidateSwipeDeckProvider.notifier).undo(),
      onForward: () => ref.read(candidateSwipeDeckProvider.notifier).skip(),
      onReload: () => ref.read(candidateSwipeDeckProvider.notifier).reload(),
    );
  }

  Widget _buildScaffold<T>({
    required BuildContext context,
    required Widget? jobContextChips,
    required AsyncValue<SwipeDeckState<T>> deckAsync,
    required FitCardData Function(T) toCardData,
    required String suggestionsTitle,
    required VoidCallback onSwipeLeft,
    required VoidCallback onSwipeRight,
    required VoidCallback onUndo,
    required VoidCallback onForward,
    required VoidCallback onReload,
  }) {
    final remaining = deckAsync.asData?.value.remaining ?? const [];
    final canUndo = deckAsync.asData?.value.canUndo ?? false;
    final cards = remaining.map(toCardData).toList();

    final query = _query.trim().toLowerCase();
    final found = cards
        .where(
          (card) =>
              query.isEmpty ||
              '${card.title} ${card.subtitle} ${card.primaryValue} ${card.tags.join(' ')}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
    final visibleCards = _showAll ? found : found.take(4).toList();
    final colors = context.colors;

    Widget status({required bool failed}) => Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              failed
                  ? Icons.wifi_off_rounded
                  : Icons.check_circle_outline_rounded,
              color: colors.primary,
              size: 42,
            ),
            const SizedBox(height: 16),
            Text(
              failed ? 'Could not load your matches' : 'You’re all caught up',
              textAlign: TextAlign.center,
              style: AppTypography.titleLarge.copyWith(
                color: colors.textDarkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              failed
                  ? 'Check your connection and try again.'
                  : 'Check back for new opportunities.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: failed ? 'Try again' : 'Refresh',
              onPressed: onReload,
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: const CustomAppBar(
        title: 'Fits',
        trailingAction: SessionAvatar(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: colors.inputFill,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  for (final (index, label, icon) in [
                    (0, 'Discover', Icons.grid_view_rounded),
                    (1, 'Match', Icons.style_rounded),
                  ])
                    Expanded(
                      child: Semantics(
                        selected: _mode == index,
                        child: TextButton.icon(
                          onPressed: () => _selectMode(index),
                          icon: Icon(icon, size: 18),
                          label: Text(label),
                          style: TextButton.styleFrom(
                            backgroundColor: _mode == index
                                ? colors.cardSurface
                                : Colors.transparent,
                            foregroundColor: _mode == index
                                ? colors.primary
                                : colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestionsTitle,
                        style: AppTypography.displaySmall.copyWith(
                          color: colors.textDarkBlue,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.8,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SearchFilterBar(
                        onChanged: (value) => setState(() {
                          _query = value;
                          _showAll = false;
                        }),
                      ),
                      if (jobContextChips != null) ...[
                        const SizedBox(height: 14),
                        jobContextChips,
                      ],
                      const SizedBox(height: 24),
                      if (deckAsync.isLoading)
                        const Padding(
                          padding: EdgeInsets.all(48),
                          child: Center(child: ZennytLoader()),
                        )
                      else if (deckAsync.hasError)
                        status(failed: true)
                      else if (cards.isEmpty)
                        status(failed: false)
                      else if (visibleCards.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No results for “$_query”.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        )
                      else
                        FitScoresGrid(items: visibleCards),
                      if (found.length > 4)
                        Center(
                          child: TextButton.icon(
                            onPressed: () =>
                                setState(() => _showAll = !_showAll),
                            icon: Icon(
                              _showAll
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                            ),
                            label: Text(
                              _showAll
                                  ? 'Show less'
                                  : 'View all ${found.length}',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
                  child: Column(
                    children: [
                      Expanded(
                        child: deckAsync.isLoading
                            ? const Center(child: ZennytLoader())
                            : deckAsync.hasError
                            ? status(failed: true)
                            : cards.isEmpty
                            ? status(failed: false)
                            : Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  if (cards.length > 1)
                                    Positioned.fill(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          top: 12,
                                          left: 10,
                                          right: 10,
                                        ),
                                        child: IgnorePointer(
                                          child: TinderCard(
                                            data: cards[1],
                                            onSwipeLeft: () {},
                                            onSwipeRight: () {},
                                            isFront: false,
                                          ),
                                        ),
                                      ),
                                    ),
                                  Positioned.fill(
                                    bottom: cards.length > 1 ? 10 : 0,
                                    child: TinderCard(
                                      key: ValueKey(cards.first.id),
                                      data: cards.first,
                                      onSwipeLeft: onSwipeLeft,
                                      onSwipeRight: onSwipeRight,
                                      isFront: true,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      TinderActionButtons(
                        canUndo: canUndo,
                        enabled:
                            cards.isNotEmpty &&
                            !deckAsync.isLoading &&
                            !deckAsync.hasError,
                        onUndo: onUndo,
                        onReject: onSwipeLeft,
                        onApprove: onSwipeRight,
                        onForward: onForward,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPrompt({
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      appBar: const CustomAppBar(title: 'Fits'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.colors.textSecondary),
              ),
              if (onAction != null && actionLabel != null) ...[
                const SizedBox(height: 24),
                PrimaryButton(label: actionLabel, onPressed: onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _JobContextSelector extends ConsumerWidget {
  final List<JobOffer> jobs;
  const _JobContextSelector({required this.jobs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeJobContextProvider);

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: jobs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final job = jobs[i];
          final isSelected = job.id == active?.id;
          return GestureDetector(
            onTap: () {
              ref.read(selectedJobContextProvider.notifier).select(job);
              ref.invalidate(recruiterSwipeDeckProvider);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? context.colors.primary
                    : context.colors.inputFill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Sourcing: ${job.title}',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : context.colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
