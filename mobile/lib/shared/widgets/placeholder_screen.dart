import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// Simple "coming soon" placeholder used by tabs whose screens are not built
/// yet in the maquette. Replace with the real screen when implemented.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: colors.border),
              const SizedBox(height: AppSpacing.base),
              Text(
                label,
                style: AppTypography.titleMedium.copyWith(
                  color: colors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Coming soon',
                style: AppTypography.bodySmall.copyWith(
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
