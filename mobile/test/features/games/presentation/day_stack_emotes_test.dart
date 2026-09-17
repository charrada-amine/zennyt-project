import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/day_stack_bank_loader.dart';
import 'package:zennyt/features/games/domain/entities/day_stack_bank.dart';
import 'package:zennyt/features/games/presentation/widgets/day_stack_emotes.dart';

/// Emotes des tâches — chemin par identité composite et présence dans le bundle.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DayStackBank bank;
  setUpAll(() async {
    DayStackBankLoader.resetForTest();
    bank = await DayStackBankLoader.load();
  });

  test('le chemin exige un univers et une tâche', () {
    expect(dayStackEmoteAssetPath(), isNull);
    expect(dayStackEmoteAssetPath(universeId: 'restaurant'), isNull);
    expect(dayStackEmoteAssetPath(taskId: 'reception_livraison'), isNull);
    expect(
      dayStackEmoteAssetPath(universeId: '', taskId: 'reception_livraison'),
      isNull,
    );
    expect(
      dayStackEmoteAssetPath(universeId: 'restaurant', taskId: ''),
      isNull,
    );
    expect(
      dayStackEmoteAssetPath(
        universeId: 'restaurant',
        taskId: 'reception_livraison',
      ),
      'assets/Day Stack/emotes-v1/restaurant/reception_livraison.png',
    );
  });

  test('un même identifiant dans deux univers donne deux emotes', () {
    // `chargement_camion` existe en logistique ET en déménagement : l'identifiant
    // seul ferait afficher la même image aux deux.
    for (final universe in ['logistique', 'demenagement']) {
      expect(
        bank.byId(universe).tasks.map((t) => t.id),
        contains('chargement_camion'),
      );
    }
    expect(
      dayStackEmoteAssetPath(
        universeId: 'logistique',
        taskId: 'chargement_camion',
      ),
      isNot(
        dayStackEmoteAssetPath(
          universeId: 'demenagement',
          taskId: 'chargement_camion',
        ),
      ),
    );
  });

  test('une emote distincte pour chacune des 82 tâches', () {
    final paths = <String>{
      for (final universe in bank.universes)
        for (final task in universe.tasks)
          dayStackEmoteAssetPath(universeId: universe.id, taskId: task.id)!,
    };
    expect(paths, hasLength(82));
  });

  test('la variante tirée ne change pas l’emote', () {
    final universe = bank.byId('restaurant');
    final task = universe.byId('reception_livraison');
    final labels = {for (var seed = 0; seed < 8; seed++) task.variantAt(seed)};
    expect(
      labels.length,
      greaterThan(1),
      reason: 'variantes réellement tirées',
    );
    // Le chemin ne dépend que de l'identité, jamais du libellé affiché.
    expect(
      dayStackEmoteAssetPath(universeId: universe.id, taskId: task.id),
      'assets/Day Stack/emotes-v1/restaurant/reception_livraison.png',
    );
  });

  test('les 82 emotes du manifest sont embarquées dans le bundle', () async {
    // Le manifest reste un fichier de relecture, non embarqué : on le lit
    // depuis le disque pour vérifier que chaque couple de la banque a son
    // image, et que chaque image répond bien depuis le bundle de l'app.
    final manifest =
        jsonDecode(
              File('$kDayStackEmotesRoot/manifest.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    final entries = (manifest['emotes'] as List).cast<Map<String, dynamic>>();
    final fromManifest = {
      for (final entry in entries)
        '${entry['universeId']}/${entry['taskId']}': entry['file'] as String,
    };
    final fromBank = {
      for (final universe in bank.universes)
        for (final task in universe.tasks) '${universe.id}/${task.id}',
    };
    expect(entries, hasLength(82));
    expect(fromManifest.keys.toSet(), fromBank);

    for (final universe in bank.universes) {
      for (final task in universe.tasks) {
        final path = dayStackEmoteAssetPath(
          universeId: universe.id,
          taskId: task.id,
        )!;
        expect(
          path,
          '$kDayStackEmotesRoot/${fromManifest['${universe.id}/${task.id}']}',
        );
        final data = await rootBundle.load(path);
        // Signature PNG : le bundle sert bien l'image, pas un fichier vide.
        expect(data.lengthInBytes, greaterThan(8), reason: path);
        expect(data.buffer.asUint8List(0, 4), [0x89, 0x50, 0x4E, 0x47]);
      }
    }
  });

  test('le décodage suit la taille affichée et la densité de l’écran', () {
    expect(dayStackEmoteCacheWidth(kDayStackEmoteCompactSize, 1), 32);
    expect(dayStackEmoteCacheWidth(kDayStackEmoteCompactSize, 2.625), 84);
    expect(dayStackEmoteCacheWidth(kDayStackEmoteSize, 3), 114);
  });
}
