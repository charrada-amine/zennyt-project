import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/jobs/domain/entities/test_attempt.dart';
import 'package:zennyt/features/jobs/domain/repositories/jobs_repository.dart';
import 'package:zennyt/features/jobs/presentation/pages/test_taking_page.dart';
import 'package:zennyt/features/jobs/presentation/providers/jobs_provider.dart';

class _FakeJobsRepository implements JobsRepository {
  _FakeJobsRepository({this.result});

  final TestResult? result;

  @override
  Future<TestResult?> getMyTestResult(String jobOfferId) async => result;

  @override
  Future<TestAttemptStarted> startTestAttempt(String jobOfferId) async => TestAttemptStarted(
        attemptId: 'attempt-1',
        jobOfferId: jobOfferId,
        timeLimitSeconds: 600,
        expiresAt: null,
        questions: [
          PresentedQuestion(
            id: 'q1',
            order: 1,
            text: 'Quel widget Flutter permet de réagir à un changement de taille '
                'de son parent sans connaître la taille de l’écran ?',
            options: const [
              'LayoutBuilder, qui reçoit les contraintes du parent',
              'MediaQuery, qui donne la taille de l’écran entier',
              'OrientationBuilder',
              'SizedBox.expand',
            ],
          ),
          const PresentedQuestion(id: 'q2', order: 2, text: 'Deuxième question', options: ['A', 'B']),
        ],
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(WidgetTester tester, _FakeJobsRepository repo,
    {required Size size, required double textScale}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(ProviderScope(
    overrides: [jobsRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const TestTakingPage(jobId: 'job-1'),
    ),
  ));
  await tester.pump();
  await tester.pump();
}

void main() {
  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(320, 568), 2.0),
    (const Size(390, 844), 1.5),
  ]) {
    final label = '${size.width.toInt()}x${size.height.toInt()} text x$scale';

    testWidgets('question screen fits on $label', (tester) async {
      await _pump(tester, _FakeJobsRepository(), size: size, textScale: scale);
      expect(tester.takeException(), isNull);
      expect(find.text('Question 1 / 2'), findsOneWidget);

      // En grand texte sur un petit écran, les réponses sont sous la ligne de
      // flottaison : la question défile au lieu de déborder.
      final option = find.text('LayoutBuilder, qui reçoit les contraintes du parent');
      await tester.scrollUntilVisible(option, 120, scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(option);
      await tester.pump();
      await tester.tap(option);
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Previous'), findsOneWidget);

      // Le chronomètre tourne : on démonte l'écran pour l'arrêter proprement.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('result screen fits on $label', (tester) async {
      await _pump(
        tester,
        _FakeJobsRepository(
          result: TestResult(
            id: 'r1',
            jobOfferId: 'job-1',
            hardSkillTestId: 't1',
            candidateId: 'c1',
            score: 7,
            percentage: 70,
            passed: true,
            startedAt: DateTime(2026, 9, 18, 10),
            completedAt: DateTime(2026, 9, 18, 10, 9),
            duration: 540,
            status: TestResultStatus.values.first,
          ),
        ),
        size: size,
        textScale: scale,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
