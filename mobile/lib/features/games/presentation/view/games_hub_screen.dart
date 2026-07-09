import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../navigation/presentation/viewmodel/nav_tab_provider.dart';

const _ink = Color(0xFF25204A);
const _blue = Color(0xFF17458F);
const _magenta = Color(0xFFD72C83);
const _muted = Color(0xFF5D5D66);
const _softGray = Color(0xFFEDEDED);
const _softPink = Color(0xFFF8B8D2);
const _softBlue = Color(0xFF3E7DE8);
const _softSlate = Color(0xFFC8D3DC);

/// Hub des jeux sérieux, aligné sur l'écran Progress / Games de la maquette.
class GamesHubScreen extends ConsumerWidget {
  const GamesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(36, 26, 28, 0),
              child: _GamesHeader(
                onBack: () {
                  if (context.canPop()) {
                    context.pop();
                    return;
                  }
                  ref.read(navTabProvider.notifier).select(0);
                },
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(36, 32, 31, 26),
                children: [
                  Text(
                    'Coverage 0%',
                    style: AppTypography.headlineLarge.copyWith(
                      color: _magenta,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 26),
                  _GameCategoryCard(
                    title: 'Cognitive Flexibility',
                    illustration: _GameIllustration.flexibility,
                    swatches: const [
                      _SwatchSpec(_softBlue, Icons.near_me_rounded),
                      _SwatchSpec(_magenta),
                      _SwatchSpec(_softGray),
                    ],
                    onTap: () => context.push(AppRoutes.gamesMoveFast),
                  ),
                  const SizedBox(height: 12),
                  _GameCategoryCard(
                    title: 'Working Memory',
                    illustration: _GameIllustration.memory,
                    swatches: const [
                      _SwatchSpec(_softBlue, Icons.apps_rounded),
                      _SwatchSpec(_magenta),
                      _SwatchSpec(_softPink),
                    ],
                    onTap: () => context.push(AppRoutes.gamesInvestigate),
                  ),
                  const SizedBox(height: 12),
                  _GameCategoryCard(
                    title: 'Decision-Making',
                    illustration: _GameIllustration.decision,
                    swatches: const [
                      _SwatchSpec(_softSlate),
                      _SwatchSpec(_softPink),
                    ],
                    onTap: () => context.push(AppRoutes.gamesPredictivePuzzle),
                  ),
                  const SizedBox(height: 12),
                  _GameCategoryCard(
                    title: 'Executive Planning',
                    illustration: _GameIllustration.planning,
                    swatches: const [
                      _SwatchSpec(_softBlue),
                      _SwatchSpec(_magenta),
                    ],
                    onTap: () => context.push(AppRoutes.gamesPlanifik),
                  ),
                  const SizedBox(height: 12),
                  _GameCategoryCard(
                    title: 'Emotional Regulation',
                    illustration: _GameIllustration.emotion,
                    swatches: const [
                      _SwatchSpec(_softBlue),
                      _SwatchSpec(_magenta),
                      _SwatchSpec(_softSlate),
                    ],
                  ),
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
    return SizedBox(
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _HeaderButton(onTap: onBack),
          ),
          Text(
            'Play & discover\nyour talent',
            textAlign: TextAlign.center,
            style: AppTypography.headlineLarge.copyWith(
              color: _ink,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.3,
              letterSpacing: 0,
            ),
          ),
          const Align(alignment: Alignment.centerRight, child: _ProfileBadge()),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFF0F0F3)),
          ),
          child: const Icon(
            Icons.chevron_left_rounded,
            color: Colors.black,
            size: 32,
          ),
        ),
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 62,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF6B37E), Color(0xFF9B5ACF)],
              ),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          Positioned(
            right: -1,
            bottom: 5,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _blue, width: 2),
              ),
              child: const Icon(Icons.menu_rounded, color: _blue, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCategoryCard extends StatelessWidget {
  const _GameCategoryCard({
    required this.title,
    required this.illustration,
    required this.swatches,
    this.onTap,
  });

  final String title;
  final _GameIllustration illustration;
  final List<_SwatchSpec> swatches;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: 116,
      padding: const EdgeInsets.fromLTRB(24, 12, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _blue, width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleLarge.copyWith(
                          color: _blue,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _blue,
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final swatch in swatches) ...[
                      _Swatch(spec: swatch),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
                const Spacer(),
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      _MetaIcon(icon: Icons.timer_outlined),
                      SizedBox(width: 6),
                      Text(
                        '10-13mins',
                        style: TextStyle(
                          color: _muted,
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(width: 30),
                      _MetaIcon(icon: Icons.bar_chart_rounded),
                      SizedBox(width: 6),
                      Text(
                        'N° aptitudes',
                        style: TextStyle(
                          color: _muted,
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 94,
            height: 88,
            child: _CategoryIllustration(type: illustration),
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: content,
      ),
    );
  }
}

enum _GameIllustration { flexibility, memory, decision, planning, emotion }

class _CategoryIllustration extends StatelessWidget {
  const _CategoryIllustration({required this.type});

  final _GameIllustration type;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned(
          right: 8,
          bottom: 6,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF5FF),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        switch (type) {
          _GameIllustration.flexibility => const _FlexibilityArt(),
          _GameIllustration.memory => const _MemoryArt(),
          _GameIllustration.decision => const _DecisionArt(),
          _GameIllustration.planning => const _PlanningArt(),
          _GameIllustration.emotion => const _EmotionArt(),
        },
      ],
    );
  }
}

class _FlexibilityArt extends StatelessWidget {
  const _FlexibilityArt();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Positioned(
          top: 7,
          right: 22,
          child: _ArtIconBubble(
            icon: Icons.arrow_upward_rounded,
            color: Color(0xFF20CFAE),
            size: 48,
          ),
        ),
        const Positioned(
          left: 6,
          top: 32,
          child: _ArtIconBubble(
            icon: Icons.arrow_back_rounded,
            color: Color(0xFFD12E7D),
            size: 48,
          ),
        ),
        const Positioned(
          right: 0,
          top: 32,
          child: _ArtIconBubble(
            icon: Icons.arrow_forward_rounded,
            color: Color(0xFF4F70D6),
            size: 48,
          ),
        ),
        Positioned(
          right: 21,
          bottom: 0,
          child: _BrainLineIcon(color: _magenta.withValues(alpha: 0.75)),
        ),
      ],
    );
  }
}

class _MemoryArt extends StatelessWidget {
  const _MemoryArt();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 12,
          top: 14,
          child: Container(
            width: 42,
            height: 42,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3326204A),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: GridView.count(
              crossAxisCount: 3,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(
                9,
                (index) => Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: index.isEven ? _softPink : const Color(0xFF20CFAE),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const Positioned(
          right: 8,
          top: 8,
          child: _ArtIconBubble(
            icon: Icons.settings_rounded,
            color: Color(0xFF20CFAE),
            size: 34,
            iconSize: 22,
          ),
        ),
        const Positioned(
          right: 28,
          top: 0,
          child: _ArtIconBubble(
            icon: Icons.settings_rounded,
            color: Color(0xFF4F70D6),
            size: 24,
            iconSize: 16,
          ),
        ),
        Positioned(
          right: 8,
          bottom: 1,
          child: _BrainLineIcon(color: _softPink),
        ),
      ],
    );
  }
}

class _DecisionArt extends StatelessWidget {
  const _DecisionArt();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 14,
          top: 29,
          child: Container(
            width: 58,
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFFFF4775),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        Positioned(
          right: 20,
          top: 29,
          child: Container(
            width: 10,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF20CFAE),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        const Positioned(
          left: 5,
          top: 17,
          child: Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFFFF4775),
            size: 35,
          ),
        ),
        const Positioned(
          right: 7,
          bottom: 5,
          child: Icon(
            Icons.arrow_upward_rounded,
            color: Color(0xFF20CFAE),
            size: 35,
          ),
        ),
        const Positioned(
          right: 24,
          top: 0,
          child: _ArtIconBubble(
            icon: Icons.radio_button_checked_rounded,
            color: Color(0xFFFFD84D),
            size: 31,
            iconColor: _ink,
            iconSize: 18,
          ),
        ),
      ],
    );
  }
}

class _PlanningArt extends StatelessWidget {
  const _PlanningArt();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 10,
          top: 9,
          child: Container(
            width: 60,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3326204A),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(9),
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    padding: const EdgeInsets.all(8),
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 5,
                    physics: const NeverScrollableScrollPhysics(),
                    children: List.generate(
                      9,
                      (_) => Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDE7F1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Positioned(
          right: 8,
          bottom: 7,
          child: _ArtIconBubble(
            icon: Icons.schedule_rounded,
            color: _magenta,
            size: 42,
            iconSize: 24,
          ),
        ),
        for (final x in [23.0, 40.0, 57.0])
          Positioned(
            left: x,
            top: 4,
            child: Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmotionArt extends StatelessWidget {
  const _EmotionArt();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 6,
          top: 10,
          child: _ArtIconBubble(
            icon: Icons.sentiment_satisfied_alt_rounded,
            color: Color(0xFF00A9D6),
            size: 32,
            iconSize: 20,
          ),
        ),
        Positioned(
          left: 35,
          top: 6,
          child: _ArtIconBubble(
            icon: Icons.sentiment_neutral_rounded,
            color: Color(0xFFFFC83D),
            size: 36,
            iconSize: 22,
            iconColor: _ink,
          ),
        ),
        Positioned(
          right: 5,
          top: 10,
          child: _ArtIconBubble(
            icon: Icons.sentiment_very_dissatisfied_rounded,
            color: Color(0xFFEF5B5B),
            size: 32,
            iconSize: 20,
          ),
        ),
        Positioned(
          left: 20,
          bottom: 9,
          child: _ArtIconBubble(
            icon: Icons.mood_bad_rounded,
            color: Color(0xFFFFC83D),
            size: 34,
            iconSize: 21,
            iconColor: _ink,
          ),
        ),
        Positioned(
          right: 23,
          bottom: 7,
          child: _ArtIconBubble(
            icon: Icons.sentiment_satisfied_rounded,
            color: Color(0xFF00A9D6),
            size: 36,
            iconSize: 22,
          ),
        ),
      ],
    );
  }
}

class _ArtIconBubble extends StatelessWidget {
  const _ArtIconBubble({
    required this.icon,
    required this.color,
    this.size = 42,
    this.iconSize = 28,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x3326204A),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: iconColor, size: iconSize),
    );
  }
}

class _BrainLineIcon extends StatelessWidget {
  const _BrainLineIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 36,
      child: CustomPaint(painter: _BrainLinePainter(color)),
    );
  }
}

class _BrainLinePainter extends CustomPainter {
  const _BrainLinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final left = Path()
      ..moveTo(size.width * 0.50, size.height * 0.88)
      ..cubicTo(
        size.width * 0.10,
        size.height * 0.96,
        size.width * 0.00,
        size.height * 0.42,
        size.width * 0.22,
        size.height * 0.24,
      )
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.02,
        size.width * 0.48,
        size.height * 0.06,
        size.width * 0.50,
        size.height * 0.25,
      );
    final right = Path()
      ..moveTo(size.width * 0.50, size.height * 0.88)
      ..cubicTo(
        size.width * 0.90,
        size.height * 0.96,
        size.width * 1.00,
        size.height * 0.42,
        size.width * 0.78,
        size.height * 0.24,
      )
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.02,
        size.width * 0.52,
        size.height * 0.06,
        size.width * 0.50,
        size.height * 0.25,
      );
    canvas.drawPath(left, paint);
    canvas.drawPath(right, paint);

    for (final segment in [
      (
        Offset(size.width * 0.24, size.height * 0.48),
        Offset(size.width * 0.42, size.height * 0.38),
      ),
      (
        Offset(size.width * 0.30, size.height * 0.72),
        Offset(size.width * 0.44, size.height * 0.58),
      ),
      (
        Offset(size.width * 0.76, size.height * 0.48),
        Offset(size.width * 0.58, size.height * 0.38),
      ),
      (
        Offset(size.width * 0.70, size.height * 0.72),
        Offset(size.width * 0.56, size.height * 0.58),
      ),
    ]) {
      canvas.drawLine(segment.$1, segment.$2, paint);
    }

    canvas.drawLine(
      Offset(size.width * 0.50, size.height * 0.24),
      Offset(size.width * 0.50, size.height * 0.88),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BrainLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SwatchSpec {
  const _SwatchSpec(this.color, [this.icon]);

  final Color color;
  final IconData? icon;
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.spec});

  final _SwatchSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: spec.color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: spec.icon == null
          ? null
          : Icon(spec.icon, color: Colors.white, size: 18),
    );
  }
}

class _MetaIcon extends StatelessWidget {
  const _MetaIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, color: _muted, size: 22);
  }
}
