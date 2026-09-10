import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zennyt/core/router/app_routes.dart';
import 'package:zennyt/features/games/presentation/view/games_hub_screen.dart';
import 'package:zennyt/features/games/presentation/view/investigate_screen.dart';

/// Ce que le HUB ouvre réellement quand on tape une carte.
///
/// Les tests d'écran instancient `InvestigateScreen` en lui passant le mode
/// directement : ils ne prouvent donc rien sur le chemin qu'emprunte un joueur.
/// Le client rapportait « j'ai 2 jeux Memory Quest Digits » — un symptôme qui,
/// s'il venait d'un mauvais routage, aurait été invisible pour toute la suite de
/// tests existante. Ce garde-fou ferme ce trou : il part de la carte, comme le
/// joueur, et vérifie le MODE de l'écran obtenu.
void main() {
  /// Router minimal : le hub + les deux moitiés de « J'investigue », déclarées
  /// avec les mêmes chemins que l'application.
  GoRouter buildRouter() => GoRouter(
        initialLocation: AppRoutes.games,
        routes: [
          GoRoute(
            path: AppRoutes.games,
            builder: (_, _) => const GamesHubScreen(),
          ),
          GoRoute(
            path: AppRoutes.gamesInvestigateDigits,
            builder: (_, _) =>
                const InvestigateScreen(mode: InvestigateMode.digits),
          ),
          GoRoute(
            path: AppRoutes.gamesInvestigateImages,
            builder: (_, _) =>
                const InvestigateScreen(mode: InvestigateMode.images),
          ),
        ],
      );

  Future<InvestigateMode> openFromHub(
    WidgetTester tester,
    String gameLabel,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    // Working Memory porte plusieurs jeux → la carte ouvre un sélecteur.
    await tester.tap(find.byKey(const ValueKey('game-category-working-memory')));
    await tester.pumpAndSettle();

    await tester.tap(find.text(gameLabel));
    await tester.pumpAndSettle();

    return tester
        .widget<InvestigateScreen>(find.byType(InvestigateScreen))
        .mode;
  }

  testWidgets('« Memory Quest · Digits » ouvre bien le mode chiffres', (
    tester,
  ) async {
    expect(
      await openFromHub(tester, 'Memory Quest · Digits'),
      InvestigateMode.digits,
    );
  });

  testWidgets('« Memory Quest · Images » ouvre bien le mode images', (
    tester,
  ) async {
    expect(
      await openFromHub(tester, 'Memory Quest · Images'),
      InvestigateMode.images,
    );
  });

  /// Build de test : seuls six jeux sont ouverts. Les autres restent **visibles
  /// et à leur place** — le menu qu'on fait valider doit être celui du produit —
  /// mais grisés et inertes.
  testWidgets('seuls les jeux ouverts sont cliquables dans le sélecteur', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: buildRouter())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('game-category-working-memory')));
    await tester.pumpAndSettle();

    // Les trois jeux sont listés…
    expect(find.text('Memory Quest · Digits'), findsOneWidget);
    expect(find.text('Memory Quest · Images'), findsOneWidget);
    expect(find.text('Je place'), findsOneWidget);

    // …mais « Je place » porte le badge « Bientôt » et n'ouvre rien. Le badge
    // sert aussi aux catégories vides du hub, encore montées derrière la
    // feuille : on cible celui de la tuile.
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Je place'),
          matching: find.byType(Material),
        ).first,
        matching: find.text('Bientôt'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Je place'));
    await tester.pumpAndSettle();
    expect(
      find.text('Memory Quest · Digits'),
      findsOneWidget,
      reason: 'le sélecteur doit rester ouvert : le jeu est inerte',
    );
  });

  testWidgets('les deux entrées de Working Memory sont distinctes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: buildRouter()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('game-category-working-memory')));
    await tester.pumpAndSettle();

    // Le client en voyait « deux fois Digits » : on verrouille un libellé de
    // chacun, et un seul.
    expect(find.text('Memory Quest · Digits'), findsOneWidget);
    expect(find.text('Memory Quest · Images'), findsOneWidget);
  });
}
