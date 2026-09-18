/// Badges de tâches du « Planning journalier ».
///
/// Le client propose de remplacer les emoji par des badges colorés, en donnant
/// deux raisons justes : le rendu d'un emoji dépend du système et échappe au
/// produit, et deux de ses exemples se fondaient dans le fond violet. Un badge
/// plein avec une icône blanche garantit le même contraste partout.
///
/// **Principe repris du référentiel** : une couleur = une famille de tâches,
/// une icône = l'action précise à l'intérieur de cette famille. Le joueur
/// apprend le code couleur une fois et le réutilise dans les sept univers.
/// L'icône et sa couleur sont indexées sur l'IDENTIFIANT de tâche, jamais sur
/// la variante de libellé tirée — elles ne changent donc pas d'une session à
/// l'autre.
///
/// ## Deux écarts assumés avec la proposition du client
///
/// 1. **Icônes HugeIcons plutôt que Tabler.** Tabler n'est pas dans le projet ;
///    l'intégrer voudrait dire 50 SVG à verser ou une dépendance de plus.
///    HugeIcons, déjà utilisé partout dans l'application, offre le même trait
///    fin. La correspondance vit dans une seule table ci-dessous : passer aux
///    vrais SVG Tabler plus tard ne touchera que ce fichier.
///
/// 2. **Couleurs calibrées sur BLANC, pas sur le violet.** Le client a comparé
///    ses badges sur le fond violet de sa maquette. Dans le jeu, les tâches
///    vivent sur des cartes blanches : c'est là que le contraste se juge. Son
///    point d'attention reste valide — une teinte proche du fond disparaît —
///    mais le fond en question n'est pas celui qu'il croyait.
library;

import 'package:flutter/material.dart';

import 'day_stack_emotes.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

/// Couleur de badge d'une famille de tâches.
///
/// Choisies assez sombres pour qu'une icône BLANCHE y ressorte, et assez
/// distinctes les unes des autres pour que huit familles restent
/// discernables — y compris pour un daltonisme courant, la forme de l'icône
/// restant de toute façon le porteur principal du sens.
const Map<String, Color> kDayStackCategoryColors = {
  'Santé & sécurité': Color(0xFFD4353F), // rouge — soins, sécurité
  'Repas & pause': Color(0xFFB4651A), // ambre foncé — pauses, repas
  'Achats & commandes': Color(0xFF7A3FBF), // violet — achats, réservations
  'Réception & transport': Color(
    0xFF0F6E8C,
  ), // bleu canard — livraisons, trajets
  'Stock & contrôle': Color(0xFF1F6F4A), // vert profond — inventaire, contrôle
  'Production & réalisation': Color(0xFF2A4FB8), // bleu — fabrication, montage
  'Documents & rapports': Color(0xFF4A5468), // ardoise — dossiers, plans
  'Communication & coordination': Color(
    0xFFB03070,
  ), // magenta — réunions, appels
};

/// Couleur de repli pour une famille inconnue.
const Color kDayStackFallbackColor = Color(0xFF4A5468);

/// Correspondance entre les noms d'icônes Tabler du référentiel et les icônes
/// HugeIcons disponibles hors ligne.
///
/// Volontairement exhaustive et explicite : un `switch` avec un cas par défaut
/// laisserait passer en silence une icône absente, et le joueur verrait un
/// badge générique sans que personne ne le remarque. Un test vérifie que les 50
/// noms de la banque sont couverts.
const Map<String, AppIconData> kDayStackTablerToHuge = {
  'ti-barcode': HugeIcons.strokeRoundedQrCode,
  'ti-bell': HugeIcons.strokeRoundedNotification01,
  'ti-box': HugeIcons.strokeRoundedPackageOpen,
  'ti-building': HugeIcons.strokeRoundedBuilding03,
  'ti-car': HugeIcons.strokeRoundedCar01,
  'ti-chart-bar': HugeIcons.strokeRoundedChartHistogram,
  'ti-checklist': HugeIcons.strokeRoundedCheckList,
  'ti-chef-hat': HugeIcons.strokeRoundedChefHat,
  'ti-clipboard-check': HugeIcons.strokeRoundedTaskDone01,
  'ti-clipboard-list': HugeIcons.strokeRoundedTask01,
  'ti-clock-hour-4': HugeIcons.strokeRoundedClock01,
  'ti-coffee': HugeIcons.strokeRoundedCoffee02,
  'ti-cut': HugeIcons.strokeRoundedScissor01,
  'ti-database': HugeIcons.strokeRoundedDatabase,
  'ti-droplet': HugeIcons.strokeRoundedDroplet,
  'ti-edit': HugeIcons.strokeRoundedPencilEdit01,
  'ti-file-search': HugeIcons.strokeRoundedFileSearch,
  'ti-file-text': HugeIcons.strokeRoundedFile02,
  'ti-file-upload': HugeIcons.strokeRoundedFileUpload,
  'ti-first-aid-kit': HugeIcons.strokeRoundedFirstAidKit,
  'ti-flame': HugeIcons.strokeRoundedFire,
  'ti-heart-handshake': HugeIcons.strokeRoundedCharity,
  'ti-layout-grid': HugeIcons.strokeRoundedGridView,
  'ti-list': HugeIcons.strokeRoundedLeftToRightListBullet,
  'ti-list-details': HugeIcons.strokeRoundedListView,
  'ti-mail': HugeIcons.strokeRoundedMail01,
  'ti-mail-fast': HugeIcons.strokeRoundedMailSend01,
  'ti-map-pin': HugeIcons.strokeRoundedLocation01,
  'ti-meat': HugeIcons.strokeRoundedSteak,
  'ti-package': HugeIcons.strokeRoundedPackage,
  'ti-phone': HugeIcons.strokeRoundedCall,
  'ti-pill': HugeIcons.strokeRoundedMedicine02,
  'ti-plug': HugeIcons.strokeRoundedPlug01,
  'ti-printer': HugeIcons.strokeRoundedPrinter,
  'ti-report-money': HugeIcons.strokeRoundedInvoice01,
  'ti-route': HugeIcons.strokeRoundedRoute01,
  'ti-ruler-2': HugeIcons.strokeRoundedRuler,
  'ti-send': HugeIcons.strokeRoundedSent,
  'ti-shield-check': HugeIcons.strokeRoundedSecurityCheck,
  'ti-shopping-cart': HugeIcons.strokeRoundedShoppingCart01,
  'ti-soup': HugeIcons.strokeRoundedRiceBowl01,
  'ti-sparkles': HugeIcons.strokeRoundedSparkles,
  'ti-spray': HugeIcons.strokeRoundedSprayCan,
  'ti-tool': HugeIcons.strokeRoundedWrench01,
  'ti-tools-kitchen-2': HugeIcons.strokeRoundedKitchenUtensils,
  'ti-truck': HugeIcons.strokeRoundedDeliveryTruck01,
  'ti-truck-delivery': HugeIcons.strokeRoundedDeliveryTruck02,
  'ti-users': HugeIcons.strokeRoundedUserGroup,
  'ti-volume': HugeIcons.strokeRoundedVolumeHigh,
  'ti-wall': HugeIcons.strokeRoundedBrickWall,
};

/// Couleur de la famille [category].
Color dayStackCategoryColor(String? category) =>
    kDayStackCategoryColors[category] ?? kDayStackFallbackColor;

/// Icône correspondant au nom Tabler [tablerName].
AppIconData dayStackIcon(String? tablerName) =>
    kDayStackTablerToHuge[tablerName] ?? HugeIcons.strokeRoundedCircle;

/// Badge d'une tâche.
///
/// Avec [universeId] et [taskId], le badge montre l'emote illustrée de la
/// tâche ([dayStackEmoteAssetPath]) : un PNG transparent qui porte son propre
/// contour, sans carré coloré autour. Sans identité, ou si l'image ne se
/// charge pas, il retombe sur le carré historique.
///
/// Carré historique repris des recommandations visuelles du référentiel :
/// coin ~10 px, icône monochrome centrée, aucun dégradé, trait fin. Le texte de
/// la tâche garde sa teinte neutre — la couleur ne sert qu'au badge.
class DayStackTaskBadge extends StatelessWidget {
  const DayStackTaskBadge({
    super.key,
    required this.category,
    required this.icon,
    this.compact = false,
    this.universeId,
    this.taskId,
    this.emoteSize,
  });

  final String? category;

  /// Nom d'icône Tabler tel que livré dans la banque.
  final String? icon;

  /// Version resserrée — 28 px au lieu de 38, icône 16 au lieu de 20.
  /// Une emote compacte occupe [kDayStackEmoteCompactSize].
  final bool compact;

  /// Univers de la tâche : les identifiants ne sont uniques que par univers.
  final String? universeId;

  /// Identifiant de tâche de la banque, jamais le libellé tiré.
  final String? taskId;

  /// Taille illustrée optionnelle, par exemple pour les schémas du tutoriel.
  /// Sans valeur, les dimensions du calendrier et du badge historique restent
  /// inchangées.
  final double? emoteSize;

  @override
  Widget build(BuildContext context) {
    final glyph = compact ? 16.0 : 20.0;
    final emote = dayStackEmoteAssetPath(
      universeId: universeId,
      taskId: taskId,
    );
    final Widget child;
    if (emote == null) {
      child = _tile(compact ? 28.0 : 38.0, glyph);
    } else {
      final size =
          emoteSize ??
          (compact ? kDayStackEmoteCompactSize : kDayStackEmoteSize);
      final ratio =
          MediaQuery.maybeDevicePixelRatioOf(context) ??
          View.of(context).devicePixelRatio;
      child = Image.asset(
        emote,
        width: size,
        height: size,
        fit: BoxFit.contain,
        cacheWidth: dayStackEmoteCacheWidth(size, ratio),
        // Décorative : la catégorie est annoncée par le badge, le titre par
        // la carte.
        excludeFromSemantics: true,
        // Même boîte que l'emote : un échec de chargement ne décale rien.
        errorBuilder: (_, _, _) => _tile(size, glyph),
      );
    }
    return Semantics(
      // La catégorie est déjà portée par la couleur, qui n'est pas lisible par
      // un lecteur d'écran : on la dit.
      label: category,
      child: child,
    );
  }

  Widget _tile(double size, double glyph) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: dayStackCategoryColor(category),
      borderRadius: BorderRadius.circular(10),
    ),
    child: AppIcon(dayStackIcon(icon), size: glyph, color: Colors.white),
  );
}
