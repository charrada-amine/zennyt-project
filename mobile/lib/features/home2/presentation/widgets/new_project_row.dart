import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/theme.dart';
import 'feed_avatar.dart';

/// The "New Project" row shown beneath the top bar in the Home feed.
class NewProjectRow extends StatelessWidget {
  const NewProjectRow({super.key, required this.hPadding});

  final double hPadding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: hPadding,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const FeedAvatar(url: AppAssets.avatar1, radius: 22),
          const SizedBox(width: AppSpacing.md),
          Text(
            AppStrings.newProject,
            style: AppTypography.titleSmall.copyWith(color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}
