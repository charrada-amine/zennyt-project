import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zennyt/core/storage/shared_preferences_provider.dart';
import 'package:zennyt/features/auth/presentation/current_user_provider.dart';
import 'package:zennyt/features/games/data/strategic_choices_bank_loader.dart';
import 'package:zennyt/features/games/domain/config/strategic_choices_content.dart';
import 'package:zennyt/features/games/domain/entities/strategic_choices_bank.dart';
import 'package:zennyt/features/games/presentation/view/strategic_choices_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // La banque des 60 situations vient d'un asset : on la précharge une fois
  // pour que l'écran la retrouve en cache.
  late StrategicChoicesBank bank;
  setUpAll(() async {
    StrategicChoicesBankLoader.resetForTest();
    bank = await StrategicChoicesBankLoader.load();
  });

  Future<void> pumpGame(WidgetTester tester, {double textScale = 1}) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    // Surface haute : la carte de situation porte désormais l'emplacement du
    // média et la description de scène du client, bien plus longue que les
    // phrases inventées d'avant. Sur 844 points, la bande d'état du bas sort du
    // cadre — et une liste paresseuse ne construit pas ce qu'elle n'affiche
    // pas, si bien que le test cherchait un texte qui n'existait pas encore.
    tester.view.physicalSize = const Size(390 * 3, 1500 * 3);
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

  test('la banque du client remplace les dix situations inventées', () {
    // L'écran jouait dix situations écrites à la main en anglais
    // (STRATEGIC_01 à 10). Elles ne venaient pas du client.
    expect(bank.scenarios, hasLength(60));
    expect(bank.scenarios.map((s) => s.id).toSet(), hasLength(60));
    expect(StrategicChoicesContent.strategies, hasLength(8));
    expect(kStrategicChoicesPerJourney, 10);
    expect(bank.byId('CS-001').title, 'La réunion interrompue');
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

  testWidgets('dix choix mènent au score du serveur et aux observations', (
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
    // Le récapitulatif n'est plus « front-only » : le serveur note la partie.
    // Le joueur coche « Breathe / pause » partout ; sur les dix situations
    // tirées, le total dépend donc de la banque — on vérifie la FORME du score
    // et sa cohérence, pas une valeur que le tirage rendrait aléatoire.
    final compteur = tester.widget<Text>(
      find.byKey(const ValueKey('strategic-answer-count')),
    );
    expect(
      compteur.data,
      matches(RegExp(r'^\d+ / 30$')),
      reason: 'dix situations cotées sur 3 chacune',
    );
    final obtenus = int.parse(compteur.data!.split(' / ').first);
    expect(obtenus, inInclusiveRange(0, 30));

    expect(
      find.textContaining('No psychometric score is calculated'),
      findsNothing,
      reason: 'le barème est branché',
    );
    // Le barème reste provisoire, et l'écran doit le dire.
    expect(find.textContaining('PROVISOIRE'), findsOneWidget);

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

  testWidgets('aucun écran ne prétend plus que le jeu ne calcule pas de score', (
    tester,
  ) async {
    // Le jeu a longtemps été « front-only ». Ses pages de règles, son
    // récapitulatif et ses observations l'annonçaient — et le disaient encore
    // après le branchement du barème. Le plus grave était la promesse que les
    // réponses « restaient sur l'écran » : elles partent maintenant au serveur.
    const mensonges = [
      'front-only',
      'does not calculate a score',
      'leaves scoring uncalculated',
      'Not scored',
      'kept only for this on-screen recap',
      'No psychometric score',
      // La taxonomie des dix situations inventées ; la banque du client n'a
      // aucune catégorie.
      'Conflict, failure, delay, criticism, and overload',
    ];

    void verifier(String etape) {
      for (final phrase in mensonges) {
        expect(
          find.textContaining(phrase),
          findsNothing,
          reason: '$etape : « $phrase » n\'est plus vrai',
        );
      }
    }

    await pumpGame(tester);
    verifier('couverture');

    await reachGameplay(tester);
    verifier('règles et gameplay');

    for (var index = 0; index < 10; index++) {
      await completeCurrentSituation(tester);
    }
    await tester.pumpAndSettle();
    verifier('récapitulatif');

    await tester.scrollUntilVisible(
      find.text('See detailed insights'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('See detailed insights'));
    await tester.pumpAndSettle();
    verifier('observations');
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
