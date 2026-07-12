/// Catalogue des objets mémoire de « J'investigue » (Mission B).
///
/// Chaque objet est identifié par une **forme (icône) + un libellé** (règle
/// d'accessibilité : jamais par la couleur seule). Les libellés restent
/// localisables FR/EN. La bibliothèque compte 20+ objets ; un niveau en tire un
/// sous-ensemble (4 → 12 objets, mosaïque max de 12).
///
/// L'icône vectorielle de chaque objet est mappée **côté présentation**
/// (`memoryObjectIcon`, investigate_screen.dart) via [id] → le domaine reste
/// sans dépendance Flutter.
class MemoryObject {
  const MemoryObject({
    required this.id,
    required this.labelEn,
    required this.labelFr,
  });

  /// Identifiant stable (clé de mappage vers l'icône vectorielle).
  final String id;

  final String labelEn;
  final String labelFr;

  /// Libellé selon le code langue (`fr` → français, sinon anglais).
  String label(String languageCode) => languageCode == 'fr' ? labelFr : labelEn;
}

/// Bibliothèque complète (21 objets). Un niveau pioche un sous-ensemble.
const List<MemoryObject> kMemoryObjectLibrary = [
  MemoryObject(id: 'Apple', labelEn: 'Apple', labelFr: 'Pomme'),
  MemoryObject(id: 'Backpack', labelEn: 'Backpack', labelFr: 'Sac à dos'),
  MemoryObject(id: 'Ball', labelEn: 'Ball', labelFr: 'Ballon'),
  MemoryObject(id: 'Bicycle', labelEn: 'Bicycle', labelFr: 'Vélo'),
  MemoryObject(id: 'Book', labelEn: 'Book', labelFr: 'Livre'),
  MemoryObject(id: 'Bottle', labelEn: 'Bottle', labelFr: 'Bouteille'),
  MemoryObject(id: 'Camera', labelEn: 'Camera', labelFr: 'Appareil photo'),
  MemoryObject(id: 'Car', labelEn: 'Car', labelFr: 'Voiture'),
  MemoryObject(id: 'Chair', labelEn: 'Chair', labelFr: 'Chaise'),
  MemoryObject(id: 'Compass', labelEn: 'Compass', labelFr: 'Boussole'),
  MemoryObject(id: 'Cup', labelEn: 'Cup', labelFr: 'Tasse'),
  MemoryObject(id: 'Eraser', labelEn: 'Eraser', labelFr: 'Gomme'),
  MemoryObject(id: 'Flower', labelEn: 'Flower', labelFr: 'Fleur'),
  MemoryObject(id: 'Headphones', labelEn: 'Headphones', labelFr: 'Casque'),
  MemoryObject(id: 'Key', labelEn: 'Key', labelFr: 'Clé'),
  MemoryObject(id: 'Lamp', labelEn: 'Lamp', labelFr: 'Lampe'),
  MemoryObject(id: 'MagnifyingGlass', labelEn: 'Magnifier', labelFr: 'Loupe'),
  MemoryObject(id: 'Pencil', labelEn: 'Pencil', labelFr: 'Crayon'),
  MemoryObject(id: 'Phone', labelEn: 'Phone', labelFr: 'Téléphone'),
  MemoryObject(id: 'Scissors', labelEn: 'Scissors', labelFr: 'Ciseaux'),
  MemoryObject(id: 'Umbrella', labelEn: 'Umbrella', labelFr: 'Parapluie'),
];
