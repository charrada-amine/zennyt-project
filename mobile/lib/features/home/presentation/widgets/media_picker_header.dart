import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zennyt/core/constants.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';

class MediaPickerHeader extends StatelessWidget {
  final String albumName;
  final int selectedCount;
  final VoidCallback onAlbumTap;
  final VoidCallback? onAddTap;

  const MediaPickerHeader({
    super.key,
    required this.albumName,
    required this.selectedCount,
    required this.onAlbumTap,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAddEnabled = selectedCount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.panelBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.itemDivider, width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Icon(
              AppConstants.isCupertino ? CupertinoIcons.xmark : Icons.close,
              color: context.colors.textPrimary,
              size: 28,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onAlbumTap,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      albumName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    AppConstants.isCupertino
                        ? CupertinoIcons.chevron_down
                        : Icons.expand_more,
                    color: context.colors.textPrimary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: isAddEnabled ? onAddTap : null,
            child: Text(
              isAddEnabled
                  ? l10n.mediaAddCount(selectedCount)
                  : l10n.mediaAdd,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isAddEnabled
                    ? AppColors.primaryBlue
                    : context.colors.iconDisabled,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
