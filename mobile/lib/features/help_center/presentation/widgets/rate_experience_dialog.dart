// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import '../../../../core/constants.dart';

class RateExperienceDialog extends StatelessWidget {
  final void Function(String rating) onRatingSelected;
  final VoidCallback? onClose;

  const RateExperienceDialog({
    super.key,
    required this.onRatingSelected,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                  child: Icon(
                    Icons.close,
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
                icon: FontAwesomeIcons.thumbsDown,
                label: l10n.poor,
              ),
              _buildRatingOption(
                icon: FontAwesomeIcons.thumbsUp,
                label: l10n.ok,
              ),
              _buildRatingOption(
                icon: FontAwesomeIcons.solidThumbsUp,
                label: l10n.great,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingOption({
    required FaIconData icon,
    required String label,
  }) {
    return GestureDetector(
      onTap: () => onRatingSelected(label),
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
              child: FaIcon(
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
