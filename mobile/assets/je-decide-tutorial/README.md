# Je Décide — illustrations du tutoriel

Générées le 2026-09-17 avec `image_gen.imagegen`, une image par appel.
Les prompts exacts, les originaux et les destinations sont consignés dans `manifest.json`.
Les originaux sont conservés dans le dossier de génération Codex ; les six fichiers de
production sont copiés sans modification dans `mobile/assets/games icons/`, déjà déclaré
dans `pubspec.yaml`. Aucune nouvelle dépendance ni déclaration d’asset.

| Carte | PNG de production | Explication |
|---|---|---|
| Lire | `Je Decide Tutorial Read.png` | Repérer le contexte et les informations utiles |
| Choisir | `Je Decide Tutorial Choose.png` | Sélectionner une option puis continuer |
| Suivre | `Je Decide Tutorial Linked.png` | Scénarios en deux parties liées |
| Chrono | `Je Decide Tutorial Time.png` | Budget variable, validation ou passage à zéro |
| Essayer | `Je Decide Tutorial Practice.png` | Un exemple avant les 30 questions |
| Bilan | `Je Decide Tutorial Profile.png` | Cinq dimensions, cotations provisoires signalées |

Direction visuelle : objets arrondis en 2.5D, bleu marine, violet, magenta et touches
de cyan. Le chemin magenta et ses étapes rappellent les illustrations existantes du jeu.
Aucune réponse recommandée, clé de cotation ni symbole de réponse correcte.

Six PNG RGBA 1254 × 1254, alpha 0–255 contrôlé. Illustrations inspectées séparément
et dans les six captures Flutter, avec décodage réel des images vérifié.

Les nombres proviennent de `DecisionConfig`. Le tutoriel ne promet pas sept secondes
fixes pour les questions rapides : leur budget est fourni par le serveur. Aucun changement
de passation, de scoring ou de stimulus psychométrique. L’aide conserve le mécanisme
de pause existant et retourne à son menu ; le chrono et le choix sont préservés.

PROVISOIRE — rendu sur appareil à valider (décision 68 de `GAMES_MODULE.md`).

## Parcours simplifié — 2026-09-17

Trois cartes sont désormais utilisées, dans cet ordre : `Choose` (lire et choisir),
`Linked` (histoire en deux parties), `Time` (chronomètre). `Read`, `Practice` et
`Profile` restent des sources archivées ; leurs fichiers et leur provenance sont conservés.
L’accueil porte le logo officiel, le but, la durée, les 30 questions et la mention
du profil à cinq dimensions avec cotations provisoires. Il mène directement aux règles par « Commencer ».
La personnalisation (pseudo, thème et avatar) est retirée à la demande de l’utilisateur ;
les assets originaux d’avatar restent archivés. Décision 75 dans `GAMES_MODULE.md`.
Un seul exemple d’entraînement suit les trois cartes, avant l’ouverture de session.
Décision de parcours 73 dans `GAMES_MODULE.md` ; rendu sur appareil à valider.

L’entrée depuis l’accueil conserve désormais l’en-tête du jeu (retour et menu) et
la barre basse. L’en-tête interne de la pile est masqué uniquement dans ce cas ;
l’aide plein écran reste autonome. Fondu/glissement léger à l’entrée et au retour ;
mouvement réduit respecté. Décision visuelle 74 ; aucune nouvelle illustration.
