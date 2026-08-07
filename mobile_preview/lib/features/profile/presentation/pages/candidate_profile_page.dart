import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

/// Profil candidat (vue recruteur) — Overview / Portfolio + accès Resume AI.
class CandidateProfilePage extends StatefulWidget {
  const CandidateProfilePage({super.key});
  @override
  State<CandidateProfilePage> createState() => _CandidateProfilePageState();
}

class _CandidateProfilePageState extends State<CandidateProfilePage> {
  bool _portfolio = false;

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
        padding: const EdgeInsets.all(16),
        children: [
          _header(),
          const SizedBox(height: 14),
          _scoreBar(),
          const SizedBox(height: 14),
          _tabs(),
          const SizedBox(height: 16),
          if (!_portfolio) ..._overview() else ..._portfolioGrid(),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(children: [
      Stack(clipBehavior: Clip.none, children: [
        const CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=45')),
        Positioned(
          top: -4,
          left: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: AppTheme.brandBlue,
                borderRadius: BorderRadius.circular(20)),
            child: const Text('88%',
                style: TextStyle(color: Colors.white, fontSize: 10)),
          ),
        ),
      ]),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Anna Mary',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.navy)),
            const Text('UX/UI Designer', style: TextStyle(color: AppTheme.muted)),
            const SizedBox(height: 6),
            Row(children: [
              _smallBtn('Good fit'),
              const SizedBox(width: 8),
              _smallBtn('Share'),
              const SizedBox(width: 8),
              _menu(),
            ]),
          ],
        ),
      ),
      Column(children: [
        _circleIcon(Icons.chat_bubble_rounded, const Color(0xFFFDE7EF), AppTheme.brandPink,
            () => context.push('/chats')),
        const SizedBox(height: 8),
        _circleIcon(Icons.auto_awesome, const Color(0xFFEDEEFB), AppTheme.brandBlue,
            () => context.push('/resume-ai')),
      ]),
    ]);
  }

  Widget _smallBtn(String label) => OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 32),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          side: const BorderSide(color: AppTheme.brandBlue),
        ),
        child: Text(label,
            style: const TextStyle(color: AppTheme.brandBlue, fontSize: 12)),
      );

  Widget _menu() => PopupMenuButton<String>(
        icon: const Icon(Icons.more_horiz, color: AppTheme.muted),
        padding: EdgeInsets.zero,
        onSelected: (v) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$v — à venir'))),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'Remove from Fit Scores', child: Text('Remove from Fit Scores')),
          PopupMenuItem(value: 'Share the profile via', child: Text('Share the profile via…')),
          PopupMenuItem(value: 'Report', child: Text('Report')),
          PopupMenuItem(value: 'Block', child: Text('Block')),
        ],
      );

  Widget _circleIcon(IconData icon, Color bg, Color fg, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, color: fg, size: 18),
        ),
      );

  Widget _scoreBar() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Text('SOFT SKILLS SCORE',
                style: TextStyle(
                    fontSize: 11, color: AppTheme.muted, fontWeight: FontWeight.w600)),
            Spacer(),
            Text('85%',
                style: TextStyle(
                    fontSize: 12, color: AppTheme.navy, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
                value: 0.85,
                minHeight: 6,
                backgroundColor: Color(0xFFEDEDF2),
                color: AppTheme.brandBlue),
          ),
        ],
      );

  Widget _tabs() {
    Widget pill(String label, bool portfolio) {
      final active = _portfolio == portfolio;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _portfolio = portfolio),
          child: Column(children: [
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: active ? AppTheme.brandPink : AppTheme.muted)),
            const SizedBox(height: 6),
            Container(
                height: 2,
                color: active ? AppTheme.brandPink : Colors.transparent),
          ]),
        ),
      );
    }

    return Row(children: [pill('Overview', false), pill('Portfolio', true)]);
  }

  List<Widget> _overview() => [
        _block('Looking for', child: Column(children: [
          _twoCol('UX/UI Designer', 'Job position', 'Hybrid', 'Type of workplace'),
          const SizedBox(height: 10),
          _twoCol('Full time', 'Type of job', 'New york, USA', 'Target job location'),
        ])),
        _block('Skills', child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Technical Skills',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.navy)),
            SizedBox(height: 4),
            Text('Figma, Adobe XD, Sketch, HTML/CSS, React',
                style: TextStyle(color: Color(0xFF555A6B))),
          ],
        )),
        _block('Professional background', child: Column(children: [
          _kv('Years of Experience', '2 years'),
          _kv('Last position hold', 'Senior UX/UI Designer · X Agency · 2024 - Présent'),
        ])),
        _block('Certifications', child: _kv('Certified UX Designer', 'UX Design group · 2023')),
        _block('Education', child: _kv('Masters of UX/UI Design', 'Design Institute of Technology · 2020 - 2022')),
        _block('About me', child: const Text(
            'Hello. My name is Anna working as UI/UX designer. The UI design will '
            'help you and your website or app to convert the visitor to real customers.',
            style: TextStyle(color: Color(0xFF555A6B), height: 1.45))),
        TextButton(
          onPressed: () => context.push('/resume-ai'),
          child: const Text('View AI version',
              style: TextStyle(color: AppTheme.brandBlue)),
        ),
      ];

  List<Widget> _portfolioGrid() => [
        const Text('Portfolio',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy, fontSize: 15)),
        const SizedBox(height: 10),
        for (final s in const ['UI Design - Mobile App', 'Apps UI - UX Design', 'Web Dashboard'])
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    'https://picsum.photos/seed/${s.hashCode}/800/450',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFEEF1F6),
                        child: const Icon(Icons.image_outlined, color: AppTheme.muted)),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(s, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
            ]),
          ),
      ];

  Widget _block(String title, {required Widget child}) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppTheme.navy, fontSize: 15)),
          const SizedBox(height: 8),
          child,
        ]),
      );

  Widget _twoCol(String v1, String l1, String v2, String l2) => Row(children: [
        Expanded(child: _kv(v1, l1)),
        Expanded(child: _kv(v2, l2)),
      ]);

  Widget _kv(String value, String label) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppTheme.navy)),
          Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
        ],
      );
}
