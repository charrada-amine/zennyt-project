import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/day_stack_bank_loader.dart';
import 'package:zennyt/features/games/domain/entities/day_stack_bank.dart';

/// Tirage des libellés — une variante PAR TÂCHE.
///
/// Le document du client l'écrit en capitales : « tirer aléatoirement UNE
/// variante PAR ÉTAPE à chaque nouvelle session ». Le code tirait auparavant
/// une seule variante pour tout le plateau, ce qui ne faisait que quatre
/// feuilles possibles par univers au lieu de 4¹².
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DayStackBank bank;
  setUpAll(() async {
    DayStackBankLoader.resetForTest();
    bank = await DayStackBankLoader.load();
  });

  test('chaque graine donne une feuille différente', () {
    // LE test qui compte. Le précédent vérifiait seulement que les rangs
    // diffèrent d'une tâche à l'autre sur un même plateau — ce qui était vrai
    // alors même qu'il n'existait que QUATRE feuilles possibles : avec un
    // simple `(seed ^ hash) % 4`, seuls les deux derniers bits de la graine
    // comptaient, et tout le plateau était déterminé par `seed & 3`.
    for (final u in bank.universes) {
      final vues = <String>{};
      for (var seed = 0; seed < 4000; seed++) {
        vues.add(u.tasks.map((t) => t.variantAt(seed)).join('|'));
      }
      expect(
        vues.length,
        greaterThan(3900),
        reason: '${u.id} : ${vues.length} feuilles pour 4000 graines — '
            'les bits hauts de la graine n\'atteignent pas le tirage',
      );
    }
  });

  test('le libellé ne bouge pas sous les yeux du joueur', () {
    // Stable pour une graine donnée : les cartes ne doivent pas se réécrire
    // pendant que le joueur réordonne.
    for (final u in bank.universes) {
      for (final t in u.tasks) {
        expect(t.variantAt(77), t.variantAt(77), reason: '${u.id}/${t.id}');
      }
    }
  });

  test('toutes les variantes restent atteignables', () {
    // Un mélange mal fait pourrait rendre certains libellés inaccessibles :
    // la banque en compte 328, ils doivent tous pouvoir sortir.
    for (final u in bank.universes) {
      for (final t in u.tasks) {
        final vus = <String>{
          for (var seed = 0; seed < 64; seed++) t.variantAt(seed),
        };
        expect(vus.length, t.variants.length, reason: '${u.id}/${t.id}');
      }
    }
  });
}
