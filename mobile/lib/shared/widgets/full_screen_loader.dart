import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import 'zennyt_loader.dart';

class FullScreenLoader extends StatelessWidget {
  const FullScreenLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Blurred background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
          // Loader centered in the screen
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: context.colors.cardSurface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ZennytLoader(size: 48),
                const SizedBox(height: 24),
                Text(
                  'Loading...',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
