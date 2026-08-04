import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

/// "Your tests" — gestion des tests : éditer / supprimer / ajouter / partager.
class MyTestsPage extends StatelessWidget {
  const MyTestsPage({super.key});

  static const _tests = ['Test 1', 'Test 2', 'Test 3', 'Test 4', 'Test 5'];

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
        title: const Text('Your tests',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final t in _tests)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F4FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _share(context, t),
                    child: Text(t,
                        style: const TextStyle(
                            color: AppTheme.brandBlue,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                InkWell(
                  onTap: () => context.push('/recruiter/add-questions'),
                  child: const Icon(Icons.edit_outlined,
                      size: 18, color: AppTheme.brandBlue),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.delete_outline, size: 18, color: AppTheme.brandPink),
              ]),
            ),
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppTheme.brandPink,
                padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () => context.push('/recruiter/add-assessment'),
            child: const Text('Add a test'),
          ),
        ],
      ),
    );
  }

  void _share(BuildContext context, String test) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(test,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.navy)),
            const SizedBox(height: 4),
            const Text('You can share the test link with your candidates.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.muted, fontSize: 12)),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                  color: AppTheme.brandPink,
                  borderRadius: BorderRadius.circular(10)),
              child: Text(
                  'https://www.${test.toLowerCase().replaceAll(' ', '')}.com/',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link shared')));
              },
              icon: const Icon(Icons.share, size: 18),
              label: const Text('Share'),
            ),
          ],
        ),
      ),
    );
  }
}
