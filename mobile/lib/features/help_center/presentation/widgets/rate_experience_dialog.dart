// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import 'package:zennyt/l10n/gen/app_localizations.dart';
import '../../../../core/constants.dart';
import '../../domain/entities/help_chat.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

class RateExperienceDialog extends StatelessWidget {
  /// Emet un jeton stable, pas le libelle affiche : celui-ci est traduit, et envoyer
  /// « Mediocre » au serveur le ferait rejeter des que l'application passe en francais.
  final void Function(HelpChatRating rating) onRatingSelected;
  final VoidCallback? onClose;

  const RateExperienceDialog({
    super.key,
    required this.onRatingSelected,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.infoSoft,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.rateYourExperience,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  fontFamily: 'inter',
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: AppIcon(
                    HugeIcons.strokeRoundedCancel01,
                    size: 16,
                    color: context.colors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
      
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildRatingOption(
                icon: HugeIcons.strokeRoundedThumbsDown,
                label: l10n.poor,
                rating: HelpChatRating.poor,
              ),
              _buildRatingOption(
                icon: HugeIcons.strokeRoundedThumbsUp,
                label: l10n.ok,
                rating: HelpChatRating.ok,
              ),
              _buildRatingOption(
                icon: AppIcons.thumbsUpFilled,
                label: l10n.great,
                rating: HelpChatRating.great,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingOption({
    required AppIconData icon,
    required String label,
    required HelpChatRating rating,
  }) {
    return GestureDetector(
      onTap: () => onRatingSelected(rating),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Center(
              child: AppIcon(
                icon,
                size: 24,
                color: AppColors.chipSelected,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.chipSelected,
              fontFamily: 'inter',
            ),
          ),
        ],
      ),
    );
  }
}
