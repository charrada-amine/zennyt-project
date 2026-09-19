import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/zennyt_loader.dart';
import '../../domain/entities/fit_resume.dart';
import '../providers/swipe_deck_provider.dart';

/// Opens the recruiter-facing AI resume of one candidate for the active offer
/// (`GET /candidates/{candidateId}/resume?jobOfferId=`) as a bottom sheet.
Future<void> showCandidateResumeSheet(
  BuildContext context, {
  required String candidateId,
  required String candidateName,
  required String jobOfferId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _CandidateResumeSheet(
      candidateId: candidateId,
      candidateName: candidateName,
      jobOfferId: jobOfferId,
    ),
  );
}

class _CandidateResumeSheet extends ConsumerStatefulWidget {
  const _CandidateResumeSheet({
    required this.candidateId,
    required this.candidateName,
    required this.jobOfferId,
  });

  final String candidateId;
  final String candidateName;
  final String jobOfferId;

  @override
  ConsumerState<_CandidateResumeSheet> createState() =>
      _CandidateResumeSheetState();
}

class _CandidateResumeSheetState extends ConsumerState<_CandidateResumeSheet> {
  late Future<FitResume> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(fitsRepositoryProvider).getCandidateResume(
          candidateId: widget.candidateId,
          jobOfferId: widget.jobOfferId,
        );
  }

  void _retry() {
    setState(() {
      _future = ref.read(fitsRepositoryProvider).getCandidateResume(
            candidateId: widget.candidateId,
            jobOfferId: widget.jobOfferId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .72,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: colors.dividerThick,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Resume AI',
              style: AppTypography.headlineSmall.copyWith(
                color: colors.textDarkBlue,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.candidateName,
              style: AppTypography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<FitResume>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: ZennytLoader());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Could not load the resume.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _retry,
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    );
                  }
                  final resume = snapshot.data!;
                  final locale = Localizations.localeOf(context).languageCode;
                  final soft = resume.softSkills.textFor(locale);
                  final hard = resume.hardSkills.textFor(locale);
                  return ListView(
                    children: [
                      if (soft.trim().isNotEmpty)
                        _ResumeSectionBlock(
                          title: 'Soft Skills',
                          text: soft,
                          available: resume.softSkills.available,
                        ),
                      if (hard.trim().isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _ResumeSectionBlock(
                          title: 'Hard Skills',
                          text: hard,
                          available: resume.hardSkills.available,
                        ),
                      ],
                      if (soft.trim().isEmpty && hard.trim().isEmpty)
                        Text(
                          'No AI resume available for this candidate yet.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumeSectionBlock extends StatelessWidget {
  const _ResumeSectionBlock({
    required this.title,
    required this.text,
    required this.available,
  });

  final String title;
  final String text;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  color: colors.textDarkBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (!available)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.inputFill,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Standard',
                  style: AppTypography.labelSmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          text,
          style: AppTypography.bodyMedium.copyWith(
            color: colors.textSecondary,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}
