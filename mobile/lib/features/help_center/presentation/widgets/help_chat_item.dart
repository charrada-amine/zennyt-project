import 'package:flutter/material.dart';
import '../../domain/entities/help_chat.dart';
import '../../../../core/constants.dart';

class HelpChatItem extends StatelessWidget {
  final HelpChat chat;
  final VoidCallback onTap;

  const HelpChatItem({
    super.key,
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration:const BoxDecoration(
                color: AppColors.infoSoft,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                "assets/images/logo_help_center.png",
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        chat.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        _quand(chat.lastMessageAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horodatage court, comme dans une liste de messagerie : l'heure si c'est aujourd'hui,
/// la date sinon. Vide tant qu'aucun message n'a ete echange — une conversation qui vient
/// d'etre ouverte n'a pas de « derniere activite » a afficher.
String _quand(DateTime? moment) {
  if (moment == null) return '';
  final local = moment.toLocal();
  final maintenant = DateTime.now();
  final memeJour = local.year == maintenant.year &&
      local.month == maintenant.month &&
      local.day == maintenant.day;
  String deuxChiffres(int n) => n.toString().padLeft(2, '0');
  return memeJour
      ? '${deuxChiffres(local.hour)}:${deuxChiffres(local.minute)}'
      : '${deuxChiffres(local.day)}/${deuxChiffres(local.month)}';
}
