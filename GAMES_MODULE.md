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
| **Planifik #2 — Ordonnancement de tâches / Day Stack** | `PLANIFIK` | `TASK_SCHEDULING` | Planification — dépendances + contraintes horaires + cohérence + réajustements | 🟢 Jouable **/10**, liste complète à réordonner, glissements sans pénalité et validation explicite | Flutter (appui maintenu sur la carte) |
| **Planifik #3 — Tour de Hanoï** | `PLANIFIK` | `PREVISION_PUZZLE` | Planification — anticipation / planning prévisionnel | 🟢 Jouable **/10** — 3 niveaux (3→4→5 disques) | Flutter custom |
| ↳ **Planifik — « Je planifie » (domaine)** | `PLANIFIK` | *(les 3 mini-jeux ci-dessus)* | Planification | 🟢 **Complet** — profil global **/30** | Flame + Flutter |
| **Move Fast — « Je bouge »** | `MOVE_FAST` | `MOVE_FAST_CORE` | Flexibilité cognitive — switching de règles (niveau unique : Orientation ⇄ Mouvement **aléatoire**) | 🟢 **Complet** — barème d'escalade (50 × mult., streak 4, bonus 250) | Flutter custom |
| **« Je continue » — Focus Stream** | `CONTINUOUS_ATTENTION` | `CONTINUOUS_ATTENTION_CORE` | Attention soutenue et sélective — protocole Long Rosvold CPT X/AX | 🟢 **Complet /100 PROVISOIRE** — 44 blocs, 1 364 essais, score de balanced accuracy isolé ; d′/c/RT descriptifs | Flutter custom |
| **« Je coordonne » — Sync Square** | `VISUOMOTOR_COORDINATION` | `COORDINATION_TRACKING_CORE` | Coordination visuo-motrice — suivi continu d'une cible sur trajectoire carrée fixe horaire | 🟢 **Complet /100 PROVISOIRE** — 2 segments de pratique + 12 tests ; précision globale seule dans le score, autres indicateurs descriptifs | Flutter custom |
| **Memory Quest — « J'investigue »** | `MEMORY_QUEST` | `MEMORY_QUEST_CORE` | Mémoire de travail — Mission A (digit span) + B (objets) + distraction | 🟢 **Complet** — 7 niveaux (3→9), calibrage → timeout (score dépend du temps), `session_valid` ; composite **/100** | Flutter custom |
| **« Je place » — Place & Bind** | `VISUOSPATIAL_MEMORY` | `OBJECT_LOCATION_BINDING_CORE` | Mémoire visuo-spatiale — liaison objet-emplacement sur grille 4×4 | 🟢 **Complet /100 PROVISOIRE** — pratique à 2 objets puis 6 niveaux de 3→8 objets ; layouts reconstruits serveur, indicateurs secondaires descriptifs | Flutter custom |
| **« Je Décide »** | `DECISION` | `DECISION_CORE` | Prise de décision (ER, DT, CS, RE — /18 chacune → /72 → SCW /100) | 🟢 **Jouable end-to-end** (V59) : banque historique de 120 items en base, 24 items actifs de la forme A servis par `GET /decision/items`, notation serveur. ⚠️ CS et RE en **notation neutre provisoire** (modèles λ/k/cohérence non implémentés) ; formes B/C/D différées | Flutter (UI) / Java (moteur + contenu) |
| **Emotional Radar — « Je gère »** | `EMOTIONAL_REGULATION` | `EMOTIONAL_RADAR_CORE` | Régulation émotionnelle — reconnaissance d'émotion (famille + nuance + intensité) | 🟢 Jouable **9 pts/scène** — 3 scènes rédigées (27), 15 visées (135) ; **contenu servi par le backend** | Flutter custom |
| **Reflective Pause — « Je gère »** | `EMOTIONAL_REGULATION` | `REFLECTIVE_PAUSE_CORE` | Régulation émotionnelle — contrôle de l'impulsivité sous pression | 🟢 **Complet /10** — 10 moments, pause minimale 3 s, résultats + insights calculés serveur | Flutter custom |
| **Strategic Choices — « Je gère »** | `EMOTIONAL_REGULATION` | `STRATEGIC_CHOICES_CORE` | Régulation émotionnelle — choix contextualisé d'une stratégie de coping | 🟢 Jouable **/30 PROVISOIRE** — 80 situations, 10 tirées ; 6 messages écrits et 74 scènes vidéo dont les médias restent à produire ; score serveur | Flutter custom + Java |
| **BART — Balloon Analogue Risk Task** | `DECISION_BEHAVIORAL` | `BART_CORE` | Prise de décision comportementale — risque révélé (Lejuez 2002) | 🟢 **Jouable /100 PROVISOIRE** — 2 ballons d'entraînement + 30 notés, point d'éclatement uniforme 1..128 dérivé de l'UUID ; score = efficience face à la stratégie fixe optimale (64 pompes) sur les mêmes ballons ; appétence au risque descriptive, non classée ; événement Fit Score suspendu | Flutter custom + SVG |
| **IST — Information Sampling Task** | `DECISION_BEHAVIORAL` | `INFORMATION_SAMPLING_CORE` | Prise de décision comportementale — recueil d'information / impulsivité de réflexion (Clark 2006) | 🟢 **Jouable /100 PROVISOIRE** — 2 entraînements + 10 gain fixe + 10 gain décroissant ; P(correct) exact sous la loi de génération ; couche confiance = biais de calibration seul ; événement Fit Score suspendu | Flutter custom |

**Tutoriel mobile Radar V2 (2026-09-17)** : cinq cartes illustrées centrées sur le
fond blanc habituel, comme Day Stack ; contenu aligné sur le parcours V2 actuel
(choix direct parmi 6/9 émotions, intensité à trois niveaux, budget commun de 30 s,
15 scènes). Les descriptions de famille/nuance et barèmes V1 conservées ci-dessous
concernent le parcours historique ; cette refonte de présentation ne les modifie pas.
En phase A V2, les médias restent provisoires et le tutoriel ne promet aucun score
normatif ni nouvelle tentative soumise.

> **Barème par mini-jeu** : Chemin Optimal / Ordonnancement / Tour de Hanoï → **/10** chacun ; leur somme = **profil Planifik /30**. Move Fast → points d'escalade (normalisés /100 pour l'interprétation). « Je continue » → balanced accuracy X/AX **/100 PROVISOIRE**, sans temps, d′ ni biais c dans le score. « Je coordonne » → précision globale pondérée par le temps, arrondie **/100 PROVISOIRE** ; précisions par vitesse/durée et distance moyenne restent descriptives. Memory Quest → **composite /100**. « Je place » → placements exacts / objets administrés sur les niveaux test, arrondis **/100 PROVISOIRE** ; swaps, distances, temps et pente de charge restent descriptifs. Emotional Radar /27 actuel + Reflective Pause /10 + Strategic Choices /30 → somme émotionnelle brute provisoire **/67** ; la normalisation du profil émotionnel /30 reste à valider. Score **toujours calculé serveur** (le client n'envoie que des métriques brutes).

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

> **BART + IST (98)** — `domain/config/{Bart,Ist}Config` (moteur, protocoles publiés) et
> `{Bart,Ist}ProvisionalRules` (tout le provisoire) ; `domain/service/BartSequenceGenerator`,
> `BartActionReplayer`, `BartScoringService`, `IstLayoutGenerator`, `IstPosteriorModel`
> (P(correct) exact), `IstActionReplayer`, `IstScoringService`, `MetacognitionService`
> (biais de calibration seul), `DecisionBehavioralStatistics` ; VO `Bart*` / `Ist*` ; port
> `DecisionBehavioralMetricsRepository` + adaptateur JDBC ; migration `V86`.

| Couche | Fichier | Rôle |
|--------|---------|------|
| **api** | `api/GamesController.java` | Contrôleur REST `/api/v1/games`. Traduit HTTP → commande, délègue au use case. Aucune logique métier. |
| | `api/GamesAdminController.java` | API `/api/v1/games/admin/**` réservée à `ROLE_ADMIN` : questions éditoriales, banques versionnées, paramètres hors scoring, assets et audit. |
| | `api/GamesAssetController.java` | Livraison authentifiée des assets administrés **publiés** ; les brouillons/archives restent invisibles aux clients de jeu. |
| | `api/GamesExceptionHandler.java` | Traduit localement payload/état invalide, propriété étrangère et ressource absente vers le format d'erreur commun en **400/403/404**, sans modifier `shared`. |
| | `api/dto/StartSessionRequest.java` | Body `POST /sessions` — `gameType` (le joueur vient du JWT). |
| | `api/dto/SubmitResultRequest.java` | Body `POST /sessions/{id}/results` — `miniGame` + payload union `Metrics` → `toMetrics()`. |
| | `api/dto/GameSessionResponse.java` | Réponse : état complet de la session + snapshot runtime immuable (banque/settings/modifiers), score composite + attempts + indicateurs propres au mini-jeu, dont **`reflectivePauseIndicators`**, **`continuousAttentionIndicators`**, **`coordinationIndicators`** et **`objectLocationIndicators`**. |
| | `api/dto/ScoreResponse.java` | Sérialisation d'un `Score`. |
| **application** | `application/usecase/StartGameSessionUseCase.java` | Charge le snapshot publié, refuse une nouvelle partie si `sessionEnabled=false`, puis crée l'agrégat `GameSession.start(...)` et le persiste. Une session déjà ouverte n'est jamais interrompue. |
| | `application/usecase/ManageGamesAdminUseCase.java` | Orchestre les brouillons, publications atomiques et uploads de la console ; ne dépend d'aucun service de scoring. |
| | `application/usecase/SubmitGameResultUseCase.java` | Charge la session avec verrou d'écriture, vérifie le propriétaire JWT, calcule le `Score` (domaine), enregistre et persiste. Il publie les Domain Events depuis **l'agrégat muté** (la copie réhydratée n'en contient pas), puis les listeners transactionnels agissent après commit. Pour « Je continue », « Je coordonne » et « Je place », une capture techniquement invalide reste audit-only (`IN_PROGRESS`, aucun `Attempt`/event) ; une structure ou séquence invalide est refusée sans écriture. Pour « Je place », même l'Attempt valide ne publie provisoirement aucun event Fit Score tant que le barème n'est pas validé. |
| | `application/command/StartGameSessionCommand.java` | `(playerId, gameType)`. |
| | `application/command/SubmitGameResultCommand.java` | `(sessionId, playerId issu du JWT, miniGame, GameMetrics, deviceCalibration?)`. |
| **domain / model** | `domain/model/GameSession.java` | **Racine d'agrégat**. Invariants : 1 résultat/mini-jeu, refus d'un mini-jeu étranger au type, complétion auto + émission d'event au dernier mini-jeu. Java pur. |
| | `domain/model/GameRuntimeSnapshot.java` | Snapshot Java pur, défensif et immuable de la banque et des configurations publiées au démarrage de la session. |
| | `domain/model/AdminConfigurationSchemaRegistry.java` | Source unique Java pure des 16 schémas `GameType × SETTINGS/MODIFIERS` : types, bornes, enums, valeurs par défaut et allowlist stricte hors scoring. |
| | `domain/model/AdminModels.java` · `domain/repository/GameAdminRepository.java` | Modèle Java pur et port de persistance de l'administration. Rejette les clés de scoring dans les configurations modifiables. |
| **infrastructure / admin** | `infrastructure/persistence/JdbcGameAdminRepository.java` | Projection unifiée des catalogues Je Décide / Emotional Radar, versions, rotations et audit via JDBC. |
| **migration / admin** | `V69__games_admin_console.sql` | Tables de brouillons, banques/items, configurations hors scoring, assets et audit ; seed des catalogues existants, sans modifier les tables de score. |
| | `V70__games_admin_full_control.sql` | Sépare SETTINGS/MODIFIERS, garantit une seule version publiée par jeu/type et une seule version publiée par code de question. |
| | `V71__games_runtime_configuration_snapshot.sql` · `V72__games_runtime_bank_snapshot.sql` | Figent versions et JSON de settings/modifiers ainsi que banque/code/version/type sur chaque session, afin qu'une publication admin ne modifie jamais une partie en cours. |
| | `V73__games_admin_radar_answer_reference.sql` | Autorise la référence d'une réponse Radar vers une scène système ou une scène administrée publiée/archivée, avec contrôle différé d'intégrité. |
| | `V74__games_admin_configuration_defaults.sql` · `V75__games_admin_normalize_legacy_configurations.sql` | Garantissent 8 versions `SETTINGS` + 8 `MODIFIERS` publiées et normalisent les anciens blobs libres vers l'allowlist typée en archivant l'historique, sans toucher aux valeurs de score. |
| **mobile / runtime** | `domain/entities/game_runtime_snapshot.dart` | Projection Dart du snapshot runtime exposé par Spring ; helpers typés et valeurs de repli sûres. |
| **web admin** | `admin/apps/web/src/features/admin/admin-app.tsx` | Shell TanStack Start responsive : authentification JWT ADMIN, navigation, rafraîchissement et gestion d'erreurs. |
| | `admin/apps/web/src/features/admin/admin-pages.tsx` | Dashboard réel avec catalogue mobile par catégories, fiche dédiée pour chacun des 13 jeux, accès contextualisé aux questions/banques/settings/modifiers/assets, catalogue paginé et audit ; les brouillons de configuration exposent leur écart exact avec la version publiée et passent par une revue d'impact avant publication. |
| | `admin/apps/web/src/features/admin/admin-editor.tsx` | Éditeurs complets : création/modification/clonage, composition ordonnée, publication, archivage et suppression sûre des brouillons ; toute nouvelle configuration reprend les valeurs publiées du jeu, puis affiche en direct les changements avant/après avec des switches, nombres bornés et enums décrits par Spring, sans textarea JSON. |
| | `admin/apps/web/src/features/admin/admin-api.ts` | Client Spring unique ; chargement parallèle des ressources, aucune donnée de démonstration. |
| | `admin/apps/web/public/assets/**` | Copies web des PNG officiels des 13 jeux et des 5 catégories, du logo splash et des 21 objets SVG originaux ; les assets Flutter sources ne sont pas modifiés. |
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
| | `resources/db/migration/V61__games_continuous_attention.sql` | Ajoute le type/mini-jeu, `continuous_attention_runs`, `continuous_attention_trials` et l'index unique partiel empêchant deux Attempts valides. |
| **Je coordonne** | `domain/config/CoordinationConfig.java` | Source de vérité de `FIXED_SQUARE_CW_V1` : carré fixed-point, 2 segments de pratique + 12 tests, durées 7000/2333 ms, tours lent/rapide, géométrie et fenêtres de validité. Java pur ; miroir Dart obligatoire. |
| | `domain/config/CoordinationProvisionalRules.java` | **Score /100 PROVISOIRE** isolé et remplaçable : précision globale pondérée par le temps, unique arrondi half-up ; aucune sous-précision ni distance dans le score. |
| | `domain/service/CoordinationTrajectoryService.java` | Reconstruit de manière déterministe la position de la cible sur le carré fixe horaire, sans easing ni saut aux changements de segment/vitesse. |
| | `domain/service/CoordinationScoringService.java` | Rejoue la trajectoire sur la timeline canonique serveur et réintègre cible mobile + pointeur maintenu sur une grille de **1 ms** : une trace clairsemée ne peut pas fabriquer un suivi parfait. Calcule précision, distance et validité ; une frontière test hors tolérance rend `technicalValid=false`. |
| | `domain/vo/Coordination{Metrics,InputSource,Phase,PointerSample,Report,SegmentMetric,Speed}.java` | Trace brute auto-validante (14 segments contigus, positions fixed-point, source d'entrée, interruptions) et rapport descriptif serveur. Le client ne transmet ni cible, ni distance, ni score. |
| | `domain/repository/CoordinationMetricsRepository.java` | Port de remplacement transactionnel du run et de ses échantillons bruts, y compris l'audit-only invalide. |
| | `infrastructure/persistence/CoordinationMetricsRepositoryAdapter.java` | Persistance batch V28 de la trace après validation du domaine. |
| | `resources/db/migration/V62__games_visuomotor_coordination.sql` | Autorise `VISUOMOTOR_COORDINATION` / `COORDINATION_TRACKING_CORE` et persiste le run, les segments/échantillons et leur audit de validité. |
| **Je place** | `domain/config/ObjectLocationConfig.java` | Source de vérité `OBJECT_LOCATION_FINE_V1` : grille 4×4, pratique 2 objets, charges test 3→8, timings, réserves et progression. Toutes les valeurs de protocole non fournies sont marquées provisoires ; miroir Dart obligatoire. |
| | `domain/config/ObjectLocationProvisionalRules.java` | **Score /100 PROVISOIRE** isolé et remplaçable : placements exacts / objets administrés, unique arrondi half-up ; temps, swaps, distances et pente de charge exclus. |
| | `domain/service/ObjectLocationLayoutGenerator.java` | Reconstruit depuis `sessionId|OBJECT_LOCATION_FINE_V1` le catalogue, les objets, leurs cellules et leur ordre de réserve avec FNV-1a 32 bits, xorshift32 et Fisher–Yates. |
| | `domain/service/ObjectLocationActionReplayer.java` · `ObjectLocationScoringService.java` | Rejoue les poses/retours/éjections, classe chaque objet de façon exclusive (`EXACT`, `SWAP`, `LOCAL`, `GLOBAL`, `UNPLACED`), dérive les indicateurs et valide timing/progression côté serveur. |
| | `domain/vo/ObjectLocation*.java` | Actions et niveaux bruts auto-validants, enums de phase/réserve/fin, rapports descriptifs ; aucune origine, catégorie d'erreur ou note n'est acceptée du client. |
| | `domain/repository/ObjectLocationMetricsRepository.java` · `infrastructure/persistence/ObjectLocationMetricsRepositoryAdapter.java` | Port + adaptateur JDBC de remplacement transactionnel d'un run, de ses niveaux et de ses actions, y compris l'audit-only invalide. |
| | `resources/db/migration/V63__games_object_location_memory.sql` | Autorise `VISUOSPATIAL_MEMORY` / `OBJECT_LOCATION_BINDING_CORE`, crée les trois tables d'audit et protège l'unique Attempt valide par session. |
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

**Day Stack — calendrier mobile du 2026-09-16 (choix utilisateur)** : le plateau
reprend la lecture de la vue Jour Outlook sur le fond mauve Games. Les tâches sont
présentées comme des rendez-vous mauves, avec titre blanc, badge de catégorie,
durée, contraintes et dépendances lisibles. Une seule colonne horaire à gauche
remplace la répétition début/fin dans chaque carte. Le calendrier défile verticalement,
avec barre de défilement visible et auto-scroll lors du réordonnancement ; Valider
reste fixe, centré et limité à 280 px. Le compteur de déplacements est retiré.
Une zone de validation séparée par un trait fin occupe sa propre hauteur hors du
calendrier, dont le rendu est découpé à sa zone défilante. Une marge de fin de liste
permet de dégager entièrement la dernière tâche au-dessus du bouton. Les créneaux courts s'étirent pour conserver les consignes lisibles :
la grille est un agenda adapté au jeu, pas une échelle temporelle strictement uniforme.
Le composant `presentation/widgets/day_stack_calendar.dart` réutilise la palette
Games et `DayStackTaskBadge`. Pendant le glissement, seule la carte est soulevée ;
les plages d’attente, la carte source atténuée et la grille horaire restent en place.
L’heure de début reste tracée même après une plage d’attente.
L’ordre et les horaires se recalculent uniquement au dépôt. Aucun changement du
calcul des horaires ni du score.
Référence : [vue calendrier Outlook mobile](https://support.microsoft.com/en-us/outlook/optimize-the-outlook-mobile-app-for-your-ios-or-android-phone).

**Day Stack — emotes par tâche (2026-09-16, demande utilisateur)** : une collection
v1 est générée et vérifiée pour les **82 tâches / 7 univers**, dans
`mobile/assets/Day Stack/emotes-v1/`. Les objets illustrés en 2.5D reprennent les
formes arrondies, le bleu marine, le mauve, le magenta et le blanc cassé de la charte,
avec un accent de catégorie existant et un contour clair pour les cartes mauves.
Les PNG gardent leur fond transparent. `manifest.json` associe chaque image à
**univers + identifiant de tâche**, aux quatre variantes et au prompt exact ; la
clé composée évite les collisions comme `chargement_camion` entre univers.
`index.html` propose une galerie avec recherche et trois fonds de relecture.
Choix visuels provisoires : voir décision 61.

**Day Stack — emotes intégrées au calendrier (2026-09-17, plan 001)** : chaque
carte affiche l’emote de sa tâche à la place du carré coloré. `DayStackTaskBadge`
reçoit deux paramètres optionnels `universeId` / `taskId` ; le chemin vient de
`dayStackEmoteAssetPath` (`presentation/widgets/day_stack_emotes.dart`), sans
lecture du manifest à l’exécution. La clé reste le couple univers + tâche : ni le
libellé tiré, ni la catégorie, ni l’ancienne icône ne choisissent l’image.
Le calendrier transmet l’univers à la carte, à sa source atténuée et au proxy de
glissement par le même `_event()` : l’image suit la carte après réorganisation.
Taille 32 px en compact (décision 62), 38 px en normal, `BoxFit.contain`, sans carré
coloré ; le liseré de catégorie reste. Décodage limité par `cacheWidth` = taille ×
densité d’écran, arrondi au supérieur (≈ 96 px au lieu de 1254 px sur un écran ×3) ;
cela réduit la mémoire, pas le poids de l’APK. Repli : sans identité, carré
historique 28/38 px ; si le PNG ne charge pas, même carré dans la boîte 32/38 px
pour éviter un saut de mise en page. L’image est décorative (`excludeFromSemantics`)
et la catégorie n’est plus annoncée deux fois. Les sept dossiers d’univers sont
déclarés dans `pubspec.yaml` avec autorisation explicite ; manifest, galerie, prompts
et planches de relecture ne sont pas embarqués. Une nouvelle tâche exigera une
nouvelle emote et la mise à jour du manifest.

**Day Stack — mission permanente (2026-09-16, demande utilisateur)** : sous la
manche, une phrase verte reste visible pendant le défilement. Elle clignote une
seule fois pendant 460 ms à l’entrée de chaque manche, puis reste stable, comme
dans Memory Quest Image/Digits ; le défilement ne relance pas l’effet. Son contexte
change avec l'univers ; toutes se terminent par « maintiens puis déplace les tâches
en respectant horaires et étapes. » :

| Univers | Début de la mission |
|---------|--------------------|
| Restaurant | Prépare le service du restaurant |
| Bureau | Organise la journée au bureau |
| Événement | Prépare l’événement |
| Chantier | Organise les travaux du chantier |
| Entrepôt | Prépare les commandes de l’entrepôt |
| Soins | Organise la tournée de soins à domicile |
| Déménagement | Prépare le déménagement |

Les libellés vivent dans `_GameplayViewState` de `task_scheduling_screen.dart` ;
ils ne modifient ni les tâches de la banque, ni les horaires, ni la notation.
Le texte n'est pas tronqué et suit le grossissement accessible. Le composant
partagé `presentation/widgets/memory_prompt.dart` porte la couleur et le
clignotement ; ses options `style` / `textAlign` permettent le format compact
Day Stack sans changer le rendu Memory Quest. Les animations désactivées
conservent la consigne visible, sans effacement. Le test couvre les
sept univers à 320×568 et la persistance de la mission pendant le défilement.

**Day Stack — interaction du 2026-09-11 (choix utilisateur)** : les déplacements
restent libres, sans alimenter
`proactiveAdjustments` / `reactiveAdjustments` (restent à zéro). Les formules serveur/mock
actuelles sont conservées : la composante d’autorégulation ne pénalise donc plus les
réorganisations. Dépendances, horaires, collisions et temps morts ne sont évalués qu’à
« Valider » ; le dernier niveau déclenche immédiatement la soumission cumulée.
Le débrief reste consultable avant l’affichage du score reçu. La latence initiale est
mesurée au premier déplacement, ou à la validation si le joueur conserve l’ordre initial.

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

**Tutoriel mobile (2026-09-17)** : cinq cartes illustrées centrées sur le fond
blanc habituel, avec balayage, précédent/suivant et bouton de démarrage final.
L’aide réutilise ce contenu en plein écran et revient au menu pause sans perdre
le choix en cours. Étapes : découvrir le support, attendre le déverrouillage,
choisir naturellement parmi cinq réponses, valider, consulter le bilan après dix
situations. Le délai de réflexion reste administrable ; le texte n’annonce pas
une durée fixe. La barre suivante reste un temps conseillé sans verrouillage.
Le barème, les métriques et le protocole de passation restent inchangés.

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
`EMOTIONAL_REGULATION` incomplète et la réutilise entre Emotional Radar, Reflective Pause et
Strategic Choices. La session se complète après les trois tentatives ; avec les 3 scènes Radar
actuelles, la somme brute est provisoirement **/67** (27 + 10 + 30). La normalisation globale /30
reste différée.

### 🧭 « Je Décide » (`DECISION_CORE`) — moteur définitif + couche provisoire isolée

Test de frontière API : `backend/src/test/java/com/zennyt/games/api/dto/DecisionSubmissionContractTest.java`
valide le décodage Jackson de `decisionItems` et le rejet de `items` en soumission,
avec choix, chronométrage, changement d'avis et réponse expirée préservés.

Prise de décision (fiche « JE DÉCIDE »). Architecture **imposée : deux couches strictement séparées**. Le moteur ne code jamais une valeur provisoire — il la lit dans le seul fichier `DecisionProvisionalRules`. Remplacer le provisoire ne demande **aucune** modification du moteur.

**Couche MOTEUR (définitive — `DecisionConfig` + `DecisionScoringService`)**
- **Structure active — retrait II autorisé le 2026-09-17** : 4 dimensions (`ER, DT, CS, RE`), **6 items/dimension**, 24 items notés, item /3, 3 items d'entraînement, ordre des blocs randomisé, mode évaluation, score **jamais** montré au joueur.
- **Agrégation** : dimension = somme des 6 items → **/18** ; brut = somme des 4 dimensions actives → **/72** ; score agrégé du mini-jeu = **SCW /100** (un seul `Attempt`, `rawPoints=SCW`, `maxPoints=100` ; détail par dimension dans la réponse API).
- **Règle DT** (seule dimension dont le score dépend du temps) : temps imparti effectif = `7 s × multiplicateur_langue + calibration_offset_ms` (**double ajustement** langue puis calibrage, socle `CalibrationService` réutilisé, non modifié). Correct (option OPTIMALE) et latence **< 75 %** → **3** ; correct mais **≥ 75 %** → **2** ; incorrect → **score de qualité de l'option**. Multiplicateurs **fournis** : `en 1.00 · fr 1.20 · de 1.25`.
- **Imputation** : ≤ 2 items manquants dans un bloc → chaque manquant imputé par la **moyenne du bloc** (⇔ moyenne des présents × 6) ; **> 2 → bloc non exploitable** (exclu du SCW, `exploitable=false`).
- **Interprétations automatiques** (textes de la fiche) : SCW ≥ 75 → *fonction décisionnelle élevée* · ER élevé + RE bas → *prise de risque sous émotion* · DT élevé → *bonne performance sous pression*.
- **Qualité de session** : `avgTimePlausible`, `impulsiveRateOk`, `randomResponseRateOk`, `deviceLatencyWithinNorm` → `sessionUsable` ; contrôles **renforcés** en mode non supervisé.
- **Indicateurs** : RT moyen/médian/écart-type, `impulsiveResponsePercent`, `slowResponsePercent`, `intraSessionVariability`, `decisionChangesCount`, `averageResponseTimeAdjustedMs`, `dtScoreCalibrationAdjusted` — exposés dans `GameSessionResponse.decisionIndicators`.

**Couche PROVISOIRE (un seul fichier — `DecisionProvisionalRules`, chaque constante `// PROVISOIRE`)**
- **a — mapping option → score par QUALITÉ** (pas par scénario) : enum `OptionQuality` avec les libellés exacts de la fiche — `OPTIMAL→3` (optimal/cohérent) · `SATISFACTORY→2` (satisfaisant/suboptimal) · `PARTIAL→1` (partiel/incohérent) · `DEFICIENT→0` (déficitaire/non pertinent). Le catalogue étiquette **chaque option** d'une qualité, jamais d'un score brut.
- **b — poids SCW = 1.0** pour les dimensions actives (la fiche dit « pondéré » sans donner les poids) : `scw = (Σ dim×poids)/(18×Σ poids)×100`. Le helper garde le test mathématique de l’exemple historique à cinq dimensions ; le moteur actif exclut II et agrège seulement ER/DT/CS/RE. La version à quatre dimensions reste à valider par le psychologue.
- **c — bornes de niveau** (seul ≥ 75 vient de la fiche) : **Élevé ≥ 75** · Normal 60–74 · Borderline 45–59 · Fragile < 45.
- **d — règle CS** (paire liée) : la note dérive de la cohérence entre les deux réponses — cohérentes → OPTIMAL · partielles → SATISFACTORY · contradictoires → DEFICIENT (`coherenceQuality`).
- **e — multiplicateurs es/it/pt** (estimations sectorielles : 1.22 / 1.18 / 1.22) + **fallback `ar`** documenté (1.20, tracé) plutôt qu'un échec.
- Seuils « bas/élevé » par dimension (déclencheurs des interprétations) et seuils de qualité de session : provisoires, isolés ici.

**Catalogue — deux ports injectables** : `DecisionScenarioCatalog` (notation : dimension + format + `provisionalScoring` + `OptionQuality` par option) et `DecisionFormCatalog` (présentation : vignette résolue, consigne, énoncés d'options). Implémentation vivante `DatabaseDecisionScenarioCatalog` (V59, 120 items en base) ; `EmptyDecisionScenarioCatalog` reste le repli de test, `JsonDecisionScenarioCatalog` est `@Deprecated`. `MiniGame.DECISION_CORE.isPlayable()=true`.

**À demander au psychologue pour remplacer le provisoire** : (bloquant) **catalogue des 30 scénarios + étiquetage `OptionQuality` des options** ; poids SCW réels ; bornes de niveau hors ≥ 75 ; multiplicateurs es/it/pt/ar ; échelles post-test fatigue/motivation (et age/educationLevel).

**Détail du score** (`ScoreBreakdownService.decision`) : une ligne par dimension active `/18`, puis brut `/72`, puis `SCW /100`. **Parité mock** à répliquer dans `games_mock_repository.dart` (câblage UI → backend = lot séparé ; les écrans `je_decide_*.dart` ne sont pas modifiés).

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

### Schéma DB (`V9__games_schema.sql`, `V11__games_device_calibrations.sql`, `V12__games_memory_quest_minigame.sql`, `V24__games_decision_minigame.sql`, `V26__games_reflective_pause_minigame.sql`, `V61__games_continuous_attention.sql`, `V62__games_visuomotor_coordination.sql`, `V63__games_object_location_memory.sql`)

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
`/games/reflective-pause`, `/games/strategic-choices`, `/games/je-continue`,
`/games/je-coordonne`, `/games/je-place`).
`/games` ouvre le shell `MainNavigationScreen(initialTab: 2)` afin de conserver la bottom nav
sur l'onglet Careers/Progress ; les routes de jeu restent plein écran.

### Arborescence & rôle de chaque fichier

> **BART + IST (98)** — `domain/config/{bart,ist}_config.dart` + `*_provisional_rules.dart`,
> `domain/service/deterministic_random.dart` (FNV-1a + xorshift32 partagés, extraits de
> `object_location_config.dart`), `domain/entities/{bart,ist}_metrics.dart`,
> `data/decision_behavioral_scoring.dart` (miroir exact des services Java, parité figée par
> tests), `presentation/view/{bart,ist}_screen.dart`,
> `presentation/widgets/decision_behavioral_components.dart`, SVG `assets/games/bart_*.svg`
> et `ist_logo.svg`.

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
| | `domain/config/game_presentation_timing.dart` | Huit timers de présentation lus depuis le snapshot ; defaults/bornes miroirs du registre Spring, sans logique de score. |
| | `domain/entities/game_runtime_snapshot.dart` | Snapshot immuable ; lecture bool/int défensive et fallback des anciennes sessions. |
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
| | `domain/repositories/emotional_radar_v2_repository.dart` | Port dédié au flow adaptatif V2 : état pur, activation idempotente de la prochaine scène et réponse mesurée. |
| **data** | `data/decision_progress_store.dart` | Checkpoint local « Je Décide » : conserve uniquement le point de reprise ; les choix individuels ne sont pas persistés. |
| | `data/dtos/game_session_dto.dart` | Parse la réponse API → entité domaine. |
| | `data/games_repository_impl.dart` | Impl **Dio** → `/api/v1/games`, y compris les trois opérations Emotional Radar V2. Convertit erreurs en `ApiException`. |
| | `data/games_mock_repository.dart` | Impl **MOCK** en mémoire : reproduit le barème serveur et le flow adaptatif Radar V2 (horloge injectable, activation/réponse/report) → jouable **sans backend**. |
| | `data/demo_games_repository.dart` | Démo existante : banque Je Décide provisoire et trois vidéos Radar locales ; textes, identifiants et notation Radar hérités du mock. |
| | `data/continuous_attention_scoring.dart` | Miroir offline du validateur/scorer serveur : séquence, correction, indicateurs, audit-only et breakdown canonique. Le backend reste autoritatif en mode API. |
| | `data/coordination_tracking_scoring.dart` | Miroir offline de la reconstruction/notation serveur « Je coordonne » ; parité des précisions, distance, validité, score half-up et breakdown. Le backend reste autoritatif en mode API. |
| | `data/object_location_scoring.dart` | Miroir offline du rejeu, de la classification exclusive, de la progression/validité et du score provisoire. Le backend reste autoritatif en mode API. |
| **Emotional Radar** | `domain/entities/emotional_radar.dart` | Entités : `BasicEmotion`, `SceneMediaType`, `EmotionalNuance` (+ `NuanceSource`), `EmotionalRadarScene` (**sans** réponse attendue), `SceneSet`, `Feedback`, `Metrics`. |
| | `domain/config/emotional_radar_config.dart` | **Miroir Dart du barème** (3/4/2, dégradé, bonus off, libellés d'intensité, bandes). Parité backend. |
| | `domain/config/emotional_radar_provisional_rules.dart` | **Miroir de la taxonomie** — `FIGMA` vs `PROVISIONAL`. |
| | `presentation/view/emotional_radar_screen.dart` | Machine d'états `cover → tutorial → gameplay → feedback → transition → results` + pause / aide / plein écran / erreur. `EmotionalRadarResultsView` : trois barres de synthèse pour l’intensité sous-estimée/correcte/surestimée, selon les comptes du rapport. |
| | `presentation/widgets/emotional_radar_tutorial.dart` | Cinq cartes V2 : observation, émotion, intensité, temps, validation ; `GameTutorialDeck` réutilisé avant la partie et dans l’aide plein écran. Valeurs tirées de la configuration V2. |
| | `mobile/assets/games icons/Emotional Radar Tutorial {Observe,Choose,Intensity,Time,Validate}.png` | Cinq nouvelles illustrations pédagogiques RGBA transparentes, dossier déjà déclaré ; aucun stimulus ni clé de correction. |
| | `mobile/assets/emotional-radar-tutorial/{README.md,manifest.json}` | Prompts exacts, provenance, contrôle visuel et règles représentées. |
| | `test/features/games/presentation/emotional_radar_tutorial_test.dart` · `goldens/emotional-radar-tutorial-{1…5}.png` | Chargement/décodage des cinq assets, gestes, validation finale, petit écran à 200 % et cinq captures. |
| | `presentation/view/emotional_radar_gameplay.dart` | `SceneCard` (média + équivalent textuel voisin), `AnswerPanel` (révélation progressive), `FeedbackCard`. |
| | `presentation/widgets/emotional_radar_video.dart` | Lecteur asset/réseau : lecture explicite, pause/replay, plein écran, retry, pause sur overlay et arrière-plan. |
| **Démo / composants** | `presentation/widgets/game_system_components.dart` | `GameContentFrame` partagé pour limiter la largeur sur tablette ; `GameWelcomePage` réutilise les boutons/panneaux existants pour un accueil court (logo officiel, nom, mission, action), sans superposition ni pied masquant le contenu. Carte, court contexte et trois repères du parcours centrés ensemble ; écart final de 8/20 px selon la hauteur. Variantes optionnelles `contextText` et `journey`, logo officiel adapté à la hauteur. Texte agrandi : défilement de toute la page. |
| **Accueils adaptés au téléphone** | `test/features/games/presentation/game_entry_layout_test.dart` · `goldens/entry-{memory-digits,memory-images,je-decide,optimal-path,predictive-puzzle,emotional-radar,reflective-pause,strategic-choices}.png` | 32 tests : huit accueils à 360×800, 360×640, 320×568 et texte à 200 % ; titres complets, bouton accessible, zone système Android respectée, absence de navigation basse, passage direct aux cartes Strategic Choices. Proximité carte/action vérifiée ; huit captures actualisées et contrôlées. |
| | `presentation/widgets/game_results_template.dart` | `insightTitle` optionnel et jauge publique `GameResultInsightMeter` ; mode compact par défaut conservé, variante pleine largeur avec valeur en points, description sémantique et respect du mouvement réduit. |
| | `test/features/games/presentation/game_insights_visual_test.dart` · `goldens/{strategic-choice-icons,reflective-pause-insights,emotional-radar-intensity-insights}.png` | Huit tests : icônes et états, valeurs serveur/maxima, rapports absents/vides, défilement à 200 %, mouvement réduit et trois captures. |
| | `mobile/assets/games_demo/emotional_radar/` | Trois MP4 silencieux et `SOURCES.md` (provenance, licence et empreintes). |
| **Tests démo** | `test/features/games/data/demo_radar_media_test.dart` | Chargement MP4 et parité de notation avec le mock. |
| | `test/features/games/presentation/{emotional_radar_video,task_scheduling_screen}_test.dart` | Lecture, cycle de vie, retry ; petits écrans, texte 200 %, placements, règles et soumission brute. |
| | `presentation/widgets/emotional_radar_components.dart` | Boutons d'émotion, chips de nuance, sélecteur d'intensité, étapes verrouillées/validées, palette — cibles ≥ 48 px, jamais de sens porté par la couleur seule. |
| **Reflective Pause** | `presentation/view/reflective_pause_screen.dart` | Flow complet `cover → intro → tutorial → 10 moments → saved → results → insights`, timer 3 s, métriques brutes seulement. `ReflectivePauseInsightsView` : profil en jauges normalisées sur les maxima 3/4/3, points serveur et compte de choix impulsifs. |
| | `presentation/widgets/reflective_pause_tutorial.dart` | Cinq étapes pédagogiques avec `GameTutorialDeck`, avant démarrage et depuis l’aide ; valeurs de nombre issues des configurations existantes, aucune correction anticipée. |
| | `mobile/assets/games icons/Reflective Pause Tutorial {Discover,Wait,Choose,Validate,Review}.png` | Cinq nouvelles illustrations transparentes, dossier déjà déclaré ; aucun stimulus ou choix recommandé. |
| | `mobile/assets/reflective-pause-tutorial/{README.md,manifest.json}` | Prompts exacts, provenance, destination et vérification visuelle. |
| | `test/features/games/presentation/reflective_pause_tutorial_test.dart` · `goldens/reflective-pause-tutorial-{1…5}.png` | Chargement et décodage des assets, balayage/retour, validation finale, petit écran à 200 % et cinq captures. |
| | `presentation/emotional_regulation_session_provider.dart` | Réutilise la même session `EMOTIONAL_REGULATION` entre Radar et Reflective, sans permettre deux tentatives identiques. |
| | `presentation/widgets/emotional_game_pause_dialog.dart` | Menu pause commun Radar/Reflective : reprise, règles/aide, sortie, mode d'entrée et audio. |
| **Strategic Choices** | `domain/config/strategic_choices_content.dart` | Réglages de présentation et catalogue stable des 8 stratégies ; aucune cotation envoyée dans le payload. |
| | `domain/entities/strategic_choices_bank.dart` · `domain/entities/strategic_choices_metrics.dart` | Parse la banque de 80 situations, impose un message non vide pour `WRITTEN`, et sérialise uniquement situation, stratégie, temps et support. |
| | `data/strategic_choices_bank_loader.dart` · `domain/service/strategic_choices_scoring.dart` | Charge l'asset en cache ; miroir offline du barème serveur pour le repository mock, avec correction du hasard et profil de coping. |
| | `assets/games/strategic_choices_bank.json` | Banque mobile de 80 situations : 60 fiches client + 20 propositions ; 6 messages écrits littéraux et 74 scènes vidéo. |
| | `presentation/view/strategic_choices_screen.dart` | Flow `cover → tutorial → 10 × (lecture → réflexion 3 s → choix → saved) → résultats → insights`, soumission des métriques brutes et score serveur ; bulle dédiée aux écrits, placeholder uniquement pour les vidéos. `StrategicChoiceCard` : huit icônes adaptées, visibles même sous verrouillage/sélection, badge d’état séparé. |
| | `backend/.../StrategicChoices{Config,ScoringService,Metrics,Report}` · `backend/.../JsonStrategicChoicesCatalog` | Validation des 10 réponses distinctes, catalogue autoritatif, somme /30, indice corrigé du hasard, profil de coping et breakdown provisoire. |
| | `backend/src/main/resources/games/strategic_choices_bank.json` | Copie serveur de la banque, identique à l'asset mobile pour assurer la parité mock ⇄ backend. |
| | `tooling/games/banks/{choix_strategiques_proposition.py,generer_pdf.py,fusionner.py}` | Source reproductible des 20 propositions, export JSON/PDF avec support et message, fusion idempotente qui conserve le champ `message`. |
| | `presentation/widgets/strategic_choices_tutorial.dart` | Cinq cartes pédagogiques via `GameTutorialDeck`, utilisées avant la partie et dans l’aide ; choix autorisé pendant la réflexion, validation après celle-ci. |
| | `mobile/assets/games icons/Strategic Choices Tutorial {Read,Reflect,Choose,Validate,Review}.png` | Cinq illustrations transparentes, dossier déjà déclaré ; aucune clé de correction ni stratégie recommandée. |
| | `mobile/assets/strategic-choices-tutorial/{README.md,manifest.json}` | Prompts exacts, provenance, destinations et vérification des illustrations. |
| | `test/features/games/presentation/strategic_choices_tutorial_test.dart` · `goldens/strategic-choices-tutorial-{1…5}.png` | Chargement/décodage des assets, gestes et retour, démarrage final, petit écran à 200 % et cinq captures. |
| | `assets/games icons/Strategic Choices.png` · `Strategic Choices Purple.png` | Deux PNG RGBA 512×512 : emblème transparent pour hub/picker et variante violette dans le jeu. Le dossier `assets/games icons/` était déjà déclaré ; aucun changement de `pubspec.yaml`. |
| | `test/features/games/{data/strategic_choices_bank_test.dart,presentation/strategic_choices_screen_test.dart}` | Invariants des 80 fiches et des 6 messages littéraux ; flow complet, score serveur, bulle écrite sans placeholder vidéo, pause et accessibilité. |
| **Je continue** | `presentation/view/continuous_attention_screen.dart` | Parcours complet `cover → règles → tutoriels X/AX → pratiques → 20 blocs X → repos 2 min → 20 blocs AX → envoi → résultats/insights`. Tempo absolu 690/230 ms, clavier/espace + tactile, aucune correction pendant les tests. |
| | `presentation/widgets/continuous_attention_pause_dialog.dart` | Pause/règles/sortie ; une interruption pendant une phase test impose le redémarrage de cette phase afin de ne pas fausser la vigilance mesurée. |
| | `test/features/games/presentation/continuous_attention_screen_test.dart` | Parcours 44 blocs/1 364 essais, pause/règles/restart, retour système, audit invalide puis retry sur le même `sessionId`, résultats et accessibilité 390×844 jusqu'à 200 %. |
| **Je coordonne** | `presentation/view/coordination_tracking_screen.dart` | Parcours complet `cover → onboarding 3 pages → pratique lente/rapide → ready → 12 segments test → sauvegarde → résultat/retry`. Ticker absolu, plateau custom, pointeur souris/touch/stylus, aucun score live ; réutilise le menu de pause mesurée et son dialogue de règles dédié. |
| | `test/features/games/domain/coordination_tracking_config_test.dart` | Vecteurs de trajectoire/timeline Dart et constantes de parité `FIXED_SQUARE_CW_V1`. |
| | `test/features/games/data/coordination_tracking_scoring_test.dart` | Score half-up, précisions/distance, validité et parité du mock avec le backend. |
| | `test/features/games/presentation/coordination_tracking_screen_test.dart` | Flow cover→résultat, activation, pratique/test, pause/règles/restart, payload 14 segments et copie non diagnostique. |
| **Je place** | `presentation/view/je_place_screen.dart` | Parcours complet `cover → onboarding ×3 → pratique → ready → 3–8 objets → résultat`, timers monotones à échéances absolues, plateau 4×4 mauve responsive, tap/drag, aucun feedback mesuré ni score client. |
| | `presentation/widgets/je_place_pause_dialog.dart` | Pratique gelable/reprenable ; une pause mesurée persiste d'abord l'audit technique puis permet le redémarrage du run, avec règles et sortie. |
| | `assets/games icons/Je Place.png` · `Je Place Object 01.png`…`20.png` | Logo et catalogue PNG 512×512 RGBA transparent, style Zennyt flat 2.5D, contrôlés à 48 px. |
| **Memory Quest Image — concepts visuels** | `assets/games icons/Memory Quest Image Concept v2.png` · `Memory Quest Image Concept v3 Minimal.png` · `Memory Quest Image Concept v4 Objects.png` · `Memory Quest Image Concept v5 Modern Recall.png` · `Memory Quest Image Concept v6 Modern Tech.png` · `Memory Quest Image Concept v7 Quiz Shapes.png` | Six propositions originales 1254×1254. La piste v7 associe directement les formes du quiz — cercle, triangle, carré arrondi, étoile et hexagone — aux objets modernes à mémoriser : smartphone, caméra hybride et casque sans fil. Elle adopte un emblème géométrique sur fond bleu, sans reprendre la double flèche circulaire précédente. Concepts livrés pour validation, non branchés au hub et créés sans utiliser les logos Memory Quest Image/Digits existants comme références. |
| **Memory Quest — tutoriels Digits/Image** | `presentation/widgets/memory_quest_tutorial.dart` | Six cartes par mode via `GameTutorialDeck`, dix pour le parcours historique combiné ; réutilisées avant démarrage et depuis l’aide. Aucun objet ni asset de partie dans les illustrations. |
| **Assets tutoriels mémoire** | `assets/games icons/Memory Quest {Digits,Image} Tutorial … .png` · `assets/memory-quest-tutorial/` | Douze PNG transparents dédiés, manifest des prompts/originaux, README et audit logique préalable. Production dans le dossier déjà déclaré. |
| **Tests tutoriels mémoire** | `test/features/games/presentation/memory_quest_tutorial_test.dart` · `goldens/memory-quest-{digits,images}-tutorial-{1…6}.png` | Neuf tests : chargement/décodage, navigation, action finale, 200 %, captures et mode combiné ; quatre tests de parcours/aide ajoutés dans `investigate_screen_test.dart`, navigation des captures existantes adaptée. |
| | `test/features/games/domain/object_location_config_test.dart` | Constantes, zones de réserve et vecteur golden déterministe partagé avec Java. |
| | `test/features/games/data/object_location_scoring_test.dart` | Rejeu, classification exclusive, score/validité, progression et rejets identiques au backend. |
| | `test/features/games/presentation/je_place_screen_test.dart` | Flow, payload brut, pause/audit/retry, accessibilité et non-débordement 390×844 / texte 200 %. |
| **Assets Day Stack** | `assets/Day Stack/emotes-v1/` | 82 emotes PNG transparentes par univers/tâche, manifeste/prompt exact, validation technique, huit planches de relecture, README et galerie locale. Seuls les sept dossiers d’univers sont déclarés dans `pubspec.yaml` et embarqués. |
| **Consigne partagée** | `presentation/widgets/memory_prompt.dart` | `MemoryPrompt` : vert Memory Quest `#4ADE80`, clignotement unique 460 ms, reduced-motion sans effacement ; réutilisé par Memory Quest et Day Stack avec style/alignement optionnels. Réexport conservé depuis `investigate_screen.dart`. |
| **presentation** | `presentation/games_providers.dart` | Bascule mock/backend via `--dart-define=GAMES_MOCK` (défaut `true`). |
| | `presentation/games_controller.dart` | `AsyncNotifier<GameSession?>` : `start()` / `submit()` ; conservation optionnelle de la session pour réessayer un envoi Je Décide échoué, comportement des autres jeux inchangé. |
| | `presentation/view/games_hub_screen.dart` | Hub jeux style maquette Progress : header « Play & discover your talent », 5 cartes de domaines cognitifs, illustration de catégorie + logos PNG officiels des jeux (`assets/games icons/`) ; le picker multi-jeux réutilise les mêmes images. `Cognitive Flexibility` propose Move Fast + Je continue + Je coordonne ; `Working Memory` propose Memory Quest + Je place ; `Emotional Regulation` propose Radar + Reflective Pause + la preview Strategic Choices, sans renommer les catégories. |
| | `presentation/view/je_decide_screen.dart` | **« Je Décide »** : accueil avec logo → trois cartes pédagogiques → un exemple → 24 items actifs servis par `GET /decision/items` → soumission → profil réel. Personnalisation retirée ; en-tête persistant et transition douce vers les cartes. Ouvre la session après l’exemple ; tutoriel sans démarrage de session. Envoi final verrouillé, réponses conservées pour réessayer, aucun profil de remplacement à zéro. |
| | `presentation/widgets/je_decide_tutorial.dart` | Trois cartes illustrées via `GameTutorialDeck`, avant l’exemple et depuis l’aide : lire/choisir, scénarios liés et chrono. But et bilan annoncés une seule fois à l’accueil ; en-tête de la pile masqué uniquement lorsque l’écran fournit déjà la navigation. |
| **Assets Je Décide** | `assets/games icons/Je Decide Tutorial {Read,Choose,Linked,Time,Practice,Profile}.png` · `assets/je-decide-tutorial/` | Trois PNG utilisés (`Choose`, `Linked`, `Time`) ; les six sources générées, prompts et provenance restent conservés. Logo `Je Decide transparent.png` repris du hub. Aucun changement de pubspec. |
| | `test/features/games/presentation/je_decide_tutorial_test.dart` · `goldens/je-decide-tutorial-{1…3}.png` · `goldens/je-decide-welcome.png` · `goldens/je-decide-tutorial-entry.png` | Chargement/décodage des assets, balayage/retour, action finale, accueil/règles à 200 % et cinq captures. Cadre stable pendant entrée/retour, accueil sortant inactif et mouvement réduit vérifiés. Tests de parcours et d’aide adaptés ; choix et chrono conservés. |
| | `presentation/view/je_decide_gameplay.dart` | Gameplay piloté par les **24 items actifs servis** : chrono DT sur le temps imparti renvoyé par le serveur, paires CS enchaînées, écrans de transition aux seules frontières de dimension, pause/règles, checkpoint. Questions II retirées, situation et réponses ensemble sur une seule page ; aucun bouton Voir les réponses/Relire. Mesure `responseTimeMs` (à la validation, via `package:clock`) et `decisionChangesCount`. XP visuel uniquement ; aucun score calculé. SFX badge à chaque frontière de catégorie, une seule fois par entrée. |
| | `test/features/games/presentation/je_decide_no_scroll_test.dart` · `goldens/je-decide-active-question.png` | Deux banques actives, 24 questions sans II sur sept tailles d’écran ; situation et réponses sur une seule page, accès à la dernière réponse sans recouvrement du pied, texte à 200 %. Aucun défilement sur les téléphones de référence ; petits écrans et longs contextes DT peuvent défiler sur la même page. Captures provisoires du découpage retirées. |
| **Contrat de soumission Je Décide** | `domain/entities/decision_metrics.dart` · `test/features/games/data/decision_submission_contract_test.dart` | POST sérialise `decisionItems`, GET formulaire garde `items` ; test du repository Dio avec rejet HTTP 400 de la mauvaise clé et projection du score serveur. |
| | `presentation/view/je_decide_results.dart` | Résultats : fin de parcours, préparation, radar accessible, modèle de score partagé avec compteur animé, détail par dimension, export. SFX badge sur la dernière catégorie et la révélation du profil ; son de comptage conservé. `DecisionProfile.fromSession` projette la **réponse serveur** (SCW /100, niveau, /18 par dimension, marqueur de notation provisoire) — rien n'est calculé côté client. |
| | `presentation/view/planifik_screen.dart` | Flow complet **Optimal Path** (intro Path Mind, deux cartes de règles (`OptimalPathTutorial`), gameplay **multi-niveaux**, score, comparaison) + HUD stations, **menu pause** (`_PauseDialog`), légende, contrôles + bouton « Continue to scheduling » (→ Planifik #2). Voir [Flow Optimal Path](#-flow-optimal-path-mobile). |
| | `test/features/games/presentation/optimal_path_tutorial_test.dart` · `goldens/optimal-path-tutorial-{1,2}.png` | Quatre tests : navigation, texte à 200 %, captures natives et démarrage réel après la dernière carte. `planifik_attempts_test.dart` suit les nouveaux libellés sans modifier ses assertions métier. |
| | `presentation/view/task_scheduling_screen.dart` | **Day Stack** : calendrier mauve défilant, mission verte contextualisée et validation séparée. Appui maintenu sur la carte seule, grille conservée pendant le drag, auto-scroll aux bords ; mesures figées à « Valider », soumission au dernier niveau, débrief puis score serveur/mock. |
| | `presentation/widgets/day_stack_calendar.dart` | Agenda Day Stack : heures fixes pendant le glissement, carte seule soulevée, source atténuée, dépôt par position des cartes et défilement automatique aux bords. Transmet univers + tâche au badge de chaque carte. |
| | `presentation/widgets/day_stack_badges.dart` | `DayStackTaskBadge` : emote de la tâche si `universeId`/`taskId` sont fournis, sinon carré coloré + icône Material historique (également repli d’erreur). Couleurs de catégories et table Tabler → Material. |
| | `presentation/widgets/day_stack_emotes.dart` | Chemin d’emote par couple univers/tâche, tailles 32/38 px et largeur de décodage `cacheWidth`. |
| | `presentation/widgets/game_tutorial_deck.dart` | Pile de cartes illustrées commune : balayage horizontal, précédent/suivant, progression, validation finale, descriptions sémantiques, reduced-motion et défilement interne sans masquer les contrôles. Variante `showHeader: false` pour un en-tête fourni par le jeu, affichage existant conservé par défaut. |
| | `presentation/widgets/day_stack_tutorial.dart` | Six étapes visuelles Day Stack avec emotes du restaurant et schémas des contraintes ; utilisé avant la partie et depuis l’aide, sans démarrer ni modifier une session. |
| | `test/features/games/presentation/game_tutorial_deck_test.dart` · `goldens/day-stack-tutorial-{1…6}.png` | Navigation par gestes/boutons, validation finale, petits écrans portrait/paysage à 200 %, sémantique et six captures avec assets réellement décodés. |
| | `test/features/games/presentation/day_stack_{badges,emotes}_test.dart` | Couverture icônes/couleurs, repli sans identité ou PNG introuvable, décodage à la taille affichée, clé composite, 82 PNG chargés depuis le bundle. |
| | `presentation/view/move_fast_screen.dart` | Écran complet « Je bouge » (intro, tutoriels, gameplay **niveau unique à règle aléatoire**, résultats). Voir [Niveau Move Fast](#-niveau-move-fast-mobile). |
| | `presentation/view/predictive_puzzle_screen.dart` | Écran complet **Predictive Puzzle** : intro, deux cartes de règles nettes (`PredictivePuzzleTutorial` + `GameTutorialDeck`), planification Tower of Hanoi, exécution auto, résultats, comparaison. Voir [Flow Predictive Puzzle](#-flow-predictive-puzzle-mobile). |
| | `test/features/games/presentation/predictive_puzzle_tutorial_test.dart` · `goldens/predictive-puzzle-tutorial-{1,2}.png` | Quatre tests : navigation des deux cartes, petit écran à 200 %, captures des schémas natifs et parcours réel jusqu’au premier coup planifié. |
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
  trois pour Planifik, Radar + Reflective Pause + Strategic Choices pour Emotional Regulation), durée du domaine,
  `N° aptitudes`, illustration PNG. Les anciennes swatches décoratives ont été supprimées.
- Le bottom sheet d'une catégorie multi-jeux reprend le **même fichier image** pour chaque entrée
  afin de conserver l'identité visuelle entre le hub et le sélecteur. Les logos historiques
  proviennent des couvertures officielles fournies :
  `Move Fast.png`, `Je Place.png`, `Strategic Choices.png`. `Je Continue.png` est une illustration nette à
  fond transparent fondée sur le concept A→X/focus ; `Je Coordonne.png` reprend le concept original
  **Sync Square** (rails carrés, cible, réticule et sens horaire), net et sans carré violet.
- Assets déclarés dans `mobile/pubspec.yaml` :
  `assets/04 Optimal Path/` (`image 120.png`, `image 120-1.png`, `image 121.png`,
  `image 121-1.png`, `image 121-2.png`) **et** `assets/04 Predictive Puzzle/`
  (`discs.png` = source historique de la carte intro, `golden_rule.png` = source Figma historique conservée ; le tutoriel utilise désormais les widgets de disques et tours),
  ainsi que les sous-dossiers utilisés de `assets/04 Je Décide/`.
- Routes actives : Cognitive Flexibility → sélecteur Move Fast (`/games/move-fast`),
  Je continue (`/games/je-continue`) ou Je coordonne (`/games/je-coordonne`), Working Memory →
  sélecteur Memory Quest (`/games/investigate`) ou Je place (`/games/je-place`), Decision-Making → `/games/je-decide`, Executive Planning →
  menu de sélection des 3 mini-jeux Planifik, Emotional Regulation → sélecteur
  Radar/Reflective/Strategic Choices.

Navigation : `ProgressScreen` héberge `GamesHubScreen`. La route `/games` rend
`MainNavigationScreen(initialTab: 2)`, et `AppBottomNav` accepte un `selectedTab` local afin
d'afficher l'onglet Careers/Progress sans modifier `navTabProvider` pendant `initState`.
Depuis le 2026-09-18, les routes de jeux, y compris leurs accueils et tutoriels,
n’affichent plus `AppBottomNav`. Le menu du hub reste présent ; les retours et
menus de pause existants permettent de sortir. La barre système Android est
respectée par `SafeArea`, sans modification du module Navigation ni de core.

Les huit accueils demandés utilisent `GameWelcomePage` : nom, logo officiel,
mission courte, contexte propre au jeu et trois repères numérotés du parcours.
Les règles détaillées restent dans les cartes. Le titre **Optimal Path** remplace
« Path Mind » à l’accueil. Titres et logos occupent des lignes séparées.
Carte, contexte, parcours et action forment un groupe centré : le bouton reste
près des repères, sans grand vide entre les éléments. Sur petite hauteur, logo,
espacements et titres s’adaptent ; aucun texte tronqué. Aucun défilement nécessaire
au texte normal sur les tailles testées ; texte agrandi et écran plus petit peuvent
faire défiler le groupe. Le retour reste en haut. Paramètres de contexte/parcours
optionnels pour préserver les usages qui n’en ont pas besoin.
Day Stack reste inchangé et sert de référence. Strategic Choices ne présente
plus sa seconde introduction : son action d’accueil ouvre les cartes directement.

### 🧭 Flow « Strategic Choices » (mobile + score serveur provisoire)

`strategic_choices_screen.dart` reprend la structure des jeux Emotional Regulation et la palette
violette du handoff. La banque contient **80 situations** : 60 fiches client et 20 propositions.
Chaque partie en tire 10 sans répétition :

`cover → tutorial → 10 × (read → reflect 3 s → choose 1/8 → answer saved) → results → insights`

- tutoriel et aide en cinq cartes illustrées centrées sur le fond blanc habituel,
  avec balayage, précédent/suivant et bouton final ; le nombre de stratégies provient
  du catalogue et celui de situations de la constante du parcours ;
- les textes distinguent lancement manuel, choix possible pendant le compte à rebours
  et validation après sa fin ; aucune durée fixe ni cotation ajoutée ;
- aucune correction right/wrong pendant le parcours ; la transition reste neutre ;
- le timer de réflexion est gelé pendant la pause ; le menu partagé propose seulement reprise,
  règles/aide et sortie, jamais un redémarrage silencieux ;
- les 6 situations `CS-102`, `CS-104`, `CS-108`, `CS-112`, `CS-115` et `CS-116` affichent le
  message reçu littéral dans une bulle, sans emplacement vidéo ;
- les 74 autres situations gardent un placeholder « Vidéo à venir » et leur scène textuelle,
  afin de rester lisibles en attendant les médias ;
- le client transmet seulement `situationId`, `selectedStrategy`, `responseTimeMs` et `medium` ;
  le serveur applique la clé 0–3, renvoie le score brut **/30**, l'indice corrigé du hasard et le
  profil descriptif de coping ;
- le barème, son interprétation et la normalisation émotionnelle restent explicitement
  **PROVISOIRES** et doivent être validés par le psychologue ;
- la variante violette du logo est utilisée dans le jeu et la variante transparente dans le hub ;
- les 74 vidéos, leurs sous-titres/transcriptions et la normalisation du profil émotionnel restent
  bloqués jusqu'à livraison/validation.

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
| **How To Play** | Deux cartes centrées sur fond blanc (`GameTutorialDeck`) : « Relie LAB à MTG », avec le schéma de stations rondes `_StationsArt` et un chemin magenta orthogonal ; « Choisis un trajet efficace », avec les quatre critères du barème existant. Textes courts, swipe, précédent/suivant et démarrage à la dernière carte. Couleurs issues de `BoardPalette`, aucun bitmap ajouté. |
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
| **How To Play** | Deux cartes centrées sur fond blanc (`GameTutorialDeck`) : « Petit sur grand, toujours » compare les empilements autorisé/interdit ; « Prépare tout, puis lance » sépare la préparation du plan et `Run Plan`. Disques/tours natifs réutilisés, texte court, balayage et boutons précédent/suivant. Le PNG de 297 × 135 pixels n’est plus agrandi. |
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

### 🧠 Tutoriels Memory Quest Digits et Image — 2026-09-17

Les routes séparées utilisent toujours `InvestigateScreen`, avec les modes
`digits` et `images`. Le tutoriel passe par `MemoryQuestTutorial` avant
`_startMission` : parcourir les cartes ne démarre pas de session ni de chrono.
Fond habituel blanc, cartes centrées, balayage et précédent/suivant ; l’action
« Je suis prêt » apparaît seulement à la fin. L’aide affiche les mêmes cartes
dans un dialogue plein écran et retourne au cycle de pause existant.

- **Digits, six cartes** : révélation un par un, rappel direct, rappel inverse,
  question d’interférence dès le niveau 3, saisie complète/effacement/validation,
  progression. Exemple illustré 3–7–2 → 2–7–3 pour l’inversion.
- **Image, six cartes** : ordre initial, échanges automatiques, casse-tête visuel
  dès le niveau 2, classement par appuis et annulation d’un rang, validation et
  expiration du chrono, progression. Nouveaux symboles pédagogiques coquillage,
  lune et plume ; aucun objet du catalogue réel ni SVG de distracteur réutilisé.
- **Mode historique, dix cartes** : les deux missions, avec seulement la question
  d’interférence des chiffres. Le tutoriel n’annonce pas un casse-tête visuel
  supplémentaire que ce mode ne joue pas.

Le départ à trois éléments, l’ajout d’un après un tour réussi et l’arrêt après
deux tours ratés au même niveau viennent des configurations/parcours existants.
Sept niveaux joués : trois à neuf éléments. Aucun délai réel, stimulus ou score
modifié. **Audit préalable** : le moteur pur `MemoryImagesGame` n’est pas câblé
aux routes. Mode `FULL` envoyé par Image et chrono de restitution sous pause
reproduits ; autres écarts de timing/métriques relevés par lecture. Corrections
ouvertes dans `mobile/assets/memory-quest-tutorial/AUDIT_LOGIQUE.md` ; elles ne
sont pas masquées par les tests verts du tutoriel.

### 🧭 Flow « Je Décide » — Phases 1–4 (mobile)

`je_decide_screen.dart` orchestre les écrans fournis dans les trois dossiers de handoff, dans une
machine d'états locale :

`welcome → practiceIntro (3 cartes) → practiceScenario (1 exemple)`

`→ analytical → riskBalance → quickChoice → xpFeedback → checkpoint → encouragement`

`→ badge → dimensionComplete → stabilityFirst → stabilitySecond → selfControl`

`→ journeyComplete → preparing → profile → strengths → details → export → hub`.

- **Welcome** : fond blanc, hero violet et logo officiel repris du hub ; un objectif court,
  durée maximale dérivée de `DecisionConfig`, 24 questions, confidentialité et bilan en
  quatre dimensions avec cotations provisoires signalées. « Commencer » ouvre les règles.
  Les trois pages d’onboarding et le panneau répétitif « How it works » sont retirés.
- **Continuité accueil/règles** : navigation supérieure, retour, menu et barre basse
  conservent leur place. « Comment jouer » apparaît dans l’en-tête du jeu ; celui de
  la pile est masqué par une option, sans doublon. Fond blanc conservé, contenu des
  cartes introduit par fondu et glissement horizontal léger de 320 ms (6 % de la largeur),
  retour vers l’accueil dans l’autre sens. Les anciens contenus ne répondent plus
  aux gestes et ne sont plus annoncés pendant leur disparition. Avec mouvement réduit,
  le changement d’étape est immédiat. Aucun nouvel écran ni illustration.
- **Personnalisation retirée (2026-09-17)** : bouton « Personnaliser (facultatif) »,
  écrans pseudo/thème/avatar, états, contrôleur et navigation associés supprimés à la
  demande de l’utilisateur. L’accueil n’a plus qu’une action de lancement : « Commencer ».
  Les fichiers graphiques d’avatars des maquettes sont conservés comme sources historiques,
  sans utilisation dans le parcours ; aucune déclaration d’asset modifiée.
- **Practice** : tutoriel puis seul scénario fourni, « Exemple d’entraînement — Choosing a route ».
  Le compteur trompeur `Practice 1/2` est retiré. Le choix reste neutre : aucun état « correct/incorrect ».
  **Tutoriel simplifié (2026-09-17)** : trois cartes centrées sur fond blanc, illustrations
  `Choose`, `Linked`, `Time` et textes français courts. La première réunit lecture,
  sélection et bouton « Continue » ; la deuxième explique les scénarios liés ; la
  troisième présente le chrono. Balayage horizontal et précédent/suivant conservés ;
  « Essayer l’exemple » apparaît à la dernière carte. Retour à l’accueil depuis les règles.
  Un seul exemple précède l’ouverture de session et les 24 questions actives.
  L’aide réutilise ces cartes en plein écran, revient au menu pause existant, conserve
  le choix et laisse le chrono suspendu jusqu’à la reprise. Les délais réels restent
  ceux du gameplay : minute ordinaire et budget serveur pour les choix rapides.
- **Questions II retirées (2026-09-17, confirmation utilisateur)** : les six questions
  d’analyse des contraintes disparaissent du parcours et du bilan. `activeBank` du port
  `DecisionFormCatalog` filtre côté serveur, tant pour la lecture que pour le contrôle
  des items soumis ; un item II soumis est désormais hors de la sélection autorisée.
  Le moteur et son miroir Dart agrègent quatre dimensions sur /72, puis SCW /100 ;
  ni axe II, ni points II, ni interprétation de difficulté d’analyse. Codes et textes II
  restent archivés, sans suppression en base, car les choix DT réutilisent leurs contextes.
  La démo sert également 24 questions ; parsing mobile défensif contre une ancienne
  réponse API contenant II. Situation et réponses ensemble sur une page ; étapes
  Situation/Réponse, écran de lecture et actions Voir les réponses/Relire retirés.
  Densité gelée sur le formulaire actif ; sur petit écran ou à 200 %, les contenus
  dépassant la hauteur restent accessibles en défilant sur cette même page, sans
  recouvrement par Continue. Paires CS conservées, choix et cotation DT inchangés.
  Aucun nouveau contenu, remplacement de question, dépendance ou migration.
- **Gameplay Phase 2** : les cinq formats livrés sont représentés sans afficher leurs codes
  internes : choix à 3 cartes, risque à 2 options, choix rapide, scénario lié en deux parties
  consécutives et préférence immédiate/différée.
- **Choix rapide** : timer visuel + numérique de 7 s, état critique orange à 2 s, timeout calme
  puis passage automatique au scénario suivant. Aucune notion de réussite/échec.
- **Feedback** : écran `+12 XP` et badge `Steady Explorer`. Ces valeurs reproduisent seulement les
  états visuels des maquettes ; elles ne constituent pas un barème.
- **Checkpoint/reprise** : pause optionnelle et restauration automatique. `DecisionProgressStore`
  conserve uniquement l'**index de l'item** de reprise dans `SharedPreferences`, jamais les réponses.
  ⚠️ Les réponses déjà données sont perdues si la session est interrompue : la soumission est unique
  et finale (contrairement à Emotional Radar, qui persiste chaque scène côté serveur).
- **Menu pause** : la croix gameplay ouvre un dialogue avec reprise, son/musique, règles et
  sauvegarde/sortie. Le timer DT est réellement suspendu puis reprend au même nombre de secondes.
- **Résultats** : nombre réel de réponses /24, préparation, radar avec équivalent textuel accessible, profil, quatre
  dimensions détaillées et écran export/partage. Le score, le niveau et le détail /18 viennent tous
  de la réponse de soumission. Une dimension en notation provisoire est **signalée comme telle** :
  un 12/18 forfaitaire ne doit pas se lire comme une performance.
- **Soumission HTTP corrigée (2026-09-17)** : l'erreur 400 relevée dans le
  simulateur était `Unrecognized field "items"` sur `SubmitResultRequest.Metrics`.
  Le formulaire GET garde `items`, mais les réponses POST doivent utiliser
  `decisionItems`, clé déjà attendue par le backend. Contrat OpenAPI corrigé
  avant la sérialisation mobile ; liste Dart `DecisionMetrics.items` et domaine
  Java inchangés. Test Dio strict du vrai repository et test Jackson du DTO
  serveur ajoutés ; tests avec repository simulé seuls ne détectaient pas ce défaut.
- **Sons des catégories et score final (2026-09-17)** : `badgeUnlocked` joue une
  fois à l'entrée de chaque transition après les questions 6, 12 et 18, puis à
  `journeyComplete` après la dernière catégorie. Même son existant que les badges,
  actuellement alias de `congrats-sfx.mp3`, sans nouvel asset ni indication de bonne/mauvaise
  réponse. Le profil garde son SFX badge et son son de comptage. La soumission doit
  contenir un résultat `DECISION_CORE` avant d'ouvrir le bilan : aucun échec réseau
  ou résultat absent ne devient un profil artificiel à 0. Le loader et le panneau
  d'erreur existants sont réutilisés, avec nouvelle tentative sur la même session
  et les mêmes réponses ; zéro réellement noté par le serveur reste valide.
  Compteur commun vérifié à une valeur intermédiaire puis au score final, son
  coupé respecté et aucun SFX répété par un simple rebuild.
- La bottom nav partagée reste visible pendant l'introduction et disparaît pendant la pratique et
  tout le gameplay/résultat.
- **Hors ligne** : « Je Décide » est le seul jeu du module qui exige le backend. Le mock lève une
  erreur explicite plutôt que d'embarquer la banque et sa clé de correction — voir l'exception de
  parité en tête de `games_mock_repository.dart`.
- Restent à fournir : les modèles d'aversion λ (ER), d'actualisation hyperbolique k (RE) et de
  cohérence de paire (CS). 66 des 120 items restent en notation neutre en attendant.

La carte `Decision-Making` du hub pointe exclusivement vers `/games/je-decide`. Predictive Puzzle
reste dans `Executive Planning`.

#### Investigation du retour arrière — 2026-09-16

Deux défauts techniques sont reproduits par des tests widget de diagnostic temporaires :

- **Carte joueur → onboarding** : après les trois pages, le bouton Retour remonte bien à
  l'onboarding, mais le nouveau `PageView` repart à l'index **0** alors que `_onboardingPage`
  reste à **2**. Le contenu de la première page est donc accompagné du bouton
  « Create my player card » et de l'indicateur de la dernière page. Le `PageController`
  est conservé, mais la position du `PageView` démonté n'est pas restaurée dans ce parcours.
- **Retour système pendant le gameplay** : `JeDecideScreen.build` retourne le Scaffold de
  gameplay avant le `PopScope` de l'introduction ; `DecisionGameplayView` n'en ajoute pas.
  La route n'intercepte donc plus le retour système pendant la passation. Le test monté
  en route racine observe `RoutePopDisposition.bubble` au lieu de `doNotPop` ; la destination
  réelle dépend de la pile de navigation. À titre de comparaison, `InvestigateScreen`
  conserve son `PopScope` autour de tous ses états.

**Statut** : diagnostic confirmé, aucun correctif de navigation appliqué. La capture transmise
est absente du chemin temporaire indiqué : l'écran exact et le type de retour du signalement
restent à identifier. Le retour tactile « Back to the situation » du gameplay appelle une
autre action (`_backToSituation`) et n'est pas identifié comme défaillant par cet audit.
Avant une correction du retour système, préciser le comportement attendu pendant un item
chronométré, pour préserver l'interdiction de pause existante.

**Validation** : les deux assertions de diagnostic exposent les défauts ; leur fichier temporaire
est retiré après exécution. Les suites existantes `je_decide_screen_test.dart` et
`je_decide_gameplay_test.dart` restent vertes : **25 tests Flutter**, sans modification de code.
Backend/ArchUnit et analyse globale non exécutés pour cette investigation de navigation.
Arborescence, barèmes, API, parité mock/backend et roadmap d'implémentation inchangés.

### 🃏 Tutoriel visuel Day Stack — 2026-09-17

Les quatre blocs de paragraphes sont remplacés par **six cartes successives** :
maintenir/déplacer, dépendances, fenêtre horaire, échéance, début « pile » et temps mort,
puis validation. Chaque carte présente un schéma et une explication courte ; les exemples
reprennent livraison, inventaire, cuisson et service du restaurant. Les emotes déjà
embarquées sont agrandies à 80–132 px dans les exemples, sans modifier leur taille dans
le calendrier. `DayStackTaskBadge.emoteSize` est une option de présentation ; ses valeurs
par défaut et son repli restent inchangés.

`GameTutorialDeck` réutilise `GamePanel` et `GamePrimaryButton` et représente la pile
avec deux cartes arrière décoratives. Les cartes claires sont centrées, limitées à
540 px de hauteur ; la scène illustrée est séparée du texte centré. Sur demande de
l’utilisateur, le fond habituel blanc des tutoriels Planifik est rétabli, y compris
les marges système et les côtés sur tablette. Titres et navigation bleu marine,
repère de progression magenta ; aucun dégradé mauve à l’extérieur des cartes. Balayage horizontal ou « Suivant », retour à la
carte précédente, repère d’étape et bouton final « Je suis prêt » / « Reprendre la partie ».
Le bouton de retour existant conserve sa destination. Le contenu peut défiler verticalement
**dans la carte** sur petit écran ou avec un texte agrandi ; aucun rétrécissement du texte
explicatif, commandes toujours en dehors de cette zone. Les repères graphiques restent
compacts et disposent d’une description sémantique équivalente. Les animations désactivées
permettent une navigation immédiate.

La première carte propose une **mini-démonstration manipulable** : appui maintenu sur la
livraison, glissement dans la place libre, puis « Bien joué ! ». Un toucher simple ou
l’action sémantique permet également d’essayer. Cette interaction locale ne modifie
ni la banque, ni les placements de la partie, ni aucune métrique. Les autres scènes
montrent de grandes emotes et des repères horaires simples. Les schémas seuls peuvent
être ajustés à leur espace disponible ; le texte explicatif n’est jamais réduit.

Parcourir le tutoriel initial n’ouvre pas de session mesurée. L’aide conserve les placements
et reprend la session d’origine. Les horaires d’exemple correspondent à la banque ; le
nombre de manches annoncé vient de `kDayStackLevels`, sans nouvelle constante métier.
**Suite :** décliner le composant dans les autres tutoriels après définition de leurs cartes
et contrôle de leurs mécaniques ; aucun autre tutoriel n’est converti dans cette livraison.

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
- `MoveFastPlane` / `_PlanePainter` : avion vectoriel calé sur la référence Figma d'origine
  (silhouette blanche, panneaux de règle,
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

### Démo mobile — 2026-09-09

Point d'entrée existant `mobile/lib/main.dart`, avec `kLot1DemoBuild=true` conservé.
Le hub affiche « Games demo » et des résultats d'exemple plutôt qu'une couverture figée à 0 %.
Les quatre jeux demandés sont accessibles dans les sélecteurs de catégorie existants.

| Jeu | Contenu fixe / dynamique | Démo et amélioration |
|-----|--------------------------|---------------------|
| Day Stack | 11–12 tâches par univers, toutes présentes et mélangées, 4 manches | Calendrier mauve, appui maintenu sur la carte seule avec heures visibles pendant le glissement, défilement tactile et automatique aux bords ; bouton Valider séparé, aucun feedback métier avant validation, règles conservant l’ordre ; tutoriel en six cartes illustrées, balayage et boutons. |
| Emotional Radar | 3 situations fixes, réponses famille/nuance/intensité interactives | 3 vidéos locales de substitution, description textuelle, pause/relecture/plein écran. |
| Reflective Pause | 10 situations fixes, réflexion et réponses chronométrées | Largeur lisible sur tablette et contraste des réponses verrouillées amélioré ; tutoriel et aide en cinq cartes illustrées sur fond blanc. |
| Strategic Choices | 80 situations, 10 tirées, 8 stratégies, réflexion et récapitulatif interactifs | 6 messages écrits jouables, 74 scènes lisibles en attente de vidéo ; score serveur /30 provisoire ; tutoriel et aide en cinq cartes illustrées. |

Ces banques fixes ne sont pas des écrans statiques : les actions modifient réellement la session.
Les clips sont illustratifs, **pas une reconstitution ni un stimulus psychométrique validé** ;
le texte de la situation fait référence et cette limite est affichée dans le lecteur.
Le mode API conserve son contenu serveur ; seule la démo remplace les médias Radar.
Les jeux « Je continue », « Je coordonne » et « Je place » restent désactivés dans le hub démo existant.

Références : les 14 planches Reflective Pause et objets disponibles ont été inspectés ; pour
les trois autres jeux, logos existants et écrans/composants Games servent de référence avec
accord explicite du demandeur. Aucun nouvel écran ou barème inventé.

Livraison : `cd mobile && flutter build apk --release` ; APK universel dans
`mobile/build/app/outputs/flutter-apk/app-release.apk`. `video_player` et la déclaration du
dossier vidéo dans `pubspec.yaml` sont **explicitement autorisés**, ainsi que le lockfile et
l'enregistrement natif générés. Prochaines étapes : remplacer les médias illustratifs par
les stimuli validés et faire valider le barème Strategic Choices ainsi que la normalisation émotionnelle.

Vérification de cette livraison : **36 tests ciblés verts**, analyse des fichiers modifiés sans
diagnostic, build APK release (148 796 849 octets) et build web réussis. Installation Android
émulateur réussie ; navigateur : navigation hub → Radar, lecture réelle du MP4, plein écran
sans lecture concurrente, retour sans autoplay, puis placement Day Stack vérifiés.
Suite Games plus large : **337 verts / 5 échecs**, dans les tests Move Fast non modifiés par
cette tâche (quatre tests de flow et une comparaison d'image). Backend : les tests ciblés et
ArchUnit ne s'exécutent pas car la compilation des tests Recruitment échoue sur
`saveIfNotOlder` / `upsertIfNotOlder` ; aucun correctif hors périmètre effectué.

| Élément | Statut |
|---------|--------|
| Planifik #1 « Chemin Optimal » (Flame + barème + persistance) | 🟢 Fait |
| Optimal Path — flow complet mobile (intro Path Mind, How To Play, gameplay, score, comparaison) | 🟢 Fait |
| Optimal Path — amélioration légère des deux cartes de règles | 🟢 Implémentée — style des stations conservé, chemin orthogonal, couleurs du plateau, textes courts et critères de score illustrés ; 🟠 rendu sur appareil à valider (décision 71). |
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
| Predictive Puzzle — deux cartes de règles et schémas nets | 🟢 Implémentés — composants natifs du jeu, fond blanc, comparaison autorisé/interdit et préparation/exécution ; 🟠 rendu sur appareil à valider (décision 70). |
| Predictive Puzzle — **3 niveaux (3 → 4 → 5 disques, optimal `2^n − 1`)** + disques responsive | 🟢 Fait |
| Predictive Puzzle — **barème catégoriel de la fiche** (1er essai/erreurs/coups superflus), remplace l'ancienne formule inventée | 🟢 Fait |
| Predictive Puzzle — cumul multi-niveaux (moyenne /10, 1 `Attempt`) + `globalPlanSuccess` hors score | 🟢 Fait |
| Predictive Puzzle — `puzzle_levels` [3,4,5] & `max_sequence_errors` [3,2,1] | 🟠 Décisions produit **à valider** (fiche : 3 constant) |
| **Planifik #2 `TASK_SCHEDULING` — « Ordonnancement de tâches »** (barème /10 : dépendances 3/0 + horaires 3/0 + cohérence 0–2 + réajustements dérivés) + écran mobile à liste réordonnable + parité mock | 🟢 Fait — Planifik complet **/30** sur ses 3 mini-jeux |
| **Day Stack — emotes par tâche** | 🟢 Collection de 82 PNG générée, vérifiée et intégrée aux cartes du calendrier (repli icône, décodage limité) ; 🟠 taille et rendu à valider visuellement sur appareil (décision 62) |
| **Planifik — jeu complet** (Chemin Optimal + Ordonnancement + Tour de Hanoï, profil global **/30**) | 🟢 **Complet** |
| **« J'investigue » (`MEMORY_QUEST`) — Mission A Digit Span** (observe → rappel même ordre → rappel inverse → résultats), écran Flutter custom, timers data-driven (900 ms / ISI 250 ms), input-lock, clavier accessible (≥48 px), score **mock** (0–5/tâche → composite /100) | 🟡 Fait (mobile, hors-ligne) — tuile hub + route `/games/investigate` + catalogue d'objets (21) |
| **« J'investigue » — Mission B (manipulation d'objets)** : observe l'ordre initial (5 s, verrouillé) → manipulations automatiques (échanges) → **restaurer l'ordre INITIAL** en tap-to-place ; objets par forme+libellé (accessibilité), score restauration → composite /100 | 🟡 Fait (mobile, hors-ligne) — enchaîné après la Mission A |
| **« J'investigue » — phase de distraction** : encode une courte séquence → **question rapide** (5–10 s, fond assombri **calme**, rappel mémoire visible, choix seuls actifs) → **rappel après distraction** ; note = **survie mémoire** (rappel après interférence), justesse de la question affichée à part ; intégré au composite | 🟡 Fait (mobile, hors-ligne) — enchaîné après la Mission B |
| **« J'investigue » — backend (Phase 4)** : mini-jeu `MEMORY_QUEST_CORE`, `MemoryQuestMetrics` (mesures par tâche), `MemoryQuestScoringService` (tâches 0–5 → **composite /100**), indicateurs + détail du score exposés, migration **V12** (CHECK), parité mock ; mobile soumet via le repository (score serveur autoritatif) | 🟢 Fait |
| **« J'investigue » — système de niveaux** (7 niveaux, longueur 3→9, +1 après 3 tâches réussies ; objets 4→12 ; distraction gatée niveau ≥ 3 ; arrêt à `max_sequence_length`/`max_session_duration_min`) | 🟢 Fait (backend + mobile + parité mock) |
| **« J'investigue » — calibrage appareil → timeout** (1er module dont le **score dépend du temps**) : `max_task_time_ms + offset` ; tâche dépassant le seuil ajusté = échec voidé ; `session_valid` | 🟢 Fait — socle `DeviceCalibration`/`CalibrationService` **réutilisé** (non modifié) |
| Accueils et navigation des jeux — téléphone | 🟢 Huit accueils allégés, titres/logos séparés, navigation basse retirée des jeux/tutoriels, entrée Strategic Choices directe ; 32 tests de disposition et huit captures. 🟠 Contrôle sur téléphone réel ouvert (décision 80). Day Stack inchangé. |
| Memory Quest Digits/Image — tutoriels visuels et aide | 🟢 Six cartes et illustrations nouvelles par jeu, objets de partie exclus, dix cartes adaptées au mode historique. 🟠 Rendu sur appareil et défauts préexistants de câblage ouverts dans l’audit du 2026-09-17. |
| **« Je Décide » (`DECISION`)** | 🟢 Jouable end-to-end (V59) — accueil avec logo, transition vers les règles dans un cadre persistant, trois cartes utiles et un exemple, sans personnalisation ; questions II retirées et situation/réponses ensemble sur une page ; banque historique de 120 items, 24 items actifs servis sans clé de correction, notation serveur /72 → SCW /100 et profil réel sur quatre axes. Reste : modèles λ/k/cohérence pour ER-1..18, CS et RE, puis formes B/C/D |
| **« Emotional Radar » (`EMOTIONAL_REGULATION`) — 5ᵉ domaine** : `GameType` + `EMOTIONAL_RADAR_CORE`, barème 9 pts/scène, écran Flutter complet (cover, tutoriel, gameplay à révélation progressive, feedback, transition, résultats, pause/aide/plein écran), parité mock | 🟢 **Fait** — jouable sur les 3 scènes rédigées (27 pts) |
| Emotional Radar — **contenu servi par le backend** (texte/image/vidéo) : catalogue en base, `GamesMediaStoragePort` + adaptateur Cloudinary dédié, endpoint de téléversement | 🟢 Fait — 1ᵉʳ jeu du module dont le matériel n'est pas embarqué |
| Emotional Radar — **notation par scène côté serveur** (clé de correction jamais envoyée au client ; score reconstruit depuis les réponses persistées) | 🟢 Fait — migration **V25**, table `emotional_radar_answers` |
| Emotional Radar — taxonomie ANGER/DISGUST/SURPRISE (Ekman) | 🟠 **PROVISOIRE** — absente des maquettes, à valider par le psychologue |
| Emotional Radar V2 — tutoriel visuel et aide | 🟢 Implémentés — cinq cartes et illustrations dédiées ; 🟠 contrôle visuel sur appareil ouvert (décision 65). Autres tutoriels à convertir dans une prochaine tâche. |
| Choix stratégique / Reflective Pause / Radar émotionnel — icônes et insights | 🟢 Implémentés — icônes des huit stratégies toujours visibles, profil Reflective en jauges, comptes d’intensité Radar en barres ; 🟠 rendu sur appareil à valider (décision 72). |
| Emotional Radar — 12 scènes manquantes (15 visées) | 🔴 En attente du psychologue — aucune scène inventée |
| **« Reflective Pause » (`REFLECTIVE_PAUSE_CORE`)** : contrat, domaine pur, barème serveur 3/4/3, V26, API, breakdown et parité mock | 🟢 **Fait — /10**, 10 moments obligatoires |
| Reflective Pause — mobile complet : cover, intro, tutoriel, timer 3 s, réponses, transition sauvegardée, résultats, insights, pause/règles, route et picker Emotional Regulation | 🟢 Fait — logo officiel net réutilisé |
| Reflective Pause — tutoriel illustré et aide | 🟢 Implémentés — cinq nouvelles illustrations, commandes accessibles, retour de l’aide avec sélection conservée ; 🟠 validation visuelle sur appareil ouverte. Les autres tutoriels restent à convertir. |
| Strategic Choices — mobile + serveur : banque 80, tirage 10, métriques brutes, score /30, breakdown, mock et parité | 🟢 **Fait end-to-end**, barème et interprétation **PROVISOIRES** |
| Strategic Choices — tutoriel visuel et aide | 🟢 Implémentés — cinq cartes et illustrations dédiées ; reprise avec sélection et réflexion conservées. 🟠 Rendu sur appareil à valider. Autres tutoriels à convertir ultérieurement. |
| Strategic Choices — 6 messages écrits littéraux | 🟢 Jouables sans média : `CS-102/104/108/112/115/116` |
| Strategic Choices — 74 vidéos, sous-titres/transcriptions | 🔴 Différé — scènes textuelles affichées en attendant les médias validés |
| Domaine Emotional Regulation — session partagée Radar + Reflective + Strategic Choices, complétion + event | 🟢 Fait — somme brute provisoire **/67** (27 + 10 + 30) |
| Profil global émotionnel normalisé /30 | 🔴 Différé — règle de normalisation non validée |
| Bascule mock ⇄ backend | 🟢 `--dart-define=GAMES_MOCK` |
| Socle de calibrage appareil (méthode « technique », transversal) | 🟢 Fait — appliqué à Move Fast (indicateurs `*Adjusted`), réutilisable Decision/Memory Quest |
| Calibrage — table `games.device_calibrations` (V11) + fallback fiabilité réduite | 🟢 Fait |
| **Panneau « détail du score »** (dont Move Fast, Planifik, Reflective Pause, Je continue, Je coordonne et Je place) | 🟢 Fait côté serveur/mock (`ScoreBreakdownService`) ; affichage `ScoreDetailPanel` sur les écrans qui l'exposent |
| Intégration Analytics (event) | 🟢 Listener en place (log ; à brancher au vrai dashboard) |
| **Console web d'administration Games** (`admin/`, Better T Stack + TanStack Start) | 🟢 **Control plane complet** : UI responsive Flutter-like, JWT `ADMIN`, CRUD/versioning/publication/archivage, création de version héritée de la publication active, diff exact et revue d'impact avant publication, composition ordonnée des banques, rotation, 16 schémas typés settings/modifiers servis par Spring, uploads PNG/SVG, audit immuable ; aucune donnée de démonstration |
| **Application runtime des contenus/configurations administrés** | 🟢 Snapshot immuable par session ; les 8 `GameType` ont chacun un `SETTINGS` et un `MODIFIERS` publié. `sessionEnabled` contrôle réellement le démarrage de toute nouvelle session ; `reducedMotionDefault` est livré pour tous et consommé par les parcours possédant déjà une branche reduced-motion (Radar, Reflective Pause, Je continue, J'investigue). Radar applique aussi `sceneCount`, `orderMode`, aide, feedback et durée de transition. Rotation et banques publiées sont consommées par Je Décide/Emotional Radar. |

---

**Roadmap accueils mobiles (2026-09-18)** : accueils enrichis sur demande de
l’utilisateur : logo officiel, nom, mission, bref contexte propre au jeu et trois
repères numérotés. Groupe centré avec action proche du parcours ; logo et espace
adaptés à la hauteur. Textes détaillés conservés dans les tutoriels. Navigation basse retirée des routes de jeux, seconde entrée
Strategic Choices supprimée. Petits écrans et texte agrandi vérifiés ; contrôle
sur téléphone réel à effectuer. Aucun changement de règles, barèmes ou assets.

**Roadmap Je Décide (2026-09-17)** : simplification d’accueil/tutoriel livrée à la
demande de l’utilisateur : une introduction avec logo, trois cartes indispensables,
un exemple, personnalisation retirée à la demande de l’utilisateur ; cadre persistant
et passage animé vers les règles. Questions longues II retirées avec leur dimension du bilan, sur confirmation ;
24 questions actives et quatre axes, situation et réponses sur une page.
Clé POST `decisionItems` alignée avec le DTO serveur et testée sur le chemin HTTP.
SFX des quatre fins de catégorie et compteur final vérifiés ; échec de soumission
affiché avec nouvelle tentative conservant session/réponses, sans faux score à zéro.
Captures, entrée/retour, mouvement réduit et accessibilité à 200 % vérifiés ;
validation visuelle sur appareil ouverte. Passation, notation et protocoles inchangés.

**Roadmap insights émotionnels (2026-09-17)** : icônes de Choix stratégique,
profil visuel de Reflective Pause et répartition des évaluations d’intensité de
Radar livrés. Vérification visuelle par captures ; rendu sur appareil à valider.
Les scores, seuils d’interprétation et règles de partie restent identiques.

**Roadmap Optimal Path (2026-09-17)** : légère amélioration des deux pages de
règles livrée, en conservant les stations rondes et le barème existant. Captures
et navigation vérifiées ; validation visuelle sur appareil ouverte. Gameplay,
aide de pause, progression et calcul du score inchangés.

**Roadmap Predictive Puzzle (2026-09-17)** : les deux fenêtres de règles sont
harmonisées avec les tutoriels en cartes. Schémas natifs vérifiés par captures ;
validation visuelle sur appareil ouverte. Aucun changement de progression ou de barème.

**Roadmap Memory Quest (2026-09-17)** : tutoriels Digits/Image et aide illustrés
livrés ; rendu sur appareil à valider. Priorités techniques ouvertes : projection
du mode dans les métriques, suspension des horloges, budgets et compteurs des
casse-têtes visuels, agrégation des métriques Image. Audit et reproductions dans
`mobile/assets/memory-quest-tutorial/AUDIT_LOGIQUE.md`, sans changement de barème.

## 🧠 Décisions à valider avec le psychologue référent

**BART + IST (98) — liste complète dans `docs/PREUVES_SCIENTIFIQUES_JEUX_DECISION.md` §9.**
Bloquant pour sortir du provisoire : (a) formule d'efficience EV du BART (stratégie fixe
`n* = 64`, plafond 100, séquence dégénérée → invalide) ; (b) poids du score IST 0,4 / 0,4 / 0,2 ;
(c) a priori de génération des grilles IST (majorité 13 à 19 cases), dont dépend P(correct) —
choisi pour contourner le désaccord Bennett 2017 / Axelsen 2018 sur la formule publiée, dont le
texte intégral n'a pas pu être obtenu ; (d) échelle de confiance 0,5 / 2⁄3 / 5⁄6 / 1 — corrige le
0,625 du design initial, qui donnait 62,5 % à « au hasard » ; (e) seuils de validité. Questions de
fond : points sans valeur monétaire alors que les paradigmes ont été validés avec de l'argent ;
transfert à une population de candidats, bien plus homogène que les échantillons cliniques
d'origine ; pas de retour d'information après chaque essai IST (absent des maquettes, présent
dans le protocole d'origine) ; aucun état visuel « ballon sous tension » (seule la taille,
fonction des seules pompes, sert d'indice). Événement Fit Score **suspendu** et
`DECISION_BEHAVIORAL` rattaché à aucun `SoftSkillModule`.

État livraison (54) : admin/Docker unifiés sur `zennyt`, huit timers live câblés dans les quatre
parcours concernés, UI filtrable par jeu et statut. Activation mobile live différée à la demande
du client ; démo inchangée. Les timers des protocoles Je Décide / Je continue / Je coordonne /
Je place restent protégés plutôt qu'exposés comme contrôles sans effet.

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
| 27 | **Emotional Radar — autorisation de l'upload média** | endpoint historique désormais **réservé à `ROLE_ADMIN`** ; médiathèque générique également protégée | Arbitrage résolu par la création de la console d'administration | `EmotionalRadarController.uploadMedia` · `GamesAdminController` |
| 28 | **Reflective Pause — barème 3/4/3** | temps contrôlé /3 + non-impulsivité /4 + prise de recul /3 ; sous-scores à 0,1, somme arrondie une fois | Le handoff nomme les dimensions et le score /10 mais ne fixe pas explicitement les poids | `ReflectivePauseConfig` / miroir Dart |
| 29 | **Reflective Pause — moment 3** | `WAIT` **ou** `REFORMULATE_CALMLY` comptent comme prise de recul | Content map : « Wait, then reformulate calmly » sans préférence entre les deux choix UI | `ReflectivePauseConfig.RECOMMENDED` |
| 30 | **Profil émotionnel provisoire /67 brut** | session complétée avec Radar actuel /27 + Reflective /10 + Strategic Choices /30 | La planche globale prévoit 3 jeux ×10 = /30, mais la normalisation des trois mini-jeux n'est pas fournie | Les trois `MiniGame` d'`EMOTIONAL_REGULATION` |
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
| 54 | **Strategic Choices — barème et supports** | 3ᵉ mini-jeu d'`Emotional Regulation` ; 80 situations, 10 tirées ; somme des cotations 0–3 sur /30 et indice corrigé du hasard ; 6 scènes naturellement écrites converties en messages littéraux, 74 restent vidéo | **PROVISOIRE — à valider par le psychologue** : clé reconstruite par inférence, interprétation, stimuli vidéo et normalisation émotionnelle /30 non validés | `StrategicChoicesConfig` · banques JSON · `strategic_choices_screen.dart` · tooling de génération |
| 55 | **Defaults d'exploitation de la console** | `sessionEnabled=true` dans `SETTINGS` et `reducedMotionDefault=false` dans `MODIFIERS` pour les 8 `GameType` ; ces valeurs reproduisent le comportement antérieur et sont versionnées, jamais rétroactives sur une session ouverte | La demande exige un contrôle complet mais ne fixe pas les valeurs initiales ni le vocabulaire des clés ; arbitrage produit à confirmer | `AdminConfigurationSchemaRegistry` · V74/V75 · `StartGameSessionUseCase` |
| 19 | **« Je Décide » — équivalence des formes parallèles** | Forme A seule seedée (V59). Les 4 formes ne peuvent pas être équivalentes tant que ER-1..18, CS et RE sont en notation neutre : la seule forme contenant ER-19..24 serait la seule où ER discrimine, et le Fit Score compare les candidats globalement | Modèles d'aversion λ (ER), d'actualisation hyperbolique k (RE) et de cohérence de paire (CS) — 66 items sur 120 restent en notation neutre en attendant | `V67__games_decision_scenarios.sql`, `DecisionScoringService.java`, `decision_scenarios.json` |

Décisions additionnelles du 2026-09-06 :

- **56 — Timers administrables** : huit timers de présentation optionnels (changelog 54),
  defaults historiques conservés. Bornes d'exploitation **provisoires, à valider** avant un usage
  psychométrique comparatif. Le feedback Move Fast consomme toujours son budget de session ;
  Reflective Pause peut allonger la réflexion mais garde son seuil de scoring fixe à 3 s.
- **57 — Mobile démo** : `kLot1DemoBuild=true` laissé intact sur choix explicite « Keep mobile
  demo mode for now ». L'admin utilise `zennyt` mais la démo mobile ne consomme pas les publications.
- **58 — Médias Radar de démonstration** : trois clips Mixkit gratuits intégrés avec accord
  explicite pour `video_player` et les assets. **PROVISOIRE — à valider** : ils illustrent le
  lecteur, sans changer les textes/réponses attendues ni prétendre valider un stimulus.
- **59 — Références UI démo** : accord explicite pour reprendre les écrans et composants
  existants de Day Stack, Radar et Strategic Choices en l'absence de maquettes complètes.
  « Day Stack » est le libellé demandé de `TASK_SCHEDULING`, pas un nouveau mini-jeu.

- **60 — Day Stack, réorganisation libre (2026-09-11)** : décision explicitement
  autorisée par le demandeur : liste complète mélangée, déplacements sans pénalité,
  évaluation uniquement à la validation. Le compteur visuel de déplacements et son
  état local devenu inutile sont retirés sur demande le 2026-09-16, sans toucher au payload. La portée psychométrique de l’autorégulation
  sans retraits reste à valider ; aucune nouvelle formule de score n’est introduite.

- **61 — Day Stack, emotes par tâche (2026-09-16)** : génération demandée par
  l’utilisateur. **PROVISOIRE — à valider visuellement** : objets arrondis en 2.5D,
  contour clair sur mauve, signes de direction pour les actions de camion ; patient A
  distingué par un repère magenta, patient B par deux points cyan, sans lettres dans
  les images. Ces repères n’ajoutent aucune règle métier. PNG non intégrés ; toute
  déclaration dans `pubspec.yaml` reste soumise à l’autorisation explicite du §3 AGENTS.

- **62 — Day Stack, emotes dans les cartes (2026-09-17)** : intégration demandée
  (plan 001), déclaration des sept dossiers autorisée explicitement. **PROVISOIRE —
  à valider visuellement sur appareil** : emote de 32 px dans les cartes (28 px pour
  l’ancien carré), 38 px en taille normale, sans carré coloré autour ; le liseré garde
  la couleur de catégorie. Les captures de test sont rendues à densité 1 et ne
  valent pas validation visuelle. Aucune règle métier ni donnée de score modifiée.

- **63 — Tutoriels en cartes, pilote Day Stack (2026-09-17)** : format visuel
  successif demandé par l’utilisateur, réutilisable dans Games. **PROVISOIRE — à valider
  visuellement sur appareil** : six cartes pour séparer les types d’horaires, emotes des
  exemples à 64 px et pile mauve. Le texte explicatif conserve son grossissement accessible ;
  les petits repères du schéma sont plafonnés à 120 % et décrits sémantiquement. Les tutoriels
  des autres jeux restent à convertir ; aucune règle d’évaluation ni nouvelle dépendance.

- **64 — Day Stack, nouvelle présentation du tutoriel (2026-09-17)** : la première
  présentation du changelog 76 est refusée par l’utilisateur. Nouvelle direction : fond
  mauve jusque dans les marges système, pile de cartes claires compacte, visuels agrandis,
  texte centré et démonstration locale manipulable sur la première carte. **PROVISOIRE —
  à valider visuellement sur appareil et par l’utilisateur** : dégradé, hauteur maximale
  540 px, emotes de 80 à 132 px. Le format en six étapes et les règles expliquées restent
  identiques ; aucun tutoriel d’un autre jeu ni barème modifié.

  **Ajustement demandé ensuite (2026-09-17)** : cartes et présentation conservées,
  dégradé de fond retiré au profit du blanc habituel des tutoriels Planifik. Titres et
  navigation adaptés au fond clair ; les scènes illustrées dans les cartes restent intactes.

- **65 — Radar émotionnel, tutoriel illustré (2026-09-17)** : conversion et nouvelles
  illustrations demandées par l’utilisateur, dans la présentation Day Stack approuvée :
  fond blanc, cartes centrées et texte court. **PROVISOIRE — à valider visuellement sur
  appareil** : cinq PNG arrondis en 2.5D, couleurs Zennyt et symboles pédagogiques.
  Les illustrations ne sont pas des stimuli psychométriques et ne représentent aucune
  clé de correction. Le contenu suit V2 : émotion directe puis intensité, sans nuance
  ni justification. Aucun changement de configuration, de timing réel, de score ou
  de protocole ; aucune nouvelle dépendance ou déclaration d’asset.

- **66 — Reflective Pause, tutoriel illustré (2026-09-17)** : même présentation
  que Day Stack et Radar demandée par l’utilisateur : fond blanc et cartes centrées.
  **PROVISOIRE — à valider visuellement sur appareil** : cinq illustrations arrondies
  en 2.5D aux couleurs Zennyt. Elles expliquent les supports, le déverrouillage,
  la sélection, la sauvegarde et le bilan ; aucune réaction recommandée ni correction
  pendant le parcours. Le texte distingue délai de réflexion et temps conseillé,
  sans imposer trois secondes à une session administrée. Aucun changement de règles,
  de durée réelle, de scoring ou de déclaration d’assets.

- **67 — Choix stratégiques, tutoriel illustré (2026-09-17)** : même présentation
  que les trois tutoriels précédents demandée par l’utilisateur : fond blanc et cartes
  centrées. **PROVISOIRE — à valider visuellement sur appareil** : cinq nouvelles
  illustrations arrondies en 2.5D, palette Zennyt et boussole. Le choix reste possible
  pendant la réflexion, la validation après sa fin. Les illustrations n’indiquent
  aucune stratégie recommandée et le score garde son caractère provisoire. Aucun
  changement de règle, de durée réelle, de barème ou de déclaration d’asset.

- **68 — Je Décide, tutoriel illustré (2026-09-17)** : même présentation que les
  tutoriels précédents demandée par l’utilisateur : fond blanc et cartes centrées.
  **PROVISOIRE — à valider visuellement sur appareil** : six illustrations arrondies
  en 2.5D, palette Zennyt et chemin magenta à étapes rappelant les assets existants.
  Elles expliquent le parcours sans réponse recommandée ni clé de cotation. Les textes
  distinguent minute ordinaire et choix rapides, validation ou passage à zéro, exemple
  d’entraînement et bilan de cinq dimensions avec cotations provisoires signalées.
  Aucun changement de protocole, scoring, durée réelle ou déclaration d’asset.

- **69 — Memory Quest Digits et Image, tutoriels illustrés (2026-09-17)** :
  refonte et générations nouvelles demandées par l’utilisateur, sans reprendre les
  objets de partie. Fond blanc et cartes centrées approuvés conservés.
  **PROVISOIRE — à valider visuellement sur appareil** : douze illustrations
  2.5D pédagogiques ; exemple chiffré 3–7–2 et symboles coquillage/lune/plume
  propres au tutoriel Image. Aucun stimulus ni clé de correction réel montré.
  Six cartes par mode séparé, dix pour le mode historique ; contenu déterminé
  après vérification du code et des règles. Défauts préexistants de soumission,
  pause et métriques consignés dans l’audit, corrections ouvertes. Aucun changement
  de protocole, scoring, durée réelle, dépendance ou déclaration d’asset.

- **70 — Predictive Puzzle, netteté des deux cartes de règles (2026-09-17)** :
  ajustement demandé par l’utilisateur, fond blanc et cartes centrées conservés.
  **PROVISOIRE — à valider visuellement sur appareil** : remplacement de la
  consommation du petit PNG par les widgets natifs `_Disc` / `_TowerView` ;
  exemples petit-sur-grand autorisé et grand-sur-petit interdit. La seconde carte
  montre un préfixe de trois coups, le plan restant à compléter puis `Run Plan`.
  Deux cartes seulement, sans solution complète ni changement de règle métier.
  Textes de carte accessibles à 200 %, dessin proportionné avec description sémantique.
  Les nouveaux paramètres visuels de la tour gardent les valeurs de partie par défaut.
  Aucun nouvel asset, aucune dépendance, aucune modification du protocole de pause.

- **71 — Optimal Path, légère amélioration du tutoriel (2026-09-17)** :
  ajustement demandé par l’utilisateur, avec conservation du style existant.
  **PROVISOIRE — à valider visuellement sur appareil** : deux cartes centrées sur
  fond blanc ; stations rondes mieux espacées, tracé magenta orthogonal et couleurs
  `BoardPalette` identiques au jeu (LAB blanc/bleu, MTG vert, bloc rouge, étoile dorée).
  Texte court conforme au tap/drag réel ; les quatre critères de score existants
  sont présentés comme maxima par niveau, sans modifier leur calcul. Schémas
  vectoriels proportionnés avec descriptions sémantiques ; texte de carte à 200 %.
  Aucun nouvel écran, asset raster, dépendance ou changement du protocole de pause.

- **72 — Choix stratégique et insights émotionnels (2026-09-17)** :
  améliorations visuelles demandées par l’utilisateur. **PROVISOIRE — à valider
  visuellement sur appareil** : huit pictogrammes Material selon la stratégie,
  conservés sous cadenas et coche via un badge séparé ; fuite = course, action
  directe = main qui agit, sans couleur dépendant de la cotation d’une réponse.
  Reflective Pause compare les trois critères par leur propre maximum (3/4/3),
  avec points serveur visibles et compte impulsif ; absence de rapport sans faux
  point fort. Radar présente les comptes du rapport `intensityErrorDirection`
  dans l’ordre sous-estimée/correcte/surestimée et conserve le pourcentage global
  d’intensité ; il ne s’agit pas d’un graphique d’émotions inventées par le client.
  Jauge de Games réutilisée en variante pleine largeur, mouvement réduit respecté.
  Aucun changement de score, seuil psychométrique, métrique envoyée ou règle de pause.

- **73 — Je Décide, parcours d’entrée simplifié (2026-09-17)** : parcours
  validé par l’utilisateur, qui demande son implémentation : une page d’accueil avec
  logo, but court, durée et 30 questions ; trois cartes utiles réunissant lire/choisir,
  scénarios liés et chrono ; un seul exemple avant la partie. Les anciennes pages
  d’onboarding et cartes supplémentaires sont retirées du parcours. Pseudo, thème et
  avatar restent facultatifs, accessibles depuis l’accueil ; retour des règles à l’accueil.
  Bilan à cinq dimensions et cotations provisoires annoncés à l’accueil et conservés aux résultats.
  **PROVISOIRE — à valider visuellement sur appareil** : rendu des écrans et des trois
  illustrations existantes. Aucun nouvel asset, dépendance, changement de passation,
  score, délai réel, métrique ni règle de pause ; sources graphiques historiques conservées.

- **74 — Je Décide, continuité accueil/règles (2026-09-17)** : l’utilisateur
  demande d’améliorer la présentation et l’animation du passage. **PROVISOIRE — à
  valider visuellement sur appareil** : conserver l’en-tête du jeu et la barre basse,
  déplacer le titre « Comment jouer » dans l’en-tête existant, masquer le doublon dans
  la pile par une option désactivée uniquement pour ce parcours. Fondu et glissement
  léger de 320 ms à l’entrée et au retour ; mouvement réduit sans animation, contenus
  sortants sans interaction ni annonce. Logo, trois illustrations et fond blanc conservés.
  Les autres tutoriels gardent leur en-tête par défaut ; aucune modification de règle,
  passation, score, métrique, chrono réel ni protocole de pause.

- **75 — Je Décide, suppression de la personnalisation (2026-09-17)** :
  demande explicite de l’utilisateur de retirer toute la partie jugée non fonctionnelle.
  Bouton, écrans pseudo/thème/avatar et code local associés supprimés. Cette décision
  remplace la branche facultative introduite en décision 73. Parcours unique : accueil,
  trois cartes, un exemple, puis les 30 questions ; transition de la décision 74 conservée.
  Les assets originaux restent archivés, sans modification de `pubspec.yaml`. Aucun
  changement de scoring, de métrique, de passation ou de protocole de pause.

- **76 — Je Décide, questions longues en deux étapes (2026-09-17)** :
  l’utilisateur confirme que le signalement concerne la situation puis les réponses,
  et demande une meilleure présentation avant d’envisager le retrait de ces questions.
  **PROVISOIRE — à valider visuellement sur appareil** : repère Situation/Réponse en
  pastilles dans la bande déjà réservée, lecture centrée et bouton Relire explicite
  dans le pied de l’écran de choix, variante accessible à 200 %. Composants, couleurs
  et flèches existants réutilisés ; aucune illustration suggérant une réponse ni asset créé.
  Questions conservées intégralement, réponse sélectionnée conservée après relecture.
  Aucun changement de timer, mesure temporelle, score, ordre ou taille de forme. Le
  défilement des textes dépassant physiquement les plus petits écrans reste nécessaire,
  avec les mêmes bornes connues. La suppression d’items n’est pas implémentée.

- **77 — Je Décide, refonte des réponses longues (2026-09-17)** :
  la capture de l’utilisateur montre les changements de la décision 76, jugés trop
  légers. **PROVISOIRE — à valider visuellement sur appareil** : réponses regroupées
  en lignes numérotées dans un seul panneau blanc, graisse réduite, consigne intégrée
  au panneau et aperçu du contexte avec Relire en tête ; Continue pleine largeur.
  Aperçu limité à une ligne, situation complète conservée et accessible par relecture ;
  aucune réponse tronquée ni indication de qualité. Composants et palette existants
  réutilisés sans asset créé. Capture dédiée au véritable item appartement II-3.
  Contenus, ordre servi, score, chronomètres, pause et métriques inchangés ; maintien
  des bornes connues de défilement sur petits écrans. Remplace la disposition du pied
  de la décision 76, dont le repère Situation/Réponse et la lecture centrée sont conservés.

- **78 — Je Décide, retrait II et version à 24 questions (2026-09-17)** :
  après rejet des présentations sur deux pages, l’utilisateur confirme le retrait des
  six questions II et de la dimension d’analyse des contraintes du bilan. Remplace les
  décisions visuelles 76/77. Parcours et démo à 24 questions (6 ER/DT/CS/RE), bilan à
  quatre axes, brut /72 et SCW /100 sur ces seuls axes ; règles d’item, budgets DT,
  calibrage et imputation des dimensions restantes inchangés. Sélection centralisée
  côté serveur, aucune suppression de contenus historiques ni des références DT.
  Navigation Situation/Réponse supprimée ; une seule page, défilable si nécessaire
  sur les plus petits écrans ou en texte agrandi. **PROVISOIRE — modification produit
  autorisée, validation psychologue à obtenir** : cette version à quatre capacités
  diffère de la fiche et du bilan historique à cinq axes ; comparabilité à valider.

- **79 — Je Décide, SFX et résultat final (2026-09-17)** : correction demandée
  des jalons silencieux et du bilan affichant 0 lors d'un échec d'envoi. Réutilisation
  du SFX badge existant sur les quatre fins de catégorie et du compteur commun.
  L'échec utilise le panneau existant et conserve les réponses en mémoire pour
  réessayer sur la même session ; aucun barème, protocole ou asset ajouté.
  **Décision technique**, aucun nouveau choix psychométrique. Écoute sur appareil
  ouverte ; tests automatisés vérifient les déclenchements, la coupure du son,
  l'absence de résultat artificiel et la progression du compteur.

- **80 — Accueils courts et espace de jeu mobile (2026-09-18)** : ajustements
  demandés par l’utilisateur à partir de ses captures Android. Huit accueils avec
  logo officiel, nom, mission courte et action ; informations redondantes retirées
  de l’accueil, règles conservées dans les tutoriels. Nom « Optimal Path » aligné
  sur le catalogue, titres et logos séparés. Menu bas de l’application retiré des
  routes de jeux et tutoriels, dont Je continue ; hub et barre système inchangés.
  Seconde introduction Strategic Choices retirée, retour du tutoriel vers l’accueil.
  Day Stack conservé comme référence, sans modification. Cette décision remplace
  le maintien de la barre basse de la décision 74. **PROVISOIRE — à valider
  visuellement sur téléphone réel** : captures et tests à 320×568/360×640/360×800,
  texte 200 % ; accueil sans défilement au texte normal, page entière défilable
  si les besoins d’accessibilité dépassent sa hauteur. Aucun asset, dépendance,
  nouveau parcours métier, métrique, score, chrono ou protocole modifié.

- **81 — Accueils, correction du vide blanc (2026-09-18)** : après retour de
  l’utilisateur, carte et bouton forment un groupe centré ; écart constant de
  24 px, logo agrandi à 176 px si la hauteur le permet et 104 px sur petit écran.
  Le retour reste en haut. Fond blanc, palette et assets officiels conservés.
  Complète la décision 80 sans réintroduire les informations retirées ; texte
  agrandi toujours défilable, aucun bouton fixe masquant le contenu.
  **PROVISOIRE — à valider visuellement sur téléphone réel** : huit captures
  contrôlées et 32 tests de disposition incluant la proximité carte/action.
  Aucun changement de gameplay, passation, score, protocole ni dépendance.

- **82 — Accueils contextualisés (2026-09-18)** : après rejet de l’accueil
  trop vide, l’utilisateur demande du contexte ou une adaptation des logos.
  Choix implémenté : conserver les assets officiels, ajouter un bref contexte
  par jeu et trois repères numérotés. Digits présente la restitution dans les deux
  sens ; Image rappelle l’ordre initial ; Optimal Path les obstacles/documents ;
  Predictive Puzzle l’exécution du plan ; Radar l’émotion/intensité ; Reflective
  la pause avant réponse ; Strategic le choix d’une stratégie ; Je Décide les
  compromis. Aucun exemple suggérant une réponse cotée ni promesse de diagnostic.
  Complète/remplace la présentation des décisions 80/81 : groupe centré enrichi,
  logo et espacements adaptés à la hauteur, action proche du parcours. Day Stack
  conservé. **PROVISOIRE — à valider visuellement sur téléphone réel** : huit
  captures, petits formats et texte agrandi vérifiés ; règles détaillées conservées.
  Aucun nouveau logo, asset, dépendance, barème, délai ou protocole ajouté.

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

**Changelog (55) — 2026-09-09** : démo des quatre jeux demandés : Day Stack responsive et règles
sans perte de session, largeur partagée et choix Strategic Choices adaptatifs, contraste Reflective
Pause, vidéos Radar embarquées avec commandes et pause de cycle de vie. Audit du contenu fixe,
tests de layout/lecture/parité et provenance des clips ajoutés. Dépendance et assets autorisés.
Barèmes, contrats, migrations et intégrations inter-modules inchangés par cette tâche.

**Changelog (54) — 2026-09-06** : console unifiée sur la base mobile historique `zennyt` après
sauvegarde, comparaison des schémas et répétition sur clone. Historique V59–V61 réconcilié avec
autorisation explicite, huit migrations appliquées par Flyway ; aucun ancien fichier SQL modifié.
Compte admin, questions, banques, versions, audit et PNG conservés. Compose gère le web et un
volume d'assets persistant, avec redémarrage automatique. Le client admin renouvelle les tokens
en single-flight et distingue identifiants incorrects, 5xx et panne réseau.

Contrat **v1.8.0** : huit SETTINGS optionnels, defaults/bornes en ms :
`memoryDigitVisibleMs` 900 [300–3000], `memoryDigitGapMs` 1000 [200–3000],
`memoryManipulationStepMs` 750 [200–3000], `memoryRetentionMs` 3000 [0–10000],
`puzzlePlaybackStepMs` 420 [150–2000], `responseFeedbackMs` 650 [200–2000],
`reflectiveThinkingTimeMs` 3000 [3000–15000], `reflectiveTransitionMs` 700 [0–5000].
`AdminConfigurationSchemaRegistry.effectiveValues` et `JdbcGameAdminRepository` matérialisent
les defaults à la création de session. Nouveau `mobile/.../domain/config/game_presentation_timing.dart`
(miroir centralisé) consommé par Investigate, Move Fast, Predictive Puzzle et Reflective Pause.
Les trois premiers attendent la session avant le gameplay ; aucun calcul de score changé.

UI : artwork officiel, sélection par jeu, filtres de versions, unités ms/s, switches nommés et
diff des valeurs effectives (y compris defaults anciens). Fichiers nouveaux : `admin/Dockerfile`,
`.dockerignore`, `admin/tests/admin-api.test.ts`, `GamePresentationTiming`, son test Dart et les
scripts de reprise/smoke dans `tooling/games/`. Tests : 14 backend ciblés dont 3 ArchUnit,
22 Flutter, 10 auth web ; build web et TypeScript verts. Analyse ciblée des 9 fichiers Dart : clean.
Smoke live valide connexion, schémas,
bornes, asset, refresh après redémarrage et connexion suivante. `flutter analyze` global :
18 diagnostics préexistants ; compilation globale des tests Maven bloquée par recruitment.
Barèmes, événements, shared/core, `pom.xml` et `pubspec.yaml` intacts. Mobile démo conservé sur choix utilisateur.

**Changelog (53) — 2026-09-01** : le cycle de version des paramètres/modificateurs est désormais
pilotable sans reconstruire une configuration. « Créer vN+1 » reprend automatiquement toutes les
valeurs de la version publiée du même `GameType`/kind ; la création globale fait de même après le
choix du jeu et conserve les defaults Spring seulement pour un flux sans publication. L'éditeur
affiche en direct chaque différence `ancienne valeur → nouvelle valeur`. Les cartes brouillon
annoncent le nombre d'écarts et l'action Publier ouvre une revue dédiée listant le diff exact,
la version publiée qui sera archivée et la garantie de snapshot des sessions en cours. Cette revue
devient une bottom sheet responsive à 390×844. Vérifications : TypeScript, Oxlint/Oxfmt et build
Vite/SSR verts ; parcours réel WebKit desktop/mobile vert contre Spring/PostgreSQL (héritage,
diff live, création, revue de publication), zéro erreur console ; le brouillon de vérification a été
supprimé après le test. **Aucun contrat/API, backend, mobile, barème, formule de scoring, Domain Event,
`pom.xml`, `pubspec.yaml`, migration existante, module `identity`, `shared` ou `core` modifié dans ce
lot.**

**Changelog (52) — 2026-09-01** : les paramètres et modificateurs de la console deviennent
**typés et validés de bout en bout**. Le contrat `v1.7.0` expose
`GET /games/admin/configuration-schemas` ; Spring fournit 16 schémas (`8 GameType × 2 kinds`) et
refuse les clés inconnues/protégées, types incorrects, valeurs hors bornes et enums invalides, y
compris juste avant publication. Le web ne demande plus de JSON brut : switches accessibles,
nombres bornés, listes et libellés métier sont rendus depuis le schéma serveur, avec layout vérifié
à 390×844 et desktop. V70 garantit une version publiée de chaque flux ; V71 convertit les anciennes
configurations libres vers l'allowlist en archivant leur version, sans réécrire l'historique.
`sessionEnabled` bloque effectivement les nouvelles sessions tout en préservant celles déjà ouvertes ;
le défaut reduced-motion versionné est consommé par Radar, Reflective Pause, Je continue et
J'investigue, et Radar conserve ses contrôles de scènes/ordre/aide/feedback/transition.
Vérifications : compilation principale Java 21 + génération OpenAPI + démarrage Spring verts,
Flyway V70/V71 appliqué sur PostgreSQL 16, **6 tests Java ciblés verts**, smoke API réel (16/16
streams conformes, écriture protégée 400, session désactivée 400 puis restauration), TypeScript,
Oxlint/Oxfmt et build Vite/SSR verts, Playwright WebKit desktop/mobile vert, analyse Flutter ciblée
sans issue et **19 tests Flutter verts**. La compilation globale des tests backend reste bloquée par
les 6 erreurs préexistantes du module `recruitment` (`saveIfNotOlder`/`upsertIfNotOlder`), non modifié.
**Aucun barème, formule de scoring, Domain Event, `pom.xml`, `pubspec.yaml`, migration existante,
module `identity`, `shared` ou `core` modifié.**

**Changelog (51) — 2026-08-30** : le dashboard Games reprend la taxonomie et le langage visuel du
hub Flutter : **5 catégories et 13 entrées**, illustrations officielles copiées depuis les assets
mobile, cartes adaptatives et fiche d'administration dédiée pour chaque jeu. Chaque fiche mène aux
questions, banques, paramètres, modificateurs et assets dans le contexte du jeu ; les listes sont
filtrées et les formulaires préremplissent le `contentType` ou `gameType` sélectionné. Les contrôles
éditoriaux restent explicitement non applicables pour les protocoles qui n'utilisent pas de questions ;
Strategic Choices reste une preview sans runtime Spring et ses contrôles sont donc désactivés plutôt
que simulés. Aucun endpoint, contrat, backend, mobile, barème, formule de scoring, Domain Event,
`pom.xml`, `pubspec.yaml`, module `identity`, `shared` ou `core` modifié. Vérifications admin : lint et
formatage Oxlint/Oxfmt, TypeScript et build Vite/SSR verts.

**Changelog (50) — 2026-08-30** : le control plane devient un **runtime administrable réellement
consommé**. Le contrat `v1.6.0` ajoute `GameRuntimeSnapshot` à chaque session : banque sélectionnée,
versions de `SETTINGS`/`MODIFIERS` et valeurs sont figées au démarrage (V67/V68), donc une publication
n'altère jamais une partie en cours. La rotation pondérée sélectionne les banques publiées ; Je Décide
sert la composition ordonnée de la banque de session et note aussi les questions administrées avec la
clé de correction conservée exclusivement côté serveur. Emotional Radar sert et note de la même façon
les scènes administrées ; V69 maintient l'intégrité des réponses vers catalogue système ou contenu
administré. La publication d'une banque valide structure, états et cardinalité (30 items Decision), et
les réponses ne peuvent viser qu'un item/scène réellement assigné à la session. Le mobile consomme les
contrôles Radar hors scoring (`sceneCount`, ordre stable, aide, reduced motion, feedback et transition).
Les payloads admin exposent aux seuls ADMIN toutes les données éditoriales nécessaires au clonage et à
la correction, sans jamais les envoyer au joueur. Les assets locaux publiés disposent désormais de
`GET /games/assets/{assetId}` ; brouillons et archives restent non livrables, et l'URL publique est
retournée après publication. La console permet de copier cette URL dans les contenus administrés ;
Flutter récupère les routes locales avec son client Dio authentifié puis affiche les PNG/SVG depuis
les octets hydratés, sans requête réseau anonyme. Smoke tests live : banque Decision v2 avec question gérée → 30 items,
soumission 200 et report serveur SCW ; banque Radar v2 avec scène gérée → réponse notée 200 ; snapshot
v1 préservé après publication v2 ; asset officiel Radar publié et livré en `image/png`. Compilation
Java 21 et génération OpenAPI vertes. Le câblage mobile Emotional Radar V2, resté incomplet, est aussi
rétabli : les repositories Dio/mock implémentent leur port dédié, le mock conserve l'horloge serveur,
l'adaptation et le report, et le drapeau de contenu sensible reste aligné avec Java ; `flutter analyze`
n'a plus aucune erreur Games (17 informations préexistantes hors périmètre subsistent) et les 40
tests Flutter ciblés Decision/Radar/session sont verts. **Aucun barème, formule de scoring,
Domain Event, `pom.xml`, `pubspec.yaml`, migration existante, module `identity`, `shared` ou `core`
modifié.**

**Changelog (49) — 2026-08-29** : la console Games passe du premier lot au **control plane complet**.
Le contrat `v1.5.0` couvre désormais la modification et suppression sûre des brouillons de questions,
le clonage, la publication et l'archivage ; les banques disposent du CRUD versionné, d'une composition
ordonnée par question, de poids de rotation, d'une publication atomique et d'un archivage ; les
configurations sont séparées en `SETTINGS` et `MODIFIERS`, versionnées par jeu/type et disposent du
cycle brouillon → publié → archivé ; les assets PNG/SVG ont métadonnées, publication, archivage et
suppression du brouillon avec purge du fichier Cloudinary ;
l'audit restitue les opérations réelles. V66 ajoute les contraintes d'unicité des publications sans
modifier une migration existante. Le front a été scindé en client API, modèles, pages, composants et
éditeurs ; toutes les pages consomment Spring, les questions sont filtrables et paginées, la composition
de banque permet ajout/retrait/réordonnancement, et chaque mutation possède états loading/error/empty,
confirmation destructive et feedback. Les 34 PNG/SVG Flutter sont servis localement par le web.
En profil `dev`, l'adaptateur média games utilise automatiquement un stockage local temporaire si les
identifiants Cloudinary sont absents ; l'upload, l'aperçu authentifié et la purge restent donc testables
dans Docker, tandis que tout autre profil continue d'exiger Cloudinary.
Vérifications : compilation Spring principale, génération OpenAPI, smoke API authentifié, lint/typecheck/
build SSR web et parcours Playwright desktop/mobile. **Aucun barème, service de scoring, Domain Event,
`pom.xml`, `pubspec.yaml`, module `identity`, `shared` ou `core` modifié.**

**Changelog (48) — 2026-08-28** : ajout de la **console web Games** dans `admin/`, scaffoldée avec
**create-better-t-stack** (TanStack Start, React, TypeScript, Tailwind, Turborepo/Bun) et inspirée de
`web-app-template`, tout en conservant Spring comme unique backend. Design aligné sur le langage
Flutter Zennyt (palette navy/magenta, rayons, contrôles 48–54 px, splash/login responsive), avec copies
web des PNG officiels, du logo splash et des 21 SVG de `J'investigue` — aucun asset mobile ni
`pubspec.yaml` modifié. API contract-first `v1.4.0` sous `/games/admin/**`, protégée par
`ROLE_ADMIN`; V65 ajoute brouillons éditoriaux, banques versionnées/clonables, poids de rotation,
configurations hors scoring, assets et audit immuable. Les catalogues Je Décide A et Emotional Radar
Core sont seedés comme versions publiées. Les publications restent atomiques et les sessions déjà
démarrées ne sont pas mutées. Le modèle rejette les clés de scoring, et l'upload historique Radar est
désormais ADMIN-only. Tests domaine ajoutés ; TypeScript et build web verts. **Aucun barème, service
de scoring, Domain Event, `pom.xml`, `pubspec.yaml`, module `identity`, `shared` ou `core` modifié.**

**Changelog (47) — 2026-08-17** : **« Je Décide » devient jouable end-to-end.** La banque du
psychologue (120 items, 24 par dimension II·ER·DT·CS·RE) passe de la ressource JSON à la **base**
(migration **V59**, seed généré depuis `resources/games/decision_scenarios.json` qui reste la source
tracée par Git). Trois tables : `decision_scenarios` (dont `pair_id`, `vignette_ref`,
`provisional_scoring` en **colonne**, pas en commentaire), `decision_scenario_options` (`quality`
seule clé de correction — le score /3 reste porté par `OptionQuality.points()`, une seconde source de
vérité ne pourrait que diverger) et `decision_form_items`. Colonne `decision_form_code` sur
**`game_sessions`** — et non sur l'attempt, qui n'est écrit qu'à la soumission alors que la forme doit
être connue pour servir les items.

**Passation = 30 items sur 120, via une forme parallèle.** La composition d'une forme est une
**donnée**, pas une règle positionnelle, pour trois raisons établies en lisant la banque :
(a) les paires CS (`CS-1a`/`CS-1b`) doivent rester groupées, ce qu'un découpage par modulo casserait ;
(b) `DT-k` **réutilise la vignette de `II-k`**, dont l'option OPTIMAL énonce la réponse en clair — les
mettre dans la même forme rendrait l'item chronométré trivial ; (c) ER-1..18, CS et RE sont en notation
neutre, donc un découpage contigu donnerait une seule forme où ER discrimine. **Forme A seule**
seedée : `II-1..6`, `ER-19..24` (les seuls ER réellement notés), `DT-7..12` (décalés, cf. (b)),
`CS-1a..3b` (3 paires complètes), `RE-1..6` → **18 des 30 items discriminent** au lieu de 12 avec un
découpage naïf. B/C/D sont **volontairement différées** : des formes équivalentes sont impossibles tant
que ER/CS/RE ne sont pas modélisées (λ, k, cohérence de paire). Le mécanisme est complet
(`DecisionConfig.assignFormCode()`, colonne, relecture à la notation) : les activer ne demandera qu'une
migration de données. La migration porte ses propres contrôles (`DO $$`) : 120 items, 24/dimension,
66 provisoires, ≥ 2 options, une OPTIMAL unique par item noté, paires complètes, forme A à 6 items par
dimension, aucune vignette partagée dans une même forme.

**Deux ports, pas un.** `DecisionScenarioCatalog` (notation : dimension, format, qualité par option)
est inchangé côté signature métier ; un port de lecture `DecisionFormCatalog` sert le contenu
(vignette **résolue**, consigne, énoncés d'options). Élargir le port de notation aurait fait entrer de
la présentation dans le chemin du barème. `DatabaseDecisionScenarioCatalog` implémente les deux ;
`JsonDecisionScenarioCatalog` est `@Deprecated`, retiré du contexte Spring, conservé une release.

**Endpoint** `GET /games/sessions/{id}/decision/items?language=` → 30 items **sans aucune clé de
correction**. Le use case renvoie les items complets, le DTO les projette : point de filtrage unique,
même patron que `GetEmotionalRadarScenesUseCase`. `timeLimitMs` (items DT) = base × multiplicateur de
langue, **sans** `calibrationOffsetMs` — celui-ci se déduit de la télémétrie appareil, que le serveur ne
reçoit qu'à la soumission ; le seuil de notation est donc très légèrement plus permissif que le
chronomètre affiché, toujours en faveur du candidat. À la soumission, `SubmitGameResultUseCase` relit
la forme **sur la session** et rejette tout item étranger : sans ce contrôle, un client pourrait ne
renvoyer que des items d'une dimension où il réussit. `formCode` existe au contrat en `readOnly` :
écho de diagnostic, jamais une entrée. Le report expose `provisionalScoring` **par dimension** (une
dimension n'est déclarée neutre que si TOUS ses items le sont) et le breakdown l'affiche.

**Mobile — le contenu ne vit plus dans l'app.** Les 6 scénarios anglais codés en dur et
`DecisionProfilePreview` (score constant 82) ont disparu. `DecisionGameplayView` est piloté par les 30
items servis, avec écrans de transition aux frontières de dimension uniquement — jamais entre les deux
cadrages d'une paire. `responseTimeMs` est mesuré **à la validation** via `package:clock` (et non avec
un `Stopwatch`, non testable) : choisir vite puis délibérer produit un temps long, l'exploit est fermé.
Le changement d'avis est rouvert et **compté** (`decisionChangesCount`), conformément au contrat. La
pause gèle le compte à rebours, son auto-avance et le chronomètre de délibération. Le profil final vient
de la réponse serveur (SCW, niveau, /18 par dimension) ; l'étape « strengths » et ses textes inventés
sont supprimées.

⚠️ **Exception de parité assumée, écrite en tête de `games_mock_repository.dart`** : « Je Décide » est le
**seul** jeu du module sans barème miroir côté mock. Noter un item suppose la qualité de chaque option,
c'est-à-dire la clé de correction des 120 items — l'embarquer la rendrait extractible et ruinerait le
test en recrutement. Hors ligne, `decisionItems` échoue explicitement et la soumission renvoie un
attempt **non scoré**. `decision_scoring.dart` reste au dépôt comme miroir documentaire du barème
serveur, couvert par son test, branché sur aucun chemin d'exécution. Ce n'est pas une régression : c'est
le seul comportement compatible avec « les scores ne quittent jamais le serveur ».

**Tests** : `DecisionItemsProjectionTest` échoue si une `OptionQuality` apparaît dans le JSON
**réellement sérialisé** (pas seulement dans les champs du DTO) ; `DecisionSeedParityTest` compare le
seed SQL à la banque JSON item par item et option par option — si les qualités sont identiques, aucun
score ne peut changer ; `GameSessionTest` couvre l'assignation de forme. Backend **484 tests verts**,
mobile **149 verts**, migration validée sur Postgres 16 (62 migrations rejouées à blanc).
**Reste** : modèles λ (ER) / k (RE) / cohérence de paire (CS), puis activation des formes B/C/D.

**Changelog (46) — 2026-08-12** : intégration **front-only** de **Strategic Choices** dans le
sélecteur `Emotional Regulation`, sans vidéo pour cette phase. Deux logos PNG RGBA 512×512 ont été
reconstruits proprement dans la charte : variante transparente pour le hub/picker et variante
violette dans le jeu. Le parcours Flutter couvre cover, intro, tutoriel, les 10 situations textuelles
du handoff, réflexion obligatoire de 3 s, choix unique parmi 8 stratégies, transition neutre,
résultats et insights explicitement non scorés. Le menu partagé gèle le timer et propose reprise,
règles/aide ou sortie, sans restart. Route `/games/strategic-choices` ajoutée avec autorisation
explicite de modifier les deux fichiers de routage `core`. Aucun contrat, backend, `GameType`,
`MiniGame`, session, Attempt, event, Fit Score, `pom.xml` ou `pubspec.yaml` modifié. Les médias,
captions/transcriptions et règles de score/normalisation restent tracés comme bloquants. Validation
mobile : **147 tests verts**, analyse ciblée sans issue ; l'analyse globale ne contient que les
**17 infos préexistantes** hors de ce changement. Les harnesses Reflective Pause/Je continue
neutralisent désormais explicitement l'utilisateur courant afin de ne pas démarrer le timeout
d'authentification pendant les tests.

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

**Changelog (56)** — 2026-09-10 : nettoyage du dépôt (aucun code, barème, contrat ni event touché).
Suppression des exports Figma à la racine (`04 Move Fast/`, `04 Emotional Radar/`, `test/`,
`test 2/`, captures `Progress Careers - tablet*`), des plans/recaps obsolètes, de `mobile_preview/`,
des artefacts locaux (`output/`, `.playwright-cli/`, `backend-logs.txt`, `tmp/`) et des explorations
d'assets non intégrées (`assets/04 Je Continue Logo Options/`, `assets/04 Je Décide 2/`,
`assets/04 Je Décide 3/`, `assets/Emotional Radar/`, `assets/04 Reflective Pause/`,
`assets/J’investigue/J’investigue/`, 6 icônes de jeu inutilisées). `mobile/pubspec.yaml` inchangé
(aucun asset encore déclaré n'a été retiré). `.gitignore` mis à jour. Zones protégées inchangées.

**Changelog (57)** — 2026-09-10 : fusion de `origin/main` dans la branche Games (merge, aucun
barème/contrat/event modifié). Les migrations `games` uniques à la branche sont **renumérotées
au-dessus de la dernière migration de `main` (V66)** pour supprimer la collision de versions :
`V59 decision`→`V67`, `V64 emotional_radar_v2`→`V68`, `V65 admin_console`→`V69`,
`V66 admin_full_control`→`V70`, `V67`→`V71`, `V68`→`V72`, `V69`→`V73`, `V70`→`V74`, `V71`→`V75`.
Les migrations continues/visuo/object-location communes à `main` y restent à `V61/V62/V63` (les
doublons de la branche sont supprimés). Côté mobile, les fichiers UI en conflit (thème, écrans
auth, navigation) adoptent la **design system de `main`** ; le correctif anti-overflow
`Row`→`Wrap` de l'écran d'inscription est conservé.

**Changelog (58)** — 2026-09-11 : création d'un concept de logo original pour **Memory Quest
Image**, après analyse des autres logos Games et du contexte du mini-jeu. Le symbole associe une
chambre de mémoire, trois cartes-images et un ruban de rappel dans la charte Zennyt flat 2.5D.
Export PNG RGBA 1254×1254 à fond réellement transparent, non intégré au hub ; les logos existants
Memory Quest Image/Digits ont été explicitement exclus des références. Aucun code, barème,
contrat, endpoint, event, `pom.xml` ou `pubspec.yaml` modifié. Zones protégées inchangées.

**Changelog (59)** — 2026-09-11 : seconde piste de logo **Memory Quest Image**, volontairement
différente de la première : emblème minimal à prisme ouvert, formes visuelles dispersées puis
réordonnées, sans boîte, cartes, ruban orbital ni perspective 2.5D. Export PNG RGBA 1254×1254 à
fond transparent, conservé comme concept non intégré. Aucun code, barème, contrat, endpoint,
event, `pom.xml` ou `pubspec.yaml` modifié. Zones protégées inchangées.

**Changelog (60)** — 2026-09-11 : troisième piste de logo **Memory Quest Image**, recentrée sur
la mécanique de mémorisation d'objets : pomme, clé et tasse occupent trois emplacements ; la clé
et ses échos de mouvement matérialisent le changement d'ordre puis le retour à la position
initiale. Aucun langage visuel de quiz (question, choix, coche ou score). Export PNG 1254×1254 sur
fond lavande, concept non intégré. Aucun code, barème, contrat, endpoint, event, `pom.xml` ou
`pubspec.yaml` modifié. Zones protégées inchangées.

**Changelog (61)** — 2026-09-11 : Day Stack passe à une liste unique de toutes les
tâches mélangées et cartes pleine largeur numérotées, directement déplaçables par
appui maintenu. La poignée à trois points est supprimée sur demande utilisateur.
La carte conserve ses coins arrondis lorsqu’elle est soulevée et déplacée.
Défilement naturel sur les cartes, auto-scroll aux bords, bouton « Valider » fixe et
protégé pendant le dépôt ; annulation de drag et consultation des règles préservent
l’ordre. Déplacements comptés sans pénalité sur accord utilisateur, aucune alerte avant
validation ; mesures figées à la validation et soumission dès la dernière validation.
Le tutoriel est harmonisé en français et explique les contrôles, « Après : X », les
fenêtres/échéances/ancrages horaires, les quatre manches et l’évaluation à la validation.
Tests widget adaptés au geste sur toute la carte, à l’annulation, aux petits écrans et au
texte 200 %.
Validation : **75 tests Flutter ciblés verts**, analyse des deux fichiers Dart modifiés
sans diagnostic ; captures vérifiées à 320×568, 390×844 (texte 200 %) et 1024×768.
Le geste d’appui maintenu sur la carte est couvert par un test widget ; l’écran est aussi
contrôlé visuellement dans le simulateur iOS 26.1.
Analyse globale : 73 diagnostics hors de ces fichiers. Backend/ArchUnit tentés sous
Java 21, bloqués avant exécution par les tests Recruitment (`saveIfNotOlder` /
`upsertIfNotOlder` absents) ; aucun correctif hors périmètre.
Aucun backend, contrat, asset, dépendance, core/shared ou barème protégé modifié.

**Changelog (62)** — 2026-09-12 : audit et correction du tutoriel Day Stack contre
la banque et le moteur réels. L’introduction et les règles sont harmonisées en français ;
elles expliquent l’appui maintenu, le défilement, « Après : X », les fenêtres, échéances
et ancrages horaires, les **4 manches**, l’absence de pénalité sur les glissements et
l’évaluation à « Valider ». Une incohérence d’implémentation est corrigée : reprendre une
carte déjà déplacée ne renseigne plus `proactiveAdjustments`, conformément à la décision
utilisateur ; le barème serveur/mock reste inchangé. Test widget du tutoriel et du payload
sans corrections ajouté, inclus dans **75 tests Flutter ciblés verts** ; analyse ciblée sans
diagnostic. Aucun backend, contrat, asset, dépendance, core/shared ou barème protégé modifié.

**Changelog (63)** — 2026-09-12 : audit des tutoriels des trois jeux
d’intelligence émotionnelle contre leurs mécaniques, banques et configurations. Emotional Radar
annonce désormais les 15 scènes, le budget de 30 s couvrant visionnage + réponse, les 6/9 émotions,
les trois intensités et la conduite à tenir après expiration. Reflective Pause décrit l’ordre réel
lecture → attente du délai publié → choix → validation sur 10 moments, sans promettre à tort un
délai fixe dans l’aide. Strategic Choices précise les 10 situations, les 8 stratégies, le choix
possible pendant la réflexion de 3 s, la validation débloquée à sa fin et le score serveur
provisoire. Les tests widget couvrent ces consignes. Aucun mécanisme, backend, contrat, asset,
dépendance, core/shared ou barème protégé modifié.

**Changelog (64)** — 2026-09-12 : quatrième piste de logo **Memory Quest Image**, construite
autour des objets modernes du catalogue réel : téléphone, appareil photo, sac à dos et lampe au
centre, encerclés par deux flèches de mémorisation/rappel et accompagnés de silhouettes d'écho.
Export PNG RGBA 1254×1254 à fond transparent, conservé comme concept non intégré. Aucun code,
barème, contrat, endpoint, event, `pom.xml` ou `pubspec.yaml` modifié. Zones protégées inchangées.

**Changelog (65)** — 2026-09-12 : cinquième piste de logo **Memory Quest Image**, avec une
interprétation plus contemporaine des objets du jeu : smartphone sans bordures, caméra hybride à
grand objectif, casque audio sans fil et lampe LED articulée au centre de la double flèche de
mémorisation. Composition simplifiée et export PNG RGBA 1254×1254 à fond transparent, concept non
intégré. Aucun code, barème, contrat, endpoint, event, `pom.xml` ou `pubspec.yaml` modifié. Zones
protégées inchangées.

**Changelog (66)** — 2026-09-12 : sixième piste de logo **Memory Quest Image**, dans un style
géométrique distinct. Les cinq formes réellement présentes dans les quiz — cercle, triangle, carré
arrondi, étoile et hexagone — encadrent trois objets modernes à mémoriser : smartphone, caméra
hybride et casque audio sans fil. Export PNG RGB 1254×1254 sur fond bleu nuit, conservé comme
concept non intégré. Aucun code, barème, contrat, endpoint, event, `pom.xml` ou `pubspec.yaml`
modifié. Zones protégées inchangées.

**Changelog (67)** — 2026-09-12 : correction reproductible des supports de **Strategic Choices**.
Les situations `CS-102`, `CS-104`, `CS-108`, `CS-112`, `CS-115` et `CS-116` sont des messages
écrits avec leur texte littéral ; les 74 autres restent vidéo. La source Python, l'export JSON, la
fusion idempotente, les banques mobile/backend et le PDF de relecture conservent désormais le
champ `message`. Le parseur rejette un écrit vide ou une vidéo portant un message, et un test widget
déterministe vérifie la bulle écrite sans placeholder vidéo. La documentation et les commentaires
obsolètes ont été alignés sur l'implémentation end-to-end existante. Validation : **23 tests Flutter
ciblés verts**, analyse ciblée sans diagnostic, banques identiques et PDF de 13 pages contrôlé ; le
test Java ciblé ne démarre pas localement car seul Java 17 est installé alors que le projet exige
Java 21. Aucun contrat, dépendance, barème, migration existante, module `shared`/`core` ni autre
bounded context modifié. Zones protégées inchangées.

**Changelog (68)** — 2026-09-16 : investigation du retour arrière de « Je Décide ».
Désynchronisation page/indicateur/bouton reproduite au retour de la carte joueur vers l'onboarding,
et absence d'interception du retour système confirmée pendant le gameplay. Capture utilisateur
indisponible ; identification du cas signalé et comportement attendu en item chronométré ouverts.
Deux tests de diagnostic temporaires exposent les défauts puis sont retirés ; les **25 tests Flutter
existants ciblés sont verts**. Seule cette documentation est modifiée par l'investigation ; aucun
correctif, décision produit, contrat, backend, dépendance, core/shared ou barème protégé touché.

**Changelog (69)** — 2026-09-16 : refonte visuelle du calendrier Day Stack sur demande
utilisateur : fond et cartes mauves, textes blancs, badges existants, heures dans
une seule colonne et défilement visible. Contraintes/dépendances restent affichées,
réordonnancement et validation conservés. Tests de défilement adaptés et capture
`test/features/games/presentation/goldens/day-stack-calendar-purple.png` ajoutée.
Validation : **25 tests Flutter ciblés verts**, analyse ciblée sans diagnostic ;
petit écran, texte 200 %, drag, auto-scroll et payload couverts. Backend/ArchUnit
non relancés pour ce changement de présentation. Aucun contrat, score, dépendance,
migration, core/shared ou zone protégée modifié. Référence Outlook et adaptation
au mauve explicitement demandées ; aucune décision métier supplémentaire.

**Changelog (70)** — 2026-09-16 : Day Stack — retrait du texte « déplacements sans
pénalité » et du compteur UI inutilisé ; bouton partagé Valider centré (largeur
maximale 280 px), zone séparée du calendrier par un trait discret, découpage explicite
du viewport et marge de fin de liste. Tests de visibilité complète de la dernière
tâche à 320×568, 390×844 et texte 200 %, capture de fin de calendrier ajoutée.
Validation : **28 tests Flutter ciblés verts**, analyse des trois fichiers Dart sans
diagnostic. Aucun backend/contrat, scoring, dépendance, migration, core/shared ou
zone protégée modifié ; pas de nouvelle décision métier. Backend/ArchUnit non relancés.

**Changelog (71)** — 2026-09-16 : Day Stack — ajout d'une mission courte et permanente
sous la manche, contextualisée pour chacun des sept univers et précisant le geste
ainsi que le respect des horaires/étapes. Texte blanc adaptable, calendrier et
validation accessibles. Test des sept missions et captures de calendrier actualisés.
Validation : **29 tests Flutter ciblés verts**, analyse ciblée des deux fichiers Dart
sans diagnostic ; petits écrans, texte 200 %, dernière tâche, drag et payload couverts.
Fichiers modifiés : écran Day Stack, son test, deux captures golden et cette documentation.
Aucun fichier créé, backend/contrat/API, scoring, dépendance, migration, core/shared
ou zone protégée modifié ; aucune décision métier ajoutée. Backend/ArchUnit non relancés.

**Changelog (72)** — 2026-09-16 : Day Stack — mission verte et clignotement unique
initial identique à Memory Quest Image/Digits (460 ms), puis texte stable.
Extraction sans duplication de `MemoryPrompt` vers un widget Games partagé ;
style/alignement optionnels, valeurs par défaut et réexport Memory Quest conservés.
Test Day Stack adapté pour vérifier couleur et absence de relance au défilement ;
captures actualisées. Validation : **48 tests Flutter ciblés verts** (Day Stack et
Memory Quest, dont clignotement unique/changement de consigne/reduced-motion),
analyse des quatre fichiers Dart sans diagnostic. Nouveau fichier : widget partagé ;
fichiers modifiés : écrans Day Stack/Memory Quest, test Day Stack, deux captures,
cette documentation. Aucun backend/contrat, barème, dépendance, migration,
core/shared ou zone protégée modifié ; aucune décision métier supplémentaire.
Backend/ArchUnit non relancés pour cette présentation.

**Changelog (73)** — 2026-09-16 : Day Stack — correction de la disparition des
repères horaires pendant le déplacement. Le proxy ne contient que le rendez-vous,
sans la plage d’attente qui le précède ; grille et source atténuée restent en place
jusqu’au dépôt. Heure de début après attente rétablie (ex. 18h00).
Défilement automatique aux bords et annulation conservés.
Test de régression sur « Accueillir les invités » à 18 h avec une longue attente,
capture pendant le drag ajoutée, ordres de tests de glissement rendus déterministes.
Validation : **49 tests Flutter ciblés verts** (30 Day Stack, 19 Memory Quest),
analyse ciblée sans diagnostic ; captures vérifiées. Fichiers mobiles : calendrier,
test Day Stack, captures golden ; documentation mise à jour. Backend/ArchUnit non
relancés ; aucun backend/contrat/API, scoring, dépendance, migration, core/shared
ou zone protégée touché. Aucune décision produit supplémentaire ni point ouvert
pour cette correction.

**Changelog (74)** — 2026-09-17 : génération demandée des **82 emotes Day Stack**,
une par tâche dans les sept univers, avec l’outil intégré image_gen. PNG à fond
transparent, objets arrondis en 2.5D et palette Zennyt ; signes d’action propres à
chaque tâche. Galerie locale recherchable avec trois fonds, sept planches par
univers et un aperçu général, manifeste avec prompts exacts/variantes, README et
rapport technique ajoutés dans `mobile/assets/Day Stack/emotes-v1/`.
Validation : **82/82 fichiers valides et transparents**, aucune image dupliquée,
82 clés univers/tâche exhaustives et **328 variantes** correctement associées ;
relecture visuelle des sept séries. Deux erreurs de connexion récupérées par
relance du même outil, aucun CLI/API utilisé. Choix visuels provisoires tracés en
décision 61. Aucun code Flutter/backend, contrat/API, score, dépendance,
`pubspec.yaml`, `pom.xml`, migration ou core/shared modifié. Tests Flutter/backend
et ArchUnit non relancés pour cette création d’assets ; zones protégées intactes.
Point ouvert : collection à valider visuellement puis à intégrer, avec autorisation
explicite requise pour sa déclaration dans `pubspec.yaml`.

**Changelog (75)** — 2026-09-17 : intégration des **82 emotes Day Stack** dans les
cartes du calendrier (plan 001). Nouveau `day_stack_emotes.dart` (chemin par couple
univers/tâche, tailles, `cacheWidth`) ; `DayStackTaskBadge` accepte `universeId` /
`taskId` optionnels, anciens appels inchangés ; le calendrier transmet l’univers à
la carte, à la source atténuée et au proxy de glissement. Repli sur l’icône
historique sans identité ou si le PNG ne charge pas, sans saut de mise en page.
Annonce de la catégorie en double au lecteur d’écran supprimée (enveloppe
`Semantics` redondante du calendrier). **`pubspec.yaml` : sept dossiers d’univers
déclarés avec autorisation explicite**, aucune dépendance ni version modifiée,
`pubspec.lock` inchangé. Tests : repli, décodage, clé composite, 82 PNG chargés
depuis le bundle, même emote sur carte, source et proxy, après réorganisation et
changement de variante ; canaux audio neutralisés dans le test d’écran (même
méthode que `feedback_screenshots_test.dart`). Trois captures Day Stack régénérées
et relues. Validation : **85 tests Day Stack ciblés verts** (73 avant, 12 ajoutés) ;
suite mobile complète **549 verts, 5 échecs préexistants** Move Fast / capture
« Je bouge » ; `flutter analyze` sans erreur, 15 avertissements et 58 infos hors
Day Stack, préexistants. Backend/ArchUnit non relancés : aucun backend, contrat/API,
score, migration, `pom.xml` ou core/shared modifié ; zones protégées intactes.
Point ouvert : taille 32 px et rendu à valider sur appareil (décision 62).

**Changelog (76)** — 2026-09-17 : refonte du tutoriel **Day Stack** en six cartes
illustrées successives, avec textes courts et schémas construits à partir des emotes déjà
intégrées. Nouveau composant Games `GameTutorialDeck` et contenu `DayStackTutorial` ;
balayage, précédent/suivant, repère d’étape, bouton final et reprise depuis l’aide.
`DayStackTaskBadge` reçoit une taille d’emote optionnelle pour les exemples, valeurs du
calendrier préservées. Défilement interne des cartes pour garder le texte agrandi lisible
et les commandes accessibles ; animations désactivables et descriptions sémantiques.
Six captures ajoutées et relues avec PNG effectivement décodés. Sept nouveaux tests ;
contrôles du tutoriel et de la reprise actualisés. Le test de drag des emotes vise désormais
la carte déplaçable, au lieu du centre d’une ligne pouvant contenir une longue attente :
son échec aléatoire avait été observé avant la refonte. **92 tests Flutter ciblés verts**,
analyse des six fichiers Dart touchés sans diagnostic. Décision de présentation 63 tracée.
Aucun backend, contrat/API, barème, métrique, migration, asset original, `pubspec.yaml`,
`pom.xml` ou core/shared modifié par cette tâche ; backend/ArchUnit et suite mobile globale
non relancés. Zones protégées intactes. Autres tutoriels à convertir dans une étape suivante.

**Changelog (77)** — 2026-09-17 : deuxième présentation du tutoriel **Day Stack**
après refus de la première. Fond mauve en dégradé plein écran, cartes claires centrées
et plus compactes, zone illustrée distincte et texte centré. Grandes emotes existantes,
scènes simplifiées et mini-démo de livraison déplaçable au doigt, avec toucher simple
et action sémantique alternatifs ; aucun effet sur la partie ni session démarrée.
Dégradé commun réutilisé pour les marges système/tablette et icônes système claires
pendant le tutoriel. Six captures mises à jour et relues, test du déplacement de démo
ajouté. Validation : **93 tests Flutter ciblés verts**, analyse ciblée sans diagnostic.
Décision de présentation 64 tracée. Aucun nouvel asset, backend, contrat/API, barème,
métrique, dépendance, `pubspec.yaml`, `pom.xml`, migration ou core/shared touché ;
backend/ArchUnit et suite mobile globale non relancés. Zones protégées intactes.
Point ouvert : nouvelle présentation à valider par l’utilisateur sur appareil.

**Changelog (78)** — 2026-09-17 : Day Stack — rétablissement demandé du **fond
habituel blanc des tutoriels Planifik**, après amélioration des cartes jugée meilleure.
Dégradé extérieur retiré ; cartes illustrées compactes conservées au milieu. Titres et
navigation bleu marine, progression magenta, icônes système foncées et contour discret
pour conserver la séparation sur fond clair. Aucun changement de contenu, geste de démo,
mesure ou navigation. Six captures actualisées, aperçu relu. Validation : **41 tests
Flutter de présentation ciblés verts**, analyse des deux fichiers Dart modifiés sans
diagnostic. Documentation courante et décision 64 précisées ; aucun nouveau fichier
source ni décision produit autonome. Backend/contrat/API, barèmes, dépendances,
`pubspec.yaml`, `pom.xml`, core/shared et zones protégées inchangés ; backend/ArchUnit
et suite mobile globale non relancés. Point ouvert : contrôle visuel sur appareil.

**Changelog (79)** — 2026-09-17 : **Radar émotionnel V2** — tutoriel et aide convertis
aux cartes illustrées centrées sur le fond blanc habituel, en réutilisant `GameTutorialDeck`.
Cinq nouvelles illustrations générées avec `image_gen.imagegen` et contrôlées : observation,
choix d’émotion, trois intensités, chronomètre commun, validation des deux réponses.
PNG transparents copiés dans le dossier `games icons` déjà déclaré ; prompts et provenance
archivés. Textes français courts, valeurs dérivées de la configuration V2, pas de nuance
ni justification écrite, aucun score normatif promis en phase A. Aide plein écran avec
retour au menu pause et choix conservés. Anciens widgets locaux de tutoriel retirés,
aucun changement du gameplay. Cinq tests ajoutés, navigation des tests existants adaptée
et cinq captures relues avec images effectivement décodées. Validation : **38 tests Flutter
ciblés distincts verts** (tutoriel, écran, pile partagée et lecteur vidéo) ; analyse ciblée des quatre fichiers Dart sans diagnostic. Décision 65 tracée.
Aucun backend, contrat/API, barème, métrique, migration, dépendance, `pubspec.yaml`,
`pom.xml` ou core/shared modifié ; backend/ArchUnit et suite mobile globale non relancés.
Zones protégées intactes. Point ouvert : contrôle visuel sur appareil.

**Changelog (80)** — 2026-09-17 : **Reflective Pause** — tutoriel et aide convertis
en cinq cartes illustrées centrées sur le fond blanc habituel avec `GameTutorialDeck`.
Cinq PNG pédagogiques transparents générés avec `image_gen.imagegen`, intégrés dans
`games icons` déjà déclaré ; prompts et provenance archivés. Textes français courts :
support écrit/vidéo, réflexion et déverrouillage, choix naturel parmi cinq propositions,
sauvegarde, bilan après dix situations ; durée fixe évitée pour respecter les sessions
administrées, temps conseillé distingué du verrouillage. Aide plein écran avec retour
au menu pause, sélection et moment conservés. Introduction et gameplay préservés ;
paramètre de note de bas de page devenu inutilisé retiré du widget local d’information.
Cinq tests ajoutés, navigation des tests existants adaptée ; absence de session pendant
les cartes vérifiée. Cinq captures contrôlées avec images effectivement décodées.
Validation : **20 tests Flutter ciblés distincts verts**, analyse ciblée des quatre
fichiers Dart sans diagnostic ; comparaison des cinq captures sans régénération verte.
Décision 66 tracée. Aucun backend, contrat/API, score, métrique, migration, dépendance,
`pubspec.yaml`, `pom.xml` ou core/shared modifié ; backend/ArchUnit et suite mobile
complète non relancés. Zones protégées intactes. Point ouvert : rendu sur appareil.

**Changelog (81)** — 2026-09-17 : **Choix stratégiques** — tutoriel et aide convertis
aux cinq cartes illustrées centrées sur le fond blanc habituel, avec `GameTutorialDeck`.
Cinq PNG pédagogiques générés avec `image_gen.imagegen`, copiés dans `games icons`
déjà déclaré ; prompts et provenance archivés. Textes français courts suivant le
parcours réel : lecture, lancement manuel de la réflexion, choix parmi huit stratégies
possible pendant le délai, validation à la fin, score provisoire et tendances après
dix situations. Aide plein écran avec retour au menu pause, sélection conservée et
réflexion gelée. Ancienne grille et widgets locaux de tutoriel/règles retirés, introduction,
gameplay et observations préservés. Cinq tests ajoutés et navigation existante adaptée ;
cinq captures relues avec images réellement décodées. **21 tests Flutter ciblés verts**,
comparaison des captures sans régénération verte et analyse des quatre fichiers Dart
sans diagnostic. Décision 67 tracée. Aucun backend,
contrat/API, score, métrique, migration, dépendance, `pubspec.yaml`, `pom.xml` ou core/shared
modifié ; backend/ArchUnit et suite mobile globale non relancés. Zones protégées intactes.
Point ouvert : rendu sur appareil à valider.

**Changelog (82)** — 2026-09-17 : **Je Décide** — tutoriel et aide convertis à six
cartes illustrées centrées sur fond blanc avec `GameTutorialDeck`. Six PNG générés
avec `image_gen.imagegen`, copiés sans modification dans `games icons` déjà déclaré ;
prompts et provenance archivés. Ancien bloc de tutoriel et lignes de règles remplacés ;
accueil, onboarding, avatars, exemple et passation conservés. Textes suivant le parcours
réel, aide plein écran avec retour au menu pause existant, choix et chrono préservés.
Cinq tests ajoutés, navigation existante adaptée et six captures relues avec images
réellement décodées. **53 tests Flutter ciblés verts**, analyse des six fichiers Dart
sans diagnostic ; comparaison des captures sans régénération vérifiée séparément.
Décision 68 tracée. Aucun backend, contrat/API, score, métrique, migration, dépendance,
`pubspec.yaml`, `pom.xml` ou core/shared modifié. Backend/ArchUnit et suite mobile globale
non relancés. Zones protégées intactes. Point ouvert : rendu sur appareil à valider.

**Changelog (83)** — 2026-09-17 : **Memory Quest Digits et Image** — logique et
règles vérifiées avant refonte, deux parcours en six cartes centrées sur fond blanc
avec `GameTutorialDeck` ; mode historique conservé avec dix cartes adaptées.
Douze nouvelles illustrations générées avec `image_gen.imagegen`, distinctes des
objets et distracteurs de partie, copiées dans le dossier déjà déclaré. Prompts,
originaux et direction provisoire archivés (décision 69). Ancien tutoriel textuel
et lignes d’aide remplacés par le contenu propre au mode ; mécanisme de pause
existant conservé. Neuf tests du tutoriel et quatre tests de parcours/aide ajoutés,
douze captures avec images décodées relues. **84 tests Flutter ciblés verts**, plus
deux captures existantes de restitution ; comparaison des nouveaux goldens sans
régénération et analyse ciblée sans diagnostic. **18 tests de scoring Java verts
en exécution isolée** ; Maven standard bloqué par des tests Recruitment préexistants.
Audit : soumission Image en `FULL` et chrono non gelé sous pause reproduits,
autres écarts de métriques/budgets consignés ; corrections ouvertes, pas de modification
silencieuse de règles. Aucun backend, contrat/API, score, métrique de partie, migration,
dépendance, `pubspec.yaml`, `pom.xml` ou core/shared modifié. Suites globales et ArchUnit
non vérifiés. Zones protégées intactes. Rendu sur appareil à valider.

**Changelog (84)** — 2026-09-17 : **Predictive Puzzle** — les deux fenêtres de
règles deviennent deux cartes centrées sur fond blanc avec `GameTutorialDeck`.
Le PNG Figma de 297 × 135 pixels, conservé sur disque, n’est plus agrandi dans
le tutoriel ; `_Disc` et `_TowerView` servent aux schémas natifs autorisé/interdit.
La seconde illustration distingue le plan à compléter et l’exécution automatique.
Textes courts en français, libellés `Add Move` et `Run Plan` identiques aux boutons
de partie. Aucun changement de règle, progression, score ou mécanisme de pause.
Quatre tests ajoutés, deux captures relues ; **13 tests Flutter ciblés verts**
(tutoriel, deck partagé, barème mock), comparaison des captures sans régénération
et analyse ciblée sans diagnostic. Décision visuelle provisoire 70 tracée.
Backend et suites globales non exécutés (aucun changement serveur).
Aucun contrat/API, backend, migration, dépendance, `pubspec.yaml`, `pom.xml`
ou core/shared modifié ; zones protégées intactes. Rendu sur appareil à valider.

**Changelog (85)** — 2026-09-17 : **Optimal Path** — légère amélioration des
deux pages de règles existantes avec `GameTutorialDeck` : cartes centrées sur
fond blanc et textes courts en français. Style de stations rondes conservé ;
`_StationsArt` trace désormais un chemin horizontal/vertical, avec palette
`BoardPalette` et libellés LAB/MTG plus lisibles. La deuxième carte reprend les
quatre critères du score existant, présentés comme maxima par niveau. Bouton
« Commencer le parcours » à la dernière carte. Quatre tests du tutoriel et deux
captures ajoutés ; parcours de `planifik_attempts_test.dart` adapté aux nouveaux
boutons, assertions de limite d’essais inchangées. **23 tests Flutter ciblés verts**
(tutoriel, deck partagé, essais/scoring mock et tracé tap/drag), comparaison des
captures sans régénération et analyse ciblée sans diagnostic. Décision visuelle
provisoire 71 tracée ; rendu sur appareil à valider. Gameplay, aide de pause,
progression, score, backend, contrat/API, migrations, dépendances, `pubspec.yaml`,
`pom.xml` et core/shared inchangés. Zones protégées intactes. Suites globales,
backend et ArchUnit non exécutés (aucun changement serveur).

**Changelog (86)** — 2026-09-17 : **Choix stratégique, Reflective Pause et
Radar émotionnel** — icônes des huit stratégies visibles dans les états actif,
verrouillé et sélectionné ; cadenas/coche deviennent des badges d’état séparés.
Fuite et action directe ont des pictogrammes plus adaptés. Profil Reflective en
jauges normalisées sur les maxima de configuration 3/4/3, avec points du rapport
et compte de choix impulsifs ; absence d’indicateurs sans faux point fort.
Radar restitue les comptes serveur sous-estimée/correcte/surestimée en barres dans
la synthèse des résultats, titre adapté, statistiques et mentions provisoires conservées.
`GameResultInsightMeter` réutilise la jauge compacte existante et ajoute une variante
pleine largeur ; le titre de synthèse reste inchangé par défaut pour les autres jeux.
Huit nouveaux tests et trois captures relues ; **64 tests Flutter ciblés verts**
(les trois parcours, les nouvelles visualisations et le modèle de résultats commun),
comparaison des captures sans régénération et analyse ciblée sans diagnostic.
Décision visuelle provisoire 72 tracée ; rendu sur appareil à valider. Aucune règle,
interprétation métier, cotation, métrique envoyée, pause, backend, contrat/API,
migration, dépendance, `pubspec.yaml`, `pom.xml` ou core/shared modifié. Zones protégées
intactes. Suites globales, backend et ArchUnit non exécutés (aucun changement serveur).

**Changelog (87)** — 2026-09-17 : **Je Décide** — entrée raccourcie à une
page d’accueil avec logo officiel, objectif court, durée et 30 questions ; trois cartes
(lire/choisir, scénario lié, chronomètre), puis un seul exemple. Les trois anciennes
pages d’onboarding et le panneau répétitif sont retirés ; pseudo/thème/avatar restent
accessibles par « Personnaliser (facultatif) ». Retours à l’accueil et maintien des
choix de personnalisation vérifiés. Mention `Practice 1/2` remplacée par un exemple
sans compteur fictif. Bilan/provisoires annoncés à l’accueil, conservés aux résultats.
Titre adaptable au texte agrandi ; accueil défilable et règles accessibles à 200 %.
Trois illustrations existantes et boutons communs réutilisés ; sources historiques
conservées. Quatre captures relues, dont une nouvelle d’accueil ; trois captures
obsolètes retirées. **57 tests Flutter ciblés verts**, comparaison des captures sans
régénération et analyse des cinq fichiers Dart concernés sans diagnostic. Parcours
complet de 30 réponses, aide/pause, choix et chrono vérifiés. Décision 73 tracée ;
rendu sur appareil à valider. Aucun backend, contrat/API, barème, métrique, délai,
protocole de pause, migration, dépendance, `pubspec.yaml`, `pom.xml`, core/shared ou
module tiers modifié. Zones protégées intactes ; suites globales, backend et ArchUnit
non exécutés (aucun changement serveur).

**Changelog (88)** — 2026-09-17 : **Je Décide** — amélioration de la
présentation et de l’animation entre accueil et règles, à la demande de l’utilisateur.
En-tête, retour, menu et barre basse conservés à leur place ; « Comment jouer » porté
par l’en-tête du jeu, sans doublon. Variante optionnelle `showHeader` du composant
Games `GameTutorialDeck`, active par défaut pour tous les autres usages. Fondu et
léger glissement à l’entrée/retour, mouvement réduit sans animation ; contenus
sortants inactifs et exclus des annonces. Fond blanc, logo et trois illustrations
existantes conservés. Deux tests ajoutés, petit écran à 200 % parcourant les trois
cartes et nouvelle capture d’entrée relue. **59 tests Flutter ciblés verts**, captures
comparées sans régénération, analyse des quatre fichiers Dart concernés sans diagnostic.
Décision visuelle provisoire 74 tracée ; rendu et animation sur appareil à valider.
Aucune modification de passation, scoring, métrique, délai réel, pause, backend,
contrat/API, migration, dépendance, `pubspec.yaml`, `pom.xml`, core/shared ou module
tiers. Zones protégées intactes ; suites globales, backend et ArchUnit non exécutés.

**Changelog (89)** — 2026-09-17 : **Je Décide** — suppression entière de la
personnalisation à la demande de l’utilisateur : bouton d’accueil, écrans pseudo,
thème et avatar, contrôleur, états, navigation et helpers uniquement utilisés par
ces écrans retirés. Accueil avec « Commencer » comme seule action de lancement ;
transition, trois cartes, exemple et parcours de 30 questions conservés. Tests de
parcours adaptés, absence de personnalisation vérifiée et capture d’accueil relue.
**59 tests Flutter ciblés verts**, captures comparées sans régénération et analyse
des deux fichiers Dart modifiés sans diagnostic. Décision 75 remplace la branche
facultative de la décision 73 ; docs de parcours/roadmap mises à jour, assets originaux
conservés comme maquettes archivées. Aucun nouveau fichier, changement de backend,
contrat/API, barème, métrique, délai réel, pause, migration, dépendance, `pubspec.yaml`,
`pom.xml`, core/shared ou module tiers. Zones protégées intactes ; suites globales,
backend et ArchUnit non exécutés. Rendu sur appareil à valider.

**Changelog (90)** — 2026-09-17 : **Je Décide** — présentation des questions
réparties sur Situation/Réponse améliorée après confirmation du cas par l’utilisateur.
Étapes en pastilles avec étape active dans la bande déjà réservée, carte de lecture
centrée et bouton « Voir les réponses ». Retour « Relire » visible à côté de Continue,
conservant le choix posé ; variante retour avec tooltip à 200 %. `_OutlinedChip`
réutilisé en variante compacte, usages précédents inchangés par défaut. Aucun texte,
choix, item ou ordre modifié ; questions conservées. Deux tests ajoutés et deux captures
sur vrais textes serveur créées/relues. **61 tests Flutter ciblés verts**, captures
comparées sans régénération et analyse des deux fichiers Dart sans diagnostic. Banques
réelles sur sept gabarits, tailles de police gelées, relecture et protocoles temporels
vérifiés ; aucune hausse des bornes connues de défilement des textes trop longs pour
les plus petits écrans. Décision visuelle provisoire 76 tracée ; rendu sur appareil
à valider. Cycle de vie, chronomètres, pause, validation et mesures inchangés. Aucun
backend, contrat/API, scoring, migration, dépendance, `pubspec.yaml`, `pom.xml`, core/shared
ou module tiers modifié. Zones protégées intactes ; suites globales, backend et ArchUnit
non exécutés.

**Changelog (91)** — 2026-09-17 : **Je Décide** — refonte plus visible des réponses
longues après retour de l’utilisateur sur la capture : gros blocs séparés remplacés
par un panneau blanc unique avec réponses numérotées, séparateurs, texte moins gras
et consigne intégrée. Aperçu du contexte avec Relire en tête ; Continue pleine largeur.
Situation et réponses conservées intégralement, sélection préservée après relecture.
Composants et palette Games réutilisés, aucun nouvel asset de production. Test/capture
dédiés au véritable item appartement II-3 signalé ; tests de contraste et de taille
stable des réponses adaptés aux lignes numérotées. **62 tests Flutter ciblés verts**,
trois captures de gameplay comparées sans régénération et analyse des trois fichiers
Dart sans diagnostic. Sept tailles d’écran, texte à 200 % et bornes connues de
défilement vérifiés sans hausse. Décision visuelle provisoire 77 tracée ; rendu sur
appareil à valider. Cycle de vie et mesures comparés à l’état avant refonte, inchangés.
Aucun backend, contrat/API, scoring, migration, dépendance, `pubspec.yaml`, `pom.xml`,
core/shared ou module tiers modifié. Zones protégées intactes ; suites globales,
backend et ArchUnit non exécutés.

**Changelog (92)** — 2026-09-17 : **Je Décide** — retrait confirmé des six questions
II et de la dimension correspondante du parcours, du calcul et du bilan. Contrat
OpenAPI précisé avant code ; sélection `activeBank` commune à la lecture et au contrôle
serveur de soumission. Quatre dimensions, 24 questions, brut /72 puis SCW /100 ;
parité Java/Dart, démo et parsing mobile adaptés. Situations II conservées comme
archives et références de contexte DT ; aucune migration ou suppression en base.
Navigation, widgets et captures provisoires Situation/Réponse retirés ; situation et
réponses sur une page, défilement accessible sur petit écran/texte agrandi. Compteurs,
durée affichée et radar à quatre axes adaptés. **73 tests Flutter ciblés verts**, captures
comparées sans régénération ; **33 tests Java isolés verts, dont ArchUnit 3/3**. Build
Maven habituel bloqué au testCompile par des erreurs Recruitment préexistantes ; aucun
fichier de ce module corrigé. Décision 78 et roadmap tracées ; retrait II autorisé,
autres zones protégées, règles d’item/DT, pause, dépendances, `pubspec.yaml`, `pom.xml`,
core/shared et modules tiers inchangés. Analyse ciblée des 13 fichiers Dart sans diagnostic, nouvelle capture à 24 questions
relue ; rendu sur appareil et validation psychologue des quatre axes ouverts.

**Changelog (93)** — 2026-09-17 : **Je Décide** — SFX badge ajouté à toutes les
transitions de catégorie, puis à la fin du parcours ; révélation du profil et son
scoreboard conservés. La soumission échouée ouvrait le bilan avec un profil de
remplacement à 0 : ce repli est supprimé, le résultat DECISION_CORE est requis.
Réutilisation du loader/panneau d'erreur existants ; réponses et session gardées
pour réessayer, envoi concurrent bloqué, autres jeux inchangés grâce à une option
facultative du contrôleur. **50 tests Flutter ciblés verts** : quatre parcours complets
(normal, erreur puis retry, résultat absent puis retry, SFX coupés), sons à chaque
catégorie sans répétition, valeur intermédiaire et finale du compteur, zéro serveur
valide, gameplay et disposition. Analyse des six fichiers Dart sans diagnostic.
Doc/arborescence/roadmap et décision technique 79 mises à jour. Aucun changement
backend, contrat, score, protocole, migration, dépendance, asset, pubspec, pom,
core/shared ou module tiers pour cette correction ; zones protégées intactes.
Backend/ArchUnit et suite mobile globale non relancés ; écoute sur appareil ouverte.

**Changelog (94)** — 2026-09-17 : **Je Décide** — cause réelle du score indisponible
identifiée dans le simulateur : HTTP 400, champ `items` inconnu dans
`SubmitResultRequest.Metrics`. Le DTO serveur attend déjà `decisionItems` ; contrat
OpenAPI corrigé en premier, puis JSON mobile aligné. Clé `items` du formulaire
GET, modèle interne des réponses et barème inchangés. Test mobile ajouté sur le
vrai repository Dio avec transport strict ; test Java Jackson ajouté sur le DTO.
**21 tests Flutter ciblés et 2 tests Java isolés verts**. Analyse des deux fichiers
Dart sans diagnostic. Hot reload envoyé au processus Flutter du simulateur, accueil
Je Décide ouvert ; passage complet au score sur appareil encore à vérifier. Aucun
changement de production backend, endpoint, scoring, migration, dépendance,
asset, pubspec, pom, core/shared ou module tiers ; zones protégées intactes.
Maven complet non relancé (blocage testCompile Recruitment déjà documenté).
Aucune nouvelle décision produit : correction de sérialisation vers l'API existante.

**Changelog (95)** — 2026-09-18 : **Accueils des jeux sur téléphone** —
composant Games `GameWelcomePage` réutilisant les panneaux/boutons existants pour
Memory Quest Digits/Image, Je Décide, Optimal Path, Predictive Puzzle, Emotional
Radar, Reflective Pause et Strategic Choices. Logos officiels, titres complets
sans chevauchement, mission courte et action visible ; règles redondantes retirées
uniquement des accueils. Défilement intégral réservé aux contraintes de hauteur
ou au texte agrandi. Navigation basse retirée des quatre écrans Games qui la
présentaient encore (dont Je continue), sans toucher Navigation/core. SafeArea
Je Décide respecte la barre système Android. Seconde entrée Strategic Choices
supprimée ; Day Stack inchangé. Décision 80 tracée, inventaire/statut/roadmap à jour.
Validation : **169 tests Flutter ciblés verts**, dont les 32 tests de disposition ;
analyse des 13 fichiers Dart touchés sans diagnostic ; huit captures d’accueil et deux captures
Je Décide actualisées et contrôlées. Aucun changement de backend, API, contrat,
barème, migration, asset, dépendance, pubspec/pom, core/shared ou module tiers ;
zones protégées intactes. Backend/ArchUnit non relancés pour cette tâche UI.
Contrôle sur téléphone réel ouvert.

**Changelog (96)** — 2026-09-18 : **Accueils, vide blanc corrigé** —
`GameWelcomePage` centre la carte et son bouton ensemble avec un écart de 24 px,
au lieu de les repousser aux deux extrémités de l’écran. Logo officiel agrandi
quand la hauteur disponible le permet ; retour en haut, petits écrans et texte
agrandi conservés. Test de proximité ajouté aux 32 cas de disposition existants.
**68 tests Flutter ciblés verts**, analyse des deux fichiers Dart sans diagnostic ;
huit captures d’accueil et capture Je Décide actualisées, contrôle visuel des huit
accueils. Décision 81 tracée ; inventaire et roadmap actualisés. Fichiers touchés
pour cet ajustement : composant Games, test des accueils, captures et cette doc.
Aucun fichier créé supplémentaire, changement de backend/API/contrat, barème,
core/shared, asset de production, dépendance ou module tiers. Zones protégées
intactes ; backend/ArchUnit non relancés. Contrôle sur téléphone réel ouvert.

**Changelog (97)** — 2026-09-18 : **Accueils plus contextualisés** — ajout
optionnel de `contextText`/`journey` à `GameWelcomePage`, utilisés par les huit
accueils demandés. Court contexte propre aux règles de chaque jeu et trois repères
numérotés, groupe centré et action proche ; espacement et logo adaptés à la hauteur.
Logos officiels conservés, règles détaillées dans les tutoriels, Day Stack inchangé.
Test de proximité adapté au parcours complet ; 32 cas de disposition conservés.
Validation : **169 tests Flutter ciblés verts**, dont les 32 cas de disposition ;
analyse des neuf fichiers Dart sans diagnostic ; huit captures d’accueil et capture Je Décide
actualisées, contrôle visuel des huit accueils. Fichiers modifiés : composant Games,
sept écrans (Memory Quest partagé par deux modes), test/captures et cette doc.
Aucun fichier supplémentaire créé ; décision 82 et inventaire/roadmap actualisés.
Backend, contrat, API, scores, migrations, assets de production, pubspec/pom,
core/shared et modules tiers inchangés ; zones protégées intactes. Backend/ArchUnit
non relancés ; contrôle sur téléphone réel ouvert.

**Changelog (98)** — 2026-09-18 : **BART + IST** — nouveau `GameType`
`DECISION_BEHAVIORAL` (distinct de `DECISION`, dont la complétion et la couverture seraient
cassées par des mini-jeux supplémentaires) avec `BART_CORE` et `INFORMATION_SAMPLING_CORE`.
Contrat, backend, migration, mobile (écrans d'après les planches concept, SVG des états du
ballon, hub + deux routes) et mock à parité exacte. Correction Flyway : les migrations games
`V77`/`V78` entraient en collision avec identity (démarrage impossible) → renumérotées
`V84`/`V85`, script de réconciliation fourni ; nouvelle migration `V86`. Catalogue du hub
13 → 15 jeux : la couverture affichée de chaque joueur existant baisse. **Backend 749 tests,
0 échec** (base 714). Mobile : 15 tests de parité + 6 tests d'écran verts. Décisions à valider :
voir la section dédiée (98).

**Dernière mise à jour** : 2026-09-18 — **(98)** BART + IST, correction Flyway V77/V78 ;
**(97)** accueils enrichis d’un contexte et de trois repères par jeu ;
**(96)** carte et bouton rapprochés, accueils centrés et logos agrandis ;
**(95)** accueils courts, navigation basse retirée des jeux et entrée Strategic Choices directe ;
**(94)** clé de soumission HTTP Je Décide corrigée ;
**(93)** sons de catégorie et bilan fiable Je Décide ;
**(92)** retrait II, 24 questions et bilan sur quatre axes ;
**(91)** réponses longues Je Décide regroupées et contexte accessible ;
**(90)** présentation des questions longues Je Décide en deux étapes ;
**(89)** personnalisation Je Décide retirée ;
**(88)** transition et cadre persistant accueil/règles Je Décide ;
**(87)** accueil Je Décide simplifié, trois cartes et personnalisation facultative ;
**(86)** icônes de Choix stratégique et visualisation des insights Reflective/Radar ;
**(85)** légère amélioration des deux cartes Optimal Path ;
**(84)** deux cartes de règles Predictive Puzzle nettes ;
**(83)** tutoriels Memory Quest Digits/Image illustrés et audit préalable ;
**(82)** tutoriel Je Décide et aide en cartes illustrées ;
**(81)** tutoriel Choix stratégiques et aide en cartes illustrées ;
**(80)** tutoriel Reflective Pause et aide en cartes illustrées ;
**(79)** tutoriel Radar V2 illustré et aide ;
**(78)** fond habituel du tutoriel rétabli, cartes centrées conservées ;
**(77)** nouvelle présentation du tutoriel Day Stack et geste à essayer ;
**(76)** tutoriel Day Stack en six cartes illustrées ;
**(75)** 82 emotes Day Stack intégrées aux cartes du calendrier ;
**(74)** 82 emotes Day Stack générées, catalogue et relecture ;
**(73)** heures Day Stack conservées pendant le déplacement ;
**(72)** mission Day Stack verte, clignotement Memory Quest partagé ;
**(71)** missions Day Stack propres aux sept univers ;
**(70)** validation Day Stack séparée du calendrier, compteur retiré ;
**(69)** calendrier Day Stack mauve et défilant ;
**(68)** diagnostic du retour arrière Je Décide, correction ouverte ;
**(67)** supports écrits Strategic Choices reproductibles et testés ;
**(66)** piste Memory Quest associant formes du quiz et objets modernes ;
**(65)** piste Memory Quest aux objets technologiques modernisés ;
**(64)** piste Memory Quest aux objets modernes et flèches circulaires ;
**(63)** audit des tutoriels d’intelligence émotionnelle ;
**(62)** audit et correction du tutoriel Day Stack ;
**(61)** Day Stack : liste réordonnable, validation sans pénalité ;
**(60)** piste Memory Quest centrée sur la mémorisation d'objets ;
**(59)** seconde piste minimaliste de logo Memory Quest Image ;
**(58)** premier concept de logo Memory Quest Image non intégré ;
**(57)** merge `origin/main` + renumérotation Flyway ; **(56)** nettoyage du dépôt ;
**(55)** démo Day Stack, Emotional Radar, Reflective Pause
et Strategic Choices ; layouts améliorés et vidéos locales provisoires. Barèmes protégés conservés.
