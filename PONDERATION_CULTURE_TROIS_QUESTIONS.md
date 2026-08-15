# Pondération par la culture — trois questions, plusieurs réponses possibles

**Module Recrutement — Zennyt**
Document de cadrage, en réponse aux questions posées sur le cahier des charges
« Pondération assistée » v3.0. État au 11 août 2026.

---

## ⚠️ Décision du 11 août 2026 — le sujet n'est pas engagé

**Après lecture de ce document, la pondération par la culture d'entreprise ne sera pas
implémentée.** La pondération de base par métier et niveau, déjà validée, reste seule en
vigueur.

Le motif principal est le constat de la partie 2.2 de ce document : un texte RH générique
obtient le même bonus maximal qu'un texte décrivant une culture réellement marquée. **Nous
mesurerions la rédaction de l'offre, pas la culture de l'équipe.** S'y ajoutent trois
raisons : une entreprise n'a pas une culture unique — un poste en R&D et un poste en
conformité cherchent des profils opposés, alors que le même paragraphe de présentation est
réutilisé d'une offre à l'autre ; le fit culturel porte un risque de biais réel ; et la
proportion n'y est pas, avec ~11 jours de développement, un atelier RH, une analyse RGPD et
des tests de non-discrimination pour un signal dont la valeur ajoutée restait à démontrer.

**Ce document reste la trace de l'instruction du sujet**, et c'est à ce titre qu'il est
conservé. Les recommandations qu'il contient ne sont pas des décisions à appliquer : ce sont
les options qui ont été évaluées avant l'arbitrage. Deux résultats gardent une valeur propre
et sont réutilisables :

- **La règle d'absorption** (question 3) : si un poids de module doit un jour être ajusté
  pour une raison quelconque, la répartition proportionnelle avec plancher est démontrée
  sûre, et la répartition à parts égales démontrée inapplicable.
- **Le dénominateur inférieur à 100** (partie 2.4) : ce constat concerne le Fit Score
  actuel, indépendamment de toute pondération culturelle.

---

## Ce que ce document contient

Trois questions ont été posées :

1. **L'extraction déterministe des mots est-elle le bon choix**, compte tenu du passage à
   l'échelle et du fait que le Fit Score doit rester rapide ?
2. **Comment décide-t-on du chiffre du bonus** — pourquoi +3, +5 ou +10 points sur un
   module plutôt qu'un autre nombre ?
3. **Comment tient-on la calibration ?** Les 5 modules doivent toujours totaliser 100 %, et
   soft + hard aussi. Si on ajoute à un module, à qui retire-t-on ?

Pour chacune, ce document présente **plusieurs solutions**, ce qu'elles coûtent, ce
qu'elles apportent, et une recommandation motivée. Les chiffres ne sont pas des
estimations de principe : ils ont été **mesurés sur la matrice réelle du projet et sur du
texte d'offre réaliste**. La méthode de mesure est donnée en annexe pour que chacun puisse
la refaire.

> **Convention** : « point » = point de pondération (ex. un module qui passe de 15 % à
> 23 % a reçu +8 points). À ne pas confondre avec un point de Fit Score, qui est autre
> chose — la partie 3.4 montre justement que les deux ne sont pas égaux.

---

## Avant les trois questions — un fait qui change les réponses

Il faut lever un malentendu, sinon la question 1 se pose mal.

**La détection ne tourne pas pendant le calcul du Fit Score.** Elle tourne **une fois par
offre**, au moment où le recruteur publie ou modifie son annonce. Le calcul du Fit Score,
lui, tourne **une fois par couple candidat × offre** — c'est-à-dire des milliers de fois
plus souvent.

```
   Le recruteur publie une offre
            │
            ▼
   ┌─────────────────────────┐
   │  Détection + suggestion │   ← UNE fois par offre
   └─────────────────────────┘
            │
   Le recruteur accepte ou ignore
            │
            ▼
   Des nombres sont écrits sur l'offre
            │
            ▼
   ══════════════════════════════════
   CALCUL DU FIT SCORE                ← des milliers de fois
   ne lit que des NOMBRES, jamais du texte
   ══════════════════════════════════
```

Conséquence directe : **la vitesse de la détection n'a presque aucun effet sur la vitesse
du Fit Score.** Une entreprise qui publie 50 offres par mois déclenche 50 détections par
mois. Même une méthode lente (1 seconde par offre) coûterait 50 secondes mensuelles,
réparties sur les moments où un recruteur clique « Publier ».

Cela ne veut pas dire que le choix est indifférent — il ne se joue simplement pas sur la
performance. Il se joue sur **l'explicabilité**, comme la suite le montre.

---

# Question 1 — Faut-il rester sur une extraction déterministe ?

## 1.1 Ce qu'on entend par là

| Méthode | En une phrase |
|---|---|
| **Déterministe (dictionnaire)** | On cherche dans le texte une liste d'expressions écrites à l'avance. « autonomie » est dans la liste, donc on le trouve. |
| **Sémantique (empreintes)** | On transforme le texte en une suite de nombres qui capture le *sens*, et on mesure sa proximité avec chaque profil de culture. « chacun est maître de son périmètre » se rapproche d'« autonomie » sans partager un seul mot. |
| **Modèle de langage (IA)** | On demande à une IA : « quelle culture décrit ce texte ? » et elle répond en langage naturel. |

## 1.2 Les quatre options, mesurées

Le temps de la première option a été **mesuré** sur ce projet : un dictionnaire de
60 expressions, balayé sur un texte de 750 mots (profil entreprise + offre, version
bavarde), sur la même version de Java que le backend.

| | Option A — Dictionnaire | Option B — Empreintes | Option C — Modèle de langage | Option D — Hybride |
|---|---|---|---|---|
| **Temps par offre** | **0,2 ms** (mesuré) | ~50 ms (appel réseau) | 300 – 1 000 ms | ~50 ms |
| **Débit sur un cœur** | **≈ 5 000 offres/s** | ~20 offres/s | ~2 offres/s | ~20 offres/s |
| **10 000 offres d'un coup** | **2 secondes** | ~8 minutes | ~1 à 3 heures | ~8 minutes |
| **Même texte, même résultat ?** | Oui, toujours | Oui | **Non** | Partiellement |
| **Dépend d'un service externe** | Non | Oui (clé d'API) | Oui (clé d'API) | Oui |
| **Coût à l'usage** | Nul | Faible | Facturé au texte | Faible |
| **Ce qu'on montre au candidat** | **le mot trouvé** | un score de proximité | une phrase générée | le mot trouvé |
| **Repère les tournures indirectes** | **Non** | Oui | Oui | Oui |
| **Effort de développement** | ~3 jours | ~5 jours | ~4 jours | ~8 jours |

**Option D (hybride)** = le dictionnaire décide, les empreintes servent uniquement à
*proposer* de nouvelles expressions à ajouter au dictionnaire, hors ligne, pendant
l'atelier RH.

## 1.3 Ce que chaque option coûte vraiment

**Option A — Dictionnaire.**
✅ Gratuite, instantanée, reproductible, et surtout : **on peut montrer le mot**. Si un
candidat conteste, on affiche « le mot *autonomie* apparaît dans la description du poste ».
❌ Elle rate ce qui n'est pas écrit littéralement. « Chacun est maître de son périmètre »
exprime l'autonomie sans contenir le mot. On appelle ça un défaut de **rappel**.
❌ Le dictionnaire est en français ; l'application est bilingue. Une offre en anglais
renverrait « aucun signal » **en silence** — le pire mode d'échec, parce qu'il ne
ressemble pas à une panne. *(Correctif : deux dictionnaires, ou une détection de langue
qui refuse explicitement d'analyser une langue non couverte.)*

**Option B — Empreintes sémantiques.**
✅ Repère les tournures indirectes, gère naturellement les deux langues (le modèle prévu
au projet, `multilingual-e5-small`, est multilingue).
❌ **On ne peut rien montrer.** À un candidat qui demande pourquoi, la seule réponse
disponible est « la distance vectorielle entre votre offre et le profil *Autonomie* valait
0,71 ». Ce n'est pas une justification recevable.
❌ Dépend d'une clé d'API. **Le projet dispose déjà du branchement** (`EmbeddingPort`,
modèle `multilingual-e5-small`) mais **aucune clé n'est configurée** : aujourd'hui c'est
l'implémentation neutre `NoOpEmbeddingPort` qui répond. Cette option ne pourrait pas être
livrée sans régler d'abord ce point.

**Option C — Modèle de langage.**
✅ La meilleure compréhension du texte, de loin.
❌ **Deux exécutions sur le même texte peuvent donner deux réponses différentes.** Pour un
système qui doit être auditable, c'est rédhibitoire : on ne peut pas rejouer une décision
passée et retrouver le même résultat.
❌ Le projet a déjà fait cette expérience. L'ancien calcul du Fit Score déléguait à une IA
externe : **environ 361 ms contre 29 ms** pour le calcul déterministe qui l'a remplacé, soit
douze fois plus lent, et dépendant d'un tiers. Ce repli a été supprimé pour ces raisons.

**Option D — Hybride.**
✅ Garde le mot montrable comme seule preuve, tout en utilisant le sémantique là où il est
utile : **aider à construire le dictionnaire**, pas à décider offre par offre.
❌ Deux systèmes à maintenir, et l'atelier RH devient un passage obligé.

## 1.4 Recommandation

**Option A pour livrer, Option D comme cible.**

Le raisonnement n'est pas celui de la performance — on a vu qu'elle ne départage rien ici.
C'est **l'explicabilité qui décide**. Le cahier des charges lui-même le pose en section 6 :
le RGPD (article 22) et l'AI Act classent ce système comme à haut risque et exigent qu'on
puisse justifier une décision. **Seul un mot clé se montre.**

Et la faiblesse principale du dictionnaire — rater les tournures indirectes — est
acceptable **précisément parce qu'un humain décide** :

| Ce qui rate | Ce qui se passe | Gravité |
|---|---|---|
| Signal manqué | Aucune suggestion n'apparaît | Le recruteur garde la pondération de base, qui est correcte |
| Faux signal | Une suggestion s'affiche | Le recruteur l'ignore d'un clic |

Les deux modes d'échec laissent la pondération de base en place. C'est ce qui rend une
méthode imparfaite acceptable ici, alors qu'elle ne le serait pas dans un système qui
appliquerait ses conclusions tout seul.

---

# Question 2 — D'où sort le chiffre du bonus ?

C'est la question la plus difficile des trois, et celle où le cahier des charges est le
plus fragile.

## 2.1 Ce que propose le cahier des charges

Le CdC v3.0 propose de faire dépendre le bonus du **nombre d'expressions distinctes**
trouvées :

| Expressions distinctes | Bonus modules (Couche C) | Bonus split Hard/Soft (Couche D) |
|---|---|---|
| 2 | +4 points | +2 points |
| 3 à 4 | +6 points | +3 à 4 points |
| 5 et plus | +8 à 10 points | +5 points |

Le document précise que ces paliers sont « une proposition de départ à valider en atelier
RH ». La question posée est donc légitime : **sur quoi s'appuie-t-on pour les valider ?**

## 2.2 Le problème, mesuré

Trois textes ont été passés dans un détecteur suivant ces règles. Le premier est du texte
RH parfaitement ordinaire ; les deux autres décrivent des entreprises réellement typées.

| Texte | Longueur | Expressions du profil dominant | Bonus obtenu |
|---|---|---|---|
| **A** — PME, texte RH générique | 98 mots | Collaboration : **7** | **+9** |
| **B** — Studio créatif réellement typé | 94 mots | Innovation : **7** | **+9** |
| **C** — Industriel réellement typé | 91 mots | Rigueur : **8** | **+9** |

Le texte A ne dit rien de particulier. Il enchaîne *bienveillance, esprit d'équipe,
entraide, écoute, communication, inclusion, diversité* — le vocabulaire que toute
entreprise emploie sur sa page « À propos ». **Il obtient exactement le même bonus maximal
qu'un studio qui banalise une journée par semaine pour le prototypage.**

Deuxième constat sur le même texte A : il déclenche **4 profils sur 6**. La règle du CdC
« 3 profils ou plus = signal trop dilué, on garde les 2 plus forts » se déclenche donc sur
du texte parfaitement ordinaire — elle ne sera pas l'exception, elle sera le cas courant.

**Le comptage d'expressions distinctes ne mesure pas l'intensité d'une culture. Il mesure
la richesse du vocabulaire RH employé.** Une page « À propos » longue et bien écrite bat
systématiquement une page courte et honnête.

## 2.3 Les options pour fixer le chiffre

### Option 1 — Les paliers fixes du CdC, tels quels

Le nombre brut d'expressions distinctes détermine le palier.

✅ Simple à expliquer, simple à coder, reproductible.
❌ Ne distingue pas le typage réel du vocabulaire standard (mesuré ci-dessus).
❌ Favorise les textes longs.
❌ Aucune justification empirique des valeurs 4 / 6 / 9.

### Option 2 — Densité plutôt que comptage

On rapporte le nombre d'expressions à la longueur du texte : *expressions pour 100 mots*.

✅ Neutralise l'avantage des textes longs.
❌ Pénalise les textes courts et denses, qui sont souvent les plus sincères.
❌ Ne résout **pas** le problème principal : le texte A reste dense en vocabulaire
collaboratif. Il obtiendrait toujours un bonus élevé.

### Option 3 — Position relative dans le corpus réel

Le bonus dépend de la position de l'offre **par rapport aux autres offres de la
plateforme**. Une offre dans les 10 % les plus marquées sur « Innovation » obtient le
bonus maximal ; une offre dans la moyenne n'obtient rien.

✅ **Résout le problème mesuré** : si toutes les entreprises écrivent « bienveillance », ce
mot cesse mécaniquement de distinguer qui que ce soit. Seul l'écart à la norme compte.
✅ S'auto-calibre : le système s'adapte à mesure que le corpus grandit.
❌ Demande un corpus de départ. En dessous d'environ **200 offres réelles**, les seuils
seraient du bruit.
❌ Le bonus d'une offre peut changer quand d'autres offres sont publiées — difficile à
expliquer à un recruteur. *(Correctif : ne recalculer les seuils qu'une fois par
trimestre, et l'annoncer.)*
❌ Plus difficile à expliquer qu'un palier fixe.

### Option 4 — Pondérer chaque expression par sa rareté

Chaque expression reçoit un poids inversement proportionnel à sa fréquence dans le corpus.
« Bienveillance », présent dans 80 % des offres, ne vaut presque rien. « Banalisé pour le
prototypage », rare, vaut beaucoup.

✅ Même bénéfice que l'option 3, mais au niveau du **mot**, donc **on peut toujours montrer
le mot** — l'explicabilité est préservée.
✅ Se calcule à l'avance, hors du chemin de la détection.
❌ Demande le même corpus de départ.
❌ Un mot rare mais accidentel peut peser lourd. *(Correctif : plafonner le poids d'une
expression isolée.)*

### Option 5 — Apprendre les valeurs sur des données de recrutement réelles

Ajuster les bonus pour qu'ils prédisent au mieux les recrutements qui ont réussi.

✅ La seule option qui donnerait une justification *empirique* aux chiffres.
❌ **Impossible aujourd'hui** : cela demande des centaines de recrutements aboutis, avec un
suivi de la réussite en poste. Le projet n'a aucune donnée de ce type.
❌ Un modèle appris sur l'historique reproduit les biais de l'historique — précisément le
risque que l'AI Act vise. Demanderait un test de non-discrimination formel.

## 2.4 Un point qu'aucune option ne doit ignorer

Un bonus de +9 points **ne vaut pas 9 points de Fit Score**. Le sous-score soft n'est pas
divisé par 100, mais par la somme des poids des modules **mesurables** — et « Prise de
décision » ne l'est pas, faute de jeu livré.

| Profil | Dénominateur réel | Ce que vaut réellement +9 points |
|---|---|---|
| TECHNIQUE | 70 | **12,9 %** |
| ANALYTIQUE | 70 | **12,9 %** |
| RELATIONNEL | 80 | 11,2 % |
| MANAGERIAL | 80 | 11,2 % |
| CONVENTIONNEL | 85 | 10,6 % |
| ARTISTIQUE | 85 | 10,6 % |

Sur un métier technique, le plafond annoncé « ± 8 à 10 points » **agit en réalité comme
± 12,9 %**. Le plafond ne veut donc pas dire la même chose selon le métier, ce qui n'était
pas l'intention.

**Recommandation associée** : exprimer les plafonds **en effet sur la note finale**, pas en
points de pondération. « Une suggestion ne peut jamais déplacer le Fit Score de plus de
X points » est une phrase vérifiable, stable d'un métier à l'autre, et compréhensible par
un recruteur comme par un candidat.

## 2.5 Recommandation

**Phase 1 (maintenant)** : Option 1, les paliers fixes du CdC — mais **avec les plafonds
exprimés en effet sur la note finale** (2.4), et le drapeau « v1 — non calibré » affiché
au recruteur. C'est ce qui permet de livrer et de commencer à collecter du texte réel.

**Phase 2 (après ~200 offres)** : basculer vers l'**Option 4**, la pondération par rareté.
C'est la seule qui corrige le défaut mesuré en 2.2 *sans* renoncer à montrer le mot au
candidat. L'option 3 corrige le même défaut mais rend l'explication plus difficile.

**À écarter** : l'option 5 tant qu'aucune donnée de réussite en poste n'existe.

---

# Question 3 — À qui retire-t-on les points ?

La contrainte est absolue : après ajustement, les 5 modules doivent totaliser **exactement
100**, et soft + hard aussi.

## 3.1 Le cadre du problème

Le CdC autorise **jusqu'à 2 modules bonifiés** par offre, jusqu'à **+10 points chacun**, et
interdit de bonifier un module **déjà dominant**. Il reste donc 3 modules pour absorber
jusqu'à 20 points.

Les résultats ci-dessous viennent d'un balayage de **toutes les combinaisons autorisées** —
36 au total, soit 6 profils × 6 paires de modules bonifiables — avec un bonus de +9 sur
chacun des deux modules.

## 3.2 Les options

### Option 1 — À parts égales

Chaque absorbeur cède le même nombre de points.

**Résultat du balayage : 3 combinaisons sur 36 sont impossibles.**

Le cas le plus net, sur un métier TECHNIQUE (poids 30 / 20 / 30 / 15 / **5**), si l'on
bonifie Mémoire de travail et Planification :

| Module | Poids de base | À parts égales (−6 chacun) | Résultat |
|---|---|---|---|
| Flexibilité | 30 | −6 | 24 |
| Prise de décision | 30 | −6 | 24 |
| **Régulation émotionnelle** | **5** | **−6** | **−1** ❌ |

Un poids négatif n'a aucun sens. La méthode s'effondre exactement là où le CdC est le plus
susceptible de s'appliquer : le module le plus faible est aussi celui qu'on ne bonifie pas,
donc celui qui absorbe.

✅ Trivial à expliquer.
❌ **Mathématiquement inapplicable dans 8 % des cas autorisés.**

### Option 2 — Proportionnelle au poids

Chaque absorbeur cède une **fraction de ce qu'il possède**. Un module qui pèse 30 cède six
fois plus qu'un module qui pèse 5.

Même cas, métier TECHNIQUE :

| Module | Poids de base | Part de l'absorption | Cède | Résultat |
|---|---|---|---|---|
| Flexibilité | 30 | 30 / 65 | −8,3 | 21,7 |
| Prise de décision | 30 | 30 / 65 | −8,3 | 21,7 |
| **Régulation émotionnelle** | **5** | 5 / 65 | **−1,4** | **3,6** ✅ |

**Résultat du balayage : 0 combinaison sur 36 produit un poids négatif.**

Ce n'est pas une chance, c'est une propriété : un module qui cède un pourcentage de ce
qu'il a **ne peut pas céder plus qu'il n'a**. La méthode est sûre par construction, pas
par vérification.

✅ Ne peut jamais produire de poids négatif.
✅ Préserve les proportions relatives entre les modules non concernés.
❌ Un module déjà faible devient très faible : 5 % → 3,2 %. À ce niveau, le module est
encore mesuré mais ne pèse presque plus rien.

### Option 3 — Proportionnelle, avec un plancher

Comme l'option 2, mais aucun module ne peut descendre sous un seuil (par exemple 5 %).
Les points que le plancher empêche d'absorber sont redistribués sur les autres absorbeurs.

**Vérification sur les 6 profils** : la capacité d'absorption au-dessus d'un plancher de
5 % vaut au minimum **35 points**, alors que le maximum jamais demandé est de **20 points**
(2 modules × 10). **Le plancher est donc toujours finançable** — il ne bloquera jamais une
suggestion légitime.

✅ Toutes les garanties de l'option 2.
✅ Garantit qu'aucun module ne devient décoratif. Un module tombé à 1 % n'est plus une
mesure, c'est un affichage.
✅ Vérifié comme toujours applicable sur la matrice réelle.
❌ Une règle de plus à expliquer.
❌ La valeur du plancher est arbitraire et devra être tranchée en atelier RH.

### Option 4 — Prendre uniquement au module dominant

Le module le plus lourd finance seul le bonus.

✅ La plus simple à raconter : « on a déplacé du poids depuis la compétence la plus
attendue vers celle que votre culture privilégie ».
❌ Contredit l'intention de la matrice : le module dominant est dominant **parce que le
métier l'exige**. Le vider au profit d'un signal culturel inverse la hiérarchie que la
matrice devait porter.
❌ Sur un profil RELATIONNEL, la régulation émotionnelle pèse 45 — la vider de 20 points
transforme le métier en autre chose.

### Option 5 — Ne pas compenser du tout

On renormalise : les poids peuvent totaliser plus de 100, et on divise par leur somme.

✅ Aucune arithmétique d'absorption.
❌ **Change silencieusement tous les autres modules.** Un recruteur qui accepte « +8 sur
Prise de décision » verrait les quatre autres baisser sans l'avoir demandé ni compris.
❌ Rend l'écran de décision impossible à présenter honnêtement.

## 3.3 Et pour le split Hard / Soft ?

Le cas est beaucoup plus simple : deux valeurs seulement. L'une monte de δ, l'autre baisse
de δ. Il n'y a pas de choix de méthode à faire.

Une seule vérification était nécessaire : le poids hard, sur la matrice réelle, va de
**10 à 65**. Un déplacement de ±5 le laisse toujours dans l'intervalle **[5, 70]** — jamais
de valeur négative, jamais au-dessus de 100. **Le plafond de ±5 est sûr sur les 24 lignes.**

## 3.4 Recommandation

**Option 3 — proportionnelle avec plancher à 5 %.**

L'option 1 est à écarter : elle est démontrée inapplicable dans 3 cas sur 36. L'option 2
est correcte et suffirait ; le plancher ajoute une garantie utile pour un coût faible,
puisqu'il est toujours finançable.

Deux règles complémentaires à retenir dans tous les cas :

1. **Toujours repartir du socle fixe**, jamais d'une pondération déjà ajustée. Le CdC le
   dit ; c'est ce qui empêche une dérive cumulative offre après offre.
2. **Vérifier la somme avant d'écrire.** Si le total ne fait pas exactement 100, rejeter la
   suggestion entière plutôt que d'écrire une pondération incohérente. Les poids étant des
   entiers, une répartition proportionnelle produit des décimales : il faut une règle
   déterministe d'attribution du point restant, sinon la somme dérive de 1.

---

# Récapitulatif des recommandations

| Question | Recommandation | Raison principale |
|---|---|---|
| **1. Extraction** | Dictionnaire déterministe, sémantique en appui hors ligne | Seul un mot se montre à un candidat — exigence RGPD / AI Act |
| **2. Chiffre du bonus** | Paliers du CdC en v1, plafonds exprimés **en effet sur la note** ; pondération par rareté après ~200 offres | Le comptage brut ne distingue pas une culture réelle d'un vocabulaire RH standard (mesuré) |
| **3. Absorption** | Proportionnelle au poids, avec plancher à 5 % | Seule méthode qui ne peut pas produire de poids négatif ; vérifiée sur les 36 combinaisons |

## Les trois choses à trancher en atelier RH

1. **La valeur du plancher** (proposition : 5 %).
2. **Les paliers de bonus**, à confronter à un échantillon d'offres réelles.
3. **Le contenu des dictionnaires**, et notamment l'exclusion du vocabulaire trop courant
   pour distinguer quoi que ce soit.

---

# Plan de test et durées

## Ce qui a déjà été mesuré

| Mesure | Résultat | Comment |
|---|---|---|
| Temps de détection par offre | **0,2 ms** | 60 expressions, texte de 750 mots, Java 21, 20 000 tours après chauffe |
| Débit sur un seul cœur | **≈ 5 000 offres/s** | déduit du précédent |
| Rattrapage de 10 000 offres | **2 secondes** | déduit du précédent |
| Combinaisons où « parts égales » échoue | **3 sur 36** | balayage exhaustif sur la matrice réelle |
| Combinaisons où « proportionnel » échoue | **0 sur 36** | même balayage |
| Capacité d'absorption au-dessus d'un plancher à 5 % | **≥ 35 points** (besoin max : 20) | même balayage |
| Texte RH générique vs entreprise réellement typée | **même bonus (+9)** | 3 textes de ~95 mots |

## Ce qui reste à tester, et en combien de temps

| Test | Ce qu'il vérifie | Effort | Prérequis |
|---|---|---|---|
| **Somme = 100 sur toutes les combinaisons** | Aucun arrondi ne fait dériver le total | 0,5 j | — |
| **Aucun poids négatif ni sous le plancher** | La méthode d'absorption tient partout | 0,5 j | — |
| **Un socle jamais modifié** | Deux acceptations successives ne s'empilent pas | 0,5 j | — |
| **Détection sur offres réelles** | Taux de déclenchement, profils dominants | 2 j | ~50 offres réelles |
| **Test de non-discrimination** | Aucun profil de candidat systématiquement désavantagé | 3 j | échantillon + cadrage juridique |
| **Journal d'audit rejouable** | Une décision passée se réexplique | 1 j | journal construit |

**Développement estimé** : détection 3 j · calcul des suggestions 2 j · écran Accepter /
Ignorer 3 j · journal d'audit 3 j — soit environ **11 jours**, hors atelier RH et hors
analyse d'impact RGPD.

## Deux points qui ne sont pas des tests logiciels

Le CdC les cite, et ils conditionnent la mise en production autant que le code :

- **L'analyse d'impact RGPD (AIPD)** et la documentation AI Act, à mener avec le service
  juridique.
- **La validation des dictionnaires en atelier RH**, sans laquelle le système reste
  légitimement marqué « v1 — non calibré ».

---

# Annexe — comment les chiffres ont été obtenus

Toutes les valeurs de ce document sont reproductibles.

**Temps de détection** — un programme Java autonome construit un dictionnaire de
60 expressions réparties sur les 6 profils du CdC, l'applique à un texte de 750 mots
(profil entreprise + description de poste, en français), et mesure 20 000 exécutions après
une phase de chauffe de la machine virtuelle. Sans cette chauffe, on mesurerait le
compilateur et non l'algorithme.

**Balayage de l'absorption** — un script énumère, pour chacun des 6 profils de la matrice,
toutes les paires de modules bonifiables selon la règle du CdC (le module dominant est
exclu), applique un bonus de +9 sur chacun, puis calcule ce que les 3 modules restants
doivent céder selon les deux méthodes. Il compte les cas produisant un poids négatif.

**Comparaison des textes** — trois textes de longueur comparable (~95 mots) ont été
rédigés : un texte RH volontairement générique, et deux textes décrivant des entreprises
réellement typées. Le même détecteur leur a été appliqué.

**Chiffres repris du projet, non remesurés ici** — les 29 ms du calcul déterministe du Fit
Score et les 361 ms de l'ancien repli par IA proviennent des mesures faites lors de la
suppression de ce repli. Les poids de la matrice proviennent des migrations `V42` et `V53`.

---

*Module Recrutement — projet Zennyt. Document de cadrage en réponse aux questions posées
sur le cahier des charges « Pondération assistée » v3.0. État au 11 août 2026.*
