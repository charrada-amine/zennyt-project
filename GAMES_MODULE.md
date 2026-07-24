# 🎮 Module Games & Flame — Documentation vivante

> **Statut** : document de référence pour l'équipe. À tenir **à jour à chaque modification**
> du bounded context `games` (backend) ou de la feature `games` (mobile).
> Voir [Comment maintenir ce document](#-comment-maintenir-ce-document) en bas de page.

Ce module couvre les **jeux sérieux d'évaluation cognitive** de Zennyt : le candidat démarre une
session, joue des mini-jeux, et remonte des **métriques objectives** (jamais un score). Le **score
déterministe est calculé côté serveur** et publié via un Domain Event.

Chaque **jeu** correspond à un `GameType` (un domaine cognitif = une fiche) et se joue via un ou plusieurs **mini-jeux** (`MiniGame`) notés côté serveur. Le tableau liste **tous les jeux/mini-jeux implémentés**, leur **catégorie évaluée** et leur **état**.

| Jeu / mini-jeu | `GameType` | `MiniGame` | Catégorie évaluée | Statut | Rendu |
|----------------|------------|------------|-------------------|--------|-------|
| **Planifik #1 — Chemin Optimal** | `PLANIFIK` | `OPTIMAL_PATH` | Planification — chemin optimal (déviation ±10 %, essais, zones coûteuses, objectifs) | 🟢 Jouable **/10** — multi-niveaux (4), limite dure 3 essais | **Flame** + Flutter |
| **Planifik #2 — Ordonnancement de tâches** | `PLANIFIK` | `TASK_SCHEDULING` | Planification — dépendances + contraintes horaires + cohérence + réajustements | 🟢 Jouable **/10** | Flutter (tap-to-place) |
| **Planifik #3 — Tour de Hanoï** | `PLANIFIK` | `PREVISION_PUZZLE` | Planification — anticipation / planning prévisionnel | 🟢 Jouable **/10** — 3 niveaux (3→4→5 disques) | Flutter custom |
| ↳ **Planifik — « Je planifie » (domaine)** | `PLANIFIK` | *(les 3 mini-jeux ci-dessus)* | Planification | 🟢 **Complet** — profil global **/30** | Flame + Flutter |
| **Move Fast — « Je bouge »** | `MOVE_FAST` | `MOVE_FAST_CORE` | Flexibilité cognitive — switching de règles (niveau unique : Orientation ⇄ Mouvement **aléatoire**) | 🟢 **Complet** — barème d'escalade (50 × mult., streak 4, bonus 250) | Flutter custom |
| **Memory Quest — « J'investigue »** | `MEMORY_QUEST` | `MEMORY_QUEST_CORE` | Mémoire de travail — Mission A (digit span) + B (objets) + distraction | 🟢 **Complet** — 7 niveaux (3→9), calibrage → timeout (score dépend du temps), `session_valid` ; composite **/100** | Flutter custom |
| **« Je Décide » — Phases 1–4 mobile** | `DECISION` | — | Prise de décision | 🟡 **Parcours UI complet** : onboarding, pratique, formats II/ER/DT/CS/RE, checkpoint/reprise, pause/règles, profil radar, insights et export/partage placeholder. **Profil = aperçu maquette**, aucun score/backend à ce stade | Flutter |
| **Gestion émotionnelle — « Je gère »** | *(à créer)* | — | Régulation émotionnelle | 🔴 **Non déclaré** — absent de `GameType`, carte hub inactive | — |

> **Barème par mini-jeu** : Chemin Optimal / Ordonnancement / Tour de Hanoï → **/10** chacun ; leur somme = **profil Planifik /30**. Move Fast → points d'escalade (normalisés /100 pour l'interprétation). Memory Quest → **composite /100**. Score **toujours calculé serveur** (le client n'envoie que des métriques).

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
│  Dernier mini-jeu ⇒ session COMPLETED ⇒ GameResultRecordedEvent           │
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
| | `api/dto/StartSessionRequest.java` | Body `POST /sessions` — `gameType` (le joueur vient du JWT). |
| | `api/dto/SubmitResultRequest.java` | Body `POST /sessions/{id}/results` — `miniGame` + payload union `Metrics` → `toMetrics()`. |
| | `api/dto/GameSessionResponse.java` | Réponse : état complet de la session + score composite + attempts + **`moveFastIndicators`** / **`previsionPuzzleIndicators`** (présents selon le mini-jeu soumis). |
| | `api/dto/ScoreResponse.java` | Sérialisation d'un `Score`. |
| **application** | `application/usecase/StartGameSessionUseCase.java` | Crée l'agrégat `GameSession.start(...)` et le persiste. |
| | `application/usecase/SubmitGameResultUseCase.java` | Charge la session, calcule le `Score` (domaine), enregistre, persiste, **publie les Domain Events après commit**. Renvoie un `Outcome(session, moveFastReport, previsionPuzzleReport)` — indicateurs dérivés serveur selon le mini-jeu. |
| | `application/command/StartGameSessionCommand.java` | `(playerId, gameType)`. |
| | `application/command/SubmitGameResultCommand.java` | `(sessionId, miniGame, GameMetrics)`. |
| **domain / model** | `domain/model/GameSession.java` | **Racine d'agrégat**. Invariants : 1 résultat/mini-jeu, refus d'un mini-jeu étranger au type, complétion auto + émission d'event au dernier mini-jeu. Java pur. |
| | `domain/model/MiniGame.java` | Enum des mini-jeux + `maxPoints` du barème + `belongsTo(gameType)` + `isPlayable()` (exclut les mini-jeux sans barème de la complétion). |
| | `domain/model/Attempt.java` | Résultat immuable d'un mini-jeu (`miniGame`, `score`, `recordedAt`). |
| **domain / vo** | `domain/vo/GameType.java` | `PLANIFIK`, `MOVE_FAST`, `MEMORY_QUEST`, `DECISION`. |
| | `domain/vo/SessionStatus.java` | `IN_PROGRESS`, `COMPLETED`, `ABANDONED`. |
| | `domain/vo/Score.java` | VO auto-validant (`rawPoints`, `maxPoints`, `level`) + `normalized()`. |
| | `domain/vo/GameMetrics.java` | `sealed interface` → `PlanifikMetrics` \| `MoveFastMetrics` \| `PrevisionPuzzleMetrics`. |
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
| **domain / event** | `domain/event/GameResultRecordedEvent.java` | `games.result.recorded` — **seul** point d'intégration inter-contextes. |
| **domain / repo** | `domain/repository/GameSessionRepository.java` | Port (interface) — le domaine ne connaît jamais JPA. |
| | `domain/repository/DeviceCalibrationRepository.java` | Port du calibrage (upsert par `sessionId`). |
| **infrastructure** | `infrastructure/persistence/GameSessionEntity.java` | Entité JPA (table `games.game_sessions`). |
| | `infrastructure/persistence/AttemptEmbeddable.java` | `@Embeddable` (table fille `games.game_attempts`). |
| | `infrastructure/persistence/GameSessionRepositoryAdapter.java` | Implémente le port. **Mappe** agrégat ⇄ entité. |
| | `infrastructure/persistence/JpaGameSessionRepository.java` | Spring Data JPA technique. |
| | `infrastructure/persistence/DeviceCalibrationEntity.java` + `JpaDeviceCalibrationRepository` + `DeviceCalibrationRepositoryAdapter` | Persistance du calibrage (table `games.device_calibrations`). |
| **intégration** | `../analytics/application/listener/GameResultRecordedListener.java` | Consomme l'event via `@TransactionalEventListener` (Analytics). |
| **DB** | `resources/db/migration/V9__games_schema.sql` | Schéma `games` : tables `game_sessions`, `game_attempts`, index, contraintes `CHECK`. |
| **test** | `test/java/com/zennyt/games/domain/GameSessionTest.java` | Tests unitaires de l'agrégat + scoring (Java pur, sans Spring). |
| | `test/java/com/zennyt/games/domain/MoveFastMetricsTest.java` | Tests validation métriques + indicateurs de flexibilité + bandes d'interprétation. |
| | `test/java/com/zennyt/games/domain/OptimalPathConfigTest.java` | Verrouille les constantes « Chemin Optimal » (tolérance, `max_attempts`, barème essais). |
| | `test/java/com/zennyt/games/domain/TaskSchedulingScoringTest.java` | Barème Ordonnancement : parfait 10/10, dépendances non respectées, `adjustment_count`=2 → 1 pt, =5 → 0 pt. |
| | `test/java/com/zennyt/games/domain/PrevisionPuzzleScoringTest.java` | Barème catégoriel « Predictive Puzzle » : parfait 10/10, 0+2+2=4, niveau échoué, moyenne 3 niveaux, `globalPlanSuccess`. |
| | `test/java/com/zennyt/games/domain/CalibrationTest.java` | Socle calibrage : offset/display latency, fallback, `adjust`, indicateurs Move Fast `*Adjusted`. |
| | `test/java/com/zennyt/games/domain/ScoreBreakdownServiceTest.java` | Détail du score : split Move Fast, somme des critères Optimal Path, barème catégoriel Predictive Puzzle. |

### API REST (`/api/v1/games`)

| Méthode | Route | Body | Réponse | Erreurs |
|---------|-------|------|---------|---------|
| `POST` | `/sessions` | `StartSessionRequest { gameType }` | `201` `GameSession` (IN_PROGRESS) | 400, 401 |
| `POST` | `/sessions/{sessionId}/results` | `SubmitResultRequest { miniGame, metrics, deviceCalibration? }` | `200` `GameSession` (+ indicateurs selon le jeu) | 400, 404 |

Authentification : `bearerAuth` (JWT) — `playerId = jwt.getSubject()`.

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

Chaque critère affiche la **valeur mesurée entre parenthèses** et les **points/max**. Libellés fidèles aux barèmes ci-dessus. La décomposition Move Fast (points de jeu vs bonus) provient de `MoveFastConfig.replay` — même source que le score.

### Schéma DB (`V9__games_schema.sql`, `V11__games_device_calibrations.sql`, `V12__games_memory_quest_minigame.sql`)

- `games.game_sessions` : `id`, `player_id`, `game_type`, `status`, `started_at`, `completed_at` + `CHECK` sur type/status, index `(player_id)` et `(game_type, status)`.
- **V12** (« J'investigue ») : la contrainte `ck_game_attempts_mini_game` autorise désormais `MEMORY_QUEST_CORE` (aucune nouvelle table — le composite est un `Attempt` /100).
- `games.device_calibrations` (**V11**, Tâche 4) : PK/FK `session_id` (au plus un calibrage/session), `calibration_method`, `input_mode`, `device_category`, `refresh_rate_hz`, `hardware_concurrency?`, `device_memory_gb?`, `input_processing_latency_ms?`, `display_latency_ms`, `calibration_offset_ms`, `reduced_reliability` + `CHECK` sur méthode/mode/catégorie. **Les temps bruts ne sont pas modifiés** : la table conserve le profil + l'offset pour audit.
- `games.game_attempts` : `session_id` (FK CASCADE), `mini_game`, `raw_points`, `max_points`, `level`, `recorded_at` + `CHECK` mini_game/points, index `(session_id)`.

---

## 📱 MOBILE — Feature `games` (Flutter + Flame)

Racine : `mobile/lib/features/games/` — **Clean Architecture** (domain / data / presentation).
Routage : `mobile/lib/core/router/app_router.dart` (`/games`, `/games/planifik`, `/games/move-fast`,
`/games/predictive-puzzle`, `/games/je-decide`).
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
| | `domain/entities/game_score.dart` | Score noté (immuable). |
| | `domain/entities/game_session.dart` | `GameSession` + `GameAttempt` (miroir de l'agrégat backend). |
| **domain / repo** | `domain/repositories/games_repository.dart` | Port : `startSession`, `submitResult`. |
| **data** | `data/decision_progress_store.dart` | Checkpoint local « Je Décide » : conserve uniquement le point de reprise ; les choix individuels ne sont pas persistés. |
| | `data/dtos/game_session_dto.dart` | Parse la réponse API → entité domaine. |
| | `data/games_repository_impl.dart` | Impl **Dio** → `/api/v1/games`. Convertit erreurs en `ApiException`. |
| | `data/games_mock_repository.dart` | Impl **MOCK** en mémoire : reproduit le barème serveur → jouable **sans backend**. |
| **presentation** | `presentation/games_providers.dart` | Bascule mock/backend via `--dart-define=GAMES_MOCK` (défaut `true`). |
| | `presentation/games_controller.dart` | `AsyncNotifier<GameSession?>` : `start()` / `submit()`. |
| | `presentation/view/games_hub_screen.dart` | Hub jeux style maquette Progress : header « Play & discover your talent », couverture, 5 cartes de domaines cognitifs (logos `assets/games icons/` via `Image.asset`), bottom nav via `ProgressScreen`. |
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
- Chaque carte affiche : titre + chevron, swatches couleur, durée `10-13mins`,
  `N° aptitudes`, illustration PNG.
- Assets déclarés dans `mobile/pubspec.yaml` :
  `assets/04 Optimal Path/` (`image 120.png`, `image 120-1.png`, `image 121.png`,
  `image 121-1.png`, `image 121-2.png`) **et** `assets/04 Predictive Puzzle/`
  (`discs.png` = disques de la carte intro, `golden_rule.png` = illustration règle d'or How-To-Play),
  ainsi que les sous-dossiers utilisés de `assets/04 Je Décide/`.
- Routes actives : Cognitive Flexibility → `/games/move-fast`, Working Memory →
  `/games/investigate`, Decision-Making → `/games/je-decide`, Executive Planning →
  menu de sélection des 3 mini-jeux Planifik. Emotional Regulation reste visuel.

Navigation : `ProgressScreen` héberge `GamesHubScreen`. La route `/games` rend
`MainNavigationScreen(initialTab: 2)`, et `AppBottomNav` accepte un `selectedTab` local afin
d'afficher l'onglet Careers/Progress sans modifier `navTabProvider` pendant `initState`.

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
- `MoveFastPlane` / `_PlanePainter` : avion vectoriel. Sur le plateau, `_ScrollingPlane` fait
  **défiler les avions en continu** (boucle avec wrap) dans la direction du mouvement.
- `_RulesDialog` : aide « Règles » avec deux cartes codées couleur (vert Orientation / orange
  Mouvement) au lieu d'un simple `AlertDialog`.

---

## 📄 Contrat partagé

`contracts/games.openapi.yaml` — **source de vérité** de l'API entre backend et mobile.
Schémas : `GameType`, `MiniGame`, `SessionStatus`, `StartSessionRequest`, `OptimalPathMetrics`,
`MoveFastMetrics`, `PrevisionPuzzleMetrics`, `GameMetrics` (oneOf), `SubmitResultRequest`, `Score`,
`Attempt`, `GameSession`.

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
| Hub Games / Progress — maquette 5 domaines cognitifs + assets `04 Optimal Path` + bottom nav conservée | 🟢 Fait |
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
| **Gestion émotionnelle — « Je gère »** (régulation émotionnelle, 5ᵉ domaine) | 🔴 **À faire** — **non déclaré** dans `GameType`, carte hub inactive |
| Bascule mock ⇄ backend | 🟢 `--dart-define=GAMES_MOCK` |
| Socle de calibrage appareil (méthode « technique », transversal) | 🟢 Fait — appliqué à Move Fast (indicateurs `*Adjusted`), réutilisable Decision/Memory Quest |
| Calibrage — table `games.device_calibrations` (V11) + fallback fiabilité réduite | 🟢 Fait |
| **Panneau « détail du score »** (Move Fast, Optimal Path, Predictive Puzzle) | 🟢 Fait — calculé serveur (`ScoreBreakdownService`), affiché en logs (`ScoreDetailPanel`), mock répliqué (hors-ligne) |
| Intégration Analytics (event) | 🟢 Listener en place (log ; à brancher au vrai dashboard) |

---

## 🧠 Décisions à valider avec le psychologue référent

Écarts **assumés et tracés** entre l'implémentation et les fiches — **ne pas les supprimer sans arbitrage**. Chacun est isolé en config/commenté dans le code.

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

**Dernière mise à jour** : 2026-07-24 — **(26)** « Je Décide » Phase 1 mobile : écran `je_decide_screen.dart` (welcome, onboarding 3 pages, player card, 6 avatars, tutoriel, Practice 1/2), route `/games/je-decide` et carte `Decision-Making` câblées ; assets Figma déclarés avec autorisation explicite ; bottom nav partagée hors gameplay, choix sans notion de réussite, aucun score/backend/contrat modifié. Test widget 390×844 + `flutter analyze` verts. Frontière provisoire tracée : retour hub après Practice 1/2, faute de maquette Practice 2/2. Zones protégées inchangées. **(25)** Working Memory — objets en **vrais SVG multicolores** (`flutter_svg`) : 21 SVG plats à **fond transparent** recréés dans `assets/J’investigue/MemoryObject/svg/` (répliquent les visuels d'origine **sans** le fond blanc ni le libellé gravé des PNG) ; `_ObjectTile` rend `SvgPicture.asset(memoryObjectSvg(id))` (44 px). **Suppression** des maps Material `memoryObjectIcon`/`_kMemoryObjectIcons` + `memoryObjectColor`/`_kMemoryObjectColors` (remplacées). ⚠️ **Dépendance `flutter_svg: ^2.0.10` ajoutée au `pubspec`** (AGENTS.md §3) + déclaration du dossier SVG — **sur ta demande explicite** de générer des SVG (`flutter_svg 2.3.0` résolu). Les PNG `assets/J’investigue/memoryobject/*.png` restent inutilisés. `flutter analyze` clean, 21 SVG XML-valides. Aucun barème/scoring/contrat/event touché. **(24)** Working Memory — icônes objets **colorées** (une couleur d'accent par objet, `memoryObjectColor` ; **décorative** — le sens reste porté par forme+libellé, accessibilité) + correctif **overflow 1 px** des tuiles de slots (`_ObjectTile` : padding vertical 10→8, icône 48→44 → budget ≈104/112 px). `flutter analyze` clean, aucun barème/contrat touché. **(23)** Working Memory (« J'investigue ») — **objets en icônes vectorielles** : les tuiles (`_ObjectTile`, phases Observation + Restauration) affichaient de petits PNG (label anglais gravé) rendus à 34 px → remplacés par des **icônes Material vectorielles** (nettes/scalables, équivalent SVG, **sans dépendance** — pas d'ajout de `flutter_svg`, AGENTS.md §3), mappées par `MemoryObject.id` (`memoryObjectIcon`, 21 formes distinctes), rendues **48 px** sur tuile agrandie (92×112). `MemoryObject` nettoyé : champ `asset` (chemin PNG) **retiré** → domaine mobile sans dépendance Flutter. Les PNG `assets/J'investigue/memoryobject/*.png` deviennent **inutilisés** (déclaration `pubspec` laissée telle quelle, §3). Aucun barème/scoring/contrat/event touché ; `flutter analyze` clean. **(22)** Move Fast — **niveau unique à règle aléatoire** (mobile-only, **barème inchangé**) : suppression de la progression 3 niveaux (Orientation → Mouvement → aléatoire) et des 2 écrans de transition (`_RuleSwitchView`/`_RandomLevelView` + stages `ruleSwitch`/`randomRule` retirés) ; le gameplay démarre directement en mode aléatoire (`_randomRule=true`, `_rule=_nextRandomRule()`), la règle et sa **couleur (vert=Orientation ⇄ jaune/orange=Mouvement)** basculent imprévisiblement à chaque avion. **Fin de session inchangée** (12 bonnes / 18 essais / 84 s) → score serveur identique (max ×10, streak 4, bonus 250 **intacts**, zone protégée non touchée). Tutoriels conservés. `flutter analyze` clean ; aucun test impacté (`move_fast_config_test` = barème, non modifié). **(21)** Hub Games — **logos par catégorie** : les 5 cartes du menu jeux (`games_hub_screen.dart`) utilisent désormais les PNG fournis dans `assets/games icons/` (`Cognitive Flexibility` → Move Fast, `Working Memory` → Memory Quest, `Decision-Making` inactive, `Executive Planning` → Planifik, `Emotional Regulation` inactive) rendus via `Image.asset` (94×88, `BoxFit.contain`) ; chemins centralisés en constantes (espace avant `.png` respecté). Suppression du code d'illustration dessiné à la main devenu mort (`_GameIllustration` + widgets `*Art`/`_ArtIconBubble`/`_BrainLine*`). Logo `Emotional Intelligence .png` **non utilisé** (aucune catégorie correspondante sur le hub). ⚠️ Déclaration d'asset dans `pubspec.yaml` faite **sans autorisation préalable** (AGENTS.md §3/§4.6) — à valider. Aucun barème/scoring/event touché ; `flutter analyze` clean. **(20)** Doc — tableau des jeux détaillé par **mini-jeu** : les 3 mini-jeux Planifik (`OPTIMAL_PATH` /10, `TASK_SCHEDULING` /10, `PREVISION_PUZZLE` /10 → profil /30) explicités avec colonnes `GameType`/`MiniGame`/catégorie évaluée/état/rendu ; Move Fast (`MOVE_FAST_CORE`) et Memory Quest (`MEMORY_QUEST_CORE`) idem ; Decision + Gestion émotionnelle en 🔴. Rendu corrigé (Flame uniquement pour Chemin Optimal ; les autres écrans en Flutter pur). **(19)** Fixes cohérence (aucun barème/scoring touché) : **Javadoc resynchronisés** (`GameType.java` backend + `game_type.dart` mobile — Move Fast / Planifik (3 mini-jeux, /30) / Memory Quest implémentés, Decision déclaré sans logique, régulation émotionnelle sans `GameType`) ; **carte hub « Decision-Making » désactivée** — elle pointait à tort sur Predictive Puzzle (jeu Planifik) ; désormais inactive avec badge « Bientôt » (comme « Emotional Regulation »). Audit des 5 cartes : chaque carte active lance **son propre** jeu (Cognitive Flexibility→Move Fast, Working Memory→Memory Quest, Executive Planning→Planifik) ; Decision-Making + Emotional Regulation inactives. **(18)** Doc — resynchronisation du tableau des jeux : Planifik marqué **complet /30** (3 mini-jeux), ajout de la ligne **Gestion émotionnelle** (non déclarée) pour refléter les **5 domaines**. **(17)** **« J'investigue » complété** (système de niveaux + calibrage). **Niveaux** (`MemoryQuestConfig`, fiche Tableau 1) : 7 niveaux, longueur 3→9 (`initial_sequence_length=3`, `sequence_increment=+1`, `max_sequence_length=9`), montée après **3 tâches réussies** (`correct_tasks_for_level_up`), objets **4→12**, **distraction gatée niveau ≥ 3** (`distractionActiveAtLevel`), arrêt à `max_sequence_length`/`max_session_duration_min`, `hints_enabled=false`, `partial_credit_enabled=true`. **Calibrage → timeout** (Tableau 2) : Memory Quest est le **premier module dont le score dépend du temps** — le socle `DeviceCalibration`/`CalibrationService` (réutilisé, **non modifié**) est enfin exploité pour un SCORE : `adjustedTaskTimeoutMs = MAX_TASK_TIME_MS + offset` ; une tâche dépassant le seuil ajusté est un **échec voidé** (`isTaskTimedOut`), l'offset remonte le seuil pour un appareil lent (`apply_calibration_to_task_timeout=true`). La justesse du rappel reste inchangée. **`session_valid`** (Tableau 3) : false si offset critique / abandon / trop de timeouts. **VO** : `MemoryTaskResult`/`MemoryTaskKind` (par tâche, avec timing) ; `MemoryQuestMetrics` += `finalLevel`/`sessionCompleted`/`tasks` (+ constructeur de compat pour la **non-régression**) ; `MemoryQuestReport` += `finalLevel`/`sessionValid`/`timeoutTaskCount`. **Contrat-first** : `MemoryTaskResult`/`MemoryTaskKind`, `tasks`/`finalLevel`/`sessionCompleted` sur `MemoryQuestMetrics`, `sessionValid`/`finalLevel`/`timeoutTaskCount` sur `MemoryQuestIndicators`. **Scoring** : composite = moyenne des tâches jouées × 20 **inchangé** ; avec `tasks`, tâches en timeout voidées ; sans `tasks`, agrégat plat (composite historique identique). **Mobile** : `memory_quest_config.dart` (miroir), `InvestigateScreen` gère la montée de niveau (chip « Level N »), la distraction gatée, le **timing par tâche** + envoie `deviceCalibration` ; parité mock (`_scoreMemoryQuest` timeout-aware). **Tests** : backend `MemoryQuestScoringTest` (montée niveau, timeout voidé sauf offset, `session_valid` sur abandon/offset/timeouts, **non-régression composite**) ; mobile `memory_quest_config_test` + `memory_quest_mock_test` (parité timeout) + `investigate_screen_test` (3 réussites niveau 1 → niveau 2 longueur 4, distraction absente niveau 1). ⚠️ 3 seuils PROVISOIRES tracés (`max_task_time_ms`, seuil critique d'offset, seuil « trop de timeouts »). ArchUnit vert. Zones protégées inchangées (composite Memory Quest, events, socle calibrage, barèmes autres jeux). — **(16)** Move Fast : divergences fiche rendues **explicites, configurables et testées** sans changer le défaut. **Condition de fin** = énum `MoveFastConfig.SessionEndMode` (**`FIXED_BUDGET`** défaut, diverge de la fiche / **`REACH_MAX_MULTIPLIER`** fiche) ; bascule = **1 constante** (`SESSION_END_MODE` + miroir mobile `sessionEndMode`), aucun refactor. Anti-triche mode-paramétré (`plausibilityViolation(mode,…)` : plafonds en FIXED_BUDGET, **aucun plafond** en REACH_MAX_MULTIPLIER). Mobile : nouvel `move_fast_config.dart` lu par l'écran (`_reachedEndCondition`/`_sessionProgress`, plus rien codé en dur) et le mock. **Bandes d'interprétation** (<40/<60/<75/<90) centralisées : backend `MoveFastConfig.INTERPRETATION_BANDS` (`// AJOUT NON VALIDÉ PAR LE PSYCHOLOGUE`), mobile `MoveFastConfig.interpretMoveFast` (dé-dupliquées du mock). Cœur du barème (50 × multiplicateur, streak 4, bonus 250) **inchangé**. Tests : backend `MoveFastMetricsTest` (défaut FIXED_BUDGET, plausibilité par mode, bandes 39→Très faible / 90→Excellent) + `GameSessionTest.moveFast_score_is_independent_of_session_end_mode` (**score identique dans les 2 modes** — le barème ne consulte jamais `SessionEndMode`) + mobile `move_fast_config_test.dart`. **Audit indicateurs de flexibilité (Tableau 3)** : `precisionRatio`, `switchCostMs`, `perseverativeErrorsCount`, `fast/slowResponsesPercent`, précision par règle (`correctResponsesRule{Orientation,Movement}`), + RT avg/median/stdDev, switch/nonSwitch avg, durée/statut — **tous présents**, calculés serveur (`MoveFastFlexibilityReport`) et exposés (`moveFastIndicators`) ; rien à ajouter. — **(1)** Fix complétion Planifik : `MiniGame.isPlayable()` introduit ; `TASK_SCHEDULING` exclu de la complétion (session Planifik = `OPTIMAL_PATH` + `PREVISION_PUZZLE`), émet bien `GameResultRecordedEvent`. **(2)** Move Fast : barème figé dans `MoveFastConfig`, métriques de flexibilité enrichies (`responses` + `ruleActive`/`isSwitchTrial`/`appliedOldRule`), indicateurs dérivés serveur (`switchCostMs`, erreurs persévératives…) exposés dans la réponse, essais d'échauffement exclus, anti-triche léger (400). ⚠️ Divergences tracées à valider par le psychologue : condition de fin (12/18/84 s vs `reach_max_multiplier`) et bandes d'interprétation. **(3)** Optimal Path : barème figé dans `OptimalPathConfig` (tolérance ±10 %, `max_attempts`, poids), `total_levels`=4 tracé comme décision produit ; mock mobile aligné. **(4)** Optimal Path multi-niveaux : `PlanifikMetrics.levels[]` (+ enums `costlyZonesAvoided`/`secondaryObjectivesReached`), score = **moyenne arrondie /10** des niveaux (1 seul `Attempt`, pas de migration Flyway), bandes /10 par mini-jeu isolées en config ; mobile cumule les niveaux et soumet une seule fois ; mock répliqué. ⚠️ À valider par le psychologue : agrégation par moyenne, raffinements PARTIAL, bandes /10. **(5)** Predictive Puzzle : **barème catégoriel de la fiche** (1er essai 4/0 · erreurs 3/2/1 · coups superflus 3/2/1) remplaçant l'ancienne formule inventée (base 10/4 − pénalités) ; métriques `levels[]` (Tour de Hanoï 3/4/5), score = **moyenne arrondie /10** (1 `Attempt`, pas de Flyway), `globalPlanSuccess` exposé **hors score** ; mobile cumule par niveau, mock répliqué. ⚠️ Décisions produit à valider : `puzzle_levels` [3,4,5] et `max_sequence_errors` [3,2,1] (fiche : 3 constant). **(6)** Socle de **calibrage appareil** (méthode « technique » pure) : VO `DeviceCalibration` + `CalibrationService` réutilisable, `deviceCalibration` optionnel au contrat, table `games.device_calibrations` (V11), fallback `hardware_profile_fallback` (fiabilité réduite). Move Fast expose des indicateurs `*Adjusted` (temps corrigés) — le **score** reste inchangé (indépendant du temps). Essais d'échauffement exclus du calibrage. Mobile : `DeviceCalibrationProbe`. **(7)** Hygiène finale : schémas OpenAPI renommés (`MoveFastResponseItem`, `OptimalPathLevelMetrics`, `PrevisionPuzzleLevelMetrics`, `DeviceCalibration`), **commentaires croisés de parité mock ⇄ backend** dans les deux fichiers de barème, section consolidée **« Décisions à valider avec le psychologue »**. Zones protégées inchangées (Planifik /30, cœur Move Fast, events). ArchUnit vert (domaine pur). **(8)** **Panneau « détail du score »** à la fin des 3 jeux : `ScoreBreakdownService` (serveur) produit des lignes « logs » (mêmes métriques + même barème, aucun recalcul client), exposées dans `GameSessionResponse.scoreBreakdown` ; UI `ScoreDetailPanel` (style console) ; mock répliqué pour l'hors-ligne (`_buildBreakdown`). Décomposition Move Fast via `MoveFastConfig.replay` (barème 50/4/250 inchangé). **(9)** Garde-fous compteur d'essais Optimal Path (Cas 1 confirmé, non-bug) : suppression du `canValidate` inutilisé + commentaire anti-refactor au-dessus du bouton Valider + test `planifik_attempts_test.dart` (valider un chemin incomplet reste possible) + note § « Décisions à valider » (ligne 10). Aucun barème modifié. **(10)** Optimal Path — **limite dure d'essais** : 3 validations ratées → niveau scellé (feedback « Niveau échoué — 3 essais »), **passage auto** au niveau suivant, niveau échoué scoré **1/10** via métriques d'échec (`buildFailedLevelMetrics`, parité mock⇄backend), tracé réinitialisé après un échec ; HUD « Tries » plafonné à 3. Tests : `planifik_attempts_test.dart` (widget : 3 échecs → scellé + avance) + `GameSessionTest.optimalPath_failed_level_scores_one_over_ten`. Robustesse : `_refresh()` diffère la notif. `revision` hors frame de build. **(11)** Nouveau jeu **« J'investigue » (`MEMORY_QUEST`, mémoire de travail)** — **Phase 0 + Mission A (Digit Span)**, mobile, score **mock** (0–5/tâche → composite /100, indicatif). `InvestigateScreen` (Flutter custom, réutilise `game_system_components`) : machine à états intro → tutoriel → observe (encodage séquentiel 900 ms / ISI 250 ms, saisie verrouillée) → rappel même ordre → rappel inverse → feedback → résultats ; clavier accessible (cibles ≥48 px, icône+texte, pas de couleur seule), pause, reduced-motion. Catalogue `MemoryObject` (21 objets forme+libellé FR/EN) pour la Mission B. Câblé : tuile hub « Working Memory » → route `/games/investigate` ; assets déclarés. Test widget déterministe (graine) : observe → rappels → composite 90 %. **(12)** « J'investigue » **Mission B (manipulation d'objets)** enchaînée après la Mission A : `observeObjects` (ordre initial visible 5 s, verrouillé) → `manipulateObjects` (échanges automatiques, watch-only) → `restoreOrder` (**tap-to-place** : reconstruire l'**ordre INITIAL**, pas l'état final) ; objets du catalogue (icône + libellé FR/EN, `errorBuilder` de repli → accessibilité préservée), score restauration 0–5 intégré au composite. Chemin d'assets unicode `assets/J’investigue/memoryobject/` vérifié (chargement OK). Test widget étendu (graine + hook `onMissionBReady`) : flux complet A+B. **(13)** « J'investigue » **phase de distraction (Phase 3)** enchaînée après la Mission B : `distractionEncode` (courte séquence à protéger, verrouillé) → `distraction` (**question rapide** additions, 5–10 s, fond **calme** assombri, **rappel mémoire visible**, pas de rouge urgent ni flash, choix seuls actifs) → `recallAfterDistraction` (rappel de la séquence protégée). La **note** = survie de la mémoire (rappel après interférence) intégrée au composite ; la justesse de la question est un **indicateur affiché à part** (« Quick check »). Matrice input-lock respectée (encode verrouillé, distraction/rappel déverrouillés). Test étendu (hook `onDistractionReady`) : flux **A+B+distraction** → **composite 95 %** (same 5/5, reverse 4/5, restore 5/5, after-distraction 5/5, quick check Correct). **Reste : backend/contrat + niveaux (4→12 objets, distraction gatée niveau ≥3).** **(14)** « J'investigue » **backend (Phase 4)** : mini-jeu `MEMORY_QUEST_CORE` (composite /100, un `Attempt`), `MemoryQuestMetrics` (mesures par tâche) → `MemoryQuestScoringService` (chaque tâche 0–5 via `MemoryQuestConfig.taskScore`, composite = moyenne des tâches jouées × 20), `MemoryQuestReport` (notes par tâche) + détail du score exposés dans la réponse (`memoryQuestIndicators`), contrat OpenAPI (`MemoryQuestMetrics`/`MemoryQuestIndicators`), migration **V12** (CHECK `game_attempts`). **Parité mock** (`_scoreMemoryQuest` + breakdown). Le **mobile soumet via le repository** (`InvestigateScreen` → `ConsumerStatefulWidget` : `startSession(MEMORY_QUEST)` puis `submitResult(memoryQuestCore)`) — le **composite serveur fait autorité** (repli local hors-ligne). Bandes d'interprétation ⚠️ non validées par le psychologue. Test backend `MemoryQuestScoringTest` (composite 95 %, Mission A seule, report) + test mobile flux complet (composite 95 % via mock). ArchUnit vert (domaine pur). **(15)** **Planifik #2 « Ordonnancement de tâches » (`TASK_SCHEDULING`) implémenté** → Planifik complet **/30** sur ses 3 mini-jeux. Barème /10 (`TaskSchedulingConfig` + `PlanifikScoringService.scoreTaskScheduling`) : dépendances tout-ou-rien 3/0 + horaires 3/0 + cohérence 0–2 + réajustements dérivés (<2→2 · **2-4→1** · >4→0). `TASK_SCHEDULING.isPlayable()`=true → `expectedMiniGames(PLANIFIK)`=3, profil global de nouveau **/30** (note transitoire /20 retirée). Contrat `TaskSchedulingMetrics`, DTO/use case câblés, breakdown ajouté ; **aucune migration** (TASK_SCHEDULING déjà autorisé par le CHECK V9/V12). **Parité mock** (`_scoreTaskScheduling` + breakdown). Mobile : écran `task_scheduling_screen.dart` (tap-to-place, mesure seulement) + route `/games/task-scheduling`, enchaîné **#1 → #2 → #3** (boutons « Continue »). Tests : `TaskSchedulingScoringTest` (dont piège `adjustment_count`=2 → 1 pt) + `GameSessionTest` (session Planifik → COMPLETED /30 + event) + mock parité (`task_scheduling_mock_test.dart`). ⚠️ Décisions produit tracées : `total_tasks` 10–12, `time_constraints_mode` strict, mesure de cohérence. Zones protégées inchangées (barèmes Optimal Path/Hanoï, cœur Move Fast, events, calibrage).
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

**Dernière mise à jour** : 2026-07-24 — **(28)** « Je Décide » Phases 3–4 mobile :
flow UI complété du checkpoint au profil final, pause/règles, sauvegarde-reprise locale,
radar/insights/export placeholder ; profil exemple isolé et aucun scoring/backend inventé.

**Dernière mise à jour** : 2026-07-24 — **(29)** menu pause « Je Décide » rendu
explicitement accessible depuis le bouton `…` des écrans de parcours et l'icône pause du gameplay.
