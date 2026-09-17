# 🖥️ Audit UI & responsive — module Jeux

> **Date** : 17 septembre 2026 · **Périmètre** : les 12 jeux du module `games` (mobile Flutter),
> tutoriels et écrans de questions-réponses en priorité.
> **Méthode** : mesure automatisée, pas inspection visuelle. 548 sondes, 139 en défaut.
> **Statut du code** : aucun fichier de production modifié. Ce document est un constat, pas un correctif.

---

## 1. Résumé exécutif

**Les écrans de questions-réponses sont conformes.** Zéro défilement vertical sur les 8 gabarits
testés, pour les 12 jeux — à une exception près : le **scénario d'entraînement de « Je décide »**.

**Le problème est ailleurs** : dans les **couvertures / intros** (11 jeux sur 12) et dans les
**tutoriels** (11 sur 12). Trois symptômes, quatre causes, et un jeu qui fait tout bien et sert de
référence : **Day Stack**.

| Famille d'écrans | Conformes | En défaut |
|---|---|---|
| Questions-réponses / gameplay | **12 / 13** | 1 (Je décide — entraînement) |
| Tutoriels | **1 / 12** | 11 |
| Couvertures / intros | **1 / 12** | 11 |

Trois natures de défaut, par ordre de gravité :

1. **Contrôle inatteignable** — le bouton principal est dessiné sous la zone sûre : il est *rogné*,
   donc **visible mais intouchable** (vérifié au hit-test). Ou pire, dans un `ListView` paresseux,
   il n'est **pas même construit**.
2. **Débordement de rendu** — `RenderFlex overflowed`, du contenu physiquement coupé.
3. **Défilement indésirable** — le contenu dépasse la hauteur disponible.

---

## 2. Méthode

Un harnais de test monte chaque jeu, parcourt **couverture → tutoriel (carte par carte) →
questions-réponses**, et relève à chaque écran :

- l'**extension de défilement verticale** maximale de l'arbre (le carrousel horizontal des cartes de
  tutoriel est exclu : c'est le geste attendu) ;
- les **exceptions de rendu** (`RenderFlex overflowed…`) ;
- les **boutons d'action dessinés hors de la zone sûre**, insets système appliqués ;
- une **empreinte textuelle** de l'écran, qui garantit que le parcours a bien avancé et qu'on ne
  mesure pas deux fois le même écran.

### Le parc d'appareils

| Gabarit | Taille | Insets système | Ce qu'il représente |
|---|---|---|---|
| 320×568 | 320 × 568 | aucun | Le plancher du marché (iPhone SE 1re gén., Android bas de gamme) |
| 360×640 | 360 × 640 | aucun | Android entrée de gamme |
| 800 nu | 360 × 800 | aucun | Dalle nue, cas théorique |
| 800 gest. | 360 × 800 | 24 haut / 24 bas | Redmi 13C, navigation par gestes |
| 800 bout. | 360 × 800 | 24 haut / 48 bas | Redmi 13C, 3 boutons |
| 390×844 | 390 × 844 | 47 haut / 34 bas | iPhone 14 |
| 412×915 | 412 × 915 | 24 haut / 24 bas | Pixel 7 |
| 768×1024 | 768 × 1024 | 24 haut | Tablette |

> **Pourquoi les insets comptent.** Sans eux, un test est optimiste de 48 à 81 px et rate exactement
> le cas qui fait mal : un bouton dessiné *dans* la barre de gestes. C'est ce qui arrive à
> « J'investigue » sur iPhone 14.

### Rejouer l'audit

```bash
cd mobile && flutter test test/features/games/presentation/ui_responsive_audit_test.dart
```

96 tests, tous verts. Le détail complet est écrit dans `mobile/build/ui_audit.json`.
Le harnais sert de **non-régression** après correction.

---

## 3. Le tableau récapitulatif

Défilement = « Oui » s'il existe au moins un gabarit où le contenu dépasse.
Responsive = « Conforme » seulement si : aucun défilement, aucun débordement, aucun contrôle hors
zone sûre, sur les 8 gabarits.

### 3.1 Planifik — « Je planifie »

| Jeu | Écran | Défilement | Responsive | Problèmes détectés | Corrections nécessaires |
|---|---|---|---|---|---|
| Chemin optimal | Intro | **Oui** — 320=252, 640=160, 800g=48, 800b=72, 390×844=37, tablette=68 | ❌ **Non conforme** | Hero à hauteur plancher `math.max(340, largeur×0.9)` (`planifik_screen.dart:335`), insensible à la hauteur d'écran. CTA « Start » = dernier enfant du `SingleChildScrollView` → **hors zone sûre sur 6 gabarits sur 8, tablette comprise** | Borner le hero par `constraints.maxHeight`, pas par une constante. Extraire le CTA du défilement : barre d'action fixe sous `SafeArea` |
| Chemin optimal | Tutoriel (2 cartes) | **Oui** — 320=46 puis 68 | ❌ **Non conforme** | Cause racine n°1 (plancher d'illustration) | Voir §5.1 |
| Chemin optimal | Jeu (plateau) | Non | ✅ Conforme | — | — |
| **Day Stack** | Intro | **Non** | ✅ **Conforme** | Aucun, sur les 8 gabarits | **Référence à reproduire** — `task_scheduling_screen.dart:1257` |
| **Day Stack** | Tutoriel | **Non** | ✅ **Conforme** | Illustrations composées passant par `LayoutBuilder` + `FittedBox` | **Référence** — `day_stack_tutorial.dart:220` |
| **Day Stack** | Jeu (planning) | **Non** | ✅ **Conforme** | — | — |
| Tour de Hanoï | Intro | **Oui** — 320=248, 640=156, 800g=44, 800b=68, 390×844=13 | ❌ **Non conforme** | Même hero à plancher fixe. CTA « Start » hors zone sûre sur 4 gabarits | Idem Chemin optimal |
| Tour de Hanoï | Tutoriel (2 cartes) | **Oui** — 320=68 puis 90, 640=37 | ❌ **Non conforme** | Cause racine n°1 | Voir §5.1 |
| Tour de Hanoï | Jeu (planification) | Non | ✅ Conforme | — | — |

### 3.2 Je bouge, Je continue, Je coordonne

| Jeu | Écran | Défilement | Responsive | Problèmes détectés | Corrections nécessaires |
|---|---|---|---|---|---|
| Move Fast | Intro | **Oui** — 320=206, 640=90, 800b=2 | ❌ **Non conforme** | CTA « Start » hors zone sûre sur 320 (+182 px) et 640 (+66 px) | Barre d'action fixe hors du défilement |
| Move Fast | Tutoriel règle Orientation | Non | ❌ **Non conforme** | **Débordement 69 px en bas @320×568.** `Column` + deux `Spacer` dans un `GamePanel` trop court (`move_fast_screen.dart:1302`) | Envelopper le panneau dans `GameFitToScreen` ; titre et corps en `AutoFitText` ; gabarit de l'avion proportionnel |
| Move Fast | Tutoriel règle Mouvement | Non | ❌ **Non conforme** | **Débordement 36 px à droite @320** (la `Row` de `_MovementCue`) **et 12 px en bas @640** | Rendre la `Row` `Flexible`/`Wrap` ; même traitement vertical |
| Move Fast | Jeu (plateau) | Non | ✅ Conforme | — | — |
| Focus Stream | Couverture | **Oui** — **320=1476**, 640=528, 800n=259, 800g=307, 800b=332, 390×844=262, 412×915=84 | ❌ **Non conforme** | **Le pire du parc** : défile sur les 7 gabarits téléphone, jusqu'à 2,6 écrans de contenu sur 320×568 | Scinder en deux écrans, ou réduire les blocs de détail à une hauteur proportionnelle |
| Focus Stream | Format du parcours | **Oui** — 320=454, 640=303, 800n=143, 800g=191, 800b=215, 390×844=166, 412×915=26 | ❌ **Non conforme** | Contenu de `_InfoShell` non borné | Densité adaptative dans `_InfoShell` |
| Focus Stream | Tutoriel règle X | **Oui** — 320=497, 640=321, 800n=146, 800g=194, 800b=218, 390×844=169, 412×915=47 | ❌ **Non conforme** | Même `_InfoShell` : défile sur **tous** les téléphones | Corriger `_InfoShell` corrige les deux écrans d'un coup |
| Focus Stream | Jeu (flux) | Non | ✅ Conforme | — | — |
| Sync Square | Couverture | **Oui** — 320=753, 640=625, 800n=234, 800g=282, 800b=306, 390×844=255, 412×915=21 | ❌ **Non conforme** | Défile sur les 7 gabarits téléphone | Borner les blocs d'info à la hauteur disponible |
| Sync Square | Tutoriel (3 cartes) | **Oui** — 320=123/123/148, 640=27/27/52 | ❌ **Non conforme** | Cause racine n°1 | Voir §5.1 |
| Sync Square | Jeu (poursuite) | Non | ✅ Conforme | — | — |

### 3.3 J'investigue, Je place, Je décide

| Jeu | Écran | Défilement | Responsive | Problèmes détectés | Corrections nécessaires |
|---|---|---|---|---|---|
| Memory Quest | Intro | **Oui** — 320=316, 640=248, 800n=88, 800g=136, 800b=160, 390×844=59 | ❌ **Non conforme** | **Le plus grave côté entrée de jeu.** « Start mission » est dessiné sous la zone sûre sur **6 gabarits, iPhone 14 compris** (845 px pour 810 utilisables). Vérifié au hit-test : le bouton est **rogné, donc intouchable** — le joueur le voit, le tap ne part pas | Barre d'action fixe, hors du contenu défilant, sous `SafeArea` |
| Memory Quest | Tutoriel (10 cartes) | **Oui** — 320 : 28 à 75 px selon la carte | ❌ **Non conforme** | Cause racine n°1, sur les 10 cartes | Voir §5.1 |
| Memory Quest | Jeu (observation) | Non | ✅ Conforme | — | — |
| Je place | Couverture | **Oui** — 320=585, 640=210, 800n=50, 800g=98, 800b=122, 390×844=47 | ❌ **Non conforme** | Défile sur 6 gabarits | Borner les blocs d'info |
| Je place | Tutoriel (3 cartes) | **Oui** — 320=44 | ❌ **Non conforme** | Cause racine n°1 | Voir §5.1 |
| Je place | Jeu (encodage) | Non | ✅ Conforme | — | — |
| Je décide | Accueil | **Oui** — 320=252, 640=180, 800n=20, 800g=68, 800b=92 | ❌ **Non conforme** | CTA « Commencer » hors zone sûre sur 320 (+140 px) et 640 (+68 px) | Barre d'action fixe |
| Je décide | Tutoriel (3 cartes) | **Oui** — 320=198, 640=104, 800g=68, 800b=92 | ❌ **Non conforme** | Cause racine n°1 ; le manque le plus élevé du parc (198 px) | Voir §5.1 |
| Je décide | **Scénario d'entraînement** | **Oui** — 320=310, 640=165, 800n=5, 800g=68, 800b=92, 390×844=1 | ❌ **Non conforme** | **Le seul écran de questions-réponses en défaut.** `_PracticeScenarioView` (`je_decide_screen.dart:660`) **ne reprend pas** le plan de mise en page adaptatif de la passation. Son bouton « Continue » passe sous la zone sûre **sur iPhone 14 (+12 px) et sur Pixel 7 (+2 px)** | Faire passer l'entraînement par le même `DecisionLayoutPlan` que `DecisionGameplayView` — le travail existe déjà, il n'est simplement pas réutilisé ici |
| Je décide | **Scénario de passation** | **Non** | ✅ **Conforme** | Aucun. `je_decide_no_scroll_test` passe, 21/21, sur les 7 gabarits téléphone, banque de démo **et** 6 pires items par dimension de la banque serveur | — |

### 3.4 Je gère — régulation émotionnelle

| Jeu | Écran | Défilement | Responsive | Problèmes détectés | Corrections nécessaires |
|---|---|---|---|---|---|
| Emotional Radar | Couverture | **Oui** — 320=150 | ❌ **Non conforme** | « View rules » (+52 px) et « Start tutorial » (+122 px) tous deux hors zone sûre @320 | Barre d'action fixe |
| Emotional Radar | Tutoriel (5 cartes) | **Oui** — 320 : 28 à 75 px | ❌ **Non conforme** | Cause racine n°1 | Voir §5.1 |
| Emotional Radar | Scène (Q&R) | **Non** | ✅ **Conforme** | — | — |
| Reflective Pause | Couverture | **Oui** — 320=286, 640=214, 800n=54, 800g=102, 800b=126, 390×844=77 | ❌ **Non conforme** | Défile sur 6 gabarits | Borner les blocs d'info |
| Reflective Pause | Intro | Non | ✅ Conforme | Utilise déjà `GameFitToScreen` | — |
| Reflective Pause | Tutoriel (5 cartes) | **Oui** — 320 : 118 à 162, 640 : 46 à 68 | ❌ **Non conforme** | Cause racine n°1, aggravée par des descriptions longues. **+ 90 px de barre de navigation affichés pendant le tutoriel** (cause racine n°4) | Voir §5.1 et §5.4 |
| Reflective Pause | Situation (Q&R) | **Non** | ✅ **Conforme** | — | — |
| Strategic Choices | Couverture | **Oui** — 320=560, 640=397, 800n=180, 800g=228, 800b=252, 390×844=15 | ❌ **Non conforme** | **Le plus grave du parc.** La couverture est un `ListView` **paresseux** (`strategic_choices_screen.dart:646`) dont « View tutorial » et « Start mission » sont les derniers enfants. Sur **5 gabarits** ils ne sont **pas même construits** — rien à l'écran n'indique qu'ils existent | Extraire les deux CTA du `ListView` dans une barre fixe, ou passer en `SingleChildScrollView` + `Column`, qui construit tout |
| Strategic Choices | Intro | Non | ✅ Conforme | — | — |
| Strategic Choices | Tutoriel (5 cartes) | **Oui** — 320 : 118 à 140, 640 : 46 à 68 | ❌ **Non conforme** | Cause racine n°1 + n°4 | Voir §5.1 et §5.4 |
| Strategic Choices | Situation (Q&R) | **Non** | ✅ **Conforme** | — | — |

---

## 4. Les preuves chiffrées

### 4.1 Boutons dessinés hors de la zone sûre

Ce ne sont pas des défauts esthétiques : un bouton dessiné sous la limite de la zone sûre est
**rogné par le clip du conteneur parent**. Flutter le peint, mais le hit-test s'arrête aux bornes du
parent — le tap n'atteint jamais le bouton. Vérifié explicitement sur « J'investigue » à 390×844 :
le chemin de hit-test au centre du bouton ne contient **aucun gestionnaire de geste**.

| Jeu | Écran | Gabarit | Contrôle | Bas du bouton | Limite zone sûre | Dépassement |
|---|---|---|---|---|---|---|
| Planifik / Chemin optimal | Intro / couverture | 320x568 | Start | 796 px | 568 px | **+228 px** |
| Planifik / Chemin optimal | Intro / couverture | 360x640 | Start | 776 px | 640 px | **+136 px** |
| Planifik / Chemin optimal | Intro / couverture | 360x800 gestes | Start | 800 px | 776 px | **+24 px** |
| Planifik / Chemin optimal | Intro / couverture | 360x800 3 boutons | Start | 800 px | 752 px | **+48 px** |
| Planifik / Chemin optimal | Intro / couverture | 390x844 iPhone 14 | Start | 823 px | 810 px | **+13 px** |
| Planifik / Chemin optimal | Intro / couverture | 768x1024 tablette | Start | 1068 px | 1024 px | **+44 px** |
| Planifik / Tour de Hanoi | Intro / couverture | 320x568 | Start | 792 px | 568 px | **+224 px** |
| Planifik / Tour de Hanoi | Intro / couverture | 360x640 | Start | 772 px | 640 px | **+132 px** |
| Planifik / Tour de Hanoi | Intro / couverture | 360x800 gestes | Start | 796 px | 776 px | **+20 px** |
| Planifik / Tour de Hanoi | Intro / couverture | 360x800 3 boutons | Start | 796 px | 752 px | **+44 px** |
| Je bouge / Move Fast | Intro / couverture | 320x568 | Start | 750 px | 568 px | **+182 px** |
| Je bouge / Move Fast | Intro / couverture | 360x640 | Start | 706 px | 640 px | **+66 px** |
| J'investigue / Memory Quest | Intro / couverture | 320x568 | Start mission | 860 px | 568 px | **+292 px** |
| J'investigue / Memory Quest | Intro / couverture | 360x640 | Start mission | 864 px | 640 px | **+224 px** |
| J'investigue / Memory Quest | Intro / couverture | 360x800 nu | Start mission | 864 px | 800 px | **+64 px** |
| J'investigue / Memory Quest | Intro / couverture | 360x800 gestes | Start mission | 888 px | 776 px | **+112 px** |
| J'investigue / Memory Quest | Intro / couverture | 360x800 3 boutons | Start mission | 888 px | 752 px | **+136 px** |
| J'investigue / Memory Quest | Intro / couverture | 390x844 iPhone 14 | Start mission | 845 px | 810 px | **+35 px** |
| Je décide | Accueil / couverture | 320x568 | Commencer | 708 px | 568 px | **+140 px** |
| Je décide | Accueil / couverture | 360x640 | Commencer | 708 px | 640 px | **+68 px** |
| Je décide | Scénario d'entraînement (questions-réponses) | 390x844 iPhone 14 | Continue | 822 px | 810 px | **+12 px** |
| Je décide | Scénario d'entraînement (questions-réponses) | 412x915 Pixel 7 | Continue | 893 px | 891 px | **+2 px** |
| Je gère / Emotional Radar | Couverture | 320x568 | View rules | 620 px | 568 px | **+52 px** |
| Je gère / Emotional Radar | Couverture | 320x568 | Start tutorial | 690 px | 568 px | **+122 px** |

### 4.2 Débordements de rendu (`RenderFlex overflowed`)

| Jeu | Écran | Gabarit | Débordement de rendu |
|---|---|---|---|
| Je bouge / Move Fast | Tutoriel — règle Orientation | 320x568 | A RenderFlex overflowed by 69 pixels on the bottom. |
| Je bouge / Move Fast | Tutoriel — règle Mouvement | 320x568 | A RenderFlex overflowed by 36 pixels on the right. |
| Je bouge / Move Fast | Tutoriel — règle Mouvement | 360x640 | A RenderFlex overflowed by 12 pixels on the bottom. |

### 4.3 Matrice complète — défilement vertical en pixels, 8 gabarits

`0` = rien à faire défiler (conforme). **Gras** = défilement indésirable.
⛔ = un bouton d'action est hors zone sûre. 💥 = débordement de rendu.

| Jeu | Écran | 320×568 | 360×640 | 800 nu | 800 gest. | 800 bout. | 390×844 | 412×915 | 768×1024 |
|---|---|---|---|---|---|---|---|---|---|
| Planifik / Chemin optimal | Intro / couverture | **252** ⛔ | **160** ⛔ | 0 | **48** ⛔ | **72** ⛔ | **37** ⛔ | 0 | **68** ⛔ |
| Planifik / Chemin optimal | Tutoriel — carte 1 | **46** | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Planifik / Chemin optimal | Tutoriel — carte 2 | **68** | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Planifik / Chemin optimal | Jeu (plateau) | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Planifik / Day Stack | Intro / couverture | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Planifik / Day Stack | Tutoriel — carte 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Planifik / Day Stack | Jeu (planning) | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Planifik / Tour de Hanoi | Intro / couverture | **248** ⛔ | **156** ⛔ | 0 | **44** ⛔ | **68** ⛔ | **13** | 0 | 0 |
| Planifik / Tour de Hanoi | Tutoriel — carte 1 | **68** | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Planifik / Tour de Hanoi | Tutoriel — carte 2 | **90** | **36.6** | 0 | 0 | 0 | 0 | 0 | 0 |
| Planifik / Tour de Hanoi | Jeu (planification) | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Je bouge / Move Fast | Intro / couverture | **206** ⛔ | **90** ⛔ | 0 | 0 | **2** | 0 | 0 | 0 |
| Je bouge / Move Fast | Tutoriel — règle Orientation | 0 💥 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Je bouge / Move Fast | Tutoriel — règle Mouvement | 0 💥 | 0 💥 | 0 | 0 | 0 | 0 | 0 | 0 |
| Je bouge / Move Fast | Jeu (plateau) | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Je continue / Focus Stream | Couverture | **1476** | **527.5** | **259** | **307** | **332.2** | **262** | **84** | 0 |
| Je continue / Focus Stream | Format du parcours | **453.5** | **303** | **143** | **191** | **215** | **166** | **26** | 0 |
| Je continue / Focus Stream | Tutoriel — règle X | **497.4** | **320.7** | **146** | **194** | **218** | **169** | **47** | 0 |
| Je continue / Focus Stream | Jeu (flux) | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Je coordonne / Sync Square | Couverture | **753.2** | **625.2** | **234** | **282** | **306** | **255** | **21** | 0 |
| Je coordonne / Sync Square | Tutoriel — carte 1 | **123** | **27** | 0 | 0 | 0 | 0 | 0 | 0 |
| Je coordonne / Sync Square | Tutoriel — carte 2 | **123** | **27** | 0 | 0 | 0 | 0 | 0 | 0 |
| Je coordonne / Sync Square | Tutoriel — carte 3 | **148** | **52** | 0 | 0 | 0 | 0 | 0 | 0 |
| Je coordonne / Sync Square | Jeu (poursuite) | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| J'investigue / Memory Quest | Intro / couverture | **315.9** ⛔ | **248** ⛔ | **88** ⛔ | **136** ⛔ | **160** ⛔ | **59** ⛔ | 0 | 0 |
| J'investigue / Memory Quest | Tutoriel — carte 1 | **50** | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| J'investigue / Memory Quest | Tutoriel — carte 2 | **53** | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| J'investigue / Memory Quest | Tutoriel — carte 3 | **28** | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| J'investigue / Memory Quest | Tutoriel — carte 4 | **50** | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| J'investigue / Memory Quest | Tutoriel — carte 5 | **50** | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| J'investigue / Memory Quest | Tutoriel — carte 6 | **75** | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| J'investigue / Memory Quest | Tutoriel — carte 7 | **50** | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| J'investigue / Memory Quest | Tutoriel — carte 8 | **50** | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| J'investigue / Memory Quest | Tutoriel — carte 9 | **50** | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| J'investigue / Memory Quest | Tutoriel — carte 10 | **75** | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| J'investigue / Memory Quest | Jeu (observation) | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Je place / Place & Bind | Couverture | **584.8** | **210** | **50** | **98** | **122** | **47** | 0 | 0 |
| Je place / Place & Bind | Tutoriel — carte 1 | **44** | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Je place / Place & Bind | Tutoriel — carte 2 | **44** | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Je place / Place & Bind | Tutoriel — carte 3 | **44** | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Je place / Place & Bind | Jeu (encodage) | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Je décide | Accueil / couverture | **252** ⛔ | **180** ⛔ | **20** | **68** | **92** | 0 | 0 | 0 |
| Je décide | Tutoriel — carte 1 | **198** | **104** | 0 | **68** | **92** | 0 | 0 | 0 |
| Je décide | Tutoriel — carte 2 | **198** | **104** | 0 | – | – | 0 | 0 | 0 |
| Je décide | Tutoriel — carte 3 | **198** | **104** | 0 | – | – | 0 | 0 | 0 |
| Je décide | Scénario d'entraînement (questions-réponses) | **309.8** | **164.8** | **4.8** | **68** | **92** | **1** ⛔ | 0 ⛔ | 0 |
| Je gère / Emotional Radar | Couverture | **150** ⛔ | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Je gère / Emotional Radar | Tutoriel — carte 1 | **28** | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Je gère / Emotional Radar | Tutoriel — carte 2 | **50** | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Je gère / Emotional Radar | Tutoriel — carte 3 | **28** | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Je gère / Emotional Radar | Tutoriel — carte 4 | **75** | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Je gère / Emotional Radar | Tutoriel — carte 5 | **28** | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Je gère / Emotional Radar | Scène (questions-réponses) | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Je gère / Reflective Pause | Couverture | **286** | **214** | **54** | **102** | **126** | **77** | 0 | 0 |
| Je gère / Reflective Pause | Intro | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Je gère / Reflective Pause | Tutoriel — carte 1 | **118** | **46** | 0 | 0 | 0 | 0 | 0 | 0 |
| Je gère / Reflective Pause | Tutoriel — carte 2 | **118** | **46** | 0 | 0 | 0 | 0 | 0 | 0 |
| Je gère / Reflective Pause | Tutoriel — carte 3 | **140** | **46** | 0 | 0 | 0 | 0 | 0 | 0 |
| Je gère / Reflective Pause | Tutoriel — carte 4 | **162** | **68** | 0 | 0 | 0 | 0 | 0 | 0 |
| Je gère / Reflective Pause | Tutoriel — carte 5 | **140** | **68** | 0 | 0 | 0 | 0 | 0 | 0 |
| Je gère / Reflective Pause | Situation (questions-réponses) | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Je gère / Strategic Choices | Couverture | **559.5** | **397.2** | **180** | **228** | **252** | **15** | 0 | 0 |
| Je gère / Strategic Choices | Intro | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Je gère / Strategic Choices | Tutoriel — carte 1 | **118** | **46** | 0 | 0 | 0 | 0 | 0 | 0 |
| Je gère / Strategic Choices | Tutoriel — carte 2 | **118** | **46** | 0 | 0 | 0 | 0 | 0 | 0 |
| Je gère / Strategic Choices | Tutoriel — carte 3 | **118** | **46** | 0 | 0 | 0 | 0 | 0 | 0 |
| Je gère / Strategic Choices | Tutoriel — carte 4 | **140** | **46** | 0 | 0 | 0 | 0 | 0 | 0 |
| Je gère / Strategic Choices | Tutoriel — carte 5 | **140** | **68** | 0 | 0 | 0 | 0 | 0 | 0 |
| Je gère / Strategic Choices | Situation (questions-réponses) | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

---

## 5. Les causes racines

Quatre causes expliquent les 139 sondes en défaut. Les traiter à la source coûte bien moins cher que
de rattraper 40 symptômes écran par écran.

### 5.1 Cause n°1 — Le plancher d'illustration du deck de tutoriel

**Touche 9 jeux.** Une seule ligne :

```dart
// mobile/lib/features/games/presentation/widgets/game_tutorial_deck.dart:254
height: (constraints.maxHeight * .6).clamp(240.0, 310.0),
```

Sous environ 400 px de carte, `0.6 × hauteur` tombe **sous le plancher de 240 px**. L'illustration
prend alors la place du titre et de la description, qui débordent et déclenchent le
`SingleChildScrollView` interne de la carte.

D'où le motif observé : le défaut apparaît **toujours** sur 320×568 et 360×640, **jamais** sur les
grands écrans. Mesuré sur l'écran Reflective Pause :

| Gabarit | Hauteur de carte | `0.6 × carte` | Bandeau appliqué | Image rendue |
|---|---|---|---|---|
| 320×568 | 267 px | 160 px | **240 px** (plancher actif) | 208 px |
| 360×640 | 339 px | 203 px | **240 px** (plancher actif) | 208 px |
| 360×800 | 499 px | 299 px | 299 px | 266 px |

**Correction** : rendre le plancher proportionnel, et surtout **mesurer d'abord le bloc de texte**
pour donner le reste à l'illustration, plutôt que l'inverse. Voir §6 : la réduction de l'image n'est
pas le premier levier à actionner.

### 5.2 Cause n°2 — Le CTA dernier enfant d'un conteneur défilant

**Touche 6 jeux.** Le bouton principal est poussé hors de la zone sûre par le contenu qui le
précède. Résultat : visible mais rogné, donc intouchable.

**Correction** : le motif à généraliser est une `Column` à deux étages —
contenu défilant dans un `Expanded`, barre d'action fixe en dessous, sous `SafeArea`.
« Je continue » le fait déjà correctement (`continuous_attention_screen.dart:1115`) ; c'est son
contenu qui est trop long, pas sa structure.

### 5.3 Cause n°3 — Les hauteurs en dur

`math.max(340, …)` pour les héros Planifik, `240` pour les illustrations : des constantes qui
ignorent la hauteur disponible. Le projet dispose déjà des bons outils —
`GameFitToScreen`, `AutoFitText`, `GameContentFrame` — mais ils ne sont utilisés que par
**4 écrans sur 16**.

**Correction** : dériver ces hauteurs du `constraints.maxHeight` du parent.

### 5.4 Cause n°4 — La barre de navigation affichée pendant le tutoriel

**Touche 4 jeux** (Reflective Pause, Strategic Choices, Je décide, Focus Stream).
`AppBottomNav` mesure **90 px** et reste affichée pendant le tutoriel — soit **16 % de la hauteur**
d'un écran 320×568, sur un écran que le candidat doit lire.

Budget vertical mesuré sur Reflective Pause en 320×568 :

```
chrome haut (en-tête + « Étape 1 sur 5 »)   68 px
carte                                      267 px   ← contenu réel 385 px, manque 118 px
entre la carte et le bouton                 43 px
bouton                                      52 px
SOUS le bouton                             106 px   ← dont 90 px de barre de navigation
                                           ──────
                                           568 px
```

**Correction** : masquer `AppBottomNav` pendant les stages `tutorial`, comme c'est déjà le cas
pendant le gameplay.

---

## 6. Question ouverte : les illustrations de tutoriel vont-elles rétrécir ?

C'est le point sensible de la cause n°1, et la réponse conditionne l'ordre des correctifs.

### 6.1 Oui, si l'on corrige naïvement

Les **33 illustrations de tutoriel sont toutes des PNG carrés 1254×1254**, rendus en
`Image.asset(fit: BoxFit.contain)`. Une image carrée dans une boîte L×H s'affiche à `min(L, H)` —
et **c'est la hauteur qui contraint sur tous les gabarits** :

| Gabarit | Largeur disponible | Bandeau (hauteur) | Image rendue |
|---|---|---|---|
| 320×568 | 254 px | **240** (plancher) | **208 px** |
| 360×640 | 294 px | 240 (plancher) | **208 px** |
| 360×800 | 294 px | 299 | **266 px** |
| 412×915 | 346 px | 310 (plafond) | **278 px** |

Chaque pixel retiré au bandeau est donc un pixel retiré à l'image, **au pixel près**. Pas de rognage
ni de déformation — `contain` le garantit — mais une réduction visible. Un plancher ramené à
`0.34 × hauteur` ferait tomber l'image à environ 150 px sur 320×568, soit **−28 %**.

### 6.2 Non, si l'on récupère d'abord l'espace perdu ailleurs

Avant de toucher à l'image, il y a du chrome à reprendre : **90 px de barre de navigation**
(cause n°4), **43 px** entre la carte et le bouton dont 16 px de décalage purement décoratif
(`Positioned.fill(bottom: 16)`), et **~32 px** d'en-tête « Comment jouer ».

| Gabarit | Manque à combler | Chrome récupérable | Impact sur l'image |
|---|---|---|---|
| **360×800 et au-dessus** | 0 px | — | **Aucun.** L'image reste à 266–278 px |
| **360×640** | 27 à 104 px | 40 à 130 px | **Aucun** dans la quasi-totalité des cas — l'image reste à 208 px |
| **320×568** | 28 à 198 px | 40 à 130 px | Nul pour les tutoriels légers ; les 4 plus lourds (Je décide 198, Sync Square 148, Reflective/Strategic 118–140) demandent **208 → 160–180 px, sur ce seul gabarit** |

Autrement dit : **sur les téléphones réellement utilisés, les images ne bougent pas.** La réduction
ne concerne que le 320×568, et seulement pour les tutoriels aux descriptions les plus longues.

Détail rassurant : la source fait 1254 px pour un rendu à 208 px. Même à 160 px, il reste **près de
8× la donnée nécessaire** — aucune perte de netteté, simplement une vignette plus petite.

### 6.3 Un cas qui ne pose pas de question : Day Stack

Les illustrations de Day Stack ne sont pas des images mais des **widgets composés**
(`_MoveDemo`, `_DayStackDemo`). Elles passent déjà par `LayoutBuilder` + `FittedBox`
(`day_stack_tutorial.dart:220`) : elles se réduisent proportionnellement au lieu de déborder.
C'est le motif à généraliser — et une raison de plus de traiter Day Stack comme la référence.

---

## 7. Plan de correction priorisé

| # | Correction | Jeux touchés | Gravité | Effort |
|---|---|---|---|---|
| 1 | **Strategic Choices — couverture** : extraire les CTA du `ListView` paresseux | 1 | 🔴 Jeu injouable sans découvrir le défilement | Faible |
| 2 | **Memory Quest — intro** : barre d'action fixe sous `SafeArea` | 1 | 🔴 « Start mission » rogné et intouchable jusqu'à l'iPhone 14 | Faible |
| 3 | **Masquer `AppBottomNav` pendant les tutoriels** | 4 | 🟠 Récupère 90 px gratuitement, sans toucher aux images | Très faible |
| 4 | **`GameTutorialDeck`** : resserrer le chrome, puis plancher d'illustration proportionnel | 9 | 🟠 Une seule ligne corrige 9 tutoriels | Moyen |
| 5 | **Je décide — scénario d'entraînement** : réutiliser le `DecisionLayoutPlan` de la passation | 1 | 🟠 Le seul écran de Q&R en défaut ; CTA hors cadre même sur Pixel 7 | Moyen |
| 6 | **Focus Stream / Sync Square — couvertures** : borner les blocs d'info | 2 | 🟡 1476 px et 753 px à faire défiler sur 320×568 | Moyen |
| 7 | **Move Fast — tutoriels** : `GameFitToScreen` + `Wrap` sur la `Row` du repère | 1 | 🟡 Deux débordements de rendu francs | Faible |
| 8 | **Héros Planifik** : borner la hauteur par `constraints.maxHeight` | 2 | 🟡 CTA hors cadre jusqu'à la tablette | Faible |

**Ordre des leviers pour les tutoriels** — il compte : si l'on attaque par le plancher
d'illustration, on paie en taille d'image ce que l'on pouvait obtenir gratuitement.

1. masquer la barre de navigation pendant les tutoriels (90 px) ;
2. resserrer les espacements du deck sur écran court (~40 px) ;
3. ne toucher au plancher d'illustration **qu'en dernier recours**, et seulement en dessous
   de ~600 px de hauteur d'écran.

---

## 8. Ce qui a été livré avec cet audit

| Fichier | Rôle |
|---|---|
| `mobile/test/features/games/presentation/ui_responsive_audit_test.dart` | Le harnais de mesure. 96 tests, tous verts. Sert de non-régression après correction |
| `mobile/build/ui_audit.json` | Les 548 sondes brutes : défilement, débordements, boutons hors zone sûre, empreinte d'écran |
| `AUDIT_UI_RESPONSIVE.md` | Ce document |

**Aucun fichier de production n'a été modifié.**

---

## 9. Comment maintenir ce document

À rejouer et mettre à jour **après chaque correction** de la liste du §7, et à chaque ajout d'écran
au module `games` :

```bash
cd mobile && flutter test test/features/games/presentation/ui_responsive_audit_test.dart
```

Un nouveau jeu s'ajoute au harnais en déclarant son parcours dans la fonction `sweep(...)` —
couverture, tutoriel, questions-réponses — sur le modèle des 12 jeux existants.
