/// Catalogue des objets mémoire de « J'investigue » (Mission B).
///
/// Chaque objet est identifié par une **forme + un libellé** (règle
/// d'accessibilité : jamais par la couleur seule). Les libellés restent
/// localisables FR/EN. La bibliothèque compte 20 objets ; un niveau en tire un
/// sous-ensemble (4 → 12 objets, mosaïque max de 12).
///
/// Les visuels réutilisent les **mêmes objets 2.5D que le jeu « Je place »**
/// (`assets/games icons/Je Place Object NN.png`) pour une cohérence entre les
/// deux jeux de mémoire. [assetPath] est une simple chaîne : le domaine reste
/// sans dépendance Flutter.
class MemoryObject {
  const MemoryObject({
    required this.id,
    required this.labelEn,
    required this.labelFr,
    required this.assetPath,
  });

  /// Identifiant stable (aligné sur le catalogue « Je place »).
  final String id;

  final String labelEn;
  final String labelFr;

  /// Chemin de l'illustration 2.5D partagée avec « Je place ».
  final String assetPath;

  /// Libellé selon le code langue (`fr` → français, sinon anglais).
  String label(String languageCode) => languageCode == 'fr' ? labelFr : labelEn;
}

/// Bibliothèque complète (20 objets, identiques à « Je place »). Un niveau
/// pioche un sous-ensemble.
const List<MemoryObject> kMemoryObjectLibrary = [
  MemoryObject(
    id: 'SMARTPHONE',
    labelEn: 'Smartphone',
    labelFr: 'Smartphone',
    assetPath: 'assets/games icons/Je Place Object 01.png',
  ),
  MemoryObject(
    id: 'WIRELESS_EARBUDS',
    labelEn: 'Earbuds',
    labelFr: 'Écouteurs',
    assetPath: 'assets/games icons/Je Place Object 02.png',
  ),
  MemoryObject(
    id: 'SMARTWATCH',
    labelEn: 'Smartwatch',
    labelFr: 'Montre',
    assetPath: 'assets/games icons/Je Place Object 03.png',
  ),
  MemoryObject(
    id: 'REUSABLE_BOTTLE',
    labelEn: 'Bottle',
    labelFr: 'Gourde',
    assetPath: 'assets/games icons/Je Place Object 04.png',
  ),
  MemoryObject(
    id: 'INSTANT_CAMERA',
    labelEn: 'Camera',
    labelFr: 'Appareil photo',
    assetPath: 'assets/games icons/Je Place Object 05.png',
  ),
  MemoryObject(
    id: 'SNEAKER',
    labelEn: 'Sneaker',
    labelFr: 'Basket',
    assetPath: 'assets/games icons/Je Place Object 06.png',
  ),
  MemoryObject(
    id: 'SUCCULENT',
    labelEn: 'Succulent',
    labelFr: 'Plante',
    assetPath: 'assets/games icons/Je Place Object 07.png',
  ),
  MemoryObject(
    id: 'CERAMIC_MUG',
    labelEn: 'Mug',
    labelFr: 'Mug',
    assetPath: 'assets/games icons/Je Place Object 08.png',
  ),
  MemoryObject(
    id: 'BACKPACK',
    labelEn: 'Backpack',
    labelFr: 'Sac à dos',
    assetPath: 'assets/games icons/Je Place Object 09.png',
  ),
  MemoryObject(
    id: 'GAME_CONTROLLER',
    labelEn: 'Controller',
    labelFr: 'Manette',
    assetPath: 'assets/games icons/Je Place Object 10.png',
  ),
  MemoryObject(
    id: 'BICYCLE_HELMET',
    labelEn: 'Helmet',
    labelFr: 'Casque',
    assetPath: 'assets/games icons/Je Place Object 11.png',
  ),
  MemoryObject(
    id: 'DESK_LAMP',
    labelEn: 'Desk lamp',
    labelFr: 'Lampe',
    assetPath: 'assets/games icons/Je Place Object 12.png',
  ),
  MemoryObject(
    id: 'NOTEBOOK',
    labelEn: 'Notebook',
    labelFr: 'Carnet',
    assetPath: 'assets/games icons/Je Place Object 13.png',
  ),
  MemoryObject(
    id: 'SUNGLASSES',
    labelEn: 'Sunglasses',
    labelFr: 'Lunettes',
    assetPath: 'assets/games icons/Je Place Object 14.png',
  ),
  MemoryObject(
    id: 'KEYCARD',
    labelEn: 'Key card',
    labelFr: 'Badge',
    assetPath: 'assets/games icons/Je Place Object 15.png',
  ),
  MemoryObject(
    id: 'COMPACT_DRONE',
    labelEn: 'Drone',
    labelFr: 'Drone',
    assetPath: 'assets/games icons/Je Place Object 16.png',
  ),
  MemoryObject(
    id: 'PORTABLE_SPEAKER',
    labelEn: 'Speaker',
    labelFr: 'Enceinte',
    assetPath: 'assets/games icons/Je Place Object 17.png',
  ),
  MemoryObject(
    id: 'POWER_BANK',
    labelEn: 'Power bank',
    labelFr: 'Batterie',
    assetPath: 'assets/games icons/Je Place Object 18.png',
  ),
  MemoryObject(
    id: 'STYLUS_TABLET',
    labelEn: 'Tablet',
    labelFr: 'Tablette',
    assetPath: 'assets/games icons/Je Place Object 19.png',
  ),
  MemoryObject(
    id: 'TRAVEL_POUCH',
    labelEn: 'Pouch',
    labelFr: 'Trousse',
    assetPath: 'assets/games icons/Je Place Object 20.png',
  ),
];
