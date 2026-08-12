import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zennyt/core/constants.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import '../../domain/entities/job_opportunity.dart';

class JobOpportunityCard extends StatelessWidget {
  final JobOpportunity opportunity;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;
  final VoidCallback? onExploreOffer;

  const JobOpportunityCard({
    super.key,
    required this.opportunity,
    this.onConfirm,
    this.onReject,
    this.onExploreOffer,
  });

  static const _titleColor = AppColors.textDark;
  static const _linkColor = AppColors.primaryBlue;
  static const _confirmGreen = AppColors.success;

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final salaryLabel = opportunity.salary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.jobOpportunity,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onExploreOffer,
                  child: Text(
                    l10n.exploreOffer,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _linkColor,
                      decoration: TextDecoration.underline,
                      decorationColor: _linkColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: context.colors.textPrimary,
                ),
                children: [
                  TextSpan(
                    text:
                        'We are offering a ${opportunity.position} position with a salary of ',
                  ),
                  TextSpan(
                    text: salaryLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const TextSpan(text: '/Mo.'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // --- ZONE CORRIGÉE POUR LE BOUTON CONFIRM (iOS / Android) ---
                AppConstants.isCupertino
                    ? Expanded(
                        child: CupertinoButton(
                          onPressed: onConfirm,
                          color: _confirmGreen, // Vert iOS direct
                          borderRadius: BorderRadius.circular(100),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          disabledColor: context.colors.border, // Couleur si onConfirm est null
                          child: Text(
                            l10n.confirmOffer,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    : Expanded(
                        child: ElevatedButton(
                          onPressed: onConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _confirmGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            l10n.confirmOffer,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ), // La condition manquante s'arrêtait ici à l'origine !

                const SizedBox(width: 12),

                // --- BOUTON REJECT ---
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _titleColor,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: context.colors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      l10n.rejectOffer,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _formatTime(opportunity.timestamp),
                style: TextStyle(
                  fontSize: 11,
                  color: context.colors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
