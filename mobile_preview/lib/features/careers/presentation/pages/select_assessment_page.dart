import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

/// Grille de sélection d'un test (avec aperçu). Renvoie le test choisi via pop.
class SelectAssessmentPage extends StatefulWidget {
  const SelectAssessmentPage({super.key});
  @override
  State<SelectAssessmentPage> createState() => _SelectAssessmentPageState();
}

class _SelectAssessmentPageState extends State<SelectAssessmentPage> {
  int? _selected;

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
        title: const Text('Select an assessment',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.25,
              ),
              itemCount: 8,
              itemBuilder: (context, i) => _card(i),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.brandBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: _selected == null
                      ? null
                      : () => context.pop('Test ${_selected! + 1}'),
                  child: const Text('Select'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(int i) {
    final active = _selected == i;
    return GestureDetector(
      onTap: () => setState(() => _selected = i),
      child: Container(
        decoration: BoxDecoration(
          color: active ? AppTheme.brandBlue : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: active ? AppTheme.brandBlue : const Color(0xFFD9DAE5)),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lightbulb_outline,
                      size: 30, color: active ? Colors.white : AppTheme.brandBlue),
                  const SizedBox(height: 8),
                  Text('Test ${i + 1}',
                      style: TextStyle(
                          color: active ? Colors.white : AppTheme.brandBlue,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: InkWell(
                onTap: () => _preview(i),
                child: Icon(Icons.visibility_outlined,
                    size: 18,
                    color: active ? Colors.white : AppTheme.brandBlue),
              ),
            ),
            if (active)
              const Positioned(
                top: 8,
                left: 8,
                child: Icon(Icons.check_circle, size: 18, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  void _preview(int i) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text('Test ${i + 1}',
                  style: const TextStyle(
                      color: AppTheme.brandBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
            ),
            const SizedBox(height: 12),
            const Text('Hard skills test overview – Developer Position',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
            const SizedBox(height: 10),
            _line('Number of Questions:', '20'),
            _line('Time per Question:', '2 minutes'),
            _line('Total Duration:', '30 minutes'),
            _line('Format:', 'Multiple choice and code snippets'),
            _line('Topics Covered:',
                'Algorithms, data structures, debugging, language-specific syntax.'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppTheme.brandBlue),
                onPressed: () {
                  Navigator.pop(context);
                  context.pop('Test ${i + 1}');
                },
                child: const Text('Select'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(color: Color(0xFF555A6B), fontSize: 13),
            children: [
              TextSpan(
                  text: '$k ',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
              TextSpan(text: v),
            ],
          ),
        ),
      );
}
