import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:zennyt/core/error/api_exception.dart';
import 'package:zennyt/features/jobs/domain/entities/test_attempt.dart';
import 'package:zennyt/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:zennyt/shared/widgets/custom_app_bar.dart';

/// Hard-skills test runner (maquettes 96, 306 / 138-139).
///
/// Démarre l'unique tentative du candidat (`POST /job-offers/{id}/test-attempts`),
/// affiche les questions mélangées une par une avec le temps restant, puis
/// soumet les indices de réponses (`POST /test-attempts/{id}/submit`). Le score
/// est calculé côté serveur — le client n'envoie jamais de score. Si un résultat
/// existe déjà, l'écran affiche ce résultat au lieu de démarrer une tentative.
class TestTakingPage extends ConsumerStatefulWidget {
  final String jobId;
  const TestTakingPage({super.key, required this.jobId});

  @override
  ConsumerState<TestTakingPage> createState() => _TestTakingPageState();
}

class _TestTakingPageState extends ConsumerState<TestTakingPage> {
  TestAttemptStarted? _attempt;
  TestResult? _result;
  final Map<String, int> _answers = {};
  int _index = 0;
  int _remaining = 0;
  Timer? _timer;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final repo = ref.read(jobsRepositoryProvider);
    try {
      final existing = await repo.getMyTestResult(widget.jobId);
      if (!mounted) return;
      if (existing != null) {
        setState(() {
          _result = existing;
          _loading = false;
        });
        return;
      }
      final started = await repo.startTestAttempt(widget.jobId);
      if (!mounted) return;
      setState(() {
        _attempt = started;
        _loading = false;
        _remaining = _secondsLeft(started);
      });
      _startTimer();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to start the assessment.';
        _loading = false;
      });
    }
  }

  int _secondsLeft(TestAttemptStarted attempt) {
    if (attempt.expiresAt != null) {
      final diff = attempt.expiresAt!.difference(DateTime.now()).inSeconds;
      return diff < 0 ? 0 : diff;
    }
    return attempt.timeLimitSeconds;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining = _remaining > 0 ? _remaining - 1 : 0);
      if (_remaining == 0) {
        t.cancel();
        _submit(auto: true);
      }
    });
  }

  Future<void> _submit({bool auto = false}) async {
    final attempt = _attempt;
    if (attempt == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      final answers = attempt.questions
          .where((q) => _answers.containsKey(q.id))
          .map((q) => TestAttemptAnswer(questionId: q.id, selectedOptionIndex: _answers[q.id]!))
          .toList();
      final result = await ref.read(jobsRepositoryProvider).submitTestAttempt(
            attemptId: attempt.attemptId,
            answers: answers,
          );
      if (!mounted) return;
      setState(() {
        _result = result;
        _submitting = false;
      });
      ref.invalidate(myTestResultProvider(widget.jobId));
      ref.invalidate(jobTestResultsProvider(widget.jobId));
      ref.invalidate(jobTestResultsSummaryProvider(widget.jobId));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFE53935)),
      );
    }
  }

  Future<void> _confirmAbandon() async {
    final attempt = _attempt;
    if (attempt == null) {
      context.pop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave the assessment?'),
        content: const Text(
          'Leaving now abandons your attempt. You only get one attempt per job offer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Leave')),
        ],
      ),
    );
    if (leave != true) return;
    try {
      await ref.read(jobsRepositoryProvider).abandonTestAttempt(attempt.attemptId);
    } catch (_) {
      // Abandon is best-effort — navigation still proceeds.
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final title = _result != null ? 'Test result' : 'Questions';

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFE53935), size: 34),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF475569))),
              const SizedBox(height: 12),
              TextButton(onPressed: () => context.pop(), child: const Text('Back to job')),
            ],
          ),
        ),
      );
    } else if (_result != null) {
      body = _TestResultView(result: _result!);
    } else {
      body = _AttemptBody(
        attempt: _attempt!,
        index: _index,
        answers: _answers,
        remaining: _remaining,
        submitting: _submitting,
        onSelect: (qid, i) => setState(() => _answers[qid] = i),
        onNext: () => setState(() => _index = (_index + 1).clamp(0, _attempt!.questions.length - 1)),
        onPrevious: () => setState(() => _index = (_index - 1).clamp(0, _attempt!.questions.length - 1)),
        onSubmit: _submit,
      );
    }

    return PopScope(
      canPop: _result != null || _error != null || _loading,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmAbandon();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: title,
          onBack: () async {
            if (_result != null || _error != null) {
              context.pop();
            } else {
              await _confirmAbandon();
            }
          },
        ),
        body: body,
      ),
    );
  }
}

class _AttemptBody extends StatelessWidget {
  final TestAttemptStarted attempt;
  final int index;
  final Map<String, int> answers;
  final int remaining;
  final bool submitting;
  final void Function(String questionId, int optionIndex) onSelect;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final Future<void> Function({bool auto}) onSubmit;

  const _AttemptBody({
    required this.attempt,
    required this.index,
    required this.answers,
    required this.remaining,
    required this.submitting,
    required this.onSelect,
    required this.onNext,
    required this.onPrevious,
    required this.onSubmit,
  });

  String get _clock {
    final m = (remaining ~/ 60).toString().padLeft(2, '0');
    final s = (remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final question = attempt.questions[index];
    final isLast = index == attempt.questions.length - 1;
    final selected = answers[question.id];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Row(
            children: [
              Text(
                'Question number ${index + 1} / ${attempt.questions.length}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1E1B4B)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: remaining < 60 ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined,
                        size: 14, color: remaining < 60 ? const Color(0xFFEF4444) : const Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      _clock,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: remaining < 60 ? const Color(0xFFEF4444) : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        LinearProgressIndicator(
          value: (index + 1) / attempt.questions.length,
          minHeight: 4,
          backgroundColor: const Color(0xFFF1F5F9),
          color: const Color(0xFF11428D),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            children: [
              Text(
                question.text,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.4, color: Color(0xFF1E1B4B)),
              ),
              const SizedBox(height: 20),
              for (var i = 0; i < question.options.length; i++)
                _OptionTile(
                  label: String.fromCharCode(65 + i),
                  text: question.options[i],
                  selected: selected == i,
                  onTap: () => onSelect(question.id, i),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
          ),
          child: Row(
            children: [
              if (index > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onPrevious,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Previous'),
                  ),
                ),
              if (index > 0) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: selected == null || submitting
                      ? null
                      : () => isLast ? onSubmit() : onNext(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF11428D),
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : Text(isLast ? 'Submit' : 'Next question',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final String text;
  final bool selected;
  final VoidCallback onTap;
  const _OptionTile({
    required this.label,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF11428D) : const Color(0xFFE2E8F0),
            width: selected ? 1.6 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF11428D) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: selected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: Color(0xFF11428D), size: 20),
          ],
        ),
      ),
    );
  }
}

class _TestResultView extends StatelessWidget {
  final TestResult result;
  const _TestResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = result.passed ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(
              result.passed ? Icons.verified_rounded : Icons.cancel_rounded,
              color: color,
              size: 52,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            result.passed ? 'Congratulations!' : 'Assessment completed',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B)),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            '${result.percentage}% · ${result.status.label}',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color),
          ),
        ),
        const SizedBox(height: 28),
        _ResultRow(label: 'Score', value: '${result.score}'),
        _ResultRow(label: 'Percentage', value: '${result.percentage}%'),
        _ResultRow(label: 'Passed', value: result.passed ? 'Yes (threshold 70%)' : 'No (threshold 70%)'),
        _ResultRow(label: 'Duration', value: _duration(result.duration)),
        if (result.completedAt != null)
          _ResultRow(label: 'Completed', value: result.completedAt!.toLocal().toString().split('.').first),
        const SizedBox(height: 28),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF11428D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Back to job', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  String _duration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s}s';
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontSize: 13.5)),
        ],
      ),
    );
  }
}
