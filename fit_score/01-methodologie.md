# Méthodologie

[← Retour au sommaire](00-README.md)

Cette matrice applique un modèle en deux couches à chaque métier, pour dériver une proposition de pondération hard/soft et de poids des 5 modules soft skills, par niveau hiérarchique (Junior, Senior, Lead, Manager).

## Couche A — Profil du métier

Chaque métier est classé selon sa nature dominante : **Technique, Analytique, Relationnel, Managérial, Conventionnel ou Artistique**. Ce profil détermine quels modules soft skills dominent (colonnes Flex. cognitive, Mémoire travail, Prise décision, Planification exécutive, Régulation émotionnelle) et l'amplitude générale du hard skills.

### Le profil « Conventionnel » — qu'est-ce que c'est ?

Ce profil a été ajouté pour couvrir des métiers dont la compétence dominante n'est ni l'analyse ouverte de problèmes complexes (Analytique), ni la résolution technique de problèmes concrets (Technique), mais la rigueur, le respect de procédures documentées et la précision d'exécution. Il s'inspire de la dimension « Conventional » du modèle RIASEC (Holland), un cadre reconnu en psychologie du travail qui distingue ce type de profil de la dimension « Investigative » (analyse, recherche de sens dans des données ambiguës).

Concrètement, un métier Conventionnel se caractérise par :
- l'application de règles ou de procédures documentées plutôt que la résolution de problèmes ouverts ;
- une expertise qui se stabilise plus tôt dans la carrière plutôt que de se complexifier indéfiniment avec l'expérience ;
- une valeur ajoutée qui repose sur la fiabilité et l'exactitude de l'exécution plutôt que sur l'innovation ou l'analyse stratégique.

C'est pourquoi ses modules soft skills prioritaires sont Mémoire de travail et Planification exécutive (suivre, organiser, exécuter avec constance), plutôt que Flexibilité cognitive ou Prise de décision (dimensions plus associées à l'improvisation face à l'ambiguïté).

**Exemples de métiers reclassés sous ce profil :** Comptable, Chargé de conformité / Compliance officer, Gestionnaire de stock, Agent de quai / Magasinier, Technicien qualité, Métreur, Commis de cuisine, Opérateur de production — précédemment classés Analytique ou Technique, mais dont la nature réelle du travail est davantage procédurale qu'analytique ou technique au sens strict.

### Le profil « Artistique » — qu'est-ce que c'est ?

Ce profil couvre les métiers dont la compétence dominante est la création — génération d'idées, sens esthétique, expression visuelle ou narrative — plutôt que l'analyse de données, la résolution technique de problèmes ou la coordination d'équipe. Il s'inspire de la dimension « Artistic » du modèle RIASEC (Holland), distincte des dimensions Investigative (Analytique) et Realistic (Technique). Son module prioritaire est Flexibilité cognitive, nettement plus dominant que dans les autres profils, car la pensée divergente (explorer plusieurs directions créatives) est au cœur de ce type de poste à tous les niveaux d'ancienneté.

Sa courbe hard skills a un pic plus bas que Technique ou Analytique (55 % contre 65 % et 60 %) : contrairement à un métier Technique où l'expertise dure peut presque suffire seule au sommet de la maîtrise, un poste créatif reste structurellement dépendant du soft skills même chez un expert confirmé — la créativité ne devient jamais secondaire.

**Point de vigilance sur la mesure** — contrairement aux autres profils, le hard skills d'un métier Artistique n'est généralement pas mesurable par un QCM automatique : il repose sur l'évaluation d'un portfolio (projets réalisés, démarche, qualité de restitution), notée selon une grille structurée plutôt qu'un score de test. La formule de calcul du Fit Score reste identique ; seule la source du Score_Hard change.

**Métiers classés sous ce profil dans cette version :** UX/UI Designer, Graphiste / Designer, UX/UI e-commerce, Scénariste (reclassés depuis Analytique ou Technique), ainsi que Directeur artistique, Illustrateur / Concept artist, Compositeur / Sound designer, Photographe, Motion designer et Styliste / Designer produit (nouveaux métiers ajoutés dans cette version).

## Couche B — Modificateur de niveau

Un même pattern relatif s'applique à tous les métiers : le poids du hard skills atteint son pic au niveau Senior, puis diminue progressivement à mesure que la responsabilité de leadership augmente — un Lead reste fortement technique mais déjà moins qu'un Senior, et un Manager, où le leadership prime sur l'expertise technique pure, l'est nettement moins encore. Seule l'amplitude de cette courbe change selon le profil du métier (Couche A) — un métier Technique a une amplitude plus marquée qu'un métier Relationnel.

### Courbe hard skills appliquée par profil (%)

| Profil de métier | Junior | Senior | Lead | Manager |
|---|---|---|---|---|
| Technique | 35% | 65% | 55% | 30% |
| Analytique | 30% | 60% | 50% | 25% |
| Artistique | 30% | 55% | 45% | 25% |
| Managérial | 20% | 40% | 35% | 20% |
| Conventionnel | 25% | 40% | 35% | 20% |
| Relationnel | 10% | 25% | 20% | 10% |

> ⚠️ **Avertissement** — ces pourcentages sont des estimations de départ, dérivées mécaniquement du modèle Couche A + Couche B. Ils n'ont pas été validés par les équipes RH et ne doivent pas être mis en production tels quels. Les profils Conventionnel et Artistique, les plus récemment introduits, sont particulièrement à valider en priorité en atelier RH : leurs courbes et leurs poids de modules sont des propositions illustratives, pas des résultats mesurés. Le profil Artistique appelle en plus une décision produit sur le mécanisme d'évaluation du hard skills (portfolio plutôt que QCM), distincte de la validation des poids eux-mêmes. Ils servent de point de départ structuré pour l'atelier de validation métier par métier (voir [recommandations en fin de document](16-prochaines-etapes.md)).

**Rappel** — le secteur d'activité n'intervient pas dans cette matrice : il ne détermine que le contenu du QCM hard skills (référentiel de questions), jamais la pondération. Les métiers sectoriels listés dans les fichiers suivants le sont sous leur secteur uniquement pour la lisibilité du document.

[← Retour au sommaire](00-README.md) | [Suivant : Métiers transverses →](02-metiers-transverses.md)
