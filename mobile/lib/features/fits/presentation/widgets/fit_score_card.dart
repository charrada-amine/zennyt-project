import 'package:flutter/material.dart';

import '../../../../core/audio/sound_service.dart';
import '../../../../core/theme/theme.dart';
import 'fit_card_data.dart';
import 'fits_palette.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

/// Compact "Fit Scores" card used by the two-column browse grid (maquettes
/// « Fits pro » / « Fits job »): indigo outline, « 100% Fit score » tab
/// top-left, kebab top-right, identity block, one bold headline and grey chips.
class FitScoreCard extends StatelessWidget {
  const FitScoreCard({
    super.key,
    required this.data,
    this.onTap,
    this.onMore,
  });

  final FitCardData data;
  final VoidCallback? onTap;

  /// Kebab menu. Hidden when null (e.g. Search results reuse this card
  /// without per-card actions).
  final VoidCallback? onMore;

  bool get _isJob => data.type == FitCardType.jobOffer;

  static const _radius = 14.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final palette = FitsPalette.of(context);

    return Material(
      color: colors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
        side: BorderSide(color: palette.indigo, width: 1.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                SoundService.instance.vibrateSelection();
                onTap!();
              },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 34, 10, 10),
              child: _isJob
                  ? _jobBody(context, palette)
                  : _candidateBody(context, palette),
            ),
            if (data.badgeText != null)
              Positioned(
                top: 0,
                left: 0,
                child: _FitBadge(text: data.badgeText!, color: palette.indigo),
              ),
            if (onMore != null)
              Positioned(top: 2, right: 0, child: _Kebab(onPressed: onMore!)),
          ],
        ),
      ),
    );
  }

  Widget _candidateBody(BuildContext context, FitsPalette palette) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _CardAvatar(url: data.avatarUrl, isJob: false),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (data.subtitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    _LocationLine(text: data.subtitle),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          pipeJoined(data.primaryValue),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelMedium.copyWith(
            color: palette.title,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _Chips(labels: data.tags, palette: palette),
      ],
    );
  }

  Widget _jobBody(BuildContext context, FitsPalette palette) {
    final colors = context.colors;
    final chips = <String>[
      if (data.experienceLabel != null) data.experienceLabel!,
      if (data.contractLabel != null) data.contractLabel!,
      if (data.workplaceLabel != null) data.workplaceLabel!,
      if ((data.salaryDisplay ?? '').isNotEmpty) data.salaryDisplay!,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _CardAvatar(url: data.avatarUrl, isJob: true),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                (data.companyName ?? '').trim().isEmpty
                    ? data.primaryValue
                    : data.companyName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          data.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.titleMedium.copyWith(
            color: palette.title,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -.2,
          ),
        ),
        if (data.subtitle.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          _LocationLine(text: data.subtitle),
        ],
        const SizedBox(height: 10),
        _ChipGrid(labels: chips, salary: data.salaryDisplay, palette: palette),
      ],
    );
  }
}

class _FitBadge extends StatelessWidget {
  const _FitBadge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(10, 5, 12, 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      );
}

class _Kebab extends StatelessWidget {
  const _Kebab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 30,
        height: 30,
        child: IconButton(
          tooltip: 'More',
          onPressed: () {
            SoundService.instance.vibrateSelection();
            onPressed();
          },
          padding: EdgeInsets.zero,
          iconSize: 18,
          icon: AppIcon(
            HugeIcons.strokeRoundedMoreVertical,
            size: 18,
            strokeWidth: 2.4,
            color: context.colors.textSecondary,
          ),
        ),
      );
}

class _CardAvatar extends StatelessWidget {
  const _CardAvatar({required this.url, required this.isJob});
  final String url;
  final bool isJob;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fallback = AppIcon(
      isJob ? HugeIcons.strokeRoundedBuilding03 : HugeIcons.strokeRoundedUser,
      color: colors.primary,
      size: 16,
    );
    return Container(
      width: 30,
      height: 30,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isJob ? colors.cardSurface : colors.inputFill,
        shape: BoxShape.circle,
        border: Border.all(color: colors.border),
      ),
      child: url.isEmpty
          ? Center(child: fallback)
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(child: fallback),
            ),
    );
  }
}

class _LocationLine extends StatelessWidget {
  const _LocationLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        AppIcon(
          HugeIcons.strokeRoundedLocation01,
          size: 12,
          color: colors.textSecondary,
        ),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: colors.textSecondary,
              fontSize: 10.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.child, required this.palette, this.center = false});
  final Widget child;
  final FitsPalette palette;
  final bool center;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        alignment: center ? Alignment.center : null,
        decoration: BoxDecoration(
          color: palette.chipBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: child,
      );
}

TextStyle _chipStyle(FitsPalette palette) => AppTypography.bodySmall.copyWith(
      color: palette.chipText,
      fontSize: 10,
      fontWeight: FontWeight.w400,
      height: 1.2,
    );

/// Candidate chips flow like the maquette (« Contract · Internationally » on one
/// line, « Immediately » wrapping).
class _Chips extends StatelessWidget {
  const _Chips({required this.labels, required this.palette});
  final List<String> labels;
  final FitsPalette palette;

  @override
  Widget build(BuildContext context) {
    final shown = labels.where((l) => l.trim().isNotEmpty).take(3).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final label in shown)
          _Chip(
            palette: palette,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _chipStyle(palette),
            ),
          ),
      ],
    );
  }
}

/// Job chips sit in a 2 × 2 grid of equal cells; the salary cell paints the
/// amount bold navy and the period regular (« $25K/Mo »).
class _ChipGrid extends StatelessWidget {
  const _ChipGrid({
    required this.labels,
    required this.salary,
    required this.palette,
  });
  final List<String> labels;
  final String? salary;
  final FitsPalette palette;

  Widget _cell(String label) {
    final style = _chipStyle(palette);
    final Widget text;
    if (label == salary) {
      final (amount, period) = splitSalary(label);
      text = Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: amount,
              style: style.copyWith(
                color: palette.navy,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextSpan(text: period),
          ],
        ),
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    } else {
      text = Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    return _Chip(palette: palette, center: true, child: text);
  }

  @override
  Widget build(BuildContext context) {
    final shown = labels.where((l) => l.trim().isNotEmpty).take(4).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (var i = 0; i < shown.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _cell(shown[i])),
              const SizedBox(width: 6),
              Expanded(
                child: i + 1 < shown.length
                    ? _cell(shown[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
