import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';

/// Hub des jeux sérieux : liste les évaluations cognitives disponibles.
///
/// Seul Planifik est jouable pour l'instant ; les autres sont annoncés mais
/// désactivés — le module s'étend sans casser cette page. Utilisé aussi comme
/// contenu de l'onglet « Progrès ».
class GamesHubScreen extends StatelessWidget {
  const GamesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jeux cognitifs')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _GameTile(
            title: 'Move Fast — Je Bouge',
            subtitle: 'Flexibilité cognitive · règles Orientation / Mouvement',
            icon: Icons.near_me,
            enabled: true,
            onTap: () => context.push(AppRoutes.gamesMoveFast),
          ),
          _GameTile(
            title: 'Planifik — Je planifie',
            subtitle: 'Évalue la planification · mini-jeu « Chemin Optimal »',
            icon: Icons.route,
            enabled: true,
            onTap: () => context.push(AppRoutes.gamesPlanifik),
          ),
          const _GameTile(
            title: 'Memory Quest — J\'investigue',
            subtitle: 'Mémoire de travail · à venir',
            icon: Icons.psychology,
            enabled: false,
          ),
          const _GameTile(
            title: 'Choix&Cap — Je décide',
            subtitle: 'Prise de décision · à venir',
            icon: Icons.balance,
            enabled: false,
          ),
        ],
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 32, color: enabled ? null : Colors.grey),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: enabled
            ? const Icon(Icons.chevron_right)
            : const Chip(
                label: Text('Bientôt'),
                visualDensity: VisualDensity.compact,
              ),
        enabled: enabled,
        onTap: enabled ? onTap : null,
      ),
    );
  }
}
