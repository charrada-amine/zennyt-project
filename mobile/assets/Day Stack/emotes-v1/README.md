# Day Stack — emotes v1

82 emotes demandées par l’utilisateur, une par tâche, pour les sept univers.
Style : objets arrondis en 2.5D, bleu marine / mauve / magenta / blanc cassé, accent de catégorie existant et fond transparent.

`manifest.json` associe chaque fichier à la clé composée univers + tâche, à ses quatre variantes de libellé et à son prompt exact. Générateur : outil intégré image_gen.

Les distinctions patient A/B utilisent un repère magenta simple et un repère cyan à deux points, sans texte dans l’image. Les actions proches (charger, décharger, partir, restituer) ont des flèches ou objets spécifiques. Ces repères sont des propositions visuelles à valider, sans portée métier.

Assets générés uniquement : aucune déclaration pubspec ni remplacement du badge Flutter à ce stade.

## Livrables et validation

| Univers | Emotes PNG | Planche |
|---|---:|---|
| Restaurant / Cuisine professionnelle | 12 | [Relecture](review/restaurant.png) |
| Gestion de projet / Bureau | 12 | [Relecture](review/gestion.png) |
| Organisation d'un événement | 12 | [Relecture](review/organisation.png) |
| Chantier de construction | 11 | [Relecture](review/chantier.png) |
| Logistique / Entrepôt | 12 | [Relecture](review/logistique.png) |
| Soins à domicile / Aide-soignant | 11 | [Relecture](review/soins.png) |
| Déménagement | 12 | [Relecture](review/demenagement.png) |

82/82 PNG contrôlés le 17 septembre 2026 : fichiers valides, canal alpha avec fond transparent et coins transparents, clés univers/tâche exhaustives, quatre variantes correctement associées, aucune image dupliquée. Relecture visuelle des sept séries sur fond mauve. Détails et SHA-256 dans `validation.json`. Deux erreurs de connexion ont été récupérées par l’outil intégré, sans recours au CLI.

Ouvrir `index.html` dans un navigateur pour parcourir la galerie, chercher une tâche et changer le fond. Les prompts exacts et correspondances figurent dans `manifest.json`.
