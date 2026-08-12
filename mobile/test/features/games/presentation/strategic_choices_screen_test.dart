import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zennyt/core/storage/shared_preferences_provider.dart';
import 'package:zennyt/features/auth/presentation/current_user_provider.dart';
import 'package:zennyt/features/games/domain/config/strategic_choices_content.dart';
import 'package:zennyt/features/games/presentation/view/strategic_choices_screen.dart';

void main() {
  Future<void> pumpGame(WidgetTester tester, {double textScale = 1}) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          currentUserProvider.overrideWithValue(null),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const StrategicChoicesScreen(
            reflectionDuration: Duration(milliseconds: 300),
            savedTransitionDuration: Duration(milliseconds: 10),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> revealScrollableText(WidgetTester tester, String label) async {
    final target = find.text(label);
    for (var attempt = 0; attempt < 8 && target.evaluate().isEmpty; attempt++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -220));
      await tester.pump();
    }
    expect(target, findsOneWidget);
    await tester.ensureVisible(target);
    await tester.pump();
  }

  Future<void> tapScrollableText(WidgetTester tester, String label) async {
    await revealScrollableText(tester, label);
    await tester.tap(find.text(label));
  }

  Future<void> reachGameplay(WidgetTester tester) async {
    await tapScrollableText(tester, 'Start mission');
    await tester.pumpAndSettle();
    await tapScrollableText(tester, 'Continue');
    await tester.pumpAndSettle();
    await tapScrollableText(tester, 'Start situation');
    await tester.pumpAndSettle();
  }

  Future<void> completeCurrentSituation(WidgetTester tester) async {
    final startReflection = find.byKey(
      const ValueKey('strategic-start-reflection'),
    );
    await tester.scrollUntilVisible(
      startReflection,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(startReflection);
    await tester.pump();

    final choice = find.byKey(const ValueKey('strategic-choice-breathePause'));
    await tester.scrollUntilVisible(
      choice,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(choice);
    await tester.pump(const Duration(milliseconds: 350));

    final validate = find.byKey(const ValueKey('strategic-validate'));
    await tester.scrollUntilVisible(
      validate,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(validate);
    await tester.pumpAndSettle();
  }

  test('catalogue public contains the exact ten text situations', () {
    expect(StrategicChoicesContent.situations, hasLength(10));
    expect(StrategicChoicesContent.strategies, hasLength(8));
    expect(
      StrategicChoicesContent.situations.first.prompt,
      'A colleague criticizes your work in front of the whole team.',
    );
    expect(
      StrategicChoicesContent.situations.last.prompt,
      'Two team members argue openly during a meeting you are facilitating.',
    );
  });

  testWidgets('cover, tutorial and purple PNG follow the supplied flow', (
    tester,
  ) async {
    await pumpGame(tester);

    expect(find.text('Strategic Choices'), findsOneWidget);
    expect(find.text('Emotional Regulation'), findsWidgets);
    final logo = tester.widget<Image>(
      find.byKey(const ValueKey('strategic-purple-logo')),
    );
    expect(logo.image, isA<AssetImage>());
    expect(
      (logo.image as AssetImage).assetName,
      'assets/games icons/Strategic Choices Purple.png',
    );

    await tapScrollableText(tester, 'View tutorial');
    await tester.pumpAndSettle();
    expect(find.text('Train the pause before action'), findsOneWidget);
    await revealScrollableText(tester, 'Text scenarios for now');
    expect(find.text('Text scenarios for now'), findsOneWidget);

    await tapScrollableText(tester, 'Continue');
    await tester.pumpAndSettle();
    expect(find.text('How the mission works'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Reflect'), findsOneWidget);
    expect(find.text('Choose'), findsOneWidget);
    expect(find.text('Validate'), findsOneWidget);
  });

  testWidgets('pause freezes reflection and offers no restart action', (
    tester,
  ) async {
    await pumpGame(tester);
    await reachGameplay(tester);

    final startReflection = find.byKey(
      const ValueKey('strategic-start-reflection'),
    );
    await tester.scrollUntilVisible(
      startReflection,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(startReflection);
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();
    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('View rules / Help'), findsOneWidget);
    expect(find.text('Exit mission'), findsOneWidget);
    expect(find.textContaining('Restart'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Resume'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Reflection time · choices'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      find.text('Reflection complete · choose one strategy'),
      findsOneWidget,
    );
  });

  testWidgets('ten choices reach a non-scored recap and descriptive insights', (
    tester,
  ) async {
    await pumpGame(tester);
    await reachGameplay(tester);

    for (var index = 0; index < 10; index++) {
      await completeCurrentSituation(tester);
    }
    await tester.pumpAndSettle();

    expect(find.text('Final summary'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('strategic-answer-count')),
      findsOneWidget,
    );
    expect(find.text('10 / 10'), findsOneWidget);
    expect(find.text('Not scored'), findsWidgets);
    expect(find.text('82 / 100'), findsNothing);
    expect(
      find.textContaining('No psychometric score is calculated'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('See detailed insights'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('See detailed insights'));
    await tester.pumpAndSettle();
    expect(find.text('Learning insights'), findsOneWidget);
    expect(find.text('Most used strategy'), findsOneWidget);
    expect(find.text('Breathe / pause'), findsOneWidget);
    expect(find.text('Trap tendencies'), findsOneWidget);
  });

  testWidgets('390x844 at 200% text remains scrollable without overflow', (
    tester,
  ) async {
    await pumpGame(tester, textScale: 2);
    expect(tester.takeException(), isNull);
    await revealScrollableText(tester, 'Strategic Choices');
    expect(find.text('Strategic Choices'), findsOneWidget);

    await tapScrollableText(tester, 'Start mission');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Continue'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Continue'), findsOneWidget);
  });
}
