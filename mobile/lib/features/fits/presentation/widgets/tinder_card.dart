import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/audio/sound_service.dart';
import '../../../../core/theme/theme.dart';
import 'fit_card_data.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

/// Direct manipulation on the horizontal axis leaves the card's detail scroll free.
class TinderCard extends StatefulWidget {
  const TinderCard({
    super.key,
    required this.data,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.isFront,
  });
  final FitCardData data;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final bool isFront;

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
      final content = FitCardContent(data: widget.data);
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
              if (_dragging && progress > .1)
                Positioned(
                  top: 20,
                  right: _drag > 0 ? 20 : null,
                  left: _drag < 0 ? 20 : null,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: progress,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _drag > 0
                              ? context.colors.success
                              : context.colors.accent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: AppIcon(
                          _drag > 0 ? HugeIcons.strokeRoundedTick02 : HugeIcons.strokeRoundedCancel01,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
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

/// One readable detail composition, reused by the swipe deck and browse sheets.
class FitCardContent extends StatelessWidget {
  const FitCardContent({super.key, required this.data});
  final FitCardData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final d = data;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _FitAvatar(data: d, size: 58),
                const Spacer(),
                if (d.badgeText != null)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: .09),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        d.badgeText!,
                        style: AppTypography.labelMedium.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              d.title,
              style: AppTypography.displaySmall.copyWith(
                color: colors.textDarkBlue,
                fontWeight: FontWeight.w700,
                letterSpacing: -.9,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                AppIcon(
                  HugeIcons.strokeRoundedLocation01,
                  size: 17,
                  color: colors.textMuted,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    d.subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: .06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.primaryLabel,
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    d.primaryValue,
                    style: AppTypography.titleMedium.copyWith(
                      color: colors.textDarkBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _Details(title: d.section1Title, stats: d.section1Stats),
            if (d.section2Stats.isNotEmpty) ...[
              const SizedBox(height: 24),
              _Details(title: d.section2Title, stats: d.section2Stats),
            ],
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: d.tags.map((tag) => Chip(label: Text(tag))).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.title, required this.stats});
  final String title;
  final List<FitCardStat> stats;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: AppTypography.titleSmall.copyWith(
          color: context.colors.textDarkBlue,
        ),
      ),
      const SizedBox(height: 12),
      for (final stat in stats)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  stat.label,
                  style: AppTypography.bodySmall.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  stat.value,
                  textAlign: TextAlign.end,
                  style: AppTypography.labelMedium.copyWith(
                    color: context.colors.textDarkBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class _FitAvatar extends StatelessWidget {
  const _FitAvatar({required this.data, required this.size});
  final FitCardData data;
  final double size;
  @override
  Widget build(BuildContext context) {
    final fallback = AppIcon(
      data.type == FitCardType.candidate
          ? HugeIcons.strokeRoundedUser
          : HugeIcons.strokeRoundedBuilding03,
      color: context.colors.primary,
      size: size * .45,
    );
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.colors.inputFill,
        borderRadius: BorderRadius.circular(size * .3),
      ),
      child: data.avatarUrl.isEmpty
          ? fallback
          : Image.network(
              data.avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}
