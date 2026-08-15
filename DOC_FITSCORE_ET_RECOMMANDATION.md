# Fit Score et recommandation — comment ça marche

**Module Recrutement — Zennyt**
Document de référence. État au 11 août 2026.

---

## Préambule

### À quoi sert ce document

Répondre à trois questions, du général au précis :

1. **Comment un candidat obtient une note face à une offre** — la formule complète, chaque
   entrée, chaque poids.
2. **Quand cette note est calculée** — six chemins différents, une seule formule.
3. **Comment cette note produit un classement** — il y en a deux, et ils ne fonctionnent
   pas pareil.

Une quatrième partie décrit la pondération assistée par la culture d'entreprise, qui n'est
**pas encore construite** mais dont la place dans l'ensemble se comprend mieux ici.

### Ce que ce document n'est pas

Ce n'est ni un cahier des charges (il décrit ce qui existe, pas ce qui devrait exister), ni
une documentation d'API. Quand le code s'écarte du cahier des charges, c'est signalé.

### Convention de lecture

| Marque | Sens |
|---|---|
| ✅ | En place, vérifié sur base réelle |
| 🔧 | En place, mais **désactivé par défaut** — un interrupteur l'active |
| 📋 | Spécifié, **non construit** |
| ⚠️ | Écart, limite ou décision en attente |

Chaque section se termine par ses **références de code**, pour que toute affirmation soit
vérifiable. Le corps du texte n'en contient pas, afin de rester lisible sans ouvrir le code.

---

# Partie I — Le Fit Score : ce que c'est

## 1. Une note, deux sous-scores

Le Fit Score est un nombre de **0 à 100** qui mesure la compatibilité entre **un candidat**
et **une offre précise**. Il n'existe pas de « note du candidat » dans l'absolu : le même
candidat a autant de notes qu'il y a d'offres.

Il se compose de deux sous-scores :

| Sous-score | Ce qu'il mesure | D'où viennent les données |
|---|---|---|
| **Soft skills** | Aptitudes cognitives et comportementales | Les mini-jeux psychométriques |
| **Hard skills** | Niveau technique | Les QCM passés par le candidat |

Un score ≥ **70** est affiché comme « bon profil ». Ce seuil est marqué provisoire dans le
code, à valider avec le produit.

**Ce que la note ne mesure pas** : ni l'expérience, ni les diplômes, ni le CV. Le CV a été
retiré du calcul — le cahier des charges ne le mentionne nulle part, et le champ qui le
portait a été supprimé plutôt que conservé toujours vide. Le texte du CV reste utilisé
ailleurs, pour le résumé IA.

> **Références** — `FitScorePolicy.GOOD_FIT_MIN_SCORE`, `FitScore.java`

## 2. La formule complète

### 2.1 La formule finale

```
                Score_Soft × Poids_Soft  +  Score_Hard × Poids_Hard
Fit Score  =  ────────────────────────────────────────────────────
                                    100
```

avec `Poids_Soft + Poids_Hard = 100`.

Les deux poids viennent de la **matrice de pondération** : ils dépendent du **métier** de
l'offre et de son **niveau hiérarchique** (partie 5).

### 2.2 Le cas sans test technique

Si le candidat n'a passé **aucun QCM** sur le métier de l'offre :

```
Poids_Hard = 0        Poids_Soft = 100        Fit Score = Score_Soft
```

**Ce n'est pas un zéro.** On ne met pas 0 au sous-score hard pour ensuite le pondérer — on
retire entièrement le sous-score hard de la formule. La différence est décisive : mettre 0
punirait le candidat pour une donnée manquante ; retirer le terme dit simplement « on ne
sait pas encore ».

C'est un principe général du système : **une absence de donnée n'est jamais un score de
zéro.**

⚠️ Cette règle a une conséquence sur le classement, traitée en partie 10.

### 2.3 Un détail d'arrondi qui compte

Le sous-score soft reste un nombre **à virgule** jusqu'au mélange final ; il n'est arrondi
qu'au moment d'être affiché. L'arrondir plus tôt faisait dériver le Fit Score de jusqu'à
**0,67 point**, et le rendait impossible à recalculer de tête depuis les sous-scores
affichés — un recruteur qui vérifiait ne retrouvait pas le résultat.

### 2.4 Quand rien n'est calculé du tout

Le calcul renvoie **« incalculable »** — et **rien n'est écrit en base** — dans deux cas :

1. L'offre n'est reliée à **aucun métier** du référentiel, ou à un métier pas encore
   approuvé par un administrateur : il n'y a pas de pondération à appliquer.
2. **Aucun module mesurable** ne pèse pour ce métier, ou le candidat n'a joué à aucun jeu
   reconnu.

Dans les deux cas, la paire reste simplement en attente. Il n'existe **aucun repli** : une
version antérieure déléguait ces cas à une IA externe, qui produisait des scores calculés
selon une logique complètement différente, environ **12 fois plus lents** (~361 ms contre
~29 ms mesurés), et dépendants d'un service tiers — de façon invisible pour le lecteur. Ce
repli a été supprimé.

> **Références** — `DeterministicFitScoreCalculator.calculate()`

## 3. Le sous-score soft skills — le calcul détaillé

C'est la partie la plus subtile du système. Elle mérite d'être suivie pas à pas.

### 3.1 Les cinq modules

Le cahier des charges définit **cinq modules psychométriques**. Chacun est alimenté par un
ou plusieurs mini-jeux :

| Module | Mini-jeux qui l'alimentent | Disponible aujourd'hui |
|---|---|---|
| **Flexibilité cognitive** | Move Fast · Je continue · Je coordonne | ✅ 3 sur 3 |
| **Mémoire de travail** | Memory Quest · Je place | ✅ 2 sur 2 |
| **Prise de décision** | Je Décide | ❌ **aucun** |
| **Planification exécutive** | Planifik | ✅ 1 sur 1 |
| **Régulation émotionnelle** | Emotional Radar · Reflective Pause | ✅ 1 sur 1 * |

\* Ces deux mini-jeux appartiennent au même type de jeu et sont agrégés par le module Games
lui-même ; ils arrivent ici sous forme d'une seule mesure.

Les trois derniers jeux — *Je continue*, *Je coordonne*, *Je place* — sont arrivés le
**10 août 2026**. Leur effet sur les scores est décrit en 3.5 : il est important, et il ne
vient d'aucun changement de pondération.

**Comment cette colonne se tient à jour.** Elle est doublée dans le code : le module
Recrutement redit quels jeux existent, parce que la règle d'architecture lui interdit de
lire le domaine de Games. Ce doublon a déjà dérivé une fois — les trois jeux ci-dessus ont
été livrés alors que le Fit Score les croyait encore absents, et les ignorait donc dans son
calcul. Un test de parité fait désormais échouer la CI si les deux listes cessent de
coïncider.

⚠️ **« Prise de décision » n'est mesurable par personne.** Le moteur et les écrans existent,
mais le catalogue des 30 scénarios est vide — il attend le psychologue. Ce module ne compte
donc dans aucun score aujourd'hui (voir 3.4).

### 3.2 La formule du sous-score soft

```
                 Σ ( Score_module × Couverture_module / 100 × Poids_module )
Score_Soft  =  ───────────────────────────────────────────────────────────────
                        Σ ( Poids_module des modules MESURABLES )
```

La somme porte sur les **modules mesurables uniquement**.

Trois notions distinctes s'y croisent, et les confondre est la source d'erreur la plus
fréquente :

| Notion | Définition | Effet sur le calcul |
|---|---|---|
| Module **non mesurable** | Aucun mini-jeu n'existe encore | Sort du numérateur **et** du dénominateur |
| Module **mesurable, non joué** | Le jeu existe, le candidat ne l'a pas fait | Contribue **0** au numérateur, **reste** au dénominateur |
| Module **joué** | Le candidat a une mesure | Contribue normalement |

### 3.3 Pourquoi un module non joué reste au dénominateur

C'est une décision, et elle corrige un bug mesuré.

L'ancienne version **redistribuait** le poids des modules manquants sur ceux qui restaient
(« renormalisation »). Deux conséquences, toutes deux constatées :

1. Sur un métier **Relationnel**, deux candidats aux régulations émotionnelles opposées —
   **95** et **20**, sur une dimension pesant **45 %** — obtenaient le **même score final**.
   La dimension qui devait le plus les distinguer ne les distinguait plus du tout.
2. **Sauter un mini-jeu qu'on rate rapportait +11 points** par rapport au fait de le jouer.
   Le système récompensait l'évitement.

Aujourd'hui, un module disponible mais non joué compte pour zéro, et son poids reste au
dénominateur. C'est la **couverture** (3.5) qui signale au recruteur que la mesure est
incomplète — pas une déformation du score.

### 3.4 Pourquoi un module non mesurable en sort entièrement

Symétriquement : on ne pénalise personne pour un jeu **qui n'existe pour personne**.

Si « Prise de décision » restait au dénominateur, sur un métier Technique où il pèse 30 %,
un candidat parfait sur les quatre autres modules plafonnerait à :

```
(100 × 70) / 100 = 70
```

soit exactement le seuil « bon profil ». Personne ne pourrait jamais le dépasser.

Le module sort donc des deux côtés de la fraction, et les quatre autres se répartissent
mécaniquement l'espace. Le jour où Games livre le catalogue de scénarios, il suffit de
basculer un drapeau : le calcul s'adapte sans autre modification.

### 3.5 La couverture

La couverture d'un module dit **quelle part de ce module a réellement été mesurée** :

```
Couverture_module = Σ(couverture des jeux joués) / nombre de jeux DISPONIBLES
```

Avoir joué Move Fast seul ne couvre la Flexibilité cognitive **qu'à un tiers**, puisque le
module compte trois jeux. Jusqu'au 10 août 2026 le même candidat la couvrait **entièrement**,
Move Fast étant alors le seul jeu livré.

⚠️ **C'est le changement le plus visible de l'arrivée des trois jeux, et il surprend.** Un
candidat qui n'a rien fait de nouveau voit son score baisser, sans qu'aucune pondération
n'ait bougé. La raison est que la question posée a changé : « as-tu joué le jeu qui existe ? »
est devenue « as-tu joué les trois ? ». Un candidat qui joue tout retrouve exactement son
score d'avant — c'est vérifié par les cinq profils de référence de la suite de tests, qui
n'ont pas bougé d'un point. La décote n'est donc pas une pénalité nouvelle : c'est le
mécanisme du 3.3 qui, pour la première fois, a de quoi s'exercer.

La couverture est appliquée **module par module, avant l'agrégation** — et non globalement
sur le score déjà agrégé. Les deux ne coïncident que si tous les modules ont la même
couverture, ce que rien ne garantit.

La couverture agrégée remonte jusqu'à l'affichage sous forme d'un indicateur
« données partielles » :

| Situation | Seuil en dessous duquel on alerte |
|---|---|
| L'offre a un QCM attaché | couverture < **60 %** |
| L'offre n'en a pas | couverture < **70 %** |

Le seuil est plus exigeant sans QCM : la note repose alors entièrement sur le soft, donc la
qualité de la mesure soft compte davantage.

**La couverture est une vraie mesure, plus une constante.** Games émet une couverture à
*chaque* mini-jeu terminé, et non plus seulement à la fin d'une session complète : une
partie interrompue arrive donc avec sa décote au lieu de disparaître. Deux niveaux se
composent — Games dit quelle part d'un jeu a été jouée, le Fit Score dit quelle part du
module a été couverte par les jeux joués.

Concrètement, un candidat peut aujourd'hui obtenir toutes sortes de valeurs : 33 % sur la
Flexibilité cognitive avec un jeu sur trois, 67 % sur Planifik avec deux mini-jeux sur trois,
100 % sur la Planification exécutive s'il va au bout.

### 3.6 Un module, un poids, une seule fois

Un module peut être alimenté par plusieurs jeux. Il faut donc **regrouper les jeux par
module avant de pondérer**, sinon le poids du module serait compté une fois par jeu :
30 + 30 + 30 = 90 points sur 100 au lieu de 30, et ce module écraserait tous les autres.

Quand plusieurs jeux d'un même module ont été joués, leurs scores sont **moyennés** avant
pondération.

### 3.7 Le bug qui rendait la pondération inopérante

⚠️ À signaler, parce que le symptôme est revenu plusieurs fois dans les discussions.

Une version antérieure **aplatissait tous les modules du candidat en une seule moyenne**
*avant* que la pondération par métier ne puisse s'exercer. Conséquence : le sous-score soft
était **strictement identique quel que soit le métier de l'offre**. Les 24 lignes de la
matrice étaient calculées, lues, transportées — et mathématiquement sans effet.

C'est ce qui donnait l'impression que « le Fit Score est identique pour toutes les offres
tant que le candidat n'a pas passé de test ». Ce n'était pas le comportement voulu par le
cahier des charges : c'était un bug. Il est corrigé, et un test le verrouille — le même
candidat obtient **30 sur un métier Technique et 19 sur un métier Relationnel**, là où les
deux donnaient la même valeur avant.

> **Références** — `DeterministicFitScoreCalculator.weightedSoftScore()`, `SoftSkillModule`

## 4. Le sous-score hard skills ✅

### 4.1 Ce qu'il vaut aujourd'hui

Le sous-score hard n'est **plus** « la note du QCM de cette offre ». C'est une **estimation
du niveau technique du candidat sur le métier**, construite sur **tous les QCM qu'il a
passés pour ce métier**, y compris chez d'autres recruteurs.

Conséquence directe : un recruteur qui n'a attaché **aucun QCM** à son offre voit quand même
une évaluation technique, si le candidat a été testé ailleurs sur le même métier.

### 4.2 « Même métier » veut dire quoi

Le **même poste du référentiel** — pas le même secteur, pas la même famille.

Ce choix vient des données :

| Définition possible | Pourquoi elle est écartée |
|---|---|
| Même **secteur** | 9 des 142 métiers n'ont aucun secteur, et ce sont les plus courants (Commercial, RH, Finance, Marketing…) : ils n'auraient aucun groupe. Les 133 autres se répartissent sur 12 secteurs, soit ~11 métiers chacun — « IT, AI & Fintech » mélangerait un développeur et un ingénieur cybersécurité. |
| Même **profil-type** | C'est l'axe de pondération *soft*. Il regroupe jusqu'à 40 métiers et ne dit rien du contenu technique : un développeur et un ingénieur mécanique partagent le profil TECHNIQUE. |

**L'objection attendue** — « une définition stricte réduit la réutilisation » — est vraie,
mais le repli est déjà correct : sans test, la note se calcule sur le soft seul. Une
réutilisation rare retombe donc sur le comportement d'avant, tandis qu'un test emprunté à
tort **fausserait** le classement. Un score faux est pire qu'un score absent.

### 4.3 Comment plusieurs tests se combinent

Une **moyenne pondérée par l'ordre de passage** : le plus récent compte 1, le précédent ½,
celui d'avant ¼, et ainsi de suite.

```
                 Σ ( pourcentage_i × poids_i )                    1
Score_Hard  =  ──────────────────────────────────    avec  poids_i = ───
                        Σ ( poids_i )                              2^(i-1)
```

**Exemple** — trois QCM sur le métier *Développeur* :

| Rang | Quand | Résultat | Poids |
|---|---|---|---|
| 1 | le mois dernier | 80 % | 1 |
| 2 | il y a 6 mois | 65 % | 0,5 |
| 3 | il y a 1 an | 40 % | 0,25 |

```
(80 × 1 + 65 × 0,5 + 40 × 0,25) / 1,75  =  122,5 / 1,75  =  70
```

Pour comparaison : « le plus récent seul » donnerait **80**, « moyenne simple » donnerait
**62**.

### 4.4 Deux propriétés qui rendent ce choix défendable

**Le présent l'emporte toujours.** La somme des poids de tous les tests plus anciens
(½ + ¼ + ⅛ + …) reste **strictement inférieure à 1**. Le test le plus récent pèse donc
toujours plus de la moitié, quel que soit le nombre de tests passés. L'historique compte,
il ne peut jamais écraser le présent.

**Le procédé n'est pas contournable.** Pour faire monter son estimation, il faut battre sa
propre moyenne pondérée — et un mauvais résultat entre dans l'historique sans jamais en
ressortir. Une agrégation par le *meilleur* score aurait récompensé la multiplication des
tentatives.

### 4.5 Pourquoi l'ordre et non l'ancienneté

Pondérer par l'âge (« un test de 6 mois compte moitié moins ») paraît plus naturel. C'est un
piège : la note **changerait tous les jours sans qu'aucun événement ne survienne**.

Or le système détecte les notes à rafraîchir en comparant leur date de calcul à celle de
leurs sources (partie 7). Une note dépendant du temps qui passe serait **périmée en
permanence** : la file de travail ne se viderait jamais.

Le poids par rang, lui, ne bouge qu'à la soumission d'un nouveau test — un événement déjà
géré.

### 4.6 Le test de l'offre consultée garde le premier rang

Même s'il est plus ancien qu'un test passé ailleurs.

Sans cette règle, un candidat effacerait un mauvais résultat sur une offre en repassant un
test sur une autre. Effet secondaire utile : la note **reste différenciée** entre deux
offres d'un même métier.

**Exemple** — le candidat a passé un test pour l'offre A il y a un an (40 %) et un test pour
l'offre C le mois dernier (80 %) :

| Offre consultée | Rang 1 | Rang 2 | Score hard |
|---|---|---|---|
| **A** (il y a son test) | A = 40 (×1) | C = 80 (×0,5) | **53** |
| **B** (même métier, pas de test) | C = 80 (×1) | A = 40 (×0,5) | **67** |

### 4.7 Quels tests comptent

| Statut du test | Compte ? |
|---|---|
| `COMPLETED` — terminé et noté | ✅ |
| `TIMEOUT` — temps écoulé, noté quand même | ✅ |
| `ABANDONED` — abandonné | ❌ |

Une tentative abandonnée n'est pas un résultat.

### 4.8 Le niveau du QCM d'origine est affiché, pas filtré

Chaque QCM est conçu par le recruteur pour son offre. **Sa difficulté n'est modélisée nulle
part.** Réutiliser un QCM d'une offre Junior pour une offre Manager surestime donc le
candidat.

Filtrer par niveau diviserait la réutilisation par ~4 pour arbitrer une grandeur qu'on ne
mesure pas. Le choix retenu : **afficher** le niveau de l'offre d'origine à côté de chaque
résultat, et laisser le lecteur juger.

### 4.9 ⚠️ Le sens du champ a changé

Le champ `hardSkillScore` valait auparavant, littéralement, « il a fait 80 % au QCM de cette
offre ». Il vaut désormais une estimation agrégée.

**Même champ, sens différent.** Si un écran affiche un jour « Test : 80 % » et
« Hard skills : 70 », ce sera signalé comme un bug alors que c'est correct. À trancher :
renommer le champ, ou ne jamais afficher les deux sans la liste des tests qui les
composent. Aucun écran mobile ne lit ce champ aujourd'hui — c'est le bon moment pour
décider.

> **Références** — `HardSkillLevelEstimate`, `HardSkillHistoryEntry`,
> `TestResultRepository.findHardSkillHistory()`

## 5. La matrice de pondération

### 5.1 Sa forme

**6 profils × 4 niveaux = 24 lignes.** C'est une table de référence **partagée** : deux
offres du même métier et du même niveau lisent la même ligne.

Chaque ligne porte **sept nombres** :

- le **poids soft** et le **poids hard** (leur somme fait 100)
- les **cinq poids de modules** (leur somme fait 100)

### 5.2 Les six profils

Le profil d'un métier est fixé une fois pour toutes dans le référentiel. Il détermine
**quels modules comptent** pour ce métier :

| Profil | Nombre de métiers | Module dominant |
|---|---|---|
| **TECHNIQUE** | 40 | Flexibilité cognitive et Prise de décision (30 chacun) |
| **ANALYTIQUE** | 32 | Prise de décision (30) |
| **MANAGERIAL** | 28 | Planification et Régulation émotionnelle (30 chacun) |
| **RELATIONNEL** | 24 | Régulation émotionnelle (45) |
| **ARTISTIQUE** | 10 | Flexibilité cognitive (40) |
| **CONVENTIONNEL** | 8 | Mémoire de travail et Planification (30 chacun) |

### 5.3 Les quatre niveaux, et le renommage V53

Les quatre bandes sont **JUNIOR · SENIOR · LEAD · MANAGER**.

⚠️ **Attention en lisant d'anciens documents.** Une migration antérieure (V29) avait renommé
positionnellement les bandes en Junior/Mid/Senior/Executive pour suivre un contrat externe.
Conséquence non vue à l'époque : **le pic du poids technique se retrouvait sur « Mid »**, et
la bande nommée « Senior » portait la pondération que le cahier des charges destine à un
Lead — alors que le §4.1 dit explicitement « Senior / Expert : hard skills dominant ».

La migration **V53** est l'inverse exact de V29. Depuis, un recruteur qui sélectionne
« Senior » obtient bien le pic de pondération technique.

Correspondance pour lire les documents antérieurs :

| Ancien nom | Nom actuel |
|---|---|
| JUNIOR | JUNIOR |
| MID | **SENIOR** |
| SENIOR | **LEAD** |
| EXECUTIVE | **MANAGER** |

### 5.4 La courbe du poids technique

Le poids hard n'est pas croissant avec le niveau. Il suit une **cloche** : faible chez le
junior (on ne l'a pas encore formé), maximal chez le senior (c'est un expert opérationnel),
puis redescendant chez le lead et le manager (le métier devient humain et stratégique).

**Poids hard par profil et par niveau — état actuel :**

| Profil | JUNIOR | SENIOR | LEAD | MANAGER |
|---|---|---|---|---|
| TECHNIQUE | 35 | **65** | 55 | 30 |
| ANALYTIQUE | 30 | **60** | 50 | 25 |
| ARTISTIQUE | 30 | **55** | 45 | 25 |
| MANAGERIAL | 20 | **40** | 35 | 20 |
| CONVENTIONNEL | 25 | **40** | 35 | 20 |
| RELATIONNEL | 10 | **25** | 20 | 10 |

Le poids soft est simplement le complément à 100.

### 5.5 Les poids de modules

Ils ne dépendent **que du profil**, pas du niveau : les quatre lignes d'un même profil
portent les mêmes cinq valeurs.

| Profil | Flexibilité cognitive | Mémoire de travail | Prise de décision | Planification | Régulation émotionnelle |
|---|---|---|---|---|---|
| TECHNIQUE | 30 | 20 | 30 | 15 | 5 |
| ANALYTIQUE | 25 | 20 | 30 | 15 | 10 |
| RELATIONNEL | 10 | 10 | 20 | 15 | **45** |
| MANAGERIAL | 10 | 10 | 20 | 30 | 30 |
| CONVENTIONNEL | 15 | 30 | 15 | 30 | 10 |
| ARTISTIQUE | **40** | 15 | 15 | 15 | 15 |

### 5.6 Les poids *effectifs* aujourd'hui ⚠️

C'est le tableau le plus important de cette partie, et le moins intuitif.

Puisque « Prise de décision » n'est mesurable par personne (3.4), son poids sort du
dénominateur. Les poids réellement appliqués ne sont donc **pas** ceux du tableau
précédent :

| Profil | Dénominateur réel | Flex. cognitive | Mém. travail | Planification | Rég. émotionnelle |
|---|---|---|---|---|---|
| TECHNIQUE | **70** | 30 → **42,9 %** | 20 → 28,6 % | 15 → 21,4 % | 5 → 7,1 % |
| ANALYTIQUE | **70** | 25 → **35,7 %** | 20 → 28,6 % | 15 → 21,4 % | 10 → 14,3 % |
| RELATIONNEL | **80** | 10 → 12,5 % | 10 → 12,5 % | 15 → 18,8 % | 45 → **56,3 %** |
| MANAGERIAL | **80** | 10 → 12,5 % | 10 → 12,5 % | 30 → **37,5 %** | 30 → **37,5 %** |
| CONVENTIONNEL | **85** | 15 → 17,6 % | 30 → **35,3 %** | 30 → **35,3 %** | 10 → 11,8 % |
| ARTISTIQUE | **85** | 40 → **47,1 %** | 15 → 17,6 % | 15 → 17,6 % | 15 → 17,6 % |

Sur un métier **Technique**, la flexibilité cognitive pèse donc en réalité **42,9 %** du
sous-score soft, pas 30 %. Le jour où « Je Décide » sera livré, tous ces pourcentages
changeront — sans qu'aucune ligne de code ne bouge.

⚠️ **Ce dénominateur, différent de 100, se propage plus loin qu'on ne l'imagine.** Il est
notamment ce qui invalide une justification du cahier des charges culture (partie 13.1).

### 5.7 « v1 — non calibré »

Les 24 lignes portent un drapeau `calibrated` à **false**, partout.

Les valeurs viennent de la matrice fournie par le métier, pas de données observées. Aucune
n'a été validée contre des résultats de recrutement réels. C'est une convention de départ,
et le drapeau existe pour que personne ne l'oublie.

### 5.8 Comment le niveau technique est mesuré : trois modes, portés par le métier

La matrice dit **combien** le technique pèse. Elle ne dit pas **comment** on le mesure — un
photographe et un développeur ne se jugent pas au même instrument. C'est le rôle d'un
troisième réglage, `type_evaluation_hard`, qui prend trois valeurs :

| Mode | Ce qu'on attend du candidat | Combien de métiers |
|---|---|---|
| **QCM** | Un test à choix multiples | 132 |
| **PORTFOLIO** | Des travaux à montrer, pas de test | 7 |
| **MIXTE** | Les deux — un portfolio *et* un test | 3 |

#### Pourquoi ce réglage vit sur le métier, et non sur le profil

Il a d'abord été posé sur la matrice, c'est-à-dire sur le couple **profil × niveau**. Cette
place le rendait incapable d'exprimer ce que le cahier des charges demande.

Le §4.3 nomme explicitement *UX/UI Designer* et *Motion designer* comme métiers hybrides, et
*Photographe*, *Illustrateur*, *Compositeur*, *Scénariste*, *Directeur artistique* comme
métiers à portfolio. Or **ces sept métiers sont tous de profil ARTISTIQUE**. Tant que le mode
était attaché au profil, ils partageaient forcément la même valeur : la distinction demandée
était littéralement inécrivable, quel que soit le soin apporté au reste.

Le réglage a donc été déplacé sur `job_positions` — un métier, un mode. Les dix métiers
ARTISTIQUE se répartissent ainsi :

| Mode | Métiers |
|---|---|
| **MIXTE** | UX/UI Designer · UX/UI e-commerce · Motion designer |
| **PORTFOLIO** | Photographe · Illustrateur / Concept artist · Compositeur / Sound designer · Scénariste · Directeur artistique · Graphiste / Designer · Styliste / Designer produit |

*UX/UI e-commerce*, *Graphiste* et *Styliste* ne sont pas nommés par le §4.3 : ils ont été
rangés par analogie avec les métiers voisins qui, eux, le sont. C'est le seul endroit de la
répartition qui relève d'un jugement plutôt que du texte, et il mérite d'être confirmé en
atelier.

#### Ce que MIXTE ne fait pas encore ⚠️

Le mode est **stocké et lisible**, mais le calcul du sous-score hard ne le distingue pas
encore de QCM : il n'existe ni pondération portfolio/test, ni support de dépôt de portfolio.
Un métier MIXTE se comporte donc aujourd'hui exactement comme un métier QCM.

Ce n'est pas un oubli mais un ordre : la donnée devait exister avant qu'on puisse écrire la
règle. Ce qu'il reste à trancher — quel poids donner au portfolio face au test — est une
question produit, pas technique.

### 5.9 L'alerte « ce poste attend un test technique »

À partir du poids hard **attendu** pour le métier, le système affiche un signal au recruteur
qui crée une offre sans QCM :

| Poids hard attendu | Alerte |
|---|---|
| < 20 | aucune |
| 20 à **35** | information |
| 36 à 49 | modérée |
| ≥ 50 | **forte** |

Deux règles se superposent à cette grille, et aucune ne se déduit des poids :

- **Le niveau MANAGER est fixé à « modérée »**, sans consulter la grille. Sans cette règle,
  la dérivation par le poids produirait l'inverse de ce que le cahier des charges demande :
  le poids hard d'un Manager est souvent *inférieur* à celui d'un Junior (30 contre 35 sur
  TECHNIQUE), donc le poste le plus exposé alerterait *moins*. La règle fixe la valeur au
  lieu de poser un plancher : un Manager ne peut donc pas atteindre « forte ». Sans effet
  aujourd'hui — aucune ligne MANAGER de la matrice n'atteint 50 — mais à savoir le jour où
  la matrice sera recalibrée.
- **La borne de l'information inclut 35**, et non 34. C'est la valeur de TECHNIQUE/JUNIOR,
  probablement le plus gros volume de la plateforme : à 34, il basculait en « modérée ».

Les métiers évalués par portfolio reçoivent un signal **à part entière**, distinct de
l'information — pour eux, l'absence de QCM est le fonctionnement normal et non une chose à
corriger. Le distinguer évite qu'un client affiche « pensez à ajouter un test » à un
photographe.

**Le signal se lit sur le mode du métier, pas sur la famille.** Ce point a été un défaut
pendant deux jours, et il vaut d'être retenu : la décision se prenait sur
`profileType == ARTISTIQUE`, ce qui était exact tant que le mode vivait sur la matrice. Le
déplacement du réglage sur le métier (5.8) a rendu cette lecture fausse sans rien casser de
visible — *UX/UI Designer*, *UX/UI e-commerce* et *Motion designer* annonçaient « pas de
test attendu » alors que leur mode en réclame un, et leur recruteur n'était jamais averti du
QCM manquant. Exactement les trois métiers pour lesquels le déplacement avait été fait.

C'est le mode d'échec typique d'un réglage qu'on déménage : l'ancien lecteur continue de
répondre, et il répond faux. Un test sur base réelle vérifie désormais que deux métiers de
la même famille et de la même ligne de pondération — *Photographe* et *UX/UI Designer* —
reçoivent bien deux signaux différents.

> **Références** — migrations `V42__job_role_profiles.sql`,
> `V53__experience_level_back_to_cdc_scale.sql`, `V60__type_evaluation_hard_by_job_position.sql`,
> `V26__job_positions_seed.sql`, `JobRoleProfile`, `JobPosition.typeEvaluationHard()`

---

# Partie II — Quand le score est calculé

## 6. Six chemins, une seule formule

La formule de la partie I est **unique**. Ce qui varie, c'est *quand* et *pour quelles
paires* elle est déclenchée.

| # | Chemin | Déclencheur | Portée | Statut |
|---|---|---|---|---|
| 1 | Partie jouée | Le candidat termine un mini-jeu | Toutes les offres du fil du candidat | ✅ |
| 2 | Offre publiée | Une offre passe ACTIVE | Tous les candidats ayant joué | ✅ |
| 3 | Test soumis | Un QCM est terminé | L'offre testée **+ toutes les offres ACTIVE du même métier** | ✅ |
| 4 | Calcul à l'affichage | Le candidat ouvre son fil | Les offres affichées sans note | 🔧 |
| 5 | File de travail | Réveil après commit | Ce qui a été enfilé par 1, 2, 3 | 🔧 |
| 6 | Pré-remplissage | Toutes les heures | Paires sans note ou périmées | ✅ |

### 6.1 Les trois déclencheurs événementiels

Ils réagissent à un fait métier, **après validation en base** (jamais avant : une
transaction annulée ne doit rien déclencher). Ils n'exécutent pas le calcul eux-mêmes — ils
**enfilent** le travail.

Le troisième a changé de portée : un test soumis modifie désormais l'estimation technique du
candidat sur **tout le métier**, donc toutes les offres ACTIVE de ce métier sont reprises,
pas seulement celle du QCM.

### 6.2 Le calcul à l'affichage 🔧 — la garantie d'exactitude

C'est la couche la plus importante conceptuellement : **elle transforme le travail de fond
d'une garantie en une optimisation.**

Quand un candidat ouvre son fil, les offres affichées sans note sont calculées **sur place**,
avant le classement. Une offre affichée ne peut donc plus être reléguée en fin de liste
faute de note.

Deux garde-fous :

- un **budget de temps** (800 ms par défaut) — un budget, pas un compteur de paires : il
  reste valable si le matériel ou le code change ;
- un plafond de 200 paires, ceinture doublant la bretelle, jamais atteint en pratique.

Cette couche **ne fait jamais échouer la requête** : si le calcul déborde ou échoue,
l'affichage se poursuit avec ce qui existe.

### 6.3 La file de travail 🔧

Une table en base, pas une file en mémoire : le travail **survit à un redémarrage**.

- deux priorités — *urgente* (déclenchée par un événement) et *normale* (pré-remplissage) ;
- réservation concurrente sûre : deux instances ne traitent jamais la même ligne ;
- réveil **après validation de la transaction** qui a enfilé — la réveiller avant la ferait
  lire une file où la ligne n'est pas encore visible ;
- après cinq échecs, une paire est abandonnée. Elle n'est pas perdue : le calcul à
  l'affichage la reprendra. C'est ce filet qui **autorise la file à échouer**.

### 6.4 Le pré-remplissage

Un passage horaire qui cherche les paires sans note ou périmées et les enfile en priorité
normale. Borné par une **échéance** (5 secondes) et une taille de lot (200 paires).

Le plafond de 200 ne borne pas la capacité de calcul — il borne la **pression exercée sur la
base partagée avec le trafic utilisateur**. Le vrai plafond du système est ce budget base de
données, pas le processeur.

**En régime normal, ce passage ne doit rien trouver.** Toute valeur non nulle durable
signale un problème ailleurs.

### 6.5 Un seul calcul, deux modes de chargement

Le calcul pur est identique partout. Seul le **chargement des données** diffère : paire par
paire pour les déclencheurs, en masse pour les lots. Un test d'équivalence verrouille le
fait que les deux chemins produisent des scores **identiques** — c'est ce qui autorise à les
faire coexister.

> **Références** — `GameSoftSkillsListener`, `JobOfferFitScoreListener`,
> `TestResultRecomputeListener`, `InlineFitScoreComputer`, `FitScoreQueueWorker`,
> `FitScoreBackfillWorker`, `RecomputeFitScoresUseCase`

## 7. La péremption — savoir qu'une note est devenue fausse

Une note calculée hier peut être fausse aujourd'hui. Le système compare la **date de calcul**
de chaque note à celle de ses **quatre sources** :

| Source | La note est périmée si elle précède… |
|---|---|
| L'offre | la dernière modification de l'offre |
| Les soft skills | la dernière partie jouée par le candidat |
| Les tests | le dernier QCM noté du candidat **sur ce métier** |
| La pondération | la dernière modification de la ligne métier × niveau |

**Pourquoi des horodatages plutôt que des numéros de version.** Ces quatre dates sont déjà
maintenues par le code existant. Une colonne « version » exigerait de penser à l'incrémenter
à chaque écriture — et en oublier une seule recréerait le bug d'origine, **en silence**.

**La quatrième source mérite une mention.** Aucun déclencheur ne réagissait à un changement
de pondération. Or le jour où l'atelier RH livrera ses valeurs calibrées, *toutes* les notes
en cache deviendront fausses d'un coup — et c'est le scénario le plus certain du projet,
puisque cet atelier est le prérequis déclaré de la mise en production.

Le mécanisme **converge** : un recalcul porte la date de calcul à maintenant, donc au-dessus
des quatre sources, et la paire cesse d'être sélectionnée.

> **Références** — `JpaFitScoreRepository.findStalePairs()`

## 8. Ce qui n'est jamais calculé

| Cas | Comportement |
|---|---|
| Métier non approuvé par un admin | Aucune note. Le pré-remplissage la calculera dès l'approbation — aucun mécanisme séparé à construire. |
| Offre fermée | Les notes sont **purgées**. Une offre rouverte les verra recalculées. |
| Candidat inactif | Traité **en dernier**, jamais exclu. |
| Offre sans métier | Incalculable. Le métier est obligatoire à la création depuis la suppression du repli IA. |

⚠️ La notion de « candidat inactif » n'a pas de source fiable aujourd'hui — aucune colonne ne
représente une vraie dernière activité. C'est précisément pourquoi ce critère est une
**priorité de tri et jamais une exclusion** : avec un indicateur imparfait, le pire cas est
un ordre sous-optimal, pas une note manquante.

---

# Partie III — Les deux classements

> Le Fit Score est une **entrée** de ces classements. Il n'est pas le classement.

Il existe deux listes, elles ne fonctionnent pas pareil, et les confondre est la source
d'incompréhension la plus fréquente.

## 9. Le fil du candidat — « Recommended for you »

### 9.1 Deux seaux, jamais d'exclusion

Les offres sont réparties en deux groupes : celles qui ont une note, celles qui n'en ont
pas. **Les notées passent toujours devant.** Aucune offre n'est jamais retirée de la liste.

### 9.2 Le tri à l'intérieur de chaque seau

```
Offres notées      :  Fit Score  +  bonus
Offres non notées  :               bonus
```

Le bonus se compose de deux parties :

```
bonus = (nombre de préférences respectées × 2,0)  +  (similarité sémantique × 2,0)
```

**Les préférences** — quatre critères, un point chacun :

| Critère | Respecté quand |
|---|---|
| Type de lieu de travail | La préférence du candidat correspond à l'offre |
| Type de contrat | Idem |
| Localisation | La ville ou le pays de l'offre correspond au lieu visé |
| Ouverture à l'international | Les deux valeurs coïncident |

Une préférence **non renseignée** ne compte ni en bonus ni en pénalité. Ce n'est jamais un
filtre bloquant : la règle produit est « 3 critères sur 4 respectés → on montre quand
même ».

**La similarité sémantique** compare l'empreinte numérique du texte libre « rôle recherché »
du candidat à celle du **nom du métier** de l'offre. Elle vaut entre 0 et 1, et est
multipliée par 2.

### 9.3 ⚠️ Ce que la similarité compare réellement

Trois limites à connaître :

1. Elle compare au **nom du métier**, pas au contenu de l'offre.
2. Elle exige une clé d'API pour le service d'empreintes.
3. Un candidat **sans texte « rôle recherché » n'a pas d'empreinte** — son bonus sémantique
   vaut donc 0.

Si peu de candidats renseignent ce texte, le signal sémantique est largement **inerte en
pratique**. C'est mesurable, et cela n'a pas encore été mesuré.

### 9.4 L'ordre de grandeur

Le bonus maximal vaut `4 × 2,0 + 1 × 2,0 = 10 points`, contre un Fit Score allant jusqu'à
100. Le Fit Score reste donc **le signal dominant** ; le bonus départage, il ne renverse
pas.

> **Références** — `CandidateFeedRanker`, réglages `recruitment.ranking.*`

## 10. Le deck du recruteur ✅

### 10.1 Deux groupes : les évalués d'abord

Le tri se fait sur **deux clés, dans cet ordre** :

1. **Le candidat a-t-il une note technique ?** → ceux qui en ont une passent devant.
2. **Sa note**, décroissante → seulement à l'intérieur de chaque groupe.

### 10.2 L'inversion que cela corrige

Ce n'est pas un confort d'affichage. Sans ce classement, le système présentait
**systématiquement** les candidats dans le mauvais ordre.

Faute de test, la note d'un candidat est son score comportemental **brut**. Un candidat
évalué, lui, voit sa note **tirée** vers son résultat au QCM. Sur un métier
TECHNIQUE / SENIOR (poids hard = 65) :

| Candidat | Soft | QCM | Calcul | Note |
|---|---|---|---|---|
| **A** — n'a pas passé le test | 70 | — | 70 | **70** |
| **B** — a passé le test à 60 % | 70 | 60 % | 0,35 × 70 + 0,65 × 60 | **64** |

Même profil comportemental. Seul le QCM les sépare — et c'est **celui qui l'a passé** qui
était relégué derrière.

### 10.3 Pourquoi on ne corrige pas la formule

Pour faire descendre le 70 sous le 64, il faudrait **retirer des points au candidat qui n'a
pas de test**. C'est-à-dire le pénaliser pour une donnée manquante — ce que le cahier des
charges interdit, et ce que tout le reste du système évite soigneusement (2.2).

Le classement en deux groupes, lui, **ne touche à aucune note**.

### 10.4 Ce que le classement dit, et ne dit pas

Il ne dit **pas** « B est meilleur que A ». Il dit :

> La note de B repose sur une mesure complète. Celle de A repose sur la moitié de
> l'information.

Ce n'est pas définitif : si A passe le test et obtient 80 %, il rejoint le premier groupe et
repasse devant. Le groupe traduit un **état de la mesure**, pas un jugement sur la personne.

> **Références** — `GetSwipeDeckUseCase.recruiterCandidates()`

---

# Partie IV — La pondération assistée par la culture ❌ *abandonnée*

> **Décision du 11 août 2026 : cette pondération ne sera pas construite.** La pondération
> de base par métier et niveau, déjà validée, reste seule en vigueur.
>
> Cette partie est conservée telle qu'elle a été écrite, parce qu'elle est la trace du
> raisonnement qui a mené à l'abandon. Elle ne décrit pas une cible : elle décrit ce qui a
> été étudié puis écarté, et pourquoi. Les motifs sont en 10 bis.
>
> L'analyse détaillée reste dans `PLAN_PONDERATION_CULTURE.md`, et les mesures qui ont
> emporté la décision dans `PONDERATION_CULTURE_TROIS_QUESTIONS.md`.

## 10 bis. Pourquoi elle est abandonnée

Le cahier des charges « Pondération assistée » v3.0 a été instruit, et trois questions ont
été posées : la méthode d'extraction, l'origine du chiffre du bonus, et la règle
d'absorption. Les réponses chiffrées ont conduit à ne pas engager le sujet.

**Ce qui a emporté la décision :**

| Constat | Détail |
|---|---|
| **On mesure la rédaction, pas la culture** | Mesuré : un texte RH parfaitement générique obtient le **même bonus maximal** (+9) qu'un texte décrivant une culture réellement marquée. Le comptage d'expressions mesure la richesse du vocabulaire employé, pas l'intensité d'une culture. |
| **Une entreprise n'a pas une culture unique** | Un poste en R&D et un poste en conformité cherchent des profils opposés — alors que les recruteurs réutilisent le même paragraphe de présentation sur toutes leurs offres. |
| **Le sujet est sensible** | Le fit culturel porte un risque de biais réel, dans un domaine que l'AI Act classe à haut risque. |
| **La proportion n'y est pas** | ~11 jours de développement, un atelier RH, une analyse d'impact RGPD et des tests de non-discrimination — pour un signal dont la valeur ajoutée restait à démontrer. |

**Une nuance, pour qui rouvrirait le sujet.** Le CdC v3.0 avait partiellement anticipé
l'objection des cultures multiples : il prévoyait d'analyser la description du poste *avec*
le profil entreprise, et de faire primer la description du poste en cas de contradiction.
Cela n'annule pas l'objection — précisément parce que le paragraphe réutilisé d'une offre à
l'autre est justement celui qui porte la culture, tandis que la description du poste parle
du rôle. Le mécanisme prévu ne rattrape donc pas le défaut qu'il visait.

**Ce qui reste vrai malgré l'abandon** : les mesures d'absorption de la partie 13 gardent
leur valeur. Si un jour un poids de module doit être ajusté pour une raison quelconque, la
règle de répartition proportionnelle avec plancher est démontrée sûre, et la répartition à
parts égales démontrée inapplicable.

## 11. Le principe

Aujourd'hui, la pondération dépend **uniquement** du métier et du niveau. Deux entreprises
recrutant le même poste obtiennent exactement la même pondération, quelle que soit leur
culture.

L'objectif : repérer dans le **profil de l'entreprise** et la **description du poste** des
signaux de culture, puis **proposer** un ajustement — sans jamais l'appliquer seul.

| Étape | Ce qui se passe | Qui agit |
|---|---|---|
| 1. Détection | Le système repère des mots clés dans les deux textes | Le système |
| 2. Suggestion | Il propose un ajustement chiffré et plafonné, en affichant les mots clés qui le motivent | Le système |
| 3. Décision | Le recruteur clique **Accepter** ou **Ignorer** | **Le recruteur** |

Six profils de culture, un par module :

| Profil de culture | Module bonifié | Exemples de mots clés |
|---|---|---|
| Innovation / Créative | Flexibilité cognitive | innovation, créativité, agilité |
| Rigueur / Process | Mémoire de travail | rigueur, précision, conformité |
| Autonomie / Entrepreneuriale | Prise de décision | autonomie, ownership, initiative |
| Performance / Exécution | Planification exécutive | excellence opérationnelle, delivery |
| Collaborative / Humaine | Régulation émotionnelle | bienveillance, collectif, écoute |
| Mixte / non tranchée | aucun | aucun signal dominant |

## 12. Où elle s'insère

C'est le point que ce document permet enfin de situer précisément :

```
   Matrice fixe (24 lignes)
            │
            ▼
   ┌──────────────────────┐
   │  Détection + suggestion │   ← une fois par offre, à la publication
   └──────────────────────┘
            │
            ▼
   Décision du recruteur  ──── Ignorer ───►  poids de base inchangés
            │
         Accepter
            ▼
   Poids ajustés, stockés sur l'offre
            │
            ▼
   ══════════════════════════════════════
   FORMULE DU FIT SCORE  (partie I)          ← lit des NOMBRES, jamais du texte
   ══════════════════════════════════════
```

Trois conséquences :

1. **La détection n'est jamais sur le chemin du calcul.** Elle tourne une fois par offre,
   pas une fois par paire. Son coût est découplé de la latence du Fit Score.
2. **Le texte n'atteint jamais le calculateur.** Seuls des nombres validés par un humain y
   entrent.
3. **Le socle n'est jamais modifié.** La suggestion part toujours de la matrice fixe, jamais
   d'un résultat déjà ajusté — pas de dérive cumulative.

Accepter une suggestion **modifie l'offre**, ce qui rend automatiquement périmées toutes les
notes concernées (partie 7). Aucun mécanisme de rafraîchissement n'est à construire.

## 13. Le calcul de la suggestion

Deux couches ajustables :

| | Couche C — modules | Couche D — split Hard/Soft |
|---|---|---|
| Ce qu'elle déplace | La répartition entre les 5 modules | Le curseur technique / comportemental |
| Plafond proposé | ± 8 à 10 points | ± 5 points |

### 13.1 ⚠️ La justification du plafond de la couche D ne tient pas

Le cahier des charges justifie le plafond plus bas de la couche D par un « impact plus fort
sur le classement final ». **Vérifié sur les 24 lignes réelles, c'est l'inverse dans 21 cas
sur 24.**

Le calcul :

```
Couche C :  effet max  =  8 × PoidsSoft / dénominateur     (dénominateur = 70 à 85, cf. 5.6)
Couche D :  effet max  =  5                                (déplacement direct de 5 points)
```

Le point que le cahier des charges ne pouvait pas connaître : **le dénominateur du
sous-score soft n'est pas 100**, mais 70 à 85 selon le profil, puisque « Prise de décision »
en est exclu. Un déplacement de 8 points de poids pèse donc *plus* que 8 % du sous-score.

| Ligne | Poids soft | Dénominateur | Effet max couche C | Effet max couche D |
|---|---|---|---|---|
| RELATIONNEL Junior · Manager | 90 | 80 | **9,0 pts** | 5,0 pts |
| ANALYTIQUE Manager | 75 | 70 | **8,6 pts** | 5,0 pts |
| TECHNIQUE Manager | 70 | 70 | **8,0 pts** | 5,0 pts |
| MANAGERIAL Senior | 60 | 80 | **6,0 pts** | 5,0 pts |
| ARTISTIQUE Senior | 45 | 85 | 4,2 pts | **5,0 pts** |
| TECHNIQUE Senior | 35 | 70 | 4,0 pts | **5,0 pts** |

La couche C va de **4,0 à 9,0 points** de note finale ; la couche D vaut 5,0 partout.

**La couche D n'est plus forte que sur les trois lignes les plus techniques** (TECHNIQUE
Senior, ANALYTIQUE Senior, ARTISTIQUE Senior) — précisément celles où le poids soft est le
plus faible. Partout ailleurs, c'est la couche C qui déplace le plus.

Avec un plafond de 10 au lieu de 8, la couche C atteint **11,2 points** sur RELATIONNEL
Junior — plus du double de la couche D.

**Conséquence pratique** : si l'objectif est de borner l'influence d'une suggestion, c'est
le plafond de la **couche C** qu'il faut resserrer, pas celui de la couche D. Et le plafond
devrait dépendre du profil, ou être exprimé en effet sur la note finale plutôt qu'en points
de poids.

### 13.2 Les cinq étapes de la normalisation

La contrainte est absolue : après ajustement, la somme des 5 modules doit valoir **exactement
100**, et soft + hard aussi.

1. **Déterminer les absorbeurs** — les modules sans signal détecté et non bonifiés. Un
   module qui a un signal mais n'est pas bonifié (parce que déjà dominant) ne doit pas
   absorber : le pénaliser contredirait son propre signal.
2. **Plafonner par la capacité d'absorption.** Si les absorbeurs pèsent 5 points au total,
   on ne peut pas leur en retirer 16. Le bonus total est donc borné par une fraction du
   poids total des absorbeurs.
3. **Répartir proportionnellement au poids**, jamais à parts égales.
4. **Corriger le reste d'arrondi.** Les poids sont des entiers ; une répartition
   proportionnelle produit des décimales. Il faut une règle déterministe d'attribution du
   point restant, sinon la somme ne fait plus 100.
5. **Vérifier l'invariant** avant d'écrire. Si la somme n'est pas exactement 100, rejeter la
   suggestion entière plutôt qu'écrire une pondération incohérente.

### 13.3 Pourquoi la répartition proportionnelle est obligatoire

Cas réel, métier TECHNIQUE (30 / 20 / 30 / 15 / **5**), avec 16 points à absorber par trois
modules pesant 30, 30 et 5 :

| Méthode | Régulation émotionnelle (5 %) |
|---|---|
| À parts égales (−5,33 chacun) | **−0,33 %** ⚠️ poids négatif |
| Proportionnelle (−1,23) | 3,77 % ✅ |

Une répartition à parts égales produit un poids négatif. La répartition proportionnelle
garantit qu'aucun module ne peut perdre plus qu'il ne possède.

Le split Hard/Soft, lui, est trivial : deux valeurs, l'une monte de δ, l'autre descend de δ.
Vérifié sur la matrice réelle — le poids hard va de 10 à 65, donc un ±5 reste toujours dans
l'intervalle [5, 70]. **Le plafond de ±5 est sûr sur les 24 lignes.**

## 14. Ce qui reste à trancher ⚠️

| # | Point | Pourquoi c'est bloquant |
|---|---|---|
| 1 | **Contradiction avec le cahier des charges Fit Score** | Le §2 pose que la description libre d'une offre n'est *jamais* une source de pondération automatique — et une tâche antérieure a **retiré** ces textes des entrées du calculateur. Les deux textes ne se réconcilient que si la décision du recruteur reste obligatoire. Non mentionné dans le document culture. |
| 2 | **Le profil « Autonomie » bonifie un module non mesurable** | Il bonifie « Prise de décision », que personne ne peut alimenter. Le bonus serait inerte — et pire, la compensation retirerait des points aux autres modules pour le financer. Le score **baisserait**. |
| 3 | **« Module déjà dominant » n'a pas de seuil** | Est-ce « le module le plus lourd » (règle autoporteuse) ou « au-dessus de X % » (il faut le chiffre) ? |
| 4 | **Une décision ou deux ?** | Le document décrit un clic binaire unique, mais son exemple ignore la couche D tout en acceptant la couche C. Ce sont donc deux décisions — à confirmer, cela change l'écran et le journal d'audit. |
| 5 | **La re-détection** | Si le recruteur modifie la description après avoir accepté, que devient la pondération validée ? Non traité. |
| 6 | **Dictionnaires monolingues** | Ils sont en français ; l'application est bilingue. Un dictionnaire monolingue renverrait « aucun signal » sur une partie des offres, **silencieusement** — le pire mode d'échec. |
| 7 | **Le compteur d'expressions favorise les textes longs** | Une page « À propos » de 3000 mots atteint 5 expressions sans effort. Le bonus mesure alors la verbosité, pas la culture. |
| 8 | **Le bonus est en points absolus** | Sur TECHNIQUE, la régulation émotionnelle vaut 5 %. Un +8 la **triple**, à partir de deux mots clés. La règle « pas de bonus au module dominant » protège le haut de l'échelle, rien ne protège le bas. |
| 9 | **Aucun journal d'audit n'existe** dans le projet | Le journal exigé (mots clés, source, delta, date, recruteur) est une construction entièrement nouvelle. Ce n'est pas un confort : c'est une exigence réglementaire, qui impose de traiter la rétention, l'accès et surtout l'**immuabilité**. |

### 14.1 Sur le choix de la méthode de détection

Le document ne tranche pas explicitement entre mots clés, analyse sémantique et modèle de
langage. La recommandation, et sa raison :

| | Mots clés | Empreintes sémantiques | Modèle de langage |
|---|---|---|---|
| Coût par offre | microsecondes | ~50 ms | 300–1000 ms |
| Reproductible | oui | oui | **non** |
| Montrable à un candidat | **le mot clé lui-même** | une distance cosinus | rien |

La performance ne décide pas — la détection n'est pas sur le chemin critique (partie 12).
C'est l'**explicabilité** qui décide : le règlement impose de pouvoir justifier la
pondération appliquée, et seul un mot clé se montre.

La faiblesse des mots clés est le **rappel** : « chacun est maître de son périmètre »
exprime l'autonomie sans contenir aucun mot du dictionnaire. C'est acceptable **parce qu'un
humain décide** — un signal manqué ne produit aucune suggestion, un faux signal produit une
suggestion qu'on ignore. Les deux modes d'échec laissent la pondération de base en place.

Piste utile : employer le modèle d'empreintes déjà présent dans le projet **hors ligne**,
pendant l'atelier RH, pour aider à *construire* le dictionnaire — pas pour décider offre par
offre.

---

# Annexes

## A. Comment vérifier soi-même

**La matrice telle qu'elle est réellement en base :**

```sql
SELECT profile_type, level, soft_weight, hard_weight,
       cognitive_flexibility_weight, working_memory_weight, decision_making_weight,
       executive_planning_weight, emotional_regulation_weight, calibrated
FROM recruitment.job_role_profiles
ORDER BY profile_type, hard_weight DESC;
```

**Le mode d'évaluation technique par métier (5.8) :**

```sql
SELECT type_evaluation_hard, count(*), string_agg(name, ' · ' ORDER BY name)
FROM recruitment.job_positions
WHERE type_evaluation_hard <> 'QCM'
GROUP BY type_evaluation_hard;
```

⚠️ Sur une base de développement, les totaux dépassent 142 : les métiers proposés par les
recruteurs pendant les démonstrations s'y accumulent. Pour retrouver le référentiel seul,
lire `V26__job_positions_seed.sql`.

**Les notes d'un candidat, avec le détail des sous-scores :**

```sql
SELECT o.title, f.score, f.soft_skill_score, f.hard_skill_score, f.coverage_ratio, f.computed_at
FROM recruitment.fit_scores f
JOIN recruitment.job_offers o ON o.id = f.job_offer_id
WHERE f.candidate_id = '...'
ORDER BY f.score DESC;
```

**L'historique technique d'un candidat sur un métier :**

```sql
SELECT o.title, o.experience_level, t.percentage, t.status, t.completed_at
FROM recruitment.test_results t
JOIN recruitment.job_offers o ON o.id = t.job_offer_id
WHERE t.candidate_id = '...' AND o.job_position_id = '...'
ORDER BY t.completed_at DESC;
```

**La suite de tests :**

```bash
cd backend && ./mvnw test
```

## B. Les réglages, et leur effet

| Réglage | Défaut | Effet |
|---|---|---|
| `recruitment.ranking.criterion-bonus` | 2,0 | Points par préférence candidat respectée |
| `recruitment.ranking.semantic-weight` | 2,0 | Multiplicateur de la similarité sémantique |
| `recruitment.ranking.pool-size` | 200 | Offres reclassées avant pagination |
| `recruitment.fitscore.db-pool-size` | 2 | Connexions maximales du travail de fond, sur un pool de 10 — au moins 8 restent aux utilisateurs |
| `recruitment.fitscore.inline.enabled` | **false** | Interrupteur du calcul à l'affichage |
| `recruitment.fitscore.inline.budget-ms` | 800 | Budget de temps par requête d'affichage |
| `recruitment.fitscore.queue.enabled` | **false** | Interrupteur de la file de travail |
| `recruitment.fitscore.queue.chunk-size` | 200 | Taille de transaction du worker |
| `recruitment.fitscore.queue.max-attempts` | 5 | Essais avant abandon d'une paire |
| `recruitment.fitscore.queue.retention-days` | 7 | Rétention de l'historique de la file |
| `recruitment.fitscore-backfill.interval-ms` | 3 600 000 | Une heure entre deux pré-remplissages |
| `recruitment.fitscore-backfill.deadline-ms` | 5 000 | Budget d'un passage |
| `recruitment.fitscore-backfill.batch-size` | 200 | Paires par passage — borne la pression sur la base, pas le processeur |

Tous sont modifiables par variable d'environnement, **sans redéploiement**.

## C. Glossaire

| Terme | Définition |
|---|---|
| **Métier** | Un des 142 postes du référentiel (« Développeur », « Data Analyst »…). Obligatoire sur chaque offre. |
| **Profil** | Une des 6 familles (TECHNIQUE, ANALYTIQUE…). Attribuée à un métier, elle détermine les poids de modules. |
| **Niveau** | Une des 4 bandes (JUNIOR, SENIOR, LEAD, MANAGER). Choisi par le recruteur sur l'offre. |
| **Mode d'évaluation** | Comment le niveau technique se mesure pour un métier : QCM, PORTFOLIO ou MIXTE. Porté par le métier, pas par le profil. |
| **Module** | Une des 5 dimensions psychométriques mesurées par les mini-jeux. |
| **Couverture** | Part d'un module réellement mesurée, de 0 à 100. |
| **Paire** | Un couple (candidat, offre) — l'unité de calcul du Fit Score. |
| **Seau** | Groupe du fil candidat : offres notées / non notées. |
| **Groupe** | Groupe du deck recruteur : candidats évalués / non évalués. |
| **Périmé** | Note calculée avant la dernière évolution d'une de ses sources. |

## D. Ce qui reste ouvert, tous sujets confondus

| Sujet | État |
|---|---|
| Le mini-jeu « Prise de décision » | Non jouable — le catalogue de 30 scénarios est vide. Un module sur cinq ne compte donc dans aucun score. C'est le dernier trou du référentiel de jeux. |
| Le calcul du mode MIXTE | Le mode est stocké et lisible, mais le sous-score hard ne le distingue pas encore de QCM. Ni pondération portfolio/test, ni dépôt de portfolio. |
| L'alerte hard skills sur les métiers MIXTE | ✅ Corrigé le 11 août 2026 — l'alerte suit le mode du métier, vérifié sur base réelle (5.9). |
| La calibration des 24 lignes | `calibrated = false` partout. Atelier RH requis. |
| Le seuil « bon profil » à 70 | Marqué provisoire dans le code, jamais validé par le produit. |
| Les seuils de couverture 60 / 70 | À valider avec les RH. |
| La couverture réelle du signal sémantique | Jamais mesurée. Potentiellement inerte si peu de candidats renseignent leur « rôle recherché ». |
| Le renommage de `hardSkillScore` | À trancher — le champ a changé de sens. |
| Le fonctionnement multi-instance | Le réveil du worker est interne au processus. |
| La charge réelle en production | Jamais mesurée. Le bornage du travail de fond l'encadre en attendant. |
| La pondération culture | ❌ **Abandonnée le 11 août 2026.** Le texte d'une offre n'est pas une base fiable pour ajuster un score — voir 10 bis. La pondération de base par métier reste seule en vigueur. |

---

*Module Recrutement — projet Zennyt. Toutes les valeurs de ce document proviennent du code
et des migrations, pas d'estimations. État au 11 août 2026.*
