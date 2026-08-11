# Fit Score v3 — Plan de remédiation à deux

Audit complet du CdC `fit_score/Zennyt_Cahier_des_charges_FitScore_v3.md` (§1 à §10) et de la
matrice `fit_score/00-README.md` … `16-prochaines-etapes.md`.

Chaque constat a été vérifié dans le code. Les calculs ont été rejoués en exécutant le vrai
`DeterministicFitScoreCalculator` compilé depuis les sources (voir §7 Vérification).


## Correctif du 2026-08-11 — l'alerte hard skills suivait la famille, pas le métier

Suite directe de F32. Le mode d'évaluation avait bien déménagé sur `job_positions`, mais
`JobRoleProfile.hardSkillsAlert()` décidait toujours sur `profileType == ARTISTIQUE`. Rien
ne cassait : l'ancien lecteur continuait de répondre, et il répondait faux.

Conséquence : les trois métiers **MIXTE** (UX/UI Designer, UX/UI e-commerce, Motion
designer) annonçaient « portfolio, pas de test attendu » alors que leur mode réclame un QCM.
Leur recruteur n'était jamais averti du test manquant — exactement les trois métiers pour
lesquels F32 avait été faite.

`hardSkillsAlert()` prend désormais le mode en paramètre : seul `PORTFOLIO` court-circuite
la dérivation par les poids, `MIXTE` et `QCM` la suivent. Le mode voyage par le résolveur,
qui chargeait déjà le métier — pas une requête de plus, ce que F20 venait de supprimer.

Deux tests le verrouillent : un test paramétré sur les trois modes à profil et poids
identiques, et un test sur base réelle vérifiant que *Photographe* et *UX/UI Designer* —
même famille, même ligne de pondération — reçoivent deux signaux différents.

---

## Fusion du 2026-08-10 — les trois jeux Games arrivent

L'équipe Games a livré « Je continue », « Je coordonne » et la mémoire visuospatiale.
Trois conséquences, dans l'ordre où elles se sont manifestées :

1. **Collision Flyway.** Leurs migrations étaient numérotées `V27`, `V28`, `V29` — trois
   numéros déjà pris par recruitment. Renumérotées `V61`, `V62`, `V63`. **Le prochain
   numéro libre est V64**, pour tout le monde. Les bases déjà migrées côté Games
   rejoueront ces trois migrations sous leur nouveau numéro : à vérifier chez eux.

2. **Le Fit Score les ignorait.** `SoftSkillModule` les déclarait encore indisponibles,
   donc ils sortaient du dénominateur. Drapeaux passés à `true`. Effet : la flexibilité
   compte désormais 3 jeux et la mémoire 2, donc **jouer Move Fast seul ne couvre plus
   qu'un tiers de la flexibilité** au lieu de la totalité. C'est la décote de couverture
   du CdC §3.3 qui a enfin de quoi s'exercer — les scores d'un candidat partiel baissent,
   ceux d'un candidat complet sont inchangés (`FitScoreBaselineTest` le prouve : les 5
   personas retrouvent leurs valeurs d'origine dès qu'on leur fait jouer tous les jeux).

3. **Le doublon est maintenant surveillé.** `SoftSkillModule` redit ce que
   `MiniGame.isPlayable()` sait déjà, parce que la règle d'architecture interdit à
   recruitment de lire le domaine Games. `SoftSkillModuleGamesParityTest` échoue si les
   deux divergent — c'est ce qui doit rattraper la prochaine livraison.

**Défaut trouvé au passage :** `DevDataSeeder` insérait ses projections soft-skills avec
un identifiant neuf à chaque démarrage. Invisible jusqu'à `V54` et sa contrainte
d'unicité, qui faisait échouer tout **second** démarrage. Rendu idempotent.

---

## 🔄 Mise à jour du 2026-08-04 — après la fusion du travail Games

**L'audit initial (2026-08-03) a été mené sur `integration-with-engagement`, qui ne contenait
pas le travail de l'équipe Games.** La branche `main` (commit `608187e`) réunit désormais tout.
Trois conséquences :

### 1. Un blocage majeur a été trouvé et réparé

`amine/main` **ne démarrait pas**. Trois migrations Flyway portaient un numéro déjà pris :

| Numéro | Référentiel métiers | Jeux |
|---|---|---|
| V24 | `experience_level_bands` | `games_decision_minigame` |
| V25 | `job_positions_table` | `games_emotional_radar` |
| V26 | `job_positions_seed` | `games_reflective_pause_minigame` |

Chaque équipe avait pris la même plage de son côté ; la fusion a gardé les deux jeux de
fichiers, et Flyway refuse de démarrer sur un doublon de version. Personne ne s'en était aperçu
parce que les deux branches fonctionnaient séparément. Les migrations des jeux sont désormais
en **V49, V50, V51** (commit `608187e`).

> ### ⚠️ Piège au premier démarrage après un `git pull`
>
> Maven **copie** les fichiers de migration vers `backend/target/classes/db/migration/` mais ne
> supprime jamais ceux qui ont disparu des sources. Après avoir récupéré la renumérotation,
> votre `target/` contient encore les anciens `V24/V25/V26__games_*.sql` **à côté** des nouveaux
> `V49/V50/V51` — et Flyway lit `target/`, pas les sources. Vous obtenez donc
> `Found more than one migration with version 24` alors que le dépôt est correct.
>
> **La commande à lancer une fois, après le pull :**
> ```
> cd backend && mvnw.cmd clean && mvnw.cmd spring-boot:run -Dspring-boot.run.profiles=dev
> ```
> Le profil `dev` est obligatoire (c'est lui qui porte l'URL de la base). Il faut aussi une base
> `zennyt` sur `localhost:5432` : `CREATE DATABASE zennyt;` si elle n'existe pas.

### 2. F03 est FAITE — le plus gros constat de l'audit tombe

`GameType.EMOTIONAL_REGULATION` existe, avec deux mini-jeux jouables
(`EMOTIONAL_RADAR_CORE`, `REFLECTIVE_PAUSE_CORE`). La chaîne est complète de bout en bout :
Games émet → `GameSoftSkillsListener` → `SoftSkillModule.fromGamesModule` → pondération.

**Effet mesuré** (candidat identique, niveau MID, régulation émotionnelle faible) :

| Profil | 5 modules (cible) | Avant fusion (3 mod.) | Après fusion (4 mod.) |
|---|---|---|---|
| RELATIONNEL | 38 | 61 (**+23**) | **38 (+0)** ✅ |
| MANAGERIAL | 45 | 62 (+17) | 46 (+1) |
| ANALYTIQUE | 50 | 60 (+10) | 54 (+4) |
| ARTISTIQUE | 51 | 60 (+9) | 53 (+2) |
| TECHNIQUE | 52 | 60 (+8) | 57 (+5) |
| CONVENTIONNEL | 53 | 60 (+7) | 55 (+2) |

Les deux infirmières qui obtenaient **le même 61** obtiennent maintenant **80** et **38**. La
dimension qui définit leur métier est enfin mesurée.

**Il reste un seul module inatteignable : `DECISION`** (`DECISION_CORE.playable() == false`,
catalogue de scénarios vide — `EmptyDecisionScenarioCatalog`). L'erreur résiduelle maximale
tombe de **+23 à +5 points**.

### 3. Deux corrections au tableau des constats

| ID | Nouveau statut |
|---|---|
| **F03** | ✅ **FAITE** côté Games. Ne reste qu'à vérifier en bout de chaîne qu'un score de régulation remonte bien jusqu'au Fit Score |
| **F27** | ❌ **N'est pas un bug** sur `main` : `MiniGame.DECISION_CORE` existe bien, le javadoc de `SoftSkillModule` est exact |

**Plages de migration mises à jour** (V49-V51 sont prises par les jeux) :
Phase 0 = **V52-V53** · Track A = **V54-V58** (livré) · Track B = **V59-V63**.

**Baseline §7 à rejouer.** Les chiffres du §7 datent d'avant la fusion. Relancez le harnais sur
`main` avant de commencer : ils vont bouger, surtout sur les profils RELATIONNEL.

---

## Sommaire

1. [Comment utiliser ce document](#1-comment-utiliser-ce-document)
2. [Décisions — TRANCHÉES le 2026-08-03](#2-décisions--tranchées-le-2026-08-03)
3. [Index des constats par sévérité](#3-index-des-constats-par-sévérité)
4. [Phase 0 — ✅ TERMINÉE](#4-phase-0--terminée-le-2026-08-04)
5. [Track A — moteur de calcul & chaîne de mesure](#5-track-a--moteur-de-calcul--chaîne-de-mesure)
6. [Track B — référentiel, alertes, API & client](#6-track-b--référentiel-alertes-api--client)
7. [Vérification](#7-vérification)
8. [Protocole de fusion](#8-protocole-de-fusion)
9. [Definition of Done](#9-definition-of-done)

---

## 1. Comment utiliser ce document

**Pourquoi ce découpage et pas « toi les premiers fichiers, moi les derniers ».**
Les 30 constats ne se répartissent pas par fichier : ils se regroupent en **6 causes racines**
qui traversent chacune plusieurs couches. Un découpage par ordre de fichier vous mettrait tous
les deux dans `DeterministicFitScoreCalculator.java`, `recruitment.openapi.yaml` et le dossier
`db/migration/` en même temps — trois zones à conflit garanti (les migrations Flyway se
conflictent même sans se chevaucher : deux `V49__` = build cassé).

Le découpage retenu donne à chaque track un **ensemble de fichiers strictement disjoint**.
Aucun fichier n'apparaît dans les deux tracks. Les rares points de contact sont isolés dans une
Phase 0 faite ensemble.

**Convention de référence.** Chaque tâche a un identifiant `F01`…`F30`. Utilisez-le dans les
messages de commit (`fix(fitscore): F01 …`) et les PR — ça rend la revue croisée triviale.

**Ordre de travail.** Décisions (§2) → Phase 0 ensemble (§4) → Tracks A et B en parallèle
(§5, §6) → intégration (§8).

---

## 2. Décisions — TRANCHÉES le 2026-08-03

Les six points sont arbitrés. Plus aucune tâche n'est bloquée.

| # | Décision retenue | Conséquence |
|---|---|---|
| **D-A** | **Les 4 niveaux reprennent l'échelle du CdC : `JUNIOR` / `SENIOR` / `LEAD` / `MANAGER`.** On annule le renommage positionnel de V29. Le pic hard (65 %) revient donc sur **`SENIOR`**, conforme au CdC §4.1 (« Senior / Expert : hard skills dominant »). | Nouvelle tâche **F31**, en Phase 0. ⚠️ *changement cassant d'API* — voir l'alerte ci-dessous |
| **D-B** | **On garde la logique du code** (alerte dérivée de l'importance réelle du test technique pour le métier), on corrige les 2 bugs avérés, et on **corrige le CdC §6**. | **F05** débloqué : correctif de bornes, pas de réécriture. **F19** débloqué |
| **D-C** | **Le mode d'évaluation passe par métier** (`job_positions`), pas par famille. Un UX/UI Designer pourra être en Mixte pendant qu'un Photographe reste en Portfolio. | Nouvelle tâche **F32** (Track B). Corriger le CdC §8.1 |
| **D-D** | **On applique la formule du CdC : diviser par 100, un module non joué compte pour 0 via une couverture à 0 %** — et on s'appuie sur les seuils 60 %/70 % existants pour masquer un score bâti sur trop peu de données. Les 5 mini-jeux **seront créés**, donc la renormalisation n'a plus de raison d'être. | **F07/F08** débloqués. **F03, F13, F15 deviennent des prérequis**, pas des options |
| **D-E** | **Niveaux 2 (entreprise) et 3 (offre) reportés tous les deux**, et **écrits comme tels**. | §5 et §9 restent en l'état. À consigner dans `PLAN_FITSCORE_V3.md` (le niveau 3 n'y figure nulle part) |
| **D-F** | **Grille portfolio reportée.** Au lancement, les métiers créatifs sont notés **sur les soft skills seuls**, avec un **message explicite** au recruteur. | **F18 débloqué et devient obligatoire** — c'est lui, le « message explicite ». Le mode `MIXTE` reste non implémenté |

### 📌 D-E en détail — l'héritage à 3 niveaux, dont **1 seul sur 3 existe**

Le CdC (§5) prévoit que la pondération d'une offre se construise en **trois couches
successives**, chacune pouvant ajuster la précédente :

```
1. job_role_profile (métier × niveau)   →  poids par défaut, communs à tout Zennyt
        ↓ hérite, puis peut surcharger
2. company_profile (société)            →  ajustements propres à la culture d'une entreprise
        ↓ hérite, puis peut surcharger
3. offer (offre individuelle)           →  ajustements ponctuels saisis par le recruteur
```

| Niveau | À quoi ça sert | État |
|---|---|---|
| **1. Métier × niveau** | « Un Développeur Senior, c'est 65 % de hard skills. » Valable pour toute la plateforme. | ✅ **existe**, 24 lignes seedées, exactes |
| **2. Société** | « Chez nous, la culture est collaborative → +5 % sur la Régulation émotionnelle, sur **toutes** nos offres. » Évite que chaque recruteur d'une même entreprise ressaisisse le même réglage à chaque publication. | ❌ **n'existe pas** — aucune table, aucun champ, aucune route |
| **3. Offre** | « Ce poste précis exige une expertise réglementaire renforcée → j'ajuste juste pour cette offre. » | ❌ **n'existe pas** |

**Ce que ça veut dire concrètement aujourd'hui :** deux entreprises très différentes — une
start-up et une banque — qui publient la même offre « Développeur Senior » obtiennent
exactement la même pondération. Aucune des deux ne peut exprimer sa spécificité.

**Pourquoi on reporte quand même :**
- Le niveau 2 avait déjà été différé consciemment (décision D6 du plan initial).
- Le niveau 3, lui, **n'avait jamais été décidé** — il a simplement été oublié. C'est pour ça
  que P0.7 demande de l'écrire noir sur blanc.
- Ce n'est pas nécessaire pour lancer : le niveau 1 seul produit déjà un score cohérent.
- C'est plusieurs semaines de travail, et il y a un point non tranché par le CdC lui-même :
  quand une société ajoute « +5 % sur la Régulation émotionnelle », **d'où viennent ces 5 points ?**
  Les deux totaux doivent rester à 100 % (contrainte vérifiée en base). Le CdC ne donne aucune
  règle de renormalisation.

**Attention technique le jour où on le fera** — ce n'est pas qu'ajouter des tables.
`JobRoleProfileResolver.resolveAll()` charge aujourd'hui les 24 lignes une fois pour toutes et
les garde en mémoire, en supposant qu'il n'existe que 24 pondérations possibles. Avec des
réglages par société ou par offre, cette optimisation tombe — et c'est elle qui rend le
balayage de rattrapage viable (2 requêtes quel que soit le nombre d'offres). À chiffrer avant
de planifier.

### ⚠️ D-A — un point à vérifier avant de lancer F31

Le renommage de V29 ne venait pas de nulle part : son commentaire dit qu'il provient du
**« contrat squad web, §3 »**. Revenir à `JUNIOR/SENIOR/LEAD/MANAGER` est donc un **changement
cassant pour l'équipe web**, pas seulement pour nous : la valeur `experienceLevel` change dans
toutes les réponses et requêtes de l'API.

**Action avant de coder F31** : prévenir la squad web et convenir d'une date de bascule
commune. Techniquement le changement est simple ; c'est la coordination qui coûte.
Si la squad web refuse, l'alternative est de garder `MID`/`EXECUTIVE` dans l'API mais
d'**échanger les pondérations** des deux bandes du milieu sur les 24 lignes — même résultat de
scoring, libellés incohérents. À arbitrer avec eux, pas entre vous.

### Ce que D-D implique concrètement

C'est la décision qui change le plus de comportement. Trois conséquences à assumer :

1. **Tant que les 5 jeux n'existent pas, beaucoup de candidats passeront sous le seuil de
   couverture** et n'auront pas de score affiché. C'est voulu : mieux vaut pas de score qu'un
   score faux. Mesuré aujourd'hui : deux infirmières aux régulations émotionnelles opposées
   (95 vs 20) obtiennent **le même 61**.
2. **F03 (créer le module Régulation émotionnelle) devient urgent**, plus « souhaitable ». Sans
   lui, tous les profils RELATIONNEL — infirmier, commercial, conseiller de vente, support
   client — perdent 45 % de leur pondération.
3. **Le vecteur de triche disparaît** : sauter un mini-jeu raté rapportait +11 points, ça
   tombera à 0.

---

## 3. Index des constats par sévérité

Sévérité = impact sur la justesse d'un score affiché à un recruteur, pas difficulté technique.

### 🔴 Critique — fausse un score ou casse une fonctionnalité

| ID | Constat | § | Fichier principal | Track | Taille |
|---|---|---|---|---|---|
| **F01** | Une clé de module inconnue devient **tout** le score soft, sans pondération | §1 | `DeterministicFitScoreCalculator.java:92-97` | A | S |
| **F02** | Aucune donnée soft ⇒ `softSkillScore = 0` persisté comme une mesure | §1 | `DeterministicFitScoreCalculator.java:95` | A | S |
| ~~**F03**~~ | ~~`EMOTIONAL_REGULATION` inatteignable~~ → ✅ **FAITE**, livrée par Games, présente sur `main` depuis `608187e` | §2 | — | — | ✅ |
| **F04** | Seuil `partialData` piloté par « le candidat a passé le test » au lieu de « l'offre a un QCM » | §1 §2 | `FitScore.java:87` | P0→A | S |
| **F05** | Niveaux d'alerte faux sur **12 lignes / 24** ; tous les `EXECUTIVE` en INFO ; TECHNIQUE/JUNIOR en MODERATE (bord `< 35`) | §6 | `JobRoleProfile.java:44-50` | B | M |
| **F06** | Le client mobile n'envoie pas `jobPositionId` ⇒ **création d'offre impossible** | §9 | `mobile/…/jobs_repository_impl.dart:36` | B | S |
| **F31** | **[D-A]** Rétablir l'échelle CdC `JUNIOR/SENIOR/LEAD/MANAGER` (annule V29). Changement cassant d'API — coordonner avec la squad web | §3 | `ExperienceLevel.java` + migration + contrat + mobile | **P0** | M |

### 🟠 Élevé — intégrité des données ou du classement

| ID | Constat | § | Fichier principal | Track | Taille |
|---|---|---|---|---|---|
| **F07** | Renormalisation : écart mesuré −11 / +23 pts ; sur RELATIONNEL elle **efface** la dimension discriminante | §1 | `DeterministicFitScoreCalculator.java:82-99` | A | M |
| **F08** | Sauter un mini-jeu raté rapporte **+11 pts** (vecteur de triche) | §1 | idem F07 | A | — |
| **F32** | **[D-C]** Déplacer `type_evaluation_hard` de `job_role_profiles` vers `job_positions` (mode par métier) | §4 §8 | `JobPosition.java` + migration + contrat | B | M |
| **F09** | Les descriptions du classifieur (RIASEC pur) **contredisent** la matrice seedée : « développement logiciel » sous ANALYTIQUE alors que les 9 métiers IT sont TECHNIQUE ; « vente » sous MANAGERIAL alors que Commercial est RELATIONNEL | §4 | `JobProfileTypeClassifier.java:25-42` | B | S |
| **F10** | La carte candidat affiche **3 modules identiques** dérivés d'une seule valeur agrégée — donnée fabriquée | §7 | `mobile/…/fits_repository_impl.dart:183-185` | B | M |
| **F11** | Pas d'`updated_at` ni de versioning sur `job_role_profiles` — engagement pris dans `PLAN_FITSCORE_V3.md`, non tenu | §10 | `V42__job_role_profiles.sql` | P0 | S |
| **F12** | Aucun recalcul quand la pondération change ; `recomputeAllActive()` plafonné à **20 offres** | §8 | `RecomputeFitScoresUseCase.java:191` | A | M |

### 🟡 Moyen — écart au CdC, pas de score faux

| ID | Constat | § | Fichier principal | Track | Taille |
|---|---|---|---|---|---|
| **F13** | Aucune source de couverture : `DEFAULT_COVERAGE_RATIO = 100` en dur ⇒ mécanisme 1 inerte | §2 | `RecomputeFitScoresUseCase.java:40` | A | M |
| **F14** | Games n'émet qu'à **100 % de complétion** : une session partielle ne produit rien du tout | §2 | `games/…/GameSession.java:84` | A | M |
| **F15** | Pas de colonne couverture par module ; `coverage_ratio` est global sur `fit_scores` | §2 §8 | `soft_skills_projection` | A | M |
| **F16** | Les 3 signaux de confiance (`calibrated`, `partialData`, `hardSkillsAlert`) sont calculés, contractualisés, et **ignorés par tous les clients** | §2 §6 §10 | `mobile/**` | B | M |
| **F17** | Les 3 contextes d'affichage §7 absents ; aucun branchement sur la présence d'un QCM | §7 | `mobile/…/fit_card_data.dart` | B | L |
| **F18** | Phrase « métier créatif / consultez le portfolio » absente du résumé IA — **obligatoire** depuis D-F | §7 | `GetCandidateResumeUseCase.java` | B | M |
| **F19** | Aucun texte d'alerte ; `INFO` ne distingue pas « ajoutez un QCM » de « métier évalué par portfolio » | §6 | `HardSkillsAlertLevel.java` | B | S |
| **F20** | N+1 : `toSummaries` fait 3 requêtes par offre (~60 sur une page de 20) alors que `resolveAll` / `findByIds` existent | §6 | `JobOfferController.java:271` | B | S |
| **F21** | Arrondi intermédiaire : `Score_Soft` arrondi avant le blend ⇒ jusqu'à +0,67 d'écart | §1 | `DeterministicFitScoreCalculator.java:60-69` | A | S |

### 🟢 Faible — nettoyage, cohérence, dette

| ID | Constat | § | Fichier | Track | Taille |
|---|---|---|---|---|---|
| **F22** | `jobDescription` / `companyDescription` morts dans `FitScoreInputs` (coûtent une requête, invitent à violer §2) | §5 | `FitScoreCalculatorPort.java` | A | S |
| **F23** | `assessmentId` figé à `null` à la création ⇒ branche de validation d'appartenance **inatteignable** | §9 | `JobOfferController.java:81` | B | S |
| **F24** | Mobile envoie `assessmentId` au POST — silencieusement ignoré | §9 | `mobile/…/jobs_repository_impl.dart` | B | S |
| **F25** | `uq_job_positions_name_sector` : `NULL` distincts en Postgres ⇒ les 9 métiers transverses ne sont pas protégés des doublons | §3 | `V25__job_positions_table.sql` | B | S |
| **F26** | Fichier mort `FitScoreEntity.java.tmp.30472.…` dans les sources (un `git add .` committerait une `@Entity` dupliquée) | §8 | `infrastructure/persistence/` | P0 | XS |
| ~~**F27**~~ | ~~Javadoc cite une constante inexistante~~ → ❌ **pas un bug** sur `main` : `DECISION_CORE` existe bien | §2 | — | — | ✅ |
| **F28** | Aucun test n'assure la forme de la courbe (pic au niveau du hard max, décroissance, 24 lignes présentes) | §4 | `JobRoleProfileTest.java` | B | S |
| **F29** | « Le mode soft-only est un mode standard, pas dégradé » (§10 #8) : aucun texte nulle part | §10 | contrat + `mobile/**` | B | S |
| **F30** | `GET /job-role-profiles` construit pour le préremplissage des curseurs — **zéro consommateur** | §9 | `mobile/**` | B | M |

**Total : 30 constats.** 6 critiques, 6 élevés, 9 moyens, 9 faibles.

---

## 4. Phase 0 — ✅ TERMINÉE le 2026-08-04

> **Toute la Phase 0 est livrée et poussée.** Les deux tracks peuvent partir
> directement de `main` — plus rien à faire ensemble avant de brancher.
>
> | Tâche | État | Livré |
> |---|---|---|
> | **P0.1** Plages de migration | ✅ | Phase 0 = V52-V53 · Track A = **V54-V58** (livré) · Track B = **V59-V63** |
> | **P0.2** F11 — `updated_at` sur `job_role_profiles` | ✅ | migration `V52`, champ ajouté au record, à l'entity et à l'adapter |
> | **P0.3** F04 — seuil `partialData` | ✅ | `partialData(boolean offerHasAssessment)` ; les 4 appelants passent désormais `offer.assessmentId() != null` |
> | **P0.4** Fichier `.tmp` mort | ✅ | disparu à la fusion |
> | **P0.5** Harnais en test JUnit | ✅ | `FitScoreBaselineTest` — 10 tests, dont 3 qui **documentent** les bugs F01/F02/F08 et devront être inversés à leur correction |
> | **P0.6** F31 — échelle `JUNIOR/SENIOR/LEAD/MANAGER` | ✅ | migration `V53`, enum, `JobPosition`, contrat OpenAPI, mobile, tests |
> | **P0.7** Consigner D-E | ✅ | `PLAN_FITSCORE_V3.md` — le niveau 3 y figure enfin, avec la question de renormalisation non tranchée |
>
> **Vérifié** : 324 tests au vert, base recréée à zéro, 53 migrations appliquées,
> application démarrée, API à 200.
>
> ⚠️ **F31 est un changement cassant d'API non encore annoncé.** `experienceLevel`
> change de valeur (`MID`→`SENIOR`, `SENIOR`→`LEAD`, `EXECUTIVE`→`MANAGER`).
> **La squad web doit être prévenue avant toute mise en production.**

<details>
<summary>Détail des tâches (pour référence)</summary>

## 4bis. Phase 0 — le détail de ce qui a été fait

Une seule séance, un seul commit, en pair. Tout ce qui touche les deux tracks est ici, pour que
A et B soient ensuite **totalement disjoints**.

- [ ] **P0.1 — Allouer les numéros de migration.** Réservez les plages maintenant, même si
      certaines restent inutilisées :
      | Plage | Propriétaire |
      |---|---|
      | `V49` → `V51` | jeux (renumérotation, déjà livré) |
      | `V52` → `V53` | Phase 0 (déjà livré) |
      | `V54` → `V58` | **Track A** — *livré, ne pas réutiliser* |
      | `V59` → `V63` | **Track B** |
      Une migration hors de votre plage = à négocier. C'est la source #1 de conflit Flyway.

- [ ] **P0.2 — F11 : `updated_at` sur `job_role_profiles`.** `V49` (A l'écrit, B relit) :
      ajouter `updated_at TIMESTAMPTZ NOT NULL DEFAULT now()`, l'ajouter au record
      `JobRoleProfile`, à `JobRoleProfileEntity` et à l'adapter.
      *C'est le prérequis de F12* — sans horodatage sur le référentiel, aucun balayage de
      péremption ne peut détecter un changement de pondération.

- [ ] **P0.3 — F04 : figer la signature.** Le correctif exige de savoir si **l'offre** porte un
      QCM, information que `FitScore` n'a pas. Décidez ensemble entre :
      - (a) ajouter `boolean offerHasAssessment` à `FitScore.calculated(...)` + colonne
        `offer_has_assessment` sur `fit_scores` (migration A) ;
      - (b) passer `JobOffer.assessmentId() != null` à `partialData(boolean)` au moment de
        l'appel, sans persistance.
      **Recommandé : (b)** — pas de migration, pas de donnée dénormalisée à maintenir
      cohérente. Une fois la signature actée, F04 part entièrement en Track A.

- [ ] **P0.4 — F26 : supprimer le fichier mort.**
      `git rm --cached` inutile (non suivi) — simple `rm` de
      `backend/src/main/java/com/zennyt/recruitment/infrastructure/persistence/FitScoreEntity.java.tmp.30472.8c41d02a216c`.

- [ ] **P0.5 — Committer le harnais de vérification** (voir §7) comme test réel, dans
      `backend/src/test/java/com/zennyt/recruitment/infrastructure/ai/`. Les deux tracks s'en
      serviront pour prouver la non-régression.

- [ ] **P0.6 — F31 [D-A] : rétablir l'échelle `JUNIOR/SENIOR/LEAD/MANAGER`.**
      **Pourquoi en Phase 0** : c'est un renommage mécanique, sans jugement, mais qui touche
      l'enum, une migration, les 24 lignes seedées, le contrat, le mobile et les tests **en même
      temps**. Le faire avant de brancher supprime le plus gros risque de conflit du projet.
      Fait à deux, en une passe :
      1. **prévenir la squad web** et convenir de la date de bascule (voir l'alerte §2) ;
      2. `ExperienceLevel.java` : `JUNIOR, SENIOR, LEAD, MANAGER` ;
      3. migration `V51` — inverse de V29, **ordre important** pour ne pas écraser une valeur
         par l'autre : `EXECUTIVE→MANAGER`, puis `SENIOR→LEAD`, puis `MID→SENIOR` ;
         renommer aussi les colonnes de libellés de `job_positions`
         (`mid_label→senior_label`, `senior_label→lead_label`, `executive_label→manager_label`) ;
      4. mettre à jour les valeurs `level` des 24 lignes de `job_role_profiles` ;
      5. contrat + mobile + collection Bruno + tous les tests qui citent `MID`/`EXECUTIVE`.
      *Vérification* : après cette étape, `TECHNIQUE/SENIOR` doit porter **hard = 65 %**
      (aujourd'hui c'est `TECHNIQUE/MID`). Le harnais §7 le montre directement.

- [ ] **P0.7 — Consigner D-E par écrit.** Ajouter dans `PLAN_FITSCORE_V3.md`, à côté de D6, une
      ligne explicite pour le **niveau 3 (overrides d'offre)** : reporté, décidé le 2026-08-03.
      Aujourd'hui il n'est mentionné nulle part — il n'a jamais été différé, il a été oublié.
      Une ligne suffit, mais elle évite qu'on redécouvre le trou dans six mois.

- [ ] **P0.8 — Créer les branches** depuis le commit Phase 0 :
      `fix/fitscore-track-a-moteur` et `fix/fitscore-track-b-client`.

---

</details>

## 5. Track A — moteur de calcul & chaîne de mesure

**Périmètre** : la formule, les modules, la couverture, le contexte Games, le recalcul.
**Fichiers possédés** (personne d'autre n'y touche) :

```
backend/src/main/java/com/zennyt/recruitment/
    infrastructure/ai/DeterministicFitScoreCalculator.java
    application/port/FitScoreCalculatorPort.java
    application/usecase/RecomputeFitScoresUseCase.java
    application/GameSoftSkillsListener.java
    application/FitScoreBackfillWorker.java
    domain/vo/SoftSkillModule.java
    domain/vo/FitScorePolicy.java
    domain/model/FitScore.java
    domain/model/SoftSkillsProjection.java
    infrastructure/persistence/FitScore*.java
    infrastructure/persistence/SoftSkillsProjection*.java
backend/src/main/java/com/zennyt/games/**
backend/src/main/resources/db/migration/V54..V58   (livré)
backend/src/test/java/com/zennyt/recruitment/infrastructure/ai/**
backend/src/test/java/com/zennyt/recruitment/application/RecomputeFitScores*
backend/src/test/java/com/zennyt/games/**
```

### A1 — Corrections immédiates, sans décision préalable

- [ ] **F01 🔴 — Le repli avale les clés inconnues.**
      `DeterministicFitScoreCalculator.java:92-97`. Le garde de boucle exclut les clés
      inconnues (`if (module == null) continue`), puis le repli `weightTotal == 0` moyenne
      **`softSkills.values()`** — la map complète, clés rejetées incluses.
      Prouvé : `{FUTUR_JEU: 90}` → `soft = 90` ; `{FUTUR_JEU: 10}` → `soft = 10`.
      → Le repli ne doit moyenner **que les entrées dont la clé résout** via
      `SoftSkillModule.fromGamesModule`.
      *Test* : `{JEU_INCONNU: 90}` ne doit pas produire 90.

- [ ] **F02 🔴 — Absence de donnée ≠ score de 0.**
      Même méthode, `average().orElse(0)`. Une map vide donne `softSkillScore = 0`, persisté et
      servi comme une mesure. Incohérent avec la philosophie de renormalisation (sauter
      *certains* modules les exclut ; sauter *tous* les modules donne 0).
      → Renvoyer `null` depuis `calculate()` quand aucun module reconnu n'existe (même
      sémantique que « profil non résolu » : rien n'est écrit).
      *Test* : map vide ⇒ `calculate(...) == null`.

- [ ] **F21 🟡 — Arrondi intermédiaire.** Ligne 60-69 : `Score_Soft` est arrondi à l'entier
      avant le blend. Mesuré : 77,50 → 78 → fit 79 au lieu de 78,33.
      → Garder le soft en `double` jusqu'au blend final ; n'arrondir que le résultat.
      *Attention* : ça déplace des scores existants de ±1 — à faire avec F12 (recalcul global).

- [ ] **F22 🟢 — Champs morts.** Retirer `jobDescription` et `companyDescription` de
      `FitScoreInputs`, et la lecture `actors.findById(...).companyInfo()` de
      `RecomputeFitScoresUseCase:79` (une requête par paire, jamais utilisée). CdC §2 interdit
      explicitement que le texte libre pilote la pondération — les garder invite la violation.

- [ ] **F27 🟢 — Javadoc fausse.** `SoftSkillModule.java:13` cite `MiniGame.DECISION_CORE` :
      la constante n'existe pas (`MiniGame` en a 5, pas celle-là). La conclusion tient mais par
      un autre mécanisme — `expectedMiniGames()` renvoie vide pour `GameType.DECISION`, donc une
      session ne peut jamais se terminer ni émettre. Corriger le texte.

### A2 — La chaîne de mesure Games

> **Ordre imposé par D-D.** La décision « module non joué = 0 via une couverture à 0 % » ne peut
> pas s'implémenter avant que la couverture existe réellement. L'ordre est donc :
> **F03 → F13/F15 → F14 → F07/F08**. Ne commencez pas par F07 : sans couverture, mettre les
> modules manquants à 0 punirait tous les candidats pour des jeux qu'on n'a pas encore livrés.

- [ ] **F03 🔴 — Ajouter `EMOTIONAL_REGULATION` à `GameType`.**
      C'est **la plus grosse source d'erreur de score du système**. Le mapping côté recruitment
      existe déjà (`SoftSkillModule.fromGamesModule`, commit `7caec44`) mais aucun producteur
      n'émet cette chaîne : `GameSoftSkillsListener:38` fait `event.gameType().name()`, et
      `GameType` ne contient que `PLANIFIK, MOVE_FAST, MEMORY_QUEST, DECISION`.
      Mesuré (§7) : sur un profil RELATIONNEL, où la régulation pèse **45 %**, deux candidats
      opposés (régulation 95 vs 20) obtiennent **tous les deux 61**. Le système ne peut pas les
      distinguer sur la dimension qui *est* le métier.
      → Ajouter la valeur d'enum + le(s) `MiniGame` correspondant(s) + le barème.
      → Corriger le javadoc de `GameType` (« n'a pas encore de GameType »).

- [ ] **F13 + F15 🟡 — Couverture réelle par module.** *(prérequis de F07, décision D-D)*
      `V54` (livré) : `ALTER TABLE recruitment.soft_skills_projection ADD COLUMN coverage_ratio INT NOT NULL DEFAULT 100;`
      Le signal existe déjà et est **jeté** : `GameResultRecordedEvent` porte `compositeRaw` et
      `compositeMax`, et `GameSession.expectedMiniGames()` donne le dénominateur.
      `GameSoftSkillsListener` ne garde que `normalizedScore` et `gameType`.
      → Propager la couverture jusqu'à `FitScoreInputs`, et appliquer le mécanisme 1
      **par module avant agrégation** (CdC §3.3), pas globalement après.
      → Supprimer `DEFAULT_COVERAGE_RATIO`.

- [ ] **F14 🟡 — Émettre sur session partielle.** *(D-D)*
      `GameSession.java:84` : `if (attempts.size() == expectedMiniGames().size()) complete(...)`.
      Une session partielle n'émet **rien** — donc pas de projection, pas de score. Le CdC
      prévoit l'inverse : la donnée partielle arrive avec une décote, elle ne disparaît pas.
      → Émettre à chaque mini-jeu avec le ratio de complétion (`attempts.size() /
      expectedMiniGames().size()`), ou émettre à l'abandon de session.

### A3 — Appliquer D-D, puis le recalibrage

- [ ] **F07 + F08 🟠 — Supprimer la renormalisation.** *(D-D — à faire **après** F03/F13/F15)*
      `weightedSoftScore` divise par `weightTotal` (somme des poids des modules *joués*) au lieu
      de 100. Impact mesuré, candidat identique, niveau MID, sans QCM :
      | Profil | 5 modules | 3 modules (réel) | Écart |
      |---|---|---|---|
      | RELATIONNEL (régul. 95) | 72 | 61 | **−11** |
      | RELATIONNEL (régul. 20) | 38 | 61 | **+23** |
      | MANAGERIAL (régul. 20) | 45 | 62 | +17 |
      | ANALYTIQUE (régul. 20) | 50 | 60 | +10 |
      Et sauter un mini-jeu raté rapporte **+11 pts** (Planifik à 30 : joué 67, sauté 78).
      **Ce qu'il faut faire, décision D-D :**
      1. diviser par **100**, plus par `weightTotal` ;
      2. un module jamais joué entre dans la somme avec une **couverture à 0 %**, donc une
         contribution nulle — il n'est plus exclu du dénominateur ;
      3. laisser les seuils 60 %/70 % existants (`FitScore.partialData`) masquer les scores
         bâtis sur trop peu de données, au lieu d'afficher un chiffre trompeur.
      **Ne livrez pas ceci avant F03.** Sans le module Régulation émotionnelle, le passer à 0
      ferait chuter tous les profils RELATIONNEL de ~45 % de leur pondération d'un coup.
      *Test* : le vecteur de triche doit disparaître — jouer un mini-jeu raté doit donner un
      score **supérieur ou égal** à ne pas le jouer, jamais inférieur.

- [ ] **F12 🟠 — Chemin de recalibrage.**
      Aucun déclencheur ne réagit à un changement de pondération, et `findStalePairs` ne compare
      que les timestamps côté candidat. Or **l'atelier RH — prérequis déclaré de la mise en
      production — ne produit que des pondérations nouvelles.** Le jour où elles arrivent,
      toutes les lignes `fit_scores` sont périmées et rien ne le détecte.
      `recomputeAllActive()` est plafonné à `MAX_BATCH_SIZE = 20` offres : ce n'est pas une
      issue de secours.
      → Étendre `findStalePairs` pour comparer `fit_scores.computed_at` à
      `job_role_profiles.updated_at` (P0.2), et laisser le balayage borné existant absorber le
      rattrapage. Pas de nouveau mécanisme.

---

## 6. Track B — référentiel, alertes, API & client

**Périmètre** : profils métier, alertes, surface HTTP, contrat, mobile.
**Fichiers possédés** (personne d'autre n'y touche) :

```
backend/src/main/java/com/zennyt/recruitment/
    domain/model/JobRoleProfile.java
    domain/model/JobPosition.java
    domain/vo/HardSkillsAlertLevel.java
    domain/vo/JobProfileType.java
    domain/vo/TypeEvaluationHard.java
    domain/vo/ExperienceLevel.java      (après P0.6 — plus personne n'y touche)
    application/JobProfileTypeClassifier.java
    application/JobRoleProfileResolver.java
    application/usecase/GetCandidateResumeUseCase.java
    application/usecase/CreateJobOfferUseCase.java
    api/**            (contrôleurs + DTO)
backend/src/main/resources/db/migration/V59..V63
backend/src/test/java/com/zennyt/recruitment/domain/**
backend/src/test/java/com/zennyt/recruitment/application/JobProfileTypeClassifierTest.java
contracts/recruitment.openapi.yaml          <-- B en est SEUL propriétaire
mobile/**                                    <-- B en est SEUL propriétaire
tooling/bruno/**
```

### B1 — Correctifs backend

- [ ] **F05 🔴 — Niveaux d'alerte.** *(D-B : on garde la logique du code, on corrige les bornes)*
      `JobRoleProfile.hardSkillsAlert()`. Résultat des 24 lignes seedées vs table §6 :
      **12 conformes sur 24**. Deux cas faux quelle que soit la lecture retenue :
      - **tous les `EXECUTIVE`** (5 profils non-artistiques) renvoient `INFO`/`NONE` là où §6
        dit explicitement « Alerte modérée » ;
      - **TECHNIQUE/JUNIOR** (`expectedHardWeight = 35`) tombe en `MODERATE` par le bord
        `< 35`, là où §6 dit « pas d'alerte ou alerte discrète » — les offres de dev junior,
        probablement le plus gros volume de la plateforme.
      Les autres écarts (RELATIONNEL / MANAGERIAL / CONVENTIONNEL en MID/SENIOR) sont
      défendables : le code est *plus juste* que le CdC. Dire à un recruteur qu'un Conseiller de
      vente Senior « repose normalement à ~50 % sur le hard skills » serait faux (25 % réel).
      **D-B a tranché : on garde la dérivation par le poids.** Donc :
      1. corriger la borne haute du bucket INFO pour que TECHNIQUE/JUNIOR (35) n'y échappe plus
         (`<= 35` au lieu de `< 35`, ou remonter la borne à 36) ;
      2. traiter le cas MANAGER : aujourd'hui les 5 profils non-artistiques renvoient
         `INFO`/`NONE` là où le CdC exige « modérée ». Comme la dérivation reste par le poids,
         il faut un plancher explicite pour le dernier niveau ;
      3. **mettre à jour le CdC §6** — sa table est non monotone (Junior ~30 % → aucune alerte,
         Manager ~25 % → alerte modérée) et ne peut pas être reproduite par une fonction de
         seuil. C'est le document qui doit s'aligner sur le code, pas l'inverse.
      *Test* : rejouer les 24 lignes seedées et figer le résultat attendu dans un test
      paramétré — c'est le seul moyen d'éviter que ça redérive.

- [ ] **F09 🟠 — Descriptions du classifieur contre matrice seedée.**
      `JobProfileTypeClassifier.DESCRIPTIONS` sont du **RIASEC canonique**, alors que les 6
      profils Zennyt sont une *adaptation* aux frontières différentes. Contradictions vérifiées :
      | Le classifieur dit | La matrice dit |
      |---|---|
      | ANALYTIQUE = « …**développement logiciel**, expertise technique poussée » | Développeur, DevOps, IA, Data Eng, Architecte… = **TECHNIQUE** (9 métiers) |
      | TECHNIQUE = « techniques et **manuels**, mécanique, production, terrain » | CdC §4.3 : TECHNIQUE = « construire, **développer**, réparer » |
      | MANAGERIAL = « **vente**, entrepreneuriat, développement commercial » | Commercial / BD, Conseiller de vente = **RELATIONNEL** |
      → Réécrire les 6 descriptions depuis la table CdC §4.3 **et** les listes de métiers
      réellement seedées dans `V26`.
      → Ajouter un test : une dizaine de métiers seedés doivent se reclasser sur leur propre
      profil. `JobProfileTypeClassifierTest` n'utilise aujourd'hui que des vecteurs one-hot
      synthétiques — il valide l'argmax, jamais la sémantique.

- [ ] **F20 🟡 — N+1.** `JobOfferController.toSummaries()` appelle par offre
      `actors.findById(...)` (1 req) et `hardSkillsAlert(offer)` → `resolve(offer)` (2 req) =
      **3 requêtes/offre**, ~60 sur une page de 20. Les primitives de lot existent et sont déjà
      utilisées deux lignes plus haut : `resolveAll(offers)` et `actors.findByIds(...)`.

- [ ] **F23 🟢 — `assessmentId` à la création.** `JobOfferController:81` passe `null` en dur ;
      `CreateJobOfferRequest` n'a pas le champ. Conséquence : la validation d'appartenance dans
      `CreateJobOfferUseCase` (lignes 47-54) est **inatteignable**, et le CdC §1/§9 présente
      pourtant le QCM comme un choix *au moment de la publication*.
      → Soit ajouter le champ au DTO + contrat, soit supprimer la branche morte. Ne pas laisser
      un code qui suggère une capacité non câblée.

- [ ] **F25 🟢 — Contrainte d'unicité.** `uq_job_positions_name_sector UNIQUE (name, sector)` :
      Postgres considère les `NULL` comme distincts, donc les **9 métiers transverses**
      (`sector = NULL`) ne sont pas protégés des doublons via `ProposeJobPositionUseCase`.
      → `V59` : index unique partiel `ON job_positions (name) WHERE sector IS NULL`
      (ou `NULLS NOT DISTINCT` si PG ≥ 15).

- [ ] **F28 🟢 — Test d'invariant sur la courbe.** `JobRoleProfileTest` ne couvre que les deux
      sommes et le bucketing d'alerte. Rien n'assure que la courbe garde sa forme. Les 24
      valeurs ne vivent que dans une migration : un chiffre transposé dans un futur `V…` — ou
      dans la recalibration RH à venir — passerait silencieusement.
      → Test paramétré sur `roleProfiles.findAll()` : 24 lignes présentes, pic au niveau du hard
      maximal, décroissance jusqu'au dernier niveau, `JUNIOR < ` le pic.
      *~15 lignes, le meilleur rapport valeur/effort de tout l'audit.*

- [x] **F32 ✅ — [D-C] Mode d'évaluation par métier.** *(fait le 2026-08-10, V60)*
      Aujourd'hui `type_evaluation_hard` est sur `job_role_profiles` (profil × niveau), donc
      **tous** les métiers ARTISTIQUE partagent le même mode. D-C a tranché : le mode appartient
      au métier.
      → `V60` : ajouter `type_evaluation_hard` sur `job_positions`, reprendre la valeur du
      profil pour les 142 lignes existantes, puis retirer la colonne de `job_role_profiles`.
      → Adapter `JobPosition`, son entity/adapter, `JobRoleProfileResolver`, le contrat.
      → Seeder les métiers hybrides en `MIXTE` (UX/UI Designer, Motion designer) et les autres
      créatifs en `PORTFOLIO`, conformément au CdC §4.3.
      → **Corriger le CdC §8.1**, qui place encore ce champ sur `job_role_profile`.
      *Note* : le mode `MIXTE` reste **non implémenté** dans le calcul (ni `poids_qcm` ni
      `poids_portfolio` n'existent, et le calculateur ne lit jamais ce champ). F32 rend le
      réglage *exprimable* ; le rendre *effectif* dépend de D-F, reportée.

- [ ] **F18 🟠 — Phrase Artistique dans le résumé IA.** *(D-F : c'est LE « message explicite »)*
      §7 exige, pour un `job_role_profile` ARTISTIQUE en Portfolio seul, une phrase explicite :
      « …le Fit Score reflète uniquement les soft skills — la qualité technique et créative
      n'est pas mesurée automatiquement… examinez le portfolio. »
      `GetCandidateResumeUseCase` et `GenerateSoftSkillsSummaryUseCase` ne contiennent aucune
      référence à `ARTISTIQUE` ni à portfolio.
      **Bonne nouvelle** : `Profile.portfolioUrl` existe déjà côté Identity — la destination
      vers laquelle pointer est stockée. Il ne manque que le test sur `typeEvaluationHard` et le
      paragraphe conditionnel.
      **D-F a reporté la grille portfolio.** Conséquence directe : au lancement, les métiers
      créatifs sont notés **sur les soft skills seuls**. F18 n'est donc plus une amélioration,
      c'est la **contrepartie obligatoire** de ce report — c'est la phrase qui prévient le
      recruteur que rien du métier n'a été mesuré.
      *Sans elle, le score d'un designer se lit comme une évaluation complète alors qu'il ne
      mesure rien de son métier. Si une seule chose du track B devait être livrée, ce serait
      celle-là.*

### B2 — Client mobile & contrat

- [x] **F06 ✅ — Création d'offre cassée.** *(fait le 2026-08-10 — sélecteur de métier livré)* `mobile/…/jobs_repository_impl.dart:36` poste 21
      champs, **sans `jobPositionId`**, obligatoire côté serveur depuis la suppression du repli
      IA. Chaque appel échoue.
      *Contexte* : `mobile/lib/features/jobs/` est **non suivi par git** — c'est le portage en
      cours, pas du code livré. À attraper avant le commit. Le contrat backend est correct :
      `tooling/bruno/Demo/02a Create job offer (REC).bru` envoie bien le champ.
      → Ajouter `jobPositionId` au payload + un sélecteur de métier dans le formulaire.

- [ ] **F24 🟢 — `assessmentId` envoyé et jeté.** Même payload : le mobile envoie
      `assessmentId`, que `CreateJobOfferRequest` n'a pas → silencieusement supprimé par Jackson.
      À traiter avec F23 (le client est codé selon le CdC, c'est le serveur qui ne suit pas).

- [ ] **F10 🟠 — Trois lignes identiques fabriquées.**
      `fits_repository_impl.dart:183-185` :
      ```dart
      decisionMaking:       _qualitative(softSkills),
      cognitiveFlexibility: _qualitative(softSkills),
      emotionalRegulation:  _qualitative(softSkills),
      ```
      Une seule valeur agrégée, rendue trois fois sous trois noms de module. §7 interdit
      explicitement le « doublon d'une valeur identique » — ici c'est pire qu'un doublon : ça
      **affirme au recruteur une granularité par module qui n'existe pas**, sur des dimensions
      dont deux ne sont même pas mesurables.
      C'est le seul constat de l'audit qui n'omet pas une information mais en **invente** une.
      → Supprimer les 3 champs, ou consommer de vrais scores par module quand l'API les exposera.
      `hardSkills: const {}` (ligne 186) rend aussi une section « Hard Skills » toujours vide.

- [ ] **F16 🟠 — Consommer les 3 signaux de confiance.** Le backend calcule, contractualise et
      transmet trois avertissements ; **aucun client n'en lit un seul** :
      | Signal | Calculé | Au contrat | Consommé |
      |---|---|---|---|
      | `calibrated` (pondération non validée RH) | ✅ | ✅ | ❌ |
      | `partialData` (couverture sous le seuil) | ✅ | ✅ | ❌ |
      | `hardSkillsAlert` (pas de QCM sur un poste hard) | ✅ | ✅ | ❌ |
      Un recruteur voit un pourcentage nu, sans aucune des trois réserves conçues autour de lui.
      *Meilleur rapport intégrité/effort du track B.*

- [ ] **F17 🟡 — Les 3 contextes d'affichage §7.**
      | Contexte | Attendu | Aujourd'hui |
      |---|---|---|
      | Page de matching (avant QCM) | une seule étiquette Fit Score % | le candidat ne voit **aucun** Fit Score sur une offre (`JobOffer` mobile n'a pas le champ ; `fromJobOffer` met `badgeText: null`) |
      | Liste candidats, **sans** QCM | Fit Score % + « basé sur les soft skills » | mention absente |
      | Liste candidats, **avec** QCM | Fit Score % + sous-ligne `Soft % · hard %` | pas de sous-ligne |
      Point décisif : **le client ne branche jamais sur la présence d'un QCM**. Un seul rendu
      sert les deux cas.
      À noter : le backend envoie déjà `fitScore`, `goodFit`, `softSkillScore`, `hardSkillScore`,
      `partialData` sur ce même payload — le mobile parse ~20 champs et saute ceux-là.

- [ ] **F19 🟡 — Message d'alerte.** *(D-B)* Seul l'enum à 4 valeurs traverse le réseau. Or §6
      insiste : le cas Artistique « n'est pas une anomalie à signaler comme un oubli ». Mais
      `ARTISTIQUE/MID → INFO` et `MANAGERIAL/JUNIOR → INFO` sont le **même jeton** : un client
      ne peut pas distinguer « pensez à ajouter un QCM » de « métier évalué par portfolio, c'est
      normal ».
      → Ajouter une valeur dédiée (ex. `PORTFOLIO_BASED`) ou un champ message/raison.

- [ ] **F29 🟢 — « Soft-only = mode standard ».** §10 #8 demande de documenter explicitement,
      **dans l'interface recruteur**, que le mode soft seul est normal et non dégradé. Aucun
      texte nulle part. Aujourd'hui le seul signal reçu est `hardSkillsAlert`, dont tout le
      cadrage est « il manque quelque chose » : l'alarme est là, la réassurance non.

- [x] **F30 ✅ — Préremplissage des curseurs.** *(fait le 2026-08-10, lecture seule)* `GET /api/v1/job-role-profiles` existe, est au
      contrat, et son javadoc dit son usage — « pour pré-remplir les curseurs de pondération du
      formulaire de création d'offre ». Recherche `job-role-profiles` sur tout le dépôt
      (`.dart`, `.ts`, `.js`, `.bru`) : **un seul résultat, le contrat lui-même**.
      → Le consommer à la création d'offre (affichage lecture seule tant que D-E n'a pas
      tranché les overrides).
      **Livré.** Le formulaire affiche le partage soft/hard et les 5 poids de modules dès que
      le métier et le niveau sont choisis, plus la mention « pondération v1 non validée » quand
      `calibrated` est faux. En passant : le formulaire n'avait **aucun sélecteur de niveau**,
      toute offre partait en JUNIOR — or c'est le niveau qui décide du partage soft/hard (35 %
      de hard en Junior contre 65 % en Senior sur un profil Technique). Le sélecteur ajouté
      utilise les intitulés propres au métier (`levelLabels`) : « Chef de chantier » plutôt que
      « Manager ».

---

## 7. Vérification

### Le harnais

Les vraies classes du moteur ont été compilées (aucune dépendance Spring dans ce chemin) et les
exemples rejoués. Sources versionnées dans **`docs/fitscore-harness/`** :

```
FitScoreHarness.java   les 5 exemples du CdC + 6 cas synthétiques (Health, Finance,
                       Industry, Retail, Hotel, Media) sur les 6 profils.
                       Le référentiel V42 y est recopié à l'identique (méthode `p(...)`).
FitScoreProbe.java     courbe de niveau, coût des modules manquants, vecteur de triche,
                       arrondi intermédiaire, cas limites
Bug.java               isole F01 et F02
```

Compilation et exécution — aucun outil de build nécessaire, JDK 21, **commande vérifiée depuis
la racine du dépôt** :

```bash
javac -d /tmp/fs -encoding UTF-8 -sourcepath backend/src/main/java backend/src/main/java/com/zennyt/recruitment/infrastructure/ai/DeterministicFitScoreCalculator.java docs/fitscore-harness/*.java && java -cp /tmp/fs FitScoreHarness && java -cp /tmp/fs FitScoreProbe && java -cp /tmp/fs Bug
```

**P0.5 : transformez-le en test JUnit committé.** C'est votre filet de non-régression commun :
chaque track doit pouvoir prouver qu'il n'a pas déplacé les scores de l'autre.

### Résultats de référence — **rejoués sur `main` le 2026-08-04**, à conserver comme baseline

Colonne « Games réel » = les **4 modules** effectivement produits depuis la fusion (seul
`DECISION` manque). C'est la colonne qui compte : c'est ce que le système calcule vraiment.

| Exemple | Profil / niveau | Soft | Fit |
|---|---|---|---|
| Ex1 Développeur Senior | TECHNIQUE / MID, QCM 78 | 80 | **79** |
| Ex2 Commercial Junior | RELATIONNEL / JUNIOR, sans QCM | 76 | **76** |
| Ex3 Comptable Manager | CONVENTIONNEL / EXECUTIVE, QCM 61 | 75 | **72** |
| Ex4 UX/UI Designer Senior | ARTISTIQUE / MID, hard 79 | 79 | **79** |
| Ex5 Chef de projet Lead | MANAGERIAL / SENIOR, QCM 80 | 72 | **75** |
| S1 Infirmier Senior | RELATIONNEL / MID, QCM 64 | 75 | **72** |
| S2 Analyste financier Lead | ANALYTIQUE / SENIOR, QCM 55 | 73 | **64** |
| S3 Technicien maintenance Junior | TECHNIQUE / JUNIOR, sans QCM | 69 | **69** |
| S4 Gestionnaire de stock Senior | CONVENTIONNEL / MID, QCM 73 | 77 | **75** |
| S5 Directeur d'hôtel Manager | MANAGERIAL / EXECUTIVE, sans QCM | 80 | **80** |
| S6 Photographe Senior | ARTISTIQUE / SENIOR, portfolio seul | 78 | **78** |

> Les chiffres de l'audit initial (colonne « A spec-émulé » du harnais) sont plus bas de 3 à 8
> points : ils avaient été mesurés sans le module Régulation émotionnelle.

**Ce qui est confirmé correct** : la formule, la pondération par module, le blend hard/soft, la
courbe de niveau (pic sur le niveau au hard max pour un candidat fort au QCM, inversion pour un
candidat fort en soft), les bornes 0-100, le `null` sur profil non résolu.

**Ce qui est confirmé faux** : F01, F02, F07, F08, F21 — avec les chiffres ci-dessus.

---

## 8. Protocole de fusion

### Règles

1. **Un fichier n'a qu'un propriétaire.** Les listes §5 et §6 sont exhaustives et disjointes.
   Besoin d'un fichier de l'autre : demandez, ne le prenez pas.
2. **`contracts/recruitment.openapi.yaml` appartient à Track B seul.** Track A a besoin d'un
   changement de contrat (F13 expose la couverture ?) → ouvrir une issue, B l'applique.
3. **Migrations : restez dans votre plage** (P0.1). Track A a livré jusqu'à **V58**
   (incluse) ; Track B commence donc à **V59**. Tout ce qui précède est pris.
4. **Rebaser sur `main` tous les jours**, pas fusionner. Historique linéaire, conflits attrapés
   tôt.
5. **Un commit par `Fxx`.** Format : `fix(fitscore): F01 le repli avale les clés de module inconnues`.
   Pas de commits fourre-tout — la revue croisée devient impossible.

### Ordre d'intégration

```
Phase 0 (ensemble)  ──┬──> Track A ──┐
                      └──> Track B ──┴──> rebase B sur A ──> intégration
```

**Track A fusionne en premier.** Deux raisons : F03 (module régulation émotionnelle) déplace
tous les scores, et Track B doit afficher les scores corrigés, pas les anciens. Track B rebase
ensuite sur A et revalide son affichage contre la nouvelle baseline.

### Dépendances inter-tracks

| Dépendance | Sens | Comment gérer |
|---|---|---|
| F12 a besoin de `updated_at` (F11) | P0 → A | Fait en Phase 0 |
| F04 a besoin de la présence du QCM sur l'offre | P0 → A | Signature figée en P0.3 |
| Tout dépend du renommage des niveaux (F31) | P0 → A + B | Fait en Phase 0, avant de brancher |
| **F07 exige F03 + F13/F15 livrés avant** | interne A | Ordre imposé par D-D — voir §A2 |
| F16/F17 affichent des scores modifiés par F03/F07 | A → B | B rebase après la fusion de A |
| F19 dépend de la forme finale de l'alerte (F05) | interne B | Même track, pas de coordination |
| F23 et F24 sont les deux moitiés du même sujet | interne B | Même commit |
| F32 touche `JobRoleProfileResolver`, lu par A | B → A | A ne modifie pas ce fichier ; B prévient à la fusion |

### Revue croisée

Chacun relit les PR de l'autre. Points d'attention spécifiques :
- **A relit B** sur : F05 (les 24 lignes donnent-elles bien le niveau attendu ?), F28.
- **B relit A** sur : F07 (les scores de la baseline §7 ont-ils bougé comme prévu ?), F03.

---

## 9. Definition of Done

Un `Fxx` est terminé quand :

- [ ] le comportement est corrigé **et** couvert par un test qui échouait avant ;
- [ ] si le contrat change, `contracts/recruitment.openapi.yaml` est à jour (via B) ;
- [ ] si une route change, la collection Bruno `tooling/bruno/Demo/` est à jour ;
- [ ] le harnais §7 tourne et l'écart avec la baseline est **expliqué**, pas seulement constaté ;
- [ ] le commit référence l'identifiant.

### Ne pas oublier avant « production »

Le CdC pose deux prérequis explicites, aucun n'est tenu, et **rien dans le code ne les fait
respecter** :

1. **§10 #1 — validation RH du référentiel.** `calibrated = false` sur les 24 lignes et les 142
   métiers l'enregistre honnêtement… et personne ne le lit (F16). Un score issu de pondérations
   admises comme non calibrées s'affiche exactement comme un score validé.
2. **§10 #3 — grille d'évaluation portfolio** avant mise en production. N'existe pas ; le mode
   `MIXTE` est inimplémentable en l'état (ni `poids_qcm` ni `poids_portfolio`), et
   `typeEvaluationHard` n'est **jamais lu** par le calculateur.

Ces deux points ne se corrigent pas en code seul — mais F16 et F28 les rendent au moins visibles
et non régressables.

---

## Annexe — Répartition en un coup d'œil

| | Track A | Track B |
|---|---|---|
| **Thème** | moteur de calcul & mesure | référentiel, alertes, API, client |
| **Constats** | F01 F02 F03 F04 F07 F08 F12 F13 F14 F15 F21 F22 F27 | F05 F06 F09 F10 F16 F17 F18 F19 F20 F23 F24 F25 F28 F29 F30 **F32** |
| **Critiques** | F01 F02 F03 F04 | F05 F06 |
| **Langages** | Java (recruitment + games), SQL | Java (api + domain), SQL, Dart, YAML |
| **Migrations** | V54–V58 *(livré)* | **V59–V63** |
| **Ordre interne imposé** | F03 → F13/F15 → F14 → F07/F08 | F05 avant F19 ; F23+F24 ensemble |
| **Fusionne** | en premier | après rebase sur A |

**Phase 0 (ensemble)** : F11, F26, **F31** (renommage des niveaux), allocation des migrations
`V49`–`V51`, signature F04, consignation de D-E, harnais committé.

### Documents à corriger (hors code)

Trois décisions imposent de modifier les documents sources, sinon le prochain audit reproduira
les mêmes constats :

| Document | Correction | Décision |
|---|---|---|
| CdC **§6** (table d'alerte) | table non monotone, irréalisable par seuil — s'aligner sur la dérivation par le poids | D-B |
| CdC **§8.1** | `type_evaluation_hard` passe sur le métier, pas sur `job_role_profile` | D-C |
| `PLAN_FITSCORE_V3.md` | ajouter le report explicite du **niveau 3** (overrides d'offre), à côté de D6 | D-E |
