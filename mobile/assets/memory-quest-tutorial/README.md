# Memory Quest Digits et Image — tutoriels illustrés

Douze illustrations dédiées générées le 2026-09-17 avec l’outil intégré
`image_gen.imagegen`, une image par appel. Prompts exacts, fichiers de production
et originaux retenus : `manifest.json`. Les originaux restent dans le dossier
de génération Codex ; les PNG sont copiés sans modification dans
`mobile/assets/games icons/`, déjà déclaré dans `pubspec.yaml`.

| Jeu | Six fichiers `Memory Quest … Tutorial ….png` | Idées expliquées |
|---|---|---|
| Digits | `Observe`, `Same`, `Reverse`, `Protect`, `Validate`, `Progress` | Révélation, rappel direct, inverse, interférence, saisie, progression |
| Image | `Observe`, `Moved`, `Protect`, `Rank`, `Validate`, `Progress` | Ordre initial, déplacements, interférence visuelle, appuis, chrono, progression |

Les chiffres 3–7–2 sont un exemple pédagogique, pas une séquence imposée en jeu.
Le coquillage, la lune et la plume sont des symboles nouveaux : aucun fichier ni
objet du catalogue `MemoryObject` ou du catalogue des distracteurs n’est utilisé.
Ils restent cohérents d’une scène illustrée à l’autre pour montrer l’ordre initial.
Palette : marine, violet, magenta et cyan ; scènes arrondies en 2.5D.
La progression Image a été régénérée pour conserver la palette et la mascotte mémoire.

Douze PNG RGBA 1254 × 1254, alpha 0–255. Inspection individuelle et dans les douze
captures Flutter, avec chargement/décodage réel vérifié. Fond normal blanc, cartes
centrées via `GameTutorialDeck`, navigation et descriptions accessibles ; grands
caractères testés. Aucun changement de stimuli, de scoring ou de durée réelle.

Six cartes par jeu, avant démarrage et dans l’aide ; dix pour le mode combiné
historique, qui ne joue pas de deuxième interférence visuelle dans le même tour.
Les seuils et nombres expliqués viennent des configurations existantes.

PROVISOIRE — rendu sur appareil à valider, décision 69 de `GAMES_MODULE.md`.
Les écarts techniques préexistants vérifiés sont décrits dans `AUDIT_LOGIQUE.md`.
