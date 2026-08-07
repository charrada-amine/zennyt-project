# Résumé IA — historique métier et double lecture : analyse et plan

**Module Recrutement — Zennyt**
Analyse du document « AI Resume — réajusté » (N. Labidi) et plan d'implémentation.

> Toutes les affirmations sur l'existant ci-dessous ont été vérifiées dans le code, pas
> supposées. Les références de fichiers sont exactes au 6 août 2026.

---

## 1. Ce que demande le document

| # | Proposition |
|---|---|
| P1 | Ne **pas** adapter le résumé IA à chaque offre — le Fit Score suffit à personnaliser |
| P2 | Le résumé hard skills s'appuie sur **tous les QCM déjà passés** sur le même domaine |
| P3 | Jamais de test → Fit Score soft seul + message explicite, section hard skills vide |
| P4 | Classement : les candidats ayant passé un test hard skills **d'abord** |
| P5 | **Deux versions** de chaque résumé : recruteur (factuelle) et candidat (diplomatique) |

---

## 2. Ce qui est déjà en place — à ne pas refaire

**P3 est déjà implémenté côté calcul.** [`DeterministicFitScoreCalculator:70`](backend/src/main/java/com/zennyt/recruitment/infrastructure/ai/DeterministicFitScoreCalculator.java) :
sans résultat de test, `hardWeight = 0` et `softWeight = 100`. Le Fit Score est déjà
purement soft. Il ne manque que le **libellé** : le texte actuel dit « Un test doit être
passé pour cette offre », pas « le score affiché est soft seul ».

**P1 est à moitié fait.** `SoftSkillsSummary` a déjà `candidate_id` en clé primaire — aucun
`jobOfferId`. Seul le résumé hard skills est par offre (contrainte
`uq_hard_skills_summary_candidate_offer`, V23).

**Le fan-out est déjà absorbé.** La file de travail à priorités livrée fin juillet
(`FitScoreEnqueuer`, `FitScoreQueueWorker`, V56) encaisse sans nouveau mécanisme le fait
qu'un test périme désormais des dizaines de scores d'un coup.

---

## 3. Décisions actées

### D1 — « même domaine » = même `jobPositionId`

Les deux alternatives sont écartées **par les données**, pas par préférence :

- **Secteur** : sur les 142 métiers seedés (V26), **9 ont `sector = NULL`** — ce sont les
  métiers transverses (Commercial, RH, Finance/Compta, Marketing, Support client,
  Management, Data Analyst, Chef de projet…). Ils n'auraient aucun groupe, précisément
  pour les profils les plus courants. Les 133 autres se répartissent sur **12 secteurs**,
  soit ~11 métiers par secteur : « IT, AI & Fintech » mélangerait le QCM d'un *Développeur*,
  d'un *Ingénieur DevOps* et d'un *Ingénieur Cybersécurité*.
- **Profil-type** : `JobProfileType` est l'axe de pondération **soft skills**
  (TECHNIQUE = 30/20/30/15/5 sur les 5 modules). Il ne dit rien du contenu technique et
  regroupe ~24 métiers, *Développeur* et *Ingénieur Mécanique* compris.

`jobPositionId` est déjà obligatoire à la création d'offre (décision 0.6), déjà porté par
`JobOffer`, déjà chargé par lot. **Aucune donnée nouvelle à modéliser.**

*Objection anticipée — « métier exact = trop peu de réutilisation ».* Le repli est déjà
correct : sans test, `hardWeight = 0`, le Fit Score devient soft seul. Une réutilisation
faible retombe sur le comportement d'aujourd'hui, alors qu'un score hard emprunté à tort
**fausse activement le classement**. Un score faux est pire qu'un score absent.

### D2 — Moyenne pondérée par **rang de récence**, pas par âge

Tous les résultats du candidat sur ce métier, du plus récent au plus ancien, avec un poids
divisé par 2 à chaque rang : `1, ½, ¼, ⅛, …`

**Pourquoi pas une pondération par l'âge** (« un test de 6 mois compte moitié moins ») :
la détection de péremption compare `fit_scores.computed_at` aux horodatages des sources
([`JpaFitScoreRepository:128`](backend/src/main/java/com/zennyt/recruitment/infrastructure/persistence/JpaFitScoreRepository.java)).
Un score qui dépend de l'âge des tests **change tous les jours sans qu'aucun événement ne
survienne** : chaque score devient périmé en permanence et la file ne se vide jamais. Le
poids par rang ne bouge qu'à la soumission d'un test — un événement déjà géré
(`TestResultCompletedEvent`).

**Propriété clé** : la somme des poids des anciens tests est toujours strictement
inférieure à 1, donc le test le plus récent pèse **toujours plus de la moitié**, quel que
soit le nombre de tests. L'historique compte sans jamais écraser le présent.

**Non gamable** : pour monter, il faut faire mieux que sa propre moyenne pondérée ; un
mauvais test entre dans l'historique et n'en sort jamais.

*Exemple* — 3 tests sur *Développeur* : 80 (le mois dernier), 65 (il y a 6 mois),
40 (il y a 1 an) → `(80×1 + 65×0,5 + 40×0,25) / 1,75 = 70`.
Pour comparaison : « le plus récent seul » donnerait 80, « moyenne simple » 62.

### D3 — Le test de l'offre consultée occupe toujours le rang 1

Même s'il est plus ancien qu'un test emprunté. Sans cette règle, un candidat effacerait un
mauvais résultat sur l'offre A en passant un test ailleurs.

Effet secondaire utile : la différenciation par offre est préservée. Historique = test sur
A il y a un an (40) et test sur C le mois dernier (80) →

| Offre consultée | Rang 1 | Rang 2 | Score hard |
|---|---|---|---|
| A (test propre) | A = 40 (×1) | C = 80 (×0,5) | **53** |
| B (même métier, pas de test) | C = 80 (×1) | A = 40 (×0,5) | **67** |

### D4 — Statuts retenus : `COMPLETED` et `TIMEOUT`, jamais `ABANDONED`

`TIMEOUT` est un résultat noté, déjà résumé par `HardSkillsSummaryListener`.

### D5 — Le niveau de l'offre source n'est pas un filtre

La difficulté d'un QCM n'est modélisée nulle part : il est généré par le recruteur pour son
offre. Filtrer par niveau diviserait la réutilisation par ~4 pour arbitrer une grandeur
qu'on ne mesure pas. Le niveau de l'offre source est **affiché**, pas filtré.

---

## 4. Points de friction (vérifiés dans le code)

### 4.1 — Le sens de `hardSkillScore` change

Aujourd'hui `hardSkillScore` = `TestResult.percentage`, littéralement « il a fait 80 % au
test de cette offre » ([`RecomputeFitScoresUseCase:79`](backend/src/main/java/com/zennyt/recruitment/application/usecase/RecomputeFitScoresUseCase.java)).
Demain c'est une estimation de niveau agrégée. **Même champ, sens différent.**

Exposé par 4 réponses : `FitScoreResponse`, `JobOfferResponse`, `JobOfferSummaryResponse`,
`CandidateFeedItemResponse`. **Vérifié : aucun fichier de `mobile/lib/` ne lit
`hardSkillScore`** — donc aucune casse d'affichage. Mais si un écran montre un jour
« Test : 80 % » et « Hard skills : 70 », ce sera signalé comme un bug alors que c'est
correct. À trancher : renommer le champ, ou ne jamais afficher les deux sans la liste des
tests.

### 4.2 — Le recalcul change de portée

`TestResultRecomputeListener` ne recalcule aujourd'hui **que la paire concernée**, et son
javadoc le justifie explicitement (« un résultat de test est spécifique à l'offre dont le
QCM a été passé »). Cette justification tombe. Il devra enfiler **toutes les offres ACTIVE
du métier** — sur le modèle de `GameSoftSkillsListener`, qui enfile déjà toutes les paires
d'un candidat.

Manquant : `JobOfferRepository` n'a **aucune** méthode de recherche par `jobPositionId`
(vérifié sur les 15 méthodes du port).

### 4.3 — La requête de péremption est restreinte à l'offre

[`JpaFitScoreRepository:146`](backend/src/main/java/com/zennyt/recruitment/infrastructure/persistence/JpaFitScoreRepository.java) :
`AND t.job_offer_id = f.job_offer_id`. Cette ligne doit sauter au profit du MAX sur le
métier, sinon un test passé ailleurs ne périmera jamais les scores concernés.

### 4.4 — Le chargement par lot ne sait pas charger un historique

`TestResultRepository.findByPairs(List<CandidateOfferPair>)` zippe (candidat, offre) et
renvoie **un** résultat par paire. Il faut une variante qui renvoie **N** résultats par
(candidat, métier), en une requête, sans repartir sur N requêtes — le problème que le
travail de juillet a supprimé.

### 4.5 — Fit Score identique entre offres du même métier × niveau

Pour un candidat **sans test propre**, toutes les offres d'un même métier et d'un même
niveau donneront le même Fit Score (offre B et offre D ci-dessus : 67 toutes deux).

C'est cohérent avec le CdC v3 — le modèle *est* métier × niveau. Mais c'est très
exactement l'objection déjà soulevée par l'encadrant (« Fit Score identique pour toutes les
offres »). Différence à savoir défendre : ce n'est plus un bug d'aplatissement des modules,
c'est le modèle assumé, et le score redevient différencié dès que le candidat passe le test
de l'offre.

### 4.6 — Le port de génération ne peut pas parler de progression

```java
BilingualText generateHardSkillsSummary(String jobTitle, String cvText, int scorePercent, boolean passed);
```

Un seul score, un seul booléen. Pour écrire « ses résultats progressent : 40 % il y a un an,
80 % le mois dernier », il faut lui passer **l'historique**, pas la moyenne.

**Règle à tenir** : le résumé doit être construit à partir des mêmes résultats que ceux qui
produisent le score. Sinon le texte dit une chose et le nombre une autre.

### 4.7 — La version candidat n'a aucune fondation

[`CandidateResumeController:32`](backend/src/main/java/com/zennyt/recruitment/api/CandidateResumeController.java)
est `@RecruiterOnly` et vérifie `offer.recruiterId().equals(recruiterId)`. Une version
candidat = nouvelle route, nouvelle annotation de sécurité, entrée de contrat, garde-fous.

Coût : 2 publics × 2 langues = **4 textes par résumé** au lieu de 2 → 2 appels Groq au lieu
d'1. Et côté mobile, **aucun des deux écrans n'existe** : seul un libellé décoratif
`'Resume AI'` en [`tinder_card.dart:179`](mobile/lib/features/fits/presentation/widgets/tinder_card.dart),
l'endpoint n'est appelé nulle part dans `mobile/lib/`.

---

## 5. Plan d'implémentation

Ordonné pour que chaque phase soit livrable et vérifiable seule. Les phases 1 à 3 sont
backend pur et sans dépendance mobile ; la phase 4 est la seule qui exige un écran.

### Phase 0 — Décisions préalables

> **État au 6 août 2026** — les phases 1 à 4 sont livrées et vérifiées. Les décisions 0.2
> et 0.3 ont été prises pour ne pas bloquer : `hardSkillScore` **garde son nom** (le
> renommer casserait le contrat sans bénéfice, aucun écran ne le lit), et la version
> candidat **est dans le périmètre**. La décision 0.1 reste à faire confirmer — elle ne
> conditionne aucun code, seulement la façon de présenter le résultat.

- [ ] **0.1** Faire confirmer §4.5 par l'encadrant **avant** de coder : le Fit Score
      redevient identique entre offres de même métier × niveau pour un candidat non testé.
- [ ] **0.2** Trancher §4.1 : renommer `hardSkillScore` (contrat + 4 DTO) ou documenter le
      changement de sens.
- [ ] **0.3** Décider si la **version candidat** (phase 4) est dans le périmètre de la
      soutenance — c'est le seul lot qui exige un écran mobile inexistant.

### Phase 1 — Le score hard sur l'historique métier

*Cœur du changement. Aucune IA, entièrement testable en unitaire.*

- [x] **1.1** Port : historique des résultats par `(candidatId, jobPositionId)`, filtré
      `COMPLETED`/`TIMEOUT`, trié `completed_at DESC` — **plus une variante par lot** qui
      charge l'historique de N couples en une requête (modèle `unnest(string_to_array(…))`
      déjà employé par `findByPairs`).
- [x] **1.2** Objet de valeur dédié pour la moyenne pondérée par rang (D2 + D3),
      testable seul, sans base ni Spring.
- [x] **1.3** Brancher dans `RecomputeFitScoresUseCase` — chemin unitaire **et** chemin par
      lot, en conservant l'équivalence entre les deux (le test d'équivalence existant est
      le garde-fou).
- [x] **1.4** Péremption : retirer `t.job_offer_id = f.job_offer_id` (§4.3) et comparer au
      MAX sur le métier.
- [x] **1.5** `JobOfferRepository` : recherche des offres ACTIVE par `jobPositionId`.
- [x] **1.6** `TestResultRecomputeListener` : enfiler toutes les offres du métier au lieu
      de la seule paire.

**Tests** — un seul test → score identique à aujourd'hui (non-régression stricte) ;
3 tests → 70 sur l'exemple de D2 ; le test propre passe devant un emprunté plus récent
(53 vs 67, exemple D3) ; un `ABANDONED` est ignoré ; un lot de 200 couples ne déclenche
qu'une requête d'historique ; un test soumis périme bien les scores des **autres** offres
du métier.

### Phase 2 — Le résumé hard skills sur l'historique métier

- [x] **2.1** Migration **V57** : `hard_skills_summary` re-clé sur
      `(candidate_id, job_position_id)` — remplace `uq_hard_skills_summary_candidate_offer`
      (V23). Les lignes existantes sont reconstruites par le premier passage.
- [x] **2.2** Élargir `ResumeSummaryGeneratorPort.generateHardSkillsSummary` pour recevoir
      l'historique (liste de résultats datés + niveau de l'offre source, §D5) au lieu d'un
      score isolé.
- [x] **2.3** `GenerateHardSkillsSummaryUseCase` : lit le même historique que la phase 1
      (§4.6, règle de cohérence), écrit par métier.
- [x] **2.4** `GetCandidateResumeUseCase` : lecture par métier + reformuler
      `HARD_SKILLS_NOT_TESTED_*` pour dire que le Fit Score est soft seul (P3).

**Tests** — un candidat testé sur une autre offre du même métier obtient un résumé ; un
candidat sans aucun test obtient le nouveau message ; le stub hors ligne reste utilisable
sans clé Groq.

### Phase 3 — Classement par tier (P4)

- [x] **3.1** `GetSwipeDeckUseCase.recruiterCandidates` : trier les candidats **ayant un
      score hard** avant ceux qui n'en ont pas, puis par score décroissant à l'intérieur de
      chaque groupe. Aujourd'hui c'est `findByJobOfferIdOrderByScoreDesc`, tri à plat.

**Justification à conserver dans le code** — ce n'est pas cosmétique. Sur TECHNIQUE / SENIOR
(`hard_weight = 65`, seed V42), un candidat soft 70 sans test obtient **70**, un candidat
soft 70 testé à 60 % obtient `0,35×70 + 0,65×60 =` **64**. Le non testé passe devant. Le
tier corrige cette inversion sans toucher à la formule.

**Tests** — à scores égaux, le testé passe devant ; l'ordre par score est conservé à
l'intérieur de chaque groupe ; la pagination reste correcte à la frontière des deux groupes.

### Phase 4 — Les deux versions du résumé (P5)

*Le seul lot qui dépend du mobile. À ne lancer qu'après la décision 0.3.*

- [x] **4.1** Stockage des deux publics (recruteur / candidat) × deux langues.
- [x] **4.2** Port : une génération par public. Coût Groq × 2 — à mesurer, pas à supposer.
- [x] **4.3** Endpoint candidat sur son propre résumé, avec sa propre annotation de
      sécurité (le contrôle actuel est un contrôle de propriété d'**offre**, inapplicable).
- [x] **4.4** Contrat d'API + garde-fous (`ApiContractRouteParityTest`,
      `RecruitmentSecurityAnnotationTest`).

**Tests** — un candidat ne peut lire que son propre résumé ; un recruteur ne reçoit jamais
la version candidat ; les deux versions portent le même fond.

### Phase 5 — Mobile (hors périmètre backend)

Les deux écrans sont à créer intégralement — celui du recruteur comme celui du candidat.
À cadrer avec l'équipe mobile.

---

## 6. Découvert pendant l'implémentation — un défaut qui bloquait tout

**`TestResultCompletedEvent` n'a jamais été publié.**

`SubmitTestAttemptUseCase` publiait ses événements depuis l'objet renvoyé par le dépôt.
Or `TestResultRepositoryAdapter.save` reconstruit un `TestResult` via `rehydrate`, et un
objet reconstruit ne porte aucun événement : la liste était systématiquement vide.

Conséquences réelles, mesurées sur base :

| | Avant | Après |
|---|---|---|
| Résumé IA hard skills | jamais généré | généré à la soumission |
| Recalcul du Fit Score après test | jamais déclenché | déclenché |

Le Fit Score restait correct malgré tout — le calcul à l'affichage livré fin juillet le
rattrapait. C'est précisément ce filet qui rendait le défaut invisible : seul le résumé,
qui n'a pas d'équivalent, restait vide indéfiniment. C'est le même défaut que celui déjà
corrigé sur `ChangeJobOfferStatusUseCase`.

Le cas d'usage n'avait **aucun test**. Il en a deux maintenant, dont un qui échoue si on
remet l'ancienne ligne — vérifié en la remettant.

**Le même défaut existait dans Games**, sur `SubmitGameResultUseCase` :
`GameResultRecordedEvent` n'avait jamais été publié non plus. Conséquence — la projection
soft skills de Recruitment n'était jamais alimentée par une partie jouée, et le résumé soft
jamais généré. Corrigé, avec test. Les deux écouteurs concernés (Analytics, Recruitment)
n'ont aucun effet visible pour l'utilisateur, contrairement au cas ci-dessous.

**Deux sites du même défaut restent ouverts**, dans `RecordSwipeUseCase` (swipe et match).
Non corrigés ici volontairement : ces événements n'ont jamais été émis, et les activer
changerait un comportement visible (notifications) — c'est une décision, pas un correctif.

---

## 6 bis. La trajectoire est calculée, jamais déduite par le modèle

Première recette avec une vraie clé Groq : sur un historique 100 % puis 50 %, le résumé a
annoncé **« une amélioration significative »** — dans les deux versions, sur deux appels
indépendants. Le candidat baissait.

Deux causes cumulées :

1. les dates étaient envoyées **au jour près**, or les deux tests dataient du même jour :
   les lignes étaient indiscernables ;
2. le prompt demandait au modèle de **déduire la direction** d'une liste ordonnée — ce que
   les modèles de langue font mal, et qu'une comparaison d'entiers fait de façon sûre.

Correctif : `HardSkillTrend` calcule la direction en Java (seuil de 10 points, sous lequel
l'écart entre deux QCM différents n'est pas interprétable), et le prompt la reçoit comme un
**fait à reformuler**, pas à recalculer. Les lignes portent un horodatage à la minute et une
étiquette de récence en toutes lettres — numéroter les lignes faisait lire « 3. » comme
« troisième essai » alors que le rang 3 est le test le plus ancien.

**Limite assumée** : une consigne de prompt reste probabiliste. Le modèle respecte
désormais la direction et ne numérote plus les essais, mais il lui arrive encore d'inférer
des causes que la donnée ne soutient pas (« capacité à gérer la pression »). Seule une
validation post-génération le garantirait ; ce n'est pas construit.

---

## 7. Ce que ce plan ne traite pas

- **La difficulté des QCM n'est pas modélisée** (§D5). Tant qu'elle ne l'est pas, agréger
  des tests de niveaux différents reste une approximation assumée, pas une mesure.
- **Le coût de génération** de la phase 4 n'a pas été mesuré. Deux appels Groq au lieu d'un,
  sur un chemin déjà asynchrone : à surveiller, pas à supposer négligeable.
- **La charge du fan-out** (§4.2) : un test soumis peut périmer des dizaines de scores. La
  file l'absorbe par construction, mais la profondeur de retard doit être observée au
  premier passage en conditions réelles.
- **L'écran recruteur** n'est pas spécifié : afficher un score agrégé sans la liste des
  tests qui le composent rendra §4.1 incompréhensible.
