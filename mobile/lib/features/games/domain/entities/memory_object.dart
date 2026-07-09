/// Catalogue des objets mémoire de « J'investigue » (Mission B).
///
/// Chaque objet est identifié par une **forme + un libellé** (règle
/// d'accessibilité : jamais par la couleur seule). Les libellés restent
/// localisables FR/EN. La bibliothèque compte 20+ objets ; un niveau en tire un
/// sous-ensemble (4 → 12 objets, mosaïque max de 12).
class MemoryObject {
  const MemoryObject({
    required this.id,
    required this.asset,
    required this.labelEn,
    required this.labelFr,
  });

  /// Identifiant stable (nom du fichier sans extension).
  final String id;

  /// Chemin de l'icône (PNG ; réutilisable, cf. checklist assets).
  final String asset;

  final String labelEn;
  final String labelFr;

  /// Libellé selon le code langue (`fr` → français, sinon anglais).
  String label(String languageCode) => languageCode == 'fr' ? labelFr : labelEn;
}

/// Dossier des icônes d'objets (fourni dans les assets J'investigue).
const String _objectsDir = 'assets/J’investigue/memoryobject';

/// Bibliothèque complète (21 objets). Un niveau pioche un sous-ensemble.
const List<MemoryObject> kMemoryObjectLibrary = [
  MemoryObject(id: 'Apple', asset: '$_objectsDir/Apple.png', labelEn: 'Apple', labelFr: 'Pomme'),
  MemoryObject(id: 'Backpack', asset: '$_objectsDir/Backpack.png', labelEn: 'Backpack', labelFr: 'Sac à dos'),
  MemoryObject(id: 'Ball', asset: '$_objectsDir/Ball.png', labelEn: 'Ball', labelFr: 'Ballon'),
  MemoryObject(id: 'Bicycle', asset: '$_objectsDir/Bicycle.png', labelEn: 'Bicycle', labelFr: 'Vélo'),
  MemoryObject(id: 'Book', asset: '$_objectsDir/Book.png', labelEn: 'Book', labelFr: 'Livre'),
  MemoryObject(id: 'Bottle', asset: '$_objectsDir/Bottle.png', labelEn: 'Bottle', labelFr: 'Bouteille'),
  MemoryObject(id: 'Camera', asset: '$_objectsDir/Camera.png', labelEn: 'Camera', labelFr: 'Appareil photo'),
  MemoryObject(id: 'Car', asset: '$_objectsDir/Car.png', labelEn: 'Car', labelFr: 'Voiture'),
  MemoryObject(id: 'Chair', asset: '$_objectsDir/Chair.png', labelEn: 'Chair', labelFr: 'Chaise'),
  MemoryObject(id: 'Compass', asset: '$_objectsDir/Compass.png', labelEn: 'Compass', labelFr: 'Boussole'),
  MemoryObject(id: 'Cup', asset: '$_objectsDir/Cup.png', labelEn: 'Cup', labelFr: 'Tasse'),
  MemoryObject(id: 'Eraser', asset: '$_objectsDir/Eraser.png', labelEn: 'Eraser', labelFr: 'Gomme'),
  MemoryObject(id: 'Flower', asset: '$_objectsDir/Flower.png', labelEn: 'Flower', labelFr: 'Fleur'),
  MemoryObject(id: 'Headphones', asset: '$_objectsDir/Headphones.png', labelEn: 'Headphones', labelFr: 'Casque'),
  MemoryObject(id: 'Key', asset: '$_objectsDir/Key.png', labelEn: 'Key', labelFr: 'Clé'),
  MemoryObject(id: 'Lamp', asset: '$_objectsDir/Lamp.png', labelEn: 'Lamp', labelFr: 'Lampe'),
  MemoryObject(id: 'MagnifyingGlass', asset: '$_objectsDir/MagnifyingGlass.png', labelEn: 'Magnifier', labelFr: 'Loupe'),
  MemoryObject(id: 'Pencil', asset: '$_objectsDir/Pencil.png', labelEn: 'Pencil', labelFr: 'Crayon'),
  MemoryObject(id: 'Phone', asset: '$_objectsDir/Phone.png', labelEn: 'Phone', labelFr: 'Téléphone'),
  MemoryObject(id: 'Scissors', asset: '$_objectsDir/Scissors.png', labelEn: 'Scissors', labelFr: 'Ciseaux'),
  MemoryObject(id: 'Umbrella', asset: '$_objectsDir/Umbrella.png', labelEn: 'Umbrella', labelFr: 'Parapluie'),
];
