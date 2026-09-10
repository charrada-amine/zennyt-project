# ZENNYT — Cahier des charges

**Système de calcul du Fit Score candidat ↔ offre d'emploi**

*Version 3.0 — Modèle métier / société / offre*

Statut : proposition restructurée
Périmètre : matching soft skills / hard skills

## Sommaire

1. [Contexte et objectifs](#1-contexte-et-objectifs)
2. [Principes de conception](#2-principes-de-conception)
3. [Formule de calcul du Fit Score](#3-formule-de-calcul-du-fit-score)
4. [Deux axes indépendants : Métier × Niveau vs Secteur](#4-deux-axes-indépendants--métier--niveau-vs-secteur)
5. [Hiérarchie d'héritage de la pondération (3 niveaux)](#5-hiérarchie-dhéritage-de-la-pondération-3-niveaux)
6. [Indicateur d'alerte hard skills manquant](#6-indicateur-dalerte-hard-skills-manquant)
7. [Affichage du matching sur les fiches candidats](#7-affichage-du-matching-sur-les-fiches-candidats)
8. [Modèle de données consolidé](#8-modèle-de-données-consolidé)
9. [Paramétrage côté recruteur](#9-paramétrage-côté-recruteur)
10. [Points ouverts / recommandations](#10-points-ouverts--recommandations)

---

## 1. Contexte et objectifs

Zennyt met en relation des candidats et des offres d'emploi réparties sur plusieurs secteurs d'activité (IT/AI/Fintech, Consulting, Finance, Santé, Marketing, Industrie, etc.), publiées par des recruteurs rattachés à des sociétés aux cultures, missions et objectifs propres. Le profil du candidat repose sur deux dimensions mesurées séparément :

- **Soft skills** — mesurés via des jeux psychométriques répartis en 5 modules (Flexibilité cognitive, Mémoire de travail, Prise de décision, Planification exécutive, Régulation émotionnelle), chacun avec un taux de couverture. Cette dimension est systématique : elle existe pour tous les candidats et toutes les offres.
- **Hard skills** — mesurés via un QCM optionnel, ajouté par le recruteur au moment de la publication de l'offre. Cette dimension est conditionnelle : elle n'existe que si le recruteur choisit de l'activer.

**Objectif du présent document** : définir une structure de calcul du Fit Score (score de compatibilité en %) entre un candidat et une offre, qui priorise structurellement les soft skills, pondère hard/soft selon la nature réelle du poste (le métier, indépendamment du secteur), et tienne compte des spécificités propres à chaque société, tout en restant ajustable au niveau de l'offre individuelle.

## 2. Principes de conception

- Le socle du Fit Score est le score soft skills : il est toujours calculable, pour toute offre, avec ou sans QCM.
- Le score brut de chaque compétence (mesuré indépendamment de l'offre) est séparé du poids qui lui est attribué.
- La pondération est pilotée par le **métier × niveau hiérarchique** — pas par le secteur d'activité, qui ne détermine que le contenu du QCM hard skills (voir section 4).
- La pondération suit une hiérarchie d'héritage à 3 niveaux — **métier → société → offre** — chaque niveau pouvant surcharger le précédent (voir section 5).
- Le calcul du matching (fit_score) se fait toujours au niveau de l'offre individuelle, car c'est elle qui porte les données réelles (QCM, scores candidat, couverture) — seule la pondération utilisée dans ce calcul est héritée des niveaux supérieurs.
- Le score affiché intègre un facteur de fiabilité lié au taux de couverture des jeux psychométriques, pour éviter d'afficher un score de confiance élevé basé sur des données partielles.
- La description textuelle libre d'une offre n'est jamais une source de pondération automatique : seuls les niveaux structurés (métier, société, offre) pilotent le calcul.

## 3. Formule de calcul du Fit Score

### 3.1 Niveau global — soft skills en composante principale

```
Fit_Score = (Score_Soft × Poids_Soft) + (Score_Hard × Poids_Hard)

avec : Poids_Soft + Poids_Hard = 100 %
```

**Règle par défaut** — si le recruteur n'a pas ajouté de QCM hard skills à l'offre, alors Poids_Soft = 100 % et Poids_Hard = 0 %. Le Fit_Score est alors strictement égal au Score_Soft, sans pénalité pour le candidat.

### 3.2 Détail du score soft skills (5 modules)

```
Score_Soft = Σ (Score_module_i × Poids_module_i), pour i = 1 à 5

avec : Σ Poids_module_i = 100 %
```

Chaque module reçoit un poids propre au métier/niveau. Exemple : un poste de management pèsera fort sur Régulation émotionnelle et Planification exécutive ; un poste analytique pèsera fort sur Flexibilité cognitive et Prise de décision.

### 3.3 Facteur de fiabilité (coverage)

```
Score_module_i_ajusté = Score_module_i × f(Couverture_i)
```

**Exemple chiffré** — Candidat avec score brut 90/100 sur un module, couverture 100 % → score ajusté = 90 × 1,0 = 90 (inchangé). Candidat avec score brut 90/100 sur le même module, couverture 40 % → score ajusté = 90 × 0,4 = 36 (fortement réduit). Le score ajusté, et non le score brut, est celui qui entre dans le calcul de Score_Soft puis du Fit_Score.

Deux mécanismes distincts interviennent ensuite, et ne doivent pas être confondus :

- **Mécanisme 1** — l'ajustement ci-dessus, qui réduit le score de façon continue et proportionnelle dès que la couverture est inférieure à 100 %, quel que soit le niveau de couverture.
- **Mécanisme 2** — les seuils de couverture (60 % / 70 %, voir tableau ci-dessous), qui n'ajustent pas davantage le score déjà réduit par le Mécanisme 1, mais déclenchent une décision d'affichage : badge « données partielles », ou masquage du Fit Score si l'offre n'a pas de QCM. En dessous du seuil, la donnée est jugée trop incomplète pour qu'un simple ajustement mathématique suffise à rassurer le recruteur.

Seuils proposés (à valider avec les équipes RH) :

| Configuration de l'offre | Seuil minimal proposé | Comportement si non atteint |
|---|---|---|
| Offre avec QCM hard skills (hard + soft) | 60 % de couverture par module | Badge « données partielles » sur le(s) module(s) concerné(s) |
| Offre sans QCM (100 % soft skills) | 70 % de couverture globale (seuil renforcé) | Fit Score masqué ou badge renforcé — pas de dimension hard pour compenser l'incertitude |

## 4. Deux axes indépendants : Métier × Niveau vs Secteur

Le métier et le secteur ne jouent pas le même rôle dans le calcul — les confondre conduit à une pondération incohérente (un secteur mélange des métiers trop différents pour partager une même logique de pondération).

### 4.1 Le métier × niveau pilote la pondération

Le métier détermine la nature réelle du poste (technique, relationnel, analytique, managérial) et donc quels modules soft skills comptent le plus, et combien le hard skills doit peser à chaque niveau hiérarchique :

- Le niveau hiérarchique détermine combien chaque catégorie pèse dans le score final.
- La relation n'est pas linéaire : le poids du hard skills atteint son pic au niveau Senior, puis diminue progressivement à mesure que la responsabilité de leadership augmente — un Lead reste fortement technique mais déjà moins qu'un Senior, et un Manager, où le leadership prime sur l'expertise technique pure, l'est nettement moins encore.

| Niveau | Logique de pondération | Modules soft skills prioritaires |
|---|---|---|
| **Junior** | Soft skills dominant (potentiel, adaptabilité). Hard skills évalué avec plus de souplesse. | Flexibilité cognitive, Mémoire de travail |
| **Senior / Expert** | Hard skills dominant (expertise technique validée par le QCM). | Prise de décision, Flexibilité cognitive |
| **Lead** | Équilibre hard / soft, avec accent sur la prise de décision. | Prise de décision, Planification exécutive |
| **Manager** | Soft skills de nouveau dominant, mais orienté leadership plutôt que potentiel. | Régulation émotionnelle, Planification exécutive |

### 4.2 Le secteur pilote uniquement le contenu du QCM hard skills

Le secteur d'activité (IT/AI/Fintech, Consulting, Finance, Santé, Marketing, Industrie…) ne détermine que le référentiel de questions hard skills utilisé pour un métier donné — jamais la pondération. Un Développeur Senior en Fintech et un Développeur Senior en Santé partagent la même pondération métier/niveau ; seul le contenu du QCM diffère.

### 4.3 Modèle de dérivation des poids par défaut (Couche A + Couche B)

Pour construire les poids par défaut de chaque job_role_profile (métier × niveau), on applique un modèle en deux couches plutôt que de fixer chaque valeur métier par métier de façon isolée :

- **Couche A** — le profil du métier : chaque métier est classé selon sa nature dominante, ce qui détermine quels modules soft skills comptent le plus.
- **Couche B** — le modificateur de niveau : un même pattern relatif s'applique à tous les métiers (le poids du hard skills atteint son pic au niveau Senior, puis diminue progressivement jusqu'au Manager), seule l'amplitude de cette courbe variant selon le profil de la Couche A.

Six profils de métier sont retenus :

| Profil métier | Nature dominante | Modules soft skills prioritaires |
|---|---|---|
| **Technique** | Résolution concrète de problèmes techniques (construire, développer, réparer). | Flexibilité cognitive, Prise de décision |
| **Analytique** | Analyse ouverte de données ou de situations complexes, recherche de sens dans l'ambigu. | Flexibilité cognitive, Prise de décision |
| **Relationnel** | Interaction humaine, écoute, persuasion, accompagnement. | Régulation émotionnelle, Prise de décision |
| **Managérial** | Coordination d'équipe, leadership, arbitrage. | Planification exécutive, Régulation émotionnelle |
| **Conventionnel** | Application de règles et de procédures documentées, précision d'exécution. | Mémoire de travail, Planification exécutive |
| **Artistique** | Création : génération d'idées, sens esthétique, expression visuelle ou narrative. | Flexibilité cognitive (dominante) |

**Le profil « Conventionnel »** — ce profil couvre les métiers dont la compétence dominante n'est ni l'analyse ouverte (Analytique) ni la résolution technique de problèmes (Technique), mais la rigueur et le respect de procédures documentées — par exemple Comptable, Gestionnaire de stock, Technicien qualité, ou Chargé de conformité. Il s'inspire de la dimension « Conventional » du modèle RIASEC (Holland), reconnu en psychologie du travail. Sa courbe hard skills est plus plate et son pic moins élevé que Technique ou Analytique : l'expertise de ce type de métier se stabilise plus tôt dans la carrière plutôt que de se complexifier indéfiniment avec l'expérience.

**Le profil « Artistique »** — ce profil couvre les métiers dont la compétence dominante est la création — génération d'idées, sens esthétique, expression visuelle ou narrative — par exemple UX/UI Designer, Graphiste, Illustrateur, Photographe, Compositeur / Sound designer, Scénariste, Directeur artistique. Il s'inspire de la dimension « Artistic » du modèle RIASEC (Holland). Son module prioritaire, Flexibilité cognitive, est nettement plus dominant que dans les autres profils, la pensée divergente étant au cœur de ce type de poste à tous les niveaux d'ancienneté. Sa courbe hard skills a un pic plus bas (55 %) que Technique ou Analytique : un poste créatif reste structurellement dépendant du soft skills même chez un expert confirmé.

**Mesure du hard skills pour le profil Artistique — mécanisme spécifique** : contrairement aux autres profils, le hard skills d'un métier Artistique n'est pas toujours mesurable par un QCM automatique classique. Trois modes d'évaluation sont possibles, configurés au niveau du job_role_profile via le champ `type_evaluation_hard` :

- **QCM** — pour les composantes objectivement vérifiables (ex. maîtrise d'un logiciel, normes d'accessibilité) ; peu de métiers Artistique s'y prêtent seuls.
- **Portfolio** — évaluation humaine structurée (grille de critères notés par un expert : démarche, cohérence, résolution du problème posé, qualité de restitution) ; mode par défaut pour la majorité des métiers Artistique (Illustrateur, Photographe, Compositeur, Scénariste, Directeur artistique).
- **Mixte** — combinaison des deux : `Score_Hard = (Score_QCM × poids_qcm) + (Score_Portfolio × poids_portfolio)`, avec poids_qcm + poids_portfolio = 100 %. Pertinent pour les métiers hybrides comme UX/UI Designer (QCM sur la méthodologie et les outils, Portfolio sur le jugement esthétique) ou Motion designer.

Dans tous les cas, la formule globale du Fit Score reste strictement identique (`Fit_Score = Score_Soft × Poids_Soft + Score_Hard × Poids_Hard`) — seule la source du Score_Hard change selon le mode retenu pour le métier.

Courbe hard skills appliquée par profil, à titre indicatif :

| Profil métier | Junior | Senior | Lead | Manager |
|---|---|---|---|---|
| **Technique** | 35% | 65% | 55% | 30% |
| **Analytique** | 30% | 60% | 50% | 25% |
| **Artistique** | 30% | 55% | 45% | 25% |
| **Managérial** | 20% | 40% | 35% | 20% |
| **Conventionnel** | 25% | 40% | 35% | 20% |
| **Relationnel** | 10% | 25% | 20% | 10% |

> **Avertissement** — les valeurs de cette courbe sont des estimations de départ dérivées mécaniquement du modèle Couche A + Couche B — elles n'ont pas été validées par les équipes RH. Le profil Conventionnel, introduit plus récemment que les quatre autres, est à valider en priorité en atelier RH, de même que la liste des métiers qui lui sont rattachés.

## 5. Hiérarchie d'héritage de la pondération (3 niveaux)

La pondération appliquée à une offre résulte de l'héritage successif de 3 niveaux, chacun pouvant surcharger le précédent :

```
job_role_profile (métier, niveau)
   ↓ hérite, puis peut surcharger
company_profile (société)
   ↓ hérite, puis peut surcharger
offer (offre individuelle)
```

| Niveau | Rôle | Exemple |
|---|---|---|
| **1. job_role_profile (métier × niveau)** | Poids par défaut, communs à tout Zennyt, pour un métier et un niveau hiérarchique donnés. | Développeur Senior → Poids_Hard 55 %, Poids_Soft 45 % |
| **2. company_profile (société)** | Ajustements propres à la culture, la mission ou les objectifs d'une société, appliqués à toutes ses offres. | Société X, culture collaborative → +5 % sur Régulation émotionnelle pour tous ses postes |
| **3. offer (offre individuelle)** | Overrides ponctuels saisis par le recruteur, pour un besoin spécifique à cette offre précise. | Ce poste précis exige une expertise réglementaire renforcée → ajustement local |

**Pourquoi ce niveau intermédiaire** — une société a une culture, une mission, des objectifs propres qui s'appliquent à toutes ses offres, indépendamment du métier. Sans ce niveau, chaque recruteur de la société devrait ressaisir le même ajustement à chaque publication d'offre — source d'oubli et d'incohérence entre recruteurs d'une même société.

## 6. Indicateur d'alerte hard skills manquant

Lorsqu'une offre est publiée sans QCM hard skills, le système ne pénalise jamais le candidat — mais il peut alerter le recruteur si l'absence de test est structurellement problématique pour ce métier/niveau. Le champ `poids_hard_attendu` est purement informationnel : il n'entre jamais dans le calcul du Fit Score.

| Niveau | Poids hard attendu (référentiel) | Message si offre publiée sans QCM |
|---|---|---|
| **Junior** | Faible (~20-35 %) | Pas d'alerte (`< 20 %`), ou alerte discrète (`20-35 %`) |
| **Senior / Lead** | Fort (`> 35 %`) | Alerte modérée (`35-50 %`) à forte (`≥ 50 %`) : les postes Senior/Lead reposent normalement à ~50-65 % sur le hard skills. Sans QCM, le Fit Score sera basé à 100 % sur les soft skills. |
| **Manager** | Modéré à faible selon le métier (~10-30 %) | **Alerte modérée, systématiquement** — palier fixe indépendant du poids calculé |

> **Note de dérivation (FITSCORE_REMEDIATION.md §2 décision D-B, tâche F05).** Cette table n'est pas monotone en fonction du poids hard réel : un poste Manager pèse souvent *moins* de hard skills qu'un poste Junior (ex. Technique Manager = 30 %, Technique Junior = 35 %), alors que le Manager doit tout de même afficher une alerte modérée. Aucune fonction de seuil unique sur `poids_hard_attendu` ne peut donc reproduire les trois lignes à la fois. L'implémentation dérive Junior et Senior/Lead par seuil sur le poids (`< 20 %` → aucune, `≤ 35 %` → discrète, `< 50 %` → modérée, sinon forte), et applique un **palier fixe** à Manager (toujours modérée), plutôt que de forcer un seuil qui casserait Junior ou Senior/Lead. Voir `JobRoleProfile.hardSkillsAlert()`.

**Cas particulier du profil Artistique** — pour ce profil, l'absence de QCM (ou de mode Mixte) n'est pas une anomalie à signaler comme un oubli — c'est le fonctionnement normal pour la plupart de ces métiers, puisque leur hard skills s'évalue par portfolio. Le message affiché au recruteur est donc informatif, pas une alerte : « Le hard skills de ce métier s'évalue par portfolio — consultez le portfolio du candidat pour juger la qualité du travail », plutôt que le message d'incitation à ajouter un QCM utilisé pour les autres profils.

## 7. Affichage du matching sur les fiches candidats

Le Fit Score combiné reste le signal principal de tri et de comparaison entre candidats sur une offre donnée. Le détail des composantes (Soft Score, % réussite hard skills) est affiché en complément, jamais en doublon d'une valeur identique :

| Contexte | Étiquettes affichées |
|---|---|
| **Page de matching (avant QCM)** | Une seule étiquette : Fit Score % — basé sur les soft skills, sans doublon avec un « Soft Score » identique |
| **Liste de candidats — offre sans QCM** | Fit Score % (= Soft Score, mention explicite « basé sur les soft skills ») |
| **Liste de candidats — offre avec QCM** | Fit Score % en avant (signal principal de tri) + détail en sous-ligne : Soft Score % · % réussite hard skills |

**Résumé IA du candidat — profil Artistique** — lorsque le `job_role_profile` associé est de type Artistique et repose uniquement sur une évaluation Portfolio (pas de QCM ni de mode Mixte), le résumé généré pour le recruteur inclut explicitement une phrase du type : « Ce profil relève d'un métier créatif. Le Fit Score affiché reflète uniquement l'évaluation des soft skills — la qualité technique et créative du travail n'est pas mesurée automatiquement. Nous vous recommandons d'examiner directement le portfolio du candidat avant de prendre votre décision. » Cette phrase ne s'affiche pas si le métier utilise un mode Mixte ou QCM.

## 8. Modèle de données consolidé

### 8.1 job_role_profile (métier × niveau)

Poids par défaut, communs à tout Zennyt, indépendants du secteur et de la société.

| Champ | Type | Description |
|---|---|---|
| **metier** | string | Métier type (ex. Développeur, Commercial, Consultant…) |
| **profil_metier** | enum | Technique \| Analytique \| Relationnel \| Managérial \| Conventionnel \| Artistique — Couche A, détermine les poids de modules par défaut |
| **niveau** | enum | Junior \| Senior \| Lead \| Manager |
| **poids_soft** | % | Poids global des soft skills dans le Fit Score |
| **poids_hard** | % \| null | Poids global des hard skills ; null/absent si aucun QCM n'est associé à l'offre |
| **poids_hard_attendu** | % | Poids hard théorique attendu pour ce métier/niveau — sert uniquement à l'alerte recruteur, jamais au calcul du score |
| **poids_module_\*** | % (×5) | Poids des 5 modules soft skills |
| **type_evaluation_hard** | enum | QCM \| Portfolio \| Mixte — mode de mesure du hard skills, pertinent surtout pour le profil Artistique |
| **poids_qcm / poids_portfolio** | % / % | Répartition du Score_Hard si type_evaluation_hard = Mixte ; somme = 100 % |

### 8.2 company_profile (société)

Ajustements propres à la culture, la mission ou les objectifs d'une société, appliqués à toutes ses offres.

| Champ | Type | Description |
|---|---|---|
| **societe_id** | id | Référence à la société |
| **scope** | enum | global (toutes les offres) ou métier (ciblé sur un métier précis) — recommandé : démarrer en global |
| **overrides** | objet | Ajustements de poids (soft/hard, modules) propres à la culture/mission de la société |

### 8.3 offer, candidate_profile, fit_score

- **offer** — référence un job_role_profile et, le cas échéant, un company_profile ; porte un champ optionnel overrides (poids personnalisés saisis par le recruteur pour cette offre précise).
- **candidate_profile** — stocke le score brut et le taux de couverture par module, indépendamment de toute offre.
- **fit_score (candidat, offre)** — résultat calculé à la volée ou mis en cache au niveau de l'offre, recalculé si le profil candidat ou la pondération (à n'importe lequel des 3 niveaux) change.

## 9. Paramétrage côté recruteur

- Le recruteur choisit un métier et un niveau hiérarchique à la création de l'offre → les poids du job_role_profile sont pré-remplis, puis ajustés automatiquement par le company_profile de sa société s'il existe.
- Le recruteur peut ajuster manuellement les curseurs de pondération (soft/hard, puis par module) avant publication — override visible et distinct de l'héritage automatique.
- Si le recruteur n'ajoute aucun QCM hard skills, le champ poids_hard reste absent de l'interface de calcul ; une alerte contextuelle s'affiche selon le tableau de la section 6.
- Si le recruteur ajoute un QCM hard skills après coup, le champ poids_hard s'active et la pondération soft/hard redevient éditable selon le profil hérité.

## 10. Points ouverts / recommandations

- Construire et valider avec les RH le référentiel métier × niveau (job_role_profile) — préalable indispensable à toute mise en production.
- Valider en priorité le profil Conventionnel, introduit plus récemment que les quatre autres profils : confirmer la liste des métiers qui lui sont rattachés et ajuster sa courbe hard/soft et ses poids de modules si l'atelier RH le juge nécessaire.
- Valider en priorité le profil Artistique, ainsi que le mode d'évaluation du hard skills (QCM, Portfolio ou Mixte) retenu pour chaque métier concerné, et construire la grille d'évaluation structurée des portfolios avant mise en production.
- Décider de la granularité du company_profile : global à la société, ou croisé société × métier — démarrer en global, affiner si besoin réel constaté en usage.
- Valider le seuil minimal de couverture des jeux psychométriques (60 % en mode hard+soft, 70 % proposé en mode soft seul).
- Définir si le QCM hard skills doit lui aussi être décliné par niveau (questions plus avancées pour un poste Senior/Lead que pour un poste Junior sur le même référentiel métier).
- Prévoir un mécanisme d'audit / versioning sur les job_role_profile et les company_profile pour tracer les évolutions de pondération dans le temps.
- Documenter explicitement, dans l'interface recruteur, que le mode « soft skills seul » est un mode de fonctionnement standard du système et non un cas dégradé.
