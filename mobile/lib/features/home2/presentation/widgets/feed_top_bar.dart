import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/zennyt_logo.dart';
import '../../../../core/theme/theme.dart';

/// Home feed top bar: hamburger menu, centered Zennyt Careers logo, and a
/// circular chat button.
class FeedTopBar extends StatelessWidget {
  const FeedTopBar({super.key, required this.hPadding});

  final double hPadding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        hPadding - 4,
        AppSpacing.xs,
        hPadding,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.push(AppRoutes.profileSettings),
            icon: Icon(Icons.menu_rounded, color: colors.textPrimary, size: 26),
          ),
          const Expanded(
            child: Center(
              child: ZennytLogo(
                axis: Axis.horizontal,
                showTagline: true,
                size: 30,
              ),
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.cardSurface,
              shape: BoxShape.circle,
              boxShadow: AppShadows.sm,
            ),
            child: IconButton(
              onPressed: () => context.push(AppRoutes.chats),
              icon: Icon(
                Icons.chat_bubble_rounded,
                color: colors.actionCardFilled, // Accent color
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
