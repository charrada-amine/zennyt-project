import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/presentation/view/je_decide_results.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> tap(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 350));
  }

  Widget subject({
    DecisionResultsStep initialStep = DecisionResultsStep.journeyComplete,
    VoidCallback? onDone,
  }) {
    return MaterialApp(
      home: DecisionResultsFlow(
        initialStep: initialStep,
        onClose: () {},
        onDone: onDone ?? () {},
      ),
    );
  }

  testWidgets('phase 4 runs from completion to detailed profile and export', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var done = false;

    await tester.pumpWidget(subject(onDone: () => done = true));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('decision-journey-complete')),
      findsOneWidget,
    );
    expect(find.text('30 / 30'), findsOneWidget);
    await tap(tester, 'decision-reveal-profile');

    expect(
      find.byKey(const ValueKey('decision-preparing-profile')),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey('decision-profile-title')),
      findsOneWidget,
    );
    expect(find.text('Analytical Decision-Maker'), findsOneWidget);
    expect(find.text('82'), findsOneWidget);
    await tap(tester, 'decision-view-insights');

    expect(find.text('Your strengths'), findsOneWidget);
    expect(
      find.text('You compare several pieces of information before choosing.'),
      findsOneWidget,
    );
    await tap(tester, 'decision-detailed-insights');

    expect(find.text('Analytical Thinking'), findsOneWidget);
    expect(find.text('Self-Control'), findsOneWidget);
    await tap(tester, 'decision-export-summary');

    expect(find.byKey(const ValueKey('decision-export-share')), findsOneWidget);
    expect(find.text('Your individual choices stay private.'), findsOneWidget);
    await tap(tester, 'decision-results-done');
    expect(done, isTrue);
  });

  testWidgets('radar exposes every public dimension as text semantics', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject(initialStep: DecisionResultsStep.profile));
    await tester.pump();

    expect(
      find.bySemanticsLabel(
        'Analytical Thinking 78 out of 100, Risk Balance 62 out of 100, '
        'Quick Choice 48 out of 100, Decision Stability 72 out of 100, '
        'Self-Control 67 out of 100',
      ),
      findsOneWidget,
    );
  });
}
