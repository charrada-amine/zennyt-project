import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:zennyt/core/error/api_exception.dart';
import 'package:zennyt/shared/widgets/custom_app_bar.dart';
import 'package:zennyt/features/jobs/domain/entities/assessment.dart';
import 'package:zennyt/features/jobs/domain/repositories/jobs_repository.dart';
import 'package:zennyt/features/jobs/presentation/providers/jobs_provider.dart';
import 'widgets/assessment_success_sheet.dart';
import 'widgets/question_form_state.dart';
import 'widgets/step1_form.dart';
import 'widgets/step2_form.dart';

/// Assistant de création/édition d'un test (assessment) — porté depuis
/// REC-04, branché sur `POST /assessments` du backend intégré.
class CreateAssessmentPage extends ConsumerStatefulWidget {
  final Assessment? existingAssessment;
  const CreateAssessmentPage({super.key, this.existingAssessment});

  @override
  ConsumerState<CreateAssessmentPage> createState() => _CreateAssessmentPageState();
}

class _CreateAssessmentPageState extends ConsumerState<CreateAssessmentPage> {
  int _currentStep = 0;
  int _currentQuestionIndex = 0;
  bool _isLoading = false;

  final _titleCtrl = TextEditingController();
  int _numQuestions = 10;
  int get _timeLimitSeconds => _numQuestions * 2 * 60;

  late List<QuestionFormState> _questions;
  Assessment? _createdAssessment;

  bool get _isEditMode => widget.existingAssessment != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingAssessment;
    if (existing != null) {
      _titleCtrl.text = existing.title;
      _numQuestions =
          existing.questions.isNotEmpty ? existing.questions.length : existing.maxQuestions;
      _questions = existing.questions.map((q) {
        final s = QuestionFormState();
        s.questionCtrl.text = q.text;
        for (int i = 0; i < 4 && i < q.options.length; i++) {
          s.optionCtrls[i].text = q.options[i];
        }
        s.correctIndex = q.correctOptionIndex;
        return s;
      }).toList();
    } else {
      _questions = List.generate(_numQuestions, (_) => QuestionFormState());
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  void _handleBack() {
    if (_currentStep == 0) {
      context.pop();
    } else if (_currentQuestionIndex > 0) {
      setState(() => _currentQuestionIndex--);
    } else {
      setState(() => _currentStep = 0);
    }
  }

  void _goToQuestions() {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a test title'), backgroundColor: Color(0xFFFFC107)),
      );
      return;
    }
    setState(() {
      if (_questions.length < _numQuestions) {
        while (_questions.length < _numQuestions) {
          _questions.add(QuestionFormState());
        }
      } else {
        _questions = _questions.take(_numQuestions).toList();
      }
      _currentStep = 1;
      _currentQuestionIndex = 0;
    });
  }

  void _nextQuestionOrSubmit() {
    final q = _questions[_currentQuestionIndex];

    if (q.questionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter text for Question ${_currentQuestionIndex + 1}'),
        backgroundColor: const Color(0xFFFFC107),
      ));
      return;
    }
    for (int i = 0; i < 4; i++) {
      if (q.optionCtrls[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Please fill all answers for Question ${_currentQuestionIndex + 1}'),
          backgroundColor: const Color(0xFFFFC107),
        ));
        return;
      }
    }

    if (_currentQuestionIndex < _numQuestions - 1) {
      setState(() => _currentQuestionIndex++);
    } else {
      _submit();
    }
  }

  /// Génération IA — le backend intégré n'expose pas encore
  /// `POST /assessments/generate` (cf. PLAN_FITSCORE_V3.md Phase 0) ;
  /// l'appel échoue proprement avec un message clair en attendant.
  Future<void> _generateWithAi() async {
    final jobTitleCtrl = TextEditingController(text: _titleCtrl.text.trim());
    final descriptionCtrl = TextEditingController();
    String difficulty = 'MID';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF1D3557), size: 20),
              SizedBox(width: 8),
              Text("Générer avec l'IA", style: TextStyle(fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: jobTitleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Intitulé du poste *',
                    hintText: 'Ex. Développeur Flutter',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description / compétences visées',
                    hintText: 'Ex. Riverpod, API REST, tests…',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: difficulty,
                  decoration: const InputDecoration(labelText: 'Difficulté'),
                  items: const [
                    DropdownMenuItem(value: 'JUNIOR', child: Text('Junior')),
                    DropdownMenuItem(value: 'MID', child: Text('Intermédiaire')),
                    DropdownMenuItem(value: 'SENIOR', child: Text('Senior')),
                  ],
                  onChanged: (v) => setDialogState(() => difficulty = v ?? 'MID'),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_numQuestions questions seront générées puis modifiables.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D3557),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Générer'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    if (jobTitleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("L'intitulé du poste est obligatoire"),
        backgroundColor: Color(0xFFFFC107),
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final created = await ref.read(assessmentsProvider.notifier).generateAssessmentAi(
            GenerateAssessmentAiParams(
              jobTitle: jobTitleCtrl.text.trim(),
              jobDescription: descriptionCtrl.text.trim(),
              questionCount: _numQuestions.clamp(1, 10),
              difficulty: difficulty,
              title: _titleCtrl.text.trim().isNotEmpty ? _titleCtrl.text.trim() : null,
              timeLimitSeconds: _timeLimitSeconds,
            ),
          );
      if (mounted && created != null) {
        setState(() => _createdAssessment = created);
        AssessmentSuccessSheet.show(context, created);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFE53935)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final questionParams = _questions
          .map((q) => CreateQuestionParams(
                text: q.questionCtrl.text.trim(),
                options: q.optionCtrls.map((c) => c.text.trim()).toList(),
                correctOptionIndex: q.correctIndex,
              ))
          .toList();

      if (_isEditMode) {
        await ref.read(assessmentsProvider.notifier).updateAssessment(
              UpdateAssessmentParams(
                id: widget.existingAssessment!.id,
                title: _titleCtrl.text.trim(),
                timeLimitSeconds: _timeLimitSeconds,
                questions: questionParams,
              ),
            );
        if (mounted) context.pop();
      } else {
        final created = await ref.read(assessmentsProvider.notifier).createAssessment(
              CreateAssessmentParams(
                title: _titleCtrl.text.trim(),
                timeLimitSeconds: _timeLimitSeconds,
                questions: questionParams,
              ),
            );
        if (mounted && created != null) {
          setState(() => _createdAssessment = created);
          AssessmentSuccessSheet.show(context, _createdAssessment!);
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFE53935)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: _isEditMode ? 'Edit test' : (_currentStep == 0 ? 'Create a test' : 'Questions'),
        onBack: _handleBack,
      ),
      body: _currentStep == 0
          ? AssessmentStep1Form(
              titleCtrl: _titleCtrl,
              numQuestions: _numQuestions,
              onNumQuestionsChanged: (v) {
                if (v != null) setState(() => _numQuestions = v);
              },
              onContinue: _goToQuestions,
              onGenerateWithAi: _isEditMode || _isLoading ? null : _generateWithAi,
            )
          : AssessmentStep2Form(
              currentQuestionIndex: _currentQuestionIndex,
              numQuestions: _numQuestions,
              currentQuestion: _questions[_currentQuestionIndex],
              isLoading: _isLoading,
              onNext: _nextQuestionOrSubmit,
              onChanged: () => setState(() {}),
            ),
    );
  }
}
