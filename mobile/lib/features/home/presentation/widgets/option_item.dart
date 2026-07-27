// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zennyt/core/constants.dart';

class OptionItem extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final VoidCallback onTap;

  const OptionItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.cardSurface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: context.colors.shadowColor,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: FaIcon(
              icon,
              color: AppColors.iconColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primaryGrey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
