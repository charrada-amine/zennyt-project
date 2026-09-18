import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/presentation/widgets/game_results_template.dart';
import 'package:zennyt/features/games/presentation/widgets/game_system_components.dart';

/// Contrat de l'écran de score commun à TOUS les jeux (référence « Je Bouge »).
///
/// Les douze jeux passent par ce modèle : ce qui est vérifié ici vaut pour
/// chacun d'eux, sans dépendre d'une partie jouée jusqu'au bout.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget subject({
    int? percent = 70,
    int? points = 7,
    int? maxPoints = 10,
    bool pending = false,
  }) => MaterialApp(
    home: Scaffold(
      body: GameResultsTemplate(
        onBack: () {},
        gameName: 'Reflective Pause',
        scoreLabel: 'Self-control score',
        scorePercent: percent,
        points: points,
        maxPoints: maxPoints,
        pending: pending,
        stats: const [
          GameResultStat(label: 'Reaction control', value: '3/3'),
          GameResultStat(label: 'Non-impulsive', value: '4/4'),
          GameResultStat(label: 'Step back', value: '0.3/3'),
        ],
        insight: 'Bonne gestion du stress — you mostly paused.',
        primaryLabel: 'Rejouer',
        onPrimary: () {},
        secondaryLabel: 'Insights',
        onSecondary: () {},
      ),
    ),
  );

  testWidgets('score en %, points du barème, trois tuiles, deux actions', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    // Le score compte de 0 à sa valeur, comme sur « Je Bouge ».
    expect(find.text('0%'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Résultats'), findsOneWidget);
    expect(find.text('Reflective Pause terminé'), findsOneWidget);
    expect(find.text('70%'), findsOneWidget);
    expect(find.text('7 / 10 points calculés par le serveur.'), findsOneWidget);
    expect(find.byType(ResultStatTile), findsNWidgets(3));
    expect(find.text('Synthèse'), findsOneWidget);
    expect(find.byType(GamePrimaryButton), findsOneWidget);
    expect(find.byType(GameOutlineButton), findsOneWidget);
  });

  testWidgets('pendant la remontée : synchronisation, sans faux score', (
    tester,
  ) async {
    await tester.pumpWidget(subject(pending: true));
    await tester.pumpAndSettle();

    expect(find.text('Synchronisation du score…'), findsOneWidget);
    expect(find.text('Score en cours de calcul.'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });

  for (final size in const [Size(320, 568), Size(390, 844), Size(844, 390)]) {
    testWidgets('tient sur $size sans défilement ni débordement', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(subject());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(Scrollable), findsNothing);
      expect(find.text('Rejouer').hitTestable(), findsOneWidget);
      expect(find.text('Insights').hitTestable(), findsOneWidget);
    });
  }
}
