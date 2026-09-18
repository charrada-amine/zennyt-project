import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

class InitialsAvatar extends StatelessWidget {
  final double size;
  final String url;

  const InitialsAvatar({super.key, this.size = 50, required this.url});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      imageBuilder: (context, imageProvider) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
        ),
      ),
      placeholder: (context, url) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE0E0E0)),
        child: AppIcon(HugeIcons.strokeRoundedUser, size: size * 0.5, color: Colors.grey),
      ),
      errorWidget: (context, url, error) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE0E0E0)),
        child: AppIcon(HugeIcons.strokeRoundedUser, size: size * 0.5, color: Colors.grey),
      ),
    );
  }
}
