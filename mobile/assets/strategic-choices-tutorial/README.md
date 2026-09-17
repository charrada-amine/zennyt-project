# Choix stratégiques — illustrations du tutoriel

Générées le 2026-09-17 avec l’outil intégré `image_gen.imagegen`, une image par appel.
Les prompts exacts, la provenance et les destinations sont dans `manifest.json`.
Les originaux sont conservés dans le dossier de génération Codex. Les PNG de production
sont copiés sans modification dans `mobile/assets/games icons/`, déjà déclaré dans
`pubspec.yaml`. Aucune nouvelle déclaration ni dépendance.

| Carte | Fichier de production | Règle représentée |
|---|---|---|
| Lire | `Strategic Choices Tutorial Read.png` | Lire un message ou une description de scène |
| Réfléchir | `Strategic Choices Tutorial Reflect.png` | Lancer manuellement le compte à rebours |
| Choisir | `Strategic Choices Tutorial Choose.png` | Sélectionner une stratégie parmi huit |
| Valider | `Strategic Choices Tutorial Validate.png` | Sauvegarder lorsque le compte à rebours est fini |
| Bilan | `Strategic Choices Tutorial Review.png` | Tendances des stratégies après le parcours |

Direction visuelle : objets arrondis en 2.5D, bleu marine, violet et magenta ; la boussole
rappelle les logos existants. Les illustrations sont pédagogiques, sans stratégie
recommandée, clé de cotation ni symbole de réponse correcte.

Cinq PNG RGBA 1254 × 1254, fond transparent contrôlé (alpha 0–255). Images inspectées
séparément puis dans les cinq captures Flutter, avec décodage réel des assets vérifié.

Les textes suivent le parcours actuel : la lecture précède le lancement explicite de
`Start reflection`, le choix est autorisé pendant la réflexion, la validation à sa fin.
Huit stratégies issues du catalogue existant ; nombre de situations transmis depuis
la constante du parcours. Aucune durée fixe ajoutée au texte. Le score final reste
provisoire et aucune correction immédiate n’est annoncée. Les vidéos restent en préparation.

PROVISOIRE — à valider visuellement sur appareil (décision 67 de `GAMES_MODULE.md`).
Ces assets ne remplacent aucune situation ni aucun stimulus psychométrique.
