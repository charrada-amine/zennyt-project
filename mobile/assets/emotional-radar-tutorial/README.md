# Emotional Radar — illustrations du tutoriel

Générées le 2026-09-17 avec l’outil intégré `image_gen.imagegen`, une image par appel.
Les cinq prompts exacts, la provenance et les destinations sont dans `manifest.json`.
Les originaux restent dans le dossier de génération Codex ; les fichiers de production
sont copiés sans modification dans `mobile/assets/games icons/`, déjà déclaré dans
`pubspec.yaml`. Aucune déclaration d’asset ni dépendance ajoutée.

| Carte | Fichier de production | Règle illustrée |
|---|---|---|
| Observer | `Emotional Radar Tutorial Observe.png` | Vidéo, visage, gestes et contexte |
| Choisir | `Emotional Radar Tutorial Choose.png` | Choix direct de l’émotion, grille de six exemples |
| Intensité | `Emotional Radar Tutorial Intensity.png` | Même émotion à trois forces croissantes |
| Temps | `Emotional Radar Tutorial Time.png` | Un budget commun à la vidéo et à la réponse |
| Valider | `Emotional Radar Tutorial Validate.png` | Deux choix : émotion et intensité |

PNG RGBA 1254 × 1254, fond transparent contrôlé, style arrondi 2.5D violet/magenta
et bleu marine. Cinq images inspectées séparément puis dans leurs captures Flutter.
Les illustrations sont pédagogiques : ce ne sont ni des stimuli de scène, ni des
réponses attendues, ni du matériel psychométrique validé. Le personnage de la première
carte reste une illustration générique de l’observation et ne correspond à aucune scène.

Les textes utilisent `EmotionalRadarV2Config` : 6 ou 9 propositions, Faible / Modérée /
Intense, 30 secondes pour regarder et répondre, 15 scènes ; aucun choix de nuance
ni justification écrite. La grille illustrée ne prétend pas représenter les 45 émotions.

PROVISOIRE — présentation et illustrations à valider visuellement sur appareil,
sans modification des règles ni de la notation (décision 65 de `GAMES_MODULE.md`).
