import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/day_stack_bank_loader.dart';
import 'package:zennyt/features/games/domain/entities/day_stack_bank.dart';
import 'package:zennyt/features/games/domain/service/day_stack_schedule.dart';

/// Le moteur qui transforme un ORDRE en planning horaire.
///
/// Trois des quatre composantes du barème client s'y adossent — dépendances,
/// gestion du temps, cohérence séquentielle. Une erreur ici produirait un score
/// faux qui aurait l'air juste, d'où le niveau de détail de ces tests.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DayStackBank bank;
  setUpAll(() async {
    DayStackBankLoader.resetForTest();
    bank = await DayStackBankLoader.load();
  });

  /// Ordre canonique d'un univers : les tâches dans l'ordre de la banque.
  ///
  /// Les prérequis y précèdent toujours leurs dépendants — c'est ainsi que la
  /// source est écrite — donc cet ordre satisfait toutes les dépendances. Il
  /// sert de référence « joueur compétent ».
  List<String> canonical(DayStackUniverse u) =>
      u.tasks.map((t) => t.id).toList();

  group('ouverture de la journée', () {
    test('déduite de la première heure contraignante', () {
      // Restaurant : la livraison ouvre à 7h, c'est la première heure de
      // l'univers. Démarrer plus tard rendrait sa propre fenêtre intenable.
      expect(dayStackStartOf(bank.byId('restaurant')), 7 * 60);
      expect(dayStackStartOf(bank.byId('gestion')), 9 * 60);
      expect(dayStackStartOf(bank.byId('chantier')), 8 * 60);
    });

    test('toute échéance reste atteignable depuis l\'ouverture', () {
      // Deux tâches de la banque doivent être finies « Avant 8h » dans des
      // univers dont la première fenêtre n'ouvre qu'à 8h00. Déduire l'ouverture
      // des seules fenêtres les rendait impossibles à tenir, même faites en
      // premier — l'ouverture recule donc aussi devant les échéances.
      for (final u in bank.universes) {
        final start = dayStackStartOf(u);
        for (final t in u.tasks) {
          final before = t.constraint.beforeMin;
          if (before == null) continue;
          expect(
            start + t.durationMin,
            lessThanOrEqualTo(before),
            reason: '${u.id}/${t.id} : intenable dès l\'ouverture',
          );
        }
      }
    });
  });

  group('pose sur l\'horloge', () {
    test('les tâches s\'enchaînent, et l\'attente devient du temps mort', () {
      final u = bank.byId('restaurant');
      final s = buildDayStackSchedule(
        universe: u,
        order: ['reception_livraison', 'inventaire_stock'],
      );

      // 7h00 : la livraison ouvre, aucune attente.
      expect(s.placements.first.startMin, 7 * 60);
      expect(s.placements.first.endMin, 7 * 60 + 15);
      expect(s.placements.first.waitBeforeMin, 0);
      // L'inventaire enchaîne sans trou.
      expect(s.placements[1].startMin, 7 * 60 + 15);
      expect(s.deadTimeMin, 0);
      expect(s.totalWorkMin, 25);
    });

    test('une fenêtre qui n\'est pas ouverte fait attendre', () {
      final u = bank.byId('soins');
      // medicament_a n'ouvre qu'à 8h ; en partant à 8h la journée est déjà
      // ouverte, donc on force une ouverture plus tôt pour observer l'attente.
      final s = buildDayStackSchedule(
        universe: u,
        order: ['consulter_dossier', 'trajet_patient_a', 'medicament_a'],
        dayStartMin: 6 * 60,
      );
      final med = s.placementOf('medicament_a')!;
      expect(med.startMin, 8 * 60, reason: 'la fenêtre médicament ouvre à 8h');
      expect(med.waitBeforeMin, greaterThan(0));
      expect(s.deadTimeMin, med.waitBeforeMin);
    });

    test('le repos passif retarde les dépendants sans occuper le planning', () {
      final u = bank.byId('restaurant');
      // marinade : 20 min de travail + 60 min de repos. mise_en_place en
      // dépend, elle ne peut donc pas démarrer avant la fin du repos — mais le
      // planning, lui, est libre entre les deux.
      final s = buildDayStackSchedule(
        universe: u,
        order: ['marinade', 'mise_en_place'],
      );
      final marinade = s.placementOf('marinade')!;
      final suite = s.placementOf('mise_en_place')!;

      expect(marinade.endMin - marinade.startMin, 20, reason: 'travail seul');
      expect(marinade.readyMin, marinade.endMin + 60, reason: 'repos ensuite');
      expect(suite.startMin, greaterThanOrEqualTo(marinade.readyMin));
      // Le repos n'est pas compté comme du travail : c'est l'hypothèse retenue,
      // et elle change le total.
      expect(s.totalWorkMin, 40);
    });
  });

  group('dépendances', () {
    test('l\'ordre canonique les respecte toutes, dans les sept univers', () {
      for (final u in bank.universes) {
        final s = buildDayStackSchedule(universe: u, order: canonical(u));
        expect(
          s.dependencyEdgesRespected,
          s.dependencyEdgeCount,
          reason: u.name,
        );
        expect(
          s.violations.where(
            (v) => v.kind == DayStackViolationKind.dependency,
          ),
          isEmpty,
          reason: u.name,
        );
      }
    });

    test('placer une tâche avant son prérequis est une violation directe', () {
      final u = bank.byId('restaurant');
      final s = buildDayStackSchedule(
        universe: u,
        order: ['inventaire_stock', 'reception_livraison'],
      );
      final direct = s.violations.where(
        (v) => v.kind == DayStackViolationKind.dependency,
      );
      expect(direct, hasLength(1));
      expect(direct.first.taskId, 'inventaire_stock');
      expect(direct.first.otherTaskId, 'reception_livraison');
    });
  });

  group('contraintes horaires', () {
    test('le dénominateur est le n RÉEL de l\'univers, jamais une constante', () {
      // Le référentiel insiste : n varie de 5 à 7, et diviser par une constante
      // rendrait deux passations incomparables.
      const attendu = {
        'restaurant': 6,
        'gestion': 7,
        'organisation': 7,
        'chantier': 5,
        'logistique': 6,
        'soins': 6,
        'demenagement': 7,
      };
      for (final u in bank.universes) {
        final s = buildDayStackSchedule(universe: u, order: canonical(u));
        final defaut = u.tasks.where(
          (t) => t.constraint.kind == DayStackConstraintKind.unspecified,
        );
        // Le bloc fixe sans heure sort du dénominateur : il ne peut être ni
        // respecté ni violé, le compter en échec pénaliserait une donnée
        // manquante.
        expect(
          s.timingConstraintCount,
          attendu[u.id]! - defaut.length,
          reason: u.name,
        );
      }
    });

    test('une échéance dépassée est relevée', () {
      final u = bank.byId('logistique');
      // consulter_commandes doit être terminée avant 8h. En la plaçant après
      // une tâche longue, elle déborde.
      final s = buildDayStackSchedule(
        universe: u,
        order: ['prep_zones_picking', 'consulter_commandes'],
        dayStartMin: 7 * 60 + 50,
      );
      expect(
        s.violations.any(
          (v) =>
              v.kind == DayStackViolationKind.timing &&
              v.taskId == 'consulter_commandes',
        ),
        isTrue,
      );
    });

    test('un ancrage tolère ±5 min, pas davantage', () {
      final u = bank.byId('restaurant');
      // service est ancré à 12h00 pile. On le place seul, en calant l'ouverture
      // pour qu'il démarre exactement à l'heure, puis 6 min trop tard.
      final pile = buildDayStackSchedule(
        universe: u,
        order: ['service'],
        dayStartMin: 12 * 60,
      );
      expect(
        pile.violations.where((v) => v.kind == DayStackViolationKind.timing),
        isEmpty,
      );

      final tard = buildDayStackSchedule(
        universe: u,
        order: ['service'],
        dayStartMin: 12 * 60 + 6,
      );
      expect(
        tard.violations.any(
          (v) => v.kind == DayStackViolationKind.timing && v.taskId == 'service',
        ),
        isTrue,
        reason: '6 min de retard sortent de la tolérance de ±5',
      );
    });

    test('une échéance relative se résout contre sa tâche cible', () {
      final u = bank.byId('gestion');
      // prep_ordre_jour doit être terminée avant que reunion_equipe ne commence.
      final bon = buildDayStackSchedule(
        universe: u,
        order: ['prep_ordre_jour', 'reunion_equipe'],
      );
      expect(
        bon.violations.any((v) => v.taskId == 'prep_ordre_jour'),
        isFalse,
      );

      final mauvais = buildDayStackSchedule(
        universe: u,
        order: ['reunion_equipe', 'prep_ordre_jour'],
      );
      expect(
        mauvais.violations.any(
          (v) =>
              v.kind == DayStackViolationKind.timing &&
              v.taskId == 'prep_ordre_jour',
        ),
        isTrue,
      );
    });
  });

  group('collision', () {
    test('un bloc fixe empêché de démarrer à l\'heure est une collision', () {
      final u = bank.byId('gestion');
      // pause_dejeuner est un bloc fixe 12h-13h. En lançant une longue tâche
      // qui court encore à 12h, le bloc ne peut plus démarrer à l'heure.
      final s = buildDayStackSchedule(
        universe: u,
        order: ['redaction_rapport', 'pause_dejeuner'],
        dayStartMin: 11 * 60 + 30,
      );
      expect(s.hasCollision, isTrue);
      expect(
        s.violations.any(
          (v) =>
              v.kind == DayStackViolationKind.collision &&
              v.taskId == 'pause_dejeuner',
        ),
        isTrue,
      );
    });

    test('un bloc fixe qui démarre à l\'heure ne collisionne pas', () {
      final u = bank.byId('gestion');
      final s = buildDayStackSchedule(
        universe: u,
        order: ['pause_dejeuner'],
        dayStartMin: 12 * 60,
      );
      expect(s.hasCollision, isFalse);
    });
  });

  group('temps mort', () {
    test('nul quand rien n\'oblige à attendre', () {
      final u = bank.byId('restaurant');
      final s = buildDayStackSchedule(
        universe: u,
        order: ['reception_livraison', 'inventaire_stock', 'nettoyage_poste'],
      );
      expect(s.deadTimeMin, 0);
      expect(s.deadTimeRatio, 0);
    });

    test('rapporté à l\'amplitude occupée, pas à la somme des durées', () {
      final u = bank.byId('restaurant');
      final s = buildDayStackSchedule(
        universe: u,
        order: ['reception_livraison', 'service'],
      );
      // service est ancré à 12h : entre la fin de la livraison (7h15) et 12h,
      // le planning ne fait rien. C'est cette amplitude que le barème regarde.
      expect(s.deadTimeMin, greaterThan(0));
      expect(s.deadTimeRatio, greaterThan(0.5));
      expect(s.deadTimeRatio, lessThanOrEqualTo(1));
    });
  });

  test('un planning partiel s\'évalue, pour signaler l\'erreur à temps', () {
    // C'est ce qui permettra de distinguer une correction PROACTIVE d'une
    // correction RÉACTIVE : sans évaluation en cours de partie, le jeu ne peut
    // rien signaler, et la composante « autorégulation » perd son sens.
    final u = bank.byId('restaurant');
    final s = buildDayStackSchedule(
      universe: u,
      order: ['inventaire_stock'],
    );
    expect(s.placements, hasLength(1));
    expect(
      s.violations.any((v) => v.kind == DayStackViolationKind.dependency),
      isTrue,
      reason: 'le prérequis manque déjà, on peut le dire tout de suite',
    );
  });

  group('jouabilité', () {
    /// Cherche un ordre sans AUCUNE violation, par parcours en profondeur des
    /// ordres topologiques, en élaguant dès qu'une violation apparaît.
    ///
    /// Une heuristique ne prouverait rien : son échec ne distingue pas « pas de
    /// plan » de « mauvaise heuristique ». Ici, échouer signifie qu'aucun ordre
    /// n'existe. Les univers se résolvent en une quinzaine de nœuds.
    List<String>? planSansViolation(DayStackUniverse u) {
      final n = u.tasks.length;
      var budget = 400000;
      List<String>? found;

      bool dfs(List<String> acc, Set<String> left) {
        if (budget-- < 0) return false;
        if (acc.length == n) {
          final s = buildDayStackSchedule(universe: u, order: acc);
          if (s.violations.isEmpty) {
            found = List.of(acc);
            return true;
          }
          return false;
        }
        final ready = left
            .map(u.byId)
            .where((t) => t.deps.every(acc.contains))
            .toList();
        for (final t in ready) {
          acc.add(t.id);
          left.remove(t.id);
          final partial = buildDayStackSchedule(universe: u, order: acc);
          final fatale = partial.violations.any(
            (v) =>
                v.kind == DayStackViolationKind.collision ||
                (v.kind == DayStackViolationKind.timing &&
                    u.byId(v.taskId).constraint.kind !=
                        DayStackConstraintKind.relative &&
                    u.byId(v.taskId).constraint.kind !=
                        DayStackConstraintKind.minDelay),
          );
          if (!fatale && dfs(acc, left)) return true;
          acc.removeLast();
          left.add(t.id);
        }
        return false;
      }

      dfs(<String>[], u.tasks.map((t) => t.id).toSet());
      return found;
    }

    test('six univers admettent un plan parfait', () {
      for (final u in bank.universes) {
        if (u.id == 'demenagement') continue; // voir le test suivant
        final plan = planSansViolation(u);
        expect(
          plan,
          isNotNull,
          reason:
              '${u.name} : un univers où le 10/10 est hors d\'atteinte '
              'frustrerait le joueur sans qu\'il comprenne pourquoi',
        );
        final s = buildDayStackSchedule(universe: u, order: plan!);
        expect(s.violations, isEmpty, reason: u.name);
        expect(s.dependencyEdgesRespected, s.dependencyEdgeCount);
        expect(s.timingConstraintsRespected, s.timingConstraintCount);
      }
    });

    test('Déménagement contient une contradiction de données', () {
      // Contradiction arithmétique, pas une affaire d'ordre :
      //   chargement_camion   fenêtre 10h-11h, durée 60 min -> démarre à 10h00
      //   recuperation_camion fenêtre ouvre à 10h, durée 20 -> finit à 10h20
      //   et chargement_camion DÉPEND de recuperation_camion.
      // Le 10/10 y est donc inatteignable. À remonter au client, au même titre
      // que le bloc fixe sans heure qu'il a lui-même signalé. Ce test tombera
      // le jour où la donnée sera corrigée — c'est le but.
      final u = bank.byId('demenagement');
      final charge = u.byId('chargement_camion');
      final recup = u.byId('recuperation_camion');

      expect(charge.deps, contains('recuperation_camion'));
      final dernierDepart = charge.constraint.endMin! - charge.durationMin;
      final plusTotFini = recup.constraint.startMin! + recup.durationMin;
      expect(
        plusTotFini,
        greaterThan(dernierDepart),
        reason: 'si cette inégalité tombe, la contradiction est levée',
      );

      expect(planSansViolation(u), isNull);
    });
  });
}
