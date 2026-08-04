import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/assessment_remote_datasource.dart';

/// Question QCM (mock — le backend ne renvoie pas le texte des questions).
class _Q {
  final String text;
  final List<String> options;
  final int correct;
  const _Q(this.text, this.options, this.correct);
}

/// Test de compétences (Hard skills test). Les questions affichées sont mock
/// (l'API ne les expose pas) mais les réponses sont soumises pour de vrai à
/// `POST /assessment-attempts` quand [assessmentId] et [jobOfferId] sont fournis.
class AssessmentTestPage extends StatefulWidget {
  final String? assessmentId;
  final String? jobOfferId;
  const AssessmentTestPage({super.key, this.assessmentId, this.jobOfferId});
  @override
  State<AssessmentTestPage> createState() => _AssessmentTestPageState();
}

class _AssessmentTestPageState extends State<AssessmentTestPage> {
  static const _questions = [
    _Q('Which of the following is a version control system commonly used in software development?',
        ['A - Docker', 'B - Git', 'C - Jenkins', 'D - Node.js'], 1),
    _Q('Which of these languages runs on the Java Virtual Machine (JVM)?',
        ['A - Java', 'B - Python', 'C - Ruby', 'D - Go'], 0),
    _Q('Which HTTP method is typically used to create a new resource?',
        ['A - GET', 'B - DELETE', 'C - POST', 'D - PATCH'], 2),
  ];

  int _index = 0;
  int? _selected;
  int _score = 0;
  int _remaining = 112; // 01:52
  Timer? _timer;
  final List<int> _answers = []; // index choisi par question (pour le backend)

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 0) {
        t.cancel();
        _finish();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _time {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _next() {
    _answers.add(_selected ?? 0);
    if (_selected == _questions[_index].correct) _score++;
    if (_index < _questions.length - 1) {
      setState(() {
        _index++;
        _selected = null;
      });
    } else {
      _finish();
    }
  }

  void _finish() {
    _timer?.cancel();
    // Complète le tableau de réponses si le minuteur a coupé en cours de test.
    while (_answers.length < _questions.length) {
      _answers.add(_answers.length == _index ? (_selected ?? 0) : 0);
    }
    _showIntegrity(validated: true);
  }

  /// Popup anti-fraude "Assessment integrity result" (mock : validé).
  void _showIntegrity({required bool validated}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (validated)
              const Text('🎉',
                  style: TextStyle(fontSize: 30))
            else
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                    color: Color(0xFFE53935), shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white),
              ),
            const SizedBox(height: 10),
            Text(
              validated
                  ? 'Congratulations\nAssessment integrity validated !'
                  : 'Assessment integrity not validated !',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppTheme.navy),
            ),
          ],
        ),
        actions: [
          Center(
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.brandBlue),
              onPressed: () {
                Navigator.of(context).pop();
                _submitAndShowScore();
              },
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  /// Soumet la tentative au backend si l'offre/test sont connus, sinon affiche
  /// le score local calculé sur les questions mock.
  Future<void> _submitAndShowScore() async {
    final assessmentId = widget.assessmentId;
    final jobOfferId = widget.jobOfferId;

    if (assessmentId == null || jobOfferId == null) {
      _showScore(_score, _questions.length, passed: _score >= _questions.length / 2);
      return;
    }

    try {
      final res = await sl<AssessmentRemoteDataSource>().submitAttempt(
        assessmentId: assessmentId,
        jobOfferId: jobOfferId,
        answers: _answers,
      );
      if (!mounted) return;
      _showScore(res.score, null, passed: res.passed);
    } catch (e) {
      if (!mounted) return;
      // Échec réseau / déjà passé : on retombe sur le score local, sans bloquer.
      _showScore(_score, _questions.length,
          passed: _score >= _questions.length / 2, note: 'Score local (hors-ligne)');
    }
  }

  void _showScore(int score, int? total, {required bool passed, String? note}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(passed ? 'Réussi 🎉' : 'Terminé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(total != null ? 'Score : $score / $total' : 'Score : $score'),
            if (note != null) ...[
              const SizedBox(height: 6),
              Text(note,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_index];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.navy,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.chevron_left), onPressed: () => context.pop()),
        title: const Text('Test',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(Icons.timer_outlined, size: 16, color: AppTheme.brandPink),
              const SizedBox(width: 4),
              Text(_time,
                  style: const TextStyle(
                      color: AppTheme.brandPink, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          const Text("Check the right answer. Here's one correct answer !",
              style: TextStyle(color: AppTheme.muted, fontSize: 13)),
          const SizedBox(height: 16),
          Text('Question ${_index + 1} : ${q.text}',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppTheme.navy, fontSize: 15, height: 1.4)),
          const SizedBox(height: 18),
          for (var i = 0; i < q.options.length; i++) _option(i, q.options[i]),
          const SizedBox(height: 24),
          Center(
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.brandBlue,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              onPressed: _selected == null ? null : _next,
              child: Text(_index < _questions.length - 1
                  ? 'Next question'
                  : 'Finish'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _option(int i, String label) {
    final selected = _selected == i;
    return GestureDetector(
      onTap: () => setState(() => _selected = i),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? AppTheme.brandBlue : Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                    color: selected ? AppTheme.brandBlue : const Color(0xFFC7C9D6),
                    width: 1.5),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 15, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(fontSize: 14, color: AppTheme.navy)),
          ],
        ),
      ),
    );
  }
}
