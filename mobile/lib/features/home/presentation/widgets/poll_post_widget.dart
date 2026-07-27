import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import 'package:zennyt/core/theme/app_color_scheme.dart';
import '../../domain/entities/post.dart';
import '../providers/poll_provider.dart';

class PollPostWidget extends ConsumerWidget {
  final String postId;
  final Poll poll;

  const PollPostWidget({
    super.key,
    required this.postId,
    required this.poll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final votes = ref.watch(pollVoteProvider);
    final selectedOptionId = votes[postId];
    final hasVoted = selectedOptionId != null ||
        poll.options.any((o) => o.isSelected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...poll.options.map((option) {
          final isThisSelected = selectedOptionId == option.id ||
              (selectedOptionId == null && option.isSelected);
          final percentage = poll.totalVotes > 0
              ? (option.voteCount / poll.totalVotes * 100).round()
              : 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: hasVoted
                  ? null
                  : () {
                      ref
                          .read(pollVoteProvider.notifier)
                          .vote(postId, option.id);
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isThisSelected
                      ? colors.pollSelectedBg
                      : colors.inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isThisSelected
                        ? colors.pollSelectedBorder
                        : colors.pollUnselectedBorder,
                    width: isThisSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isThisSelected
                              ? colors.pollSelectedBorder
                              : colors.chevron,
                          width: 2,
                        ),
                        color: isThisSelected
                            ? colors.pollSelectedBorder
                            : Colors.transparent,
                      ),
                      child: isThisSelected
                          ? Icon(
                              Icons.check,
                              size: 14,
                              color: colors.cardSurface,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: isThisSelected
                              ? colors.pollOptionTextSelected
                              : colors.pollOptionTextUnselected,
                          fontWeight: isThisSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (hasVoted) ...[
                      const SizedBox(width: 8),
                      Text(
                        '$percentage%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isThisSelected
                              ? colors.pollSelectedBorder
                              : colors.pollPercentageText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
        if (hasVoted)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${l10n.votesCount(poll.totalVotes)} · ${l10n.timeLeft(poll.duration)}',
              style: TextStyle(
                fontSize: 13,
                color: colors.pollPercentageText,
              ),
            ),
          ),
      ],
    );
  }
}
