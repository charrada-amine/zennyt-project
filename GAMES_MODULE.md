# 🎮 Module Games & Flame — Documentation vivante

> **Statut** : document de référence pour l'équipe. À tenir **à jour à chaque modification**
> du bounded context `games` (backend) ou de la feature `games` (mobile).
> Voir [Comment maintenir ce document](#-comment-maintenir-ce-document) en bas de page.

Ce module couvre les **jeux sérieux d'évaluation cognitive** de Zennyt : le candidat démarre une
session, joue des mini-jeux, et remonte des **métriques objectives** (jamais un score). Le **score
déterministe est calculé côté serveur** puis publié via un Domain Event lorsque son intégration
inter-contextes est validée ; « Je place » reste temporairement exclu de cette publication.

Chaque **jeu** correspond à un `GameType` (un domaine cognitif = une fiche) et se joue via un ou plusieurs **mini-jeux** (`MiniGame`) notés côté serveur. Le tableau liste **tous les jeux/mini-jeux implémentés**, leur **catégorie évaluée** et leur **état**.

| Jeu / mini-jeu | `GameType` | `MiniGame` | Catégorie évaluée | Statut | Rendu |
|----------------|------------|------------|-------------------|--------|-------|
| **Planifik #1 — Chemin Optimal** | `PLANIFIK` | `OPTIMAL_PATH` | Planification — chemin optimal (déviation ±10 %, essais, zones coûteuses, objectifs) | 🟢 Jouable **/10** — multi-niveaux (4), limite dure 3 essais | **Flame** + Flutter |
| **Planifik #2 — Ordonnancement de tâches** | `PLANIFIK` | `TASK_SCHEDULING` | Planification — dépendances + contraintes horaires + cohérence + réajustements | 🟢 Jouable **/10** | Flutter (tap-to-place) |
| **Planifik #3 — Tour de Hanoï** | `PLANIFIK` | `PREVISION_PUZZLE` | Planification — anticipation / planning prévisionnel | 🟢 Jouable **/10** — 3 niveaux (3→4→5 disques) | Flutter custom |
| ↳ **Planifik — « Je planifie » (domaine)** | `PLANIFIK` | *(les 3 mini-jeux ci-dessus)* | Planification | 🟢 **Complet** — profil global **/30** | Flame + Flutter |
| **Move Fast — « Je bouge »** | `MOVE_FAST` | `MOVE_FAST_CORE` | Flexibilité cognitive — switching de règles (niveau unique : Orientation ⇄ Mouvement **aléatoire**) | 🟢 **Complet** — barème d'escalade (50 × mult., streak 4, bonus 250) | Flutter custom |
| **« Je continue » — Focus Stream** | `CONTINUOUS_ATTENTION` | `CONTINUOUS_ATTENTION_CORE` | Attention soutenue et sélective — protocole Long Rosvold CPT X/AX | 🟢 **Complet /100 PROVISOIRE** — 44 blocs, 1 364 essais, score de balanced accuracy isolé ; d′/c/RT descriptifs | Flutter custom |
| **« Je coordonne » — Sync Square** | `VISUOMOTOR_COORDINATION` | `COORDINATION_TRACKING_CORE` | Coordination visuo-motrice — suivi continu d'une cible sur trajectoire carrée fixe horaire | 🟢 **Complet /100 PROVISOIRE** — 2 segments de pratique + 12 tests ; précision globale seule dans le score, autres indicateurs descriptifs | Flutter custom |
| **Memory Quest — « J'investigue »** | `MEMORY_QUEST` | `MEMORY_QUEST_CORE` | Mémoire de travail — Mission A (digit span) + B (objets) + distraction | 🟢 **Complet** — 7 niveaux (3→9), calibrage → timeout (score dépend du temps), `session_valid` ; composite **/100** | Flutter custom |
| **« Je place » — Place & Bind** | `VISUOSPATIAL_MEMORY` | `OBJECT_LOCATION_BINDING_CORE` | Mémoire visuo-spatiale — liaison objet-emplacement sur grille 4×4 | 🟢 **Complet /100 PROVISOIRE** — pratique à 2 objets puis 6 niveaux de 3→8 objets ; layouts reconstruits serveur, indicateurs secondaires descriptifs | Flutter custom |
| **« Je Décide » — Phases 1–4 mobile** | `DECISION` | `DECISION_CORE` | Prise de décision (II, ER, DT, CS, RE — /18 chacune → /90 → SCW /100) | 🟡 **Parcours UI complet** (aperçu maquette) + 🟢 **moteur backend prêt** : agrégation, règle DT, imputation, interprétations, validité, couche provisoire isolée. **Non jouable end-to-end** tant que le catalogue de 30 scénarios est vide (`DECISION_CORE.isPlayable()=false`) | Flutter (UI) / Java (moteur) |
| **Emotional Radar — « Je gère »** | `EMOTIONAL_REGULATION` | `EMOTIONAL_RADAR_CORE` | Régulation émotionnelle — reconnaissance d'émotion (famille + nuance + intensité) | 🟢 Jouable **9 pts/scène** — 3 scènes rédigées (27), 15 visées (135) ; **contenu servi par le backend** | Flutter custom |
| **Reflective Pause — « Je gère »** | `EMOTIONAL_REGULATION` | `REFLECTIVE_PAUSE_CORE` | Régulation émotionnelle — contrôle de l'impulsivité sous pression | 🟢 **Complet /10** — 10 moments, pause minimale 3 s, résultats + insights calculés serveur | Flutter custom |

> **Barème par mini-jeu** : Chemin Optimal / Ordonnancement / Tour de Hanoï → **/10** chacun ; leur somme = **profil Planifik /30**. Move Fast → points d'escalade (normalisés /100 pour l'interprétation). « Je continue » → balanced accuracy X/AX **/100 PROVISOIRE**, sans temps, d′ ni biais c dans le score. « Je coordonne » → précision globale pondérée par le temps, arrondie **/100 PROVISOIRE** ; précisions par vitesse/durée et distance moyenne restent descriptives. Memory Quest → **composite /100**. « Je place » → placements exacts / objets administrés sur les niveaux test, arrondis **/100 PROVISOIRE** ; swaps, distances, temps et pente de charge restent descriptifs. Emotional Radar /27 actuel + Reflective Pause /10 → composite émotionnel provisoire **/37**. Score **toujours calculé serveur** (le client n'envoie que des métriques brutes).

---

## 🧭 Vue d'ensemble & principe directeur

```
┌──────────────────────────── MOBILE (Flutter) ────────────────────────────┐
│  Flame game / Écran   →  produit des MÉTRIQUES objectives (pas de score)  │
│  GamesController      →  start(gameType) / submit(miniGame, metrics)      │
│  GamesRepository      →  Mock (autonome)  ──ou──  Impl (Dio → backend)    │
└───────────────────────────────────┬───────────────────────────────────────┘
                                     │  HTTP  POST /api/v1/games/...
                                     ▼
┌──────────────────────────── BACKEND (Spring, DDD hexagonal) ─────────────┐
│  GamesController → UseCase → Agrégat GameSession → PlanifikScoringService │
│  Le SCORE est calculé ici, jamais reçu du client.                         │
│  Dernier mini-jeu ⇒ COMPLETED ⇒ event (sauf intégration provisoire gelée)  │
└───────────────────────────────────┬───────────────────────────────────────┘
                                     │  Domain Event (in-process)
                                     ▼
                        Analytics (tableau de bord cognitif)
```

**Règle d'or** : le client transmet uniquement des **métriques mesurées** (nombre d'essais, longueur
de chemin, séquence de réponses…). Le barème vit dans le domaine backend — le client ne peut jamais
s'auto-attribuer de points. Le mock mobile **reproduit** ce même barème pour rester jouable hors-ligne.

---

## 🔷 BACKEND — Bounded Context `games`

Racine : `backend/src/main/java/com/zennyt/games/` — architecture **hexagonale / DDD**.
Contexte **indépendant** : ne dépend que de `shared`, s'intègre au reste **uniquement** par
`GameResultRecordedEvent`.

### Arborescence & rôle de chaque fichier

| Couche | Fichier | Rôle |
|--------|---------|------|
| **api** | `api/GamesController.java` | Contrôleur REST `/api/v1/games`. Traduit HTTP → commande, délègue au use case. Aucune logique métier. |
| | `api/GamesExceptionHandler.java` | Traduit localement payload/état invalide, propriété étrangère et ressource absente vers le format d'erreur commun en **400/403/404**, sans modifier `shared`. |
| | `api/dto/StartSessionRequest.java` | Body `POST /sessions` — `gameType` (le joueur vient du JWT). |
| | `api/dto/SubmitResultRequest.java` | Body `POST /sessions/{id}/results` — `miniGame` + payload union `Metrics` → `toMetrics()`. |
| | `api/dto/GameSessionResponse.java` | Réponse : état complet de la session + score composite + attempts + indicateurs propres au mini-jeu, dont **`reflectivePauseIndicators`**, **`continuousAttentionIndicators`**, **`coordinationIndicators`** et **`objectLocationIndicators`**. |
| | `api/dto/ScoreResponse.java` | Sérialisation d'un `Score`. |
| **application** | `application/usecase/StartGameSessionUseCase.java` | Crée l'agrégat `GameSession.start(...)` et le persiste. |
| | `application/usecase/SubmitGameResultUseCase.java` | Charge la session avec verrou d'écriture, vérifie le propriétaire JWT, calcule le `Score` (domaine), enregistre et persiste. Il publie les Domain Events depuis **l'agrégat muté** (la copie réhydratée n'en contient pas), puis les listeners transactionnels agissent après commit. Pour « Je continue », « Je coordonne » et « Je place », une capture techniquement invalide reste audit-only (`IN_PROGRESS`, aucun `Attempt`/event) ; une structure ou séquence invalide est refusée sans écriture. Pour « Je place », même l'Attempt valide ne publie provisoirement aucun event Fit Score tant que le barème n'est pas validé. |
| | `application/command/StartGameSessionCommand.java` | `(playerId, gameType)`. |
| | `application/command/SubmitGameResultCommand.java` | `(sessionId, playerId issu du JWT, miniGame, GameMetrics, deviceCalibration?)`. |
| **domain / model** | `domain/model/GameSession.java` | **Racine d'agrégat**. Invariants : 1 résultat/mini-jeu, refus d'un mini-jeu étranger au type, complétion auto + émission d'event au dernier mini-jeu. Java pur. |
| | `domain/model/MiniGame.java` | Enum des mini-jeux + `maxPoints` du barème + `belongsTo(gameType)` + `isPlayable()` (exclut les mini-jeux sans barème de la complétion). |
| | `domain/model/Attempt.java` | Résultat immuable d'un mini-jeu (`miniGame`, `score`, `recordedAt`). |
| **domain / vo** | `domain/vo/GameType.java` | `PLANIFIK`, `MOVE_FAST`, `MEMORY_QUEST`, `DECISION`, `EMOTIONAL_REGULATION`, `CONTINUOUS_ATTENTION`, `VISUOMOTOR_COORDINATION`, `VISUOSPATIAL_MEMORY`. |
| | `domain/vo/SessionStatus.java` | `IN_PROGRESS`, `COMPLETED`, `ABANDONED`. |
| | `domain/vo/Score.java` | VO auto-validant (`rawPoints`, `maxPoints`, `level`) + `normalized()`. |
| | `domain/vo/GameMetrics.java` | `sealed interface` des métriques objectives de tous les mini-jeux, dont `ReflectivePauseMetrics`, `ContinuousAttentionMetrics`, `CoordinationMetrics` et `ObjectLocationMetrics`. |
| | `domain/vo/PlanifikMetrics.java` | Métriques « Chemin Optimal » : liste `levels` (multi-niveaux) + fabrique mono-niveau de compat. |
| | `domain/vo/TaskSchedulingMetrics.java` | Métriques « Ordonnancement de tâches » : `dependenciesRespected`, `timeConstraintsRespected`, `planningCoherence` (0–2), `adjustmentCount`. |
| | `domain/vo/OptimalPathLevel.java` | Métriques d'UN niveau (`levelIndex`, `attempts`, longueurs, enums) + `deviationFromOptimal()`. |
| | `domain/vo/CostlyZonesAvoided.java` | `TOTAL` \| `PARTIAL` \| `NONE` (évitement des zones coûteuses). |
| | `domain/vo/SecondaryObjectivesReached.java` | `YES` \| `PARTIAL` \| `NO` (objectifs secondaires). |
| | `domain/vo/MoveFastMetrics.java` | Métriques « Je bouge » : `practiceTrialExcludedCount` + `responses` (liste `MoveFastResponse`). Exclut l'échauffement, dérive `correctResponses`, **valide la plausibilité** (anti-triche). |
| | `domain/vo/MoveFastResponse.java` | Un essai mesuré : `practiceTrial`, `correct`, `reactionTimeMs`, `ruleActive`, `isSwitchTrial`, `appliedOldRule`. |
| | `domain/vo/MoveFastRule.java` | Règle active d'un essai : `ORIENTATION` \| `MOVEMENT`. |
| | `domain/vo/MoveFastFlexibilityReport.java` | **Indicateurs de flexibilité cognitive dérivés serveur** (switch cost, erreurs persévératives, précision par règle, RT stats…) + versions **`*Adjusted`** (temps corrigés du calibrage). |
| | `domain/vo/DeviceCalibration.java` | **Socle calibrage appareil** (transversal) : `displayLatencyMs`, `calibrationOffsetMs`, fallback + `reducedReliability()`. |
| | `domain/vo/CalibrationMethod.java` / `InputMode.java` / `DeviceCategory.java` | Enums du calibrage (`technique`/`hardware_profile_fallback`, mode d'entrée, catégorie). |
| | `domain/vo/PrevisionPuzzleMetrics.java` | Métriques « Predictive Puzzle » : liste `levels` (multi-niveaux Tour de Hanoï). |
| | `domain/vo/PrevisionPuzzleLevel.java` | Métriques d'UN niveau (disques, 1er essai, erreurs, coups planifiés/optimaux, retries, complété) + validation `2^n−1`. |
| | `domain/vo/PrevisionPuzzleReport.java` | Indicateurs qualitatifs : `globalPlanSuccess` (HORS /10), détail par niveau. |
| **domain / config** | `domain/config/PrevisionPuzzleConfig.java` | **Constantes + barème catégoriel** Predictive Puzzle (fiche validée) : `optimal_moves(n)`, poids par critère, `puzzle_levels`/`max_sequence_errors` (décisions produit). Java pur. |
| | `domain/config/MemoryQuestConfig.java` | **Barème + système de niveaux « J'investigue »** : `taskScore(acc)` (0–5), bandes (provisoires), **niveaux** (`sequenceLengthForLevel`/`objectCountForLevel`/`distractionActiveAtLevel`, `total_levels`=7), **timeout calibrage** (`MAX_TASK_TIME_MS` PROVISOIRE, `adjustedTaskTimeoutMs`/`isTaskTimedOut`), **`isSessionValid`** (seuils PROVISOIRES). Java pur. |
| | `domain/vo/MemoryTaskResult.java` / `MemoryTaskKind.java` | Tâche mesurée (kind, correct/total, `responseTimeMs`) — le timeout est décidé serveur. |
| | `domain/vo/MemoryQuestMetrics.java` · `MemoryQuestReport.java` · `domain/service/MemoryQuestScoringService.java` | Mesures par tâche + composite /100 (moyenne des tâches jouées) + indicateurs. Parité mock. |
| | `domain/config/OptimalPathConfig.java` | **Constantes « Chemin Optimal »** (clés de la fiche) : tolérance ±10 %, `max_attempts`, `total_levels` (décision produit), `preplanning_required`, `global_plan_validation`, poids du barème (dont PARTIAL) + **bandes d'interprétation /10 par mini-jeu** (provisoires). Java pur. |
| | `domain/config/TaskSchedulingConfig.java` | **Constantes « Ordonnancement de tâches »** : poids 3/3/2/2, seuils `adjustmentScore` (<2/2-4/>4), `total_tasks` 10–12 + `time_constraints_mode` (décisions produit). Java pur. |
| | `domain/config/MoveFastConfig.java` | **Constantes du barème** Move Fast, **`SessionEndMode`** (FIXED_BUDGET par défaut / REACH_MAX_MULTIPLIER) + `plausibilityViolation(mode,…)`, **bandes d'interprétation** (source unique). Java pur. |
| | *mobile* `domain/config/move_fast_config.dart` | **Miroir Dart** : `MoveFastSessionEndMode`, seuils de fin, `interpretMoveFast` (bandes centralisées) — lu par l'écran + le mock (rien codé en dur). |
| **domain / service** | `domain/service/PlanifikScoringService.java` | **Barème déterministe** Planifik + Move Fast (via `MoveFastConfig`) + interprétations. Java pur, rejouable. |
| | `domain/service/CalibrationService.java` | **Service transversal** : `offsetMs` + `adjust` (temps brut − offset). Réutilisable dès qu'un score dépendra du temps (Decision, Memory Quest). |
| | `domain/service/ScoreBreakdownService.java` | **Détail du score** (panneau) : lignes « comme des logs » à partir des mêmes métriques + même barème. Miroir mock exact. |
| | `domain/vo/ScoreBreakdown.java` | Lignes du détail (`NOTE`/`INFO`/`CRITERION`/`SUBTOTAL`/`TOTAL`). |
| **Emotional Radar** | `api/EmotionalRadarController.java` | 3 routes : scènes, validation d'une scène, téléversement média. Couche fine. |
| | `api/dto/EmotionalRadarDtos.java` | **Point de filtrage unique de la clé de correction** : `SceneResponse.from` omet `expected*` + `explanation`. Ne jamais y ajouter de champ `expected*`. |
| | `application/usecase/GetEmotionalRadarScenesUseCase.java` | Scènes de la session + taxonomie (le contrôleur les expurge). |
| | `application/usecase/AnswerEmotionalRadarSceneUseCase.java` | Note UNE scène, **persiste** la réponse, renvoie le feedback + cumul. |
| | `application/usecase/UploadEmotionalRadarMediaUseCase.java` | Téléverse un média et le rattache à sa scène (ports uniquement — ArchUnit). |
| | `application/port/GamesMediaStoragePort.java` | Port média **propre au contexte** `games` (patron identity/engagement). |
| | `domain/config/EmotionalRadarConfig.java` | **Barème définitif** : 3/4/2, dégradé d'intensité, `GRADIENT_BONUS_ENABLED`, `TOTAL_SCENES`. Java pur. |
| | `domain/config/EmotionalRadarProvisionalRules.java` | **Couche PROVISOIRE isolée** : taxonomie des nuances (`FIGMA` vs `PROVISIONAL`) + bandes d'interprétation. Patron `DecisionProvisionalRules`. |
| | `domain/service/EmotionalRadarScoringService.java` | `grade` (corrige une scène) + `score` (agrège les réponses persistées) + `report`. Java pur. |
| | `domain/vo/EmotionalRadarScene.java` | Scène **avec** clé de correction — auto-validante (alt text / transcript obligatoires). Jamais sérialisée telle quelle. |
| | `domain/vo/EmotionalRadarAnswer.java` | Réponse **déjà notée** — source de vérité du score. |
| | `domain/vo/EmotionalRadarMetrics.java` · `EmotionalRadarSceneMetric.java` | Mesures **comportementales seules** (temps, aide, plein écran) — aucune réponse, aucun point. |
| | `domain/vo/EmotionalRadarReport.java` | Indicateurs : justesse émotion/nuance, calibrage d'intensité, confusions. |
| | `domain/vo/BasicEmotion.java` · `SceneMediaType.java` | 6 familles ; DIALOGUE/TEXT/IMAGE/VIDEO (+ exigences d'accessibilité). |
| | `domain/catalog/EmotionalRadarSceneCatalog.java` | Port du catalogue (patron `DecisionScenarioCatalog`). |
| | `domain/repository/EmotionalRadarAnswerRepository.java` · `EmotionalRadarSceneRepository.java` | Ports : réponses notées (upsert par session+scène) ; écriture de scène (média). |
| | `infrastructure/catalog/DatabaseEmotionalRadarSceneCatalog.java` | Catalogue en base — **non vide** (3 scènes). |
| | `infrastructure/persistence/EmotionalRadarScene{Entity,RepositoryAdapter}.java` · `EmotionalRadarAnswer{Entity,RepositoryAdapter}.java` · `Jpa*` | Persistance ; l'état « scène média incomplète » reste confiné à l'infrastructure. |
| | `infrastructure/storage/CloudinaryGamesMediaStorageAdapter.java` | Adaptateur média dédié `games` (dossier `zennyt/games/emotional-radar`). |
| **Reflective Pause** | `domain/config/ReflectivePauseConfig.java` | Catalogue des 10 moments, pause minimale 3 s, réponses recommandées et poids **3 + 4 + 3 = 10**. Java pur ; miroir Dart obligatoire. |
| | `domain/vo/ReflectivePause{Metrics,MomentMetric,Report,ResponseType}.java` | Mesures brutes auto-validantes (10 IDs uniques, timer cohérent), types de réponse et indicateurs serveur. |
| | `domain/service/ReflectivePauseScoringService.java` | Calcule temps contrôlé /3 + non-impulsivité /4 + prise de recul /3 ; arrondit les sous-scores à 0,1 puis la somme une seule fois. |
| | `resources/db/migration/V26__games_reflective_pause_minigame.sql` | Étend le CHECK `game_attempts.mini_game` avec `REFLECTIVE_PAUSE_CORE`, sans nouvelle table. |
| **Je continue** | `domain/config/ContinuousAttentionConfig.java` | Source de vérité du protocole **Long Rosvold X/AX** : `ROSVOLD_LONG_V1`, 44 blocs, 31 lettres/bloc, 690 ms + ISI 230 ms, fenêtre de réponse `[0,690)`, repos 2 min et tolérance technique provisoire 100 ms. Java pur ; miroir Dart obligatoire. |
| | `domain/config/ContinuousAttentionProvisionalRules.java` | **Score /100 PROVISOIRE** isolé et remplaçable : moyenne des balanced accuracies X_TEST/AX_TEST avec un unique arrondi rationnel half-up, sans flottants ; d′, biais c et temps exclus. |
| | `domain/service/ContinuousAttentionSequenceGenerator.java` | Génération/reconstruction déterministe FNV-1a 32 bits + xorshift32 + Fisher–Yates ; valide la séquence exacte depuis l'UUID de session. |
| | `domain/service/ContinuousAttentionScoringService.java` | Recalcule cibles/correction et dérive hits, omissions, commissions, rejets corrects, balanced accuracy, RT descriptifs, d′, biais c, quartiles temporels et validité technique. |
| | `domain/vo/ContinuousAttention{Metrics,BlockMetric,TrialMetric,Phase,InputSource,Report,PhaseReport,EpochReport}.java` | Payload brut auto-validant et rapport serveur. Ordre, compteurs, continuité X puis AX, timeline nominale, tuples de réponse et monotonie des onsets sont vérifiés avant persistance. |
| | `domain/repository/ContinuousAttentionMetricsRepository.java` | Port de remplacement transactionnel des données brutes d'une session, y compris l'audit-only invalide. |
| | `infrastructure/persistence/ContinuousAttentionMetricsRepositoryAdapter.java` | Persistance JDBC batch des 1 364 essais après validation du domaine. |
| | `resources/db/migration/V27__games_continuous_attention.sql` | Ajoute le type/mini-jeu, `continuous_attention_runs`, `continuous_attention_trials` et l'index unique partiel empêchant deux Attempts valides. |
| **Je coordonne** | `domain/config/CoordinationConfig.java` | Source de vérité de `FIXED_SQUARE_CW_V1` : carré fixed-point, 2 segments de pratique + 12 tests, durées 7000/2333 ms, tours lent/rapide, géométrie et fenêtres de validité. Java pur ; miroir Dart obligatoire. |
| | `domain/config/CoordinationProvisionalRules.java` | **Score /100 PROVISOIRE** isolé et remplaçable : précision globale pondérée par le temps, unique arrondi half-up ; aucune sous-précision ni distance dans le score. |
| | `domain/service/CoordinationTrajectoryService.java` | Reconstruit de manière déterministe la position de la cible sur le carré fixe horaire, sans easing ni saut aux changements de segment/vitesse. |
| | `domain/service/CoordinationScoringService.java` | Rejoue la trajectoire sur la timeline canonique serveur et réintègre cible mobile + pointeur maintenu sur une grille de **1 ms** : une trace clairsemée ne peut pas fabriquer un suivi parfait. Calcule précision, distance et validité ; une frontière test hors tolérance rend `technicalValid=false`. |
| | `domain/vo/Coordination{Metrics,InputSource,Phase,PointerSample,Report,SegmentMetric,Speed}.java` | Trace brute auto-validante (14 segments contigus, positions fixed-point, source d'entrée, interruptions) et rapport descriptif serveur. Le client ne transmet ni cible, ni distance, ni score. |
| | `domain/repository/CoordinationMetricsRepository.java` | Port de remplacement transactionnel du run et de ses échantillons bruts, y compris l'audit-only invalide. |
| | `infrastructure/persistence/CoordinationMetricsRepositoryAdapter.java` | Persistance batch V28 de la trace après validation du domaine. |
| | `resources/db/migration/V28__games_visuomotor_coordination.sql` | Autorise `VISUOMOTOR_COORDINATION` / `COORDINATION_TRACKING_CORE` et persiste le run, les segments/échantillons et leur audit de validité. |
| **Je place** | `domain/config/ObjectLocationConfig.java` | Source de vérité `OBJECT_LOCATION_FINE_V1` : grille 4×4, pratique 2 objets, charges test 3→8, timings, réserves et progression. Toutes les valeurs de protocole non fournies sont marquées provisoires ; miroir Dart obligatoire. |
| | `domain/config/ObjectLocationProvisionalRules.java` | **Score /100 PROVISOIRE** isolé et remplaçable : placements exacts / objets administrés, unique arrondi half-up ; temps, swaps, distances et pente de charge exclus. |
| | `domain/service/ObjectLocationLayoutGenerator.java` | Reconstruit depuis `sessionId|OBJECT_LOCATION_FINE_V1` le catalogue, les objets, leurs cellules et leur ordre de réserve avec FNV-1a 32 bits, xorshift32 et Fisher–Yates. |
| | `domain/service/ObjectLocationActionReplayer.java` · `ObjectLocationScoringService.java` | Rejoue les poses/retours/éjections, classe chaque objet de façon exclusive (`EXACT`, `SWAP`, `LOCAL`, `GLOBAL`, `UNPLACED`), dérive les indicateurs et valide timing/progression côté serveur. |
| | `domain/vo/ObjectLocation*.java` | Actions et niveaux bruts auto-validants, enums de phase/réserve/fin, rapports descriptifs ; aucune origine, catégorie d'erreur ou note n'est acceptée du client. |
| | `domain/repository/ObjectLocationMetricsRepository.java` · `infrastructure/persistence/ObjectLocationMetricsRepositoryAdapter.java` | Port + adaptateur JDBC de remplacement transactionnel d'un run, de ses niveaux et de ses actions, y compris l'audit-only invalide. |
| | `resources/db/migration/V29__games_object_location_memory.sql` | Autorise `VISUOSPATIAL_MEMORY` / `OBJECT_LOCATION_BINDING_CORE`, crée les trois tables d'audit et protège l'unique Attempt valide par session. |
| **domain / event** | `domain/event/GameResultRecordedEvent.java` | `games.result.recorded` — **seul** point d'intégration inter-contextes. |
| **domain / repo** | `domain/repository/GameSessionRepository.java` | Port (interface) — le domaine ne connaît jamais JPA ; expose un chargement sérialisé pour empêcher deux soumissions concurrentes d'écraser un audit validé. |
| | `domain/repository/DeviceCalibrationRepository.java` | Port du calibrage (upsert par `sessionId`). |
| **infrastructure** | `infrastructure/persistence/GameSessionEntity.java` | Entité JPA (table `games.game_sessions`). |
| | `infrastructure/persistence/AttemptEmbeddable.java` | `@Embeddable` (table fille `games.game_attempts`). |
| | `infrastructure/persistence/GameSessionRepositoryAdapter.java` | Implémente le port, **mappe** agrégat ⇄ entité et conserve la séparation entre copie sauvée et événements de l'agrégat original. |
| | `infrastructure/persistence/JpaGameSessionRepository.java` | Spring Data JPA technique ; `findByIdForUpdate` applique un verrou pessimiste pendant la soumission. |
| | `infrastructure/persistence/DeviceCalibrationEntity.java` + `JpaDeviceCalibrationRepository` + `DeviceCalibrationRepositoryAdapter` | Persistance du calibrage (table `games.device_calibrations`). |
| **intégration** | `../analytics/application/listener/GameResultRecordedListener.java` | Consomme l'event via `@TransactionalEventListener` (Analytics). |
| **DB** | `resources/db/migration/V9__games_schema.sql` | Schéma `games` : tables `game_sessions`, `game_attempts`, index, contraintes `CHECK`. |
| **test** | `test/java/com/zennyt/games/domain/GameSessionTest.java` | Tests unitaires de l'agrégat + scoring (Java pur, sans Spring). |
| | `test/java/com/zennyt/games/domain/MoveFastMetricsTest.java` | Tests validation métriques + indicateurs de flexibilité + bandes d'interprétation. |
| | `test/java/com/zennyt/games/domain/OptimalPathConfigTest.java` | Verrouille les constantes « Chemin Optimal » (tolérance, `max_attempts`, barème essais). |
| | `test/java/com/zennyt/games/domain/TaskSchedulingScoringTest.java` | Barème Ordonnancement : parfait 10/10, dépendances non respectées, `adjustment_count`=2 → 1 pt, =5 → 0 pt. |
| | `test/java/com/zennyt/games/domain/PrevisionPuzzleScoringTest.java` | Barème catégoriel « Predictive Puzzle » : parfait 10/10, 0+2+2=4, niveau échoué, moyenne 3 niveaux, `globalPlanSuccess`. |
| | `test/java/com/zennyt/games/domain/CalibrationTest.java` | Socle calibrage : offset/display latency, fallback, `adjust`, indicateurs Move Fast `*Adjusted`. |
| | `test/java/com/zennyt/games/domain/EmotionalRadarScoringTest.java` | Barème 3/4/2, dégradé d'intensité, 27/27 sur 3 scènes, bonus neutralisé, nuance étrangère à la famille rejetée, **anti-triche** (le score ignore les métriques client), alt text/transcript obligatoires, `FIGMA` vs `PROVISIONAL`. |
| | `test/java/com/zennyt/games/domain/ScoreBreakdownServiceTest.java` | Détail du score : split Move Fast, somme des critères Optimal Path, barème catégoriel Predictive Puzzle. |
| | `test/java/com/zennyt/games/domain/ContinuousAttentionScoringTest.java` | Vecteurs déterministes cross-platform, protocole, fenêtre temporelle, score 84, d′/c descriptifs, stratégies dégénérées, arrondi rationnel, validité et exclusion de la pratique. |
| | `test/java/com/zennyt/games/application/SubmitContinuousAttentionResultUseCaseTest.java` | Propriété JWT, soumission valide atomique, audit-only invalide, rejet déterministe et absence d'Attempt/event indus. |
| | `test/java/com/zennyt/games/infrastructure/persistence/ContinuousAttentionMetricsRepositoryAdapterTest.java` | Vérifie le remplacement transactionnel et le batch exact de 1 364 essais. |
| | `test/java/com/zennyt/games/domain/CoordinationScoringTest.java` | Verrouille trajectoire, ordre/durées, grille serveur 1 ms, résistance aux samples clairsemés, précision/distance, score half-up et validité temporelle. |
| | `test/java/com/zennyt/games/application/SubmitCoordinationResultUseCaseTest.java` | Vérifie propriété JWT, soumission valide, audit-only invalide, verrou de chargement et publication d'event même si le repository renvoie une copie réhydratée. |
| | `test/java/com/zennyt/games/api/GamesExceptionHandlerTest.java` | Vérifie les réponses contractuelles 400/403/404 du bounded context. |
| | `test/java/com/zennyt/games/infrastructure/persistence/CoordinationMetricsRepositoryAdapterTest.java` | Vérifie le remplacement transactionnel du run V28 et la persistance de la trace brute. |
| | `test/java/com/zennyt/games/support/CoordinationTestFixtures.java` | Fabrique déterministe de traces de coordination pour les tests domaine/application/infrastructure. |
| | `test/java/com/zennyt/games/domain/ObjectLocationScoringTest.java` | Vecteur golden Java/Dart, layouts, rejeu, classification exclusive, progression/stop, timings, score provisoire et audit technique. |
| | `test/java/com/zennyt/games/application/SubmitObjectLocationResultUseCaseTest.java` | Propriété JWT, reconstruction serveur, soumission valide atomique, audit-only, retry et absence volontaire d'event Fit Score. |
| | `test/java/com/zennyt/games/api/dto/ObjectLocationApiContractTest.java` | Verrouille les noms JSON de la requête et du rapport par niveau. |
| | `test/java/com/zennyt/games/infrastructure/persistence/ObjectLocationMetricsRepositoryAdapterTest.java` | Vérifie le remplacement V29 et la persistance des actions brutes. |
| | `test/java/com/zennyt/games/support/ObjectLocationTestFixtures.java` | Fabrique déterministe de niveaux/actions pour les tests domaine/application/infrastructure. |

### API REST (`/api/v1/games`)

| Méthode | Route | Body | Réponse | Erreurs |
|---------|-------|------|---------|---------|
| `POST` | `/sessions` | `StartSessionRequest { gameType }` | `201` `GameSession` (IN_PROGRESS) | 400, 401 |
| `POST` | `/sessions/{sessionId}/results` | `SubmitResultRequest { miniGame, metrics, deviceCalibration? }` | `200` `GameSession` (+ indicateurs selon le jeu) | 400, 401, 403, 404 |
| `GET` | `/sessions/{sessionId}/emotional-radar/scenes` | — | `200` `EmotionalRadarSceneList` — scènes + taxonomie, **sans réponse attendue** | 401, 404 |
| `POST` | `/sessions/{sessionId}/emotional-radar/scenes/{sceneId}/answers` | `{ selectedEmotion, selectedNuance, selectedIntensity }` | `200` `EmotionalRadarFeedback` — correction notée et persistée serveur | 400, 404 |
| `POST` | `/emotional-radar/scenes/{sceneId}/media` | `multipart/form-data { file, altText?, transcript? }` | `201` `EmotionalRadarScene` | 400, 404 |

Authentification : `bearerAuth` (JWT) — `playerId = jwt.getSubject()`. La soumission vérifie que
la session appartient à ce joueur ; connaître un `sessionId` étranger ne permet pas de l'altérer.

### Cycle de vie d'une session

```
start(playerId, gameType) ──► IN_PROGRESS
    │  recordResult(miniGame, score)   (1 par mini-jeu, cohérent avec le type, mini-jeu jouable)
    ▼
attempts.size == expectedMiniGames.size ?          (expectedMiniGames = mini-jeux JOUABLES du type)
    │ oui ──► complete() ──► COMPLETED + registerEvent(GameResultRecordedEvent)
    └ non ──► reste IN_PROGRESS
```

> **ℹ️ Mini-jeux actifs/inactifs.** `MiniGame.isPlayable()` distingue les mini-jeux
> réellement jouables de ceux sans barème ; `expectedMiniGames()` ne compte que les jouables et
> `recordResult` refuse un mini-jeu inactif. **Les 3 mini-jeux Planifik sont désormais jouables**
> (`OPTIMAL_PATH` + `TASK_SCHEDULING` + `PREVISION_PUZZLE`) → une session Planifik se complète sur
> les **3** et le **profil global est /30**. (Le drapeau reste utile si un futur mini-jeu arrive sans barème.)

### Barème (`PlanifikScoringService`)

**Planifik #1 « Chemin Optimal » — /10 par niveau** (constantes figées dans `OptimalPathConfig`, clés de la fiche « JE PLANIFIE — Mini-jeu 1 »)

Le mini-jeu enchaîne plusieurs niveaux. Le client envoie `levels[]` (une entrée par niveau) ; **le serveur note chaque niveau /10** puis **agrège par moyenne arrondie** en un score unique de mini-jeu (préserve un seul `Attempt` par mini-jeu). *Barème par niveau :*
- `optimal_path_tolerance` = **0.10** → `path_deviation ≤ 10 %` → **4 pts**, sinon **0**
- `max_attempts` = **3** → essais : 1 → 3 pts · 2 → 2 pts · ≥3 → 1 pt (`OptimalPathConfig.attemptScore`)
- `costlyZonesAvoided` : **TOTAL → 2** · **PARTIAL → 1** · **NONE → 0** (⚠️ raffinement à valider — la fiche dit « total ou partiel » pour 2 pts max)
- `secondaryObjectivesReached` : **YES → 1** · **PARTIAL → 0** (⚠️ règle à valider, cf. `SECONDARY_OBJECTIVE_PARTIAL_POINTS`) · **NO → 0**
- `preplanning_required` = true · `global_plan_validation` = true · `total_levels` = **4** (⚠️ décision produit — fiche : « à définir »)

> **⛔ Limite dure d'essais (`max_attempts` = 3).** Un « mauvais chemin » = une validation qui n'atteint pas la sortie (`onWrong` → `_levelAttempts++`). À la **3ᵉ** validation ratée, le niveau est **scellé en échec** : plus aucune validation acceptée, feedback « Niveau échoué — 3 essais », **passage automatique** au niveau suivant. Le niveau échoué est capturé comme un niveau normal avec des **métriques d'échec** (`pathLength = 0` → chemin 0/4, `attempts ≥ 3` → essais 1/3, zones `NONE` → 0/2, objectif `NO` → 0/1) ⇒ **1/10** (pas de 0 brutal), pour que la moyenne des niveaux reste cohérente. Scoré à l'identique par le mock et le backend (`buildFailedLevelMetrics`). *Cas limite* : réussir au 3ᵉ essai (2 ratés + 1 réussi) **n'est pas un échec** (la réussite passe par `onCorrect`, jamais par le compteur de ratés) → essais 1/3 mais niveau évalué normalement. Après un chemin raté (non final), **le trait de trajet est réinitialisé au départ** pour retracer.

> **⚠️ Agrégation par moyenne à valider avec le psychologue.** Le score du mini-jeu = moyenne arrondie des scores /10 des niveaux (`PlanifikScoringService.scoreOptimalPath`). Le mock mobile réplique exactement cette agrégation. **Persistance** : on ne stocke que le score agrégé (un `Attempt`) — **pas de migration Flyway** ; le détail par niveau ne vit que dans la requête API (option préférée pour ne pas alourdir le schéma).

> **⚠️ NON VALIDÉ PAR LE PSYCHOLOGUE — bandes /10 par mini-jeu.** Les bandes 0–3 / 4–6 / 7–10 sont un ajout développeur, isolées dans `OptimalPathConfig.MINI_GAME_INTERPRETATION_BANDS` (partagées avec Predictive Puzzle). Les bandes du **profil global /30** (≤10/≤17/≤23/≤27/sinon) restent **conformes à la fiche et inchangées**.
- Interprétation mini-jeu (provisoire) : 0–3 *Très faible* · 4–6 *Moyen* · 7–10 *Bon à excellent*

**Planifik #2 « Ordonnancement de tâches » — /10** (constantes figées dans `TaskSchedulingConfig`, fiche « JE PLANIFIE — Mini-jeu 2 »)
- **Dépendances respectées** (`dependencies_respected`, tout-ou-rien) → **3 pts** si TOUTES respectées, sinon **0** (pas de score partiel — explicite dans la fiche)
- **Contraintes horaires respectées** (`time_constraints_respected`, tout-ou-rien) → **3 pts** ou **0**
- **Cohérence du planning** (`planning_coherence`) : 0 désordonné · 1 partiel · 2 clair → **0 à 2 pts**
- **Réajustements** (score dérivé du nombre brut `adjustment_count`) : **<2 → 2 pts** · **2 à 4 → 1 pt** · **>4 → 0 pt** (⚠️ la valeur **2** tombe dans « 2 à 4 » = **1 pt**, pas 2)
- Total = somme = **/10** ; interprétation mini-jeu partagée (0–3/4–6/7–10). Mock répliqué (`_scoreTaskScheduling`).

**Profil Planifik global — /30** : ≤10 *Très faible* · ≤17 *Moyen faible* · ≤23 *Moyen* · ≤27 *Bon* · sinon *Excellent* — les 3 mini-jeux étant jouables, le composite est bien **/30**.

**Move Fast « Je bouge » — barème en escalade** (constantes figées dans `MoveFastConfig`, clés de la fiche « JE BOUGE »)
- `base_points_per_correct` = **50**, `final_bonus_multiplier` = **250**
- `correct_streak_for_upgrade` = **4**, `max_multiplier` = **10** (min ×1)
- `reset_streak_on_error` = true, `decrease_multiplier_on_error` = true (min ×1)
- `max_response_time_ms` = **2000**, `min_response_time_ms` = **250**
- Réponse correcte : `+50 × multiplicateur` ; 4 bonnes consécutives : multiplicateur `+1`, compteur remis à 0
- Erreur avec streak partiel : compteur remis à 0 ; streak vide : multiplicateur `-1` (min ×1) ; bonus final : `+250 × multiplicateur`

**Move Fast — métriques mesurées (contract-first)**
Le client envoie `practiceTrialExcludedCount` + `responses[]`, un objet par essai : `correct`, `reactionTimeMs`, `ruleActive` (`ORIENTATION`/`MOVEMENT`), `isSwitchTrial`, `appliedOldRule` (erreur persévérative), `practiceTrial`. **Le score et les indicateurs sont calculés serveur — le client n'envoie jamais de points.**

**Move Fast — indicateurs de flexibilité cognitive dérivés serveur** (`MoveFastFlexibilityReport`, exposés dans `GameSessionResponse.moveFastIndicators`) : `precisionRatio`, `average/median/stdDev reactionTimeMs`, `fast/slowResponsesPercent` (<250 ms / >2000 ms), `switch`/`nonSwitchResponseTimeAvgMs`, **`switchCostMs`** (métrique centrale = switch − nonSwitch), `perseverativeErrorsCount`, `correctResponsesRule{Orientation,Movement}`, `sessionDurationSec`, `sessionCompletionStatus`.

> **🟠 Essais d'échauffement (warm-up).** Les `PRACTICE_TRIAL_COUNT` (=3) premiers essais sont marqués `practiceTrial=true` et **exclus par le backend** du scoring ET de toutes les statistiques (correction méthodologique de la fiche révisée, Tableau 2 — ils ne servent pas non plus au calibrage, cf. Tâche 4). Le compteur `practiceTrialExcludedCount` documente l'exclusion et est validé pour cohérence.

> **⚠️ DIVERGENCE À VALIDER PAR LE PSYCHOLOGUE — condition de fin de session (CONFIGURABLE).** Le mode est piloté par l'énumération `MoveFastConfig.SessionEndMode` : **`FIXED_BUDGET`** (défaut, **diverge de la fiche** : 12 bonnes / 18 essais / 84 s) ou **`REACH_MAX_MULTIPLIER`** (règle de la fiche : jouer jusqu'à ×10, sans limite de temps ni d'essais). **Basculer = changer la seule constante `SESSION_END_MODE`** (+ son miroir mobile `MoveFastConfig.sessionEndMode`) — aucun refactor. L'anti-triche s'adapte au mode (`plausibilityViolation(mode, …)`) : en `FIXED_BUDGET` il rejette (400) au-delà de `maxResponses`/durée ; en `REACH_MAX_MULTIPLIER` **aucun plafond**. Le mobile lit ce mode depuis la config (pas de valeur en dur dans l'écran : `_reachedEndCondition`/`_sessionProgress`). **Divergence tracée — ne pas trancher sans le psychologue référent.**

> **⚠️ NON VALIDÉ PAR LE PSYCHOLOGUE — bandes d'interprétation.** Les bandes ci-dessous (<40 / <60 / <75 / <90 / sinon, sur 100) n'existent dans aucune fiche. Conservées à titre provisoire dans `MoveFastConfig.INTERPRETATION_BANDS` (commentaire `// AJOUT NON VALIDÉ PAR LE PSYCHOLOGUE`), à valider ou remplacer.

- Interprétation (sur 100, provisoire) : <40 *Très faible* · <60 *Moyen faible* · <75 *Moyen* · <90 *Bon* · sinon *Excellent*

### 🎯 « Je continue » (`CONTINUOUS_ATTENTION_CORE`) — attention soutenue X/AX

`CONTINUOUS_ATTENTION` est un `GameType` séparé de `MOVE_FAST` : le hub mobile affiche les deux
jeux dans la carte existante **Cognitive Flexibility**, mais leurs sessions et leurs barèmes ne
sont jamais mélangés. Le nom de catégorie reste inchangé pour préserver la taxonomie produit et la
matrice Fit Score. Le renommage éventuel est seulement tracé dans « Décisions à valider ».

#### Protocole réellement implémenté

La fiche cite « Conners CPT-3 », mais ses paramètres décrivent le **Long Rosvold Continuous
Performance Test** : phase X puis phase AX, 2 blocs de pratique + 20 blocs de test par famille,
31 lettres par bloc, 8 cibles X ou 6 cibles AX, lettre **690 ms**, écran vide **230 ms**, et repos
programmé de **2 minutes** entre X et AX. Il s'agit d'une **erreur de référence de la fiche à
signaler au psychologue**, pas d'une adaptation du code. L'implémentation et l'interface ne
revendiquent jamais une équivalence, une norme ou un T-score Conners.
Référence de protocole utilisée pour cette correction :
[Long Rosvold CPT — Millisecond](https://www.millisecond.com/library/v7/cpt/cpt_rosvold/cpt_rosvold/cpt_rosvold_long.manual).

- famille X : répondre uniquement à `X` ; distracteurs tirés avec remplacement dans
  `A–W, Y, Z` ;
- famille AX : répondre uniquement à `X` immédiatement précédé de `A` ; distracteurs `A–Z`,
  avec prévention des AX accidentels, y compris aux frontières ;
- 44 blocs × 31 = **1 364 essais** ; pratique persistée pour audit mais exclue du score ;
- `previousLetter` reste continu entre pratique/test et entre blocs d'une même famille, puis
  est réinitialisé au passage X → AX ;
- séquence `ROSVOLD_LONG_V1` déterministe depuis l'UUID de session, générée de façon identique
  en Java et Dart, puis intégralement reconstruite et validée serveur ;
- graine normative : FNV-1a 32 bits UTF-8 de
  `lower(sessionId) + "|ROSVOLD_LONG_V1"`, état zéro remplacé par `0x6D2B79F5`, puis
  xorshift32 unsigned (`<<13`, `>>>17`, `<<5`), modulo non signé et Fisher-Yates descendant ;
- bloc X : 8 `X` + 23 tirages avec remplacement dans `A–W,Y,Z`, puis mélange ; bloc AX :
  6 tokens `AX_PAIR` + 19 distracteurs mélangés, expansion des paires, et retraitage de tout
  `X` distracteur qui suivrait un `A` ;
- vecteur croisé Java/Dart (`00000000-0000-4000-8000-000000000001`) : seed
  `0xFC0A124C`, FNV du flux de 1 364 lettres `0xD9278D75`, premier bloc
  `HZNXXAJGQXXYYKEOCXFVXOXLJLNNIXH`, premier bloc AX
  `AXHAXDNCNOJAAXVAXAXZUAXAIIPACHW`, dernier bloc
  `JYGAXJBYARQQKAXFSPAXXAXFYAXAXDY`.

#### Mesures, persistance et score

Chaque essai conserve phase/bloc/index, lettres précédente/courante, réponse sémantique mappée
`57`/`0`, exactitude client contrôlée, latence, timestamps monotones ayant la même origine de
phase, durées réelles d'affichage/ISI, source clavier/touch, réponses supplémentaires et
interruption. La fenêtre de réponse est exactement `[0,690 ms)` : 0 et 689 sont acceptés, 690 et
l'ISI sont refusés. La migration **V27** ajoute le `GameType`, le mini-jeu et une persistance
run + essais dédiée : les 1 364 lignes d'un payload structurellement valide ne disparaissent pas
après la soumission. Le serveur reconstruit la séquence, la cible et `correct`, contrôle
`responseTimestampMs - actualOnsetMs = latencyMs`, puis rejette toute divergence structurelle.

Une structure valide mais techniquement non comparable (incomplète, interrompue, arrière-plan ou
écart temporel supérieur à la tolérance) est conservée **audit-only** et renvoyée avec la session
`IN_PROGRESS` : aucun `Attempt`, aucun `GameResultRecordedEvent`, aucun Fit Score. Un retry
remplace atomiquement ce run d'audit. Une structure invalide est rejetée sans persistance.

Le score est isolé dans `ContinuousAttentionProvisionalRules` :

```text
balancedAccuracyPhase(%) = (hitRate(%) + correctRejectionRate(%)) / 2
score /100 = roundHalfUp(mean(balancedAccuracyXTest(%), balancedAccuracyAxTest(%)))
```

`// PROVISOIRE — non validé par le psychologue` : la règle est remplaçable sans modifier le
moteur. L'implémentation conserve cette moyenne sous forme d'une fraction entière commune et
n'arrondit qu'une fois, afin que Java et Dart produisent strictement le même entier, y compris
sur une valeur exacte à `.5`. Les temps de réaction, `d′` avec correction log-linéaire, le biais `c`, les omissions,
commissions et tendances sur 4 époques de 5 blocs sont **strictement descriptifs** et ne changent
jamais le score. Aucun diagnostic, percentile, classement candidat ou décision de recrutement.
Le niveau associé au `Score` est la constante neutre **`Descriptive — provisional`**, sans bande
d'interprétation. Limite connue du barème provisoire : « ne jamais répondre » et « répondre à
toutes les lettres » donnent tous deux 50/100 ; ce plancher de hasard doit être réévalué par le
psychologue, sans introduire `d′`, `c` ou les temps dans le score.

Les indicateurs descriptifs utilisent la correction log-linéaire exacte :

```text
H  = (hits + 0.5) / (targets + 1)
FA = (commissions + 0.5) / (nonTargets + 1)
d′ = Z(H) - Z(FA)
c  = -0.5 × (Z(H) + Z(FA))
```

#### UX, pause et validité

Flow : cover → format 25 min → tutoriel X → pratique X → test X → repos 2 min → tutoriel AX →
pratique AX → test AX → sauvegarde → résultats descriptifs → insights. Feedback uniquement en
pratique ; aucun feedback, son, vibration ou animation par essai pendant le test. Le bouton tactile
et la barre d'espace produisent la même réponse sémantique. Une pause ou un passage en arrière-plan
pendant le test marque le run local interrompu et impose la reprise de la phase ; les essais
abandonnés ne sont pas fusionnés avec le run recommencé. Le menu Pause/Règles/Exit reste complet ;
pendant un bloc actif, ouvrir Pause explique explicitement que la phase redémarrera.

### 🎯 « Je coordonne » (`COORDINATION_TRACKING_CORE`) — suivi visuo-moteur continu

`VISUOMOTOR_COORDINATION` est un `GameType` autonome : il ne modifie ni `MOVE_FAST`, ni
`CONTINUOUS_ATTENTION`, ni leurs barèmes. Le hub l'affiche comme troisième jeu de la carte
existante **Cognitive Flexibility** ; le nom de cette catégorie reste inchangé en attendant un
arbitrage taxonomique avec le psychologue et la matrice Fit Score.

#### Protocole `FIXED_SQUARE_CW_V1`

La cible démarre au **coin supérieur gauche** d'un carré normalisé, puis suit sa bordure dans le
sens horaire, à vitesse linéaire et sans easing. La trajectoire reste continue aux changements de
segment et de vitesse. Avant le départ, la balle orange reste immobile ; le premier échantillon
doit placer le pointeur dans la moitié intérieure de son rayon pour déclencher l'horloge globale.

| Phase | Segments | Ordre | Durée active |
|-------|----------|-------|--------------|
| Pratique | 2 | 7000 ms lent → 7000 ms rapide | **14 000 ms** — auditée, hors score |
| Test | 12 | `(7000 lent → 7000 rapide → 2333 lent → 2333 rapide) × 3` | **55 998 ms** — seule phase cotée |
| Total protocole | 14 | pratique puis test, segments contigus | **69 998 ms** |

La durée catalogue **3 min** couvre l'expérience complète (consignes, tutoriels, préparation et
résultats) ; la fenêtre mesurée de validité porte uniquement sur les **55 998 ms de test**. Les
paramètres géométriques et cinématiques ci-dessous ont été autorisés par le demandeur pour rendre
le protocole exécutable, mais restent **PROVISOIRES — non validés par le psychologue** :

- coordonnées fixed-point `[0, 1_000_000]`, inset du tracé `160_000` (**0,16**), rayon cible
  `75_000` (**0,075**) et rayon d'activation `37_500` ;
- un tour lent = **7000 ms**, un tour rapide = **3500 ms** ;
- départ au coin supérieur gauche, progression strictement horaire et continue ;
- sources d'entrée déclarées : `MOUSE`, `TOUCH`, `STYLUS`.

La fiche fournie rapproche le jeu de la page publique CogniFit **UPDA-SHIF / Synchronization**,
alors que le paramétrage de suivi continu et les bornes de validité sont rattachés au manuel
**FT&PD / Vienna Test System**. Cette filiation scientifique divergente est documentée sans
revendiquer de norme CogniFit/VTS : le psychologue doit confirmer la référence finale avant toute
interprétation psychométrique. La capacité d'**auto-évaluation** annoncée par la fiche n'est pas
opérationnalisée par le protocole actuel ; seule la coordination visuo-motrice est effectivement
mesurée.

#### Trace brute, recalcul serveur et validité

Le client envoie exactement 14 segments contigus avec phase, vitesse, durée nominale/réelle et
échantillons `(sampleIndex, timestampMs, pointerPresent, pointerX, pointerY)`, plus la source
d'entrée, les drapeaux de complétion/interruption et les compteurs d'arrière-plan/frames perdues.
Il n'envoie **jamais** la position de la balle, l'état vert/orange/rouge, une distance, une précision
agrégée ou un score. Le serveur reconstruit la cible depuis `FIXED_SQUARE_CW_V1`, puis rejoue la
timeline canonique sur une grille de **1 ms** : le pointeur est maintenu entre deux échantillons,
mais la cible continue de se déplacer. Deux positions aux extrémités d'un segment ne peuvent donc
pas simuler un suivi continu :

- pointeur à une distance ≤ rayon de la balle → temps « à l'intérieur » ;
- pointeur absent → temps hors cible et distance canonique **1200** ;
- distance euclidienne / diagonale du plateau, ramenée dans `[0,1200]` ;
- pratique exclue ; précision globale, rapide, lente, segments longs/courts et distance moyenne
  calculées uniquement sur les 12 tests.

`accuracyValid` exige une précision dans `[0,100]` et `executionTimeValid` une durée test dans
`[54 000,58 000]` ms ; `taskValid` est leur conjonction. `technicalValid` exige une session
complète, non interrompue, sans passage en arrière-plan et sans frontière de segment test hors de la
tolérance provisoire de **100 ms** ; `sessionValid` est la conjonction de `taskValid` et
`technicalValid`. Les trous d'échantillonnage et frames perdues restent tracés comme indicateurs
techniques descriptifs, sans figer artificiellement la cible grâce à la grille serveur. Un
run structurellement valide mais non valide pour la mesure reste **audit-only** : aucun `Attempt`,
aucun `GameResultRecordedEvent`, aucun Fit Score ; une structure incompatible avec le protocole est
refusée.

#### Score provisoire et expérience mobile

Le barème remplaçable est isolé dans `CoordinationProvisionalRules` :

```text
overallAccuracyPercent = insideTestDurationMs / totalTestDurationMs × 100
score /100 = roundHalfUp(overallAccuracyPercent)
```

Ce choix a été autorisé par le demandeur, mais reste
`// PROVISOIRE — non validé par le psychologue`. La précision rapide/lente, la précision des
segments longs/courts, la distance moyenne, la durée, les compteurs techniques et la validité sont
**strictement descriptifs**. Aucun temps de réaction, percentile, diagnostic, norme ou classement
n'entre dans le score. Le niveau renvoyé reste neutre : `Descriptive — provisional`.

Le parcours mobile suit la charte existante : cover **Je coordonne**, présentation du format,
tutoriels cible/curseur et trajectoire, pratique lente puis rapide, état Ready, 12 segments mesurés,
sauvegarde puis résultats descriptifs. Le logo PNG transparent **Sync Square** représente les deux
rails carrés, une cible en mouvement, le réticule du pointeur et le sens horaire ; la cover l'affiche
agrandi et sans tuile/cadre intermédiaire, tandis que le hub et le picker réutilisent le même PNG.
Pendant le jeu, la balle traduit seulement la position du
pointeur : blanc + coche verte dans la moitié intérieure, orange dans le reste du rayon, rouge +
croix blanche hors cible. Aucun score live n'est affiché. Une pause/perte de focus pendant un test
actif interrompt localement la mesure et impose de recommencer la phase test : le menu remplace alors
**Reprendre** par **Redémarrer**, tout en conservant Voir les règles et Quitter. Avant activation et
en pratique, Reprendre reste permis. Une interruption locale incomplète n'est pas envoyée comme un
faux payload de 14 segments ; l'audit-only serveur concerne les traces complètes mais techniquement
invalides reçues par l'API.

### 🧠 « Je place » (`OBJECT_LOCATION_BINDING_CORE`) — mémoire objet-emplacement

`VISUOSPATIAL_MEMORY` est un `GameType` autonome, présenté comme deuxième jeu de la catégorie
mobile **Working Memory** sans modifier `MEMORY_QUEST`, son protocole ni son barème. Le protocole
versionné `OBJECT_LOCATION_FINE_V1` utilise une grille **4×4** et un catalogue V1 de 20 objets
modernes en PNG transparent. Le flow est : cover → onboarding ×3 → pratique à 2 objets → ready →
niveaux test de **3, 4, 5, 6, 7 puis 8 objets** → résultats descriptifs. Pour chaque niveau :

1. les objets et leurs emplacements sont visibles pendant `1500 ms × nombre d'objets` ;
2. le plateau reste vide pendant **2000 ms** ;
3. le joueur restaure tous les objets, avec une limite de `4000 ms × nombre d'objets`.

La pratique est auditée mais exclue du score. Les zones de réserve sont fixées par protocole :
pratique dessous ; tests 1→6 = **dessous, gauche, droite, deux côtés, dessous, gauche**. Tap
objet→case est l'entrée principale et le drag reste optionnel. Poser sur une case occupée éjecte
l'objet précédent ; un timeout conserve les omissions. Aucun feedback juste/faux ni score live
n'apparaît pendant les niveaux mesurés.

#### Reconstruction, progression et validité

Le client n'envoie que `phase`, index/charge, durées réellement observées et actions ordonnées
`PLACE`/`RETURN_TO_RESERVE` (`objectId`, case cible éventuelle, timestamp), puis les compteurs
techniques. Le serveur dérive la graine depuis `sessionId|OBJECT_LOCATION_FINE_V1`, reconstruit
catalogue, origines et réserves avec **FNV-1a 32 bits → xorshift32 → Fisher–Yates**, puis rejoue les
actions. Un vecteur golden partagé verrouille la parité Java/Dart ; les origines et la correction ne
figurent jamais dans le payload.

Un niveau est réussi à partir de `ceil(60 % × charge)` placements exacts. Le parcours administre au
moins trois niveaux test, puis s'arrête après deux niveaux échoués consécutifs ou après le niveau 6.
Les cinq catégories sont mutuellement exclusives : `EXACT`, `SWAP`, `LOCAL` (case adjacente),
`GLOBAL`, `UNPLACED`. Leur somme égale toujours le nombre d'objets administrés. Une pause, perte de
focus, rotation ou mise en arrière-plan pendant la mesure invalide le run ; celui-ci est conservé
**audit-only**, sans Attempt ni event, avant un redémarrage depuis le niveau 1. La pratique peut être
gelée/reprise. Les tolérances techniques sont ±100 ms pour encodage/rétention et ±250 ms pour la
limite de rappel ; elles ne donnent aucun point.

#### Score provisoire et intégration

```text
score /100 = roundHalfUp(100 × placements exacts / objets des niveaux TEST terminés)
```

Ce calcul vit uniquement dans `ObjectLocationProvisionalRules` et son miroir mock. Swaps, erreurs
locales/globales, omissions, distance moyenne, repositionnements, intervalle de première pose,
span, pente de charge et temps sont **descriptifs**. Aucun diagnostic, percentile, classement ou
norme clinique n'est produit. Le backend fait autorité et persiste les actions V29. Tant que le
psychologue n'a pas validé le barème et l'intégration, une soumission valide clôt la session et crée
l'Attempt, mais son `GameResultRecordedEvent` est volontairement supprimé : aucun Fit Score ni
Analytics n'est alimenté silencieusement.

**Planifik #3 « Predictive Puzzle » — /10 par niveau** (barème CATÉGORIEL de la fiche — **seule fiche validée « conforme au script »** ; constantes dans `PrevisionPuzzleConfig`)

> 🔴 **Correction majeure** : l'ancienne formule (base 10/4 − pénalités −2/−1/−1 clampée) était **inventée** et non conforme. Elle est **remplacée** par le barème catégoriel du script, calculé **par niveau** puis **agrégé par moyenne arrondie**. Plus de « base 4 » forfaitaire pour un niveau échoué.

*Barème par niveau (Tour de Hanoï) :*
- **Séquence correcte au 1er essai** (`first_try_sequence`, sans retry ni erreur) → **4 pts** sinon **0**
- **Erreurs de séquence** (`sequence_errors`) : 0 → 3 · 1-2 → 2 · ≥3 → 1
- **Mouvements superflus** (`extra_moves`, ratio `(plannedMoves − optimalMoves)/optimalMoves`) : <10 % → 3 · <25 % → 2 · ≥25 % → 1
- **Total niveau** = somme /10 · **Score mini-jeu** = moyenne arrondie des niveaux joués (1 seul `Attempt`)
- Un **niveau échoué** (tolérance dépassée ou plan non complété) est noté sur ses **compteurs réels** — pas de forfait.

*Constantes (`PrevisionPuzzleConfig`) :* `total_pegs`=3 · `optimal_moves(n)=2^n−1` (7/15/31, déterministe, recalculé serveur) · `preview_mode`=true · `post_validation_edit`=false · `extra_moves_detection`=true.
- `puzzle_levels`=**[3,4,5]** disques → ⚠️ **décision produit à valider** (la fiche ne fige pas le nombre de niveaux)
- `max_sequence_errors`=**[3,2,1]** → ⚠️ la fiche dit **3 (constant)** ; le resserrement 3→2→1 est une **décision produit à valider**

> **`global_plan_success`** (succès/échec du plan) reste un **indicateur qualitatif HORS du /10** : exposé dans la réponse (`GameSessionResponse.previsionPuzzleIndicators` → `PrevisionPuzzleReport`), il n'entre pas dans le score. Le mock mobile réplique le barème à l'identique. **Persistance** : score agrégé seul, **pas de migration Flyway**.

- Interprétation mini-jeu (provisoire, partagée, `OptimalPathConfig.MINI_GAME_INTERPRETATION_BANDS`) : 0–3 *Très faible* · 4–6 *Moyen* · 7–10 *Bon à excellent*

### ❤️ « Emotional Radar » (`EMOTIONAL_RADAR_CORE`) — reconnaissance émotionnelle

Cinquième domaine cognitif (« Je gère »). Le candidat observe une scène, identifie la **famille
d'émotion**, précise la **nuance**, puis évalue l'**intensité** sur 5 niveaux.

**Première singularité du module : le contenu vit dans le backend.** Texte, image et vidéo des
scènes sont servis par l'API — aucun autre jeu n'a son matériel hors de l'application.

**Barème par scène — /9** (constantes dans `EmotionalRadarConfig`, carte *Scoring* du handoff)
- **Émotion de base** : famille exacte → **3 pts**, sinon 0 (tout ou rien)
- **Nuance** : nuance exacte → **4 pts**, sinon 0 (tout ou rien)
- **Intensité** : écart 0 → **2 pts** · écart 1 → **1 pt** · écart ≥ 2 → **0**
- **Gradient bonus `+1`** : implémenté mais **désactivé** (`GRADIENT_BONUS_ENABLED = false`)
- Score du mini-jeu = **somme des scènes** ; `maxPoints = scènes jouées × 9` (barème **dynamique**,
  `MiniGame.maxPoints = 0` comme `MOVE_FAST_CORE`)

> **⚠️ Pourquoi le bonus est neutralisé.** L'activer porterait une scène à 10 points et
> contredirait les **deux** totaux affichés par la maquette : 27 (3 scènes) et 135 (15 scènes).
> Le VO `Score` refuse par ailleurs `rawPoints > maxPoints`. Une seule constante (+ son miroir
> mobile) suffit à le réactiver si le psychologue le valide.

#### 🔒 La clé de correction ne quitte jamais le serveur

Les maquettes exigent un feedback **après chaque scène** (émotion attendue, nuance attendue,
intensité suggérée, explication) — ce qui, naïvement, imposerait d'envoyer la réponse au client.
Résolution : **notation par scène côté serveur**.

```
GET  /sessions/{id}/emotional-radar/scenes   → énoncés + médias, AUCUNE réponse
POST /sessions/{id}/emotional-radar/scenes/{sceneId}/answers
                                              → note, PERSISTE, puis renvoie la correction
POST /sessions/{id}/results                   → EmotionalRadarMetrics = temps uniquement
```

`EmotionalRadarMetrics` ne transporte **ni réponse ni point** — seulement ce que le serveur ne peut
pas observer (`responseTimeMs`, `helpOpened`, `fullscreenOpened`, `reducedMotion`). Le score est
reconstruit depuis les `EmotionalRadarAnswer` que le serveur a lui-même notées : **un payload final
falsifié ne peut pas modifier le score** — il n'existe même pas de champ à falsifier.

`EmotionalRadarDtos.SceneResponse.from` est le **point de filtrage unique** : c'est la seule
projection d'une scène vers le client, et elle omet délibérément les quatre champs `expected*` +
`explanation`. Ne jamais y ajouter de champ `expected*`.

#### 📚 Catalogue de scènes & taxonomie

- Port `EmotionalRadarSceneCatalog` (patron `DecisionScenarioCatalog`), impl
  `DatabaseEmotionalRadarSceneCatalog` — contrairement à « Je Décide », elle **n'est pas vide**.
- **3 scènes rédigées** livrées par `V25` (les seules dont le handoff fournit le contenu) :
  1. *Dialogue* — « Friend: I am sorry, I have to cancel tonight. » → **Sadness / Disappointment / 3**
  2. *Text* — « You hear a strange noise at night while alone at home. » → **Fear / Anxiety / 4**
  3. *Image* — « A child cries alone in a quiet courtyard. » → **Sadness / Empathic pain / 3**
     (scène `active = false` tant que son média n'est pas téléversé)
- `TOTAL_SCENES` = **3** aujourd'hui, 15 visées. **Les 12 scènes manquantes ne sont pas inventées.**

> **⚠️ Contradiction Figma tranchée (scène 3).** La table *Phase 2 scene answer data* indique
> `Joy → Triumph → 4` ; les planches *Dark Mode Support*, *Responsive* tablette **et** desktop
> indiquent `Sadness → Empathic pain → 3`, cette dernière précisant « The scene is interpersonal and
> silent. The answer should capture sadness observed in someone else. » **Trois planches
> concordantes + justification textuelle** l'emportent sur la ligne isolée du tableau.

**Taxonomie émotion → nuances** (`EmotionalRadarProvisionalRules`, table `emotional_radar_nuances`) :
chaque nuance porte sa **source**. `FIGMA` = lisible sur une planche, fait autorité —
**SADNESS** en entier (Disappointment, Nostalgia, Empathic pain, Sympathy, Guilt), plus
`FEAR → Anxiety` et `JOY → Excitement/Triumph`. `PROVISIONAL` = sous-catégories d'Ekman ajoutées
faute de taxonomie fournie (ANGER, DISGUST, SURPRISE n'apparaissent sur **aucune** planche alors que
les six familles sont sélectionnables dès l'étape 1). Le moteur ne code jamais ces valeurs en dur.

#### 🖼️ Médias

`GamesMediaStoragePort` + `CloudinaryGamesMediaStorageAdapter` — même patron qu'`identity`
(`FileStoragePort`) et `engagement` (`EngagementMediaStoragePort`), chacun possédant le sien
au-dessus du bean partagé `CloudinaryConfig`. **Aucune dépendance ajoutée, aucun code d'un autre
module appelé.** Dossier distant dédié `zennyt/games/emotional-radar`.

Accessibilité portée par le **domaine**, pas seulement par la DB : `EmotionalRadarScene` refuse une
scène IMAGE/VIDEO sans `mediaUrl` ni `altText`, et une scène VIDEO sans `transcript` (planche
*Accessibility Compliance* : « Scene media needs alt text or text equivalent; future video needs
subtitles/transcript »). Une scène média incomplète reste `active = false` et n'est jamais servie.

#### 🎨 Imperfections de maquette corrigées

| # | Constat | Correction |
|---|---------|------------|
| 1 | Scène 3 : réponse contradictoire entre 4 planches | `Sadness / Empathic pain / 3` |
| 2 | Carte d'échec : « Your answer » affiche `Joy / Excitement / 2` mais « Best answer » omet l'intensité | les deux lignes en `famille / nuance / niveau` |
| 3 | Carte de succès : copie différente en clair (« You identified… ») et en sombre (« The emotional pattern was… ») | voix active du mode clair partout |
| 4 | Le score reste à `Score 0` sur la carte de feedback (il ne passe à 9 qu'à la scène suivante) alors que la planche sombre l'incrémente sur la carte (9 → 18) | mise à jour **dès la validation** |
| 5 | CTA de feedback : « Next scene » en clair, « Continue » en sombre | « Next scene » partout |
| 6 | Hub : le titre « Emotional Regulation » se tronquait en « Emotional R… » | titre réduit pour tenir (`FittedBox`) — passer à la ligne ferait déborder la carte |

### ⏱️ « Reflective Pause » (`REFLECTIVE_PAUSE_CORE`) — contrôle de l'impulsivité

Deuxième mini-jeu du domaine `EMOTIONAL_REGULATION`. Le joueur traverse **10 moments de
pression**, attend un minimum de **3 secondes**, puis choisit naturellement une réponse parmi :
répondre immédiatement, respirer/analyser, attendre, demander plus d'informations ou reformuler
calmement. Aucune correction « bon/mauvais » n'est révélée pendant le parcours.

**Données envoyées par moment** : `momentId`, `selectedResponse`, `responseTimeMs`,
`minimumTimerReached`. Le domaine impose exactement les 10 IDs `PRESSURE_01..10`, sans doublon,
et vérifie `minimumTimerReached == (responseTimeMs >= 3000)`. Le client n'envoie **ni score ni
sous-score**.

**Barème serveur /10** (`ReflectivePauseConfig` + `ReflectivePauseScoringService`) :

- temps de réaction contrôlé = taux de pauses minimales atteint × **3** ;
- réponses non impulsives = taux de réponses autres que `RESPOND_IMPULSIVELY` × **4** ;
- capacité à prendre du recul = taux de réponses recommandées par le content map × **3** ;
- chaque sous-score est arrondi à **0,1**, puis la somme est arrondie **une seule fois** ;
- interprétation : **0–4** Strong impulsivity · **5–7** Good stress management ·
  **8–10** Very good self-control.

Le content map indique pour `PRESSURE_03` « Wait, then reformulate calmly » : `WAIT` et
`REFORMULATE_CALMLY` sont donc toutes deux acceptées comme prise de recul. Ce choix, ainsi que les
poids 3/4/3 et le composite émotionnel provisoire, restent à valider avec le psychologue.

**Session émotionnelle partagée** : le mobile conserve en mémoire la session
`EMOTIONAL_REGULATION` incomplète et la réutilise entre Emotional Radar et Reflective Pause. La
session se complète après les deux tentatives ; avec les 3 scènes Radar actuelles, le composite
est provisoirement **/37** (27 + 10). Le futur mini-jeu Strategic Choices et une normalisation
globale /30 restent différés.

### 🧭 « Je Décide » (`DECISION_CORE`) — moteur définitif + couche provisoire isolée

Prise de décision (fiche « JE DÉCIDE »). Architecture **imposée : deux couches strictement séparées**. Le moteur ne code jamais une valeur provisoire — il la lit dans le seul fichier `DecisionProvisionalRules`. Remplacer le provisoire ne demande **aucune** modification du moteur.

**Couche MOTEUR (définitive — `DecisionConfig` + `DecisionScoringService`)**
- **Structure** : 5 dimensions (`II, ER, DT, CS, RE`), **6 items/dimension**, 30 items notés, item /3, 3 items d'entraînement, ordre des blocs randomisé, mode évaluation, score **jamais** montré au joueur.
- **Agrégation** : dimension = somme des 6 items → **/18** ; brut = somme des 5 dimensions → **/90** ; score agrégé du mini-jeu = **SCW /100** (un seul `Attempt`, `rawPoints=SCW`, `maxPoints=100` ; détail par dimension dans la réponse API).
- **Règle DT** (seule dimension dont le score dépend du temps) : temps imparti effectif = `7 s × multiplicateur_langue + calibration_offset_ms` (**double ajustement** langue puis calibrage, socle `CalibrationService` réutilisé, non modifié). Correct (option OPTIMALE) et latence **< 75 %** → **3** ; correct mais **≥ 75 %** → **2** ; incorrect → **score de qualité de l'option**. Multiplicateurs **fournis** : `en 1.00 · fr 1.20 · de 1.25`.
- **Imputation** : ≤ 2 items manquants dans un bloc → chaque manquant imputé par la **moyenne du bloc** (⇔ moyenne des présents × 6) ; **> 2 → bloc non exploitable** (exclu du SCW, `exploitable=false`).
- **Interprétations automatiques** (textes de la fiche) : SCW ≥ 75 → *fonction décisionnelle élevée* · II bas + CS bas → *difficulté d'analyse et incohérence* · ER élevé + RE bas → *prise de risque sous émotion* · DT élevé → *bonne performance sous pression*.
- **Qualité de session** : `avgTimePlausible`, `impulsiveRateOk`, `randomResponseRateOk`, `deviceLatencyWithinNorm` → `sessionUsable` ; contrôles **renforcés** en mode non supervisé.
- **Indicateurs** : RT moyen/médian/écart-type, `impulsiveResponsePercent`, `slowResponsePercent`, `intraSessionVariability`, `decisionChangesCount`, `averageResponseTimeAdjustedMs`, `dtScoreCalibrationAdjusted` — exposés dans `GameSessionResponse.decisionIndicators`.

**Couche PROVISOIRE (un seul fichier — `DecisionProvisionalRules`, chaque constante `// PROVISOIRE`)**
- **a — mapping option → score par QUALITÉ** (pas par scénario) : enum `OptionQuality` avec les libellés exacts de la fiche — `OPTIMAL→3` (optimal/cohérent) · `SATISFACTORY→2` (satisfaisant/suboptimal) · `PARTIAL→1` (partiel/incohérent) · `DEFICIENT→0` (déficitaire/non pertinent). Le catalogue étiquette **chaque option** d'une qualité, jamais d'un score brut.
- **b — poids SCW = 1.0** pour les 5 dimensions (la fiche dit « pondéré » sans donner les poids) : `scw = (Σ dim×poids)/(18×Σ poids)×100`. Vérifié sur l'exemple validé de la fiche (II=12, ER=9, DT=15, CS=14, RE=10 → raw=60 → **SCW ≈ 66,7**).
- **c — bornes de niveau** (seul ≥ 75 vient de la fiche) : **Élevé ≥ 75** · Normal 60–74 · Borderline 45–59 · Fragile < 45.
- **d — règle CS** (paire liée) : la note dérive de la cohérence entre les deux réponses — cohérentes → OPTIMAL · partielles → SATISFACTORY · contradictoires → DEFICIENT (`coherenceQuality`).
- **e — multiplicateurs es/it/pt** (estimations sectorielles : 1.22 / 1.18 / 1.22) + **fallback `ar`** documenté (1.20, tracé) plutôt qu'un échec.
- Seuils « bas/élevé » par dimension (déclencheurs des interprétations) et seuils de qualité de session : provisoires, isolés ici.

**Catalogue — port injectable** : `DecisionScenarioCatalog` (dimension + format + `OptionQuality` par option). Implémentation vivante **vide** `EmptyDecisionScenarioCatalog` (`// EN ATTENTE DU PSYCHOLOGUE — 30 scénarios + étiquetage`). **Aucun contenu de scénario n'est inventé.** `MiniGame.DECISION_CORE.isPlayable()=false` tant que le catalogue est vide (même patron que `TASK_SCHEDULING` avant implémentation).

**À demander au psychologue pour remplacer le provisoire** : (bloquant) **catalogue des 30 scénarios + étiquetage `OptionQuality` des options** ; poids SCW réels ; bornes de niveau hors ≥ 75 ; multiplicateurs es/it/pt/ar ; échelles post-test fatigue/motivation (et age/educationLevel).

**Détail du score** (`ScoreBreakdownService.decision`) : une ligne par dimension `/18`, puis brut `/90`, puis `SCW /100`. **Parité mock** à répliquer dans `games_mock_repository.dart` (câblage UI → backend = lot séparé ; les écrans `je_decide_*.dart` ne sont pas modifiés).

### 🎯 Socle de calibrage appareil (transversal — Tâche 4)

Méthode **« technique » pure** (fiche « JE BOUGE » Tableau 2 révisé + guide Calibrage_Appareil) : sépare la **latence machine** du **temps de réaction cognitif**. La méthode « hybrid » des autres fiches est **écartée** (mélange latence matérielle et cognition → invalidée).

- **VO `DeviceCalibration`** (optionnel dans `SubmitResultRequest`, ne casse pas les anciens clients) : `inputMode`, `deviceCategory`, `refreshRateHz`, `hardwareConcurrency?`, `deviceMemoryGb?` (absent iOS), `inputProcessingLatencyMs?`.
- `displayLatencyMs = (1000 / refreshRateHz) / 2` · `calibrationOffsetMs = displayLatencyMs + inputProcessingLatencyMs` (calculés serveur).
- **Fallback** (guide §5) : si la mesure directe est indisponible → `calibrationMethod = "hardware_profile_fallback"` (profil matériel seul, `inputProcessingLatencyMs` absent) → session marquée **fiabilité réduite** (`reducedReliability`, `calibrationReliable=false`).
- **Application** : les **temps bruts restent stockés tels quels** ; la correction s'applique **au calcul** — `reactionTimeAdjustedMs = reactionTimeMs − calibrationOffsetMs`. Pour Move Fast, `MoveFastFlexibilityReport` expose les indicateurs bruts **et** `*Adjusted` (moyenne, médiane, fast/slow %, switch cost — l'offset s'annule dans une différence, donc `switchCostAdjusted == switchCost`).
- **Le score Move Fast ne dépend PAS du temps** (justesse × multiplicateur) → le calibrage n'affecte QUE les indicateurs comportementaux. `CalibrationService` (`offsetMs`/`adjust`) est conçu pour être **réutilisé quand un score dépendra du temps** (Decision/DT, Memory Quest/timeout).
- **Les essais d'échauffement (Tâche 1.D) ne servent JAMAIS au calibrage** — l'offset est purement technique (niveau appareil).
- **Mobile** : `DeviceCalibrationProbe` détecte `refreshRate`/cœurs/catégorie et mesure la latence machine « entrée → frame » hors échauffement ; fallback si aucune mesure.

### 🧾 Détail du score — panneau de résultats (« logs du back »)

À la fin de chaque jeu, un panneau montre **d'où viennent les points**, ligne par ligne comme une addition. **Calculé côté serveur** (`ScoreBreakdownService`) à partir des **mêmes métriques et du même barème** que le score — le client ne recalcule rien, n'invente aucun barème, il **affiche** juste (`ScoreDetailPanel`, style console). Exposé dans `GameSessionResponse.scoreBreakdown` ; **le mock reproduit les lignes à l'identique** (`_buildBreakdown`) pour marcher hors-ligne.

- **Move Fast** — escalade : `Bonnes réponses`, `Multiplicateur atteint (×n)`, `Points de jeu`, `Bonus de fin (×n × 250)`, `Total`. Note : « chaque bonne réponse = 50 × multiplicateur ; +1 au multiplicateur toutes les 4 bonnes réponses d'affilée ».
- **Optimal Path** — par niveau puis moyenne : `Chemin optimal (±10 %)` /4 · `Essais` /3 · `Zones coûteuses évitées` /2 · `Objectif secondaire` /1 · `Niveau = X/10` → `Moyenne des N niveaux : X/10`.
- **Predictive Puzzle** — par niveau puis moyenne : `Réussi du 1er coup` /4 · `Erreurs de séquence` /3 · `Coups superflus` /3 · `Niveau = X/10` → `Moyenne des N niveaux : X/10`.
- **Reflective Pause** — `Controlled reaction time` /3 · `Non-impulsive responses` /4 · `Ability to step back` /3 → `Total /10`.
- **Je continue** — note explicative · `X_TEST — balanced accuracy` · `AX_TEST — balanced accuracy` · `Validité technique` · `Score descriptif /100`. Le mock mobile reproduit exactement ces cinq lignes, y compris pour un run audit-only invalide.
- **Je coordonne** — note provisoire · `Précision globale` · précisions `Lente`/`Rapide` et `Segments longs`/`Segments courts` marquées descriptives · `Distance moyenne` · `Validité de la tâche` · `Score descriptif /100`. Seule la précision globale arrondie produit des points ; le mock reproduit le même rapport.
- **Je place** — note provisoire · `Placements exacts` · `Niveaux terminés` · swaps/erreurs/omissions marqués descriptifs · `Validité de la session` · `Score descriptif /100`. Seule l'exactitude globale produit des points ; le mock rejoue les mêmes actions et le même layout déterministe.

Chaque critère affiche la **valeur mesurée entre parenthèses** et les **points/max**. Libellés fidèles aux barèmes ci-dessus. La décomposition Move Fast (points de jeu vs bonus) provient de `MoveFastConfig.replay` — même source que le score.

### Schéma DB (`V9__games_schema.sql`, `V11__games_device_calibrations.sql`, `V12__games_memory_quest_minigame.sql`, `V24__games_decision_minigame.sql`, `V26__games_reflective_pause_minigame.sql`, `V27__games_continuous_attention.sql`, `V28__games_visuomotor_coordination.sql`, `V29__games_object_location_memory.sql`)

- `games.game_sessions` : `id`, `player_id`, `game_type`, `status`, `started_at`, `completed_at` + `CHECK` sur type/status, index `(player_id)` et `(game_type, status)`.
- **V12** (« J'investigue ») : la contrainte `ck_game_attempts_mini_game` autorise désormais `MEMORY_QUEST_CORE` (aucune nouvelle table — le composite est un `Attempt` /100).
- **V24** (« Je Décide ») : la contrainte `ck_game_attempts_mini_game` autorise désormais `DECISION_CORE` (aucune nouvelle table — le SCW est un `Attempt` /100 ; `DECISION` était déjà autorisé au niveau session par V9).
- **V26** (« Reflective Pause ») : la contrainte `ck_game_attempts_mini_game` autorise désormais `REFLECTIVE_PAUSE_CORE` (aucune nouvelle table — score agrégé /10).
- **V27** (« Je continue ») : autorise `CONTINUOUS_ATTENTION` / `CONTINUOUS_ATTENTION_CORE`, crée une ligne `continuous_attention_runs` par session et 1 364 lignes `continuous_attention_trials` pour l'audit. Une capture techniquement invalide peut être remplacée par un retry ; seul un run valide crée un `Attempt`. L'index partiel `ux_ca_single_valid_attempt` protège la soumission valide concurrente.
- **V28** (« Je coordonne ») : autorise `VISUOMOTOR_COORDINATION` / `COORDINATION_TRACKING_CORE`, puis crée `coordination_tracking_runs`, `coordination_tracking_segments` et `coordination_tracking_samples` pour conserver la trace brute et les indicateurs serveur. Un run audit-only peut être remplacé ; l'index partiel `ux_coord_single_valid_attempt` interdit deux soumissions valides pour la même session.
- **V29** (« Je place ») : autorise `VISUOSPATIAL_MEMORY` / `OBJECT_LOCATION_BINDING_CORE`, puis crée `object_location_runs`, `object_location_levels` et `object_location_actions`. Le serveur conserve le rapport dérivé et les actions brutes, tandis que le layout reste reconstructible par `sessionId` + version de protocole. Un run audit-only peut être remplacé ; l'index partiel `ux_object_location_single_valid_attempt` protège l'unique Attempt valide.
- `games.device_calibrations` (**V11**, Tâche 4) : PK/FK `session_id` (au plus un calibrage/session), `calibration_method`, `input_mode`, `device_category`, `refresh_rate_hz`, `hardware_concurrency?`, `device_memory_gb?`, `input_processing_latency_ms?`, `display_latency_ms`, `calibration_offset_ms`, `reduced_reliability` + `CHECK` sur méthode/mode/catégorie. **Les temps bruts ne sont pas modifiés** : la table conserve le profil + l'offset pour audit.
- `games.game_attempts` : `session_id` (FK CASCADE), `mini_game`, `raw_points`, `max_points`, `level`, `recorded_at` + `CHECK` mini_game/points, index `(session_id)`.

---

## 📱 MOBILE — Feature `games` (Flutter + Flame)

Racine : `mobile/lib/features/games/` — **Clean Architecture** (domain / data / presentation).
Routage : `mobile/lib/core/router/app_router.dart` (`/games`, `/games/planifik`, `/games/move-fast`,
`/games/predictive-puzzle`, `/games/je-decide`, `/games/emotional-radar`,
`/games/reflective-pause`, `/games/je-continue`, `/games/je-coordonne`, `/games/je-place`).
`/games` ouvre le shell `MainNavigationScreen(initialTab: 2)` afin de conserver la bottom nav
sur l'onglet Careers/Progress ; les routes de jeu restent plein écran.

### Arborescence & rôle de chaque fichier

| Couche | Fichier | Rôle |
|--------|---------|------|
| **domain / entities** | `domain/entities/game_type.dart` | Enum + `wire` (aligné contrat). |
| | `domain/entities/mini_game.dart` | Enum mini-jeux + `wire`. |
| | `domain/entities/game_metrics.dart` | Interface `GameMetrics` (`toJson`). |
| | `domain/entities/planifik_metrics.dart` | Métriques « Chemin Optimal ». |
| | `domain/entities/move_fast_metrics.dart` | Métriques « Je bouge ». |
| | `domain/entities/prevision_puzzle_metrics.dart` | Métriques « Predictive Puzzle » envoyées au backend/mock. |
| | `domain/entities/reflective_pause_metrics.dart` | Réponses/timings bruts Reflective Pause + indicateurs serveur ; sérialise `reflectivePauseMoments`. |
| | `domain/config/reflective_pause_config.dart` | Miroir exact de `ReflectivePauseConfig.java` pour le mode mock (3/4/3, content map, bandes). |
| | `domain/entities/continuous_attention_metrics.dart` | Blocs/essais bruts « Je continue », enums de phase/input et indicateurs descriptifs serveur ; listes immuables et sérialisation conforme au contrat. |
| | `domain/config/continuous_attention_config.dart` | Miroir exact de `ContinuousAttentionConfig.java` : génération déterministe, timings, compteurs et golden vector cross-platform. |
| | `domain/config/continuous_attention_provisional_rules.dart` | Miroir du score provisoire ; même calcul rationnel entier et même arrondi que Java. |
| | `domain/entities/coordination_tracking_metrics.dart` | Trace brute « Je coordonne » : échantillons normalisés, 14 segments, source d'entrée et indicateurs descriptifs serveur ; sérialisation conforme au contrat. |
| | `domain/config/coordination_tracking_config.dart` | Miroir pur Dart de `FIXED_SQUARE_CW_V1` : même timeline, même géométrie, même reconstruction de trajectoire et même distance canonique que Java. |
| | `domain/entities/object_location_metrics.dart` | Niveaux/actions bruts « Je place » et rapport descriptif serveur ; aucune origine, correction ou note dans la requête. |
| | `domain/config/object_location_config.dart` | Miroir pur Dart de `OBJECT_LOCATION_FINE_V1`, catalogue d'assets et générateur déterministe identique à Java avec vecteur golden partagé. |
| | `domain/entities/game_score.dart` | Score noté (immuable). |
| | `domain/entities/game_session.dart` | `GameSession` + `GameAttempt` (miroir de l'agrégat backend). |
| **domain / repo** | `domain/repositories/games_repository.dart` | Port : `startSession`, `submitResult`. |
| **data** | `data/decision_progress_store.dart` | Checkpoint local « Je Décide » : conserve uniquement le point de reprise ; les choix individuels ne sont pas persistés. |
| | `data/dtos/game_session_dto.dart` | Parse la réponse API → entité domaine. |
| | `data/games_repository_impl.dart` | Impl **Dio** → `/api/v1/games`. Convertit erreurs en `ApiException`. |
| | `data/games_mock_repository.dart` | Impl **MOCK** en mémoire : reproduit le barème serveur → jouable **sans backend**. |
| | `data/continuous_attention_scoring.dart` | Miroir offline du validateur/scorer serveur : séquence, correction, indicateurs, audit-only et breakdown canonique. Le backend reste autoritatif en mode API. |
| | `data/coordination_tracking_scoring.dart` | Miroir offline de la reconstruction/notation serveur « Je coordonne » ; parité des précisions, distance, validité, score half-up et breakdown. Le backend reste autoritatif en mode API. |
| | `data/object_location_scoring.dart` | Miroir offline du rejeu, de la classification exclusive, de la progression/validité et du score provisoire. Le backend reste autoritatif en mode API. |
| **Emotional Radar** | `domain/entities/emotional_radar.dart` | Entités : `BasicEmotion`, `SceneMediaType`, `EmotionalNuance` (+ `NuanceSource`), `EmotionalRadarScene` (**sans** réponse attendue), `SceneSet`, `Feedback`, `Metrics`. |
| | `domain/config/emotional_radar_config.dart` | **Miroir Dart du barème** (3/4/2, dégradé, bonus off, libellés d'intensité, bandes). Parité backend. |
| | `domain/config/emotional_radar_provisional_rules.dart` | **Miroir de la taxonomie** — `FIGMA` vs `PROVISIONAL`. |
| | `presentation/view/emotional_radar_screen.dart` | Machine d'états `cover → tutorial → gameplay → feedback → transition → results` + pause / aide / plein écran / erreur. |
| | `presentation/view/emotional_radar_gameplay.dart` | `SceneCard` (média + équivalent textuel voisin), `AnswerPanel` (révélation progressive), `FeedbackCard`. |
| | `presentation/widgets/emotional_radar_components.dart` | Boutons d'émotion, chips de nuance, sélecteur d'intensité, étapes verrouillées/validées, palette — cibles ≥ 48 px, jamais de sens porté par la couleur seule. |
| **Reflective Pause** | `presentation/view/reflective_pause_screen.dart` | Flow complet `cover → intro → tutorial → 10 moments → saved → results → insights`, timer 3 s, métriques brutes seulement. |
| | `presentation/emotional_regulation_session_provider.dart` | Réutilise la même session `EMOTIONAL_REGULATION` entre Radar et Reflective, sans permettre deux tentatives identiques. |
| | `presentation/widgets/emotional_game_pause_dialog.dart` | Menu pause commun Radar/Reflective : reprise, règles/aide, sortie, mode d'entrée et audio. |
| **Je continue** | `presentation/view/continuous_attention_screen.dart` | Parcours complet `cover → règles → tutoriels X/AX → pratiques → 20 blocs X → repos 2 min → 20 blocs AX → envoi → résultats/insights`. Tempo absolu 690/230 ms, clavier/espace + tactile, aucune correction pendant les tests. |
| | `presentation/widgets/continuous_attention_pause_dialog.dart` | Pause/règles/sortie ; une interruption pendant une phase test impose le redémarrage de cette phase afin de ne pas fausser la vigilance mesurée. |
| | `assets/04 Je Continue Logo Options/` | Explorations non intégrées V1 + V2 de logos PNG transparents, planches comparatives et prompts. La série V2 professionnelle contient `AX Ligature`, `Focus Gate`, `Signal Ribbon` et `Dual Phase`. Le logo actif `assets/games icons/Je Continue.png` reste inchangé jusqu'à validation produit. |
| | `test/features/games/presentation/continuous_attention_screen_test.dart` | Parcours 44 blocs/1 364 essais, pause/règles/restart, retour système, audit invalide puis retry sur le même `sessionId`, résultats et accessibilité 390×844 jusqu'à 200 %. |
| **Je coordonne** | `presentation/view/coordination_tracking_screen.dart` | Parcours complet `cover → onboarding 3 pages → pratique lente/rapide → ready → 12 segments test → sauvegarde → résultat/retry`. Ticker absolu, plateau custom, pointeur souris/touch/stylus, aucun score live ; réutilise le menu de pause mesurée et son dialogue de règles dédié. |
| | `test/features/games/domain/coordination_tracking_config_test.dart` | Vecteurs de trajectoire/timeline Dart et constantes de parité `FIXED_SQUARE_CW_V1`. |
| | `test/features/games/data/coordination_tracking_scoring_test.dart` | Score half-up, précisions/distance, validité et parité du mock avec le backend. |
| | `test/features/games/presentation/coordination_tracking_screen_test.dart` | Flow cover→résultat, activation, pratique/test, pause/règles/restart, payload 14 segments et copie non diagnostique. |
| **Je place** | `presentation/view/je_place_screen.dart` | Parcours complet `cover → onboarding ×3 → pratique → ready → 3–8 objets → résultat`, timers monotones à échéances absolues, plateau 4×4 mauve responsive, tap/drag, aucun feedback mesuré ni score client. |
| | `presentation/widgets/je_place_pause_dialog.dart` | Pratique gelable/reprenable ; une pause mesurée persiste d'abord l'audit technique puis permet le redémarrage du run, avec règles et sortie. |
| | `assets/games icons/Je Place.png` · `Je Place Object 01.png`…`20.png` | Logo et catalogue PNG 512×512 RGBA transparent, style Zennyt flat 2.5D, contrôlés à 48 px. |
| | `test/features/games/domain/object_location_config_test.dart` | Constantes, zones de réserve et vecteur golden déterministe partagé avec Java. |
| | `test/features/games/data/object_location_scoring_test.dart` | Rejeu, classification exclusive, score/validité, progression et rejets identiques au backend. |
| | `test/features/games/presentation/je_place_screen_test.dart` | Flow, payload brut, pause/audit/retry, accessibilité et non-débordement 390×844 / texte 200 %. |
| **presentation** | `presentation/games_providers.dart` | Bascule mock/backend via `--dart-define=GAMES_MOCK` (défaut `true`). |
| | `presentation/games_controller.dart` | `AsyncNotifier<GameSession?>` : `start()` / `submit()`. |
| | `presentation/view/games_hub_screen.dart` | Hub jeux style maquette Progress : header « Play & discover your talent », 5 cartes de domaines cognitifs, illustration de catégorie + logos PNG officiels des jeux (`assets/games icons/`) ; le picker multi-jeux réutilise les mêmes images. `Cognitive Flexibility` propose Move Fast + Je continue + Je coordonne ; `Working Memory` propose Memory Quest + Je place, sans renommer les catégories. |
| | `presentation/view/je_decide_screen.dart` | **« Je Décide » Phases 1–4** : machine d'états du welcome au profil final, restauration automatique d'un checkpoint local. UI uniquement, sans session backend. |
| | `presentation/view/je_decide_gameplay.dart` | Gameplay **Phases 2–3** : scénarios représentatifs, timer DT 7 s, paire CS, feedback XP, encouragement, badge/dimension, checkpoint, pause/règles et sauvegarde/reprise. XP visuel uniquement ; aucun score calculé. |
| | `presentation/view/je_decide_results.dart` | Résultats **Phase 4** : fin de parcours, préparation, radar accessible, score-ring/forces/axe de progression/détails et export-partage placeholder. Valeurs strictement issues de la maquette et marquées `DecisionProfilePreview`, jamais calculées depuis les choix. |
| | `presentation/view/planifik_screen.dart` | Flow complet **Optimal Path** (intro Path Mind, How To Play, gameplay **multi-niveaux**, score, comparaison) + HUD stations, **menu pause** (`_PauseDialog`), légende, contrôles + bouton « Continue to scheduling » (→ Planifik #2). Voir [Flow Optimal Path](#-flow-optimal-path-mobile). |
| | `presentation/view/task_scheduling_screen.dart` | **Planifik #2 « Ordonnancement de tâches »** : tap-to-place d'un lot de tâches (dépendances + échéances affichées), mesure (deps/horaires/cohérence/réajustements), soumet via le repo, `ScoreDetailPanel`, enchaîne vers #3. |
| | `presentation/view/move_fast_screen.dart` | Écran complet « Je bouge » (intro, tutoriels, gameplay **niveau unique à règle aléatoire**, résultats). Voir [Niveau Move Fast](#-niveau-move-fast-mobile). |
| | `presentation/view/predictive_puzzle_screen.dart` | Écran complet **Predictive Puzzle** : intro, règles, planification Tower of Hanoi, exécution auto, résultats, comparaison. Voir [Flow Predictive Puzzle](#-flow-predictive-puzzle-mobile). |
| | `presentation/widgets/game_system_components.dart` | Design system jeux : palette, boutons, HUD, ruban de séries, contrôles directionnels, avion, tuiles de résultat. |
| **presentation / flame** | `presentation/flame/planifik_game.dart` | **`FlameGame`** stations : tracé, `undo`/`clear`, `revision` (HUD live), ligne de route magenta, `buildLevelMetrics()` (métriques par niveau), layout col×row remplissant. Ne calcule **pas** de score. |
| | `presentation/flame/cell_component.dart` | Station **circulaire** tactile + `BoardPalette` : LAB, MTG, bloc (éclair), étoile, chemin. |
| | `presentation/flame/grid_config.dart` | `CellKind` + `GridConfig` + générateur `GridConfig.randomLevels()` : graphes de grille solvables par BFS, difficulté croissante, fallback déterministe `levels`. |

### Le jeu Flame « Chemin Optimal » (`planifik_game.dart`)

- Grille indexée `row * cols + col`, cellules `start / end / obstacle / costly / objective / normal`.
- Le joueur touche des cases **adjacentes** depuis le départ ; retoucher la dernière case = annuler.
- `canValidate` (`ValueNotifier<bool>`) passe `true` quand le chemin atteint l'arrivée.
- `buildLevelMetrics({levelIndex, attempts})` produit un `PlanifikLevelMetrics` du niveau courant :
  `pathLength`, `optimalLength`, `costlyZonesAvoided` (TOTAL/NONE — le Flame ne connaît que le binaire),
  `secondaryObjectivesReached` (YES/PARTIAL/NO) — **jamais de score** (calculé serveur/mock).
- **Cumul multi-niveaux** : l'écran accumule un `PlanifikLevelMetrics` par niveau (`_levelMetrics`,
  essais = mauvaises routes + 1) et soumet **un seul** `PlanifikMetrics { levels }` au dernier niveau.
- Découplé de Riverpod : le jeu n'appelle aucun provider ; l'écran lit `canValidate` / `buildLevelMetrics`.

### Hub Games / Progress (`games_hub_screen.dart`)

Le hub n'est plus une liste `ListTile` générique. Il suit la maquette fournie :

- Header : bouton retour carré, titre centré **« Play & discover your talent »**, avatar/menu à droite.
- Indicateur **Coverage 0%** en magenta.
- 5 cartes bordées bleu : Cognitive Flexibility, Working Memory, Decision-Making,
  Executive Planning, Emotional Regulation.
- Chaque carte affiche : titre + chevron, **logos PNG officiels des jeux réellement disponibles**
  (Move Fast + Je continue + Je coordonne pour Cognitive Flexibility, Memory Quest + Je place pour Working Memory, un pour Je Décide,
  trois pour Planifik), durée du domaine,
  `N° aptitudes`, illustration PNG. Les anciennes swatches décoratives ont été supprimées.
- Le bottom sheet d'une catégorie multi-jeux reprend le **même fichier image** pour chaque entrée
  afin de conserver l'identité visuelle entre le hub et le sélecteur. Les logos historiques
  proviennent des couvertures officielles fournies :
  `Move Fast.png`, `Memory Quest.png`, `Je Decide.png`, `Optimal Path.png`,
  `Task Scheduling.png`, `Predictive Puzzle.png`, `Je Place.png`. `Je Continue.png` est une illustration nette à
  fond transparent fondée sur le concept A→X/focus ; `Je Coordonne.png` reprend le concept original
  **Sync Square** (rails carrés, cible, réticule et sens horaire), net et sans carré violet.
- Assets déclarés dans `mobile/pubspec.yaml` :
  `assets/04 Optimal Path/` (`image 120.png`, `image 120-1.png`, `image 121.png`,
  `image 121-1.png`, `image 121-2.png`) **et** `assets/04 Predictive Puzzle/`
  (`discs.png` = disques de la carte intro, `golden_rule.png` = illustration règle d'or How-To-Play),
  ainsi que les sous-dossiers utilisés de `assets/04 Je Décide/`.
- Routes actives : Cognitive Flexibility → sélecteur Move Fast (`/games/move-fast`),
  Je continue (`/games/je-continue`) ou Je coordonne (`/games/je-coordonne`), Working Memory →
  sélecteur Memory Quest (`/games/investigate`) ou Je place (`/games/je-place`), Decision-Making → `/games/je-decide`, Executive Planning →
  menu de sélection des 3 mini-jeux Planifik, Emotional Regulation → sélecteur Radar/Reflective.

Navigation : `ProgressScreen` héberge `GamesHubScreen`. La route `/games` rend
`MainNavigationScreen(initialTab: 2)`, et `AppBottomNav` accepte un `selectedTab` local afin
d'afficher l'onglet Careers/Progress sans modifier `navTabProvider` pendant `initState`.

### 🎯 Flow « Je coordonne » (mobile)

`coordination_tracking_screen.dart` est un écran Flutter custom autonome, sans dépendance Flame.
Sa machine d'états est :

`cover → starting → tutorial ×3 → practice → ready → test → submitting → results`

avec branches `invalid → restart test` et `error → retry submission/journey`. Le cover présente
le PNG **Sync Square** agrandi sans cadre, l'objectif, la durée catalogue et le format ; les trois
tutoriels utilisent des démonstrations mauves dédiées pour le déclenchement, les trois états du
cercle et l'alternance de vitesse. La pratique enchaîne
les deux segments de 7 s, puis l'écran Ready annonce les 12 segments et l'absence de score live.

- **Plateau** : fond gameplay partagé `ZennytGamePalette.gameBlue` (`#4E46E8`) et surface mauve
  `gamePanel` (`#675DE6`), comme Move Fast et Je continue ; double rail carré blanc, cible
  orange/blanche/rouge avec halo/contour et réticule à quatre lignes + point central. Les objets
  restent dessinés avec `CustomPainter` pour être nets à toute densité ; aucun raster flou dans le
  gameplay.
- **Tempo** : `Ticker` basé sur un timestamp absolu ; le rendu ne somme jamais les deltas de frame.
  La vitesse peut changer sans saut de position ni easing. Le HUD affiche seulement segment,
  allure, temps restant et progression — jamais précision ni points.
- **Entrée** : `Listener` + `MouseRegion` unifient souris/trackpad, touch et stylus ; les coordonnées
  sont normalisées puis converties en fixed-point contractuel. La modalité n'est verrouillée
  qu'après une activation réussie dans le demi-rayon, puis ne peut plus changer au milieu du run ;
  le test d'activation utilise la même distance entière au carré que le recalcul serveur.
- **Pause/retour système** : la pratique peut être suspendue ; pendant le test, pause, perte de
  focus ou changement de zone de jeu interrompt la mesure et conduit à `invalid`, avec redémarrage
  depuis le segment test 1 dans la même session. La reprise réactive bien le ticker d'une pratique
  gelée ; elle ne peut jamais relancer un ticker de test interrompu. Un changement de métriques
  n'invalide la mesure que si la taille physique de la vue change. Le menu propose reprise lorsque
  permise, règles, redémarrage et sortie.
- **Résultats** : cadran explicitement **PROVISIONAL /100**, précision globale, lente/rapide,
  longue/courte et distance moyenne ; copie « descriptive, not a diagnosis or ranking », puis retour
  au hub ou nouvelle partie.
- **Accessibilité** : statut doublé par icône + texte, légende non portée par la couleur seule,
  sémantique du plateau calme (pas d'annonce à chaque frame), texte adaptable et animation des
  dots neutralisée en reduced motion.

### 🧠 Flow « Je place » (mobile)

`je_place_screen.dart` est une machine d'états autonome :

`cover → starting → onboarding ×3 → practice encode/retain/recall → feedback → ready → levels 1–6 → submitting → results`

avec branches `invalid → retry audit/restart` et `error → retry`. Le cover utilise le logo PNG
transparent sans cadre parasite et les composants partagés `GamePanel`/`GamePrimaryButton`. Le
gameplay adopte le fond mauve `gameBlue`, un panneau `gamePanel`, un HUD neutre (phase, niveau,
charge, temps, progression) et une grille responsive ; il reste scrollable aux petites hauteurs et
au texte agrandi. Les objets 2.5D sont chargés en haute qualité, avec repli vectoriel uniquement en
cas d'asset absent.

- **Interaction** : sélectionner un objet puis une case constitue le chemin accessible principal ;
  drag-and-drop reste un raccourci. Les 16 cases ont des libellés sémantiques et l'état sélectionné
  n'est pas porté seulement par la couleur.
- **Tempo** : chaque phase possède un `Stopwatch` monotone et une échéance absolue ; les ticks UI
  n'entrent pas dans le calcul. Les durées réelles sont envoyées, jamais remplacées par les durées
  nominales.
- **Pause** : pratique = clock figé puis Resume ; test = snapshot incomplet et soumission
  `TECHNICAL_INTERRUPTION` attendue avant Restart/Exit. Une erreur réseau conserve l'intention et
  retente d'abord l'audit. Le retry garde le même `sessionId`, sans Attempt ni score pour le run
  interrompu.
- **Résultats** : score marqué **PROVISIONAL /100**, exactitude globale et statistiques
  descriptives, copie explicitement non diagnostique/non comparative, puis retour au hub ou replay.
- **Responsive/accessibilité** : reduced motion neutralise les transitions décoratives ; le layout
  390×844 avec texte 200 %, la réserve bilatérale et la charge 8 sont couverts par les tests widget.

### 🗺️ Flow Optimal Path (mobile)

`planifik_screen.dart` est un flow multi-étapes (comme Move Fast), aligné sur les maquettes
Figma **« Optimal Path »**. `enum _PlanifikStage { intro, howToPlay, gameplay, score, comparison }`.

| Étape | Contenu |
|-------|---------|
| **Intro (Path Mind)** | Écran **pixel-perfect** : carte hero violet plein `#4F46E5` (illustration grille `_PathMindArt` + cercles de fond roses/cyan/violets en overflow hors carte), chip « Spatial Planning », 3 mini-cartes meta (Goal/Duration/Format), carte « Simple rule » (bordure périwinkle), **bouton capsule Start**. Marges 24, gaps 20/18/16/22, ombres douces, top-aligné. |
| **How To Play** | Carousel 2 pages (PageView) : « Connect the Stations » (illustration `_StationsArt`) et « Scoring Breakdown » (barème tutoriel). |
| **Gameplay (multi-niveaux)** | Fond violet, **HUD** (Score/Timer/Tries + Pause) + barre de progression, **plateau de stations circulaires** (`GameWidget`), bannière **Correct!/Wrong route!**, légende Start/Goal/Block/★/Path, boutons **Clear / Validate route**. |
| **Score** | Même structure visuelle que Move Fast : titre Results, carte bleue **Cognitive score**, 3 tuiles de stats, panneau Summary insight, puis **Score breakdown panel** (barème reconstruit : chemin optimal 4pts, essais 3pts, zones coûteuses 2pts, bonus 1pt). |
| **Comparison** | Même structure visuelle que Move Fast : titre Comparative Results, carte bleue benchmark/ranking, grille 2×2 de stats, panneau Performance evolution + CTA Replay. |

**🎚️ Niveaux progressifs randomisés** (`GridConfig.randomLevels()`) : une nouvelle séquence de 4
cartes est générée à chaque Start/Replay. Le générateur construit des graphes de grille, place
départ/arrivée/obstacles, résout chaque candidat par **BFS** et ne garde que les cartes solvables
dont le plus court chemin devient progressivement plus long, plus tortueux et plus contraint.
Le joueur enchaîne niveau 1 → 4 ; une route correcte (**+250**) fait passer au niveau suivant,
une route incomplète donne **−2** et « Wrong route! ». Au dernier niveau → soumission backend +
écran Score. Chaque niveau recrée un plateau frais (`key: ValueKey(_level)`).

| Niveau | Génération | Contraintes principales |
|--------|------------|-------------------------|
| 1 | 5×6 | court chemin cible 8–12, faible densité d'obstacles, 1 objectif, 2 zones coûteuses |
| 2 | 6×6 | chemin cible 10–15, plus de détours/tournants, 1 objectif, 3 zones coûteuses |
| 3 | 6×7 | chemin cible 12–18, densité supérieure, 2 objectifs, 4 zones coûteuses |
| 4 | 8×8 | chemin cible 17–30, expert, plus de décisions, 2 objectifs, 5 zones coûteuses |

`GridConfig.levels` (`level1`…`level4`) reste présent comme suite de secours déterministe
pour previews/tests figés, mais le gameplay utilise `_levelConfigs = GridConfig.randomLevels()`.

**⏸️ Menu pause** (`_PauseDialog`, calqué sur Move Fast) : stats **Time / Attempts**, options
audio (Sound effects / Music), **Resume** (magenta) / **View rules** (`_OptimalRulesDialog`) /
**Exit mission** (rouge). Le timer se met en pause pendant le dialogue.

**Charte couleurs du plateau** (`BoardPalette`) : LAB (départ) = cercle blanc + anneau bleu,
MTG (arrivée) = vert `#22C55E`, bloc (éclair) = rouge `#E8574C`, étoile = doré `#F5B800`,
station = cyan clair `#CDEBF5`, ligne de route = magenta `#D12E7D`.

> Le **backend est inchangé** : `OPTIMAL_PATH` + `scoreOptimalPath` existent déjà. Le score breakdown
> mobile **reconstruit** le barème à partir des `PlanifikMetrics` pour l'afficher (le serveur ne
> renvoie que `rawPoints/maxPoints/level`).

### 🧩 Flow Predictive Puzzle (mobile)

`predictive_puzzle_screen.dart` implémente le mini-jeu Planifik #3, d'après les maquettes
`04 Predictive Puzzle`. Le joueur doit planifier la séquence complète avant de lancer l'exécution :
la phase de planning et la phase machine sont strictement séparées.

| Étape | Contenu |
|-------|---------|
| **Intro** | Carte hero violette, chip « Predictive Reasoning », titre « Predictive Puzzle », metas Goal/Duration/Format, règle simple et CTA Start. Illustration de la carte = PNG Figma `assets/04 Predictive Puzzle/discs.png` (positionnée dans le `Stack`, sans peinture custom). |
| **How To Play** | Deux pages : règle d'or Tower of Hanoi (jamais un grand disque sur un petit) illustrée par le PNG Figma `assets/04 Predictive Puzzle/golden_rule.png` ; puis « Plan before you act » (séquence de mouvements planifiés, hauteur adaptée au contenu). |
| **Planning** | Fond violet, HUD Timer/Moves/Errors, trois tours A/B/C, feedback source → destination, queue horizontale de mouvements, Undo/Clear/Add Move. |
| **Auto Run** | Les contrôles sont désactivés ; la machine rejoue la queue avec un tick régulier et marque le premier `failed_step_index` visuel. |
| **Results / Comparison** | Même structure que les jeux précédents : score cognitif, tuile **Levels** (niveaux réussis), tuiles stats, résumé, benchmark optimal cumulé (`Σ 2^n − 1`), CTA Replay. |

**🎚️ Niveaux progressifs** (`_puzzleLevels`) : une session enchaîne **3 niveaux de difficulté
croissante par nombre de disques** — L1 = 3 disques, L2 = 4, L3 = 5. La Tour de Hanoï standard
étant toujours résoluble, l'optimal est **déterministe et fermé** : `2^n − 1` (soit 7 → 15 → 31),
aucun BFS nécessaire (contrairement à Optimal Path). La tolérance d'erreurs se resserre par palier
(3 → 2 → 1). Le plateau (`_TowerView`) dimensionne les disques de façon responsive (`LayoutBuilder`)
pour que 5 disques tiennent proprement, et `_Disc._colors` couvre les disques 1–5.

Logique runtime :

- `selected_source != null` active la sélection de destination.
- `is_legal_move(source, destination)` queue un mouvement valide et met à jour l'état de planning.
- Un mouvement illégal reste visible dans la queue, incrémente `sequenceErrors`, puis fait échouer
  l'exécution au moment du Run.
- `queued_moves.length > 0` et pile cible complète (`C = [n, …, 2, 1]` pour le niveau courant)
  activent **Run Plan**.
- `execution_state == running` désactive les tours et les boutons de planification.
- Un **Run réussi** sur un niveau non final → passage au niveau suivant (`_advanceLevel`, board
  régénéré, stats cumulées) ; un **échec** ou le **dernier niveau** → écran Results + soumission.

Le mobile accumule un `PrevisionPuzzleLevelMetrics` **par niveau** (`_levelMetrics` : `discCount`,
`firstTrySuccess`, `sequenceErrors`, `plannedMoves`, `optimalMoves`, `retries`, `completed`) et soumet
**une seule** `PrevisionPuzzleMetrics { levels }` à la fin. Le backend/mock notent **chaque niveau /10**
(barème catégoriel de la fiche) puis font la **moyenne arrondie** via `scorePrevisionPuzzle` — un seul
`Attempt` enregistré. `globalPlanSuccess` est exposé dans la réponse mais reste **hors du score**.

### 🧭 Flow « Je Décide » — Phases 1–4 (mobile)

`je_decide_screen.dart` orchestre les écrans fournis dans les trois dossiers de handoff, dans une
machine d'états locale :

`welcome → onboarding (3 pages) → playerCard → avatar → practiceIntro → practiceScenario`

`→ analytical → riskBalance → quickChoice → xpFeedback → checkpoint → encouragement`

`→ badge → dimensionComplete → stabilityFirst → stabilitySecond → selfControl`

`→ journeyComplete → preparing → profile → strengths → details → export → hub`.

- **Welcome** : hero violet, objectif/durée/format, étapes et confidentialité.
- **Onboarding** : carousel « Every choice tells a story », « No pressure » et
  « Your decision profile ».
- **Player card** : nickname facultatif, preview et 4 thèmes couleur.
- **Avatar** : 6 guides (`Navigator`, `Analyst`, `Explorer`, `Strategist`, `Pathfinder`, `Observer`)
  à partir des PNG fournis.
- **Practice** : tutoriel puis seul scénario fourni, `Practice 1/2 — Choosing a route`.
  Le choix reste neutre : aucun état « correct/incorrect ».
- **Gameplay Phase 2** : les cinq formats livrés sont représentés sans afficher leurs codes
  internes : choix à 3 cartes, risque à 2 options, choix rapide, scénario lié en deux parties
  consécutives et préférence immédiate/différée.
- **Choix rapide** : timer visuel + numérique de 7 s, état critique orange à 2 s, timeout calme
  puis passage automatique au scénario suivant. Aucune notion de réussite/échec.
- **Feedback** : écran `+12 XP` et badge `Steady Explorer`. Ces valeurs reproduisent seulement les
  états visuels des maquettes ; elles ne constituent pas un barème.
- **Checkpoint/reprise** : à mi-parcours, pause optionnelle, écran de progression sauvegardée et
  restauration automatique. `DecisionProgressStore` conserve uniquement le nom de l'étape de
  reprise dans `SharedPreferences`, jamais les réponses.
- **Menu pause** : la croix gameplay ouvre un dialogue avec reprise, son/musique, règles et
  sauvegarde/sortie. Le timer DT est réellement suspendu puis reprend au même nombre de secondes.
- **Résultats Phase 4** : fin 30/30, préparation, radar avec équivalent textuel accessible, profil,
  forces, axe de progression, cinq dimensions détaillées et écran export/partage placeholder.
  Le profil `82/100 — Analytical Decision-Maker` et ses cinq valeurs sont un **aperçu exact de la
  maquette**, isolé dans `DecisionProfilePreview` ; il n'est pas dérivé des choix.
- La bottom nav partagée reste visible pendant l'introduction et disparaît pendant la pratique et
  tout le gameplay/résultat.
- Restent à fournir avant l'intégration backend : `Practice 2/2`, catalogue des 30 scénarios,
  mapping option→dimension (0–3), seuils de profil, règles XP/badges et règles de randomisation.
  Tant qu'ils manquent, aucun `MiniGame.DECISION_CORE`, métrique, score, appel backend ni profil
  psychométrique réel n'est créé côté client.

La carte `Decision-Making` du hub pointe exclusivement vers `/games/je-decide`. Predictive Puzzle
reste dans `Executive Planning`.

### Gestion d'état & bascule mock/backend

```dart
// games_providers.dart
const _useMock = bool.fromEnvironment('GAMES_MOCK', defaultValue: true);
final gamesRepositoryProvider = Provider<GamesRepository>((ref) =>
    _useMock ? GamesMockRepository() : GamesRepositoryImpl(ref.watch(dioProvider)));
```

- **Par défaut** : mock → la feature est **autonome**, jouable sans backend.
- **Backend réel** : lancer avec `--dart-define=GAMES_MOCK=false`. Seule cette ligne change ;
  ni le contrôleur ni Flame ne sont modifiés.

### 🎚️ Niveau Move Fast (mobile)

Une session « Je bouge » se joue sur un **niveau unique à règle aléatoire** (état géré dans
`move_fast_screen.dart`). **Dès le premier avion**, la règle active bascule de façon imprévisible ;
la couleur de l'avion et le libellé suivent toujours la règle (`_ruleColor` / `_ruleLabel`), donc le
feedback visuel reste cohérent : **vert = Orientation**, **jaune/orange = Mouvement**.

| Niveau | Règle | Couleur |
|--------|-------|---------|
| **Unique — Règle aléatoire** | **change à chaque avion** (imprévisible), alterne Orientation ⇄ Mouvement | vert ⇄ jaune |

- **Fin de session (inchangée)** : `_targetCorrectAnswers` (12 bonnes réponses), `_maxResponses`
  (18 essais) ou expiration du `_sessionSeconds` (84 s).
- **Randomisation** : `_nextRandomRule()` bascule la règle 2 fois sur 3 et la garde 1 fois sur 3 → le
  joueur ne peut pas anticiper ; teste réellement la flexibilité cognitive.
- Les **tutoriels** Orientation puis Mouvement restent **en amont** (le joueur doit connaître les 2
  règles avant que la partie ne les mélange). Machine à états simplifiée :
  `intro → tutorials → gameplay → results → comparison` (plus d'écrans de transition de niveau).

> Le barème backend/mock (`scoreMoveFast`) rejoue la séquence `correctResponses` (dérivée des
> essais notés) sans connaître les niveaux — la difficulté est purement côté présentation.
>
> **Métriques envoyées** : l'écran construit désormais une liste `responses` (une entrée par essai,
> avec `ruleActive` / `isSwitchTrial` / `appliedOldRule` déduits du changement de règle et de la
> direction choisie), marque les **3 premiers essais** `practiceTrial=true` (échauffement) et renseigne
> `practiceTrialExcludedCount`. Le backend calcule le score **et** les indicateurs de flexibilité ;
> le score affiché fait autorité côté serveur (`_serverSession`).

### 🎨 Composants UI jeux (`game_system_components.dart`)

- `GameDirectionControls` : D-pad **compact centré** (croix de largeur `buttonSize*3 + gap*2`),
  aligné sur la maquette Figma.
- `MoveFastPlane` / `_PlanePainter` : avion vectoriel calé sur la référence Figma
  `04 Move Fast/Move Fast Pro/Plane trail/next.png` (silhouette blanche, panneaux de règle,
  contour et ombre bleu-violet). Sur le plateau, `_ScrollingPlane` fait **défiler les avions en
  continu** (boucle avec wrap) dans la direction du mouvement, sans ligne de trajectoire.
- `_RulesDialog` : aide « Règles » avec deux cartes codées couleur (vert Orientation / orange
  Mouvement) au lieu d'un simple `AlertDialog`.

---

## 📄 Contrat partagé

`contracts/games.openapi.yaml` — **source de vérité** de l'API entre backend et mobile.
Schémas : `GameType`, `MiniGame`, `SessionStatus`, `StartSessionRequest`, `OptimalPathMetrics`,
`MoveFastMetrics`, `PrevisionPuzzleMetrics`, `ContinuousAttentionMetrics`,
`CoordinationProtocolVersion`, `CoordinationPhase`, `CoordinationSpeed`,
`CoordinationInputSource`, `CoordinationPointerSample`, `CoordinationSegmentMetric`,
`CoordinationMetrics`, `CoordinationIndicators`, `GameMetrics` (oneOf), `SubmitResultRequest`,
`Score`, `Attempt`, `GameSession`.

Pour `COORDINATION_TRACKING_CORE`, le contrat transporte uniquement la trace brute normalisée et
les états techniques du run ; `GameSession.coordinationIndicators` expose ensuite le rapport
recalculé côté serveur. Le client ne peut choisir ni la trajectoire, ni l'ordre des segments, ni
les agrégats utilisés au résultat.

> ⚠️ Toute évolution de l'API doit modifier **ce contrat en premier**, puis backend et mobile.

---

## 🔄 Flux complet (exemple Planifik)

1. **Mobile** — `GamesController.start(GameType.planifik)` → `POST /games/sessions` → `GameSession` IN_PROGRESS.
2. Le joueur trace le chemin dans `PlanifikGame` ; à chaque niveau validé : `buildLevelMetrics(levelIndex, attempts)` accumulé (soumission multi-niveaux au dernier niveau).
3. `GamesController.submit(miniGame: optimalPath, metrics)` → `POST /sessions/{id}/results`.
4. **Backend** — `SubmitGameResultUseCase` calcule le `Score` via `PlanifikScoringService`, `recordResult` sur l'agrégat.
5. Au **dernier mini-jeu** du type (Planifik : `OPTIMAL_PATH` + `TASK_SCHEDULING` + `PREVISION_PUZZLE` → /30) → session `COMPLETED` + `GameResultRecordedEvent` publié.
6. `GameResultRecordedListener` (Analytics) consomme l'event pour le tableau de bord cognitif.

---

## ✅ Statut & roadmap

| Élément | Statut |
|---------|--------|
| Planifik #1 « Chemin Optimal » (Flame + barème + persistance) | 🟢 Fait |
| Optimal Path — flow complet mobile (intro Path Mind, How To Play, gameplay, score, comparaison) | 🟢 Fait |
| Optimal Path — **4 niveaux randomisés par graphe BFS** + plateau de stations + **menu pause** | 🟢 Fait |
| Optimal Path — barème figé en constantes `OptimalPathConfig` (clés de la fiche) | 🟢 Fait |
| Optimal Path — **cumul multi-niveaux explicite** (score = moyenne /10 des niveaux, 1 seul `Attempt`) | 🟢 Fait |
| Optimal Path — enums `costlyZonesAvoided` (TOTAL/PARTIAL/NONE) & `secondaryObjectivesReached` (YES/PARTIAL/NO) | 🟠 Raffinements PARTIAL **à valider** par le psychologue |
| Optimal Path — agrégation par moyenne + bandes /10 par mini-jeu | 🟠 **À valider** par le psychologue (bandes /30 globales conformes, inchangées) |
| Optimal Path — `total_levels` = 4 | 🟠 Décision produit (fiche : « à définir ») |
| Optimal Path — **limite dure `max_attempts` = 3** (3 chemins ratés → niveau échoué 1/10 + passage auto) | 🟢 Fait — parité mock/backend, réinit. du tracé après échec |
| Move Fast « Je bouge » (écran + barème escalade) | 🟢 Fait |
| Move Fast — niveau unique à **règle aléatoire** (Orientation ⇄ Mouvement dès le départ) | 🟢 Fait |
| Move Fast — barème figé en constantes `MoveFastConfig` (clés de la fiche) | 🟢 Fait |
| Move Fast — métriques de flexibilité (`responses` enrichies) + indicateurs dérivés serveur (switch cost, erreurs persévératives…) | 🟢 Fait |
| Move Fast — essais d'échauffement (warm-up) exclus du scoring/stats | 🟢 Fait |
| Move Fast — condition de fin (`SessionEndMode`) | 🟠 **Configurable** : défaut `FIXED_BUDGET` (12/18/84 s, DIVERGE de la fiche) / `REACH_MAX_MULTIPLIER` (fiche) — bascule = 1 constante, à valider par le psychologue |
| Move Fast — bandes d'interprétation (/100) | 🟠 Provisoires, **non validées** par le psychologue |
| **« Je continue » (`CONTINUOUS_ATTENTION`) — contrat + domaine + V27** : Long Rosvold X/AX complet, séquence déterministe serveur, 1 364 essais audités, propriété JWT, soumission valide atomique et audit-only invalide sans Attempt/event | 🟢 Fait |
| **« Je continue » — score /100** : balanced accuracy X_TEST/AX_TEST uniquement, arrondi rationnel unique ; d′, biais c et RT descriptifs hors score | 🟠 Implémenté en config **PROVISOIRE — non validé par le psychologue** |
| **« Je continue » — mobile complet** : onboarding/règles, pratiques X/AX, 40 blocs test au tempo 690/230 ms, repos 2 min, pause/reprise sécurisée, résultats et insights, logo, hub/picker et route `/games/je-continue` | 🟢 Fait |
| Référence de la fiche « Conners CPT-3 » → correction **Long Rosvold CPT** | 🟠 Documentée et à signaler/faire corriger par le psychologue ; aucune norme Conners utilisée |
| **« Je coordonne » (`VISUOMOTOR_COORDINATION`) — contrat + domaine + V28** : `FIXED_SQUARE_CW_V1`, 2 pratiques + 12 tests, trace fixed-point persistée, trajectoire/précision/validité recalculées serveur, audit-only sans Attempt/event | 🟢 Implémenté |
| **« Je coordonne » — score /100** : `roundHalfUp(overallAccuracyPercent)` uniquement ; vitesse/durée/distance et validité descriptives | 🟠 Implémenté en config **PROVISOIRE — autorisé par le demandeur, non validé par le psychologue** |
| **« Je coordonne » — mobile complet** : cover au logo PNG agrandi, onboarding illustré, pratique, ready, test 55 998 ms, ticker absolu, plateau mauve partagé Sync Square, feedback non porté par la couleur seule, pause/règles/restart, résultat descriptif, hub/picker et route `/games/je-coordonne` | 🟢 Implémenté |
| Références « Je coordonne » UPDA-SHIF / FT&PD-VTS + capacité d'auto-évaluation | 🟠 Divergences documentées ; filiation scientifique et mesure d'auto-évaluation à confirmer avec le psychologue |
| Catégorie mobile de « Je coordonne » | 🟠 Affiché dans **Cognitive Flexibility** sans renommage ; placement taxonomique à valider avec le psychologue et la matrice Fit Score |
| **« Je place » (`VISUOSPATIAL_MEMORY`) — contrat + domaine + V29** : `OBJECT_LOCATION_FINE_V1`, layouts déterministes serveur, actions brutes, classification exclusive, audit-only invalide et score provisoire isolé | 🟢 Implémenté |
| **« Je place » — mobile complet** : logo + 20 objets PNG transparents, onboarding, pratique, grille 4×4 responsive, niveaux 3→8, tap/drag, pause auditée avant retry, résultat descriptif, hub/picker et route `/games/je-place` | 🟢 Implémenté |
| **« Je place » — score /100 et protocole/timings/progression** | 🟠 Implémentés en config **PROVISOIRE — autorisés par le demandeur, non validés par le psychologue** |
| **« Je place » — event Fit Score / Analytics** | 🟠 Volontairement suspendu même pour un Attempt valide jusqu'à validation du barème et décision d'intégration inter-contextes |
| Catégorie mobile de « Je place » | 🟠 Affiché dans **Working Memory** à côté de Memory Quest, sans renommer/modifier le domaine historique |
| Renommer `Cognitive Flexibility` en « Attention & Flexibility » | 🔴 Non appliqué — décision taxonomique à valider avec le psychologue et la matrice Fit Score |
| Hub Games / Progress — maquette 5 domaines cognitifs, mini-logos des jeux dans les cartes + picker, bottom nav conservée | 🟢 Fait |
| Planifik #3 `PREVISION_PUZZLE` — Predictive Puzzle | 🟢 Fait |
| Predictive Puzzle — **3 niveaux (3 → 4 → 5 disques, optimal `2^n − 1`)** + disques responsive | 🟢 Fait |
| Predictive Puzzle — **barème catégoriel de la fiche** (1er essai/erreurs/coups superflus), remplace l'ancienne formule inventée | 🟢 Fait |
| Predictive Puzzle — cumul multi-niveaux (moyenne /10, 1 `Attempt`) + `globalPlanSuccess` hors score | 🟢 Fait |
| Predictive Puzzle — `puzzle_levels` [3,4,5] & `max_sequence_errors` [3,2,1] | 🟠 Décisions produit **à valider** (fiche : 3 constant) |
| **Planifik #2 `TASK_SCHEDULING` — « Ordonnancement de tâches »** (barème /10 : dépendances 3/0 + horaires 3/0 + cohérence 0–2 + réajustements dérivés) + écran mobile tap-to-place + parité mock | 🟢 Fait — Planifik complet **/30** sur ses 3 mini-jeux |
| **Planifik — jeu complet** (Chemin Optimal + Ordonnancement + Tour de Hanoï, profil global **/30**) | 🟢 **Complet** |
| **« J'investigue » (`MEMORY_QUEST`) — Mission A Digit Span** (observe → rappel même ordre → rappel inverse → résultats), écran Flutter custom, timers data-driven (900 ms / ISI 250 ms), input-lock, clavier accessible (≥48 px), score **mock** (0–5/tâche → composite /100) | 🟡 Fait (mobile, hors-ligne) — tuile hub + route `/games/investigate` + catalogue d'objets (21) |
| **« J'investigue » — Mission B (manipulation d'objets)** : observe l'ordre initial (5 s, verrouillé) → manipulations automatiques (échanges) → **restaurer l'ordre INITIAL** en tap-to-place ; objets par forme+libellé (accessibilité), score restauration → composite /100 | 🟡 Fait (mobile, hors-ligne) — enchaîné après la Mission A |
| **« J'investigue » — phase de distraction** : encode une courte séquence → **question rapide** (5–10 s, fond assombri **calme**, rappel mémoire visible, choix seuls actifs) → **rappel après distraction** ; note = **survie mémoire** (rappel après interférence), justesse de la question affichée à part ; intégré au composite | 🟡 Fait (mobile, hors-ligne) — enchaîné après la Mission B |
| **« J'investigue » — backend (Phase 4)** : mini-jeu `MEMORY_QUEST_CORE`, `MemoryQuestMetrics` (mesures par tâche), `MemoryQuestScoringService` (tâches 0–5 → **composite /100**), indicateurs + détail du score exposés, migration **V12** (CHECK), parité mock ; mobile soumet via le repository (score serveur autoritatif) | 🟢 Fait |
| **« J'investigue » — système de niveaux** (7 niveaux, longueur 3→9, +1 après 3 tâches réussies ; objets 4→12 ; distraction gatée niveau ≥ 3 ; arrêt à `max_sequence_length`/`max_session_duration_min`) | 🟢 Fait (backend + mobile + parité mock) |
| **« J'investigue » — calibrage appareil → timeout** (1er module dont le **score dépend du temps**) : `max_task_time_ms + offset` ; tâche dépassant le seuil ajusté = échec voidé ; `session_valid` | 🟢 Fait — socle `DeviceCalibration`/`CalibrationService` **réutilisé** (non modifié) |
| **« Je Décide » (`DECISION`) — Phases 1–4 mobile** | 🟡 Fait côté UI — parcours complet jusqu'au profil, timer/timeout, transitions, pause/règles, checkpoint/reprise, radar/insights/export placeholder ; **profil maquette uniquement**. Catalogue complet/backend/scoring réel en attente des règles |
| **« Emotional Radar » (`EMOTIONAL_REGULATION`) — 5ᵉ domaine** : `GameType` + `EMOTIONAL_RADAR_CORE`, barème 9 pts/scène, écran Flutter complet (cover, tutoriel, gameplay à révélation progressive, feedback, transition, résultats, pause/aide/plein écran), parité mock | 🟢 **Fait** — jouable sur les 3 scènes rédigées (27 pts) |
| Emotional Radar — **contenu servi par le backend** (texte/image/vidéo) : catalogue en base, `GamesMediaStoragePort` + adaptateur Cloudinary dédié, endpoint de téléversement | 🟢 Fait — 1ᵉʳ jeu du module dont le matériel n'est pas embarqué |
| Emotional Radar — **notation par scène côté serveur** (clé de correction jamais envoyée au client ; score reconstruit depuis les réponses persistées) | 🟢 Fait — migration **V25**, table `emotional_radar_answers` |
| Emotional Radar — taxonomie ANGER/DISGUST/SURPRISE (Ekman) | 🟠 **PROVISOIRE** — absente des maquettes, à valider par le psychologue |
| Emotional Radar — 12 scènes manquantes (15 visées) | 🔴 En attente du psychologue — aucune scène inventée |
| **« Reflective Pause » (`REFLECTIVE_PAUSE_CORE`)** : contrat, domaine pur, barème serveur 3/4/3, V26, API, breakdown et parité mock | 🟢 **Fait — /10**, 10 moments obligatoires |
| Reflective Pause — mobile complet : cover, intro, tutoriel, timer 3 s, réponses, transition sauvegardée, résultats, insights, pause/règles, route et picker Emotional Regulation | 🟢 Fait — logo officiel net réutilisé |
| Domaine Emotional Regulation — session partagée Radar + Reflective, complétion + event | 🟢 Fait — composite provisoire **/37** (27 + 10) |
| Profil global émotionnel /30 avec Strategic Choices | 🔴 Différé — aucune règle/maquette de scoring fournie |
| Bascule mock ⇄ backend | 🟢 `--dart-define=GAMES_MOCK` |
| Socle de calibrage appareil (méthode « technique », transversal) | 🟢 Fait — appliqué à Move Fast (indicateurs `*Adjusted`), réutilisable Decision/Memory Quest |
| Calibrage — table `games.device_calibrations` (V11) + fallback fiabilité réduite | 🟢 Fait |
| **Panneau « détail du score »** (dont Move Fast, Planifik, Reflective Pause, Je continue, Je coordonne et Je place) | 🟢 Fait côté serveur/mock (`ScoreBreakdownService`) ; affichage `ScoreDetailPanel` sur les écrans qui l'exposent |
| Intégration Analytics (event) | 🟢 Listener en place (log ; à brancher au vrai dashboard) |

---

## 🧠 Décisions à valider avec le psychologue référent

Écarts **assumés et tracés** entre l'implémentation et les fiches — **ne pas les supprimer sans arbitrage**. Chacun est isolé en config/commenté dans le code. Pour « Je coordonne », les choix 37 à 45 ont été **autorisés par le demandeur pour l'intégration**, mais restent **PROVISOIRES — non validés par le psychologue**. Le seuil technique 46 est en plus à valider sur le parc réel. Pour « Je place », les choix 47 à 53 ont été autorisés afin de rendre la fiche incomplète exécutable, mais restent eux aussi provisoires.

| # | Point | Choix implémenté | Fiche / référence | Localisation |
|---|-------|------------------|-------------------|--------------|
| 1 | **Bandes d'interprétation Move Fast** (/100) | <40/<60/<75/<90/sinon — **centralisées** (source unique par côté, faciles à changer) | Aucune fiche | backend `MoveFastConfig.INTERPRETATION_BANDS` · mobile `MoveFastConfig.interpretMoveFast` |
| 2 | **Condition de fin Move Fast** | **Configurable en 1 changement** : énum `SessionEndMode` — défaut `FIXED_BUDGET` (12/18/84 s, diverge de la fiche) ou `REACH_MAX_MULTIPLIER` (fiche, sans limite). Basculer = changer **une seule constante** (backend `SESSION_END_MODE` + miroir mobile `sessionEndMode`), sans refactor ; anti-triche adapté au mode | Fiche : `reach_max_multiplier` (aucune limite) | `MoveFastConfig.SESSION_END_MODE` |
| 3 | **Bandes d'interprétation mini-jeu /10** (Optimal Path & Predictive Puzzle) | 0–3/4–6/7–10 | Ajout développeur (fiche = seulement /30 global) | `OptimalPathConfig.MINI_GAME_INTERPRETATION_BANDS` |
| 4 | **Agrégation multi-niveaux par moyenne** (Optimal Path & Predictive Puzzle) | moyenne arrondie /10, 1 `Attempt` | Non spécifié | `PlanifikScoringService.scoreOptimalPath` / `scorePrevisionPuzzle` |
| 5 | **Zones coûteuses TOTAL/PARTIAL/NONE** (Optimal Path) | 2 / 1 / 0 | Fiche : « total ou partiel » pour 2 pts max | `OptimalPathConfig.COSTLY_ZONES_PARTIAL_POINTS` |
| 6 | **Objectifs secondaires PARTIAL** (Optimal Path) | PARTIAL = 0 | Fiche ne tranche pas | `OptimalPathConfig.SECONDARY_OBJECTIVE_PARTIAL_POINTS` |
| 7 | **Resserrement tolérance Hanoï** | `max_sequence_errors` 3 → 2 → 1 par niveau | Fiche : **3 constant** | `PrevisionPuzzleConfig.MAX_SEQUENCE_ERRORS` |
| 8 | **Niveaux** (`total_levels`=4 ; `puzzle_levels`=[3,4,5]) | décisions produit | Fiche : « à définir » | `OptimalPathConfig.TOTAL_LEVELS` / `PrevisionPuzzleConfig.PUZZLE_LEVELS` |
| 9 | **Calibrage fallback** | `hardware_profile_fallback` → fiabilité réduite | Guide §5 | `DeviceCalibration.reducedReliability()` |
| 10 | **Critère « essais » Optimal Path** | Compte les **validations prématurées** (chemin incomplet, → −2 pts) ; un chemin **complet mais sous-optimal** (traverse des zones coûteuses) atteint l'arrivée → **essai correct**, pénalisé par le critère « zones », pas par « essais » | Fiche : « nombre d'essais » | `planifik_screen.dart` (`_validate` → `onWrong` → `_levelAttempts`) ; test `planifik_attempts_test.dart` |
| 11 | **Bandes d'interprétation « J'investigue »** (/100) | <40/<60/<75/<90/sinon | Aucune fiche (résultat « indicatif, non diagnostique ») | `MemoryQuestConfig.INTERPRETATION_BANDS` |
| 12 | **Barème « J'investigue »** (tâches 0–5, composite = moyenne × 20) | Notes par tâche + moyenne | Handoff « J'investigue » (à confirmer par le psychologue) | `MemoryQuestScoringService` |
| 13 | **Ordonnancement — `total_tasks`** | 10–12 tâches (mobile : 9 lisibles) | Fiche : nombre non figé | `TaskSchedulingConfig.TOTAL_TASKS_MIN/MAX` |
| 14 | **Ordonnancement — `time_constraints_mode`** | « strict » (tout-ou-rien) | Fiche : pas de mode partiel détaillé | `TaskSchedulingConfig.TIME_CONSTRAINTS_MODE` |
| 15 | **Ordonnancement — mesure de `planning_coherence`** | dérivée du nb de violations (0 → 2 · 1-2 → 1 · >2 → 0) | Fiche : jugement 0/1/2 non chiffré | `task_scheduling_screen.dart` (`_planningCoherence`) |
| 16 | **« J'investigue » — `max_task_time_ms`** | **6000 ms PROVISOIRE** (délai max d'une tâche avant échec par dépassement) | Fiche : aucune valeur scientifique ; recommande le 95ᵉ percentile pilote | `MemoryQuestConfig.MAX_TASK_TIME_MS` |
| 17 | **« J'investigue » — seuil critique d'offset de calibrage** | **100 ms PROVISOIRE** (au-delà → session invalide) | Non chiffré par la fiche | `MemoryQuestConfig.CRITICAL_CALIBRATION_OFFSET_MS` |
| 18 | **« J'investigue » — seuil « trop de timeouts » (critère validité 3)** | **> 3 tâches PROVISOIRE** (au-delà → session invalide) | Non chiffré par la fiche | `MemoryQuestConfig.MAX_TIMEOUT_TASKS` |
| 20 | **Emotional Radar — barème d'intensité** | écart 0 → 2 pts · 1 → 1 pt · ≥ 2 → 0 | Maquette : seulement « Intensity 2 pts ». Le dégradé traduit la tuile « 81% Intensity — Calibration quality » | `EmotionalRadarConfig.intensityScore` |
| 21 | **Emotional Radar — gradient bonus** | **désactivé** (`GRADIENT_BONUS_ENABLED=false`) : l'activer donnerait 10 pts/scène, incompatible avec les totaux 27 et 135 de la maquette | Maquette : « Gradient bonus +1 optional » | `EmotionalRadarConfig.GRADIENT_BONUS_ENABLED` |
| 22 | **Emotional Radar — nuance tout-ou-rien** | 4 pts si exacte, 0 sinon (pas de crédit partiel pour « bonne famille, mauvaise nuance ») | Non spécifié | `EmotionalRadarScoringService.grade` |
| 23 | **Emotional Radar — réponse de la scène 3** | `Sadness / Empathic pain / 3` | **Contradiction Figma** : 3 planches contre la ligne du tableau (`Joy → Triumph → 4`) | `V25__games_emotional_radar.sql` |
| 24 | **Emotional Radar — nuances ANGER / DISGUST / SURPRISE** | sous-catégories **d'Ekman**, marquées `PROVISIONAL`, isolées dans la couche provisoire | **Absentes de toutes les planches** alors que les 6 familles sont sélectionnables | `EmotionalRadarProvisionalRules` + colonne `source` |
| 25 | **Emotional Radar — `total_scenes` = 3** | 3 scènes rédigées ; l'UI annonce « / 15 » | Planche « Phase 2 QA notes » : les 15 scènes sont en Phase 3 | `EmotionalRadarConfig.TOTAL_SCENES` |
| 26 | **Emotional Radar — bandes d'interprétation** (/100) | <40/<60/<75/<90 — alignées sur les autres jeux | Aucune fiche | `EmotionalRadarProvisionalRules.interpret` |
| 27 | **Emotional Radar — autorisation de l'upload média** | endpoint **authentifié seulement** — aucun rôle admin n'existe dans `games` | Non spécifié — **arbitrage produit attendu** | `EmotionalRadarController.uploadMedia` |
| 28 | **Reflective Pause — barème 3/4/3** | temps contrôlé /3 + non-impulsivité /4 + prise de recul /3 ; sous-scores à 0,1, somme arrondie une fois | Le handoff nomme les dimensions et le score /10 mais ne fixe pas explicitement les poids | `ReflectivePauseConfig` / miroir Dart |
| 29 | **Reflective Pause — moment 3** | `WAIT` **ou** `REFORMULATE_CALMLY` comptent comme prise de recul | Content map : « Wait, then reformulate calmly » sans préférence entre les deux choix UI | `ReflectivePauseConfig.RECOMMENDED` |
| 30 | **Profil émotionnel provisoire /37** | session complétée avec Radar actuel /27 + Reflective /10 | La planche globale prévoit 3 jeux ×10 = /30, mais Strategic Choices et la normalisation Radar /10 ne sont pas fournis | `MiniGame.EMOTIONAL_RADAR_CORE` + `REFLECTIVE_PAUSE_CORE` |
| 31 | **« Je continue » — référence scientifique** | implémenter et nommer le protocole **Long Rosvold CPT X/AX** ; ne jamais utiliser les normes/T-scores Conners | La fiche cite « Conners CPT-3 » mais décrit 44 blocs X/AX à 690/230 ms, protocole Rosvold ; erreur de référence à corriger avec le psychologue | `ContinuousAttentionConfig` · contrat `ROSVOLD_LONG_V1` · UI |
| 32 | **« Je continue » — score /100** | moyenne des balanced accuracies X_TEST et AX_TEST ; RT, d′ et biais c strictement hors score ; niveau neutre constant, aucune bande clinique | **PROVISOIRE — non validé par le psychologue** ; limite connue : « jamais répondre » et « toujours répondre » donnent 50/100 | `ContinuousAttentionProvisionalRules` + miroir Dart |
| 33 | **Catégorie mobile de « Je continue »** | jeu affiché dans la carte existante **Cognitive Flexibility**, sans renommer la catégorie ; `GameType.CONTINUOUS_ATTENTION` séparé côté domaine | Attention soutenue et flexibilité cognitive sont distinctes ; « Attention & Flexibility » toucherait la taxonomie produit et la matrice Fit Score | `games_hub_screen.dart` |
| 34 | **Pause/interruption Rosvold** | repos programmé 2 min entre X/AX ; interruption pendant un test ⇒ reprise de phase ; run invalide éventuellement conservé audit-only mais **aucun Attempt/event/Fit Score** | Une pause libre modifie la vigilance mesurée ; règle de reprise définitive à confirmer | `ContinuousAttentionConfig` + écran mobile + use case |
| 35 | **Tolérance technique des durées réelles** | `TIMING_TOLERANCE_MS = 100` sur onset réel/prévu, affichage 690 et ISI 230 ; 100 accepté, 101 invalide ; jamais dans le score | **PROVISOIRE — à valider sur appareils réels** (690/230 ms non alignés exactement sur les frames) | `ContinuousAttentionConfig` + miroir Dart |
| 36 | **Adaptation audio de « Je continue »** | le stimulus visuel rapide n'est pas annoncé automatiquement par VoiceOver ; les contrôles, consignes et états restent sémantiques | Une annonce vocale à chaque lettre altérerait le protocole et produirait 1 364 annonces. Toute modalité audio équivalente doit faire l'objet d'une validation accessibilité/psychométrique séparée | `continuous_attention_screen.dart` |
| 37 | **« Je coordonne » — vitesses** | tour lent **7000 ms**, tour rapide **3500 ms**, mouvement linéaire continu | La fiche distingue lent/rapide sans définir les vitesses de parcours | `CoordinationConfig.SLOW_LAP_MS/FAST_LAP_MS` + miroir Dart |
| 38 | **« Je coordonne » — géométrie/départ** | inset **0,16**, rayon cible **0,075**, activation à demi-rayon, départ au coin supérieur gauche et sens horaire | Dimensions, point initial et règle de continuité non chiffrés | `CoordinationConfig` · `CoordinationTrajectoryService` + miroir Dart |
| 39 | **« Je coordonne » — distance/pointeur absent** | distance normalisée par la diagonale du plateau vers `[0,1200]` ; pointeur absent = hors cible + distance **1200** | La fiche donne 0–1200 sans conversion ni traitement d'une absence de pointage | `CoordinationScoringService` · `CoordinationTrackingConfig.canonicalDistanceUnits` |
| 40 | **« Je coordonne » — score /100** | `roundHalfUp(overallAccuracyPercent)` uniquement ; vitesse, durée et distance descriptives ; niveau neutre constant | La fiche fournit les variables mais aucun barème composite | `CoordinationProvisionalRules` + miroir Dart |
| 41 | **Catégorie mobile de « Je coordonne »** | troisième jeu de la carte existante **Cognitive Flexibility**, sans renommer la catégorie ; `VISUOMOTOR_COORDINATION` reste séparé côté domaine | Coordination visuo-motrice et flexibilité cognitive sont distinctes ; déplacer/renommer touche la taxonomie et la matrice Fit Score | `games_hub_screen.dart` |
| 42 | **Pause/interruption « Je coordonne »** | pratique interruptible ; pause/perte de focus pendant un test ⇒ run interrompu/audit-only et **redémarrage du test**, sans `Attempt`/event/Fit Score | Une pause libre altère la continuité du suivi et la fatigue mesurée | config + écran mobile + `SubmitGameResultUseCase` |
| 43 | **Adaptation touch/stylus** | le protocole accepte `MOUSE`, `TOUCH`, `STYLUS` avec coordonnées normalisées ; même cible/rayon et même score | La fiche décrit un curseur souris ; l'occlusion du doigt et l'ergonomie tactile peuvent modifier la mesure | `CoordinationInputSource` + écran mobile |
| 44 | **« Je coordonne » — filiation scientifique** | implémentation nommée par son protocole produit `FIXED_SQUARE_CW_V1`, sans revendiquer de normes CogniFit/VTS | La fiche mélange la page publique **UPDA-SHIF / Synchronization** et le manuel **FT&PD / Vienna Test System** ; référence finale à confirmer | contrat + `CoordinationConfig` + copie UI |
| 45 | **Capacité d'auto-évaluation** | non calculée et non affichée ; le jeu mesure actuellement la coordination visuo-motrice objective | La fiche annonce aussi une capacité d'auto-évaluation sans questionnaire, variable ou règle de cotation correspondante | contrat `CoordinationMetrics`/`Indicators` · résultats mobile |
| 46 | **Tolérance temporelle « Je coordonne »** | frontière/durée de segment test tolérée à **±100 ms** ; au-delà `technicalValid=false`. Le score rejoue toujours la cible sur la grille canonique serveur de 1 ms ; gaps/frames restent descriptifs | La fiche fixe les durées mais ne donne ni tolérance appareil ni règle sur les frames perdues | `CoordinationConfig.TIMING_TOLERANCE_MS` + miroir Dart · scorer Java/Dart |
| 47 | **« Je place » — protocole et charge** | grille 4×4 ; pratique 2 ; tests **[3,4,5,6,7,8]** ; catalogue V1 de 20 objets modernes | Le PDF décrit le principe et des objets randomisés sans figer grille, charges ni catalogue numérique | `ObjectLocationConfig` + miroir Dart |
| 48 | **« Je place » — timings** | encodage `1500 ms × objet`, rétention 2000 ms, rappel max `4000 ms × objet`, minimum anti-tap `150 ms × objet` | Valeurs absentes/non suffisamment figées dans la fiche | `ObjectLocationConfig` + miroir Dart |
| 49 | **« Je place » — progression** | réussite `ceil(60 %)` ; minimum 3 niveaux test ; arrêt après 2 échecs consécutifs, jamais avant le niveau 3 | Seuils et règle d'arrêt non fournis | `ObjectLocationConfig` · `ObjectLocationScoringService` + miroir Dart |
| 50 | **« Je place » — score /100** | exacts / objets administrés, arrondi half-up unique ; swaps, distance, pente et temps descriptifs | La fiche liste des variables mais ne fournit pas un barème composite validé | `ObjectLocationProvisionalRules` + miroir Dart |
| 51 | **« Je place » — tolérances/interruptions** | ±100 ms encodage-rétention, ±250 ms rappel ; pause/focus/rotation/background ⇒ audit-only puis restart mesuré | Tolérance appareil et reprise après interruption non spécifiées | config + scorer + `je_place_screen.dart` |
| 52 | **Catégorie mobile de « Je place »** | deuxième jeu de **Working Memory**, sans renommer la catégorie ni modifier `MEMORY_QUEST` | Placement produit cohérent avec la mémoire visuo-spatiale, mais taxonomie finale à confirmer | `games_hub_screen.dart` |
| 53 | **Fit Score / Analytics de « Je place »** | event supprimé même après Attempt valide tant que le barème est provisoire | Aucun mapping vers la matrice Fit Score ni validation psychologue fournis | `SubmitGameResultUseCase.executeObjectLocation` |
| 19 | **« Je Décide » — frontière mobile/backend** | Le parcours UI Phases 1–4 est navigable. Le profil final est l'aperçu statique de la maquette (`DecisionProfilePreview`) et ne dépend jamais des choix ; XP purement visuel | `Practice 2/2`, catalogue 30 scénarios, mapping option→dimension, seuils de profil, XP/badges et randomisation non fournis | `je_decide_screen.dart`, `je_decide_gameplay.dart`, `je_decide_results.dart` |

**Conforme à la fiche, NE PAS toucher** : profil global Planifik /30 (`interpretGlobal`), cœur du barème Move Fast (50 × multiplicateur, streak 4, bonus 250), barème catégoriel « Predictive Puzzle » (seule fiche validée), architecture par Domain Events.

## 🔧 Comment maintenir ce document

Ce fichier doit rester **synchronisé** avec le code. **Mettez-le à jour dans la même PR** dès que
vous touchez à l'un de ces chemins :

- `backend/src/main/java/com/zennyt/games/**`
- `backend/src/main/resources/db/migration/V9__games_schema.sql` (ou migrations games ultérieures)
- `backend/src/main/java/com/zennyt/analytics/application/listener/GameResultRecordedListener.java`
- `mobile/lib/features/games/**`
- `mobile/lib/core/router/app_router.dart` (routes `/games*`)
- `contracts/games.openapi.yaml`

**Checklist à chaque modification :**
- [ ] Un fichier ajouté/supprimé/renommé → mettre à jour les **tableaux d'arborescence**.
- [ ] Un endpoint change → mettre à jour la **table API** et le **contrat OpenAPI**.
- [ ] Un barème change → mettre à jour la section **Barème** (backend **et** mock mobile doivent rester identiques).
- [ ] Un nouveau jeu/mini-jeu devient jouable → mettre à jour le **tableau de statut** et la **roadmap**.
- [ ] Mettre à jour la ligne ci-dessous.

**Changelog (45) — 2026-08-05** : nouveau jeu complet **« Je place »** dans Working Memory,
sans modifier Memory Quest. Contrat-first : `VISUOSPATIAL_MEMORY` / `OBJECT_LOCATION_BINDING_CORE`,
payload d'actions brutes et rapport `objectLocationIndicators`. Backend : protocole déterministe
`OBJECT_LOCATION_FINE_V1` (grille 4×4, pratique 2, tests 3→8), reconstruction
FNV-1a/xorshift/Fisher–Yates, rejeu serveur, catégories exclusives EXACT/SWAP/LOCAL/GLOBAL/UNPLACED,
score exactitude /100 isolé **PROVISOIRE**, validité et audit-only ; V29 persiste runs/niveaux/actions.
Une tentative valide clôt la session mais ne publie provisoirement pas l'event Fit Score. Mobile :
logo + 20 objets PNG transparents 512×512, flow cover→onboarding→pratique→6 niveaux→résultats,
grille mauve tap/drag responsive, pause mesurée auditée avant retry, hub/picker et route
`/games/je-place`; parité mock/backend et vecteur golden. Validation : Maven verify **291 tests**
(0 échec/erreur, 4 skips préexistants), ArchUnit **3/3**, Flutter **142 tests** et analyze clean.
`pom.xml`, `pubspec.yaml`, shared, Identity, Recruitment et les barèmes existants sont inchangés.

**Changelog (44) — 2026-08-05** : troisième exploration visuelle non intégrée du logo mobile
**« Je coordonne »**, créée après rejet produit de la V2 jugée trop répétitive. Le dossier
`test 2/V3 Artistic Rounded/` contient quatre silhouettes volontairement distinctes et plus
larges/arrondies : `Circuit souple`, `Virage magnétique`, `Regard accordé` et `Geste précis`.
Elles conservent la palette Games, le contour bleu nuit, la cible orange et l'indice cyan de suivi,
mais ne répètent plus toutes le même cadre carré. Les quatre fichiers sont des **PNG RGBA
1024×1024 transparents**, remappés sur six aplats, exempts de frange verte et contrôlés sur
blanc/violet à 36/56/88 px. Recommandation : **Virage magnétique** ; alternative plus conceptuelle :
**Regard accordé**. Les séries 42–43 restent conservées. Le logo actif, le code mobile, le protocole,
le score, le contrat, le backend, `pubspec.yaml` et `pom.xml` restent inchangés.

**Changelog (43) — 2026-08-05** : seconde exploration visuelle non intégrée du logo mobile
**« Je coordonne »**, créée après rejet produit des métaphores trop abstraites de la série 42.
Les quatre variantes V2 de `test 2/` — `Square Sync`, `Corner Lock`, `Dual Pace` et
`Precision Capture` — repartent directement de la grammaire du logo actif : trajectoire carrée,
cible orange, viseur blanc, mouvement horaire et palette Games. Elles sont livrées en **PNG RGBA
1024×1024 transparent**, normalisées à environ 84 % du canvas, contrôlées sur blanc/violet et aux
tailles 36/56/88 px ; aucune frange chroma verte n'est détectée. `Square Sync` est la recommandation
de sélection. La série 42 est conservée dans `test 2/rejected-v1-abstract/` afin de ne pas perdre
l'historique. Le logo actif, le code mobile, le protocole, le score, le contrat, le backend,
`pubspec.yaml` et `pom.xml` restent inchangés.

**Changelog (42) — 2026-08-05** : exploration visuelle non intégrée du logo mobile
**« Je coordonne »**. Quatre directions PNG transparentes ont été générées dans le dossier racine
`test 2/` : `Virage en tandem`, `Étreinte de précision`, `Écho du mouvement` et `C cinétique`.
Chaque piste raconte différemment la convergence regard-geste autour d'une cible mobile, tout en
évitant le double carré, le viseur et les nombreux segments du logo actif. Les exports sont
normalisés en **1024×1024 RGBA**, remappés sur les six aplats Games, contrôlés sur blanc/indigo à
36/56/88 px et exempts de frange verte. Recommandation : **Virage en tandem**, puis
**C cinétique**. Le logo actif, le code mobile, le protocole, le score, le contrat, le backend,
`pubspec.yaml` et `pom.xml` restent inchangés.

**Changelog (41) — 2026-08-05** : seconde exploration professionnelle du logo mobile
**« Je continue »**, toujours sans intégration. Quatre silhouettes V2 cohérentes ont été générées
séparément : `AX Ligature`, `Focus Gate`, `Signal Ribbon` et `Dual Phase`. Elles partagent la même
grammaire cue cyan → cible magenta, le contour bleu nuit et la palette Games stricte. Les légères
variations de lumière génératives ont été remappées sur six couleurs plates ; chaque livrable est
normalisé en **1024×1024 RGBA transparent** et comparé sur blanc/indigo aux tailles 36/56/88 px.
Deux sorties intermédiaires insuffisantes ont été rejetées avant livraison (ambiguïté d'objet et
silhouette trop fine). Recommandation : **AX Ligature**, puis **Focus Gate**. Le logo actif, le code
mobile, le protocole Rosvold, le score, le contrat, le backend, `pubspec.yaml` et `pom.xml` restent
inchangés.

**Changelog (40) — 2026-08-05** : exploration visuelle du logo mobile **« Je continue »**, sans
intégration ni remplacement du logo actif. Quatre directions PNG transparentes ont été générées à
partir de la mécanique Long Rosvold X/AX et de la charte Games : `AX Focus Gate`, `Signal Stream`,
`Focus Relay` et `Continuity Loop`. Les fichiers sont normalisés en **1024×1024 RGBA**, détourés
sans halo vert, comparés sur fond blanc et `gameBlue`, puis contrôlés aux tailles réelles du hub
(36 px) et du picker (56 px). La recommandation produit est **AX Focus Gate**, avec **Focus Relay**
comme alternative sans lettres. Les prompts et critères sont documentés dans le dossier. Le logo
actuel, le code mobile, le protocole, le score, le contrat, le backend, `pubspec.yaml` et `pom.xml`
restent inchangés.

**Changelog (39) — 2026-08-01** : harmonisation UI mobile de **« Je coordonne »**, sans changement
du protocole ni du score. Cover : suppression de la tuile translucide autour du logo et
agrandissement du PNG RGBA `Je Coordonne.png` avec rendu haute qualité. Onboarding : les trois
pages utilisent désormais des démonstrations mauves dédiées (activation au centre, états
Centered/Inside/Outside, même trajectoire à deux allures) à la place des pictogrammes génériques.
Gameplay : fond global `ZennytGamePalette.gameBlue`, plateau `gamePanel`, header/HUD adaptés au
fond sombre, rails blancs renforcés et cible avec halo/contour cohérent ; palette locale remplacée
par les constantes du design system Games. Test widget ajouté pour verrouiller le PNG, les trois
tutoriels et les couleurs partagées. Validation : **123 tests Flutter** verts et `flutter analyze`
sans erreur. Pause/interruption, timings, métriques, contrat, backend, barèmes, `pubspec.yaml` et
`pom.xml` inchangés.

**Changelog (38) — 2026-08-01** : nouveau jeu complet **« Je coordonne »**
(`VISUOMOTOR_COORDINATION` / `COORDINATION_TRACKING_CORE`) ajouté comme troisième jeu de la
catégorie mobile existante **Cognitive Flexibility**, sans renommer la taxonomie ni modifier les
GameTypes/barèmes historiques. Contrat-first : protocole `FIXED_SQUARE_CW_V1`, 2 segments de
pratique + 12 tests (**55 998 ms** mesurés, **69 998 ms** actifs au total), positions fixed-point
brutes et rapport descriptif ; trajectoire, précision, distance et validité recalculées côté
serveur. Domaine Java pur, score **/100 PROVISOIRE** isolé
(`roundHalfUp(overallAccuracyPercent)` seulement), autres indicateurs hors score, persistance
audit V28 (`coordination_tracking_runs` / `_segments` / `_samples`) et soumission invalide sans
`Attempt`/event/Fit Score. Mobile : flow cover→tutoriels→pratique→ready→test→résultat/retry,
plateau custom au tempo absolu, souris/touch/stylus, menu pause/règles avec redémarrage du test,
route `/games/je-coordonne`, hub/picker et logo transparent original **Sync Square** ; parité
mock/backend implémentée dans les mêmes fichiers de config/scoring. Les vitesses 7000/3500 ms, la géométrie
0,16/0,075, la conversion diagonale→1200, le score, le placement de catégorie, la règle de pause et
l'adaptation touch/stylus ont été autorisés par le demandeur mais restent **non validés par le
psychologue**. Divergence UPDA-SHIF ↔ FT&PD/VTS et absence de mesure d'auto-évaluation tracées.
Durcissements issus des revues : grille canonique serveur/mock de **1 ms** contre les traces
clairsemées, tolérance de durée ±100 ms, verrou pessimiste de session, publication des events depuis
l'agrégat muté, erreurs HTTP 400/403/404 contractuelles, temps final réellement observé et reprise
lifecycle de la pratique. Validation finale : **274 tests Java** verts (4 ignorés), **ArchUnit 3/3**,
**122 tests Flutter** verts, `flutter analyze` sans erreur et revue Claude ciblée effectuée.
Son verdict final est : **aucun défaut bloquant ou actionnable restant**.
`pom.xml` et `pubspec.yaml` inchangés.

**Changelog (37) — 2026-07-30** : nouveau jeu complet **« Je continue »**
(`CONTINUOUS_ATTENTION` / `CONTINUOUS_ATTENTION_CORE`) dans la catégorie mobile existante
**Cognitive Flexibility**, à côté de Move Fast, sans renommer la taxonomie. Contrat-first :
protocole `ROSVOLD_LONG_V1` X/AX (44 blocs, 1 364 essais, 690 ms + ISI 230 ms), séquence
déterministe reconstruite depuis l'UUID, métriques/indicateurs descriptifs et propriété JWT.
Backend : domaine Java pur, exactitude et cibles recalculées serveur, score /100
`// PROVISOIRE — non validé par le psychologue` isolé et arrondi rationnel Java/Dart, d′/biais
c/RT hors score, audit-only des runs techniquement invalides sans `Attempt`/event, persistance
V27 et protection contre la double tentative. Mobile : parcours complet d'environ 25 min,
pratiques X/AX, 40 blocs mesurés, repos 2 min, clavier/tactile, pause-règles avec redémarrage
obligatoire d'une phase test interrompue, résultats/insights non diagnostiques, mock paritaire,
hub/picker/route `/games/je-continue` et logo A→X transparent généré dans la charte existante.
Correction scientifique tracée : la fiche décrit le **Long Rosvold CPT**, pas le Conners CPT-3 ;
aucune norme Conners n'est utilisée, correction à faire valider par le psychologue. Validation :
OpenAPI généré, backend **255 tests verts, 4 ignorés**, ArchUnit **3/3** ; mobile **103 tests
verts**, `flutter analyze` sans erreur, format Dart et contrôle de diff propres. Contrastes AA,
retour système pendant la pause et texte jusqu'à 200 % couverts ; adaptation audio séparée à
valider. `pom.xml` et `pubspec.yaml` inchangés ; barèmes, GameTypes existants et événements
historiques inchangés.

**Changelog (36) — 2026-07-29** : Move Fast mobile — avion vectoriel réaligné sur la référence
Figma `04 Move Fast/Move Fast Pro/Plane trail/next.png` (silhouette, ailes, panneaux, contour et
ombre), en conservant la couleur dynamique de la règle ; suppression des lignes de trajectoire du
plateau. Aucun asset embarqué, barème, contrat, endpoint ou event modifié. Zones protégées
inchangées.

**Changelog (35) — 2026-07-29** : harmonisation visuelle du hub Games. Les logos
**Memory Quest, Je Décide, Optimal Path, Task Scheduling et Predictive Puzzle** utilisent désormais
des variantes PNG détourées, sans le carré violet intégré aux sources. Les symboles et couleurs
officiels sont conservés ; un fin contour bleu rend les éléments blancs/lavande lisibles sur les
cartes blanches, dans les catégories comme dans les pickers. Move Fast, Emotional Radar et
Reflective Pause étaient déjà détourés et restent inchangés. Aucun écran de jeu, barème, contrat,
endpoint, dépendance ou `pubspec.yaml` modifié.

**Changelog (34) — 2026-07-29** : nouveau jeu **« Reflective Pause »**
(`EMOTIONAL_REGULATION` / `REFLECTIVE_PAUSE_CORE`) intégré contract-first, backend et mobile.
Contrat : cinq réponses brutes, exactement 10 `reflectivePauseMoments`, indicateurs serveur et enum
mini-jeu. Domaine pur : catalogue des moments, validation anti-falsification du timer 3 s, barème
provisoire **3 + 4 + 3 = /10**, report et détail du score ; migration **V26** limitée au CHECK des
mini-jeux. Mobile : flow complet fidèle aux 14 planches (cover, intro, tutoriel, gameplay,
transition sauvegardée, résultats, insights), choix verrouillés pendant 3 s, menu pause/règles
commun extrait d'Emotional Radar, session émotionnelle partagée, route et picker à deux jeux. Logo
officiel `Group.png` copié à l'identique en `assets/games icons/Reflective Pause.png` (net, aucune
génération requise, aucun changement `pubspec.yaml`). Parité mock/backend et tests de parcours
complet ajoutés. Composite émotionnel actuel **/37** (Radar 27 + Reflective 10), explicitement
provisoire en attendant Strategic Choices et les règles du profil /30. Validation : backend
**235 tests verts, 4 ignorés**, ArchUnit **3/3**, mobile **69 tests verts** et `flutter analyze`
clean. Zones
protégées inchangées : barèmes existants, events, calibrage, `pom.xml` et `pubspec.yaml`.

**Changelog (33) — 2026-07-26** : **Nouveau jeu « Emotional Radar » (`EMOTIONAL_REGULATION` /
`EMOTIONAL_RADAR_CORE`)** — 5ᵉ domaine cognitif, la carte hub « Emotional Regulation » n'est plus
inactive. **Barème** (`EmotionalRadarConfig`, carte *Scoring* du handoff) : émotion 3 + nuance 4 +
intensité 2 = **9 pts/scène** ; intensité en dégradé (écart 0 → 2 · 1 → 1 · ≥ 2 → 0) ; **gradient
bonus implémenté mais désactivé** — l'activer donnerait 10 pts/scène et contredirait les deux totaux
de la maquette (27 pour 3 scènes, 135 pour 15), que `Score` refuserait de toute façon
(`rawPoints > maxPoints`). Barème **dynamique** (`maxPoints = 0` comme `MOVE_FAST_CORE`).
**Anti-triche — la clé de correction ne quitte jamais le serveur** : les maquettes exigent un
feedback après chaque scène, résolu par une **notation par scène côté serveur**
(`POST .../scenes/{id}/answers` note **et persiste**), tandis que `EmotionalRadarMetrics` ne
transporte que des mesures comportementales (temps, aide, plein écran) — **aucune réponse, aucun
point**. Le score est reconstruit depuis les `emotional_radar_answers` persistées : un payload final
falsifié ne peut rien changer. `EmotionalRadarDtos.SceneResponse.from` est le **point de filtrage
unique** (omet les 4 champs `expected*` + `explanation`). **Contenu servi par le backend** (1ᵉʳ jeu
du module) : catalogue en base (port `EmotionalRadarSceneCatalog`, impl **non vide**),
`GamesMediaStoragePort` + `CloudinaryGamesMediaStorageAdapter` (patron identity/engagement, dossier
`zennyt/games/emotional-radar`, **aucune dépendance ajoutée**), endpoint de téléversement.
**Accessibilité portée par le domaine** : `EmotionalRadarScene` refuse une scène IMAGE/VIDEO sans
`altText`, une VIDEO sans `transcript` ; une scène média incomplète reste `active=false`.
**Migration V25** : `emotional_radar_scenes` / `_nuances` / `_answers` (PK `(session, scène)` →
re-valider n'ajoute pas de points) + extension des CHECK `game_sessions.game_type` (⚠️ nom réel de
la contrainte V9 : `ck_game_sessions_type`) et `game_attempts.mini_game`. **3 scènes rédigées
seeded** — les 12 manquantes ne sont **pas inventées** (planche « Phase 2 QA notes » : Phase 3).
⚠️ **Contradiction Figma tranchée** : scène 3 = `Sadness / Empathic pain / 3` (planches Dark Mode +
Responsive tablette + desktop, avec justification écrite) et non `Joy → Triumph → 4` (ligne isolée
du tableau de handoff). ⚠️ **Taxonomie des nuances** : `SADNESS` complète + `FEAR→Anxiety` +
`JOY→Excitement/Triumph` viennent des planches (`source=FIGMA`) ; **ANGER, DISGUST et SURPRISE
n'apparaissent nulle part** alors que les 6 familles sont sélectionnables → complétées par les
sous-catégories **d'Ekman**, marquées `PROVISIONAL` et isolées dans `EmotionalRadarProvisionalRules`
(patron `DecisionProvisionalRules` — le moteur ne code aucune valeur provisoire).
**Mobile** : écran complet (cover, règles, gameplay à **révélation progressive** — étapes 2 et 3
verrouillées, `Validate` inactif tant que les 3 choix ne sont pas faits —, feedback correct/incorrect,
transition, résultats + détail du score, pause, aide, plein écran), route `/games/emotional-radar`,
composants dédiés (cibles ≥ 48 px, **jamais de sens porté par la couleur seule**, `Semantics` alignés
sur la planche d'accessibilité), **parité mock** complète (miroir du barème + catalogue des 3 scènes
hors-ligne, clé de correction confinée à la couche data). **5 imperfections de maquette corrigées**
(scène 3, intensité absente de « Best answer », copie de succès divergente clair/sombre, score figé
à 0 sur la carte de feedback, CTA « Continue » vs « Next scene ») **+ 1 bug UI** : le titre
« Emotional Regulation » du hub se tronquait en « Emotional R… » (réduit pour tenir — passer à la
ligne faisait déborder la carte de 15 px). **Tests** : backend `EmotionalRadarScoringTest` (12 cas,
dont l'anti-triche et les invariants d'accessibilité) → **230 verts**, ArchUnit vert (le use case
d'upload passe par un **port** et non par JPA) ; mobile `emotional_radar_mock_test` (10, parité) +
`emotional_radar_screen_test` (8, parcours complet jusqu'à 27/27) → **62 verts**,
`flutter analyze` clean. ⚠️ **Ouvert** : aucun rôle admin n'existe dans `games`, l'upload média est
donc seulement authentifié — arbitrage produit attendu. Asset `Emotional Radar.png` attendu (repli
sur l'icône de catégorie en attendant). Zones protégées inchangées (barèmes Planifik/Move Fast/
Memory Quest/Decision, events, socle calibrage, `pom.xml`/`pubspec.yaml` non modifiés).

**Changelog (31) — 2026-07-24** : Hub Games — remplacement des swatches décoratives
par les mini-logos des jeux disponibles dans chaque catégorie. Les mêmes symboles vectoriels et
accents couleur sont maintenant réutilisés dans le bottom sheet Executive Planning pour Optimal
Path, Task Scheduling et Predictive Puzzle. Emotional Regulation reste explicitement « Jeux à
venir ». Aucun asset/dépendance/pubspec ajouté ; test widget hub + picker ajouté.

**Changelog (30) — 2026-07-24** : **« Je Décide » — moteur backend (`DECISION_CORE`)**,
deux couches strictement séparées. **MOTEUR (définitif)** : `DecisionConfig` (5 dimensions × 6 items /18 → /90, item /3, règle DT à **double ajustement** langue `7 s × mult` puis `+ offset` calibrage — correct+rapide `<75%`→3 / correct+lent→2 / incorrect→qualité option, multiplicateurs fournis en/fr/de, imputation ≤2→moyenne du bloc / >2→non exploitable) et `DecisionScoringService` (agrégation, SCW, interprétations fiche, qualité de session renforcée si non supervisé, indicateurs temporels). **PROVISOIRE (un seul fichier `DecisionProvisionalRules`, chaque constante `// PROVISOIRE`)** : (a) mapping option→score par **qualité** (`OptionQuality` OPTIMAL/SATISFACTORY/PARTIAL/DEFICIENT = 3/2/1/0) ; (b) **poids SCW = 1.0** (vérifié : raw=60 → **SCW 66,7**) ; (c) bornes de niveau (seul ≥75 fiche) Élevé/Normal/Borderline/Fragile ; (d) dérivation CS depuis la cohérence de la paire ; (e) multiplicateurs es/it/pt + fallback ar tracé. **Catalogue** port `DecisionScenarioCatalog` + impl vivante **vide** `EmptyDecisionScenarioCatalog` (`// EN ATTENTE DU PSYCHOLOGUE — 30 scénarios + étiquetage`) → `DECISION_CORE.isPlayable()=false` (patron `TASK_SCHEDULING`) ; **aucun contenu de scénario inventé**. VO `DecisionMetrics`/`DecisionItemResponse`/`DecisionReport` + enums `DecisionDimension`/`DecisionItemFormat`/`OptionQuality`/`AdministrationMode`. Contrat OpenAPI (`DecisionMetrics`/`DecisionIndicators`/`DecisionDimension`/`AdministrationMode`, `DECISION_CORE`, `decisionIndicators`), câblage `SubmitResultRequest.toMetrics`/use case/`GameSessionResponse`/`ScoreBreakdownService.decision` (dimensions /18 → brut /90 → SCW /100), `interpretGlobal(DECISION)`. Migration **V24** (CHECK `game_attempts` += `DECISION_CORE`). Tests `DecisionScoringTest` (6×OPTIMAL→18/18, **exemple fiche 66,7→Normal**, DT rapide/lent, DT langue en 7 s vs fr 8,4 s, DT calibrage ne bascule pas 3→2, imputation 2→moyenne / 3→non exploitable, les 4 interprétations, `session_usable=false` par critère, **délégation moteur→provisoire** = swappabilité). Domaine pur (ArchUnit). **Parité mock** : miroir Dart complet — `domain/config/decision_config.dart`, `domain/config/decision_provisional_rules.dart`, `domain/decision_scenario_catalog.dart` (port + `EmptyDecisionScenarioCatalog`), `data/decision_scoring.dart` (score SCW /100 + breakdown), entités `domain/entities/decision_metrics.dart` (+ enums), `MiniGame.decisionCore` et cases `games_mock_repository.dart` (catalogue vide → non jouable, parité backend) ; test `test/features/games/data/decision_scoring_test.dart` (7 cas : SCW 100/Élevé, **fiche 66,7→Normal**, DT rapide/lent/incorrect, DT langue, DT calibrage, imputation, bornes). `flutter analyze` clean. **Reste : câblage UI `je_decide_*.dart` (lot séparé) + le catalogue des 30 scénarios (psychologue).** ⚠️ Contrat : les 6 membres du `oneOf GameMetrics` déclenchent une NPE **non fatale** du normaliseur openapi-generator 7.5.0 (`processSimplifyOneOf`, quirk à exactement 6 membres) — build OK, DTO games générés non consommés (contrôleurs écrits main). Zones protégées inchangées (barèmes Planifik/Move Fast/Memory Quest, events, socle calibrage réutilisé, pom/pubspec, écrans mobile).

**Changelog (29) — 2026-07-24** : correctif menu pause « Je Décide » — le bouton
`…` des écrans welcome/onboarding/player card/avatar/pratique ouvre désormais réellement le menu
du parcours (continuer, règles, audio, sortie), et le gameplay expose une icône pause explicite
au lieu de masquer cette action derrière la croix. Le même menu/règles est réutilisé, le timer DT
reste gelé pendant son ouverture. Tests widget ajoutés pour les deux points d'entrée.

**Changelog (28) — 2026-07-24** : « Je Décide » Phases 3–4 mobile — transitions
Phase 3, checkpoint et reprise locale sans conserver les choix, menu pause/règles avec gel réel
du timer, écrans pause/progression sauvegardée/welcome back, fin de parcours 30/30, préparation,
radar accessible, profil/forces/détails et export-partage placeholder. Les badges et graphiques
sont dessinés nativement (aucun asset flou ajouté). Le profil final reprend exactement l'exemple
de la maquette dans `DecisionProfilePreview` et reste explicitement non psychométrique : aucun
calcul mobile, métrique, contrat ou backend ajouté faute de catalogue/barème validé. Tests widget
du flow complet premier écran→profil, pause/règles/timer, checkpoint/reprise et résultats ajoutés.
Zones protégées inchangées.

**Changelog (27) — 2026-07-24** : « Je Décide » Phase 2 mobile — nouveau
`je_decide_gameplay.dart` avec shell violet responsive, progression, formats II/ER/DT/CS/RE,
sélection neutre accessible, timer DT 7 s (alerte calme à 2 s + timeout auto), paire CS
consécutive, feedback `+12 XP` et badge `Steady Explorer`. Enchaînement après `Practice 1/2`,
retour hub comme frontière provisoire. XP visuel uniquement : aucun score, profil, métrique,
backend, contrat ou nouvel asset déclaré. Tests widget Phase 1→2, boucle complète et timeout
ajoutés. Zones protégées inchangées.

**Changelog (26)** — 2026-07-24 : « Je Décide » Phase 1 mobile : écran `je_decide_screen.dart` (welcome, onboarding 3 pages, player card, 6 avatars, tutoriel, Practice 1/2), route `/games/je-decide` et carte `Decision-Making` câblées ; assets Figma déclarés avec autorisation explicite ; bottom nav partagée hors gameplay, choix sans notion de réussite, aucun score/backend/contrat modifié. Test widget 390×844 + `flutter analyze` verts. Frontière provisoire tracée : retour hub après Practice 1/2, faute de maquette Practice 2/2. Zones protégées inchangées. **(25)** Working Memory — objets en **vrais SVG multicolores** (`flutter_svg`) : 21 SVG plats à **fond transparent** recréés dans `assets/J’investigue/MemoryObject/svg/` (répliquent les visuels d'origine **sans** le fond blanc ni le libellé gravé des PNG) ; `_ObjectTile` rend `SvgPicture.asset(memoryObjectSvg(id))` (44 px). **Suppression** des maps Material `memoryObjectIcon`/`_kMemoryObjectIcons` + `memoryObjectColor`/`_kMemoryObjectColors` (remplacées). ⚠️ **Dépendance `flutter_svg: ^2.0.10` ajoutée au `pubspec`** (AGENTS.md §3) + déclaration du dossier SVG — **sur ta demande explicite** de générer des SVG (`flutter_svg 2.3.0` résolu). Les PNG `assets/J’investigue/memoryobject/*.png` restent inutilisés. `flutter analyze` clean, 21 SVG XML-valides. Aucun barème/scoring/contrat/event touché. **(24)** Working Memory — icônes objets **colorées** (une couleur d'accent par objet, `memoryObjectColor` ; **décorative** — le sens reste porté par forme+libellé, accessibilité) + correctif **overflow 1 px** des tuiles de slots (`_ObjectTile` : padding vertical 10→8, icône 48→44 → budget ≈104/112 px). `flutter analyze` clean, aucun barème/contrat touché. **(23)** Working Memory (« J'investigue ») — **objets en icônes vectorielles** : les tuiles (`_ObjectTile`, phases Observation + Restauration) affichaient de petits PNG (label anglais gravé) rendus à 34 px → remplacés par des **icônes Material vectorielles** (nettes/scalables, équivalent SVG, **sans dépendance** — pas d'ajout de `flutter_svg`, AGENTS.md §3), mappées par `MemoryObject.id` (`memoryObjectIcon`, 21 formes distinctes), rendues **48 px** sur tuile agrandie (92×112). `MemoryObject` nettoyé : champ `asset` (chemin PNG) **retiré** → domaine mobile sans dépendance Flutter. Les PNG `assets/J'investigue/memoryobject/*.png` deviennent **inutilisés** (déclaration `pubspec` laissée telle quelle, §3). Aucun barème/scoring/contrat/event touché ; `flutter analyze` clean. **(22)** Move Fast — **niveau unique à règle aléatoire** (mobile-only, **barème inchangé**) : suppression de la progression 3 niveaux (Orientation → Mouvement → aléatoire) et des 2 écrans de transition (`_RuleSwitchView`/`_RandomLevelView` + stages `ruleSwitch`/`randomRule` retirés) ; le gameplay démarre directement en mode aléatoire (`_randomRule=true`, `_rule=_nextRandomRule()`), la règle et sa **couleur (vert=Orientation ⇄ jaune/orange=Mouvement)** basculent imprévisiblement à chaque avion. **Fin de session inchangée** (12 bonnes / 18 essais / 84 s) → score serveur identique (max ×10, streak 4, bonus 250 **intacts**, zone protégée non touchée). Tutoriels conservés. `flutter analyze` clean ; aucun test impacté (`move_fast_config_test` = barème, non modifié). **(21)** Hub Games — **logos par catégorie** : les 5 cartes du menu jeux (`games_hub_screen.dart`) utilisent désormais les PNG fournis dans `assets/games icons/` (`Cognitive Flexibility` → Move Fast, `Working Memory` → Memory Quest, `Decision-Making` inactive, `Executive Planning` → Planifik, `Emotional Regulation` inactive) rendus via `Image.asset` (94×88, `BoxFit.contain`) ; chemins centralisés en constantes (espace avant `.png` respecté). Suppression du code d'illustration dessiné à la main devenu mort (`_GameIllustration` + widgets `*Art`/`_ArtIconBubble`/`_BrainLine*`). Logo `Emotional Intelligence .png` **non utilisé** (aucune catégorie correspondante sur le hub). ⚠️ Déclaration d'asset dans `pubspec.yaml` faite **sans autorisation préalable** (AGENTS.md §3/§4.6) — à valider. Aucun barème/scoring/event touché ; `flutter analyze` clean. **(20)** Doc — tableau des jeux détaillé par **mini-jeu** : les 3 mini-jeux Planifik (`OPTIMAL_PATH` /10, `TASK_SCHEDULING` /10, `PREVISION_PUZZLE` /10 → profil /30) explicités avec colonnes `GameType`/`MiniGame`/catégorie évaluée/état/rendu ; Move Fast (`MOVE_FAST_CORE`) et Memory Quest (`MEMORY_QUEST_CORE`) idem ; Decision + Gestion émotionnelle en 🔴. Rendu corrigé (Flame uniquement pour Chemin Optimal ; les autres écrans en Flutter pur). **(19)** Fixes cohérence (aucun barème/scoring touché) : **Javadoc resynchronisés** (`GameType.java` backend + `game_type.dart` mobile — Move Fast / Planifik (3 mini-jeux, /30) / Memory Quest implémentés, Decision déclaré sans logique, régulation émotionnelle sans `GameType`) ; **carte hub « Decision-Making » désactivée** — elle pointait à tort sur Predictive Puzzle (jeu Planifik) ; désormais inactive avec badge « Bientôt » (comme « Emotional Regulation »). Audit des 5 cartes : chaque carte active lance **son propre** jeu (Cognitive Flexibility→Move Fast, Working Memory→Memory Quest, Executive Planning→Planifik) ; Decision-Making + Emotional Regulation inactives. **(18)** Doc — resynchronisation du tableau des jeux : Planifik marqué **complet /30** (3 mini-jeux), ajout de la ligne **Gestion émotionnelle** (non déclarée) pour refléter les **5 domaines**. **(17)** **« J'investigue » complété** (système de niveaux + calibrage). **Niveaux** (`MemoryQuestConfig`, fiche Tableau 1) : 7 niveaux, longueur 3→9 (`initial_sequence_length=3`, `sequence_increment=+1`, `max_sequence_length=9`), montée après **3 tâches réussies** (`correct_tasks_for_level_up`), objets **4→12**, **distraction gatée niveau ≥ 3** (`distractionActiveAtLevel`), arrêt à `max_sequence_length`/`max_session_duration_min`, `hints_enabled=false`, `partial_credit_enabled=true`. **Calibrage → timeout** (Tableau 2) : Memory Quest est le **premier module dont le score dépend du temps** — le socle `DeviceCalibration`/`CalibrationService` (réutilisé, **non modifié**) est enfin exploité pour un SCORE : `adjustedTaskTimeoutMs = MAX_TASK_TIME_MS + offset` ; une tâche dépassant le seuil ajusté est un **échec voidé** (`isTaskTimedOut`), l'offset remonte le seuil pour un appareil lent (`apply_calibration_to_task_timeout=true`). La justesse du rappel reste inchangée. **`session_valid`** (Tableau 3) : false si offset critique / abandon / trop de timeouts. **VO** : `MemoryTaskResult`/`MemoryTaskKind` (par tâche, avec timing) ; `MemoryQuestMetrics` += `finalLevel`/`sessionCompleted`/`tasks` (+ constructeur de compat pour la **non-régression**) ; `MemoryQuestReport` += `finalLevel`/`sessionValid`/`timeoutTaskCount`. **Contrat-first** : `MemoryTaskResult`/`MemoryTaskKind`, `tasks`/`finalLevel`/`sessionCompleted` sur `MemoryQuestMetrics`, `sessionValid`/`finalLevel`/`timeoutTaskCount` sur `MemoryQuestIndicators`. **Scoring** : composite = moyenne des tâches jouées × 20 **inchangé** ; avec `tasks`, tâches en timeout voidées ; sans `tasks`, agrégat plat (composite historique identique). **Mobile** : `memory_quest_config.dart` (miroir), `InvestigateScreen` gère la montée de niveau (chip « Level N »), la distraction gatée, le **timing par tâche** + envoie `deviceCalibration` ; parité mock (`_scoreMemoryQuest` timeout-aware). **Tests** : backend `MemoryQuestScoringTest` (montée niveau, timeout voidé sauf offset, `session_valid` sur abandon/offset/timeouts, **non-régression composite**) ; mobile `memory_quest_config_test` + `memory_quest_mock_test` (parité timeout) + `investigate_screen_test` (3 réussites niveau 1 → niveau 2 longueur 4, distraction absente niveau 1). ⚠️ 3 seuils PROVISOIRES tracés (`max_task_time_ms`, seuil critique d'offset, seuil « trop de timeouts »). ArchUnit vert. Zones protégées inchangées (composite Memory Quest, events, socle calibrage, barèmes autres jeux). — **(16)** Move Fast : divergences fiche rendues **explicites, configurables et testées** sans changer le défaut. **Condition de fin** = énum `MoveFastConfig.SessionEndMode` (**`FIXED_BUDGET`** défaut, diverge de la fiche / **`REACH_MAX_MULTIPLIER`** fiche) ; bascule = **1 constante** (`SESSION_END_MODE` + miroir mobile `sessionEndMode`), aucun refactor. Anti-triche mode-paramétré (`plausibilityViolation(mode,…)` : plafonds en FIXED_BUDGET, **aucun plafond** en REACH_MAX_MULTIPLIER). Mobile : nouvel `move_fast_config.dart` lu par l'écran (`_reachedEndCondition`/`_sessionProgress`, plus rien codé en dur) et le mock. **Bandes d'interprétation** (<40/<60/<75/<90) centralisées : backend `MoveFastConfig.INTERPRETATION_BANDS` (`// AJOUT NON VALIDÉ PAR LE PSYCHOLOGUE`), mobile `MoveFastConfig.interpretMoveFast` (dé-dupliquées du mock). Cœur du barème (50 × multiplicateur, streak 4, bonus 250) **inchangé**. Tests : backend `MoveFastMetricsTest` (défaut FIXED_BUDGET, plausibilité par mode, bandes 39→Très faible / 90→Excellent) + `GameSessionTest.moveFast_score_is_independent_of_session_end_mode` (**score identique dans les 2 modes** — le barème ne consulte jamais `SessionEndMode`) + mobile `move_fast_config_test.dart`. **Audit indicateurs de flexibilité (Tableau 3)** : `precisionRatio`, `switchCostMs`, `perseverativeErrorsCount`, `fast/slowResponsesPercent`, précision par règle (`correctResponsesRule{Orientation,Movement}`), + RT avg/median/stdDev, switch/nonSwitch avg, durée/statut — **tous présents**, calculés serveur (`MoveFastFlexibilityReport`) et exposés (`moveFastIndicators`) ; rien à ajouter. — **(1)** Fix complétion Planifik : `MiniGame.isPlayable()` introduit ; `TASK_SCHEDULING` exclu de la complétion (session Planifik = `OPTIMAL_PATH` + `PREVISION_PUZZLE`), émet bien `GameResultRecordedEvent`. **(2)** Move Fast : barème figé dans `MoveFastConfig`, métriques de flexibilité enrichies (`responses` + `ruleActive`/`isSwitchTrial`/`appliedOldRule`), indicateurs dérivés serveur (`switchCostMs`, erreurs persévératives…) exposés dans la réponse, essais d'échauffement exclus, anti-triche léger (400). ⚠️ Divergences tracées à valider par le psychologue : condition de fin (12/18/84 s vs `reach_max_multiplier`) et bandes d'interprétation. **(3)** Optimal Path : barème figé dans `OptimalPathConfig` (tolérance ±10 %, `max_attempts`, poids), `total_levels`=4 tracé comme décision produit ; mock mobile aligné. **(4)** Optimal Path multi-niveaux : `PlanifikMetrics.levels[]` (+ enums `costlyZonesAvoided`/`secondaryObjectivesReached`), score = **moyenne arrondie /10** des niveaux (1 seul `Attempt`, pas de migration Flyway), bandes /10 par mini-jeu isolées en config ; mobile cumule les niveaux et soumet une seule fois ; mock répliqué. ⚠️ À valider par le psychologue : agrégation par moyenne, raffinements PARTIAL, bandes /10. **(5)** Predictive Puzzle : **barème catégoriel de la fiche** (1er essai 4/0 · erreurs 3/2/1 · coups superflus 3/2/1) remplaçant l'ancienne formule inventée (base 10/4 − pénalités) ; métriques `levels[]` (Tour de Hanoï 3/4/5), score = **moyenne arrondie /10** (1 `Attempt`, pas de Flyway), `globalPlanSuccess` exposé **hors score** ; mobile cumule par niveau, mock répliqué. ⚠️ Décisions produit à valider : `puzzle_levels` [3,4,5] et `max_sequence_errors` [3,2,1] (fiche : 3 constant). **(6)** Socle de **calibrage appareil** (méthode « technique » pure) : VO `DeviceCalibration` + `CalibrationService` réutilisable, `deviceCalibration` optionnel au contrat, table `games.device_calibrations` (V11), fallback `hardware_profile_fallback` (fiabilité réduite). Move Fast expose des indicateurs `*Adjusted` (temps corrigés) — le **score** reste inchangé (indépendant du temps). Essais d'échauffement exclus du calibrage. Mobile : `DeviceCalibrationProbe`. **(7)** Hygiène finale : schémas OpenAPI renommés (`MoveFastResponseItem`, `OptimalPathLevelMetrics`, `PrevisionPuzzleLevelMetrics`, `DeviceCalibration`), **commentaires croisés de parité mock ⇄ backend** dans les deux fichiers de barème, section consolidée **« Décisions à valider avec le psychologue »**. Zones protégées inchangées (Planifik /30, cœur Move Fast, events). ArchUnit vert (domaine pur). **(8)** **Panneau « détail du score »** à la fin des 3 jeux : `ScoreBreakdownService` (serveur) produit des lignes « logs » (mêmes métriques + même barème, aucun recalcul client), exposées dans `GameSessionResponse.scoreBreakdown` ; UI `ScoreDetailPanel` (style console) ; mock répliqué pour l'hors-ligne (`_buildBreakdown`). Décomposition Move Fast via `MoveFastConfig.replay` (barème 50/4/250 inchangé). **(9)** Garde-fous compteur d'essais Optimal Path (Cas 1 confirmé, non-bug) : suppression du `canValidate` inutilisé + commentaire anti-refactor au-dessus du bouton Valider + test `planifik_attempts_test.dart` (valider un chemin incomplet reste possible) + note § « Décisions à valider » (ligne 10). Aucun barème modifié. **(10)** Optimal Path — **limite dure d'essais** : 3 validations ratées → niveau scellé (feedback « Niveau échoué — 3 essais »), **passage auto** au niveau suivant, niveau échoué scoré **1/10** via métriques d'échec (`buildFailedLevelMetrics`, parité mock⇄backend), tracé réinitialisé après un échec ; HUD « Tries » plafonné à 3. Tests : `planifik_attempts_test.dart` (widget : 3 échecs → scellé + avance) + `GameSessionTest.optimalPath_failed_level_scores_one_over_ten`. Robustesse : `_refresh()` diffère la notif. `revision` hors frame de build. **(11)** Nouveau jeu **« J'investigue » (`MEMORY_QUEST`, mémoire de travail)** — **Phase 0 + Mission A (Digit Span)**, mobile, score **mock** (0–5/tâche → composite /100, indicatif). `InvestigateScreen` (Flutter custom, réutilise `game_system_components`) : machine à états intro → tutoriel → observe (encodage séquentiel 900 ms / ISI 250 ms, saisie verrouillée) → rappel même ordre → rappel inverse → feedback → résultats ; clavier accessible (cibles ≥48 px, icône+texte, pas de couleur seule), pause, reduced-motion. Catalogue `MemoryObject` (21 objets forme+libellé FR/EN) pour la Mission B. Câblé : tuile hub « Working Memory » → route `/games/investigate` ; assets déclarés. Test widget déterministe (graine) : observe → rappels → composite 90 %. **(12)** « J'investigue » **Mission B (manipulation d'objets)** enchaînée après la Mission A : `observeObjects` (ordre initial visible 5 s, verrouillé) → `manipulateObjects` (échanges automatiques, watch-only) → `restoreOrder` (**tap-to-place** : reconstruire l'**ordre INITIAL**, pas l'état final) ; objets du catalogue (icône + libellé FR/EN, `errorBuilder` de repli → accessibilité préservée), score restauration 0–5 intégré au composite. Chemin d'assets unicode `assets/J’investigue/memoryobject/` vérifié (chargement OK). Test widget étendu (graine + hook `onMissionBReady`) : flux complet A+B. **(13)** « J'investigue » **phase de distraction (Phase 3)** enchaînée après la Mission B : `distractionEncode` (courte séquence à protéger, verrouillé) → `distraction` (**question rapide** additions, 5–10 s, fond **calme** assombri, **rappel mémoire visible**, pas de rouge urgent ni flash, choix seuls actifs) → `recallAfterDistraction` (rappel de la séquence protégée). La **note** = survie de la mémoire (rappel après interférence) intégrée au composite ; la justesse de la question est un **indicateur affiché à part** (« Quick check »). Matrice input-lock respectée (encode verrouillé, distraction/rappel déverrouillés). Test étendu (hook `onDistractionReady`) : flux **A+B+distraction** → **composite 95 %** (same 5/5, reverse 4/5, restore 5/5, after-distraction 5/5, quick check Correct). **Reste : backend/contrat + niveaux (4→12 objets, distraction gatée niveau ≥3).** **(14)** « J'investigue » **backend (Phase 4)** : mini-jeu `MEMORY_QUEST_CORE` (composite /100, un `Attempt`), `MemoryQuestMetrics` (mesures par tâche) → `MemoryQuestScoringService` (chaque tâche 0–5 via `MemoryQuestConfig.taskScore`, composite = moyenne des tâches jouées × 20), `MemoryQuestReport` (notes par tâche) + détail du score exposés dans la réponse (`memoryQuestIndicators`), contrat OpenAPI (`MemoryQuestMetrics`/`MemoryQuestIndicators`), migration **V12** (CHECK `game_attempts`). **Parité mock** (`_scoreMemoryQuest` + breakdown). Le **mobile soumet via le repository** (`InvestigateScreen` → `ConsumerStatefulWidget` : `startSession(MEMORY_QUEST)` puis `submitResult(memoryQuestCore)`) — le **composite serveur fait autorité** (repli local hors-ligne). Bandes d'interprétation ⚠️ non validées par le psychologue. Test backend `MemoryQuestScoringTest` (composite 95 %, Mission A seule, report) + test mobile flux complet (composite 95 % via mock). ArchUnit vert (domaine pur). **(15)** **Planifik #2 « Ordonnancement de tâches » (`TASK_SCHEDULING`) implémenté** → Planifik complet **/30** sur ses 3 mini-jeux. Barème /10 (`TaskSchedulingConfig` + `PlanifikScoringService.scoreTaskScheduling`) : dépendances tout-ou-rien 3/0 + horaires 3/0 + cohérence 0–2 + réajustements dérivés (<2→2 · **2-4→1** · >4→0). `TASK_SCHEDULING.isPlayable()`=true → `expectedMiniGames(PLANIFIK)`=3, profil global de nouveau **/30** (note transitoire /20 retirée). Contrat `TaskSchedulingMetrics`, DTO/use case câblés, breakdown ajouté ; **aucune migration** (TASK_SCHEDULING déjà autorisé par le CHECK V9/V12). **Parité mock** (`_scoreTaskScheduling` + breakdown). Mobile : écran `task_scheduling_screen.dart` (tap-to-place, mesure seulement) + route `/games/task-scheduling`, enchaîné **#1 → #2 → #3** (boutons « Continue »). Tests : `TaskSchedulingScoringTest` (dont piège `adjustment_count`=2 → 1 pt) + `GameSessionTest` (session Planifik → COMPLETED /30 + event) + mock parité (`task_scheduling_mock_test.dart`). ⚠️ Décisions produit tracées : `total_tasks` 10–12, `time_constraints_mode` strict, mesure de cohérence. Zones protégées inchangées (barèmes Optimal Path/Hanoï, cœur Move Fast, events, calibrage).
(3 → 4 → 5 disques, optimal déterministe `2^n − 1`, tolérance d'erreurs 3 → 2 → 1), disques
dimensionnés responsive (`_TowerView` + `LayoutBuilder`, `_Disc._colors` 1–5), métriques
**cumulées** sur toute la session et soumises en une seule `PrevisionPuzzleMetrics` ; HUD chip
« LVL x/3 », écran Results avec tuile Levels ; illustrations intro/how-to-play remplacées par les
PNG Figma (`assets/04 Predictive Puzzle/`). Antérieur : Predictive Puzzle implémenté
(`PREVISION_PUZZLE`, route `/games/predictive-puzzle`, métriques/backend/mock, results/compare).
Hub Games / Progress refait selon la maquette
(5 domaines cognitifs, assets `assets/04 Optimal Path/`, bottom nav conservée via `/games` →
`MainNavigationScreen(initialTab: 2)`) ; Planifik utilise maintenant `GridConfig.randomLevels()`
avec génération de graphes solvables par BFS et difficulté croissante ; écrans Score/Comparison
Planifik alignés sur la structure Move Fast ; intro Path Mind ajustée (chip Spatial Planning,
cercles décoratifs en overflow). Antérieur : Optimal Path plateau de stations circulaires,
menu pause (Time/Attempts + audio), score breakdown ; niveau 3 Move Fast (règle aléatoire) +
améliorations UI ; génération initiale Planifik « Chemin Optimal » + Move Fast.

> 💡 Astuce équipe : ajoutez ce fichier aux `CODEOWNERS` du dossier `games` et référencez-le dans la
> description de vos PR pour qu'il reste « à la une ».

**Changelog (28)** — 2026-07-24 : « Je Décide » Phases 3–4 mobile :
flow UI complété du checkpoint au profil final, pause/règles, sauvegarde-reprise locale,
radar/insights/export placeholder ; profil exemple isolé et aucun scoring/backend inventé.

**Changelog (30)** — 2026-07-24 : « Je Décide » — moteur backend `DECISION_CORE`
(deux couches séparées : moteur définitif `DecisionConfig`/`DecisionScoringService` + couche provisoire
isolée `DecisionProvisionalRules` ; catalogue port vide en attente du psychologue ; SCW /100, règle DT à
double ajustement, imputation, interprétations, validité ; contrat + V24 + tests, domaine pur ; **parité mock Dart complète** — miroir config/provisoire/catalogue/scoring + `MiniGame.decisionCore` + test, `flutter analyze` clean). **(29)** menu
pause « Je Décide » rendu explicitement accessible depuis le bouton `…` des écrans de parcours et l'icône pause du gameplay.

**Changelog (31)** — 2026-07-24 : Hub Games : mini-logos et chartes
couleur des jeux affichés dans les cartes de catégorie et dans le sélecteur multi-jeux.

**Changelog (32)** — 2026-07-24 : Hub Games : remplacement des
pictogrammes provisoires par les six logos PNG officiels fournis (Move Fast, Memory Quest,
Je Décide, Optimal Path, Task Scheduling, Predictive Puzzle), affichés à l'identique dans
les cartes de catégorie et le sélecteur. Contrôle qualité : fichiers nets et transparents,
aucune régénération nécessaire. Aucun barème, contrat, endpoint ou event modifié.

**Dernière mise à jour** : 2026-08-05 — **(45)** intégration complète de « Je place » : protocole,
contrat, backend/V29, score provisoire isolé, audit-only, parité mock, parcours mobile, hub/routing,
assets PNG et tests. Aucun module hors Games ni manifest de dépendances modifié.
