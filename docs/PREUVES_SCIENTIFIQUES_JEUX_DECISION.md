# Preuves scientifiques — jeux de décision comportementaux

Dossier de revue à l'intention du psychologue référent · Module `games` · 17 septembre 2026

## Objet du document

Le module `games` mesure aujourd'hui la prise de décision par un **seul** instrument, « Je Décide »
(`DECISION_CORE`) : un test de jugement situationnel à vignettes, 5 dimensions, 30 items notés. Cet
instrument est **déclaratif** — le candidat dit ce qu'il *ferait*.

Deux paradigmes **comportementaux** sont proposés pour compléter cette mesure : le **BART** (prise de
risque révélée) et l'**IST** (recueil d'information avant décision), plus une **couche de confiance**
greffée sur l'IST. Ce document rassemble les preuves scientifiques disponibles sur ces trois éléments,
y compris — et surtout — **ce que la littérature leur reproche**.

Il est écrit pour être lu de façon critique. Il n'a pas pour but de justifier les choix de conception :
il a pour but de donner de quoi les contester.

## Convention de fiabilité des sources

Chaque affirmation chiffrée porte un marqueur :

| Marqueur | Signification |
|---|---|
| **[V]** | Vérifié sur la source pendant la rédaction (résumé d'article, page d'éditeur ou dépôt PMC consulté) |
| **[AV]** | Référence citée de mémoire, **à vérifier sur le texte intégral** avant tout usage externe |

Aucun chiffre de ce document ne doit partir vers un client, un candidat ou un régulateur avant que les
**[AV]** aient été confirmés sur les textes intégraux. La bibliographie de la section 10 porte les
mêmes marqueurs.

---

# 1. L'avertissement qui domine tout le reste

Avant d'examiner chaque jeu, il faut poser le problème général, car il conditionne tout ce qui suit et
il s'applique **aussi aux jeux déjà livrés** du module.

## 1.1 Le paradoxe de fiabilité

Un effet expérimental devient célèbre quand il est robuste — c'est-à-dire quand **tous** les
participants le montrent. Or un effet que tout le monde montre de la même façon a, par construction,
une **faible variance inter-individuelle**. Et sans variance inter-individuelle, il n'y a rien à
mesurer chez un individu : la fiabilité test-retest s'écroule.

Autrement dit : les tâches cognitives les plus solides comme **expériences** sont souvent les plus
mauvaises comme **instruments de mesure individuelle**. Les tâches n'ont pas été conçues pour
distinguer des personnes ; elles ont été conçues pour démontrer un mécanisme.

> Hedge, Powell & Sumner (2018), *Behavior Research Methods* **[V]** — les auteurs montrent que la
> faible variance inter-sujets qui rend un effet expérimental robuste est exactement ce qui détruit la
> fiabilité des différences individuelles, et donc la réplicabilité des corrélations publiées à partir
> de ces tâches.

## 1.2 Le chiffre le plus important du dossier

Une méta-analyse de 2025 a agrégé **358 mesures de préférence pour le risque**, sur 33 panels,
57 échantillons et 579 114 répondants **[V]**.

| Catégorie de mesure | Stabilité test-retest | Accord interne (validité convergente) |
|---|---|---|
| Auto-rapport — propension | **0,61** (HDI 95 % : 0,52–0,70) | 0,41 (0,39–0,43) |
| Auto-rapport — fréquence | **0,60** (0,42–0,78) | 0,21 (0,19–0,23) |
| **Mesures comportementales** | **0,25** (0,17–0,34) | **0,20** (0,17–0,24) |
| Entre catégories | — | **≈ 0,1 ou moins** |

Source : Bagaïni et al. (2025), *Nature Human Behaviour* **[V]**.

Deux lectures de ce tableau, toutes deux importantes :

1. **La stabilité.** Une fiabilité de 0,25 est très loin de ce qu'exige une décision individuelle.
   Les standards de la profession situent le seuil autour de 0,70 pour une mesure de recherche, et
   plus haut encore pour une décision individuelle à enjeu **[AV — à confirmer sur les Standards
   AERA/APA/NCME 2014]**. Une mesure à 0,25 signifie que la majeure partie de ce qu'on observe chez un
   candidat un jour donné ne se retrouvera pas chez lui la fois suivante.
2. **L'accord.** Les mesures comportementales de risque **ne s'accordent pas entre elles** (0,20), et
   s'accordent encore moins avec les auto-rapports (≈ 0,1). Les auteurs concluent que « différentes
   mesures de préférence pour le risque peuvent présenter des signatures psychométriques très
   différentes » et qu'elles « ne devraient pas être utilisées de façon interchangeable ». Cela veut
   dire qu'on ne sait pas, en toute rigueur, **ce que** l'une d'entre elles mesure.

Le même constat vaut au-delà du risque : sur une large batterie d'auto-régulation, les mesures issues
de tâches comportementales se sont révélées nettement moins fiables que les auto-rapports
(Enkavi et al., 2019, *PNAS* **[V]**).

## 1.3 La nuance — et elle compte

Il serait malhonnête de s'arrêter au 0,25. Ce chiffre est une **moyenne de catégorie**, et le BART
semble faire mieux que sa catégorie dans les études qui l'ont testé isolément :

| Étude | Ce qui a été mesuré | Résultat |
|---|---|---|
| Weafer et al. (2013) **[AV]** | BART, retest à 8,6 jours en moyenne, N = 119 | r ≈ **0,79** |
| Buelow & Barnhart (2018) **[V pour la référence, AV pour les valeurs]** | BART, CCT, GDT et IGT, retest à 3 semaines, N = 98 | BART, CCT, GDT « modérément fortes » ; **IGT faible** |

Comment réconcilier 0,79 et 0,25 ? Trois facteurs plausibles, à discuter :

- **L'intervalle de retest.** Huit jours laissent intacts la mémoire de la tâche et la stratégie
  adoptée ; la méta-analyse agrège des intervalles bien plus longs. Une forte corrélation à court
  terme peut mesurer la persistance d'une stratégie plutôt que la stabilité d'un trait.
- **L'agrégation.** La catégorie « comportementale » de la méta-analyse mêle des tâches très
  inégales ; la moyenne ne décrit aucune tâche en particulier.
- **La mesure retenue.** Les pompes moyennes ajustées ne sont pas le seul indice extrait du BART, et
  les indices ne sont pas également fiables.

**Ce que la nuance ne sauve pas :** même si le BART est *répétable*, le problème de **validité
convergente** demeure entier. Une mesure peut être stable et mesurer autre chose que ce qu'on croit.

## 1.4 Conséquence pour la conception

Cette section n'est pas un préambule décoratif : elle dicte trois décisions de conception.

- **Aucun de ces deux jeux ne peut, seul, porter une décision d'embauche.** Ils apportent une
  information incrémentale à un profil, pondérée par leur fiabilité, jamais un verdict.
- L'**appétence au risque** du BART reste **descriptive et non classée** : nous ne la transformons pas
  en « meilleur / moins bon » (voir 2.4).
- L'événement Fit Score reste **suspendu** pour ces deux jeux jusqu'à validation, comme cela a déjà
  été fait pour « Je place ».

---

# 2. BART — Balloon Analogue Risk Task

## 2.1 Origine et statut

Lejuez et al. (2002), *Journal of Experimental Psychology: Applied*, 8(2), 75–84 **[V]**.

Étude d'origine : **N = 86**. La tâche a montré des propriétés expérimentales saines, et la prise de
risque au BART corrélait avec des mesures de recherche de sensations, d'impulsivité et de déficit de
contrainte comportementale **[V]**.

**Statut de propriété intellectuelle : procédure publiée, sans propriétaire.** Le BART est
librement implémentable. Aucune norme commerciale n'est utilisée ni nécessaire.

## 2.2 Protocole retenu

![Concept d'écran BART — couverture, gonflage, éclatement. Illustration de travail, pas une maquette validée.](figures/bart_concept.png)

- **30 ballons** notés, précédés de **2 ballons d'entraînement** non notés.
- Chaque pompe crédite une **réserve temporaire** ; « Collecter » la transfère vers la **banque
  permanente** ; l'éclatement la fait perdre.
- Point d'éclatement tiré uniformément sur **1..128** : la probabilité d'éclatement à la pompe *k*
  vaut `1 / (128 - k + 1)`. C'est le paramétrage d'origine.

## 2.3 L'indice standard, et pourquoi il ne peut pas être un score

L'indice principal du BART est le **nombre moyen de pompes ajusté** : la moyenne des pompes sur les
ballons **collectés uniquement**. Les ballons éclatés sont exclus parce qu'ils sont **tronqués** — on
ne sait pas combien de pompes le joueur aurait faites, seulement qu'il a été interrompu. Inclure les
essais éclatés comprimerait mécaniquement la moyenne des joueurs les plus téméraires, exactement à
l'envers de ce qu'on veut mesurer.

Cet indice est un **trait**, pas une performance :

- pompes élevées → enclin au risque ;
- pompes faibles → averse au risque ;
- **aucun des deux pôles n'est meilleur que l'autre.**

Un score sur 100 construit sur cet axe affirmerait qu'une des deux dispositions est supérieure. Rien
dans la littérature ne le soutient, et dans un contexte de recrutement une telle affirmation serait à
la fois fausse et attaquable. C'est pourquoi l'appétence au risque reste chez nous un **indicateur
descriptif non classé**.

## 2.4 Ce que nous ajoutons — et qui n'est dans aucun article

Le serveur génère la séquence d'éclatement ; il connaît donc quelque chose que le joueur ignore. Cela
autorise un axe de mesure qui, lui, **est** valide en performance : l'écart au rendement maximal
atteignable en espérance.

`EV(n) = n x valeur_pompe x (128 - n) / 128`, maximisée à **n\* = 64**.

```
ev_optimal_earnings = Somme  (n* x valeur_pompe)  si point_eclatement(essai) > n*
                      essais notes                sinon 0

efficiency_percent  = min(100, arrondi(total_earnings / ev_optimal_earnings x 100))
```

Le benchmark est la **meilleure stratégie fixe connaissant la loi**, évaluée sur la séquence
réellement servie au joueur. Il n'est **pas** clairvoyant : une stratégie qui pomperait
`point_eclatement - 1` fois à chaque essai suppose la connaissance de l'avenir, écraserait tout joueur
humain, et ne discriminerait plus rien. Le benchmark subit exactement la même chance que le joueur.

Sur cet axe, **l'excès de prudence comme l'excès de risque coûtent des points** — ce qui est
précisément la propriété qu'un score doit avoir.

> **[!] Cette construction n'est dans aucune publication.** Elle est propre à ce design. Elle vit
> dans `BartProvisionalRules`, marquée `// PROVISOIRE`, et c'est le premier point de la liste de
> validation (section 9). Le plafond à 100 et le traitement d'une séquence dégénérée
> (`ev_optimal_earnings = 0`) sont eux aussi des choix nôtres.

## 2.5 Ce qu'on reproche au BART

| Critique | Portée pour nous |
|---|---|
| Stabilité de catégorie faible (0,25) — Bagaïni et al. 2025 **[V]** | Atténuée par les retests propres au BART (2.3), mais non écartée |
| Validité convergente faible : n'accorde pas avec les autres mesures de risque **[V]** | **Non atténuée.** On ne peut pas affirmer que le BART mesure « le risque » en général |
| Effets d'apprentissage au fil des essais **[AV]** | La trajectoire essai par essai est conservée pour pouvoir l'examiner |
| Sensible à la version (automatique vs manuelle, nombre de ballons) **[AV]** | Notre version est fixée et documentée ; toute comparaison externe l'exige |

---

# 3. IST — Information Sampling Task

## 3.1 Origine et statut

Clark, Robbins, Ersche & Sahakian (2006), *Biological Psychiatry*, 60(5), 515–522 **[V]**.

Les participants ouvrent séquentiellement une grille de **25 cases** révélant deux couleurs, puis
désignent la couleur **majoritaire**. Deux conditions : **gain fixe** et **gain décroissant** **[V]**.

Échantillons de l'étude d'origine : usagers d'amphétamines (n = 24), d'opiacés (n = 40), anciens
usagers abstinents depuis au moins un an (n = 24), témoins non usagers (n = 26) **[V]**. Les usagers
actifs échantillonnaient **moins** d'information et décidaient à une **probabilité plus faible** d'avoir
raison **[V]** — c'est la définition opérationnelle de l'**impulsivité de réflexion**.

**Statut de propriété intellectuelle : paradigme publié ; une version sous marque figure dans la
batterie commerciale CANTAB [V].** Nous implémentons le paradigme publié et **n'utilisons aucune norme
CANTAB** — même discipline que la correction « Long Rosvold » déjà appliquée à « Je continue ».

## 3.2 Protocole retenu

![Concept d'écran IST — couverture, grille en gain décroissant, recueil de confiance. Illustration de travail, pas une maquette validée.](figures/ist_concept.png)

| Condition | Règle | Ce qu'elle isole |
|---|---|---|
| Gain fixe | 100 points si correct, quel que soit le nombre de cases ouvertes | Échantillonnage **gratuit** |
| Gain décroissant | Le gain part de 250 et perd 10 points par case ouverte | Échantillonnage **coûteux** |

20 essais notés (10 par condition), 1 essai d'entraînement par condition. Réponse incorrecte : −100
dans les deux conditions.

La **différence** entre les deux conditions est l'information la plus intéressante de la tâche :
échantillonner beaucoup quand c'est gratuit et moins quand c'est coûteux est un comportement
*adapté*, non une simple tendance.

## 3.3 Correction statistique obligatoire — P(correct)

C'est le point technique le plus important de ce dossier, et il change notre implémentation.

> Bennett, Oldham, Dawson, Parkes, Murawski & Yücel (2017), *Biological Psychiatry*, 82(4), e29–e30
> **[V]** — le calcul de l'indice principal de l'IST, **P(correct), repose sur une inférence
> statistique incorrecte**, ce qui **surestime systématiquement** l'impulsivité de réflexion des
> participants et gonfle le risque d'erreur de type II.

La correction proposée est une **formule bayésienne tenant compte de l'ordre dans lequel le
participant a ouvert les cases** **[V]**.

**Conséquence pour nous :** l'implémentation doit utiliser la formule corrigée de Bennett et al., pas
la formule conventionnelle. Comme le serveur possède la disposition réelle de la grille et la séquence
ordonnée des ouvertures, il a tout ce qu'il faut pour la calculer — mais il faut la calculer
correctement.

> **[!] Action avant implémentation :** récupérer le texte intégral de Bennett et al. (2017) et
> transcrire la formule exacte. Ce dossier n'en donne pas l'expression algébrique, et la reconstruire
> par déduction serait exactement le genre d'erreur que l'article dénonce.

## 3.4 Notation

Contrairement au BART, l'IST possède un **axe de compétence véritable**. Trois composantes, toutes
orientées « mieux / moins bien » :

1. exactitude des décisions ;
2. probabilité d'avoir raison au moment de s'engager — P(correct), formule corrigée ;
3. discrimination entre les deux conditions.

Score **/100** = mélange pondéré des trois. **[!] Les trois poids sont PROVISOIRES** et vivent dans
`IstProvisionalRules`.

## 3.5 Ce qu'on reproche à l'IST

| Critique | Portée pour nous |
|---|---|
| P(correct) conventionnel statistiquement incorrect **[V]** | **Traitée** : formule corrigée obligatoire (3.3) |
| Surestimation dépendante de l'âge chez l'enfant **[AV]** | Hors périmètre : population adulte |
| Fiabilité test-retest peu étudiée par rapport au BART | **Non traitée** — à signaler comme une incertitude réelle |
| Paradigme issu de la recherche clinique sur l'addiction | Le cadre d'interprétation en recrutement reste à construire (section 9) |

---

# 4. Couche de confiance — et une correction de notre propre conception

## 4.1 L'intention

Un tap sur une échelle de confiance après chaque décision IST, soit **20 jugements**. Deux indicateurs
visés au départ :

- **biais de calibration** = confiance moyenne − exactitude ;
- **sensibilité métacognitive** — capacité à distinguer ses bonnes de ses mauvaises réponses.

## 4.2 Pourquoi la sensibilité métacognitive doit être abandonnée ici

Le design initial proposait **AUROC2** plutôt que meta-d′, au motif que meta-d′ exige beaucoup
d'essais. La vérification bibliographique invalide ce raisonnement **sur les deux jambes**.

**Première jambe — AUROC2 n'est pas neutre.** AUROC2 **dépend de la performance de type 1**, c'est-à-dire
du taux de réussite à la tâche elle-même : plus la performance baisse, plus la part d'essais devinés
augmente, et plus AUROC2 baisse mécaniquement — à bruit métacognitif constant. meta-d′ a précisément
été inventé pour corriger ce défaut (Maniscalco & Lau 2012 ; Fleming & Lau 2014 **[V]**). Dans notre
usage, l'exactitude à l'IST **varie fortement d'un candidat à l'autre** : AUROC2 confondrait donc
« bon à la tâche » avec « bien calibré ». C'est exactement l'erreur à ne pas commettre dans un
contexte d'évaluation.

**Seconde jambe — le nombre d'essais est hors d'atteinte.** Guggenmos (2021), *Neuroscience of
Consciousness*, 2021(1), niab040 **[V]** :

| Nombre d'essais | Fiabilité test-retest du M-ratio |
|---|---|
| moins de 400 | r ≤ 0,6 |
| 400 à 600 | ≈ 0,7 |
| 600 à 800 | ≈ 0,85 |
| 400 à 600, mais exactitude à 60 % | ≈ **0,4** |

L'auteur recommande **un minimum de 400 essais** **[V]**. Nous en avons **20**. Il n'existe aucun
aménagement qui comble un facteur 20.

**Décision : la sensibilité métacognitive est retirée du lot 1.** Pas reléguée en « exploratoire » —
**retirée**. Publier un indicateur dont la fiabilité attendue est proche de zéro, même étiqueté
prudent, revient à inviter quelqu'un à s'en servir.

Et une conclusion plus structurelle, qui vaut d'être dite au commanditaire : **la sensibilité
métacognitive n'est pas mesurable dans un format d'évaluation de 15 minutes.** Ce n'est pas une limite
de notre implémentation, c'est une limite de la mesure. Si cette capacité compte vraiment, elle exige
un dispositif d'un autre ordre.

## 4.3 Ce qui reste

Le **biais de calibration** — sur/sous-confiance — est une simple différence de moyennes. Il sera
bruité à 20 essais, mais il est non biaisé en espérance et directement interprétable. Il est conservé
comme **indicateur descriptif, hors du score**.

Échelle par défaut, **[!] PROVISOIRE** : 4 points sans milieu neutre, mappés sur
`0,625 / 0,75 / 0,875 / 1,0` — la borne basse d'un choix binaire est 0,5, pas 0. Un jugement non fourni
est enregistré à vide et exclu de l'indicateur, sans invalider l'essai IST.

Cadre de lecture du biais : Moore & Healy (2008), *Psychological Review* **[AV]**, qui distingue
surestimation de sa performance, surplacement par rapport aux autres et excès de précision — trois
choses souvent confondues sous le mot « surconfiance ». Notre indicateur ne capte que la **première**.

---

# 5. Registre des divergences avec les protocoles publiés

Toute divergence entre ce que nous implémentons et ce que l'article décrit est listée ici. Une
divergence non listée est un défaut du document.

| # | Élément | Protocole publié | Notre implémentation | Motif |
|---|---|---|---|---|
| D1 | BART — score | Aucun score ; indices descriptifs | Score /100 en efficience EV | Le module exige un `Attempt` noté ; axe reconstruit pour être valide en performance (2.4) |
| D2 | BART — récompense | Gain monétaire réel | Points sans contrepartie | Contrainte produit. **Effet sur la validité à discuter** : l'enjeu réel est un ingrédient du paradigme |
| D3 | BART — entraînement | Non systématique | 2 ballons non notés | Aligné sur la pratique du module (échauffement Move Fast exclu) |
| D4 | IST — P(correct) | Formule conventionnelle, **incorrecte** | Formule bayésienne corrigée de Bennett et al. | Correction obligatoire (3.3) |
| D5 | IST — récompense | Points, parfois convertis | Points seuls | Idem D2 |
| D6 | Confiance | meta-d′ / M-ratio sur grands effectifs d'essais | **Biais de calibration seul** | 20 essais rendent la sensibilité non mesurable (4.2) |
| D7 | Les deux jeux | Passation supervisée en laboratoire | Passation possiblement autonome | Contrôles de validité **renforcés** en mode non supervisé, comme « Je Décide » |
| D8 | Les deux jeux | Population clinique ou étudiante | Candidats en recrutement | **Divergence de population non résolue.** Aucune norme transférable ; voir section 9 |

La divergence **D2** mérite une attention particulière : le BART et l'IST ont été validés avec des
gains réels. Remplacer l'argent par des points non convertibles change ce que le joueur risque. La
littérature sur l'incitation en économie expérimentale suggère que cela peut modifier le
comportement **[AV]**. Nous ne pouvons pas le corriger, mais nous devons le dire.

La divergence **D8** est la plus lourde. Ces paradigmes ont été validés en distinguant des groupes
cliniques de témoins. **Rien ne garantit qu'ils discriminent utilement parmi des candidats
professionnels**, qui forment une population beaucoup plus homogène — et l'homogénéité est
exactement ce qui détruit la fiabilité (section 1.1).

---

# 6. Paradigmes écartés, et le motif probant

Ces paradigmes ont été examinés et **rejetés**. Le motif est dans chaque cas empirique ou
déontologique, pas une question de coût de développement.

## 6.1 Iowa Gambling Task — écarté

Bechara, Damasio, Damasio & Anderson (1994), *Cognition* **[AV]**. Le paradigme de décision sous
ambiguïté le plus célèbre. Écarté pour trois raisons convergentes :

- **Fiabilité individuelle insuffisante.** Buelow & Barnhart (2018) **[V pour la référence]** trouvent
  une fiabilité **faible** pour l'IGT là où le BART, le CCT et le GDT sont modérément forts. Schmitz
  et al. (2020), *Assessment* **[AV]**, intitulent leur article « problèmes non résolus de fiabilité
  et de validité pour la prise de risque ».
- **Hypothèses de base contestées.** Steingroever et al. (2013), *Psychological Assessment* **[AV]** :
  les trajectoires d'apprentissage individuelles ne ressemblent pas à la courbe moyenne du groupe, et
  la variabilité inter-études est forte, plusieurs études rapportant des scores nets très bas chez des
  sujets sains. Buelow & Suhr (2009) **[AV]** relèvent qu'il n'existe pas de définition précise de ce
  que l'IGT mesure.
- **Statut commercial.** La version diffusée et ses normes passent par PAR Inc. **[AV]**

Un instrument dont on ne sait ni ce qu'il mesure ni s'il le mesure deux fois de la même façon n'a pas
sa place dans une décision d'embauche.

## 6.2 Tâche de Markov à deux étapes — écartée

Daw et al. (2011), *Neuron* **[AV]**. Sépare élégamment le contrôle *model-based* du *model-free*.
Écartée pour deux raisons : la notation exige un ajustement de modèle bayésien hiérarchique, ce qui
place le score hors de toute vérification simple ; et le résultat est **inexplicable à un recruteur**,
ce qui est disqualifiant pour un instrument dont une personne devra justifier l'usage.

## 6.3 Paradigmes d'intégrité — écartés, et recommandation de ne pas les construire

Fischbacher & Föllmi-Heusi (2013) **[AV]** ; Mazar, Amir & Ariely (2008) **[AV]**. Mesurent la
tricherie quand le sujet se croit non observé.

**Trois motifs, chacun suffisant :**

1. **Le paradigme exige de tromper le candidat.** La mesure n'est valide que si la personne croit
   n'être pas observée. Un dispositif de recrutement qui repose sur cette croyance est incompatible
   avec le consentement éclairé.
2. **Exposition juridique.** Un score d'intégrité alimentant une décision d'embauche est un terrain
   d'impact disparate et de contestation.
3. **La littérature de ce domaine précis a été gravement atteinte.** Shu, Mazar, Gino, Ariely &
   Bazerman (2012), *PNAS* — **rétracté le 13 septembre 2021** : l'expérience de terrain (étude 3)
   contenait des **données frauduleuses** **[V]**. Les auteurs eux-mêmes avaient publié en 2020 un
   article ne parvenant pas à répliquer leurs propres résultats **[V]**.

Précision d'équité : la rétractation porte sur l'étude de placement de signature, **pas** sur la tâche
matricielle de 2008, qui est un travail distinct. Mais lorsqu'un champ voit son résultat le plus
médiatisé s'effondrer sur une fraude de données, la prudence s'impose sur l'ensemble du champ.

**Si l'intégrité compte pour le Fit Score**, la voie défendable est un **inventaire d'intégrité
transparent**, où le candidat sait ce qui est évalué — pas un paradigme de tromperie.

## 6.4 Contraintes conflictuelles — écartées pour l'instant

Les tâches de compromis multi-attributs (lignée Tversky) recouvriraient `OPTIMAL_PATH` (zones
coûteuses) et `TASK_SCHEDULING`, déjà sous `PLANIFIK`. Le conflit taxonomique doit être tranché avant
d'ajouter un troisième instrument sur le même terrain.

---

# 7. Paradigmes des lots suivants

| Lot | Paradigme | Référence | Ce qui le recommande | Ce qui l'attend |
|---|---|---|---|---|
| 2 | Apprentissage par renversement probabiliste | Cools, Clark, Owen & Robbins (2002), *J. Neurosci.* **[AV]** | Complète `MOVE_FAST`, qui change de règle avec un indice **explicite** ; ici le changement n'est jamais annoncé | 80 à 120 essais ; fiabilité individuelle à vérifier |
| 3 | Actualisation temporelle titrée | Du, Green & Myerson (2002) ; AUC de Myerson, Green & Warusawitharana (2001) **[AV]** | L'**AUC** est un indice sans modèle, réputé robuste ; l'actualisation temporelle est l'une des mesures comportementales les plus stables **[AV]** | Reste **déclaratif** : recouvre partiellement l'approche à vignettes |
| 4 | Confiance et ultimatum | Berg, Dickhaut & McCabe (1995) ; Güth, Schmittberger & Schwarze (1982) **[AV]** ; méta-analyse Johnson & Mislin (2011) **[AV]** | Seule famille touchant des compétences réellement interpersonnelles | En mono-joueur le partenaire est un **algorithme** : on mesure les croyances sur autrui, pas une interaction. **À divulguer explicitement** |

Le lot 3 mérite d'être signalé au psychologue comme **contre-exemple utile** : dans le paysage
généralement décevant de la fiabilité des tâches comportementales, l'actualisation temporelle fait
figure d'exception favorable **[AV, à confirmer]**. Si la fiabilité est le critère dominant, ce lot
pourrait légitimement passer devant le lot 2.

---

# 8. Cadre juridique et déontologique

Cette section signale des points à faire trancher par un conseil juridique. **Elle ne constitue pas un
avis juridique.**

| Sujet | Point d'attention | Statut |
|---|---|---|
| Règlement européen sur l'IA | Les usages liés à l'emploi et à la gestion des travailleurs relèvent des systèmes **à haut risque** (annexe III) **[AV — numéro de règlement et point d'annexe à confirmer]** | À faire qualifier |
| Code du travail français | Les méthodes et techniques d'aide au recrutement doivent être **pertinentes au regard de la finalité** et portées à la connaissance du candidat (art. L1221-8 / L1221-9) **[AV]** | À faire qualifier |
| RGPD, décision automatisée | Encadrement d'une décision fondée exclusivement sur un traitement automatisé (art. 22) **[AV]** | À faire qualifier |
| Validité liée au critère | Un instrument de sélection demande des preuves de validité **pour le poste visé**, pas seulement de validité de construit | **Absente à ce jour** pour ces deux jeux |
| Impact disparate | À surveiller par âge, genre, origine, handicap — les tâches chronométrées et motrices sont des points de vigilance connus | Dispositif de suivi **à définir** |

Deux remarques de fond, cohérentes avec la section 1 :

- Une fiabilité faible n'est pas seulement un problème scientifique : elle est un problème
  d'**équité**. Une mesure instable classe des personnes selon un bruit qui varie d'un jour à l'autre.
- Le module a déjà la bonne réponse architecturale : `sessionUsable`, les runs *audit-only*, et
  l'événement Fit Score **suspendu** tant que le barème n'est pas validé. Ces garde-fous doivent
  rester en place pour ces deux jeux.

---

# 9. Ce que nous demandons au psychologue référent

## 9.1 Bloquant — sortir de la couche provisoire

1. **La formule d'efficience EV du BART** (2.4). Construction propre à ce design, dans aucune
   publication. Le benchmark « stratégie fixe optimale n\* = 64 » est-il le bon référent, ou faut-il
   une norme d'échantillon ? Le plafond à 100 est-il acceptable ? Une séquence dégénérée doit-elle
   invalider la session ou être régénérée ?
2. **Les trois poids du score IST** (3.4).
3. **La formule corrigée de P(correct)** : valider sa transcription depuis Bennett et al. (2017) une
   fois le texte intégral obtenu (3.3).
4. **Les bandes de niveau** des deux jeux.
5. **L'échelle de confiance** : valider ou remplacer le défaut à 4 points et son mappage (4.3).
6. **Les seuils de validité de session** par jeu.

## 9.2 Questions de fond, plus importantes que les réglages

7. **La divergence de population (D8).** Ces paradigmes discriminent-ils utilement parmi des candidats
   professionnels, population bien plus homogène que celles où ils ont été validés ? Si la réponse est
   incertaine, faut-il livrer ces jeux en **mode observation** — mesures collectées, aucun score
   exposé au recruteur — le temps de constituer des données internes ?
8. **La perte de l'enjeu réel (D2).** Des points non convertibles suffisent-ils à faire fonctionner un
   paradigme validé avec de l'argent ?
9. **Le plancher de fiabilité acceptable.** Quelle fiabilité minimale exigez-vous avant qu'une mesure
   entre dans le Fit Score ? Ce seuil, fixé une fois, tranche mécaniquement plusieurs débats de ce
   document.
10. **La taxonomie.** Ces deux paradigmes forment-ils un domaine, ou des facettes de la décision ? Le
    nom `DECISION_BEHAVIORAL` est un nom de travail. Question déjà ouverte pour « Je coordonne » et
    « Je place ».
11. **La confirmation de la section 4.2** : acceptez-vous le retrait de la sensibilité métacognitive,
    et la conclusion qu'elle n'est pas atteignable dans un format de 15 minutes ?

## 9.3 Divergences que nous signalons de notre propre initiative

12. Le BART ne produit **pas** de mesure « meilleur / moins bon » sur son indice standard. Tout
    rapport lu par un recruteur doit le dire, sans quoi l'appétence au risque sera lue comme une note.
13. L'IST sous marque CANTAB et l'IGT via PAR Inc. sont commerciaux. **Aucune norme** de ces batteries
    n'est utilisée — seuls les paradigmes publiés le sont.
14. L'ordre des lots suivants pourrait être revu au profit de l'actualisation temporelle, plus fiable
    que le renversement probabiliste (section 7).

---

# 10. Bibliographie

Marqueurs : **[V]** vérifié pendant la rédaction · **[AV]** à vérifier sur le texte intégral.

## Mesure et psychométrie — la section à lire en premier

| Réf. | Statut |
|---|---|
| Bagaïni, A., Liu, Y., Kapoor, M., Son, G., Bürkner, P.-C., Tisdall, L., & Mata, R. (2025). A systematic review and meta-analyses of the temporal stability and convergent validity of risk preference measures. *Nature Human Behaviour*, 9(4), 700–712. doi:10.1038/s41562-024-02085-2 | **[V]** |
| Hedge, C., Powell, G., & Sumner, P. (2018). The reliability paradox: why robust cognitive tasks do not produce reliable individual differences. *Behavior Research Methods*, 50(3), 1166–1186. doi:10.3758/s13428-017-0935-1 | **[V]** |
| Enkavi, A. Z., Eisenberg, I. W., Bissett, P. G., Mazza, G. L., MacKinnon, D. P., Marsch, L. A., & Poldrack, R. A. (2019). Large-scale analysis of test–retest reliabilities of self-regulation measures. *PNAS*, 116(12), 5472–5477. | **[V]** |
| Frey, R., Pedroni, A., Mata, R., Rieskamp, J., & Hertwig, R. (2017). Risk preference shares the psychometric structure of major psychological traits. *Science Advances*, 3(10), e1701381. | **[V]** |
| Buelow, M. T., & Barnhart, W. R. (2018). Test–retest reliability of common behavioral decision making tasks. *Archives of Clinical Neuropsychology*, 33(1), 125–129. | **[V]** réf. / **[AV]** valeurs |
| Weafer, J., Baggott, M. J., & de Wit, H. (2013). Test–retest reliability of behavioral measures of impulsive choice, impulsive action, and inattention. | **[AV]** |
| AERA, APA & NCME (2014). *Standards for Educational and Psychological Testing*. | **[AV]** |

## BART

| Réf. | Statut |
|---|---|
| Lejuez, C. W., Read, J. P., Kahler, C. W., Richards, J. B., Ramsey, S. E., Stuart, G. L., Strong, D. R., & Brown, R. A. (2002). Evaluation of a behavioral measure of risk taking: the Balloon Analogue Risk Task (BART). *Journal of Experimental Psychology: Applied*, 8(2), 75–84. | **[V]** |

## IST et impulsivité de réflexion

| Réf. | Statut |
|---|---|
| Clark, L., Robbins, T. W., Ersche, K. D., & Sahakian, B. J. (2006). Reflection impulsivity in current and former substance users. *Biological Psychiatry*, 60(5), 515–522. | **[V]** |
| Bennett, D., Oldham, S., Dawson, A., Parkes, L., Murawski, C., & Yücel, M. (2017). Systematic overestimation of reflection impulsivity in the Information Sampling Task. *Biological Psychiatry*, 82(4), e29–e30. | **[V]** |
| Huq, S. F., Garety, P. A., & Hemsley, D. R. (1988). Probabilistic judgements in deluded and non-deluded subjects. *Quarterly Journal of Experimental Psychology*, 40(4), 801–812. | **[AV]** |

## Métacognition

| Réf. | Statut |
|---|---|
| Guggenmos, M. (2021). Measuring metacognitive performance: type 1 performance dependence and test-retest reliability. *Neuroscience of Consciousness*, 2021(1), niab040. | **[V]** |
| Fleming, S. M., & Lau, H. C. (2014). How to measure metacognition. *Frontiers in Human Neuroscience*, 8, 443. | **[V]** |
| Maniscalco, B., & Lau, H. (2012). A signal detection theoretic approach for estimating metacognitive sensitivity from confidence ratings. *Consciousness and Cognition*, 21(1), 422–430. | **[V]** |
| Moore, D. A., & Healy, P. J. (2008). The trouble with overconfidence. *Psychological Review*, 115(2), 502–517. | **[AV]** |

## Paradigmes écartés

| Réf. | Statut |
|---|---|
| Bechara, A., Damasio, A. R., Damasio, H., & Anderson, S. W. (1994). Insensitivity to future consequences following damage to human prefrontal cortex. *Cognition*, 50(1–3), 7–15. | **[AV]** |
| Steingroever, H., Wetzels, R., Horstmann, A., Neumann, J., & Wagenmakers, E.-J. (2013). Performance of healthy participants on the Iowa Gambling Task. *Psychological Assessment*, 25(1), 180–193. | **[AV]** |
| Buelow, M. T., & Suhr, J. A. (2009). Construct validity of the Iowa Gambling Task. *Neuropsychology Review*, 19(1), 102–114. | **[AV]** |
| Schmitz, F., Kunina-Habenicht, O., Hildebrandt, A., Oberauer, K., & Wilhelm, O. (2020). Psychometrics of the Iowa and Berlin Gambling Tasks: unresolved issues with reliability and validity for risk taking. *Assessment*, 27(2), 232–252. | **[AV]** |
| Daw, N. D., Gershman, S. J., Seymour, B., Dayan, P., & Dolan, R. J. (2011). Model-based influences on humans' choices and striatal prediction errors. *Neuron*, 69(6), 1204–1215. | **[AV]** |
| Fischbacher, U., & Föllmi-Heusi, F. (2013). Lies in disguise: an experimental study on cheating. *Journal of the European Economic Association*, 11(3), 525–547. | **[AV]** |
| Mazar, N., Amir, O., & Ariely, D. (2008). The dishonesty of honest people: a theory of self-concept maintenance. *Journal of Marketing Research*, 45(6), 633–644. | **[AV]** |
| Shu, L. L., Mazar, N., Gino, F., Ariely, D., & Bazerman, M. H. (2012). *PNAS*, 109(38), 15197–15200. **RÉTRACTÉ** le 13 septembre 2021 (*PNAS* 118(38), e2115397118) — données frauduleuses dans l'étude de terrain. | **[V]** |
| Kristal, A. S., Whillans, A. V., Bazerman, M. H., Gino, F., Shu, L. L., Mazar, N., & Ariely, D. (2020). Signing at the beginning versus at the end does not decrease dishonesty. *PNAS*, 117(13), 7103–7107. | **[V]** |

## Lots suivants et autres paradigmes de risque

| Réf. | Statut |
|---|---|
| Cools, R., Clark, L., Owen, A. M., & Robbins, T. W. (2002). Defining the neural mechanisms of probabilistic reversal learning. *Journal of Neuroscience*, 22(11), 4563–4567. | **[AV]** |
| Myerson, J., Green, L., & Warusawitharana, M. (2001). Area under the curve as a measure of discounting. *Journal of the Experimental Analysis of Behavior*, 76(2), 235–243. | **[AV]** |
| Du, W., Green, L., & Myerson, J. (2002). Cross-cultural comparisons of discounting delayed and probabilistic rewards. *The Psychological Record*, 52(4), 479–492. | **[AV]** |
| Kirby, K. N., Petry, N. M., & Bickel, W. K. (1999). Heroin addicts have higher discount rates for delayed rewards than non-drug-using controls. *JEP: General*, 128(1), 78–87. | **[AV]** |
| Berg, J., Dickhaut, J., & McCabe, K. (1995). Trust, reciprocity, and social history. *Games and Economic Behavior*, 10(1), 122–142. | **[AV]** |
| Güth, W., Schmittberger, R., & Schwarze, B. (1982). An experimental analysis of ultimatum bargaining. *Journal of Economic Behavior & Organization*, 3(4), 367–388. | **[AV]** |
| Johnson, N. D., & Mislin, A. A. (2011). Trust games: a meta-analysis. *Journal of Economic Psychology*, 32(5), 865–889. | **[AV]** |
| Rogers, R. D., et al. (1999). Choosing between small, likely rewards and large, unlikely rewards. *Journal of Neuroscience*, 19(20), 9029–9038. | **[AV]** |
| Brand, M., Fujiwara, E., Borsutzky, S., Kalbe, E., Kessler, J., & Markowitsch, H. J. (2005). Decision-making deficits of Korsakoff patients in a new gambling task with explicit rules. *Neuropsychology*, 19(3), 267–277. | **[AV]** |
| Figner, B., Mackinlay, R. J., Wilkening, F., & Weber, E. U. (2009). Affective and deliberative processes in risky choice. *JEP: LMC*, 35(3), 709–730. | **[AV]** |

---

## Note sur les illustrations

Les deux figures des sections 2.2 et 3.2 sont des **illustrations de travail** fournies pour situer le
propos. Elles ne sont **pas** des maquettes validées : le dossier `mobile/assets/` ne contient aucune
planche pour ces deux jeux, et la règle du projet interdit d'inventer un écran ou un asset. Le
périmètre mobile reste suspendu au handoff design.

## Documents liés

`docs/superpowers/specs/2026-09-17-decision-behavioral-games-design.md` — design technique, structure
du `GameType`, schéma de base, découpage en lots.

`GAMES_MODULE.md` — documentation vivante du module, dont l'état de « Je Décide » et les précédents
« Je coordonne » / « Je place » cités ici.

**Dernière mise à jour** : 17 septembre 2026
