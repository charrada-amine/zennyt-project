import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/avatar/avatar_service.dart';

/// Circular avatar that renders [imageUrl] when present, falling back to a
/// generated avatar based on [fallbackSeed] (or a generic 'zennyt' seed).
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.imageUrl,
    this.size = 60,
    this.fallbackSeed,
  });

  final String? imageUrl;
  final double size;
  final String? fallbackSeed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasUrl = imageUrl != null && imageUrl!.isNotEmpty;
    
    final effectiveUrl = hasUrl
        ? imageUrl!
        : const AvatarService().defaultFor(fallbackSeed ?? 'zennyt');

    Widget placeholder() => Icon(
      Icons.person_rounded,
      size: size * 0.55,
      color: colors.textSecondary,
    );

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.inputFill,
        border: Border.all(color: colors.border, width: 2),
      ),
      child: Image.network(
        effectiveUrl,
        fit: BoxFit.cover,
        width: size,
        height: size,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : placeholder(),
        errorBuilder: (context, _, _) => placeholder(),
      ),
    );
  }
}
