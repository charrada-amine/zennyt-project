# Reflective Pause — illustrations du tutoriel

Générées le 2026-09-17 avec l’outil intégré `image_gen.imagegen`, une image par appel.
Prompts exacts, provenance et destinations : `manifest.json`.
Les originaux sont conservés dans le dossier de génération Codex. Les cinq PNG de
production sont copiés sans modification dans `mobile/assets/games icons/`, déjà
déclaré dans `pubspec.yaml`. Aucune nouvelle déclaration ni dépendance.

| Carte | Fichier de production | Règle illustrée |
|---|---|---|
| Découvrir | `Reflective Pause Tutorial Discover.png` | Message ou scène vidéo |
| Attendre | `Reflective Pause Tutorial Wait.png` | Réponses verrouillées pendant la réflexion |
| Choisir | `Reflective Pause Tutorial Choose.png` | Une sélection parmi cinq propositions |
| Valider | `Reflective Pause Tutorial Validate.png` | Enregistrer le choix et continuer |
| Bilan | `Reflective Pause Tutorial Review.png` | Résultats et tendances après dix situations |

PNG RGBA 1254 × 1254, transparence contrôlée (alpha 0–255). Style arrondi 2.5D,
violet, bleu marine et magenta, conforme à la direction du tutoriel Radar.
Les cinq images ont été inspectées séparément puis dans les cinq captures Flutter.
Le symbole de sauvegarde ne donne pas de correction « bon/mauvais ».

Les textes dérivent le nombre de situations et de réactions des configurations
existantes. Le délai de réflexion est décrit sans durée fixe : une session peut
publier une durée supérieure au défaut de trois secondes. La barre qui suit ce
délai indique un temps conseillé et ne bloque pas la réponse. Le tutoriel n’ajoute
aucun choix recommandé, aucun ordre appris des réponses et aucune cotation.

PROVISOIRE — à valider visuellement sur appareil (décision 66 de `GAMES_MODULE.md`).
Ces illustrations pédagogiques ne remplacent aucune situation ni aucun stimulus.
