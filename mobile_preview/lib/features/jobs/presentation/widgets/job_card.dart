import 'package:flutter/material.dart';

import '../../domain/entities/job.dart';

/// Carte d'affichage d'une offre dans la liste.
class JobCard extends StatelessWidget {
  final Job job;
  const JobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(job.title, style: theme.textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${job.companyName} · ${job.location}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                Chip(label: Text(job.contractType), visualDensity: VisualDensity.compact),
                if (job.remoteAllowed)
                  const Chip(label: Text('Remote'), visualDensity: VisualDensity.compact),
              ],
            ),
          ],
        ),
        trailing: job.hasApplied
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.chevron_right),
        onTap: () {/* navigation vers le détail via GoRouter */},
      ),
    );
  }
}
