import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zennyt/core/constants.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../shared/widgets/initials_avatar.dart';
import '../../domain/entities/post.dart';

class CreatePostHeader extends StatelessWidget {
  final VoidCallback? onPostTap;
  final bool isPostEnabled;
  final PostVisibility visibility;
  final String avatarUrl;
  final ValueChanged<PostVisibility> onVisibilityChanged;

  const CreatePostHeader({
    super.key,
    required this.onPostTap,
    required this.isPostEnabled,
    required this.visibility,
    required this.avatarUrl,
    required this.onVisibilityChanged,
  });

  void _showVisibilityPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  AppConstants.isCupertino
                      ? CupertinoIcons.globe
                      : Icons.public,
                  color: context.colors.textPrimary,
                ),
                title: Text(l10n.publicVisibility),
                trailing: visibility == PostVisibility.public
                    ? Icon(Icons.check, color: context.colors.textPrimary)
                    : null,
                onTap: () {
                  onVisibilityChanged(PostVisibility.public);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  AppConstants.isCupertino
                      ? CupertinoIcons.person_2
                      : Icons.people_outline,
                  color: context.colors.textPrimary,
                ),
                title: Text(l10n.friendsVisibility),
                trailing: visibility == PostVisibility.friends
                    ? Icon(Icons.check, color: context.colors.textPrimary)
                    : null,
                onTap: () {
                  onVisibilityChanged(PostVisibility.friends);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _visibilityLabel(AppLocalizations l10n) {
    return visibility == PostVisibility.public
        ? l10n.publicVisibility
        : l10n.friendsVisibility;
  }

  IconData _visibilityIcon() {
    return visibility == PostVisibility.public
        ? (AppConstants.isCupertino
            ? CupertinoIcons.globe
            : Icons.public)
        : (AppConstants.isCupertino
            ? CupertinoIcons.person_2
            : Icons.people_outline);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.panelBackground,
        border: Border(
          bottom: BorderSide(color: context.colors.divider, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Icon(
              AppConstants.isCupertino ? CupertinoIcons.xmark : Icons.close,
              color: context.colors.textPrimary,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              InitialsAvatar(
                url: avatarUrl,
                size: 40,
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showVisibilityPicker(context),
                child: Row(
                  children: [
                    Icon(
                      _visibilityIcon(),
                      color: context.colors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _visibilityLabel(l10n),
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Icon(
                      AppConstants.isCupertino
                          ? CupertinoIcons.chevron_down
                          : Icons.expand_more,
                      color: context.colors.textSecondary,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: isPostEnabled ? onPostTap : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
              decoration: BoxDecoration(
                color: isPostEnabled
                    ? context.colors.brandNavy
                    : context.colors.iconDisabled,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.postAction,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
