# Emotional Radar v2 — Intégration (Cowen & Keltner, 45 émotions, difficulté adaptative, theta/IRT)

Refonte scientifique du jeu « Emotional Radar » selon le brief du 2026-08-12
(`Tableaux_Radar_emotionnel_6-6-9-9_numerote.pdf`). Passe du modèle **Ekman 6
émotions** (issu de la maquette Figma) à **Cowen & Keltner + littérature, 45
émotions**, difficulté **adaptative** à deux axes (charge de choix 6/6/9/9 + distance
sémantique), et **double score** : score « jeu » (`radar_emotion_score`, visible,
utilisable) + score « décisionnel » `theta` (IRT, **verrouillé** tant que non calibré).

Ce document liste ce qui reste à faire — **destiné à codex sol** — après le socle
livré ci-dessous.

---

## ✅ Déjà livré (socle, backend + logique mobile — compile / vérifié)

**Backend — cœur de domaine (Java pur, `mvn compile` OK, vérifié à l'exécution)**
- `resources/games/emotional_radar_emotions.json` — **référentiel 45 émotions**
  (18/20/3/4), catégories + type de stimulus + coordonnées valence/arousal **PROVISOIRES**.
- `domain/vo/` : `EmotionCategory`, `StimulusType`, `EmotionDefinition`,
  `DistanceBand`, `DifficultyLevel`, `RadarSceneOutcome`, `RadarThetaEstimate`,
  `EmotionalRadarV2Report`.
- `domain/catalog/EmotionReferential` (port) + `infrastructure/catalog/JsonEmotionReferential` (`@Component`).
- `domain/service/` : `SemanticDistanceModel` + `ValenceArousalDistanceModel`,
  `DistractorSelectionService`, `AdaptiveDifficultyService`, `RadarGameScoreService`,
  `ThetaIrtService` (2PL MLE, **isolé, verrouillé**), `EmotionalRadarV2ReportService`.
- `domain/config/` : `EmotionalRadarV2Config`, `EmotionalRadarV2ProvisionalRules`.
- Test : `test/.../domain/EmotionalRadarV2Test.java` (⚠️ non exécuté — voir Blocage CI).

**Mobile — miroir logique (Dart, `flutter analyze` clean)**
- `lib/features/games/domain/config/emotional_radar_v2_config.dart`
- `.../emotional_radar_v2_provisional_rules.dart`
- `.../emotional_radar_v2_referential.dart` (45 émotions + distance + distracteurs +
  adaptatif + score jeu, miroir déterministe du backend).

**Non touché volontairement** : l'ancien Emotional Radar (`EmotionalRadarConfig`,
`BasicEmotion`, `EmotionalRadarScoringService`, écran mobile) reste en place et
fonctionnel pour ne rien casser tant que le câblage v2 n'est pas terminé (tâches ci-dessous).

---

## ⛔ Blocage CI préalable (hors périmètre Radar, à traiter d'abord)
La branche `Games-Progress` a des **marqueurs de conflit de merge committés** dans :
- `backend/src/test/java/com/zennyt/recruitment/infrastructure/ai/FitScoreBaselineTest.java`
- `backend/src/test/java/com/zennyt/recruitment/infrastructure/ai/DeterministicFitScoreCalculatorTest.java`

Tant qu'ils ne sont pas résolus, **aucune compilation de tests** ne passe (donc
`EmotionalRadarV2Test` non plus). Résoudre le merge (choisir la bonne baseline Fit
Score) avant d'aller plus loin.

---

## 🎬 Tâches ASSETS — génération vidéo IA (à faire par codex sol)
1. **135 vidéos** = 45 émotions × 3 intensités (Faible / Modérée / Intense).
   - Cadrage selon `stimulusType` : `FACIAL` gros plan 5–6 s ; `BODY`/`SOCIAL`/
     `CONTEXTUAL` plan large 6–8 s.
   - `SOCIAL` = plusieurs personnages : générer plusieurs variantes, **sélection
     manuelle** de la meilleure.
   - `CONTEXTUAL` : **légende contextuelle** dans l'UI (jamais incrustée à la vidéo).
   - `SEXUAL_DESIRE` (`sensitive_content_flag`) : cadrage pudique, validation éditoriale.
2. **Accessibilité** (obligatoire, cf. domaine actuel) : `altText` + `transcript`
   pour chaque vidéo.
3. **Diversité** des personnages (âge, origine, genre) suivie sur les 135 vidéos.
4. **Norming** : chaque vidéo validée par un panel (accord inter-juges **Kappa ≥ 0.70**)
   avant `norming_status = validé`. Vidéos rejetées → renvoyées en production.

## 🎨 Tâches UI / écrans (à faire par codex sol) — Flutter
Remplacer/refondre `emotional_radar_screen.dart` + `emotional_radar_gameplay.dart` :
5. Écran de jeu **adaptatif** : afficher N choix selon le niveau (6 ou 9, grille 3×3
   en L3/L4), la vidéo, la légende contextuelle si `CONTEXTUAL`.
6. Saisie **intensité perçue** (Faible/Modérée/Intense) + **justification textuelle**
   (`require_explanation`, notée 0–5 côté serveur).
7. Timer **8 000 ms** max / plancher impulsif **400 ms**.
8. Retour de progression « façon jeu vidéo » : niveau atteint + score `radar_emotion_score`
   /10 (`emotional_level` Faible/Moyen/Élevé). **Ne jamais** afficher le theta.
9. Écran de résultats : accuracy par niveau / par nombre de choix / par distance
   sémantique (les deux axes), correspondance d'intensité, temps, impulsivité.
10. Câbler le state machine sur `nextLevel(...)` (mobile) et `buildChoices(...)` pour
    le mode offline/mock ; **le serveur reste autoritaire** sur le score.
11. **Objets/illustrations à générer** (icônes d'émotions, états, badges) : à produire.

## 🗄️ Tâches BACKEND — persistance & contrat (à faire par codex sol)
12. **DB (Flyway)** : nouvelle table `games.emotional_radar_v2_scenes` (émotion jouée,
    intensité, `stimulus_type`, `media_url`, `alt_text`, `transcript`, `norming_status`,
    `character_diversity_*`) + table réponses notées (`radar_scene_outcomes`) portant
    les champs de `RadarSceneOutcome`. Étendre le CHECK `game_attempts` si besoin.
13. **OpenAPI** (`contracts/*.yaml`) : schémas `EmotionalRadarV2SceneResponse` (sans clé
    de correction), `EmotionalRadarV2AnswerRequest` (emotionKey, intensité, justification,
    temps), `EmotionalRadarV2Indicators` (mapper `EmotionalRadarV2Report`). Régénérer.
14. **Use cases / contrôleur** : `GetV2ScenesUseCase` (tire une session adaptative de
    15 scènes, sélection de distracteurs serveur), `AnswerV2SceneUseCase` (corrige,
    persiste `RadarSceneOutcome`, calcule le prochain niveau), submit → `radar_emotion_score`.
15. **Catalogue de scènes v2** adossé DB (comme `DatabaseEmotionalRadarSceneCatalog`),
    filtrant sur `norming_status = validé`.

## 🔗 Tâches d'INTÉGRATION scoring (attention au couplage — cf. « Je Décide »)
16. **Composite émotionnel** : aujourd'hui `/37` (Radar 27 + Reflective 10). Le score
    Radar devient `radar_emotion_score` /10 (ou une normalisation /100). Recalculer le
    composite `EMOTIONAL_REGULATION` et **re-baseliner** `ScoreBreakdownService` + les
    tests. Ripple possible sur le module `EMOTIONAL_REGULATION` du Fit Score
    (`SoftSkillModule` / `FitScoreBaselineTest`) — **documenter chaque écart**.
17. Décider du sort de l'ancien Radar (6 émotions) : le retirer une fois v2 câblé
    (supprimer `BasicEmotion`/`EmotionalRadarConfig`/scoring + écrans + parité mock).

## 🔬 Tâches CONTENU / SCIENCE (psychologue — à tracer, pas à inventer)
18. **Finaliser les 45 émotions** : valider la liste, les 14 faciales implicites, la
    répartition 18/20/3/4, et **remplacer les coordonnées valence/arousal placeholder**
    par l'espace sémantique **réel de Cowen & Keltner** (dans `emotional_radar_emotions.json`).
19. Confirmer `DistanceBand` (Élevée/Moyenne/Faible), les seuils 70 %/40 %, la fenêtre 3–4.

## 📏 Tâches CALIBRATION (theta — avant tout usage décisionnel, brief §4)
Tant que non fait, `EmotionalRadarV2ProvisionalRules.DECISIONAL_USE_ALLOWED` reste
`false` et le theta n'est **jamais** comparatif/RH/clinique.
20. Norming stimuli (Kappa ≥ 0.70) → 21. Collecte pilote (plusieurs centaines) →
    22. Difficulté empirique (remplace la distance théorique) → 23. Estimation IRT (2PL,
    discrimination/difficulté par item) → 24. Fiabilité (α ≥ 0.80) → 25. Validation
    externe (GERT/MSCEIT) → 26. Basculer `calibration_status = Validé` et
    `decisional_use_allowed = true`.

---

### Références de valeurs (brief) déjà encodées dans le socle
`choices_per_level` 6/6/9/9 · `target_distance_per_level` Élevée/Moyenne/Élevée/Faible ·
`level_up` 70 % · `level_down` 40 % · fenêtre 3–4 · `total_scenes` 15 ·
`max_response_time_ms` 8000 · `min_impulsive_time_ms` 400 · `min_items_for_reliable_theta`
20 · modèle IRT 2PL · `emotion_pool_size` 45 · `video_library_size` 135.
