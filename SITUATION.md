# Situation — Fit Score, où on en est et quoi faire ensuite

*Point d'arrêt : 5 août 2026, après la lecture du nouveau `GAMES_MODULE.md`.*

---

## 1. Le problème qu'on essayait de régler

Un candidat qui **saute** un mini-jeu qu'il aurait raté **gagnait 11 points**. C'est un vrai problème d'équité : n'importe qui pouvait en profiter.

La cause : quand un jeu manquait, le système **redistribuait ses points** sur les jeux joués. Donc moins on jouait, moins on avait d'occasions de perdre des points.

## 2. Ce qui a été décidé (validé)

**On ne peut pas simplement dire « jeu non joué = 0 ».** Parce qu'il y a deux situations très différentes :

| Situation | Ce que ça veut dire | Décision |
|---|---|---|
| Le candidat **a sauté** un jeu qui existe | il a choisi de ne pas être mesuré | **il perd les points** |
| Le jeu **n'existe pour personne** | la plateforme ne sait pas encore mesurer | **il ne compte pas du tout** |

**Pourquoi cette distinction est nécessaire :** le jeu « Je Décide » n'est pas jouable. Pas parce qu'il n'est pas développé — il l'est entièrement — mais parce que ses **30 scénarios attendent le psychologue**.

Sans cette distinction, ce jeu compterait 0 pour tout le monde, et **plafonnerait tous les développeurs à 70/100** — soit exactement le seuil « bon profil ». Plus aucun développeur ne pourrait jamais être un bon profil.

> **En une phrase :** on ne punit personne pour un jeu qui n'existe pas, on punit ceux qui sautent un jeu qui existe.

Le jour où les 30 scénarios arrivent, le jeu rentre automatiquement dans le calcul. **Sans retoucher au code.**

---

## 3. Ce qu'on vient de découvrir (le nouveau `GAMES_MODULE.md`)

L'équipe Jeux a livré **3 jeux entiers** qu'on n'a pas encore :

| Jeu | Ce qu'il mesure | État |
|---|---|---|
| **« Je continue »** | Attention soutenue | 🟢 Complet |
| **« Je coordonne »** | Coordination visuo-motrice | 🟢 Complet |
| **« Je place »** | Mémoire visuo-spatiale | 🟢 Complet |

### Ce ne sont pas de nouveaux modules

Le cahier des charges a **5 modules**, et il en a toujours 5. Le hub mobile a d'ailleurs exactement 5 cartes. Les nouveaux jeux sont des **mesures supplémentaires de modules qui existent déjà** :

| Module | Jeux qui l'alimentent |
|---|---|
| **Flexibilité cognitive** | Move Fast + **Je continue** + **Je coordonne** ← 3 jeux |
| **Mémoire de travail** | Memory Quest + **Je place** ← 2 jeux |
| Prise de décision | Je Décide *(bloqué)* |
| Planification exécutive | Planifik |
| Régulation émotionnelle | Radar + Reflective Pause |

### 🔴 Mais ça casse le calcul

Le calcul additionne le poids de chaque ligne qui lui arrive.

- **Planifik** a 3 mini-jeux, mais ils sont regroupés côté Jeux → **une seule ligne** arrive. ✅
- **Flexibilité cognitive** a 3 jeux **séparés** → **trois lignes** arrivent. ❌

Résultat : la Flexibilité cognitive serait comptée **trois fois** — 90 points sur 100 au lieu de 30. Elle écraserait tous les autres modules.

**Ce n'est pas encore visible** (ces jeux ne sont pas fusionnés), **mais ça casserait le jour de la fusion.**

---

## 4. Ce qui est déjà fait et livré

Sur la branche `fix/fitscore-track-a-moteur`, **3 corrections terminées et testées** :

| # | Correction | Effet |
|---|---|---|
| 1 | Un module inconnu devenait tout le score · l'absence de donnée devenait un 0 · un arrondi prématuré · du code mort | Les scores ne peuvent plus être pilotés par une donnée non reconnue |
| 2 | **La couverture réelle par jeu** — combien de chaque jeu a été joué | Le cahier des charges le prévoyait, ça n'existait nulle part |
| 3 | Les jeux envoient un résultat **à chaque mini-jeu**, plus seulement à la fin | Avant, une partie interrompue ne produisait **rien du tout** |

À chaque étape : **328 tests au vert**, base recréée à zéro, application démarrée.

> 💡 La correction n°1 protège déjà contre les 3 nouveaux jeux : tant qu'ils ne sont pas reliés, ils sont **ignorés proprement**. Avant, un candidat qui n'aurait joué que « Je continue » aurait vu ce seul score devenir son Fit Score entier.

---

## 5. Ce qu'il reste à faire — côté développement

### Étape A — Relier les nouveaux jeux à leur module

Dire au système que « Je continue » et « Je coordonne » nourrissent la Flexibilité cognitive, et « Je place » la Mémoire de travail.

### Étape B — Regrouper avant de pondérer *(la correction du problème ci-dessus)*

D'abord faire la moyenne des jeux d'un même module, **puis** appliquer le poids du module **une seule fois**.

### Étape C — Affiner la couverture

Un candidat qui a joué Move Fast mais pas Je continue ni Je coordonne a couvert **1 jeu sur 3** de la Flexibilité cognitive. Sa couverture doit le refléter.

### Étape D — Appliquer la décision du point 2

Ne plus redistribuer les points d'un jeu sauté, mais ignorer les jeux qui n'existent pas.

### Étape E — Le recalcul après l'atelier RH

Aujourd'hui, si on change les pondérations, **aucun score existant n'est recalculé**. L'atelier RH va justement produire de nouvelles pondérations. La colonne d'horodatage nécessaire a déjà été ajoutée ; il reste à brancher le balayage.

---

## 6. Ce qu'il faut faire — côté organisation

### 🔴 Urgent — prévenir l'équipe Jeux

Leurs 3 nouveaux jeux apportent les fichiers de base de données **`V27`, `V28`, `V29`**.

**Ces trois numéros sont déjà pris chez nous.** C'est exactement le bug qui empêchait `main` de démarrer mardi, et qu'on vient de réparer.

> **À leur dire : partir de `V55`.** Tout ce qui est en dessous est utilisé.

### 🟠 Important — relancer sur les 30 scénarios

« Je Décide » est développé de bout en bout, écrans mobiles compris. **Il ne manque que les 30 scénarios du psychologue.**

Tant qu'ils n'arrivent pas, un module entier du score reste vide. C'est le seul point vraiment bloqué, et il ne dépend pas de l'équipe technique.

### 🟡 À prévoir — prévenir l'équipe web

Le changement des niveaux d'expérience (`MID` → `SENIOR`, `SENIOR` → `LEAD`, `EXECUTIVE` → `MANAGER`) **casse leur API**.

Attention au piège : `SENIOR` reste une valeur valide, mais **ne désigne plus le même poste**. Un client non mis à jour ne verra aucune erreur — il visera simplement le mauvais niveau.

### 🟢 Plus tard — décider où comptent les nouveaux jeux

Faut-il qu'un candidat joue **les 3 jeux** de Flexibilité cognitive pour être pleinement couvert, ou **un seul suffit-il** ? C'est une question produit, pas technique.

---

## 7. Résumé — quoi faire, dans quel ordre

| Qui | Quoi | Quand |
|---|---|---|
| **Vous** | Prévenir l'équipe Jeux : migrations à partir de **V55** | 🔴 avant leur prochaine fusion |
| **Vous** | Relancer sur les 30 scénarios de « Je Décide » | 🟠 cette semaine |
| **Vous** | Prévenir l'équipe web du changement de niveaux | 🟡 avant mise en production |
| **Dev** | Étapes A à D ci-dessus | en cours |
| **Dev** | Étape E (recalcul) | après |
| **Produit** | Couverture des 3 jeux de Flexibilité cognitive | avant lancement |

---

## 8. Pour retrouver le détail

| Document | Contenu |
|---|---|
| `FITSCORE_REMEDIATION.md` | Les 32 écarts, un par un, avec fichier et gravité |
| `COMPTE_RENDU_03-05_AOUT_2026.md` | Le récit des 3 jours, pour le superviseur |
| `docs/fitscore-harness/` | Les programmes qui rejouent les scores pour vérifier |
| **Ce fichier** | Où on en est, et quoi faire ensuite |
