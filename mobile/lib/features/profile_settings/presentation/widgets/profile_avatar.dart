import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// Circular avatar that renders [imageUrl] when present, falling back to a
/// neutral person icon (used while loading, on error, or when the user has no
/// avatar yet).
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.imageUrl,
    this.size = 60,
  });

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasUrl = imageUrl != null && imageUrl!.isNotEmpty;

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
      child: hasUrl
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              width: size,
              height: size,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : placeholder(),
              errorBuilder: (context, _, _) => placeholder(),
            )
          : placeholder(),
    );
  }
}
