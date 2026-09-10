import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// Circular network avatar used throughout the Home feed.
class FeedAvatar extends StatelessWidget {
  const FeedAvatar({super.key, required this.url, this.radius = 22});

  final String url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: context.colors.inputFill, // Background for avatar
      backgroundImage: CachedNetworkImageProvider(url),
    );
  }
}
