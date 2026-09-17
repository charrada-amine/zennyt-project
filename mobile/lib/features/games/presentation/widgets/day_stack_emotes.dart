/// Emotes illustrées des tâches du « Planning journalier ».
///
/// Une image par tâche, livrée dans `assets/Day Stack/emotes-v1/` : objets
/// arrondis sur fond transparent, dans la palette Zennyt. Le chemin se déduit
/// du couple **univers + identifiant de tâche**, sans lire le manifest à
/// l'exécution : ce fichier sert à la relecture et aux tests de couverture.
///
/// Le couple est obligatoire. Certains identifiants existent dans plusieurs
/// univers (`chargement_camion` en logistique et en déménagement) avec une
/// illustration différente. Le libellé tiré, sa variante, la catégorie et
/// l'ancienne icône ne choisissent jamais l'emote.
library;

/// Dossier de la collection, tel que déclaré (par univers) dans `pubspec.yaml`.
const String kDayStackEmotesRoot = 'assets/Day Stack/emotes-v1';

/// Côté de l'emote dans une carte du calendrier.
// PROVISOIRE — à valider visuellement (décision 62 de GAMES_MODULE.md).
const double kDayStackEmoteCompactSize = 32;

/// Côté de l'emote en taille normale, identique à l'ancien badge.
const double kDayStackEmoteSize = 38;

/// Chemin d'asset de l'emote, ou `null` si l'identité est incomplète.
String? dayStackEmoteAssetPath({String? universeId, String? taskId}) {
  if (universeId == null || universeId.isEmpty) return null;
  if (taskId == null || taskId.isEmpty) return null;
  return '$kDayStackEmotesRoot/$universeId/$taskId.png';
}

/// Largeur de décodage d'une emote affichée sur [size] points logiques.
///
/// Les originaux mesurent 1254 px : les décoder tels quels pour une vignette
/// de 32 points coûterait inutilement de la mémoire à chaque carte.
int dayStackEmoteCacheWidth(double size, double devicePixelRatio) =>
    (size * devicePixelRatio).ceil();
