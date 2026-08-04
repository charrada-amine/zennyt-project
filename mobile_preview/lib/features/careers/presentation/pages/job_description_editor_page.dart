import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

/// Sous-écran "Description" du formulaire d'offre — sections "Click to add content".
class JobDescriptionEditorPage extends StatelessWidget {
  const JobDescriptionEditorPage({super.key});

  static const _sections = [
    'About the job',
    'Responsibilities',
    'Minimum Qualifications',
    'Preferred Qualifications',
    'What We Offer',
    'How to apply',
  ];

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
        title: const Text('Description',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final s in _sections) ...[
            Text(s,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppTheme.navy, fontSize: 15)),
            const SizedBox(height: 6),
            TextField(
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Click to add content',
                filled: true,
                fillColor: const Color(0xFFF4F5F8),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
          ],
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppTheme.brandBlue,
                padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () => context.pop(),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
