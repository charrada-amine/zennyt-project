import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

/// "Create a test" — choix du nombre de questions, puis ajout des questions.
class CreateTestPage extends StatefulWidget {
  const CreateTestPage({super.key});
  @override
  State<CreateTestPage> createState() => _CreateTestPageState();
}

class _CreateTestPageState extends State<CreateTestPage> {
  int _count = 30;
  final _title = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
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
        title: const Text('Create a test',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _title,
              decoration: InputDecoration(
                labelText: 'Test title',
                hintText: 'ex. Back-end technical test',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Select the number of questions',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: AppTheme.navy, fontSize: 15)),
            const SizedBox(height: 4),
            const Text(
                'The test includes a maximum of 30 questions. Candidates have '
                '2 minutes to answer each question.',
                style: TextStyle(color: AppTheme.muted, fontSize: 12)),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _count,
              decoration: InputDecoration(
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              items: const [10, 15, 20, 25, 30]
                  .map((n) => DropdownMenuItem(
                      value: n, child: Text('Maximum $n questions')))
                  .toList(),
              onChanged: (v) => setState(() => _count = v ?? 30),
            ),
            const SizedBox(height: 20),
            Center(
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.brandBlue,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 28, vertical: 14)),
                onPressed: () {
                  final title = _title.text.trim();
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Donne un titre au test.')));
                    return;
                  }
                  context.push('/recruiter/add-questions', extra: title);
                },
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
