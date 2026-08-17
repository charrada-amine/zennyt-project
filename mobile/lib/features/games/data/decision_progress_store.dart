import 'package:shared_preferences/shared_preferences.dart';

/// Persistance locale minimale du point de reprise de « Je Décide ».
///
/// Seul le fait qu'un checkpoint a été atteint est conservé. Les choix restent
/// privés et ne sont pas enregistrés dans le stockage local par cette phase.
class DecisionProgressStore {
  static const _savedCheckpointKey = 'games.je_decide.saved_checkpoint';
  static const _savedItemIndexKey = 'games.je_decide.saved_item_index';

  Future<bool> hasSavedCheckpoint() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_savedCheckpointKey) ?? false;
  }

  /// Index (0-based) de l'item où reprendre, ou 0 si aucun checkpoint.
  Future<int> loadSavedItemIndex() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(_savedItemIndexKey) ?? 0;
  }

  Future<void> saveCheckpoint({required int itemIndex}) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_savedCheckpointKey, true);
    await preferences.setInt(_savedItemIndexKey, itemIndex);
  }

  Future<void> clearCheckpoint() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_savedCheckpointKey);
    await preferences.remove(_savedItemIndexKey);
  }
}
