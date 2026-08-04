import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../assessment/data/assessment_remote_datasource.dart';

/// "Add questions" — saisie d'une question + 4 réponses, marquage de la bonne
/// réponse, puis création du test via `POST /assessments`.
class AddQuestionsPage extends StatefulWidget {
  final String title;
  const AddQuestionsPage({super.key, required this.title});
  @override
  State<AddQuestionsPage> createState() => _AddQuestionsPageState();
}

class _AddQuestionsPageState extends State<AddQuestionsPage> {
  final _question = TextEditingController();
  final _answers = List.generate(4, (_) => TextEditingController());
  bool _selectMode = false;
  bool _saving = false;
  int? _correct;

  @override
  void dispose() {
    _question.dispose();
    for (final c in _answers) {
      c.dispose();
    }
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
        title: const Text('Questions',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Question number 1',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppTheme.navy, fontSize: 15)),
          const SizedBox(height: 10),
          TextField(
            controller: _question,
            minLines: 2,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Type the question',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < 4; i++) _answerField(i),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => setState(() => _selectMode = !_selectMode),
            child: Text(
              _selectMode ? 'Tap an answer to mark it correct' : 'Select the right answers',
              style: const TextStyle(
                  color: AppTheme.brandBlue, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.brandBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14)),
              onPressed: _saving ? null : _onContinue,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _answerField(int i) {
    final correct = _correct == i;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: _selectMode ? () => setState(() => _correct = i) : null,
        child: AbsorbPointer(
          absorbing: _selectMode,
          child: TextField(
            controller: _answers[i],
            decoration: InputDecoration(
              hintText: 'Answer ${String.fromCharCode(65 + i)}',
              filled: correct,
              fillColor: correct ? const Color(0xFF22A06B) : null,
              hintStyle: TextStyle(color: correct ? Colors.white70 : null),
              prefixIcon: Icon(Icons.radio_button_unchecked,
                  size: 18, color: correct ? Colors.white : AppTheme.muted),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            style: TextStyle(color: correct ? Colors.white : AppTheme.navy),
          ),
        ),
      ),
    );
  }

  /// Valide la saisie puis crée le test via POST /assessments.
  Future<void> _onContinue() async {
    final qText = _question.text.trim();
    final options = _answers.map((c) => c.text.trim()).toList();
    if (qText.isEmpty || options.any((o) => o.isEmpty) || _correct == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Complète la question, les 4 réponses et la bonne réponse.')));
      return;
    }

    setState(() => _saving = true);
    try {
      await sl<AssessmentRemoteDataSource>().createAssessment(
        title: widget.title,
        questions: [
          NewQuestion(
              text: qText, options: options, correctOptionIndex: _correct!),
        ],
      );
      if (!mounted) return;
      setState(() => _saving = false);
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SuccessDialog(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la création : $e')));
    }
  }
}

class _SuccessDialog extends StatefulWidget {
  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog> {
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
          const Text(
              'Now you can get a link and share it with your candidates.',
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
                Navigator.pop(context); // close dialog
                context.go('/careers'); // retour à l'espace recruteur (refetch)
              }
            },
            child: Text(_copied ? 'Done' : 'Get a link'),
          ),
        ),
      ],
    );
  }
}
