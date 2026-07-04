# 🎮 Module Games & Flame — Documentation vivante

> **Statut** : document de référence pour l'équipe. À tenir **à jour à chaque modification**
> du bounded context `games` (backend) ou de la feature `games` (mobile).
> Voir [Comment maintenir ce document](#-comment-maintenir-ce-document) en bas de page.

Ce module couvre les **jeux sérieux d'évaluation cognitive** de Zennyt : le candidat démarre une
session, joue des mini-jeux, et remonte des **métriques objectives** (jamais un score). Le **score
déterministe est calculé côté serveur** et publié via un Domain Event.

| Jeu | Type (`GameType`) | Fiche | Statut | Rendu |
|-----|-------------------|-------|--------|-------|
| **Planifik — « Je planifie »** | `PLANIFIK` | Planification | 🟢 mini-jeu #1 jouable | Grille tactile **Flame** |
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
| | `domain/vo/GameMetrics.java` | `sealed interface` → `PlanifikMetrics` \| `MoveFastMetrics`. |
| | `domain/vo/PlanifikMetrics.java` | Métriques « Chemin Optimal » + `deviationFromOptimal()`. |
| | `domain/vo/MoveFastMetrics.java` | Métriques « Je bouge » (`correctResponses`, `reactionTimesMs`) + accuracy. |
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

### Schéma DB (`V9__games_schema.sql`)

- `games.game_sessions` : `id`, `player_id`, `game_type`, `status`, `started_at`, `completed_at` + `CHECK` sur type/status, index `(player_id)` et `(game_type, status)`.
- `games.game_attempts` : `session_id` (FK CASCADE), `mini_game`, `raw_points`, `max_points`, `level`, `recorded_at` + `CHECK` mini_game/points, index `(session_id)`.

---

## 📱 MOBILE — Feature `games` (Flutter + Flame)

Racine : `mobile/lib/features/games/` — **Clean Architecture** (domain / data / presentation).
Routage : `mobile/lib/core/router/app_router.dart` (`/games`, `/games/planifik`, `/games/move-fast`).

### Arborescence & rôle de chaque fichier

| Couche | Fichier | Rôle |
|--------|---------|------|
| **domain / entities** | `domain/entities/game_type.dart` | Enum + `wire` (aligné contrat). |
| | `domain/entities/mini_game.dart` | Enum mini-jeux + `wire`. |
| | `domain/entities/game_metrics.dart` | Interface `GameMetrics` (`toJson`). |
| | `domain/entities/planifik_metrics.dart` | Métriques « Chemin Optimal ». |
| | `domain/entities/move_fast_metrics.dart` | Métriques « Je bouge ». |
| | `domain/entities/game_score.dart` | Score noté (immuable). |
| | `domain/entities/game_session.dart` | `GameSession` + `GameAttempt` (miroir de l'agrégat backend). |
| **domain / repo** | `domain/repositories/games_repository.dart` | Port : `startSession`, `submitResult`. |
| **data** | `data/dtos/game_session_dto.dart` | Parse la réponse API → entité domaine. |
| | `data/games_repository_impl.dart` | Impl **Dio** → `/api/v1/games`. Convertit erreurs en `ApiException`. |
| | `data/games_mock_repository.dart` | Impl **MOCK** en mémoire : reproduit le barème serveur → jouable **sans backend**. |
| **presentation** | `presentation/games_providers.dart` | Bascule mock/backend via `--dart-define=GAMES_MOCK` (défaut `true`). |
| | `presentation/games_controller.dart` | `AsyncNotifier<GameSession?>` : `start()` / `submit()`. |
| | `presentation/view/games_hub_screen.dart` | Hub listant les jeux (aussi onglet « Progrès »). |
| | `presentation/view/planifik_screen.dart` | Flow complet **Optimal Path** (intro Path Mind, How To Play, gameplay **multi-niveaux**, score, comparaison) + HUD stations, **menu pause** (`_PauseDialog`), légende, contrôles. Voir [Flow Optimal Path](#-flow-optimal-path-mobile). |
| | `presentation/view/move_fast_screen.dart` | Écran complet « Je bouge » (intro, tutoriels, gameplay **à 3 niveaux**, transitions de règle, résultats). Voir [Niveaux Move Fast](#-niveaux-move-fast-mobile). |
| | `presentation/widgets/game_system_components.dart` | Design system jeux : palette, boutons, HUD, ruban de séries, contrôles directionnels, avion, tuiles de résultat. |
| **presentation / flame** | `presentation/flame/planifik_game.dart` | **`FlameGame`** stations : tracé, `undo`/`clear`, `revision` (HUD live), ligne de route magenta, `buildMetrics()`, layout col×row remplissant. Ne calcule **pas** de score. |
| | `presentation/flame/cell_component.dart` | Station **circulaire** tactile + `BoardPalette` : LAB, MTG, bloc (éclair), étoile, chemin. |
| | `presentation/flame/grid_config.dart` | `CellKind` + `GridConfig` + **4 niveaux progressifs** (`level1`…`level4`, `levels`), `isWalkable`. |

### Le jeu Flame « Chemin Optimal » (`planifik_game.dart`)

- Grille indexée `row * cols + col`, cellules `start / end / obstacle / costly / objective / normal`.
- Le joueur touche des cases **adjacentes** depuis le départ ; retoucher la dernière case = annuler.
- `canValidate` (`ValueNotifier<bool>`) passe `true` quand le chemin atteint l'arrivée.
- `buildMetrics({attempts})` produit des `PlanifikMetrics` : `pathLength`, `costlyZonesAvoided`,
  `secondaryObjectives`, `optimalLength` — **jamais de score** (calculé côté serveur/mock).
- Découplé de Riverpod : le jeu n'appelle aucun provider ; l'écran lit `canValidate` / `buildMetrics`.

### 🗺️ Flow Optimal Path (mobile)

`planifik_screen.dart` est un flow multi-étapes (comme Move Fast), aligné sur les maquettes
Figma **« Optimal Path »**. `enum _PlanifikStage { intro, howToPlay, gameplay, score, comparison }`.

| Étape | Contenu |
|-------|---------|
| **Intro (Path Mind)** | Écran **pixel-perfect** : carte hero violet plein `#4F46E5` (illustration grille `_PathMindArt` + glows roses/cyan), chip « Cognitive Flexibility », 3 mini-cartes meta (Goal/Duration/Format), carte « Simple rule » (bordure périwinkle), **bouton capsule Start**. Marges 24, gaps 20/18/16/22, ombres douces, top-aligné. |
| **How To Play** | Carousel 2 pages (PageView) : « Connect the Stations » (illustration `_StationsArt`) et « Scoring Breakdown » (barème tutoriel). |
| **Gameplay (multi-niveaux)** | Fond violet, **HUD** (Score/Timer/Tries + Pause) + barre de progression, **plateau de stations circulaires** (`GameWidget`), bannière **Correct!/Wrong route!**, légende Start/Goal/Block/★/Path, boutons **Clear / Validate route**. |
| **Score** | Result card (points + niveau) + **Score breakdown panel** (barème reconstruit : chemin optimal 4pts, essais 3pts, zones coûteuses 2pts, bonus 1pt). |
| **Comparison** | Tuiles comparatives : votre route vs optimal, delta, zones coûteuses, bonus, niveau. |

**🎚️ Niveaux progressifs** (`GridConfig.levels`, difficulté croissante) : le joueur enchaîne
level1 → level4 ; une route correcte (**+250**) fait passer au niveau suivant (plus grand,
plus de blocs), une route incomplète donne **−2** et « Wrong route! ». Au dernier niveau →
soumission backend + écran Score. Chaque niveau recrée un plateau frais (`key: ValueKey(_level)`).

| Niveau | Grille | Blocs | Optimal |
|--------|--------|-------|---------|
| level1 | 5×6 | 6 | 9 |
| level2 | 5×7 | 13 | 10 |
| level3 | 5×8 | 12 | 9 |
| level4 | 6×8 | 18 | 12 |

**⏸️ Menu pause** (`_PauseDialog`, calqué sur Move Fast) : stats **Time / Attempts**, options
audio (Sound effects / Music), **Resume** (magenta) / **View rules** (`_OptimalRulesDialog`) /
**Exit mission** (rouge). Le timer se met en pause pendant le dialogue.

**Charte couleurs du plateau** (`BoardPalette`) : LAB (départ) = cercle blanc + anneau bleu,
MTG (arrivée) = vert `#22C55E`, bloc (éclair) = rouge `#E8574C`, étoile = doré `#F5B800`,
station = cyan clair `#CDEBF5`, ligne de route = magenta `#D12E7D`.

> Le **backend est inchangé** : `OPTIMAL_PATH` + `scoreOptimalPath` existent déjà. Le score breakdown
> mobile **reconstruit** le barème à partir des `PlanifikMetrics` pour l'afficher (le serveur ne
> renvoie que `rawPoints/maxPoints/level`).

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
`MoveFastMetrics`, `GameMetrics` (oneOf), `SubmitResultRequest`, `Score`, `Attempt`, `GameSession`.

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
| Optimal Path — **4 niveaux progressifs** + plateau de stations + **menu pause** | 🟢 Fait |
| Move Fast « Je bouge » (écran + barème escalade) | 🟢 Fait |
| Move Fast — 3 niveaux (Orientation → Mouvement → **règle aléatoire**) | 🟢 Fait |
| Planifik #2 `TASK_SCHEDULING`, #3 `PREVISION_PUZZLE` | 🔴 Barème `throw` — non implémenté |
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

**Dernière mise à jour** : 2026-07-04 — Optimal Path : **plateau de stations circulaires**,
**4 niveaux progressifs**, **menu pause** (Time/Attempts + audio), écran **Path Mind pixel-perfect**
(hero violet plein, mini-cartes meta, bouton capsule, ombres douces). Antérieur : flow Optimal Path (intro/briefing/
gameplay/score/comparaison, charte couleurs Figma, undo/clear/validate, warning banner, score
breakdown). Antérieur : niveau 3 Move Fast (règle aléatoire) + améliorations UI ;
génération initiale Planifik « Chemin Optimal » + Move Fast.

> 💡 Astuce équipe : ajoutez ce fichier aux `CODEOWNERS` du dossier `games` et référencez-le dans la
> description de vos PR pour qu'il reste « à la une ».
