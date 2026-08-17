import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zennyt/features/games/domain/entities/decision_form.dart';
import 'package:zennyt/features/games/domain/entities/decision_metrics.dart';
import 'package:zennyt/features/games/presentation/view/je_decide_gameplay.dart';

/// Boucle de gameplay « Je Décide » : mesure du temps de réponse, indicateur de
/// changement d'avis, et gel de l'item chronométré pendant la pause.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  DecisionFormItem item(
    String id,
    DecisionDimension dimension, {
    DecisionItemFormat format = DecisionItemFormat.standard,
    int? timeLimitMs,
  }) => DecisionFormItem(
    itemId: id,
    dimension: dimension,
    format: format,
    vignette: 'Situation $id.',
    task: 'Consigne $id.',
    timeLimitMs: timeLimitMs,
    options: [
      DecisionFormOption(optionId: '$id-o1', label: 'Option 1'),
      DecisionFormOption(optionId: '$id-o2', label: 'Option 2'),
      DecisionFormOption(optionId: '$id-o3', label: 'Option 3'),
    ],
  );

  /// Forme minimale : un item libre puis un item chronométré à 7 s. On garde
  /// `itemsPerDimension` à 2 pour qu'aucun écran de transition ne s'intercale.
  DecisionForm form() => DecisionForm(
    formCode: 'A',
    itemsPerDimension: 2,
    items: [
      item('II-1', DecisionDimension.ii),
      item(
        'DT-7',
        DecisionDimension.dt,
        format: DecisionItemFormat.temporalDecision,
        timeLimitMs: 7000,
      ),
    ],
  );

  Future<List<DecisionItemResponse>?> pumpJourney(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    List<DecisionItemResponse>? submitted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DecisionGameplayView(
            form: form(),
            onClose: () {},
            onComplete: (responses) => submitted = responses,
          ),
        ),
      ),
    );
    await tester.pump();
    return submitted;
  }

  testWidgets(
    'le temps de réponse est mesuré à la validation, pas au premier tap',
    (tester) async {
      List<DecisionItemResponse>? submitted;
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DecisionGameplayView(
              form: form(),
              onClose: () {},
              onComplete: (responses) => submitted = responses,
            ),
          ),
        ),
      );
      await tester.pump();

      // Item 1 : on choisit tout de suite, puis on délibère 4 s avant de valider.
      await tester.tap(find.byKey(const ValueKey('decision-option-0')));
      await tester.pump(const Duration(seconds: 4));
      // Puis on change d'avis — c'est permis, et compté.
      await tester.tap(find.byKey(const ValueKey('decision-option-2')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('decision-continue')));
      await tester.pump();

      // Item 2 (chronométré) : on ne répond pas, le temps s'écoule.
      expect(find.text('7 sec'), findsOneWidget);
      await tester.pump(const Duration(seconds: 7));
      expect(
        find.byKey(const ValueKey('decision-timeout-title')),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      expect(submitted, isNotNull);
      final first = submitted!.first;
      expect(
        first.selectedOptionId,
        'II-1-o3',
        reason: 'la réponse validée est le dernier choix',
      );
      expect(
        first.decisionChangesCount,
        1,
        reason: 'le changement d\'avis est un indicateur mesuré, pas une faute',
      );
      expect(
        first.responseTimeMs,
        greaterThanOrEqualTo(4000),
        reason:
            'choisir vite puis délibérer doit produire un temps LONG — sinon la '
            'contrainte de temps se contourne',
      );

      final timed = submitted!.last;
      expect(timed.answered, isFalse, reason: 'item manqué → imputation serveur');
      expect(timed.selectedOptionId, isNull);
    },
  );

  testWidgets('la pause gèle le compte à rebours de l\'item chronométré', (
    tester,
  ) async {
    await pumpJourney(tester);

    // Passe le premier item pour atteindre l'item chronométré.
    await tester.tap(find.byKey(const ValueKey('decision-option-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('decision-continue')));
    await tester.pump();

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('4 sec'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('decision-pause-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('decision-pause-dialog')), findsOneWidget);

    // Le chrono ne doit pas tourner derrière le dialogue.
    await tester.pump(const Duration(seconds: 5));
    expect(find.byKey(const ValueKey('decision-timeout-title')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('decision-pause-dialog-resume')));
    await tester.pumpAndSettle();
    expect(find.text('4 sec'), findsOneWidget, reason: 'reprise là où on en était');
  });
}
