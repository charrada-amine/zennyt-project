import 'package:flutter/widgets.dart';

/// Lightweight responsive helpers so the UI adapts across phones (small to
/// large) and tablets without hard-coding pixel positions.
///
/// The maquette relies primarily on fluid layouts; this utility only handles
/// breakpoint-aware padding and a max content width so forms stay readable on
/// wide screens (tablets / foldables / landscape).
class Responsive {
  Responsive._();

  /// Breakpoint above which we treat the device as a tablet.
  static const double tabletBreakpoint = 600;

  /// Largest width a single column of content should occupy. On wider screens
  /// content is centered within this width.
  static const double maxContentWidth = 480;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  /// Horizontal padding that grows slightly on larger screens.
  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= tabletBreakpoint) return 32;
    if (width >= 400) return 24;
    return 20;
  }

  /// Scales a value down on very small screens (e.g. iPhone SE) to avoid
  /// overflow, capped at the original value on normal screens.
  static double scale(BuildContext context, double value) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 340) return value * 0.85;
    if (width <= 375) return value * 0.93;
    return value;
  }
}

/// Centers and constrains its [child] to [Responsive.maxContentWidth] so the
/// layout looks intentional on tablets and large screens.
class CenteredConstrainedBox extends StatelessWidget {
  const CenteredConstrainedBox({
    super.key,
    required this.child,
    this.maxWidth = Responsive.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
