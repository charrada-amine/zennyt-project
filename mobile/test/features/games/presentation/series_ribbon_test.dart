import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/presentation/widgets/game_system_components.dart';

/// Bandeau de série, calé sur la maquette Figma.
///
/// Les chiffres des pastilles y étaient illisibles — 10 px dans un cercle de
/// 20 — alors que la maquette les veut nettement plus grands. Agrandir un
/// élément d'une rangée est exactement le geste qui provoque un débordement :
/// ces tests verrouillent la taille ET l'absence de débordement, du plus petit
/// écran Android à une tablette.
void main() {
  Widget host(Widget child, {required double width}) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: width, child: child),
          ),
        ),
      );

  const ribbon = SeriesRibbon(
    current: 4,
    multiplier: 5,
    color: Color(0xFF22C55E),
    statusValue: '4/4',
    statusCaption: 'upgrade',
  );

  testWidgets('rend le compteur sur deux lignes et le multiplicateur',
      (tester) async {
    await tester.pumpWidget(host(ribbon, width: 340));

    expect(find.text('Series'), findsOneWidget);
    expect(find.text('4/4'), findsOneWidget);
    expect(find.text('upgrade'), findsOneWidget);
    expect(find.text('x5'), findsOneWidget);
    for (var i = 1; i <= 4; i++) {
      expect(find.text('$i'), findsOneWidget);
    }
  });

  testWidgets('les chiffres des pastilles sont lisibles', (tester) async {
    await tester.pumpWidget(host(ribbon, width: 340));

    final style = tester.widget<Text>(find.text('1')).style!;
    expect(
      style.fontSize,
      greaterThanOrEqualTo(16),
      reason: 'la maquette porte le chiffre à 18 px ; il était à 10',
    );
    expect(style.fontWeight, FontWeight.w800);
  });

  for (final width in <double>[280, 320, 360, 390, 430, 700]) {
    testWidgets('aucun débordement à ${width.toInt()} px', (tester) async {
      await tester.pumpWidget(host(ribbon, width: width));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('une police système à 200 % ne fait pas déborder le bandeau',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: const Scaffold(
            body: Center(child: SizedBox(width: 360, child: ribbon)),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
