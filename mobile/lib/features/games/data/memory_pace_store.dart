import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/shared_preferences_provider.dart';
import '../domain/config/memory_quest_config.dart';

/// Mémorise l'**allure** d'un joueur sur MemoryQuest d'une partie à l'autre.
///
/// Le barème de [MemoryQuestConfig.objectObservationMs] est une moyenne de
/// population ; un joueur donné s'en écarte facilement de ±40 %. L'escalier
/// adaptatif recale ce barème partie après partie, mais il ne sert à rien s'il
/// repart de zéro à chaque ouverture du jeu : c'est ce que cette classe évite.
///
/// La valeur est locale à l'appareil, et volontairement pas envoyée au backend :
/// elle règle le confort de jeu, elle n'entre dans aucun score. Un score resterait
/// comparable entre joueurs seulement si tous recevaient le même temps.
/// Le magasin de préférences peut manquer ([_prefs] nul) : le jeu tourne alors
/// au barème de référence, sans rien mémoriser. La persistance de l'allure est
/// un confort, pas une condition de fonctionnement — la faire échouer bruyamment
/// couperait une partie pour une raison qui n'a aucun effet sur le score.
class MemoryPaceStore {
  const MemoryPaceStore(this._prefs);

  final SharedPreferences? _prefs;

  static const String _key = 'memory_quest.player_pace';

  /// Allure enregistrée, ou [MemoryQuestConfig.playerPaceNeutral] au premier
  /// lancement. Une valeur hors bornes (fichier de préférences trafiqué, ou
  /// bornes resserrées depuis) est ramenée dans l'intervalle plutôt que rejetée.
  double read() {
    final stored = _prefs?.getDouble(_key);
    if (stored == null || stored.isNaN) {
      return MemoryQuestConfig.playerPaceNeutral;
    }
    return stored.clamp(
      MemoryQuestConfig.playerPaceMin,
      MemoryQuestConfig.playerPaceMax,
    );
  }

  Future<void> write(double factor) async {
    await _prefs?.setDouble(
      _key,
      factor.clamp(
        MemoryQuestConfig.playerPaceMin,
        MemoryQuestConfig.playerPaceMax,
      ),
    );
  }

  /// Remet le joueur au barème de référence.
  Future<void> reset() async {
    await _prefs?.remove(_key);
  }
}

final memoryPaceStoreProvider = Provider<MemoryPaceStore>((ref) {
  // `sharedPreferencesProvider` n'est résolu que par `main()`. Hors application
  // — tests de widget, previews — il est en erreur : on retombe alors sur un
  // magasin sans stockage plutôt que de propager l'erreur jusqu'à l'écran.
  // Riverpod enveloppe l'erreur dans un type non exporté, d'où le `on Object` :
  // il n'y a de toute façon qu'une seule issue utile ici, jouer sans mémoire.
  try {
    return MemoryPaceStore(ref.watch(sharedPreferencesProvider));
  } on Object {
    return const MemoryPaceStore(null);
  }
});
