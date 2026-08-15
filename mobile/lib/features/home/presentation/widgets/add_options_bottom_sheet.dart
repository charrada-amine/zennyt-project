import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zennyt/core/theme/theme.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import 'option_item.dart';

class AddOptionsBottomSheet {
  static void show(
    BuildContext context, {
    VoidCallback? onMediaTap,
    VoidCallback? onDocumentTap,
    VoidCallback? onPollTap,
  }) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Container(
          decoration: BoxDecoration(
            color: colors.cardSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OptionItem(
                      icon: FontAwesomeIcons.image,
                      label: l10n.mediaLabel,
                      iconColor: const Color(0xFF6366F1),
                      bgColor: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
                      onTap: () {
                        Navigator.pop(context);
                        onMediaTap?.call();
                      },
                    ),
                  ),
                  Expanded(
                    child: OptionItem(
                      icon: FontAwesomeIcons.trophy,
                      label: l10n.scoreLabel,
                      iconColor: const Color(0xFFF59E0B),
                      bgColor: isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  Expanded(
                    child: OptionItem(
                      icon: FontAwesomeIcons.userPen,
                      label: l10n.aiResumeLabel,
                      iconColor: const Color(0xFFA855F7),
                      bgColor: isDark ? const Color(0xFF3B0764) : const Color(0xFFF3E8FF),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OptionItem(
                      icon: FontAwesomeIcons.fileLines,
                      label: l10n.documentLabel,
                      iconColor: const Color(0xFF10B981),
                      bgColor: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
                      onTap: () {
                        Navigator.pop(context);
                        onDocumentTap?.call();
                      },
                    ),
                  ),
                  Expanded(
                    child: OptionItem(
                      icon: FontAwesomeIcons.squarePollVertical,
                      label: l10n.poll,
                      iconColor: const Color(0xFF0284C7),
                      bgColor: isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE),
                      onTap: () {
                        Navigator.pop(context);
                        onPollTap?.call();
                      },
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
