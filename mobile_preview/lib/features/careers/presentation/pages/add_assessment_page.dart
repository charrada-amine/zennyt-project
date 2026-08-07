import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

/// Choix : créer un test manuellement ou le générer avec l'IA.
class AddAssessmentPage extends StatelessWidget {
  const AddAssessmentPage({super.key});

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
        title: const Text('Add assessment',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _option(context, 'Create a test', Icons.edit_note,
              () => context.push('/recruiter/create-test')),
          const SizedBox(height: 14),
          _option(context, 'Generate a test with AI', Icons.auto_awesome,
              () => context.push('/recruiter/generate-ai')),
        ],
      ),
    );
  }

  Widget _option(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.brandBlue),
        ),
        child: Row(children: [
          Icon(icon, color: AppTheme.brandBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppTheme.navy)),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.muted),
        ]),
      ),
    );
  }
}
