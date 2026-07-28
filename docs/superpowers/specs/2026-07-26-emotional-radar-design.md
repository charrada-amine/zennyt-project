# Emotional Radar — Design (Games / Régulation émotionnelle)

> Statut : spec validée avec le demandeur le 2026-07-26, avant implémentation.
> Module concerné : `games` **uniquement** (backend + contrat + mobile). Voir `AGENTS.md` §1.
> Source de vérité visuelle : `04 Emotional Radar/` (20 planches Figma).

## 1. Objectif

Cinquième domaine cognitif de Zennyt — **régulation émotionnelle**. Le candidat observe une scène
(dialogue, texte, image ou vidéo), identifie la **famille d'émotion**, précise la **nuance**, puis
évalue l'**intensité** sur 5 niveaux. Le barème est déterministe et calculé **côté serveur**.

Nouveauté architecturale par rapport aux quatre jeux existants : **le contenu des scènes vit dans
le backend** (texte, image, vidéo) et non dans l'app. C'est le premier jeu du module dont le
matériel est servi par l'API.

## 2. Périmètre

| Inclus | Exclu |
|--------|-------|
| Backend `games` : type, mini-jeu, barème, catalogue, médias, endpoints | Tout autre bounded context |
| `contracts/games.openapi.yaml` (contract-first) | `web/` (React) — explicitement hors périmètre |
| Mobile `mobile/lib/features/games/**` + parité mock | `pom.xml` / `pubspec.yaml` |
| Migration `V25` | Modification d'une migration existante |

## 3. Nommage

- `GameType.EMOTIONAL_REGULATION` — le domaine cognitif (« Je gère »), 5ᵉ carte du hub.
- `MiniGame.EMOTIONAL_RADAR_CORE` — le jeu lui-même.

Le type porte le **domaine** et non le jeu, sur le modèle de `PLANIFIK` qui héberge trois mini-jeux :
d'autres mini-jeux de régulation émotionnelle pourront s'y rattacher sans nouveau `GameType`.

## 4. Boucle de jeu

Déduite de « Prototype logic » (planche *Developer handoff*) :

```
Cover → Tutorial/Rules → Gameplay ──► [ émotion → nuance → intensité → Validate ]
                                            │
                                     Feedback (correct | incorrect)
                                            │
                                   Next scene ──► … ──► Results
```

Overlays disponibles depuis le gameplay : **Pause** (mode d'entrée, audio, resume, règles, quitter),
**Pause/Help** (rappel des 5 étapes, sans pénalité), **Fullscreen** pour les scènes image.

**Révélation progressive** (planche *Developer handoff*) :
- Étape 2 (nuance) affichée seulement après `selectedEmotion != null` ; sinon état **Locked**.
- Étape 3 (intensité) affichée seulement après `selectedNuance != null` ; sinon **Locked**.
- `Validate` actif seulement si les trois sont renseignés et `isValidated == false`.
- Après validation, le feedback **remplace la zone de réponse**, la scène restant visible.

## 5. Barème (`EmotionalRadarConfig`, Java pur)

Par scène, d'après la carte *Scoring* du handoff :

| Critère | Points | Règle |
|---------|--------|-------|
| Émotion de base | **3** | famille exacte, sinon 0 |
| Nuance | **4** | nuance exacte, sinon 0 |
| Intensité | **2** | `\|réponse − attendue\|` : 0 → 2 pts · 1 → 1 pt · ≥2 → 0 |
| Gradient bonus | **+1** | **désactivé par défaut** (`GRADIENT_BONUS_ENABLED = false`) |

**Total = 9 points par scène.** Les deux totaux affichés par Figma se recoupent exactement :
`9 × 3 = 27` (échantillon Phase 2) et `9 × 15 = 135` (jeu complet). Le `Score` du domaine refuse
`rawPoints > maxPoints`, donc activer le bonus imposerait 10/scène et casserait ces deux totaux :
il est implémenté mais neutralisé derrière une constante unique.

`MiniGame.EMOTIONAL_RADAR_CORE.maxPoints = 0` (barème **dynamique**, comme `MOVE_FAST_CORE`) ; le
`Score` porte `scenesPlayed × 9`. Les bandes d'interprétation s'appliquent sur `Score.normalized()`.

## 6. La clé de correction ne quitte jamais le serveur

`AGENTS.md` §7.4 : le client mesure, le serveur note. Or les maquettes exigent un feedback
**après chaque scène** (émotion attendue, nuance attendue, intensité suggérée, explication).
Résolution — **notation par scène côté serveur** :

```
GET  /games/sessions/{id}/emotional-radar/scenes
     → prompt, média, options ; AUCUNE réponse attendue dans le payload

POST /games/sessions/{id}/emotional-radar/scenes/{sceneId}/answers
     → { selectedEmotion, selectedNuance, selectedIntensity }
     ← { correct, expectedEmotion, expectedNuance, suggestedIntensity,
         explanation, scenePoints, totalPoints }
     Le serveur note ET persiste la réponse.

POST /games/sessions/{id}/results                       (endpoint existant, inchangé)
     → EmotionalRadarMetrics : UNIQUEMENT des mesures comportementales
```

`EmotionalRadarMetrics` ne transporte **aucune réponse ni aucun point** — seulement ce que le
serveur ne peut pas observer : `responseTimeMs`, `helpOpened`, `fullscreenOpened`, `reducedMotion`
par scène. Les points proviennent des réponses que le serveur a lui-même notées et persistées :
un payload final falsifié ne change donc rien au score.

La récupération des scènes est **scopée à la session** : le serveur fige l'ensemble des scènes de
cette session, ce qui ancre la notation ultérieure.

## 7. Catalogue de scènes

Port `EmotionalRadarSceneCatalog` (patron `DecisionScenarioCatalog`), implémentation lisant la base.

**Trois scènes rédigées** sont livrées (les seules dont Figma fournit le contenu) :

| # | Type | Prompt | Réponse attendue |
|---|------|--------|------------------|
| 1 | Dialogue | *Friend: "I am sorry, I have to cancel tonight."* | Sadness / Disappointment / 3 |
| 2 | Text | *You hear a strange noise at night while alone at home.* | Fear / Anxiety / 4 |
| 3 | Image | *A child cries alone in a quiet courtyard.* | Sadness / Empathic pain / 3 |

`TOTAL_SCENES` est une constante de configuration (**3** aujourd'hui, 15 quand le psychologue
livrera le contenu). Les 12 scènes manquantes ne sont **pas inventées** (`AGENTS.md` §4).

### Contradiction Figma tranchée (scène 3)

La table *Phase 2 scene answer data* indique `Joy → Triumph → 4`. Trois autres planches indiquent
`Sadness → Empathic pain → 3` : *Dark Mode Support*, layout tablette et layout desktop de
*Responsive reimagination* — cette dernière précisant « The scene is interpersonal and silent. The
answer should capture sadness observed in someone else. » Trois planches contre une, et la
justification textuelle est cohérente avec le prompt → **`Sadness / Empathic pain / 3` retenu**,
divergence tracée dans « Décisions à valider ».

## 8. Taxonomie des nuances

Figma ne documente complètement que **Sadness** (Disappointment, Nostalgia, Empathic pain,
Sympathy, Guilt), plus des nuances isolées pour **Fear** (Anxiety) et **Joy** (Excitement, Triumph).
**Anger, Disgust et Surprise n'ont aucune liste**, alors que les six familles sont sélectionnables
dès l'étape 1 — un joueur choisissant Anger tomberait sur une étape 2 vide.

Décision du demandeur : compléter avec les **sous-catégories standard d'Ekman**. Ce contenu est
**psychométrique et non validé** → il est isolé dans `EmotionalRadarProvisionalRules`, chaque entrée
commentée `// PROVISOIRE — à valider`, sur le modèle strict de `DecisionProvisionalRules`. Le
moteur de notation ne connaît jamais ces valeurs en dur ; les remplacer ne touche pas au moteur.

Les nuances issues de Figma sont marquées comme telles et **ne doivent pas** être écrasées lors de
l'arbitrage du psychologue.

## 9. Médias

`GamesMediaStoragePort` + `CloudinaryGamesMediaStorageAdapter`, exactement comme `identity` et
`engagement` possèdent chacun le leur au-dessus du bean partagé `CloudinaryConfig`. Aucune
dépendance ajoutée, aucun code d'un autre module appelé.

- Types : `DIALOGUE`, `TEXT`, `IMAGE`, `VIDEO`.
- Les lignes de scène portent `media_url` + `media_public_id`.
- **`alt_text` obligatoire** pour IMAGE et VIDEO, **`transcript` obligatoire** pour VIDEO : la
  planche *Accessibility Compliance* impose « Scene media needs alt text or text equivalent; future
  video needs subtitles/transcript ». Contrainte portée par le domaine, pas seulement par la DB.

## 10. Schéma — `V25__games_emotional_radar.sql`

- `games.emotional_radar_scenes` — `id`, `scene_order`, `media_type`, `prompt_text`,
  `instruction_text`, `media_url?`, `media_public_id?`, `alt_text?`, `transcript?`,
  `expected_emotion`, `expected_nuance`, `expected_intensity`, `explanation`, `active`.
- `games.emotional_radar_nuances` — `emotion`, `nuance_key`, `display_order`, `source`
  (`FIGMA` | `PROVISIONAL`).
- `games.emotional_radar_answers` — PK `(session_id, scene_id)`, `selected_emotion`,
  `selected_nuance`, `selected_intensity`, `correct`, `points`, `answered_at`.
- Extension des `CHECK` : `game_sessions.game_type` += `EMOTIONAL_REGULATION`,
  `game_attempts.mini_game` += `EMOTIONAL_RADAR_CORE`.

Aucune migration existante n'est modifiée.

## 11. Imperfections de maquette corrigées

| # | Constat | Correction |
|---|---------|------------|
| 1 | Scène 3 : réponse contradictoire entre 4 planches | `Sadness / Empathic pain / 3` (§7) |
| 2 | Carte d'échec : « Your answer » affiche `Joy / Excitement / 2` mais « Best answer » omet l'intensité | les deux lignes en `famille / nuance / niveau` |
| 3 | Carte de succès : copie différente en clair (« You identified… ») et en sombre (« The emotional pattern was… ») | voix active du mode clair partout |
| 4 | Le score reste à `Score 0` sur la carte de feedback ; il ne passe à 9 qu'à la scène suivante — alors que la planche sombre l'incrémente sur la carte (9 → 18) | mise à jour dès la validation |
| 5 | CTA de feedback : « Next scene » en clair, « Continue » en sombre | « Next scene » partout |

## 12. Mobile

`emotional_radar_screen.dart` dans `mobile/lib/features/games/presentation/view/`, réutilisant
`game_system_components.dart` (aucun bouton/HUD/pause redupliqué — `AGENTS.md` §5). Machine d'états
`cover → tutorial → gameplay → feedback → transition → results`, alignée sur la boucle §4.

Contrainte d'accessibilité portée par l'UI (planche dédiée) : cibles ≥ 48×48 px espacées de 8 px,
contraste 4.5:1, **jamais de sens porté par la couleur seule** (icône + libellé + bordure),
transitions 200–300 ms, mouvement réduit respecté, résultats **text-first**.

Le mode mock reproduit le barème à l'identique pour rester jouable hors-ligne, mais il ne peut pas
reproduire le catalogue serveur : il embarque les 3 scènes rédigées, avec un commentaire croisé
mock ⇄ backend comme l'exige `AGENTS.md` §7.7.

## 13. Tests

Backend (Java pur, sans Spring) :
- barème par scène : parfait 9/9, famille fausse → 0/3, intensité ±1 → 1 pt, ±2 → 0
- agrégation : 3 scènes parfaites → 27/27 ; bonus gradient désactivé → jamais 10/scène
- la clé de correction n'apparaît dans aucun DTO de scène (test de sérialisation)
- un payload final falsifié ne modifie pas le score (points issus des réponses persistées)
- `alt_text` manquant sur IMAGE/VIDEO → rejet du domaine
- complétion de session → `GameResultRecordedEvent`

Mobile : parité mock (mêmes 9 points par scène), révélation progressive (étapes verrouillées),
`Validate` inactif tant que les trois choix ne sont pas faits.

## 14. Décisions à tracer dans `GAMES_MODULE.md`

| # | Point | Choix | Référence |
|---|-------|-------|-----------|
| 20 | Barème intensité 2/1/0 selon l'écart | dérivé de « calibration quality » | Figma dit seulement « Intensity 2 pts » |
| 21 | Gradient bonus désactivé | sinon 10/scène, incompatible avec 27 et 135 | Figma : « +1 optional » |
| 22 | Nuance tout-ou-rien (4/0) | pas de crédit partiel pour bonne famille / mauvaise nuance | non spécifié |
| 23 | Scène 3 = Sadness/Empathic pain/3 | 3 planches contre 1 | contradiction Figma |
| 24 | Nuances Anger/Disgust/Surprise | sous-catégories Ekman, couche provisoire isolée | absentes de Figma |
| 25 | `TOTAL_SCENES` = 3 | 15 dans l'UI, 3 scènes rédigées | Phase 3 |

## 15. Points ouverts

- **Autorisation de l'upload média** : aucun rôle admin n'existe dans `games`. L'endpoint d'upload
  est authentifié, mais qui a le droit d'écrire dans le catalogue reste à trancher.
- Les 12 scènes manquantes et leur étiquetage attendent le psychologue.
- Le contrat `GameMetrics` passera de 6 à 7 membres du `oneOf` : le changelog (30) signale une NPE
  non fatale du normaliseur openapi-generator 7.5.0 **à exactement 6 membres** — à revérifier au build.
