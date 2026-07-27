import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zennyt/core/constants.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import 'option_item.dart';

class AddOptionsBottomSheet {
  static void show(
    BuildContext context, {
    VoidCallback? onMediaTap,
    VoidCallback? onDocumentTap,
    VoidCallback? onPollTap,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.chipUnselected,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  OptionItem(
                    icon: FontAwesomeIcons.image,
                    label: 'Media',
                    onTap: () {
                      Navigator.pop(context);
                      onMediaTap?.call();
                    },
                  ),
                  OptionItem(
                    icon: FontAwesomeIcons.trophy,
                    label: 'Score',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  OptionItem(
                    icon: FontAwesomeIcons.userPen,
                    label: 'AI Resume',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  OptionItem(
                    icon: FontAwesomeIcons.file,
                    label: 'Document',
                    onTap: () {
                      Navigator.pop(context);
                      onDocumentTap?.call();
                    },
                  ),
                  OptionItem(
                    icon: FontAwesomeIcons.squarePollVertical,
                    label: l10n.poll,
                    onTap: () {
                      Navigator.pop(context);
                      onPollTap?.call();
                    },
                  ),
                  const SizedBox(width: 60),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
