# Pondération assistée par la culture d'entreprise — analyse et plan

**Module Recrutement — Zennyt**
Analyse du cahier des charges « Pondération assistée » v3.0 et plan d'implémentation.

> Toutes les affirmations sur l'existant ci-dessous ont été vérifiées dans le code, pas
> supposées. Les références de fichiers sont exactes au 6 août 2026.

---

## 1. Le point de friction principal — à trancher avant tout le reste

Le cahier des charges Fit Score v3, §2, pose une interdiction explicite :

> « La description textuelle libre d'une offre n'est **jamais** une source de pondération
> automatique : seuls les niveaux structurés (métier, société, offre) pilotent le calcul. »

Cette règle n'est pas restée théorique. La tâche **F22** a retiré `jobDescription` et
`companyDescription` des entrées du calculateur, avec ce commentaire dans
`FitScoreCalculatorPort` :

> « Surtout, les garder invitait à s'en servir : le CdC §2 interdit explicitement que la
> description textuelle libre pilote la pondération. »

**Le nouveau document propose précisément ce que le CdC interdit** : dériver la pondération
du profil entreprise et de la description du poste.

### La réconciliation est possible, mais elle repose entièrement sur un point

Les deux textes sont compatibles **uniquement** parce que la décision du recruteur est
obligatoire. Le texte ne pilote jamais le calcul : il produit une *proposition*, et c'est
un humain qui, en cliquant, fixe une valeur au niveau « offre » — un des trois niveaux
structurés que le CdC autorise.

Conséquences concrètes, non négociables :

- **Aucune application automatique, jamais** — pas même pour les suggestions « à forte
  confiance ». Une optimisation du type « auto-accepter au-delà de 5 signaux pour faire
  gagner du temps au recruteur » violerait à la fois le CdC §2 et l'AI Act.
- **Le texte ne doit jamais atteindre le calculateur.** Seuls des nombres validés par un
  humain y entrent. F22 a nettoyé ce chemin ; il faut qu'il le reste.

C'est le premier point à faire confirmer par l'encadrant : le document ne mentionne pas
cette tension avec le CdC v3, et quelqu'un la découvrira tôt ou tard.

---

## 2. Ce qui est solide dans le document

À dire aussi, parce que plusieurs choix sont bien vus :

- **Mots clés plutôt qu'analyse sémantique.** Le projet dispose déjà d'un modèle
  d'empreintes qui pourrait détecter la culture par similarité. Le choix des mots clés
  explicites est meilleur ici : un mot clé se montre à un candidat qui conteste, une
  similarité vectorielle non. C'est exactement ce que l'explicabilité exige.
- **Taxonomie fermée de 6 profils, un par module.** Évite le remappage artificiel d'une
  classification externe (type Denison ou Cameron-Quinn) sur les 5 modules du CdC.
- **Le bonus dépend du nombre de signaux, pas du profil détecté.** Aucun profil de culture
  n'est structurellement favorisé — c'est une précaution anti-biais réelle.
- **Le socle n'est jamais modifié.** La suggestion part toujours de la matrice fixe, jamais
  d'un résultat déjà ajusté : pas de dérive cumulative.
- **Plafond plus bas sur le split Hard/Soft** (± 5 contre ± 8-10). Correct : ce curseur pèse
  bien plus lourd sur le classement final.
- **« v1 — non calibré »** reprend une convention déjà en place : la table
  `job_role_profiles` porte déjà un booléen `calibrated`, à `false` partout.

---

## 3. Points de friction techniques (vérifiés dans le code)

### 3.1 — « Prise de décision » n'est pas mesurable

Le profil **Autonomie / Entrepreneuriale** bonifie le module *Prise de décision*. Or côté
Games, `MiniGame.DECISION_CORE` a son drapeau `playable` à `false` — le catalogue de
scénarios est vide.

Bonifier un module qu'aucun candidat ne peut alimenter **n'a aucun effet sur le score**.
Pire : la mécanique de compensation retirerait des points aux autres modules pour financer
un bonus inerte, ce qui **dégraderait** le score au lieu de l'ajuster.

À trancher avant l'atelier RH : soit ce profil est désactivé jusqu'à livraison du mini-jeu,
soit la compensation ignore les modules non mesurables.

### 3.2 — Où stocker les poids ajustés

`JobRoleProfile` est une table de référence **partagée** : 24 lignes (6 profils × 4
niveaux), une seule par combinaison. Deux offres du même métier et du même niveau lisent
aujourd'hui la même ligne. Une pondération ajustée par offre n'a donc nulle part où vivre.

**Décision recommandée : stocker les poids validés sur l'offre elle-même.** Raison
concrète, pas esthétique : la détection de péremption des scores compare déjà
`fit_scores.computed_at < job_offers.updated_at` (vérifié dans `JpaFitScoreRepository`).
Si accepter une suggestion touche l'offre, **tous les scores concernés deviennent périmés
et sont repris automatiquement**, sans écrire un seul mécanisme nouveau.

Le stocker ailleurs obligerait à ajouter une comparaison de plus dans la requête de
péremption — faisable, mais c'est du travail en pure perte.

### 3.3 — Le chargement par lot devient plus coûteux

`JobRoleProfileResolver.resolveAll()` résout aujourd'hui *n'importe quel nombre d'offres*
en deux requêtes, parce que le référentiel tient en 24 lignes chargées une fois. Des poids
par offre cassent cette propriété.

À prévoir explicitement : charger les surcharges du lot en une requête indexée par offre,
sur le modèle de ce qui a été fait pour les paires. Sinon on réintroduit le problème de
N requêtes que le travail de juillet a supprimé.

### 3.4 — Aucun précédent d'audit dans le projet

Recherche faite : **aucun journal d'audit n'existe** dans le code, dans aucun contexte. Le
journal exigé ici (mots clés, source, delta, date, recruteur) est donc une construction
entièrement nouvelle — et ce n'est pas un confort, c'est une **exigence réglementaire**.

À dimensionner comme tel : rétention, accès, et surtout **immuabilité** (un journal
modifiable ne prouve rien).

### 3.5 — Le texte de l'entreprise vient d'un autre contexte

`companyInfo` vit sur `RecruitmentActor`, une **projection** alimentée par événements
depuis le module Identity. Elle peut être absente ou en retard. La détection doit traiter
ce cas sans échouer, et le journal doit enregistrer *quelle version* du texte a été
analysée — sinon une contestation ultérieure est invérifiable.

### 3.6 — Trois règles du document sont sous-spécifiées

| Règle | Ce qui manque |
|---|---|
| « un module déjà dominant ne peut pas recevoir de bonus » | **Aucun seuil.** Qu'est-ce que « dominant » ? 40 % dans l'exemple. 30 % ? 25 % ? |
| « les modules sans signal absorbent la compensation » | **Aucun plancher.** Si les modules absorbants sont déjà bas, la compensation peut les rendre négatifs. |
| Re-détection | **Non traité.** Si le recruteur modifie la description après avoir accepté, que devient la suggestion ? |

Ces trois points bloqueront l'implémentation dès qu'on écrira le premier test.

### 3.7 — Multilingue

Les dictionnaires du document sont en français. L'application est bilingue et les profils
d'entreprise peuvent être rédigés en anglais. Un dictionnaire monolingue donnerait
« aucun signal détecté » sur la moitié des offres — silencieusement, ce qui est le pire cas.

---

## 4. Plan d'implémentation

Ordonné pour que chaque étape soit livrable et vérifiable seule.

### Phase 0 — Décisions préalables (aucun code)

Rien ne doit être écrit avant ces réponses.

- [ ] **0.1** Confirmer la lecture du §1 : le texte ne pilote pas le calcul, la décision
      humaine le fait. Acter que l'auto-application est exclue définitivement.
- [ ] **0.2** Trancher le sort du profil *Autonomie* tant que « Prise de décision » n'est
      pas jouable.
- [ ] **0.3** Fixer le seuil de « module dominant » et le plancher de compensation.
- [ ] **0.4** Décider la politique de re-détection après modification de l'offre.
- [ ] **0.5** Décider la langue des dictionnaires (français seul en v1, ou bilingue).
- [ ] **0.6** Lancer l'analyse d'impact RGPD avec le délégué à la protection des données —
      **en parallèle du développement**, pas après : elle peut invalider des choix.

### Phase 1 — Le socle de stockage et d'audit

*Sans traçabilité, le reste n'est pas déployable.*

- [ ] **1.1** Migration : poids ajustés portés par l'offre (5 modules + split Hard/Soft),
      `NULL` = aucun ajustement, donc comportement actuel inchangé.
- [ ] **1.2** Migration : table de journal d'audit — suggestion, mots clés détectés avec
      leur source, delta proposé, décision, recruteur, horodatage. En écriture seule.
- [ ] **1.3** Résolution de la pondération effective : socle métier × niveau, puis
      surcharge de l'offre si elle existe.
- [ ] **1.4** Variante par lot de cette résolution, en une requête indexée par offre.

**Tests** — une offre sans ajustement donne exactement le score d'aujourd'hui (non-régression
stricte) ; une offre ajustée donne le score attendu ; un lot de 200 offres mixtes ne
déclenche qu'une requête de surcharges.

### Phase 2 — Détection et suggestion

- [ ] **2.1** Dictionnaires de mots clés en configuration, modifiables sans redéploiement
      (même approche que les poids de classement déjà en place).
- [ ] **2.2** Détecteur : analyse combinée des deux textes, expressions distinctes,
      seuil minimal de 2, source conservée pour chaque expression.
- [ ] **2.3** Calcul de la suggestion : paliers de bonus, plafonds, exclusion des modules
      dominants, compensation à somme constante, priorité à la description du poste en cas
      de contradiction.
- [ ] **2.4** Au-delà de 2 profils détectés, ne retenir que les deux plus forts.

**Tests** — un mot clé isolé ne déclenche rien ; deux expressions déclenchent ; la somme
reste à 100 % dans tous les cas, y compris aux plafonds ; un module dominant ne reçoit
jamais de bonus ; un signal contradictoire fait gagner la description du poste ; un texte
sans signal ne produit aucune suggestion.

### Phase 3 — Décision du recruteur

- [ ] **3.1** Endpoint de consultation : suggestion + mots clés + delta, sans rien appliquer.
- [ ] **3.2** Endpoint de décision : Accepter ou Ignorer, binaire, journalisé.
- [ ] **3.3** Accepter écrit les poids sur l'offre **et** touche `updated_at`, ce qui rend
      les scores périmés et déclenche le recalcul par le mécanisme existant.
- [ ] **3.4** Contrat d'API et garde-fous de sécurité (seul le recruteur propriétaire décide).

**Tests** — consulter n'écrit rien ; accepter journalise et rend les scores périmés ;
ignorer journalise sans rien changer ; un autre recruteur reçoit un refus ; une seconde
décision sur la même suggestion est rejetée.

### Phase 4 — Calibration et conformité

*Hors périmètre du développement seul.*

- [ ] **4.1** Atelier RH : construire les dictionnaires sur un échantillon réel d'offres.
- [ ] **4.2** Tests de non-discrimination sur cet échantillon.
- [ ] **4.3** Documentation AI Act et analyse d'impact RGPD finalisées.
- [ ] **4.4** Mise en service derrière un interrupteur, marquée « v1 — non calibré ».

---

## 5. Ce que ce plan ne traite pas

- **Le niveau « société » du CdC v3** reste non construit. Ce document couvre l'ajustement
  par offre ; une surcharge s'appliquant à *toutes* les offres d'une entreprise reste un
  sujet distinct.
- **La qualité réelle de la détection** est inconnue tant que les dictionnaires n'existent
  pas. Aucun chiffre de précision ne peut être avancé aujourd'hui.
- **L'interface recruteur** n'est pas spécifiée ici — l'équipe mobile devra concevoir
  l'écran Accepter / Ignorer, avec l'affichage des mots clés qui justifient la suggestion.
- **La charge de détection** : analyser deux textes à chaque publication d'offre a un coût
  qui n'a pas été mesuré. À surveiller, sans le supposer négligeable.
