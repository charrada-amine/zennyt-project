import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/session_avatar.dart';
import '../../../../core/enums/user_role.dart';
import '../../../auth/presentation/current_user_provider.dart';
import '../../../jobs/domain/entities/job.dart';
import '../../domain/entities/candidate_profile.dart';
import '../../domain/entities/swipe_result.dart';
import '../providers/swipe_deck_provider.dart';
import '../widgets/fit_card_data.dart';
import '../widgets/fit_scores_grid.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/zennyt_loader.dart';
import '../widgets/resume_sheet.dart';
import 'fits_swipe_view.dart';
import '../widgets/fits_palette.dart';
import '../../../navigation/presentation/viewmodel/nav_tab_provider.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

/// Écran Fits — porté depuis REC-04 (mobile/zennyt), branché sur le backend
/// intégré. Deck bidirectionnel : offres pour le candidat, candidats
/// fit-scorés pour le recruteur.
///
/// Refonte « maquettes Fits pro / Fits job » (2026-09-19) : écran fixe (sans
/// défilement) — recherche + grille Fit Scores 2 colonnes ; « View more » ouvre
/// l'interface de swipe ([FitsSwipeView]) à la place de la grille,
/// avec les onglets « Job Offers | Professionnels ». L'onglet applicable est
/// déterminé par le rôle : un candidat source des offres, un recruteur source
/// des professionnels (voir RECRUITMENT_MODULE.md, décision à valider).
class FitsScreen extends ConsumerStatefulWidget {
  const FitsScreen({super.key});

  @override
  ConsumerState<FitsScreen> createState() => _FitsScreenState();
}

class _FitsScreenState extends ConsumerState<FitsScreen> {
  String _query = '';
  bool _swiping = false;
  ContractType? _contractFilter;

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

    return _buildScaffold(
      context,
      isRecruiter: true,
      jobs: jobs,
    );
  }

  Widget _buildCandidateView(BuildContext context) {
    _listenForMatch<JobOffer>(
      candidateSwipeDeckProvider,
      FitCardData.fromJobOffer,
    );
    return _buildScaffold(context, isRecruiter: false, jobs: const []);
  }

  Widget _buildScaffold(
    BuildContext context, {
    required bool isRecruiter,
    required List<JobOffer> jobs,
  }) {
    final deck = DeckBinding.watch(ref, isRecruiter: isRecruiter);
    final colors = context.colors;
    final palette = FitsPalette.of(context);
    // Only recruiters have an offer context; watching it for a candidate would
    // hit `/recruiters/me/job-offers` for nothing (and pollute the deck load).
    final activeJob = isRecruiter ? ref.watch(activeJobContextProvider) : null;

    if (_swiping) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) setState(() => _swiping = false);
        },
        child: Scaffold(
          backgroundColor: colors.scaffoldBg,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _FitsHeader(onBack: () => setState(() => _swiping = false)),
                Expanded(child: FitsSwipeView(isRecruiter: isRecruiter)),
              ],
            ),
          ),
        ),
      );
    }

    final query = _query.trim().toLowerCase();
    var found = deck.cards
        .where(
          (card) =>
              query.isEmpty ||
              '${card.title} ${card.subtitle} ${card.primaryValue} ${card.tags.join(' ')}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
    if (!isRecruiter && _contractFilter != null) {
      found = found
          .where((card) => card.contractLabel == _contractFilter!.label)
          .toList();
    }

    final Widget results;
    if (deck.loading) {
      results = const Center(child: ZennytLoader());
    } else if (deck.hasError || deck.cards.isEmpty) {
      results = FitsDeckStatus(failed: deck.hasError, onReload: deck.onReload);
    } else if (found.isEmpty) {
      results = Align(
        alignment: Alignment.topLeft,
        child: Text(
          'No results for “$_query”.',
          style: AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
        ),
      );
    } else {
      // Pas de défilement : on n'affiche que les rangées qui tiennent (2 au
      // plus), le reste du deck se parcourt dans l'interface de swipe.
      results = LayoutBuilder(
        builder: (context, constraints) {
          final rowHeight = MediaQuery.textScalerOf(context).scale(176) + 16;
          final rows = ((constraints.maxHeight + 16) / rowHeight)
              .floor()
              .clamp(1, 2);
          return ClipRect(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
              child: FitScoresGrid(
                items: found.take(rows * 2).toList(),
                onMore: (card) => _showCardActions(
                  card,
                  isRecruiter: isRecruiter,
                  activeJob: activeJob,
                ),
                onResume: isRecruiter && activeJob != null
                    ? (card) => showCandidateResumeSheet(
                          context,
                          candidateId: card.id,
                          candidateName: card.title,
                          jobOfferId: activeJob.id,
                        )
                    : null,
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FitsHeader(
              // Onglet racine : le retour ramène à l'accueil.
              onBack: () => ref.read(navTabProvider.notifier).select(0),
              trailing: const SessionAvatar(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(36, 6, 36, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _SearchField(
                      palette: palette,
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _FilterButton(
                    palette: palette,
                    onPressed: () =>
                        _showFilters(isRecruiter: isRecruiter, jobs: jobs),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Center(child: _SegmentedTabs(isRecruiter: isRecruiter)),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Fit Scores',
                style: AppTypography.titleLarge.copyWith(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(child: results),
            if (!deck.loading && !deck.hasError && deck.cards.isNotEmpty)
              Material(
                color: palette.viewMoreBg,
                child: InkWell(
                  onTap: () => setState(() => _swiping = true),
                  child: SizedBox(
                    height: 50,
                    child: Center(
                      child: Text(
                        'View more',
                        style: AppTypography.labelLarge.copyWith(
                          color: colors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Kebab menu of one grid card. Kept to real actions per role:
  /// a recruiter hides the pair from their Fit Scores / opens the AI resume,
  /// a candidate marks the offer as "not interested" (a LEFT swipe).
  void _showCardActions(
    FitCardData card, {
    required bool isRecruiter,
    required JobOffer? activeJob,
  }) {
    if (isRecruiter && activeJob != null) {
      showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const AppIcon(HugeIcons.strokeRoundedAiBrain01),
                title: const Text('Resume AI'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  showCandidateResumeSheet(
                    context,
                    candidateId: card.id,
                    candidateName: card.title,
                    jobOfferId: activeJob.id,
                  );
                },
              ),
              ListTile(
                leading: const AppIcon(HugeIcons.strokeRoundedRemove01),
                title: const Text('Remove from Fit Scores'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _dismissCandidate(card.id, activeJob.id);
                },
              ),
            ],
          ),
        ),
      );
      return;
    }
    // Candidate-side offer card.
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const AppIcon(HugeIcons.strokeRoundedCancel01),
              title: const Text('Not interested'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _passOffer(card.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _dismissCandidate(String candidateId, String jobOfferId) async {
    try {
      await ref.read(fitsRepositoryProvider).dismissFitScore(
            candidateId: candidateId,
            jobOfferId: jobOfferId,
          );
    } catch (_) {
      // Best-effort : le rechargement ci-dessous reflète l'état serveur réel.
    }
    if (mounted) await ref.read(recruiterSwipeDeckProvider.notifier).reload();
  }

  Future<void> _passOffer(String jobOfferId) async {
    try {
      await ref.read(fitsRepositoryProvider).swipe(
            targetId: jobOfferId,
            targetType: SwipeTargetType.jobOffer,
            jobOfferId: jobOfferId,
            direction: SwipeDirection.left,
          );
    } catch (_) {
      // Best-effort : le rechargement reflète l'état serveur réel.
    }
    if (mounted) await ref.read(candidateSwipeDeckProvider.notifier).reload();
  }

  /// Filter button: recruiters pick the offer they source for; candidates
  /// narrow the deck by contract type. Both are local/behavioural, not new
  /// endpoints.
  void _showFilters({required bool isRecruiter, List<JobOffer> jobs = const []}) {
    if (isRecruiter) {
      if (jobs.isEmpty) return;
      final active = ref.read(activeJobContextProvider);
      showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text(
                  'Source candidates for',
                  style: AppTypography.titleMedium.copyWith(
                    color: context.colors.textDarkBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              for (final job in jobs)
                ListTile(
                  selected: job.id == active?.id,
                  leading: AppIcon(
                    job.id == active?.id
                        ? HugeIcons.strokeRoundedCheckmarkCircle02
                        : HugeIcons.strokeRoundedCircle,
                    color: context.colors.primary,
                  ),
                  title: Text(job.title),
                  subtitle: Text(job.locationDisplay),
                  onTap: () {
                    ref.read(selectedJobContextProvider.notifier).select(job);
                    ref.invalidate(recruiterSwipeDeckProvider);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: StatefulBuilder(
          builder: (context, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text(
                  'Contract type',
                  style: AppTypography.titleMedium.copyWith(
                    color: context.colors.textDarkBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _contractFilter == null,
                      onSelected: (_) {
                        setState(() => _contractFilter = null);
                        setSheetState(() {});
                      },
                    ),
                    for (final type in ContractType.values)
                      ChoiceChip(
                        label: Text(type.label),
                        selected: _contractFilter == type,
                        onSelected: (_) {
                          setState(() => _contractFilter = type);
                          setSheetState(() {});
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

/// « Job Offers | Professionnels » — l'onglet actif dépend du rôle : un
/// candidat source des offres, un recruteur source des professionnels. L'autre
/// onglet est affiché mais inactif (pas de dataset cross-rôle inventé).
class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.isRecruiter});
  final bool isRecruiter;

  @override
  Widget build(BuildContext context) {
    final palette = FitsPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.segmentBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tab(context, palette, 'Job Offers', selected: !isRecruiter),
          _tab(context, palette, 'Professionnels', selected: isRecruiter),
        ],
      ),
    );
  }

  Widget _tab(
    BuildContext context,
    FitsPalette palette,
    String label, {
    required bool selected,
  }) {
    return Semantics(
      selected: selected,
      enabled: selected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? palette.navy : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: selected
                ? Colors.white
                : palette.dark
                    ? context.colors.textSecondary
                    : palette.navy,
          ),
        ),
      ),
    );
  }
}

/// En-tête des maquettes : retour carré à gauche, « Fits » centré, avatar de
/// session à droite.
class _FitsHeader extends StatelessWidget {
  const _FitsHeader({required this.onBack, this.trailing});
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 76,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: colors.cardSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colors.border),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onBack,
                    child: Tooltip(
                      message: MaterialLocalizations.of(context).backButtonTooltip,
                      child: Center(
                        child: AppIcon(
                          HugeIcons.strokeRoundedArrowLeft01,
                          size: 24,
                          strokeWidth: 2,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Fits',
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge.copyWith(
                  color: FitsPalette.of(context).title,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(width: 48, child: Center(child: trailing)),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.palette, required this.onChanged});
  final FitsPalette palette;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: palette.fieldBorder),
    );
    return SizedBox(
      height: 36,
      child: TextFormField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: AppTypography.bodyMedium.copyWith(color: colors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: colors.textSecondary,
            fontSize: 14,
          ),
          isDense: true,
          filled: true,
          fillColor: colors.cardSurface,
          contentPadding: EdgeInsets.zero,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: AppIcon(
              HugeIcons.strokeRoundedSearch01,
              size: 20,
              color: colors.textSecondary,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: palette.navy, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.palette, required this.onPressed});
  final FitsPalette palette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 36,
        height: 36,
        child: Material(
          color: context.colors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: palette.navy, width: 1.3),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onPressed,
            child: Tooltip(
              message: 'Filters',
              child: Center(
                child: AppIcon(
                  HugeIcons.strokeRoundedFilterHorizontal,
                  size: 20,
                  color: palette.navy,
                ),
              ),
            ),
          ),
        ),
      );
}
