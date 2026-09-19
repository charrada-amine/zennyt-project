import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../../../core/audio/sound_service.dart';
import '../../../../core/theme/theme.dart';
import 'fit_card_data.dart';
import 'fits_palette.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

/// Direct manipulation on the horizontal axis leaves the card's detail scroll free.
class TinderCard extends StatefulWidget {
  const TinderCard({
    super.key,
    required this.data,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.isFront,
    this.onResume,
    this.bottomInset = 24,
  });
  final FitCardData data;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final bool isFront;

  /// Recruiter-only "Resume AI" action forwarded to [FitCardContent].
  final VoidCallback? onResume;

  /// Room kept under the card content for the overlapping action buttons.
  final double bottomInset;

  @override
  State<TinderCard> createState() => _TinderCardState();
}

class _TinderCardState extends State<TinderCard> {
  double _drag = 0;
  bool _dragging = false;
  bool _submitted = false;
  static const _thresholdFraction = .28;

  void _reset() => setState(() {
    _drag = 0;
    _dragging = false;
  });

  @override
  void didUpdateWidget(covariant TinderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.id != widget.data.id) {
      _drag = 0;
      _dragging = false;
      _submitted = false;
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final threshold = width * _thresholdFraction;
      final progress = (_drag.abs() / threshold).clamp(0.0, 1.0);
      final content = FitCardContent(
        data: widget.data,
        onResume: widget.onResume,
        bottomInset: widget.bottomInset,
      );
      if (!widget.isFront) return ExcludeSemantics(child: content);
      return GestureDetector(
        onHorizontalDragStart: _submitted
            ? null
            : (_) => setState(() => _dragging = true),
        onHorizontalDragUpdate: _submitted
            ? null
            : (details) => setState(() => _drag += details.delta.dx),
        onHorizontalDragCancel: _reset,
        onHorizontalDragEnd: _submitted
            ? null
            : (_) {
                if (_drag.abs() >= threshold) {
                  _submitted = true;
                  SoundService.instance.vibrateSelection();
                  _drag > 0 ? widget.onSwipeRight() : widget.onSwipeLeft();
                } else {
                  _reset();
                }
              },
        child: AnimatedContainer(
          duration: _dragging
              ? Duration.zero
              : AppMotion.duration(context, AppMotion.settle),
          curve: Curves.easeOutBack,
          transformAlignment: Alignment.bottomCenter,
          transform: Matrix4.identity()
            ..translateByDouble(_drag, 0, 0, 1)
            ..rotateZ(
              AppMotion.reduced(context) ? 0 : _drag / width * math.pi / 18,
            ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              content,
              if (_drag != 0 && progress > .02)
                Positioned.fill(
                  child: IgnorePointer(
                    child: _SwipeVerdictOverlay(
                      content: content,
                      progress: progress,
                      liking: _drag > 0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// Progressive blur + tint while dragging: green towards « Like » (right), red
/// towards « Pass » (left). The blur and the colour grow from the edge the card
/// is heading to and spread across it as the drag nears the commit threshold.
class _SwipeVerdictOverlay extends StatelessWidget {
  const _SwipeVerdictOverlay({
    required this.content,
    required this.progress,
    required this.liking,
  });

  final Widget content;
  final double progress;
  final bool liking;

  static const _green = Color(0xFF22C55E);
  static const _red = Color(0xFFE11D48);

  @override
  Widget build(BuildContext context) {
    final color = liking ? _green : _red;
    final from = liking ? Alignment.centerRight : Alignment.centerLeft;
    final to = liking ? Alignment.centerLeft : Alignment.centerRight;
    final eased = Curves.easeOut.transform(progress);
    // The gradient front advances from the edge (0) to the far side (1).
    final reach = (.3 + .7 * eased).clamp(0.0, 1.0);
    final reduced = AppMotion.reduced(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!reduced)
            ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => LinearGradient(
                begin: from,
                end: to,
                colors: const [Colors.white, Colors.transparent],
                stops: [0, reach],
              ).createShader(rect),
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(
                  sigmaX: 5 * eased,
                  sigmaY: 5 * eased,
                  tileMode: TileMode.decal,
                ),
                child: content,
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: from,
                end: to,
                colors: [
                  color.withValues(alpha: .30 * eased),
                  color.withValues(alpha: .14 * eased),
                  color.withValues(alpha: 0),
                ],
                stops: [0, reach * .7, reach],
              ),
            ),
          ),
          Align(
            alignment: Alignment(liking ? .55 : -.55, -.35),
            child: Opacity(
              opacity: ((progress - .4) / .6).clamp(0.0, 1.0) * .9,
              child: Transform.scale(
                scale: .7 + .3 * eased,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .92),
                    border: Border.all(color: color.withValues(alpha: .6), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: .15),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Center(
                    child: AppIcon(
                      liking
                          ? HugeIcons.strokeRoundedTick02
                          : HugeIcons.strokeRoundedCancel01,
                      color: color,
                      size: 30,
                      strokeWidth: 2.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One readable detail composition, reused by the swipe deck and browse sheets
/// (maquettes « Fits pro » / « Fits job-1/2 »): blue-grey card, bold navy
/// identity, dividers, magenta pills, and a periwinkle fade at the bottom that
/// the action buttons overlap.
///
/// [bottomInset] reserves room under the content for those buttons.
class FitCardContent extends StatelessWidget {
  const FitCardContent({
    super.key,
    required this.data,
    this.onResume,
    this.bottomInset = 24,
  });
  final FitCardData data;

  /// Recruiter-only "Resume AI" action on candidate cards.
  final VoidCallback? onResume;

  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final palette = FitsPalette.of(context);
    final d = data;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.deckBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 150,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [palette.deckBg, palette.deckFade],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 22, 16, bottomInset),
              child: d.type == FitCardType.jobOffer
                  ? _jobLayout(context, d, palette)
                  : _candidateLayout(context, d, palette),
            ),
          ),
        ],
      ),
    );
  }

  Widget _identity(
    BuildContext context,
    FitCardData d,
    FitsPalette palette, {
    String? company,
    Widget? trailing,
  }) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FitAvatar(data: d, size: 58),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                d.title,
                style: AppTypography.headlineMedium.copyWith(
                  color: palette.title,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.4,
                  height: 1.2,
                ),
              ),
              if ((company ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  company!,
                  style: AppTypography.bodyLarge.copyWith(
                    color: colors.textSecondary,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (d.subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                _LocationRow(text: d.subtitle),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing],
      ],
    );
  }

  Widget _candidateLayout(
    BuildContext context,
    FitCardData d,
    FitsPalette palette,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _identity(
          context,
          d,
          palette,
          trailing: onResume == null ? null : _ResumeButton(onPressed: onResume!),
        ),
        const SizedBox(height: 22),
        _LabeledValue(label: d.primaryLabel, value: pipeJoined(d.primaryValue)),
        const SizedBox(height: 14),
        const _CardDivider(),
        const SizedBox(height: 20),
        _SkillSection(title: d.section1Title, stats: d.section1Stats),
        if (d.section2Stats.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SkillSection(title: d.section2Title, stats: d.section2Stats),
        ],
        if (d.tags.isNotEmpty) ...[
          const SizedBox(height: 18),
          const _CardDivider(),
          const SizedBox(height: 18),
          _TagPills(tags: d.tags),
        ],
      ],
    );
  }

  Widget _jobLayout(BuildContext context, FitCardData d, FitsPalette palette) {
    final colors = context.colors;
    final description = (d.description ?? '').trim();
    final salary = (d.salaryDisplay ?? '').trim();
    final (amount, period) = splitSalary(salary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _identity(context, d, palette, company: d.companyName),
        const SizedBox(height: 22),
        const _CardDivider(),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionTitle('About the job'),
          const SizedBox(height: 12),
          Text(
            description,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: palette.title,
              fontSize: 14,
              height: 1.7,
            ),
          ),
        ],
        if (d.tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          _TagPills(tags: d.tags),
        ],
        const SizedBox(height: 16),
        const _CardDivider(),
        const SizedBox(height: 18),
        _SectionTitle('Salary'),
        const SizedBox(height: 10),
        Row(
          children: [
            AppIcon(
              HugeIcons.strokeRoundedDollarCircle,
              size: 22,
              color: palette.title,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: salary.isEmpty
                      ? [
                          TextSpan(
                            text: 'Not disclosed',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ]
                      : [
                          TextSpan(
                            text: amount,
                            style: const TextStyle(
                              color: FitsPalette.magenta,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: period,
                            style: TextStyle(
                              color: palette.title,
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                ),
                style: const TextStyle(fontFamily: AppTypography.fontFamily),
              ),
            ),
          ],
        ),
        if (d.postedAt != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              postedAgoLabel(d.postedAt!),
              style: AppTypography.bodySmall.copyWith(
                color: colors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTypography.titleMedium.copyWith(
          color: FitsPalette.of(context).title,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      );
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();
  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        color: FitsPalette.of(context).deckDivider,
      );
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        AppIcon(
          HugeIcons.strokeRoundedLocation01,
          size: 19,
          color: colors.textSecondary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyLarge.copyWith(
              color: colors.textSecondary,
              fontSize: 15.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _LabeledValue extends StatelessWidget {
  const _LabeledValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final title = FitsPalette.of(context).title;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyLarge.copyWith(
            color: title,
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyLarge.copyWith(
              color: title,
              fontSize: 15.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _SkillSection extends StatelessWidget {
  const _SkillSection({required this.title, required this.stats});
  final String title;
  final List<FitCardStat> stats;

  @override
  Widget build(BuildContext context) {
    final palette = FitsPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title),
        const SizedBox(height: 10),
        for (final stat in stats)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text.rich(
              TextSpan(
                style: AppTypography.bodyMedium.copyWith(
                  color: palette.title,
                  fontSize: 15,
                ),
                children: [
                  TextSpan(text: '${stat.label}: '),
                  TextSpan(
                    text: stat.value,
                    style: TextStyle(
                      color: palette.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TagPills extends StatelessWidget {
  const _TagPills({required this.tags});
  final List<String> tags;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      for (final tag in tags)
        Container(
          constraints: const BoxConstraints(minWidth: 96),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: FitsPalette.magenta,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            tag,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
    ],
  );
}

class _ResumeButton extends StatelessWidget {
  const _ResumeButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = FitsPalette.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: palette.navy,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              SoundService.instance.vibrateSelection();
              onPressed();
            },
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: AppIcon(
                  HugeIcons.strokeRoundedUserList,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Resume AI',
          style: AppTypography.bodySmall.copyWith(
            color: context.colors.textPrimary,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _FitAvatar extends StatelessWidget {
  const _FitAvatar({required this.data, required this.size});
  final FitCardData data;
  final double size;
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isJob = data.type == FitCardType.jobOffer;
    final fallback = AppIcon(
      isJob ? HugeIcons.strokeRoundedBuilding03 : HugeIcons.strokeRoundedUser,
      color: colors.primary,
      size: size * .45,
    );
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isJob ? colors.cardSurface : colors.inputFill,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: data.avatarUrl.isEmpty
          ? Center(child: fallback)
          : Image.network(
              data.avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(child: fallback),
            ),
    );
  }
}
