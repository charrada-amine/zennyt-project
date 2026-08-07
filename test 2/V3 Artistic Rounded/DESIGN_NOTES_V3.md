# Je Coordonne — exploration logo V3

Cette série répond au rejet de la V2, dont les quatre propositions conservaient presque la même
construction carrée. La V3 ne garde que les ancrages de marque indispensables — contour bleu nuit,
palette Games, cible orange et formes plates — puis attribue à chaque proposition une **silhouette
propre**, plus large, plus ronde et plus expressive.

## 01 — Circuit souple

Un ruban-squircle très large transforme le plateau carré en un mouvement continu et accueillant.
La cible orange et le curseur blanc restent immédiatement référentiels au gameplay, tandis que les
trois zones colorées racontent la progression, l'ajustement et le contrôle.

## 02 — Virage magnétique — recommandation

La trajectoire n'est plus un cadre : un seul grand virage conduit le point cyan vers la bille orange.
La relation poursuivant/cible est lisible en une seconde, la forme est dynamique et l'ensemble reste
net aux petites tailles. C'est le meilleur équilibre entre nouveauté artistique et fidélité au jeu.

## 03 — Regard accordé

L'œil est traité comme une sculpture géométrique, pas comme un symbole anatomique. La bille orange
devient la cible regardée et le point cyan vient s'aligner avec elle : la coordination visio-motrice
est racontée sans reprendre le plateau. C'est l'option la plus conceptuelle de la série.

## 04 — Geste précis

Deux capsules abstraites évoquent un geste de guidage autour de la cible. Cette piste apporte une
dimension humaine et tactile, avec une diagonale énergique et des masses généreuses, sans dessiner
une main réaliste ni utiliser un pictogramme d'accessibilité générique.

## Grammaire commune

- palette stricte : `#071333`, `#4E46E8`, `#00A9D6`, `#D12E7D`, `#FF9F43`, `#FFFFFF` ;
- aplats sans texture, contour bleu nuit épais, extrémités et angles arrondis ;
- une cible orange dominante et un indice cyan de suivi ou d'alignement ;
- une seule idée principale par logo, sans texte, cadre décoratif ni détail fragile ;
- zone visible normalisée sur un canvas carré de 1024 px.

## Production et contrôle

- mode ImageGen : `logo-brand`, un appel indépendant par direction ;
- référence au logo actif utilisée uniquement pour la sémantique et la palette, pas pour recopier
  sa géométrie ; Move Fast et Je Continue utilisés comme références de largeur et de finition ;
- génération sur fond chroma uniforme, détourage avec matte doux et despill, puis remappage sur les
  six couleurs Games ;
- livrables finaux : PNG `RGBA` 1024×1024 à fond réellement transparent ;
- quatre coins alpha = 0, aucune frange verte détectée, six couleurs maximum ;
- contrôle sur fond blanc et violet, puis à 36, 56 et 88 px dans le comparatif.

## Statut d'intégration

Exploration uniquement. Aucun fichier n'a remplacé
`mobile/assets/games icons/Je Coordonne.png`. Le code mobile, le backend, le contrat OpenAPI,
le protocole, le score, `pubspec.yaml` et `pom.xml` ne sont pas modifiés par cette série.
