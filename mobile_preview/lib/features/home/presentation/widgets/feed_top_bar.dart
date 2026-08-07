import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import 'progress_logo.dart';

/// Barre supérieure blanche du fil : menu, logo centré, bouton messagerie.
class FeedTopBar extends StatelessWidget implements PreferredSizeWidget {
  const FeedTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.hairline)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.push('/profile'),
                icon: const Icon(Icons.menu, color: AppTheme.navy),
              ),
              const Spacer(),
              const ProgressLogo(),
              const Spacer(),
              Container(
                margin: const EdgeInsets.only(right: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFFFDE7EF),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => context.push('/chats'),
                  icon: const Icon(Icons.chat_bubble_rounded,
                      color: AppTheme.brandPink, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
