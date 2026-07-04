import 'package:flutter/material.dart';
import 'zennyt_logo.dart';

/// A custom animated loader inspired by the app's logo.
/// 
/// It spins smoothly and pulses slightly to indicate a loading state,
/// replacing standard circular progress indicators for a more branded experience.
class ZennytLoader extends StatefulWidget {
  const ZennytLoader({
    super.key,
    this.size = 48.0,
  });

  final double size;

  @override
  State<ZennytLoader> createState() => _ZennytLoaderState();
}

class _ZennytLoaderState extends State<ZennytLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.1)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 0.9)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50.0,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _controller.value * 2.0 * 3.141592653589793,
            child: child,
          ),
        );
      },
      child: ZennytLogo(
        size: widget.size,
        showWordmark: false,
        showTagline: false,
      ),
    );
  }
}
