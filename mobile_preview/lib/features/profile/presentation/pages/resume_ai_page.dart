import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

/// "Resume AI" — synthèses IA des soft & hard skills du candidat (mock).
class ResumeAiPage extends StatelessWidget {
  const ResumeAiPage({super.key});

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
        title: const Text('Resume AI',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Last Updated: September 29, 2025',
              style: TextStyle(color: AppTheme.muted, fontSize: 12)),
          const SizedBox(height: 16),
          const Text('Soft Skills Summary',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppTheme.navy, fontSize: 16)),
          const SizedBox(height: 8),
          const Text(
              'On the interpersonal front, the candidate brings strong '
              'communication and leadership abilities. She communicates clearly '
              'and confidently, both in team settings and with stakeholders, and '
              'is effective in motivating team members and keeping projects on '
              'track. She excels at time management and prioritizing tasks, rarely '
              'missing deadlines. Her teamwork is generally positive.',
              style: TextStyle(color: Color(0xFF555A6B), height: 1.5)),
          const SizedBox(height: 8),
          const Text('Soft skills measured through validated psychometric games.',
              style: TextStyle(
                  color: AppTheme.brandBlue,
                  fontSize: 12,
                  fontStyle: FontStyle.italic)),
          const Divider(height: 32),
          const Text('Hard Skills Summary',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppTheme.navy, fontSize: 16)),
          const SizedBox(height: 8),
          const Text(
              'The candidate demonstrates a strong command of project management '
              'methodologies, particularly Agile and Scrum, having successfully led '
              'multiple cross-functional teams through complex project lifecycles. '
              'She is well-versed in budgeting and financial constraints, and '
              'demonstrates a clear understanding of cost control and forecasting. '
              'There is room for growth in adapting to newer technical environments '
              'and enhancing data analytics with tools such as SQL or Python.',
              style: TextStyle(color: Color(0xFF555A6B), height: 1.5)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('View original version',
                style: TextStyle(color: AppTheme.brandBlue)),
          ),
        ],
      ),
    );
  }
}
