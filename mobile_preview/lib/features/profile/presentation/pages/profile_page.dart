import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/app_mode.dart';

/// Profil (recruteur) — contenu mock représentatif de la maquette Profile.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
        title: const Text('Profile',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(children: [
            const CircleAvatar(
                radius: 32,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=15')),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Kristin Watson',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.navy)),
                  const Text('HR Responsible',
                      style: TextStyle(color: AppTheme.muted)),
                  const SizedBox(height: 2),
                  Row(children: const [
                    Icon(Icons.business, size: 14, color: AppTheme.brandBlue),
                    SizedBox(width: 4),
                    Text('Google inc',
                        style: TextStyle(color: AppTheme.navy, fontSize: 13)),
                  ]),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                  color: Color(0xFFFDE7EF), shape: BoxShape.circle),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.chat_bubble_rounded,
                  color: AppTheme.brandPink, size: 18),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.brandBlue)),
                child: const Text('Good fit',
                    style: TextStyle(color: AppTheme.brandBlue)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD9DAE5))),
                child: const Text('Share',
                    style: TextStyle(color: AppTheme.navy)),
              ),
            ),
          ]),
          const Divider(height: 32),
          const Text('Company Informations',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppTheme.navy, fontSize: 16)),
          const SizedBox(height: 12),
          _info('Company size', '100-200 employees'),
          _info('Field of work', 'Consulting & Services'),
          _info('Company location', 'California, USA'),
          _info('Company Registration Number (EIN)', 'Verified'),
          const Divider(height: 32),
          const Text('About me',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppTheme.navy, fontSize: 16)),
          const SizedBox(height: 8),
          const Text(
              'Hello. My name is Kristin Watson, working as HR Responsible at '
              'Google inc with an experience of 20 years.',
              style: TextStyle(color: Color(0xFF555A6B), height: 1.45)),
          const Divider(height: 32),
          // Bascule de mode (preview) : candidat ⇄ recruteur. En recruteur,
          // l'onglet central de la barre du bas devient "Careers".
          ValueListenableBuilder<bool>(
            valueListenable: appIsRecruiter,
            builder: (_, isRecruiter, __) => SwitchListTile(
              value: isRecruiter,
              onChanged: (v) => appIsRecruiter.value = v,
              activeColor: AppTheme.brandBlue,
              contentPadding: EdgeInsets.zero,
              title: const Text('Mode recruteur',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: AppTheme.navy)),
              subtitle: const Text('Affiche l\'onglet Careers dans la barre du bas',
                  style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: AppTheme.brandBlue,
                padding: const EdgeInsets.symmetric(vertical: 14)),
            icon: const Icon(Icons.business_center_outlined),
            label: const Text('Open recruiter space (Careers)'),
            onPressed: () {
              appIsRecruiter.value = true;
              context.go('/careers');
            },
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppTheme.brandBlue, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: AppTheme.navy)),
          ],
        ),
      );
}
