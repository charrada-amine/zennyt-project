# Jeux de décision comportementaux — BART + IST (Batch 1)

> **Statut** : design validé en séance de brainstorming, non implémenté.
> **Date** : 2026-09-17
> **Module** : `games` (backend + mobile + contrat)
> **Décision structurelle** : approche A — un nouveau `GameType` hébergeant deux mini-jeux.

---

## 1. Contexte et motivation

### 1.1 Ce qui existe aujourd'hui dans la catégorie décision

`GameType.DECISION` héberge **un seul** mini-jeu, `DECISION_CORE` (« Je Décide ») :

- test de jugement situationnel à vignettes ;
- 5 dimensions (`II` analyse, `ER` émotion dans la décision, `DT` décision sous temps,
  `CS` cohérence/stabilité, `RE` responsabilité), 6 items chacune ;
- item /3 → dimension /18 → brut /90 → **SCW /100** ;
- banque de 120 items en base (V59), forme A de 30 items servie sans clé de correction ;
- seule `DT` dépend du temps : limite effective `7 s × multiplicateur_langue + calibration_offset` ;
- garde-fous de validité de session (`avgTimePlausible`, `impulsiveRateOk`,
  `randomResponseRateOk`, `deviceLatencyWithinNorm` → `sessionUsable`).

### 1.2 Le manque

Toute la catégorie décision est **déclarative** : le joueur dit ce qu'il *ferait*. Aucun paradigme
**comportemental** n'existe dans `DECISION`. Rien ne mesure la préférence révélée face au risque,
ni la quantité d'information achetée avant de s'engager, ni l'apprentissage par le feedback.

C'est précisément là que vivent les paradigmes validés du domaine public. Ce design en implémente
deux, choisis pour leur validité par unité d'effort et leur adéquation aux patterns déjà en place
dans le module.

### 1.3 Route de validation retenue

**Proposition depuis la littérature → couche `PROVISOIRE` → validation ultérieure.** C'est la route
suivie pour « Je coordonne » et « Je place » : les jeux sont jouables immédiatement, chaque constante
non validée vit dans un fichier isolé marqué `// PROVISOIRE`, et l'événement Fit Score reste
**suspendu** jusqu'à validation du barème (précédent « Je place »).

**La ligne de propriété intellectuelle porte sur les normes, pas sur les paradigmes.** BART et IST
sont publiés et librement implémentables. Ce qui ne peut pas être emprunté, ce sont les *données
normatives* d'une batterie commerciale (l'IST sous marque CANTAB, l'IGT via PAR Inc.). Le module
tient déjà cette discipline — la correction Long Rosvold note « aucune norme Conners utilisée ».
Même règle ici : notation propre, en couche provisoire, jusqu'à validation par le psychologue.

---

## 2. Décision structurelle : pourquoi un nouveau `GameType`

### 2.1 Ce qui a été écarté, et pourquoi

Ajouter les nouveaux mini-jeux **sous `GameType.DECISION`** casse un jeu déjà livré.
`GameSession.expectedMiniGames()` dérive la complétion de session de *tous* les mini-jeux jouables
du type :

```java
public List<MiniGame> expectedMiniGames() {
    return Arrays.stream(MiniGame.values())
        .filter(m -> m.belongsTo(gameType) && m.isPlayable())
        .toList();
}
```

Passer cet ensemble de 1 à 3 pour `DECISION` produit deux régressions immédiates :

1. une session « Je Décide » n'atteint plus `COMPLETED` après `DECISION_CORE` ;
2. `coverageRatio()` tombe de 100 à 33, ce qui alimente la décote de couverture du Fit Score
   (CdC §3.3).

C'est exactement la raison pour laquelle `CONTINUOUS_ATTENTION`, `VISUOMOTOR_COORDINATION` et
`VISUOSPATIAL_MEMORY` ont chacun été isolés dans leur propre `GameType` plutôt que fondus dans
`MOVE_FAST` / `MEMORY_QUEST` — les commentaires de l'enum le disent explicitement (« Ce type reste
distinct de MOVE_FAST afin de préserver l'agrégat, le barème et les événements historiques »).

### 2.2 Ce qui est retenu

Un nouveau `GameType.DECISION_BEHAVIORAL` hébergeant **deux** mini-jeux, sur le modèle de `PLANIFIK`
qui en héberge trois :

| Élément | Valeur |
|---|---|
| `GameType` | `DECISION_BEHAVIORAL` *(nom à arbitrer, voir §9)* |
| Mini-jeu 1 | `BART_CORE` — risque révélé |
| Mini-jeu 2 | `INFORMATION_SAMPLING_CORE` — recueil d'information |
| Profil | composite des deux mini-jeux, `coverageRatio` réel |
| Domaine d'affichage mobile | carte **Decision Making** existante, à côté de « Je Décide » |

`GameType.DECISION` n'est pas touché : il garde sa complétion, son SCW /100 et son historique
d'événements. Les schémas admin `SETTINGS` / `MODIFIERS` sont générés automatiquement pour tout
nouveau `GameType` par `AdminConfigurationSchemaRegistry` — rien à écrire de ce côté.

Le placement « nouveau type, domaine d'affichage existant » reprend celui de « Je place », affiché
sous **Working Memory** sans renommer le domaine.

---

## 3. Protocole BART (`BART_CORE`)

Référence : Lejuez et al. (2002), *Journal of Experimental Psychology: Applied* — Balloon Analogue
Risk Task.

### 3.1 Tâche

- **30 essais** (ballons). 2 ballons d'entraînement, **exclus de la notation** (précédent : essais
  d'échauffement Move Fast).
- Chaque *pompe* ajoute des points à une réserve temporaire.
- Le ballon éclate à un numéro de pompe prédéfini → la réserve temporaire est **perdue**, l'essai
  se termine.
- « Collecter » transfère la réserve temporaire vers la banque permanente.
- Point d'éclatement tiré uniformément sur `1..128` : la probabilité d'éclatement à la pompe *k*
  vaut `1 / (128 − k + 1)`. Paramétrage standard de Lejuez.

### 3.2 Ce que le serveur possède, et pourquoi c'est structurant

Les 30 points d'éclatement sont générés **côté serveur**, de façon déterministe, avec une graine
dérivée de `sessionId` + version de protocole — le pattern de
`ContinuousAttentionSequenceGenerator` et `ObjectLocationLayoutGenerator`.

Le client envoie, par essai : nombre de pompes, issue (`COLLECTED` / `EXPLODED`), horodatage de
chaque pompe. Le serveur **rejoue** l'essai contre sa propre séquence (pattern
`ObjectLocationActionReplayer`) et rejette toute réclamation impossible — un client ne peut pas
déclarer avoir collecté à la pompe 40 sur un ballon qui éclate à 12.

L'anti-triche découle de l'architecture (AGENTS.md §7.4 : le client mesure, ne calcule jamais), il
n'est pas rajouté après coup.

### 3.3 Mesures

| Mesure | Rôle |
|---|---|
| **Pompes moyennes ajustées** | Moyenne des pompes sur les ballons **collectés uniquement** — les essais éclatés sont tronqués et biaisent la moyenne brute. Indice standard d'appétence au risque. |
| Nombre d'éclatements | Descriptif |
| Gains totaux | Entre dans le score (§3.4) |
| Ajustement après éclatement | Sensibilité à la perte |
| Ajustement après collecte | Sensibilité au gain |
| Trajectoire essai par essai | Adaptation au fil de la session |

### 3.4 Notation — le problème, et sa résolution

**Le problème.** Les pompes moyennes ajustées sont un **trait**, pas une performance : élevé =
enclin au risque, bas = averse au risque, et **aucun des deux pôles n'est « meilleur »**. Un score
/100 sur cet axe serait psychométriquement faux ; même étiqueté « descriptif /100 » comme le font
« Je coordonne » et « Je place », il sous-entendrait un classement que la mesure ne supporte pas.

**La résolution.** Parce que le serveur connaît la séquence d'éclatement, il peut calculer ce que la
stratégie **optimale en espérance (EV)** aurait rapporté sur cette séquence exacte, et noter le
joueur en **efficience de gains** par rapport à elle. Cet axe *est* valide en performance : l'excès
de prudence **comme** l'excès de risque coûtent des points. Les pompes moyennes ajustées restent à
côté, en indicateur d'appétence au risque purement **descriptif et non classé**.

**Définition exacte du benchmark — point critique d'implémentation.** Le benchmark est la
**meilleure stratégie fixe connaissant la loi**, pas une stratégie clairvoyante connaissant la
séquence. Distinction structurante :

- ❌ **Pas** « pomper `point_éclatement − 1` fois à chaque essai ». Cette stratégie suppose une
  connaissance parfaite de l'avenir ; tout joueur humain obtiendrait un score dérisoire contre elle,
  et la mesure ne discriminerait plus rien.
- ✅ **Le nombre de pompes `n*` qui maximise l'espérance de gain sous la loi uniforme `1..128`.**
  `EV(n) = n × valeur_pompe × (128 − n) / 128`, maximisée à **`n* = 64`**. Le benchmark est donc
  « pomper 64 fois puis collecter, à chaque essai », **évalué sur la séquence effectivement servie**
  au joueur — un essai dont le point d'éclatement est ≤ 64 rapporte 0 au benchmark comme il aurait
  rapporté 0 au joueur. Le benchmark subit donc exactement la même chance que le joueur.

```
ev_optimal_earnings = Σ  (n* × valeur_pompe)  si point_éclatement(essai) > n*
                      essais notés            sinon 0

efficiency_percent  = min(100, roundHalfUp(total_earnings / ev_optimal_earnings × 100))
```

Le plafond à 100 est nécessaire : un joueur chanceux peut dépasser le benchmark sur une séquence
donnée. Si `ev_optimal_earnings == 0` (séquence dégénérée, tous les éclatements ≤ `n*`), la session
est marquée invalide et part en run audit-only — c'est un défaut de la séquence, pas du joueur.

> ⚠️ **PROVISOIRE** — la formulation en efficience EV, le plafond à 100 et le traitement de la
> séquence dégénérée sont des constructions propres à ce design, issues d'aucune publication. Elles
> vivent dans `BartProvisionalRules` et figurent en tête de la liste du psychologue (§9).

**Score `BART_CORE` = /100** — efficience de gains vs. la stratégie fixe optimale en espérance,
évaluée sur la séquence servie.

---

## 4. Protocole IST (`INFORMATION_SAMPLING_CORE`)

Référence : Clark et al. (2006) — Information Sampling Task.

### 4.1 Tâche

- Grille **5×5 = 25 cases** couvertes, chacune cachant l'une de deux couleurs.
- Le joueur ouvre les cases **une par une**, puis décide quelle couleur est **majoritaire** parmi
  les 25.
- **20 essais**, deux conditions de 10 :

| Condition | Règle | Ce qu'elle isole |
|---|---|---|
| **Fixed win** (FW) | 100 points si correct, quel que soit le nombre de cases ouvertes | Échantillonnage **gratuit** |
| **Decreasing win** (DW) | Le gain part de 250 et perd 10 points par case ouverte | Échantillonnage **coûteux** |

- Réponse incorrecte : **−100** dans les deux conditions.
- 1 essai d'entraînement par condition, exclu de la notation.

Les dispositions de grille sont générées serveur, déterministes, même pattern de graine. Le client
envoie par essai : indices des cases ouvertes **dans l'ordre** avec horodatages, couleur choisie,
latence de décision.

### 4.2 Mesures

| Mesure | Rôle |
|---|---|
| Cases ouvertes en moyenne, **par condition** | Descriptif |
| **P(correct) au moment de la décision** | Indice d'**impulsivité de réflexion**. Calculé serveur depuis la disposition réelle — c'est la raison pour laquelle le serveur doit posséder la grille. ⚠️ Formule corrigée obligatoire, voir ci-dessous. |
| **Discrimination entre conditions** | Le joueur échantillonne-t-il **moins** quand échantillonner coûte ? Signal de compétence authentique. |
| Erreurs | Entre dans le score |

**⚠️ Correction statistique obligatoire sur P(correct).** Bennett, Oldham, Dawson, Parkes, Murawski &
Yücel (2017, *Biological Psychiatry*, 82(4), e29–e30) établissent que le calcul conventionnel de
P(correct) — celui de la version CANTAB — **repose sur une inférence statistique incorrecte**, ce qui
**surestime systématiquement** l'impulsivité de réflexion et gonfle le risque d'erreur de type II. La
correction est une **formule bayésienne tenant compte de l'ordre dans lequel les cases ont été
ouvertes**.

L'implémentation doit utiliser la formule corrigée. Le serveur possède déjà tout le nécessaire — la
disposition réelle et la séquence ordonnée des ouvertures — mais il doit calculer juste.

> **Action bloquante avant implémentation** : obtenir le texte intégral de Bennett et al. (2017) et
> transcrire la formule exacte. Ne pas la reconstruire par déduction : ce serait précisément l'erreur
> que l'article dénonce. Ce point est au §9.

### 4.3 Notation

Contrairement à BART, l'IST possède un **axe de compétence véritable** : l'exactitude de la
décision, la quantité de preuve réellement détenue à l'engagement, et l'ajustement de
l'échantillonnage à son coût sont toutes des choses que l'on peut faire mieux ou moins bien.

**Score `INFORMATION_SAMPLING_CORE` = /100** — mélange pondéré de :

1. exactitude des décisions ;
2. P(correct) au moment de la décision ;
3. discrimination entre conditions.

> ⚠️ **PROVISOIRE** — les trois poids vivent dans `IstProvisionalRules`, à valider (§9).

---

## 5. Couche confiance (métacognition)

Un tap sur une échelle de confiance **après chaque décision IST** → 20 jugements.

| Indicateur | Calcul | Statut |
|---|---|---|
| **Biais de calibration** | confiance moyenne − exactitude | **Conservé**, descriptif, hors score |
| ~~Sensibilité métacognitive~~ | ~~AUROC2 / meta-d′~~ | **RETIRÉ** — voir ci-dessous |

**Correction du 2026-09-17 — la sensibilité métacognitive est retirée du lot 1.** La première version
de ce design proposait AUROC2 plutôt que meta-d′ au motif du nombre d'essais. La revue
bibliographique (voir `docs/PREUVES_SCIENTIFIQUES_JEUX_DECISION.md` §4.2) invalide ce raisonnement sur
les deux jambes :

1. **AUROC2 n'est pas neutre** : il **dépend de la performance de type 1** — plus l'exactitude baisse,
   plus la part d'essais devinés monte, plus AUROC2 baisse mécaniquement à bruit métacognitif
   constant. meta-d′ a été inventé exactement pour corriger ce défaut (Maniscalco & Lau 2012 ;
   Fleming & Lau 2014). Comme l'exactitude à l'IST varie fortement entre candidats, AUROC2
   confondrait « bon à la tâche » et « bien calibré ».
2. **Le nombre d'essais est hors d'atteinte** : Guggenmos (2021, *Neuroscience of Consciousness*,
   niab040) recommande **un minimum de 400 essais** pour le M-ratio ; en dessous de 400, r ≤ 0,6, et
   à 60 % d'exactitude la fiabilité tombe à ≈ 0,4 même entre 400 et 600 essais. Nous en avons **20**.

Conséquence : **aucun indicateur de sensibilité métacognitive n'est calculé, stocké ni exposé.** Pas
relégué en « exploratoire » — retiré. La colonne `auroc2` disparaît de `ist_runs` (§7). Conclusion
plus large à porter au commanditaire : la sensibilité métacognitive **n'est pas mesurable dans un
format de 15 minutes**, ce qui est une limite de la mesure et non de l'implémentation.

**Échelle par défaut à implémenter** (⚠️ **PROVISOIRE**, à valider — §9.4) : **4 points**, sans
point neutre pour éviter le refuge au milieu, mappés sur `0.625 / 0.75 / 0.875 / 1.0` pour le calcul
du biais (bornes de confiance dans un choix binaire : le hasard vaut 0,5). Libellés provisoires :
*« au hasard » / « plutôt sûr » / « sûr » / « certain »*. Un jugement non fourni est enregistré
`null` et exclu de l'indicateur, sans invalider l'essai IST correspondant.

**Limites assumées.** 20 essais est trop peu pour meta-d′, qui demande ~100+ essais pour se
stabiliser ; d'où AUROC2, sans ajustement de modèle. Même AUROC2 restera bruité à 20 essais. Le
biais de calibration, lui, n'est qu'une différence de moyennes et tient très bien.

**Les deux indicateurs restent hors du score.** La couche coûte presque rien à construire et
améliore chacune des tâches des lots suivants, ce qui justifie de la faire maintenant malgré la
faible sensibilité.

Le module calcule déjà d′ et le biais *c* dans `ContinuousAttentionScoringService` — la machinerie
existe.

---

## 6. Architecture backend

Le jeu de fichiers reprend **« Je place » (`OBJECT_LOCATION_BINDING_CORE`)**, l'implémentation la
plus récente et la plus proche structurellement.

### 6.1 Fichiers à créer

```
backend/src/main/java/com/zennyt/games/
├── domain/config/
│   ├── BartConfig.java                    # MOTEUR : 30 essais, valeur de pompe, max 128, loi d'éclatement
│   ├── BartProvisionalRules.java          # PROVISOIRE : formule d'efficience EV, bandes de niveau
│   ├── IstConfig.java                     # MOTEUR : grille 5×5, 10+10 essais, gains FW/DW, pénalité
│   └── IstProvisionalRules.java           # PROVISOIRE : poids du score, bandes, seuils de validité
├── domain/service/
│   ├── BartSequenceGenerator.java         # déterministe, graine sessionId + version protocole
│   ├── BartActionReplayer.java            # rejoue et rejette les réclamations impossibles
│   ├── BartScoringService.java            # efficience EV → /100 + indicateurs descriptifs
│   ├── IstLayoutGenerator.java            # déterministe
│   ├── IstActionReplayer.java
│   ├── IstScoringService.java             # exactitude + P(correct) + discrimination → /100
│   └── MetacognitionService.java          # biais de calibration + AUROC2
├── domain/vo/
│   ├── BartMetrics.java  BartTrialMetric.java  BartReport.java
│   ├── BartTrialOutcome.java              # COLLECTED | EXPLODED
│   ├── IstMetrics.java  IstTrialMetric.java  IstReport.java
│   ├── IstCondition.java                  # FIXED_WIN | DECREASING_WIN
│   ├── IstBoxOpening.java
│   └── ConfidenceJudgment.java  MetacognitionReport.java
├── domain/repository/
│   ├── BartMetricsRepository.java
│   └── IstMetricsRepository.java
├── infrastructure/persistence/
│   ├── BartMetricsRepositoryAdapter.java  + entités JPA
│   └── IstMetricsRepositoryAdapter.java   + entités JPA
└── api/dto/
    ├── BartDtos.java
    └── IstDtos.java
```

### 6.2 Fichiers à modifier

| Fichier | Modification |
|---|---|
| `domain/vo/GameType.java` | + `DECISION_BEHAVIORAL` |
| `domain/model/MiniGame.java` | + `BART_CORE(DECISION_BEHAVIORAL, 100, true)`, + `INFORMATION_SAMPLING_CORE(DECISION_BEHAVIORAL, 100, true)` |
| `domain/service/ScoreBreakdownService.java` | + lignes de détail pour les deux mini-jeux |
| `application/usecase/SubmitGameResultUseCase.java` | + branches de soumission |
| `api/dto/GameSessionResponse.java` | + `bartIndicators`, `istIndicators`, `metacognitionIndicators` |

### 6.3 Contrainte de couches

Le domaine reste **Java pur** : aucune annotation Spring ni JPA dans `domain/` (vérifié par
ArchUnit en CI). Contract-first : `contracts/games.openapi.yaml` est modifié **en premier**, puis le
backend, puis le mobile (AGENTS.md §7.5).

---

## 7. Schéma de base — `V84__games_decision_behavioral.sql`

Dernière migration existante : `V83__engagement_billing.sql`. La nouvelle prend donc **V84**.

> ⚠️ Ne jamais modifier une migration existante (AGENTS.md §7.6).

```
-- Extension des CHECK existants
games.game_sessions.game_type      → autorise DECISION_BEHAVIORAL
games.game_attempts.mini_game      → autorise BART_CORE, INFORMATION_SAMPLING_CORE

-- BART
games.bart_runs          (session_id PK/FK, protocol_version, seed_source,
                          adjusted_avg_pumps, explosions, total_earnings,
                          ev_optimal_earnings, efficiency_percent,
                          post_loss_adjustment, post_win_adjustment,
                          session_valid, created_at)
games.bart_trials        (run_id FK, trial_index, is_practice, explosion_point,
                          pumps, outcome, trial_earnings, first_pump_latency_ms)

-- IST
games.ist_runs           (session_id PK/FK, protocol_version, seed_source,
                          mean_boxes_fw, mean_boxes_dw, condition_discrimination,
                          mean_p_correct_at_decision, errors, total_earnings,
                          calibration_bias, session_valid, created_at)
games.ist_trials         (run_id FK, trial_index, is_practice, condition,
                          majority_color, chosen_color, correct,
                          boxes_opened, p_correct_at_decision,
                          decision_latency_ms, confidence)
games.ist_box_openings   (trial_id FK, opening_index, box_index,
                          revealed_color, latency_ms)

-- Un seul Attempt valide par session et par mini-jeu
ux_bart_single_valid_attempt   (index partiel)
ux_ist_single_valid_attempt    (index partiel)
```

Les temps bruts sont **conservés tels quels** ; toute correction s'applique au calcul, jamais au
stockage (règle du socle de calibrage).

---

## 8. Garde-fous, composite, tests

### 8.1 Validité de session

Chaque mini-jeu porte son contrôle de validité, sur le modèle existant (`sessionUsable` de
« Je Décide », validité de tâche de « Je coordonne ») :

| Jeu | Motifs d'invalidité |
|---|---|
| BART | latences implausibles ; une seule pompe systématiquement sur tous les essais ; collecte immédiate sur tous les essais |
| IST | zéro case ouverte sur tous les essais ; latences de décision implausibles ; taux de réponse aléatoire |

Une capture invalide produit un **run audit-only** : pas d'`Attempt`, pas d'événement. C'est le
comportement déjà en place pour « Je continue », « Je coordonne » et « Je place ». Les contrôles
sont **renforcés en mode non supervisé**, comme pour « Je Décide ».

### 8.2 Composite du `GameType`

Deux mini-jeux **/100 chacun** → composite **/200**, normalisé par
`GameSession.playedNormalizedScore()`. Le choix de /100 (plutôt que /10 à la Planifik) tient au fait
que la notation naturelle des deux tâches est de nature pourcentuelle — efficience et mélanges
d'exactitude — et que /10 imposerait un arrondi destructeur. Aucune fiche n'impose d'échelle ici.

`coverageRatio()` fonctionne sans modification : 50 après un mini-jeu, 100 après les deux.

### 8.3 Événement Fit Score

**Suspendu**, y compris pour un `Attempt` valide, jusqu'à validation du barème par le psychologue —
précédent explicite de « Je place ». Le listener reste en place, l'émission est gelée.

### 8.4 Tests

Tests de domaine en **Java pur, sans Spring** (AGENTS.md §8) :

1. déterminisme des générateurs : même `sessionId` + version → même séquence / même grille ;
2. les rejoueurs **rejettent** les réclamations impossibles (collecte après éclatement, ouverture
   d'une case déjà ouverte, décision sans ouverture déclarée) ;
3. notation sur fixtures calculées à la main, dont les exemples publiés des articles ;
4. cas limites de validité → run audit-only, aucun `Attempt`, aucun événement ;
5. **non-régression** : `expectedMiniGames()` pour `GameType.DECISION` reste **inchangé** à
   `[DECISION_CORE]`, et une session « Je Décide » atteint toujours `COMPLETED` avec
   `coverageRatio() == 100` après ce seul mini-jeu.

### 8.5 Parité mock ⇄ backend

`mobile/lib/features/games/data/games_mock_repository.dart` doit reproduire les deux services de
notation **à l'identique**, avec commentaires croisés pointant l'un vers l'autre, dans la même PR
(AGENTS.md §7.7). Modèle existant : `object_location_scoring.dart` /
`ObjectLocationScoringService`.

### 8.6 Mobile — bloqué sur les maquettes

`mobile/assets/` ne contient de dossier que pour les jeux livrés (`04 Je Décide`,
`04 Predictive Puzzle`, `J'investigue`, …). **Aucune maquette n'existe pour BART ni pour l'IST.**

AGENTS.md §4 interdit d'inventer un écran, une icône ou un asset ; §11 impose de s'arrêter et de
demander quand ils manquent. Le périmètre mobile de ce design est donc **suspendu au handoff
design** : backend + contrat sont spécifiables et implémentables dès maintenant, le flow mobile ne
l'est pas.

Composants à réutiliser quand les maquettes arriveront (§5 AGENTS.md, pas de duplication) :
`game_system_components.dart`, `ScoreDetailPanel`, le plateau en grille de `je_place_screen.dart`
pour la grille 5×5 de l'IST, les dialogues de pause/règles existants.

---

## 9. À faire valider par le psychologue référent

**Bloquant pour sortir du provisoire :**

1. **Formule d'efficience EV de BART** (§3.4) — construction propre à ce design, issue d'aucune
   publication. Le point le plus important de la liste. Trois sous-questions : le benchmark
   « stratégie fixe optimale `n* = 64` » est-il le bon référent (vs. une norme empirique
   d'échantillon) ? le plafond à 100 est-il acceptable ou faut-il laisser le dépassement visible ?
   une séquence dégénérée doit-elle invalider la session ou être régénérée ?
2. **Poids du score IST** — exactitude / P(correct) à la décision / discrimination entre conditions.
3. **Bandes de niveau** des deux jeux.
4. **Échelle de confiance** — valider ou remplacer le défaut provisoire à 4 points et son mappage
   `0.625 / 0.75 / 0.875 / 1.0` (§5) et les libellés.
5. **Seuils de validité de session** par jeu.
5 bis. **Transcription de la formule corrigée de P(correct)** depuis Bennett et al. (2017), une fois
   le texte intégral obtenu (§4.2). **Bloquant pour l'implémentation de l'IST**, pas seulement pour
   sortir du provisoire.
5 ter. **Confirmation du retrait de la sensibilité métacognitive** (§5) et de la conclusion qu'elle
   n'est pas atteignable dans un format de 15 minutes.

**Décisions produit à arbitrer :**

6. **Nom du `GameType`** — `DECISION_BEHAVIORAL` est un nom de travail. Enjeu taxonomique : ces
   deux paradigmes forment-ils un domaine, ou des facettes de la décision ? À croiser avec la
   matrice Fit Score. Question déjà ouverte pour « Je coordonne » (affiché sous *Cognitive
   Flexibility*) et « Je place » (*Working Memory*).
7. **Composite /200** — confirmer que BART et IST appartiennent à un même profil.
8. Nombre d'essais : 30 ballons et 2×10 essais IST suivent les articles ; confirmer que la durée
   totale (~12–15 min + onboarding) est acceptable à côté des 20–30 min de « Je Décide ».

**Divergences à signaler :**

9. BART ne produit **pas** de mesure « meilleur/pire » sur son indice standard ; le score /100 porte
   sur un axe reconstruit (efficience EV), pas sur les pompes moyennes ajustées. À expliciter dans
   tout rapport lu par un recruteur.
10. L'IST sous marque CANTAB et l'IGT via PAR Inc. sont commerciaux : **aucune norme** de ces
    batteries n'est utilisée, uniquement les paradigmes publiés.

---

## 10. Suite de la feuille de route (hors périmètre de ce design)

| Lot | Contenu | Pourquoi plus tard |
|---|---|---|
| **2** | Apprentissage par renversement probabiliste (Cools 2002) | Complète le récit « s'adapte vs. persévère » à côté de `MOVE_FAST`, qui change de règle avec indice **explicite**. ~80–120 essais. |
| **3** | Actualisation temporelle titrée, AUC (Du/Green/Myerson 2002) | Peu coûteux, mais **déclaratif** — recouvre partiellement l'approche à vignettes. |
| **4** | Jeu de confiance (Berg 1995) + ultimatum (Güth 1982) | Bloqué sur une décision produit : en mono-joueur, le partenaire est un algorithme. Pratique standard en recherche, mais cela mesure les *croyances sur* autrui, pas une interaction réelle — à divulguer explicitement. |
| **Écartés** | Iowa Gambling Task | Fidélité test-retest faible pour une évaluation **individuelle**, 100 essais, et la version connue est commerciale (PAR Inc.). |
| **Écartés** | Tâche Markov à deux étapes (Daw 2011) | La notation exige un ajustement de modèle bayésien hiérarchique, et le résultat est inexplicable à un recruteur. |
| **Écartés** | Contraintes conflictuelles (compromis multi-attributs) | Recouvre `OPTIMAL_PATH` (zones coûteuses) et `TASK_SCHEDULING` sous `PLANIFIK`. Conflit taxonomique à trancher avant. |
| **Écartés** | Paradigmes d'intégrité (dé sous le gobelet, tâche matricielle) | **Recommandation explicite de ne pas construire.** Ces mesures ne sont valides que si le candidat se croit non observé — elles exigent donc de le tromper. Un score d'intégrité dérivé ainsi, dans une décision d'embauche, est exposé sur le consentement éclairé et l'impact disparate. Si l'intégrité compte pour le Fit Score, utiliser un inventaire d'intégrité **transparent**. |

---

## 11. Catalogue complet des paradigmes évalués

Conservé ici pour que les lots suivants n'aient pas à refaire la revue.

| # | Paradigme | Facette | Ce qu'il mesure | Statut PI | Adéquation architecture |
|---|---|---|---|---|---|
| 1 | **BART** (Lejuez 2002) | Risque révélé | Pompes moyennes ajustées, éclatements, ajustement post-perte / post-gain | Procédure publiée, sans propriétaire | ★★★ **Lot 1** |
| 2 | Cambridge Gambling Task (Rogers 1999) | Risque, cotes explicites | Sépare **ajustement au risque**, **impulsivité** et **aversion au délai** | Paradigme publié ; version + normes CANTAB propriétaires | ★★★ Meilleure séparation risque/impulsivité de la liste |
| 3 | Game of Dice Task (Brand 2005) | Risque, cotes stables connues | Usage de règles de probabilité explicites, 18 lancers | Entièrement décrit dans la littérature | ★★★ Le moins coûteux de la famille risque |
| 4 | Columbia Card Task (Figner 2009) | Risque, « chaud » vs « froid » | Distingue risque délibératif et affectif | Publié | ★★ Deux conditions → plus long |
| 5 | Iowa Gambling Task (Bechara 1994) | Risque sous ambiguïté | Apprentissage d'évitement des paquets désavantageux, 100 essais | Version + normes via PAR Inc. | ★ Écarté (§10) |
| 6 | **IST** (Clark 2006) | Recueil d'information | Cases ouvertes, P(correct) à la décision = impulsivité de réflexion | Paradigme publié ; version CANTAB propriétaire | ★★★ **Lot 1** |
| 7 | Tâche des perles (Huq 1988) | Recueil d'information | « Tirages jusqu'à décision » | Publié | ★★ Plus simple mais plus pauvre, et cliniquement chargé (recherche sur la psychose) |
| 8 | Renversement probabiliste (Cools 2002) | Adaptation au feedback | Erreurs de persévération, win-stay/lose-shift, taux d'apprentissage | Publié | ★★★ **Lot 2** |
| 9 | Markov à deux étapes (Daw 2011) | Adaptation au feedback | Contrôle *model-based* vs *model-free* | Publié | ★ Écarté (§10) |
| 10 | Actualisation titrée (Du/Green/Myerson 2002) | Patience | Points d'indifférence → *k* hyperbolique et **AUC** sans modèle | Publié | ★★★ **Lot 3** |
| 11 | Monetary Choice Questionnaire (Kirby 1999) | Patience | 27 items binaires → *k* par table publiée | Publié, avec normes | ★★★ Très bon marché, mais **déclaratif** |
| 12 | Jeu de confiance (Berg 1995) | Social | Montant envoyé (confiance) / rendu (fiabilité), réciprocité | Publié | ★★ **Lot 4**, partenaire scripté |
| 13 | Ultimatum (Güth 1982) | Social | Normes d'équité, rejet coûteux d'offres inéquitables | Publié | ★★ **Lot 4** |
| 14 | Dilemme du prisonnier itéré | Social | Coopération, réciprocité, réaction à la trahison | Publié | ★★ **Lot 4** |
| 15 | Compromis multi-attributs (lignée Tversky) | Contraintes conflictuelles | Cohérence des poids implicites, violations de transitivité | Théorie de la décision, pas de tâche canonique unique | ★★ Écarté — conflit `PLANIFIK` |
| 16 | **Confiance + meta-d′** (Maniscalco & Lau 2012) | Métacognition | Sensibilité métacognitive, biais de sur/sous-confiance | Publié, code de notation ouvert | ★★★ **Lot 1** — ce n'est pas un jeu, c'est une **couche** |
| 17 | Dé sous le gobelet / tâche matricielle (Fischbacher 2013) | Intégrité | Tricherie en l'absence d'observation | Publié | ⛔ Ne pas construire (§10) |

---

## Changelog de ce document

| # | Date | Contenu |
|---|------|---------|
| 1 | 2026-09-17 | Création. Inspection de la logique games existante, catalogue des 17 paradigmes de décision évalués, décomposition en 4 lots, design du lot 1 (BART + IST + couche confiance) sous un nouveau `GameType`. Non implémenté. |
| 2 | 2026-09-17 | Deux corrections issues de la revue bibliographique (`docs/PREUVES_SCIENTIFIQUES_JEUX_DECISION.md`). **(a)** La sensibilité métacognitive est **retirée** du lot 1 : AUROC2 dépend de la performance de type 1, et le M-ratio demande ≥ 400 essais contre 20 disponibles ; colonne `auroc2` supprimée de `ist_runs`. **(b)** P(correct) de l'IST doit suivre la **formule bayésienne corrigée de Bennett et al. (2017)**, le calcul conventionnel étant statistiquement incorrect ; obtention du texte intégral rendue bloquante avant implémentation. Précision du benchmark EV du BART (stratégie fixe optimale `n* = 64`, non clairvoyante) et ajout d'une échelle de confiance par défaut implémentable. |

**Dernière mise à jour** : 2026-09-17
