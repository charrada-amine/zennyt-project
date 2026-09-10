import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// Adds tactile depth without replacing the child's gestures or semantics.
/// A scroll/pointer cancellation releases the visual press immediately.
class AppPressScale extends StatefulWidget {
  const AppPressScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.scale = .97,
  });

  final Widget child;
  final bool enabled;
  final double scale;

  @override
  State<AppPressScale> createState() => _AppPressScaleState();
}

class _AppPressScaleState extends State<AppPressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: widget.enabled ? (_) => _setPressed(true) : null,
    onPointerUp: (_) => _setPressed(false),
    onPointerCancel: (_) => _setPressed(false),
    onPointerMove: (_) => _setPressed(false),
    child: AnimatedScale(
      scale: widget.enabled && _pressed ? widget.scale : 1,
      duration: AppMotion.duration(
        context,
        _pressed ? AppMotion.press : AppMotion.settle,
      ),
      curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
      child: widget.child,
    ),
  );
}

/// A finite entrance; it does not delay mounting, input, or network work.
class AppReveal extends StatelessWidget {
  const AppReveal({super.key, required this.child, this.distance = 14});

  final Widget child;
  final double distance;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.reveal,
      curve: AppMotion.curve,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, distance * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}
