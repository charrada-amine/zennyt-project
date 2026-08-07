import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/app_mode.dart';
import '../../data/matches_remote_datasource.dart';

/// Liste des matches de l'utilisateur courant (candidat ou recruteur selon le
/// mode). Branchée sur `GET /candidates|recruiters/me/matches`.
class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});
  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  late Future<List<MatchItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = sl<MatchesRemoteDataSource>()
        .getMatches(recruiter: appIsRecruiter.value);
  }

  void _reload() {
    setState(() {
      _future = sl<MatchesRemoteDataSource>()
          .getMatches(recruiter: appIsRecruiter.value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.navy,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.chevron_left), onPressed: () => context.pop()),
        title: const Text('Matches',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.brandBlue),
              onPressed: _reload),
        ],
      ),
      body: FutureBuilder<List<MatchItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Impossible de charger les matches.'),
                const SizedBox(height: 12),
                FilledButton(onPressed: _reload, child: const Text('Réessayer')),
              ]),
            );
          }
          final matches = snap.data ?? const [];
          if (matches.isEmpty) {
            return const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.favorite_border, size: 48, color: AppTheme.muted),
                SizedBox(height: 8),
                Text('Pas encore de match.'),
              ]),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final m = matches[i];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEDEEFB),
                  child: Icon(Icons.work_outline, color: AppTheme.brandBlue),
                ),
                title: Text(m.jobOfferTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: AppTheme.navy)),
                subtitle: Text('Statut : ${m.status}',
                    style: const TextStyle(color: AppTheme.muted)),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.muted),
                onTap: () => context.push('/chats'),
              );
            },
          );
        },
      ),
    );
  }
}
