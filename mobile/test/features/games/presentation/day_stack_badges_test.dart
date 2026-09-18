import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/app_icon_finders.dart';
import 'package:zennyt/shared/icons/app_icons.dart';
import 'package:zennyt/features/games/data/day_stack_bank_loader.dart';
import 'package:zennyt/features/games/domain/entities/day_stack_bank.dart';
import 'package:zennyt/features/games/presentation/widgets/day_stack_badges.dart';
import 'package:zennyt/features/games/presentation/widgets/day_stack_emotes.dart';

/// Badges de tâches — couverture et lisibilité.
///
/// La banque référence 50 icônes et 8 familles. Une icône non mappée
/// retomberait sur un rond générique, et une famille sans couleur sur un gris :
/// ni l'un ni l'autre ne casse l'application, donc rien ne les signalerait.
/// Ces tests sont le seul filet.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DayStackBank bank;
  setUpAll(() async {
    DayStackBankLoader.resetForTest();
    bank = await DayStackBankLoader.load();
  });

  Iterable<DayStackTask> allTasks() sync* {
    for (final u in bank.universes) {
      yield* u.tasks;
    }
  }

  test('les 50 icônes de la banque sont toutes mappées', () {
    final manquantes = <String>{};
    for (final task in allTasks()) {
      final name = task.icon;
      if (name == null || !kDayStackTablerToHuge.containsKey(name)) {
        manquantes.add(name ?? '(aucune)');
      }
    }
    expect(
      manquantes,
      isEmpty,
      reason: 'sans correspondance, le badge retombe sur un rond générique',
    );
  });

  test('les 8 familles ont toutes leur couleur', () {
    final manquantes = <String>{};
    for (final task in allTasks()) {
      final category = task.category;
      if (category == null || !kDayStackCategoryColors.containsKey(category)) {
        manquantes.add(category ?? '(aucune)');
      }
    }
    expect(manquantes, isEmpty);
    expect(kDayStackCategoryColors, hasLength(8));
  });

  test('aucune couleur de famille n\'est utilisée deux fois', () {
    // Une couleur = une famille : deux familles de même teinte détruiraient le
    // code couleur que le joueur est censé apprendre une fois.
    final valeurs = kDayStackCategoryColors.values.map((c) => c.toARGB32());
    expect(valeurs.toSet(), hasLength(kDayStackCategoryColors.length));
  });

  test('une icône blanche reste lisible sur chaque badge', () {
    // Le badge porte une icône BLANCHE : son aplat doit donc être assez sombre.
    // Seuil de 3:1, celui qu'un pictogramme demande — un texte en exigerait 4,5.
    //
    // Le même calcul vaut contre la carte : le client a comparé ses badges sur
    // le violet de sa maquette, mais dans le jeu les tâches vivent sur des
    // cartes BLANCHES. Un aplat assez sombre pour une icône blanche se détache
    // donc aussi du fond.
    for (final entry in kDayStackCategoryColors.entries) {
      final ratio = _contrastRatio(entry.value, const Color(0xFFFFFFFF));
      expect(
        ratio,
        greaterThanOrEqualTo(3.0),
        reason: '${entry.key} : contraste ${ratio.toStringAsFixed(2)}:1 '
            'insuffisant pour une icône blanche',
      );
    }
  });

  testWidgets('le badge suit les recommandations visuelles', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: DayStackTaskBadge(
              category: 'Santé & sécurité',
              icon: 'ti-pill',
            ),
          ),
        ),
      ),
    );

    // 38×38 en liste, coin ~10 px, icône 20 px, aplat sans dégradé.
    expect(tester.getSize(find.byType(DayStackTaskBadge)), const Size(38, 38));
    final icon = tester.widget<AppIcon>(find.byType(AppIcon));
    expect(icon.size, 20);
    expect(icon.color, Colors.white);
    expect(icon.icon, kDayStackTablerToHuge['ti-pill']);

    final box = tester.widget<Container>(
      find.descendant(
        of: find.byType(DayStackTaskBadge),
        matching: find.byType(Container),
      ),
    );
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.gradient, isNull, reason: 'aplat, jamais de dégradé');
    expect(decoration.color, kDayStackCategoryColors['Santé & sécurité']);
  });

  Future<void> pumpBadge(
    WidgetTester tester,
    DayStackTaskBadge badge, {
    double devicePixelRatio = 1,
  }) async {
    tester.view.devicePixelRatio = devicePixelRatio;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: badge)),
      ),
    );
  }

  /// Attend la fin réelle du chargement : décoder un PNG sort du temps simulé.
  Future<void> settleImage(WidgetTester tester) async {
    await tester.runAsync(() async {
      final image = find.byType(Image);
      await precacheImage(
        tester.widget<Image>(image).image,
        tester.element(image),
        onError: (_, _) {},
      );
    });
    await tester.pump();
  }

  testWidgets('sans identité, le carré historique garde ses dimensions', (
    tester,
  ) async {
    for (final (compact, side) in [(true, 28.0), (false, 38.0)]) {
      await pumpBadge(
        tester,
        DayStackTaskBadge(
          category: 'Santé & sécurité',
          icon: 'ti-pill',
          compact: compact,
          universeId: compact ? null : 'restaurant',
        ),
      );
      expect(find.byType(Image), findsNothing);
      expect(findAppIcon(dayStackIcon('ti-pill')), findsOneWidget);
      expect(tester.getSize(find.byType(DayStackTaskBadge)), Size(side, side));
    }
  });

  testWidgets('une emote introuvable retombe sur l’icône sans décaler', (
    tester,
  ) async {
    for (final (compact, side) in [
      (true, kDayStackEmoteCompactSize),
      (false, kDayStackEmoteSize),
    ]) {
      await pumpBadge(
        tester,
        DayStackTaskBadge(
          category: 'Stock & contrôle',
          icon: 'ti-box',
          compact: compact,
          universeId: 'univers_inconnu',
          taskId: 'tache_absente',
        ),
      );
      expect(tester.getSize(find.byType(DayStackTaskBadge)), Size(side, side));
      await settleImage(tester);
      expect(findAppIcon(dayStackIcon('ti-box')), findsOneWidget);
      expect(tester.getSize(find.byType(DayStackTaskBadge)), Size(side, side));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('l’emote est décodée à sa taille d’affichage', (tester) async {
    await pumpBadge(
      tester,
      const DayStackTaskBadge(
        category: 'Réception & transport',
        icon: 'ti-truck',
        compact: true,
        universeId: 'restaurant',
        taskId: 'reception_livraison',
      ),
      devicePixelRatio: 3,
    );
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.width, kDayStackEmoteCompactSize);
    expect(image.height, kDayStackEmoteCompactSize);
    expect(image.fit, BoxFit.contain);
    expect(image.excludeFromSemantics, isTrue);
    final provider = image.image as ResizeImage;
    expect(provider.width, 96, reason: '32 points × densité 3');
    expect(
      (provider.imageProvider as AssetImage).assetName,
      'assets/Day Stack/emotes-v1/restaurant/reception_livraison.png',
    );
    expect(
      find.descendant(
        of: find.byType(DayStackTaskBadge),
        matching: find.byType(Container),
      ),
      findsNothing,
      reason: 'le PNG transparent porte son contour, sans carré coloré',
    );
    expect(
      tester.getSize(find.byType(DayStackTaskBadge)),
      const Size.square(kDayStackEmoteCompactSize),
    );
  });

  testWidgets('une emote connue se charge, sans repli sur l’icône', (
    tester,
  ) async {
    await pumpBadge(
      tester,
      const DayStackTaskBadge(
        category: 'Réception & transport',
        icon: 'ti-truck',
        compact: true,
        universeId: 'logistique',
        taskId: 'chargement_camion',
      ),
      devicePixelRatio: 2,
    );
    await settleImage(tester);
    final raw = tester.widget<RawImage>(find.byType(RawImage));
    expect(raw.image, isNotNull, reason: 'PNG décodé depuis le bundle');
    expect(raw.image!.width, 64, reason: 'décodé à 32 points × densité 2');
    expect(find.byType(AppIcon), findsNothing);
    expect(
      tester.getSize(find.byType(DayStackTaskBadge)),
      const Size.square(kDayStackEmoteCompactSize),
    );
    expect(tester.takeException(), isNull);
  });

  test('une icône fixe par identifiant, quelle que soit la variante tirée', () {
    // Le référentiel l'exige : l'icône est indexée sur l'identifiant de tâche,
    // pas sur le libellé tiré. Elle ne doit donc pas changer d'une session à
    // l'autre.
    final task = bank.byId('restaurant').byId('reception_livraison');
    final attendu = dayStackIcon(task.icon);
    for (var seed = 0; seed < 8; seed++) {
      task.variantAt(seed); // le libellé change…
      expect(dayStackIcon(task.icon), attendu); // …l'icône non
    }
  });
}

/// Ratio de contraste WCAG entre deux couleurs opaques.
double _contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

double _relativeLuminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}
