import 'package:flutter/material.dart';

import 'package:zennyt/core/constants.dart';
import '../../../../core/theme/app_color_scheme.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

class CreatePostBottomActions extends StatelessWidget {
  final VoidCallback onAddTap;
  final VoidCallback onMediaTap;
  final double bottomInset;

  const CreatePostBottomActions({
    super.key,
    required this.onAddTap,
    required this.onMediaTap,
    required this.bottomInset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
      child: Row(
        children: [
          GestureDetector(
            onTap: onMediaTap,
            child: AppIcon(
              HugeIcons.strokeRoundedImage01,
              color: context.colors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {},
            child: AppIcon(
              HugeIcons.strokeRoundedChampion,
              color: context.colors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: onAddTap,
            child: AppIcon(
              HugeIcons.strokeRoundedAdd01,
              color: context.colors.primary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
