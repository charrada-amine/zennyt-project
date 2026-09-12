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
/// 1. **Icônes Material plutôt que Tabler.** Tabler n'est pas dans le projet ;
///    l'intégrer voudrait dire 50 SVG à verser ou une dépendance de plus. Les
///    variantes `outlined` de Material offrent le même trait fin, sans rien
///    ajouter. La correspondance vit dans une seule table ci-dessous : passer
///    aux vrais SVG Tabler plus tard ne touchera que ce fichier.
///
/// 2. **Couleurs calibrées sur BLANC, pas sur le violet.** Le client a comparé
///    ses badges sur le fond violet de sa maquette. Dans le jeu, les tâches
///    vivent sur des cartes blanches : c'est là que le contraste se juge. Son
///    point d'attention reste valide — une teinte proche du fond disparaît —
///    mais le fond en question n'est pas celui qu'il croyait.
library;

import 'package:flutter/material.dart';

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
  'Réception & transport': Color(0xFF0F6E8C), // bleu canard — livraisons, trajets
  'Stock & contrôle': Color(0xFF1F6F4A), // vert profond — inventaire, contrôle
  'Production & réalisation': Color(0xFF2A4FB8), // bleu — fabrication, montage
  'Documents & rapports': Color(0xFF4A5468), // ardoise — dossiers, plans
  'Communication & coordination': Color(0xFFB03070), // magenta — réunions, appels
};

/// Couleur de repli pour une famille inconnue.
const Color kDayStackFallbackColor = Color(0xFF4A5468);

/// Correspondance entre les noms d'icônes Tabler du référentiel et les icônes
/// Material disponibles hors ligne.
///
/// Volontairement exhaustive et explicite : un `switch` avec un cas par défaut
/// laisserait passer en silence une icône absente, et le joueur verrait un
/// badge générique sans que personne ne le remarque. Un test vérifie que les 50
/// noms de la banque sont couverts.
const Map<String, IconData> kDayStackTablerToMaterial = {
  'ti-barcode': Icons.qr_code_2_outlined,
  'ti-bell': Icons.notifications_none_rounded,
  'ti-box': Icons.inventory_2_outlined,
  'ti-building': Icons.apartment_outlined,
  'ti-car': Icons.directions_car_outlined,
  'ti-chart-bar': Icons.bar_chart_rounded,
  'ti-checklist': Icons.checklist_rounded,
  'ti-chef-hat': Icons.restaurant_menu_outlined,
  'ti-clipboard-check': Icons.fact_check_outlined,
  'ti-clipboard-list': Icons.assignment_outlined,
  'ti-clock-hour-4': Icons.schedule_outlined,
  'ti-coffee': Icons.local_cafe_outlined,
  'ti-cut': Icons.content_cut_rounded,
  'ti-database': Icons.storage_outlined,
  'ti-droplet': Icons.water_drop_outlined,
  'ti-edit': Icons.edit_outlined,
  'ti-file-search': Icons.plagiarism_outlined,
  'ti-file-text': Icons.description_outlined,
  'ti-file-upload': Icons.upload_file_outlined,
  'ti-first-aid-kit': Icons.medical_services_outlined,
  'ti-flame': Icons.local_fire_department_outlined,
  'ti-heart-handshake': Icons.volunteer_activism_outlined,
  'ti-layout-grid': Icons.grid_view_outlined,
  'ti-list': Icons.list_alt_outlined,
  'ti-list-details': Icons.view_list_outlined,
  'ti-mail': Icons.mail_outline_rounded,
  'ti-mail-fast': Icons.forward_to_inbox_outlined,
  'ti-map-pin': Icons.place_outlined,
  'ti-meat': Icons.kebab_dining_outlined,
  'ti-package': Icons.widgets_outlined,
  'ti-phone': Icons.call_outlined,
  'ti-pill': Icons.medication_outlined,
  'ti-plug': Icons.power_outlined,
  'ti-printer': Icons.print_outlined,
  'ti-report-money': Icons.request_quote_outlined,
  'ti-route': Icons.alt_route_rounded,
  'ti-ruler-2': Icons.straighten_outlined,
  'ti-send': Icons.send_outlined,
  'ti-shield-check': Icons.verified_user_outlined,
  'ti-shopping-cart': Icons.shopping_cart_outlined,
  'ti-soup': Icons.soup_kitchen_outlined,
  'ti-sparkles': Icons.auto_awesome_outlined,
  'ti-spray': Icons.sanitizer_outlined,
  'ti-tool': Icons.build_outlined,
  'ti-tools-kitchen-2': Icons.restaurant_outlined,
  'ti-truck': Icons.local_shipping_outlined,
  'ti-truck-delivery': Icons.local_shipping_outlined,
  'ti-users': Icons.groups_outlined,
  'ti-volume': Icons.volume_up_outlined,
  'ti-wall': Icons.foundation_outlined,
};

/// Couleur de la famille [category].
Color dayStackCategoryColor(String? category) =>
    kDayStackCategoryColors[category] ?? kDayStackFallbackColor;

/// Icône correspondant au nom Tabler [tablerName].
IconData dayStackIcon(String? tablerName) =>
    kDayStackTablerToMaterial[tablerName] ?? Icons.circle_outlined;

/// Badge carré arrondi d'une tâche.
///
/// Dimensions et style repris des recommandations visuelles du référentiel :
/// coin ~10 px, icône monochrome centrée, aucun dégradé, trait fin. Le texte de
/// la tâche garde sa teinte neutre — la couleur ne sert qu'au badge.
class DayStackTaskBadge extends StatelessWidget {
  const DayStackTaskBadge({
    super.key,
    required this.category,
    required this.icon,
    this.compact = false,
  });

  final String? category;

  /// Nom d'icône Tabler tel que livré dans la banque.
  final String? icon;

  /// Version resserrée — 28 px au lieu de 38, icône 16 au lieu de 20.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 28.0 : 38.0;
    final glyph = compact ? 16.0 : 20.0;
    return Semantics(
      // La catégorie est déjà portée par la couleur, qui n'est pas lisible par
      // un lecteur d'écran : on la dit.
      label: category,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: dayStackCategoryColor(category),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(dayStackIcon(icon), size: glyph, color: Colors.white),
      ),
    );
  }
}
