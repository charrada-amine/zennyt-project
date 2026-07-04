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

  static const _assetRoot = 'assets/04 Optimal Path';

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
                    imagePath: '$_assetRoot/image 120.png',
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
                    imagePath: '$_assetRoot/image 120-1.png',
                    swatches: const [
                      _SwatchSpec(_softBlue, Icons.apps_rounded),
                      _SwatchSpec(_magenta),
                      _SwatchSpec(_softPink),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _GameCategoryCard(
                    title: 'Decision-Making',
                    imagePath: '$_assetRoot/image 121.png',
                    swatches: const [
                      _SwatchSpec(_softSlate),
                      _SwatchSpec(_softPink),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _GameCategoryCard(
                    title: 'Executive Planning',
                    imagePath: '$_assetRoot/image 121-1.png',
                    swatches: const [
                      _SwatchSpec(_softBlue),
                      _SwatchSpec(_magenta),
                    ],
                    onTap: () => context.push(AppRoutes.gamesPlanifik),
                  ),
                  const SizedBox(height: 12),
                  _GameCategoryCard(
                    title: 'Emotional Regulation',
                    imagePath: '$_assetRoot/image 121-2.png',
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
    required this.imagePath,
    required this.swatches,
    this.onTap,
  });

  final String title;
  final String imagePath;
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
            width: 90,
            child: Image.asset(
              imagePath,
              width: 86,
              height: 86,
              fit: BoxFit.contain,
            ),
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
