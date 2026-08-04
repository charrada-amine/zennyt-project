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
import '../widgets/filter_selector.dart';
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
                borderRadius: BorderRadius.circular(20)),
            title: const Text("🎉  It's a Match !",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: Color(0xFF21438A))),
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
                Text(card.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('Vous vous êtes mutuellement sélectionnés.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 13, color: Color(0xFF7A869A))),
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
        recruiterSwipeDeckProvider, FitCardData.fromCandidate);
    final jobsAsync = ref.watch(jobOffersProvider);
    final jobs = jobsAsync.asData?.value ?? [];

    if (jobsAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (jobs.isEmpty) {
      return _buildEmptyPrompt(
        title: 'No job offers yet',
        message: 'Create a job offer first to start sourcing candidates.',
      );
    }

    final deckAsync = ref.watch(recruiterSwipeDeckProvider);

    return _buildScaffold(
      context: context,
      jobContextChips: _JobContextSelector(jobs: jobs),
      deckAsync: deckAsync,
      toCardData: (c) => FitCardData.fromCandidate(c),
      suggestionsTitle: 'Fit Scores',
      onSwipeLeft: () => ref.read(recruiterSwipeDeckProvider.notifier).swipeLeft(),
      onSwipeRight: () => ref.read(recruiterSwipeDeckProvider.notifier).swipeRight(),
      onUndo: () => ref.read(recruiterSwipeDeckProvider.notifier).undo(),
      onForward: () => ref.read(recruiterSwipeDeckProvider.notifier).skip(),
    );
  }

  Widget _buildCandidateView(BuildContext context) {
    _listenForMatch<JobOffer>(
        candidateSwipeDeckProvider, FitCardData.fromJobOffer);
    final deckAsync = ref.watch(candidateSwipeDeckProvider);

    return _buildScaffold(
      context: context,
      jobContextChips: null,
      deckAsync: deckAsync,
      toCardData: (j) => FitCardData.fromJobOffer(j),
      suggestionsTitle: 'Recommended for you',
      onSwipeLeft: () => ref.read(candidateSwipeDeckProvider.notifier).swipeLeft(),
      onSwipeRight: () => ref.read(candidateSwipeDeckProvider.notifier).swipeRight(),
      onUndo: () => ref.read(candidateSwipeDeckProvider.notifier).undo(),
      onForward: () => ref.read(candidateSwipeDeckProvider.notifier).skip(),
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
  }) {
    final remaining = deckAsync.asData?.value.remaining ?? const [];
    final canUndo = deckAsync.asData?.value.canUndo ?? false;
    final cards = remaining.map(toCardData).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Fits',
        trailingAction: const SessionAvatar(),
      ),
      body: PageView(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        physics: const BouncingScrollPhysics(),
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SearchFilterBar(),
                if (jobContextChips != null) ...[
                  const SizedBox(height: 12),
                  jobContextChips,
                ],
                const SizedBox(height: 18),
                Text(
                  suggestionsTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),
                const FilterSelector(),
                const SizedBox(height: 16),
                FitScoresGrid(items: cards),
                const SizedBox(height: 4),
                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'View more',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    ),
                    icon: const Icon(Icons.bolt, size: 18),
                    label: const Text('Open Matching Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_up_rounded, color: Color(0xFF64748B), size: 28),
                      onPressed: () => _pageController.animateToPage(
                        0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: deckAsync.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : cards.isEmpty
                          ? const Center(
                              child: Text(
                                'No more matches found.',
                                style: TextStyle(color: Color(0xFF7A869A), fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                            )
                          : Stack(
                              clipBehavior: Clip.none,
                              children: [
                                if (cards.length > 1)
                                  Positioned.fill(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 12, bottom: 4, left: 8, right: 8),
                                      child: Transform.scale(
                                        scale: 0.96,
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
    );
  }

  Widget _buildEmptyPrompt({required String title, required String message}) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(title: 'Fits'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
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
      height: 34,
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
                color: isSelected ? const Color(0xFF1B3B7B) : const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Sourcing: ${job.title}',
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
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
