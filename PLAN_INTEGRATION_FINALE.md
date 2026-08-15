# Plan d'intégration finale — ramener tout le monde sur `main`

**Module Recrutement — Zennyt**
État au 15 août 2026. Point de départ : `amine/main` = `9d1d675`.

---

## 1. Où on en est

`amine/main` contient déjà : le Track A, le Track B, les trois jeux Games du 10 août,
F32 (mode d'évaluation par métier), F06/F30 (sélecteurs métier et niveau côté mobile),
le correctif de l'alerte hard skills, et la décision d'abandon de la pondération culture.
**513 tests, 0 échec. Schéma Flyway en 63.**

Deux branches ont bougé **après** cette fusion et ne sont pas dans `main` :

| Branche | Auteur | Date | Commits en attente | Domaine |
|---|---|---|---|---|
| `amine/Games-Progress` | Amine Charrada | 12 août | 2 | Games + Fit Score |
| `amine/IntergrationV1` | Amine Manai, MSI | 12 août | 12 | Engagement + Identity + mobile |

**Aucune des deux n'apporte de migration Flyway.** C'est la bonne nouvelle : le scénario
qui a coûté le plus cher jusqu'ici — deux équipes qui prennent le même numéro de version —
ne se reproduit pas. Le prochain numéro libre reste **V64**.

---

## 2. Ce que chaque branche apporte

### 2.1 `Games-Progress` — le module manquant arrive

| Apport | Détail |
|---|---|
| **Les 30 scénarios « Je Décide »** | `decision_scenarios.json`, banque de 120 items. `JsonDecisionScenarioCatalog` remplace `EmptyDecisionScenarioCatalog`. |
| **`DECISION_CORE` devient jouable** | `MiniGame` passe le drapeau à `true`. |
| **Emotional Radar V2** | Nouveau moteur : difficulté adaptative, estimation IRT (thêta), distance valence/arousal, référentiel de 425 lignes d'émotions. |
| **Écran mobile « Strategic Choices »** | 1 928 lignes Dart, plus ses tests. |

C'est **l'événement que le document de référence annonçait** : « le jour où Games livre le
catalogue, il suffit de basculer un drapeau ».

### 2.2 `IntergrationV1` — engagement et identity

279 fichiers, dont 248 côté mobile. Backend : chat temps réel sécurisé (WebSocket + poignée
de main JWT), appels audio/vidéo (Agora), enregistrement d'appel, photos de profil.
**Aucun fichier du contexte `recruitment` n'est touché**, et les contrats modifiés sont
`engagement.openapi.yaml` et `identity.openapi.yaml` — pas le nôtre.

---

## 3. Les points durs, avant de commencer

### 3.1 Les attentes des tests Fit Score sont fausses ⚠️

**C'est le point le plus important de ce document.**

`Games-Progress` est partie d'une base **antérieure au 10 août**. Elle ne contient donc pas
le correctif qui a rendu disponibles les trois jeux livrés ce jour-là — et, fait révélateur,
**ses propres jeux y sont encore marqués indisponibles** :

```
game("CONTINUOUS_ATTENTION", false)      <- alors que le jeu est livré
game("VISUOMOTOR_COORDINATION", false)   <- idem
game("VISUOSPATIAL_MEMORY", false)       <- idem
```

Leur branche a donc calculé ses attentes de tests en tenant compte d'**un seul** des deux
changements : « Je Décide » devient mesurable (le dénominateur repasse de 70 à 100), mais
pas du fait qu'un module compte désormais plusieurs jeux. Résultat, elles supposent encore
qu'un seul jeu couvre la flexibilité à 100 %.

Voici ce que donne le calcul réel une fois les deux effets cumulés :

| Cas de test | Games-Progress annonce | Réel après fusion |
|---|---|---|
| Un seul jeu joué (90) | 27 | **9** (couverture 10) |
| Couverture partielle 40 % | 11 | **4** (couverture 4) |
| Deux couvertures différentes | 32 | **12** (couverture 15) |
| Régulation émotionnelle pondérée | 25 | **9** |
| Clé de module inconnue ignorée | 24 | **8** |
| Candidat 3 modules — TECHNIQUE | 37 | **21** |
| Candidat 3 modules — RELATIONNEL | 21 | **15** |

**Les sept sont à corriger.** Ce ne sont pas des erreurs de leur part : ce sont deux
travaux justes menés en parallèle, dont personne n'a encore calculé la somme.

Deux cas structurants, eux, tombent juste et servent de garde-fou :

- **Candidat parfait** (les 8 jeux à 100) → **100 / 100**. Si ce n'est pas le cas après
  fusion, la fusion est ratée.
- **Tout sauf « Je Décide »** sur un métier TECHNIQUE → **70**. C'est le changement de
  comportement le plus visible : ne pas jouer « Je Décide » coûte désormais 30 points, alors
  que le module était purement ignoré la veille.

### 3.2 Un secret réel dans `.env.example` 🔴

Le fichier `.env.example` d'`IntergrationV1` contient ce qui ressemble à de **vraies
informations d'identification Cloudinary**, et non des valeurs d'exemple :

```
CLOUDINARY_API_SECRET=SisHNefg-FelZA_WM_AG7UdbrQk
CLOUDINARY_API_KEY=816956116244257
```

Les clés Resend et Groq du même fichier, elles, sont bien des marque-places
(`your_..._key_here`). Le contraste indique que le Cloudinary a été collé par accident.

**À traiter avant la fusion, pas après.** Une fois le commit sur `main`, le secret est dans
l'historique de tous ceux qui clonent, et le retirer d'un commit ultérieur ne l'efface pas.
La seule action réellement corrective est de **révoquer la clé côté Cloudinary** puis de
remettre un marque-place. C'est une décision qui appartient à celui qui détient le compte.

### 3.3 Une montée de version majeure côté mobile

`IntergrationV1` fait passer `flutter_secure_storage` de **^9.2.2 à ^10.3.1**. Changement de
version majeure : les ruptures d'API sont à attendre, et ce paquet porte le stockage des
jetons d'authentification — s'il casse, plus personne ne se connecte.

Autres ajouts : `agora_rtc_engine` (appels), `stomp_dart_client` + `web_socket_channel`
(temps réel), `hive` (cache local), `get_it`, `dartz`, `freezed_annotation`.

### 3.4 Des fichiers d'atelier commités

`IntergrationV1` embarque 11 fichiers `.vs/` (réglages Visual Studio, dont un
`slnx.sqlite` binaire). À exclure de la fusion et à ajouter au `.gitignore`.

---

## 4. Le plan, étape par étape

L'ordre est délibéré : **Games d'abord**, parce qu'il touche le Fit Score et demande une
vraie réflexion ; `IntergrationV1` ensuite, parce qu'il est volumineux mais sans recoupement
avec le recrutement.

### Étape 0 — Avant tout

- [ ] **Signaler le secret Cloudinary** à qui détient le compte, et faire révoquer la clé.
- [ ] Confirmer avec Amine Charrada que `Games-Progress` est bien prête à fusionner.
- [ ] Partir d'un arbre propre : `git status` doit être vide.

### Étape 1 — Fusionner `Games-Progress`

```bash
git checkout main
git merge amine/Games-Progress --no-commit
```

**4 conflits attendus, tous dans des fichiers de test :**

| Fichier | Comment trancher |
|---|---|
| `SoftSkillModuleGamesParityTest.java` | Conflit ajout/ajout : les deux côtés ont écrit un test du même nom. **Garder la version de `main`**, qui vérifie la parité dans les deux sens, puis y reporter ce que leur version couvre en plus. |
| `SubmitGameResultUseCaseEventTest.java` | Prendre leur version si elle compile, sinon reporter à la main les nouveaux dépôts injectés. |
| `DeterministicFitScoreCalculatorTest.java` | **Ne pas prendre un côté ou l'autre.** Recalculer chaque attente — voir le tableau 3.1. |
| `FitScoreBaselineTest.java` | Idem. Les personas doivent jouer **tous** les jeux, « Je Décide » compris, pour rester pleinement couverts. |

**Puis, dans le code de production :**

- [ ] `SoftSkillModule` — repasser les trois jeux Games à `true` (leur branche les a
      remis à `false` en repartant d'une base ancienne), et garder leur passage de
      `DECISION` à `true`. **Les cinq modules doivent être disponibles.**
- [ ] Vérifier que `MiniGame.DECISION_CORE` est bien `playable = true`.

**Vérifications :**

```bash
cd backend && ./mvnw clean
ZENNYT_TEST_POSTGRES_URL=jdbc:postgresql://localhost:5432/zennyt ./mvnw test
```

- [ ] `SoftSkillModuleGamesParityTest` passe — c'est lui qui prouve que les deux listes de
      jeux coïncident enfin.
- [ ] Le test « candidat parfait » rend **100 / 100**.
- [ ] Le test « tout sauf Je Décide » rend **70** sur TECHNIQUE.
- [ ] `flutter analyze` : 0 erreur.

> **Le `mvnw clean` n'est pas décoratif.** Maven copie les migrations et les ressources dans
> `target/` sans jamais y supprimer ce qui a disparu. Ce piège a coûté trois faux
> diagnostics sur ce projet.

### Étape 2 — Mettre à jour ce que « Je Décide » change

Le module devient mesurable : plusieurs affirmations écrites noir sur blanc deviennent
fausses le jour de la fusion.

- [ ] **`DOC_FITSCORE_ET_RECOMMANDATION.md` §3.1** — « Prise de décision : ❌ aucun » devient
      « ✅ 1 sur 1 ».
- [ ] **§3.4** — la section « Pourquoi un module non mesurable en sort entièrement » décrit
      désormais un cas de figure qui n'existe plus. La conserver comme explication du
      mécanisme, mais dire que plus aucun module n'est dans ce cas.
- [ ] **§5.6, le tableau des poids effectifs** — c'est le plus visible. Les dénominateurs
      passent tous à **100**, et les pourcentages effectifs redeviennent les poids nominaux.
      Sur un métier TECHNIQUE, la flexibilité repasse de 42,9 % à 30 %.
- [ ] **Annexe D** — retirer la ligne « Le mini-jeu Prise de décision : non jouable ».
- [ ] **`PONDERATION_CULTURE_TROIS_QUESTIONS.md` §2.4** — le constat « le dénominateur vaut
      70 à 85 et non 100 » **cesse d'être vrai**. À marquer comme résolu, en gardant la
      trace : c'était l'un des deux acquis signalés lors de l'abandon.
- [ ] Régénérer les deux PDF : `python docs/md_to_pdf.py <fichier>.md`.

### Étape 3 — Prévenir du changement de comportement

Ce n'est pas une tâche de code, mais elle ne peut pas être sautée.

Un candidat qui n'a pas joué « Je Décide » **perd désormais des points** — jusqu'à 30 sur un
métier technique, 20 sur un profil relationnel. La veille, le module était ignoré. Tous les
Fit Score déjà calculés deviennent donc faux d'un coup.

- [ ] Le mécanisme de péremption gère ce cas : la pondération n'a pas changé, mais les
      scores doivent être recalculés. **Lancer un recalcul complet** après la fusion.
- [ ] Prévenir l'équipe produit : les scores affichés vont bouger, à la baisse pour tout
      candidat n'ayant pas joué le nouveau jeu.

### Étape 4 — Fusionner `IntergrationV1`

```bash
git merge amine/IntergrationV1 --no-commit
```

**3 conflits attendus :**

| Fichier | Comment trancher |
|---|---|
| `mobile/pubspec.yaml` | Réunion des deux listes. Attention à `flutter_secure_storage` 9 → 10 : garder leur version, mais vérifier que l'authentification fonctionne encore (voir ci-dessous). |
| `mobile/lib/core/router/app_router.dart` | Réunion : leurs ~140 lignes de routes engagement + les nôtres (jeux, offres). Aucune ne se recouvre. |
| `.env.example` | **Ne pas prendre leur version telle quelle** — voir 3.2. Réunir les clés, avec des marque-places partout. |

- [ ] Exclure les 11 fichiers `.vs/` de la fusion, et les ajouter au `.gitignore`.

**Vérifications :**

- [ ] `flutter pub get` puis `flutter analyze` : 0 erreur.
- [ ] **Connexion et déconnexion à la main** sur l'application — c'est le seul moyen de
      vérifier la montée de `flutter_secure_storage`. Un test automatique ne couvrira pas le
      stockage natif.
- [ ] `./mvnw test` : la suite backend doit rester verte (leurs changements portent sur
      `engagement` et `identity`, mais les tests de parité de contrat balaient tout).
- [ ] Démarrer le backend et vérifier `actuator/health`.

### Étape 5 — Clôture

- [ ] `git push amine HEAD:main` et `git push origin`.
- [ ] Annoncer aux trois équipes : **prochain numéro de migration libre = V64**.
- [ ] Mettre à jour `RECRUITMENT_MODULE.md` et `GAMES_MODULE.md` si la fusion a changé leur
      contenu.

---

## 5. Estimation

| Étape | Durée | Difficulté |
|---|---|---|
| 0 — Secret + confirmations | 30 min | Dépend d'un tiers |
| 1 — Fusion Games + tests | **3 à 4 h** | La partie délicate : 7 attentes à recalculer |
| 2 — Mise à jour des documents | 1 h 30 | Mécanique |
| 3 — Recalcul + annonce | 30 min | — |
| 4 — Fusion IntergrationV1 | **2 à 3 h** | Volumineux, mais sans recoupement |
| 5 — Clôture | 30 min | — |

**Total : une journée de travail.** L'étape 1 est celle qui demande de l'attention ; les
autres sont de l'exécution.

---

## 6. Ce qui restera ouvert après

| Sujet | État |
|---|---|
| Calibration des 24 lignes de pondération | `calibrated = false` partout. Atelier RH requis. |
| Seuil « bon profil » à 70 | Marqué provisoire dans le code, jamais validé par le produit. |
| Seuils de couverture 60 / 70 | À valider avec les RH. |
| Calcul du mode MIXTE | Le mode est stocké et lisible, mais le sous-score hard ne le distingue pas encore de QCM. |
| Renommage de `hardSkillScore` | Le champ a changé de sens et porte une estimation agrégée. |
| Pondération par la culture | ❌ Abandonnée le 11 août 2026. Ne pas rouvrir sans élément nouveau. |

Aucun de ces points n'est bloquant pour la fusion.

---

*Module Recrutement — projet Zennyt. Plan établi le 15 août 2026, sur l'état réel des
branches `amine/Games-Progress` et `amine/IntergrationV1` à cette date.*
