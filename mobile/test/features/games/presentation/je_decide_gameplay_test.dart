import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/presentation/view/je_decide_gameplay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> tap(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key)).last;
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 350));
  }

  Widget subject({
    DecisionGameplayStep initialStep = DecisionGameplayStep.analytical,
    VoidCallback? onClose,
    VoidCallback? onComplete,
  }) {
    return MaterialApp(
      home: DecisionGameplayView(
        initialStep: initialStep,
        onClose: onClose ?? () {},
        onComplete: onComplete ?? () {},
      ),
    );
  }

  testWidgets(
    'phase 2 follows all supplied scenario formats and keeps CS paired',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var completed = false;

      await tester.pumpWidget(subject(onComplete: () => completed = true));
      await tester.pump();

      expect(find.text('Delivery Bike'), findsOneWidget);
      expect(find.text('Scenario 04 / 30'), findsOneWidget);
      final firstContinue = find.descendant(
        of: find.byKey(const ValueKey('decision-continue')),
        matching: find.byType(FilledButton),
      );
      expect(tester.widget<FilledButton>(firstContinue).onPressed, isNull);

      await tap(tester, 'decision-option-1');
      expect(tester.widget<FilledButton>(firstContinue).onPressed, isNotNull);
      await tap(tester, 'decision-continue');

      expect(find.text('A financial choice'), findsOneWidget);
      expect(find.text('Scenario 07 / 30'), findsOneWidget);
      await tap(tester, 'decision-option-0');
      await tap(tester, 'decision-continue');

      expect(find.text('Choose quickly'), findsOneWidget);
      expect(find.text('7 sec'), findsOneWidget);
      await tap(tester, 'decision-option-2');
      await tap(tester, 'decision-continue');

      expect(find.text('Part 1 of 2'), findsOneWidget);
      expect(find.text('Scenario 19 / 30'), findsOneWidget);
      await tap(tester, 'decision-option-1');
      await tap(tester, 'decision-continue');

      expect(find.text('Part 2 of 2'), findsOneWidget);
      expect(find.text('Scenario 20 / 30'), findsOneWidget);
      await tap(tester, 'decision-option-0');
      await tap(tester, 'decision-continue');

      expect(find.text('Reward timing'), findsOneWidget);
      expect(find.text('Scenario 25 / 30'), findsOneWidget);
      await tap(tester, 'decision-option-1');
      await tap(tester, 'decision-continue');

      expect(find.byKey(const ValueKey('decision-xp-title')), findsOneWidget);
      expect(find.text('+12 XP'), findsOneWidget);
      await tap(tester, 'decision-next-scenario');

      expect(
        find.byKey(const ValueKey('decision-badge-title')),
        findsOneWidget,
      );
      expect(find.text('Steady Explorer'), findsOneWidget);
      await tap(tester, 'decision-badge-continue');

      expect(completed, isTrue);
      expect(find.textContaining('correct'), findsNothing);
      expect(find.textContaining('wrong'), findsNothing);
    },
  );

  testWidgets('quick choice warns calmly then advances after timeout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      subject(initialStep: DecisionGameplayStep.quickChoice),
    );
    await tester.pump();

    expect(find.text('7 sec'), findsOneWidget);
    for (var second = 0; second < 5; second++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.text('2 sec'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('0 sec'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('decision-timeout-title')),
      findsOneWidget,
    );
    expect(find.text('No worries. The journey continues.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Part 1 of 2'), findsOneWidget);
    expect(find.text('Scenario 19 / 30'), findsOneWidget);
  });
}
