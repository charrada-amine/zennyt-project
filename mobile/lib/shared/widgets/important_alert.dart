import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';

class ImportantAlert extends StatelessWidget {
  final VoidCallback onClose;

  const ImportantAlert({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.important,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close, color: Colors.grey, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.importantAlertDescription,
            style: const TextStyle(color: AppColors.textDark, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
