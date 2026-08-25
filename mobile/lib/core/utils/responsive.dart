import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The three layout tiers used to serve different designs per screen size.
enum DeviceType { mobile, tablet, desktop }

/// Lightweight responsive helpers so the UI adapts across phones (small to
/// large), tablets, and desktops without hard-coding pixel positions.
///
/// The maquette relies primarily on fluid layouts; this utility handles
/// breakpoint-aware padding, device-type detection, and a max content width so
/// forms stay readable on wide screens (tablets / foldables / landscape /
/// desktop).
class Responsive {
  Responsive._();

  /// Breakpoint above which we treat the device as a tablet.
  static const double tabletBreakpoint = 600;

  /// Breakpoint above which we treat the device as a desktop.
  static const double desktopBreakpoint = 1024;

  /// Largest width a single column of content should occupy. On wider screens
  /// content is centered within this width.
  static const double maxContentWidth = 480;

  /// Returns the current [DeviceType] based on screen width.
  /// On web we always return [DeviceType.desktop] so the UI matches the
  /// Windows/desktop design (user request: web = same as Windows).
  static DeviceType deviceType(BuildContext context) {
    if (kIsWeb) return DeviceType.desktop;
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktopBreakpoint) return DeviceType.desktop;
    if (width >= tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  static bool isDesktop(BuildContext context) {
    if (kIsWeb) return true;
    return deviceType(context) == DeviceType.desktop;
  }

  static bool isTablet(BuildContext context) {
    if (kIsWeb) return false;
    return MediaQuery.sizeOf(context).width >= tabletBreakpoint;
  }

  static bool isMobile(BuildContext context) {
    if (kIsWeb) return false;
    return deviceType(context) == DeviceType.mobile;
  }

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

/// Declarative per-platform layout builder.
///
/// Each screen that needs different designs per device type wraps its build
/// with this widget. [tablet] is optional — when omitted, falls back to
/// [mobile].
///
/// ```dart
/// ResponsiveBuilder(
///   mobile:  (context) => LoginMobileLayout(),
///   desktop: (context) => LoginDesktopLayout(),
/// )
/// ```
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  /// Builder for screens narrower than [Responsive.tabletBreakpoint].
  final WidgetBuilder mobile;

  /// Builder for screens between tablet and desktop breakpoints.
  /// Falls back to [mobile] when not provided.
  final WidgetBuilder? tablet;

  /// Builder for screens at or wider than [Responsive.desktopBreakpoint].
  final WidgetBuilder desktop;

  @override
  Widget build(BuildContext context) {
    switch (Responsive.deviceType(context)) {
      case DeviceType.desktop:
        return desktop(context);
      case DeviceType.tablet:
        return (tablet ?? mobile)(context);
      case DeviceType.mobile:
        return mobile(context);
    }
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
