# 🎮 Module Games & Flame — Documentation vivante

> **Statut** : document de référence pour l'équipe. À tenir **à jour à chaque modification**
> du bounded context `games` (backend) ou de la feature `games` (mobile).
> Voir [Comment maintenir ce document](#-comment-maintenir-ce-document) en bas de page.

Ce module couvre les **jeux sérieux d'évaluation cognitive** de Zennyt : le candidat démarre une
session, joue des mini-jeux, et remonte des **métriques objectives** (jamais un score). Le **score
déterministe est calculé côté serveur** et publié via un Domain Event.

| Jeu | Type (`GameType`) | Fiche | Statut | Rendu |
|-----|-------------------|-------|--------|-------|
| **Planifik — « Je planifie »** | `PLANIFIK` | Planification | 🟢 mini-jeux #1 et #3 jouables | Flame + écrans Flutter custom |
| **Move Fast — « Je bouge »** | `MOVE_FAST` | Flexibilité cognitive | 🟢 jouable | Écran Flutter custom |
| Memory Quest — « J'investigue » | `MEMORY_QUEST` | Mémoire de travail | 🔴 déclaré, non implémenté | — |
| Choix&Cap — « Je décide » | `DECISION` | Prise de décision | 🔴 déclaré, non implémenté | — |

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
| | `api/dto/GameSessionResponse.java` | Réponse : état complet de la session + score composite + attempts. |
| | `api/dto/ScoreResponse.java` | Sérialisation d'un `Score`. |
| **application** | `application/usecase/StartGameSessionUseCase.java` | Crée l'agrégat `GameSession.start(...)` et le persiste. |
| | `application/usecase/SubmitGameResultUseCase.java` | Charge la session, calcule le `Score` (domaine), enregistre, persiste, **publie les Domain Events après commit**. |
| | `application/command/StartGameSessionCommand.java` | `(playerId, gameType)`. |
| | `application/command/SubmitGameResultCommand.java` | `(sessionId, miniGame, GameMetrics)`. |
| **domain / model** | `domain/model/GameSession.java` | **Racine d'agrégat**. Invariants : 1 résultat/mini-jeu, refus d'un mini-jeu étranger au type, complétion auto + émission d'event au dernier mini-jeu. Java pur. |
| | `domain/model/MiniGame.java` | Enum des mini-jeux + `maxPoints` du barème + `belongsTo(gameType)`. |
| | `domain/model/Attempt.java` | Résultat immuable d'un mini-jeu (`miniGame`, `score`, `recordedAt`). |
| **domain / vo** | `domain/vo/GameType.java` | `PLANIFIK`, `MOVE_FAST`, `MEMORY_QUEST`, `DECISION`. |
| | `domain/vo/SessionStatus.java` | `IN_PROGRESS`, `COMPLETED`, `ABANDONED`. |
| | `domain/vo/Score.java` | VO auto-validant (`rawPoints`, `maxPoints`, `level`) + `normalized()`. |
| | `domain/vo/GameMetrics.java` | `sealed interface` → `PlanifikMetrics` \| `MoveFastMetrics` \| `PrevisionPuzzleMetrics`. |
| | `domain/vo/PlanifikMetrics.java` | Métriques « Chemin Optimal » + `deviationFromOptimal()`. |
| | `domain/vo/MoveFastMetrics.java` | Métriques « Je bouge » (`correctResponses`, `reactionTimesMs`) + accuracy. |
| | `domain/vo/PrevisionPuzzleMetrics.java` | Métriques « Predictive Puzzle » : cible complétée, erreurs, retries, mouvements planifiés/optimaux. |
| **domain / service** | `domain/service/PlanifikScoringService.java` | **Barème déterministe** Planifik + Move Fast + interprétations. Java pur, rejouable. |
| **domain / event** | `domain/event/GameResultRecordedEvent.java` | `games.result.recorded` — **seul** point d'intégration inter-contextes. |
| **domain / repo** | `domain/repository/GameSessionRepository.java` | Port (interface) — le domaine ne connaît jamais JPA. |
| **infrastructure** | `infrastructure/persistence/GameSessionEntity.java` | Entité JPA (table `games.game_sessions`). |
| | `infrastructure/persistence/AttemptEmbeddable.java` | `@Embeddable` (table fille `games.game_attempts`). |
| | `infrastructure/persistence/GameSessionRepositoryAdapter.java` | Implémente le port. **Mappe** agrégat ⇄ entité. |
| | `infrastructure/persistence/JpaGameSessionRepository.java` | Spring Data JPA technique. |
| **intégration** | `../analytics/application/listener/GameResultRecordedListener.java` | Consomme l'event via `@TransactionalEventListener` (Analytics). |
| **DB** | `resources/db/migration/V9__games_schema.sql` | Schéma `games` : tables `game_sessions`, `game_attempts`, index, contraintes `CHECK`. |
| **test** | `test/java/com/zennyt/games/domain/GameSessionTest.java` | 7 tests unitaires de l'agrégat (Java pur, sans Spring). |

### API REST (`/api/v1/games`)

| Méthode | Route | Body | Réponse | Erreurs |
|---------|-------|------|---------|---------|
| `POST` | `/sessions` | `StartSessionRequest { gameType }` | `201` `GameSession` (IN_PROGRESS) | 400, 401 |
| `POST` | `/sessions/{sessionId}/results` | `SubmitResultRequest { miniGame, metrics }` | `200` `GameSession` (mise à jour) | 400, 404 |

Authentification : `bearerAuth` (JWT) — `playerId = jwt.getSubject()`.

### Cycle de vie d'une session

```
start(playerId, gameType) ──► IN_PROGRESS
    │  recordResult(miniGame, score)   (1 par mini-jeu, cohérent avec le type)
    ▼
attempts.size == expectedMiniGames.size ?
    │ oui ──► complete() ──► COMPLETED + registerEvent(GameResultRecordedEvent)
    └ non ──► reste IN_PROGRESS
```

### Barème (`PlanifikScoringService`)

**Planifik #1 « Chemin Optimal » — /10**
- Respect du chemin optimal (±10 %) → **4 pts**
- Nombre d'essais : 1 → 3 pts · 2 → 2 pts · 3+ → 1 pt
- Évitement des zones coûteuses → **2 pts**
- Objectif secondaire atteint → **1 pt**
- Interprétation : 0–3 *Très faible* · 4–6 *Moyen* · 7–10 *Bon à excellent*

**Profil Planifik global — /30** : ≤10 *Très faible* · ≤17 *Moyen faible* · ≤23 *Moyen* · ≤27 *Bon* · sinon *Excellent*

**Move Fast « Je bouge » — barème en escalade**
- Multiplicateur x1 (min) → x10 (max)
- Réponse correcte : `+50 × multiplicateur`
- 4 bonnes réponses consécutives : multiplicateur `+1`, compteur remis à 0
- Erreur avec streak partiel : compteur remis à 0 ; streak vide : multiplicateur `-1` (min x1)
- Bonus final : `+250 × multiplicateur de fin`
- Interprétation (sur 100) : <40 *Très faible* · <60 *Moyen faible* · <75 *Moyen* · <90 *Bon* · sinon *Excellent*

**Planifik #3 « Predictive Puzzle » — /10**
- Cible finale complétée → base **10 pts** ; plan non complété → base **4 pts**
- Erreur de séquence / mouvement illégal → **−2 pts**
- Mouvement inutile au-delà de l'optimal → **−1 pt**
- Retry / réinitialisation du plan → **−1 pt**
- Score clampé entre 0 et 10, interprétation Planifik mini-jeu : 0–3 *Très faible* · 4–6 *Moyen* · 7–10 *Bon à excellent*

### Schéma DB (`V9__games_schema.sql`)

- `games.game_sessions` : `id`, `player_id`, `game_type`, `status`, `started_at`, `completed_at` + `CHECK` sur type/status, index `(player_id)` et `(game_type, status)`.
- `games.game_attempts` : `session_id` (FK CASCADE), `mini_game`, `raw_points`, `max_points`, `level`, `recorded_at` + `CHECK` mini_game/points, index `(session_id)`.

---

## 📱 MOBILE — Feature `games` (Flutter + Flame)

Racine : `mobile/lib/features/games/` — **Clean Architecture** (domain / data / presentation).
Routage : `mobile/lib/core/router/app_router.dart` (`/games`, `/games/planifik`, `/games/move-fast`,
`/games/predictive-puzzle`).
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
| **data** | `data/dtos/game_session_dto.dart` | Parse la réponse API → entité domaine. |
| | `data/games_repository_impl.dart` | Impl **Dio** → `/api/v1/games`. Convertit erreurs en `ApiException`. |
| | `data/games_mock_repository.dart` | Impl **MOCK** en mémoire : reproduit le barème serveur → jouable **sans backend**. |
| **presentation** | `presentation/games_providers.dart` | Bascule mock/backend via `--dart-define=GAMES_MOCK` (défaut `true`). |
| | `presentation/games_controller.dart` | `AsyncNotifier<GameSession?>` : `start()` / `submit()`. |
| | `presentation/view/games_hub_screen.dart` | Hub jeux style maquette Progress : header « Play & discover your talent », couverture, 5 cartes de domaines cognitifs, assets `assets/04 Optimal Path/`, bottom nav via `ProgressScreen`. |
| | `presentation/view/planifik_screen.dart` | Flow complet **Optimal Path** (intro Path Mind, How To Play, gameplay **multi-niveaux**, score, comparaison) + HUD stations, **menu pause** (`_PauseDialog`), légende, contrôles. Voir [Flow Optimal Path](#-flow-optimal-path-mobile). |
| | `presentation/view/move_fast_screen.dart` | Écran complet « Je bouge » (intro, tutoriels, gameplay **à 3 niveaux**, transitions de règle, résultats). Voir [Niveaux Move Fast](#-niveaux-move-fast-mobile). |
| | `presentation/view/predictive_puzzle_screen.dart` | Écran complet **Predictive Puzzle** : intro, règles, planification Tower of Hanoi, exécution auto, résultats, comparaison. Voir [Flow Predictive Puzzle](#-flow-predictive-puzzle-mobile). |
| | `presentation/widgets/game_system_components.dart` | Design system jeux : palette, boutons, HUD, ruban de séries, contrôles directionnels, avion, tuiles de résultat. |
| **presentation / flame** | `presentation/flame/planifik_game.dart` | **`FlameGame`** stations : tracé, `undo`/`clear`, `revision` (HUD live), ligne de route magenta, `buildMetrics()`, layout col×row remplissant. Ne calcule **pas** de score. |
| | `presentation/flame/cell_component.dart` | Station **circulaire** tactile + `BoardPalette` : LAB, MTG, bloc (éclair), étoile, chemin. |
| | `presentation/flame/grid_config.dart` | `CellKind` + `GridConfig` + générateur `GridConfig.randomLevels()` : graphes de grille solvables par BFS, difficulté croissante, fallback déterministe `levels`. |

### Le jeu Flame « Chemin Optimal » (`planifik_game.dart`)

- Grille indexée `row * cols + col`, cellules `start / end / obstacle / costly / objective / normal`.
- Le joueur touche des cases **adjacentes** depuis le départ ; retoucher la dernière case = annuler.
- `canValidate` (`ValueNotifier<bool>`) passe `true` quand le chemin atteint l'arrivée.
- `buildMetrics({attempts})` produit des `PlanifikMetrics` : `pathLength`, `costlyZonesAvoided`,
  `secondaryObjectives`, `optimalLength` — **jamais de score** (calculé côté serveur/mock).
- Découplé de Riverpod : le jeu n'appelle aucun provider ; l'écran lit `canValidate` / `buildMetrics`.

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
  `image 121-1.png`, `image 121-2.png`).
- Routes actives : Cognitive Flexibility → `/games/move-fast`, Executive Planning →
  `/games/planifik`, Decision-Making → `/games/predictive-puzzle`. Les autres domaines sont
  visuels pour l'instant.

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
| **Intro** | Carte hero violette, chip « Predictive Reasoning », titre « Predictive Puzzle », metas Goal/Duration/Format, règle simple et CTA Start. |
| **How To Play** | Deux pages : règle d'or Tower of Hanoi (jamais un grand disque sur un petit), puis planification complète avant action. |
| **Planning** | Fond violet, HUD Timer/Moves/Errors, trois tours A/B/C, feedback source → destination, queue horizontale de mouvements, Undo/Clear/Add Move. |
| **Auto Run** | Les contrôles sont désactivés ; la machine rejoue la queue avec un tick régulier et marque le premier `failed_step_index` visuel. |
| **Results / Comparison** | Même structure que les jeux précédents : score cognitif, tuiles stats, résumé, benchmark optimal 15 mouvements, CTA Replay. |

Logique runtime :

- `selected_source != null` active la sélection de destination.
- `is_legal_move(source, destination)` queue un mouvement valide et met à jour l'état de planning.
- Un mouvement illégal reste visible dans la queue, incrémente `sequenceErrors`, puis fait échouer
  l'exécution au moment du Run.
- `queued_moves.length > 0` et pile cible complète (`C = [4, 3, 2, 1]`) activent **Run Plan**.
- `execution_state == running` désactive les tours et les boutons de planification.
- `final_stacks == target_stacks` soumet `targetCompleted=true`, sinon le plan échoue.

Le mobile soumet `PrevisionPuzzleMetrics` :
`targetCompleted`, `sequenceErrors`, `unnecessaryMoves`, `retries`, `plannedMoves`, `optimalMoves`.
Le backend/mock appliquent le même barème via `scorePrevisionPuzzle`.

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

### 🎚️ Niveaux Move Fast (mobile)

Une session « Je bouge » enchaîne **3 niveaux de difficulté croissante** au sein d'une même
partie (état géré dans `move_fast_screen.dart`). La couleur de l'avion et le libellé de règle
suivent toujours la règle active (`_ruleColor` / `_ruleLabel`), donc le feedback visuel reste
cohérent.

| Niveau | Règle | Déclenchement | Écran de transition |
|--------|-------|---------------|---------------------|
| **1 — Orientation** | fixe : direction du **nez** | départ → `_movementLevelThreshold` (4 bonnes réponses) | — |
| **2 — Mouvement** | fixe : direction du **déplacement** | 4 → `_randomLevelThreshold` (8 bonnes réponses) | `_RuleSwitchView` (1 seule fois) |
| **3 — Règle aléatoire** | **change à chaque avion** (imprévisible) | ≥ 8 bonnes réponses → fin | `_RandomLevelView` (1 seule fois) |

- **Fin de session** : `_targetCorrectAnswers` (12 bonnes réponses), `_maxResponses` (18 essais) ou
  expiration du `_sessionSeconds` (84 s).
- **Randomisation (niv 3)** : `_nextRandomRule()` bascule la règle 2 fois sur 3 et la garde 1 fois
  sur 3 → le joueur ne peut pas anticiper ; teste réellement la flexibilité cognitive.
- Le stage `_MoveFastStage.randomRule` complète la machine à états
  (`intro → tutorials → gameplay ⇄ ruleSwitch/randomRule → results → comparison`).

> Le barème backend/mock (`scoreMoveFast`) est **inchangé** : il rejoue la séquence
> `correctResponses` sans connaître les niveaux — la difficulté est purement côté présentation.

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
2. Le joueur trace le chemin dans `PlanifikGame` ; au clic « Valider » : `buildMetrics(attempts)`.
3. `GamesController.submit(miniGame: optimalPath, metrics)` → `POST /sessions/{id}/results`.
4. **Backend** — `SubmitGameResultUseCase` calcule le `Score` via `PlanifikScoringService`, `recordResult` sur l'agrégat.
5. Au **dernier** mini-jeu du type → session `COMPLETED` + `GameResultRecordedEvent` publié.
6. `GameResultRecordedListener` (Analytics) consomme l'event pour le tableau de bord cognitif.

---

## ✅ Statut & roadmap

| Élément | Statut |
|---------|--------|
| Planifik #1 « Chemin Optimal » (Flame + barème + persistance) | 🟢 Fait |
| Optimal Path — flow complet mobile (intro Path Mind, How To Play, gameplay, score, comparaison) | 🟢 Fait |
| Optimal Path — **4 niveaux randomisés par graphe BFS** + plateau de stations + **menu pause** | 🟢 Fait |
| Move Fast « Je bouge » (écran + barème escalade) | 🟢 Fait |
| Move Fast — 3 niveaux (Orientation → Mouvement → **règle aléatoire**) | 🟢 Fait |
| Hub Games / Progress — maquette 5 domaines cognitifs + assets `04 Optimal Path` + bottom nav conservée | 🟢 Fait |
| Planifik #3 `PREVISION_PUZZLE` — Predictive Puzzle | 🟢 Fait |
| Planifik #2 `TASK_SCHEDULING` | 🔴 Barème `throw` — non implémenté |
| `MEMORY_QUEST`, `DECISION` | 🔴 Déclarés au contrat, non implémentés |
| Bascule mock ⇄ backend | 🟢 `--dart-define=GAMES_MOCK` |
| Intégration Analytics (event) | 🟢 Listener en place (log ; à brancher au vrai dashboard) |

---

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

**Dernière mise à jour** : 2026-07-05 — Predictive Puzzle implémenté
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
