import 'package:shared_preferences/shared_preferences.dart';

/// Persistance locale minimale du point de reprise de « Je Décide ».
///
/// Seul le fait qu'un checkpoint a été atteint est conservé. Les choix restent
/// privés et ne sont pas enregistrés dans le stockage local par cette phase.
class DecisionProgressStore {
  static const _savedCheckpointKey = 'games.je_decide.saved_checkpoint';
  static const _savedStepKey = 'games.je_decide.saved_step';

  Future<bool> hasSavedCheckpoint() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_savedCheckpointKey) ?? false;
  }

  Future<String?> loadSavedStep() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_savedStepKey);
  }

  Future<void> saveCheckpoint({required String stepName}) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_savedCheckpointKey, true);
    await preferences.setString(_savedStepKey, stepName);
  }

  Future<void> clearCheckpoint() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_savedCheckpointKey);
    await preferences.remove(_savedStepKey);
  }
}
