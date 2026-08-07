import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

/// "Generate a test with AI" — depuis un fichier ou un prompt (mock).
class GenerateTestAiPage extends StatefulWidget {
  const GenerateTestAiPage({super.key});
  @override
  State<GenerateTestAiPage> createState() => _GenerateTestAiPageState();
}

class _GenerateTestAiPageState extends State<GenerateTestAiPage> {
  bool _fromPrompt = false;
  final _prompt = TextEditingController();
  int _count = 10;

  @override
  void dispose() {
    _prompt.dispose();
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
        title: const Text('Generate a test with AI',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            _tab('From File', false),
            const SizedBox(width: 10),
            _tab('From Prompt', true),
          ]),
          const SizedBox(height: 18),
          if (!_fromPrompt) ..._fileMode() else ..._promptMode(),
          const SizedBox(height: 20),
          Center(
            child: FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.brandBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14)),
              onPressed: _generate,
              child: const Text('Generate test'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, bool prompt) {
    final active = _fromPrompt == prompt;
    return GestureDetector(
      onTap: () => setState(() => _fromPrompt = prompt),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.brandBlue : const Color(0xFFEDEEFB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppTheme.brandBlue)),
      ),
    );
  }

  List<Widget> _fileMode() => [
        const Text('Add the file and number of questions',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
        const SizedBox(height: 4),
        const Text(
            'Upload a file (book, manual, MCQ) then select a number of questions '
            'to generate your test.',
            style: TextStyle(color: AppTheme.muted, fontSize: 12)),
        const SizedBox(height: 14),
        InkWell(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD9DAE5))),
            child: Row(children: const [
              Icon(Icons.upload_file, color: AppTheme.brandBlue, size: 20),
              SizedBox(width: 10),
              Text('Add your file', style: TextStyle(color: AppTheme.navy)),
              Spacer(),
              Icon(Icons.add, color: AppTheme.muted),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFFF6F4FF),
              borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Icon(Icons.picture_as_pdf, color: Color(0xFFE53935)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Quizz number 1',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: AppTheme.navy)),
                  Text('867 kb · 14 Jun 2025 at 11:30 am',
                      style: TextStyle(color: AppTheme.muted, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.delete_outline, color: AppTheme.brandPink, size: 20),
          ]),
        ),
        const SizedBox(height: 14),
        _countDropdown(),
      ];

  List<Widget> _promptMode() => [
        const Text('Describe the job and domain',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
        const SizedBox(height: 4),
        const Text(
            'Write a description explaining the field of activity and the job '
            'position, then AI will generate a MCQ test based on your text.',
            style: TextStyle(color: AppTheme.muted, fontSize: 12)),
        const SizedBox(height: 14),
        const Text('Job description',
            style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.navy)),
        const SizedBox(height: 6),
        TextField(
          controller: _prompt,
          minLines: 4,
          maxLines: 6,
          maxLength: 1000,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText:
                'Example: I need a test for a senior React developer position…',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 8),
        _countDropdown(),
      ];

  Widget _countDropdown() => DropdownButtonFormField<int>(
        value: _count,
        decoration: InputDecoration(
            labelText: 'Number of questions',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
        items: const [10, 15, 20, 25, 30]
            .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
            .toList(),
        onChanged: (v) => setState(() => _count = v ?? 10),
      );

  void _generate() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _TestAddedDialog(),
    );
  }
}

class _TestAddedDialog extends StatefulWidget {
  const _TestAddedDialog();
  @override
  State<_TestAddedDialog> createState() => _TestAddedDialogState();
}

class _TestAddedDialogState extends State<_TestAddedDialog> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Your test was successfully added !',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
          const SizedBox(height: 6),
          const Text('Now you can get a link and share it with your candidates.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.muted, fontSize: 12)),
          if (_copied) ...[
            const SizedBox(height: 10),
            const Text('Link copied !',
                style: TextStyle(
                    color: AppTheme.brandBlue, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
      actions: [
        Center(
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.brandBlue),
            onPressed: () {
              if (!_copied) {
                setState(() => _copied = true);
              } else {
                Navigator.pop(context);
                context.pop();
              }
            },
            child: Text(_copied ? 'Done' : 'Get a link'),
          ),
        ),
      ],
    );
  }
}
