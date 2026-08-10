# Je Coordonne — exploration de logo V2

Cette série corrige la première exploration, jugée trop abstraite. Elle repart du logo actif
`mobile/assets/games icons/Je Coordonne.png` comme référence directe et conserve ses quatre signes
indissociables : **trajectoire carrée**, **cible orange**, **viseur blanc** et **mouvement horaire**.
Le logo actif n'est pas remplacé par ce travail : ces fichiers restent des options de sélection.

## Direction commune

- PNG carré **1024 × 1024 RGBA**, fond transparent.
- Emprise visible normalisée à environ **84 %** du canvas.
- Palette Games stricte : `#071333`, `#4E46E8`, `#00A9D6`, `#D12E7D`, `#FF9F43`, `#FFFFFF`.
- Construction vectorielle/flat, traits épais, coins arrondis et silhouette lisible dans le hub.
- Aucun texte, lettre, main, personnage, tuile de fond, ombre, texture ou métaphore abstraite.

## Les quatre propositions

### 01 — Square Sync — recommandée

La simplification la plus fidèle au logo actif : un rail carré dominant, une cible orange agrandie,
un viseur blanc et une flèche courte. Elle raconte immédiatement « suivre précisément la bille autour
du carré » et reste la plus claire à la taille réelle de 36 px.

### 02 — Corner Lock

Le virage supérieur droit devient le moment central : la cible est verrouillée par le viseur pendant
le changement de direction. La cible a été agrandie après le premier contrôle miniature afin de
passer le seuil de lisibilité à 36 px.

### 03 — Dual Pace

Les segments cyan et magenta distinguent les allures lente et rapide sans introduire une deuxième
bille. Une seule cible reste suivie, sur deux rails carrés concentriques, ce qui relie directement le
symbole aux deux vitesses du protocole.

### 04 — Precision Capture

Cette variante met l'alignement curseur–cible au premier plan : le point blanc est exactement au
centre de la bille orange, encadrée par le viseur. La cible passe au coin inférieur droit pour créer
une option distincte sans sortir de la grammaire du logo actif.

## Contrôle qualité

| Contrôle | Résultat |
|---|---|
| Format | 4/4 en PNG RGBA 1024 × 1024 |
| Fond | 4/4 transparents, alpha nul aux quatre coins |
| Frange chroma | 0 pixel vert résiduel visible sur les 4 fichiers |
| Emprise | 4/4 à 83,98 % du canvas |
| Cible orange à 36 px | 6 px · 6 px · 5 px · 7 px |
| Silhouette à 36 px | 4/4 sans poussière ni composante isolée |
| Fonds de contrôle | blanc et violet `#4E46E8` dans la planche comparative |
| Tailles contrôlées | 36 / 56 / 88 px |

## Méthode de génération

- Mode : génération ImageGen avec le logo actif comme **référence de style et de sémantique**.
- Structure de prompt commune : logo mobile professionnel, rail carré blanc/bleu nuit, cible orange,
  viseur blanc, flèche horaire, trois accents cyan/magenta/indigo, aucune abstraction concurrente.
- Transparence : génération sur fond chroma `#00FF00`, détourage doux avec despill, puis remappage
  des pixels visibles sur la palette Games exacte.
- La variante 02 a reçu une itération ciblée : agrandissement du groupe cible + viseur uniquement.

La série V1 rejetée est conservée dans `rejected-v1-abstract/` pour garder l'historique de recherche.
