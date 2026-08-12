import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/zennyt_logo.dart';

/// Split-screen shell used by all auth screens on desktop.
///
/// ```
/// ┌──────────────────────────────────────────────────┐
/// │  LEFT  (≈45 %)           │  RIGHT  (≈55 %)      │
/// │  [formContent]           │  Hero image           │
/// │  scrollable, centered,   │  + gradient overlay   │
/// │  max 480 px wide         │  + brand text         │
/// └──────────────────────────────────────────────────┘
/// ```
class AuthDesktopShell extends StatelessWidget {
  const AuthDesktopShell({
    super.key,
    required this.formContent,
    this.heroImagePath = 'assets/images/bg_office.png',
  });

  /// The scrollable form content displayed in the left panel.
  final Widget formContent;

  /// Path to the hero image shown in the right panel.
  final String heroImagePath;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: Row(
        children: [
          Expanded(
            flex: 45,
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 40,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Center(
                            child: ZennytLogo(
                              size: 48,
                              showWordmark: true,
                              showTagline: true,
                            ),
                          ),
                          const SizedBox(height: 48),
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: colors.cardSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colors.divider.withValues(alpha: 0.5),
                              ),
                            ),
                            child: formContent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Right panel: hero image ───────────────────────────────────
          Expanded(
            flex: 55,
            child: _HeroPanel(imagePath: heroImagePath),
          ),
        ],
      ),
    );
  }
}

/// The right-side hero image panel with a gradient overlay and brand text
/// at the bottom — matching the desktop maquettes.
class _HeroPanel extends StatefulWidget {
  const _HeroPanel({required this.imagePath});

  final String imagePath;

  @override
  State<_HeroPanel> createState() => _HeroPanelState();
}

class _HeroPanelState extends State<_HeroPanel> {
  int _currentIndex = 0;
  late Timer _timer;

  static const List<String> _images = [
    'assets/images/bg1.png',
    'assets/images/bg2.png',
    'assets/images/bg3.png',
    'assets/images/bg4.png',
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = _images.indexOf(widget.imagePath);
    if (_currentIndex == -1) _currentIndex = 0;

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _images.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      // Slight rounding on the left edge where it meets the form panel.
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(32),
        bottomLeft: Radius.circular(32),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image with cross-fade transition
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            child: Image.asset(
              _images[_currentIndex],
              key: ValueKey(_images[_currentIndex]),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // Gradient overlay — dark at bottom for text readability
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Color(0x80000000),
                  Color(0xCC001D55),
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),

          // G Logo at top right
          const Positioned(
            top: 40,
            right: 40,
            child: ZennytLogo(
              size: 72,
              showWordmark: false,
            ),
          ),

          // Brand text at the bottom
          Positioned(
            left: 40,
            right: 40,
            bottom: 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome to',
                  style: AppTypography.headlineSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Progress Careers',
                  style: AppTypography.displaySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Reveal your true professional potential.',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    for (int i = 0; i < _images.length; i++) ...[
                      _SliderIndicator(isActive: i == _currentIndex),
                      if (i < _images.length - 1) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderIndicator extends StatelessWidget {
  const _SliderIndicator({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 4,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(2),
        ),
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: 0.0,
            end: isActive ? 1.0 : 0.0,
          ),
          duration: isActive ? const Duration(seconds: 5) : const Duration(milliseconds: 1),
          curve: Curves.linear,
          builder: (context, value, child) {
            return FractionallySizedBox(
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
