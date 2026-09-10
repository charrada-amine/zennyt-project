import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Intensité d'une vibration, exprimée comme un moment de jeu et non comme une
/// durée : les écrans disent « erreur », pas « 60 millisecondes ».
enum HapticShot {
  /// Erreur : franche, c'est le retour qui doit être ressenti à coup sûr.
  error(milliseconds: 60, amplitude: 255),

  /// Réussite / franchissement d'un palier.
  success(milliseconds: 35, amplitude: 180),

  /// Sélection, pose d'un élément : discrète.
  selection(milliseconds: 15, amplitude: 110);

  const HapticShot({required this.milliseconds, required this.amplitude});

  final int milliseconds;

  /// Sur 255. Ignorée par les appareils sans contrôle d'amplitude, qui jouent
  /// alors l'intensité par défaut du système.
  final int amplitude;
}

/// Vibration commandée directement au moteur de l'appareil (Android).
///
/// Le chemin standard de Flutter, `HapticFeedback`, demande un *retour haptique
/// tactile*, qu'Android n'exécute que si le réglage système « Vibration au
/// toucher » est actif — désactivé par défaut sur beaucoup de Xiaomi/Redmi. Dans
/// ce cas la demande est ignorée sans erreur : le code s'exécute, rien ne vibre.
/// C'est la cause de la vibration d'erreur d'Optimal Path que le client signalait
/// comme non fonctionnelle alors que le câblage était correct.
///
/// Ce canal contourne ce réglage : il ne dépend que de la permission `VIBRATE`,
/// déclarée au manifeste. Voir `MainActivity.kt` pour l'implémentation native.
///
/// iOS n'a pas ce problème — `HapticFeedback` y suffit — et n'implémente donc pas
/// le canal : [vibrate] y renvoie `false`, ce qui laisse l'appelant reprendre le
/// chemin standard.
class NativeHaptics {
  const NativeHaptics._();

  @visibleForTesting
  static const MethodChannel channel = MethodChannel('zennyt/haptics');

  /// Passe à `true` au premier échec du canal, pour ne pas retenter à chaque
  /// vibration sur une plateforme qui ne l'implémente pas.
  static bool _unavailable = false;

  @visibleForTesting
  static void resetForTest() => _unavailable = false;

  /// Joue [shot]. Retourne `false` si le canal natif n'a rien pu jouer —
  /// l'appelant doit alors retomber sur `HapticFeedback`, plutôt que de laisser
  /// le joueur sans aucun retour.
  static Future<bool> vibrate(HapticShot shot) async {
    if (_unavailable || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      final played = await channel.invokeMethod<bool>('vibrate', {
        'milliseconds': shot.milliseconds,
        'amplitude': shot.amplitude,
      });
      return played ?? false;
    } on MissingPluginException {
      // Canal absent : plateforme non couverte, ou moteur Flutter de test.
      _unavailable = true;
      return false;
    } catch (error) {
      // Un appareil sans moteur, ou un refus du système, ne doit jamais
      // interrompre une partie.
      return false;
    }
  }
}
