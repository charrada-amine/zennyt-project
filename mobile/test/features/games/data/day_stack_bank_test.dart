import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/day_stack_bank_loader.dart';
import 'package:zennyt/features/games/domain/entities/day_stack_bank.dart';

/// Intégrité de la banque « Planning journalier » livrée par le client.
///
/// Ces vérifications ne sont pas décoratives : la source exprimait les
/// dépendances en libellés et les contraintes horaires en prose. Chaque test
/// ci-dessous correspond à une erreur de conversion qui produirait un plateau
/// injouable ou un score faux — sans que rien ne le signale au joueur.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DayStackBank bank;

  setUpAll(() async {
    DayStackBankLoader.resetForTest();
    bank = await DayStackBankLoader.load();
  });

  /// Effectifs annoncés par le tableau de normalisation du référentiel.
  /// Le n de contraintes horaires y est décisif : la composante « gestion du
  /// temps » divise par lui, et une divergence fausserait le score.
  const attendu = <String, ({int taches, int horaires, int deps})>{
    'restaurant': (taches: 12, horaires: 6, deps: 9),
    'gestion': (taches: 12, horaires: 7, deps: 8),
    'organisation': (taches: 12, horaires: 7, deps: 8),
    'chantier': (taches: 11, horaires: 5, deps: 9),
    'logistique': (taches: 12, horaires: 6, deps: 9),
    'soins': (taches: 11, horaires: 6, deps: 9),
    'demenagement': (taches: 12, horaires: 7, deps: 10),
  };

  test('les sept univers du référentiel sont présents', () {
    expect(bank.universes, hasLength(7));
    expect(
      bank.universes.map((u) => u.id).toSet(),
      attendu.keys.toSet(),
    );
  });

  test('les effectifs correspondent au tableau de normalisation', () {
    for (final universe in bank.universes) {
      final ref = attendu[universe.id]!;
      expect(universe.tasks, hasLength(ref.taches), reason: universe.name);
      expect(
        universe.timingConstraintCount,
        ref.horaires,
        reason:
            '${universe.name} : le n de contraintes horaires pilote la '
            'composante « gestion du temps »',
      );
      expect(
        universe.tasks.where((t) => t.deps.isNotEmpty).length,
        ref.deps,
        reason: universe.name,
      );
    }
  });

  test('chaque tâche porte ses quatre variantes de libellé', () {
    for (final universe in bank.universes) {
      for (final task in universe.tasks) {
        expect(
          task.variants,
          hasLength(4),
          reason:
              '${universe.id}/${task.id} — les variantes existent pour qu\'un '
              'candidat qui retombe sur cet univers n\'y retrouve pas les '
              'mêmes formulations',
        );
        expect(task.variants.toSet(), hasLength(4), reason: task.id);
      }
    }
  });

  group('dépendances', () {
    test('toutes résolues en identifiants du même univers', () {
      for (final universe in bank.universes) {
        final ids = universe.tasks.map((t) => t.id).toSet();
        for (final task in universe.tasks) {
          for (final dep in task.deps) {
            expect(
              ids,
              contains(dep),
              reason: '${universe.id}/${task.id} dépend de « $dep », inconnu',
            );
          }
        }
      }
    });

    test('le libellé à virgules ne produit pas de fausses dépendances', () {
      // « Commander le matériel (chaises, son, déco) » : découpé sur la
      // virgule, il donnait trois dépendances inexistantes. C'est le seul
      // libellé de la banque dans ce cas, et donc le seul garde-fou utile.
      final task = bank.byId('organisation').byId('reception_materiel');
      expect(task.deps, ['commande_materiel']);
    });

    test('aucun cycle : chaque univers admet un ordre de réalisation', () {
      for (final universe in bank.universes) {
        final deps = {for (final t in universe.tasks) t.id: t.deps};
        final visiting = <String>{};
        final done = <String>{};

        bool cycleFrom(String id, List<String> path) {
          if (done.contains(id)) return false;
          if (!visiting.add(id)) {
            fail('${universe.id} : cycle ${[...path, id].join(' -> ')}');
          }
          for (final dep in deps[id]!) {
            if (cycleFrom(dep, [...path, id])) return true;
          }
          visiting.remove(id);
          done.add(id);
          return false;
        }

        for (final id in deps.keys) {
          cycleFrom(id, const []);
        }
      }
    });
  });

  group('contraintes horaires', () {
    test('une fenêtre commence avant de finir', () {
      for (final universe in bank.universes) {
        for (final task in universe.tasks) {
          final c = task.constraint;
          if (c.kind != DayStackConstraintKind.window) continue;
          expect(c.startMin, isNotNull, reason: task.id);
          expect(c.endMin, isNotNull, reason: task.id);
          expect(c.startMin!, lessThan(c.endMin!), reason: task.id);
        }
      }
    });

    test('chaque forme porte les champs dont son calcul a besoin', () {
      for (final universe in bank.universes) {
        for (final task in universe.tasks) {
          final c = task.constraint;
          final where = '${universe.id}/${task.id}';
          switch (c.kind) {
            case DayStackConstraintKind.window:
              expect(c.startMin, isNotNull, reason: where);
            case DayStackConstraintKind.deadline:
              expect(c.beforeMin, isNotNull, reason: where);
            case DayStackConstraintKind.anchor:
              expect(c.startMin, isNotNull, reason: where);
              // Tolérance ±5 min imposée par le référentiel sur les ancrages.
              expect(c.toleranceMin, 5, reason: where);
            case DayStackConstraintKind.relative:
              expect(c.beforeTaskId, isNotNull, reason: where);
              expect(
                universe.tasks.map((t) => t.id),
                contains(c.beforeTaskId),
                reason: '$where vise une tâche inconnue',
              );
            case DayStackConstraintKind.minDelay:
              expect(c.minDelayMin, isNotNull, reason: where);
            case DayStackConstraintKind.unspecified:
            case DayStackConstraintKind.none:
              break;
          }
        }
      }
    });

    test('toute heure tombe dans une journée', () {
      for (final universe in bank.universes) {
        for (final task in universe.tasks) {
          final c = task.constraint;
          for (final minute in [c.startMin, c.endMin, c.beforeMin]) {
            if (minute == null) continue;
            expect(minute, inInclusiveRange(0, 24 * 60), reason: task.id);
          }
        }
      }
    });

    test('le seul bloc fixe sans heure est celui que le client signale', () {
      final sansHeure = [
        for (final u in bank.universes)
          for (final t in u.tasks)
            if (t.constraint.kind == DayStackConstraintKind.unspecified)
              '${u.id}/${t.id}',
      ];
      // Le référentiel demande de corriger cette donnée avant d'activer le
      // barème. Tant qu'elle est là, on la garde VISIBLE plutôt que comblée par
      // une heure inventée — et ce test échouera si une seconde apparaît.
      expect(sansHeure, ['demenagement/trajet_nouveau_logement']);
    });
  });

  group('durées', () {
    test('toute tâche a une durée de travail strictement positive', () {
      for (final universe in bank.universes) {
        for (final task in universe.tasks) {
          expect(task.durationMin, greaterThan(0), reason: task.id);
          expect(task.restMin, greaterThanOrEqualTo(0), reason: task.id);
        }
      }
    });

    test('le repos passif reste séparé du travail', () {
      // « 20 min + 60 min repos » : les additionner trancherait à la place du
      // psychologue la question — encore ouverte au référentiel — de savoir si
      // le repos bloque le créneau.
      final marinade = bank.byId('restaurant').byId('marinade');
      expect(marinade.durationMin, 20);
      expect(marinade.restMin, 60);
    });
  });

  test('chaque tâche porte son icône et sa famille', () {
    for (final universe in bank.universes) {
      for (final task in universe.tasks) {
        expect(task.icon, isNotNull, reason: '${universe.id}/${task.id}');
        expect(task.category, isNotNull, reason: '${universe.id}/${task.id}');
      }
    }
  });

  test('le tirage de variante ne touche qu\'au libellé', () {
    final task = bank.byId('restaurant').byId('reception_livraison');
    final libelles = {for (var seed = 0; seed < 8; seed++) task.variantAt(seed)};
    expect(libelles, hasLength(4), reason: 'les quatre variantes sortent');
    for (final libelle in libelles) {
      expect(task.variants, contains(libelle));
    }
    // La structure, elle, ne bouge pas — sinon deux sessions du même univers ne
    // seraient plus comparables.
    expect(task.durationMin, 15);
    expect(task.deps, isEmpty);
  });
}
