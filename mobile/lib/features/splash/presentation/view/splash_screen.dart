import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/theme.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../onboarding/data/onboarding_local_data_source.dart';

/// Creative animated splash that mirrors the brand mark coming to life:
/// 1. the blue ring draws itself on (a "progress" arc completing),
/// 2. the magenta arrow pops in with an overshoot,
/// 3. the "ZENNYT" wordmark rises into place,
/// 4. the "Careers" tagline fades in,
/// 5. the whole lockup gives a final pulse.
///
/// Routes to onboarding (first launch only) or login once the reveal finishes.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );

  late final Animation<double> _ringSweep = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.05, 0.50, curve: Curves.easeInOutCubic),
  );
  late final Animation<double> _markScale = Tween<double>(begin: 0.6, end: 1.0)
      .animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.50, curve: Curves.easeOutBack),
        ),
      );
  late final Animation<double> _arrowPop = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.46, 0.66, curve: Curves.easeOutBack),
  );
  late final Animation<double> _wordFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.60, 0.80, curve: Curves.easeOut),
  );
  late final Animation<Offset> _wordSlide =
      Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.60, 0.82, curve: Curves.easeOutCubic),
        ),
      );
  late final Animation<double> _taglineFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.80, 0.94, curve: Curves.easeOut),
  );
  late final Animation<double> _pulse =
      TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(
            begin: 1.0,
            end: 1.06,
          ).chain(CurveTween(curve: Curves.easeOut)),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween(
            begin: 1.06,
            end: 1.0,
          ).chain(CurveTween(curve: Curves.easeIn)),
          weight: 50,
        ),
      ]).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.84, 1.0)),
      );

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _goNext();
    });
    _controller.forward();
  }

  Future<void> _goNext() async {
    if (_navigated) return;
    await Future<void>.delayed(const Duration(milliseconds: 300));

    // Wait for the session bootstrap to resolve before deciding where to go,
    // so we never race (and ping-pong with) the router's auth redirect.
    while (mounted && ref.read(authControllerProvider).isLoading) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    if (!mounted || _navigated) return;
    _navigated = true;

    // Signed in? The redirect will (also) take us home; do it here too so the
    // transition is immediate.
    if (ref.read(authControllerProvider).value != null) {
      debugPrint('SPLASH -> home (signed in)');
      context.go(AppRoutes.home);
      return;
    }
    final completed = ref.read(onboardingLocalDataSourceProvider).isCompleted();
    debugPrint('SPLASH -> ${completed ? 'login' : 'onboarding'}');
    context.go(completed ? AppRoutes.login : AppRoutes.onboarding);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: Center(
        child: ScaleTransition(
          scale: _pulse,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _markScale,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => CustomPaint(
                    size: const Size.square(96),
                    painter: _SplashMarkPainter(
                      ringProgress: _ringSweep.value,
                      arrowScale: _arrowPop.value.clamp(0.0, 1.2),
                      ringColor: const Color(0xFF21438A),
                      arrowColor: const Color(0xFFD6317A),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FadeTransition(
                opacity: _wordFade,
                child: SlideTransition(
                  position: _wordSlide,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppStrings.appName,
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 32,
                          fontWeight: AppTypography.extraBold,
                          letterSpacing: 2.6,
                          height: 1,
                        ),
                      ),
                      FadeTransition(
                        opacity: _taglineFade,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            AppStrings.appTagline,
                            style: TextStyle(
                              color: const Color(0xFFD6317A), // Brand accent
                              fontSize: 14,
                              fontWeight: AppTypography.medium,
                              letterSpacing: 1.6,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints the Zennyt mark with an animatable ring sweep (draw-on) and an
/// arrow that scales in. Colors are solid so per-frame repaints stay cheap.
class _SplashMarkPainter extends CustomPainter {
  _SplashMarkPainter({
    required this.ringProgress,
    required this.arrowScale,
    required this.ringColor,
    required this.arrowColor,
  });

  final double ringProgress;
  final double arrowScale;
  final Color ringColor;
  final Color arrowColor;

  static const double _gapStart = -70; // top-right opening
  static const double _gapEnd = 8;

  static double _rad(double deg) => deg * math.pi / 180.0;
  static Offset _onCircle(Offset c, double r, double deg) =>
      Offset(c.dx + r * math.cos(_rad(deg)), c.dy + r * math.sin(_rad(deg)));

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.22;
    final radius = size.width / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    const fullSweep = 360 - (_gapEnd - _gapStart);
    if (ringProgress > 0) {
      final bluePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth
        ..color = ringColor;
      canvas.drawArc(
        rect,
        _rad(_gapEnd),
        _rad(fullSweep * ringProgress),
        false,
        bluePaint,
      );
    }

    if (arrowScale > 0) {
      const tipDeg = -45.0;
      final tip = _onCircle(center, radius + strokeWidth * 1.25, tipDeg);
      final baseLeft = _onCircle(
        center,
        radius - strokeWidth * 0.30,
        tipDeg - 30,
      );
      final baseRight = _onCircle(
        center,
        radius - strokeWidth * 0.30,
        tipDeg + 30,
      );
      final centroid = Offset(
        (tip.dx + baseLeft.dx + baseRight.dx) / 3,
        (tip.dy + baseLeft.dy + baseRight.dy) / 3,
      );
      Offset scaled(Offset p) => Offset(
        centroid.dx + (p.dx - centroid.dx) * arrowScale,
        centroid.dy + (p.dy - centroid.dy) * arrowScale,
      );
      final t = scaled(tip);
      final l = scaled(baseLeft);
      final r = scaled(baseRight);
      final arrow = Path()
        ..moveTo(t.dx, t.dy)
        ..lineTo(l.dx, l.dy)
        ..lineTo(r.dx, r.dy)
        ..close();
      canvas.drawPath(arrow, Paint()..color = arrowColor);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashMarkPainter old) =>
      old.ringProgress != ringProgress || old.arrowScale != arrowScale;
}
