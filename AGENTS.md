# AGENTS.md — Règles de travail pour les agents IA sur Zennyt

> **Lis ce fichier en entier avant toute action.** Il définit ce que tu as le droit de faire, ce que
> tu dois demander avant de faire, et ce que tu ne dois jamais faire sans autorisation explicite.
> En cas de doute entre deux interprétations : **demande, n'improvise pas.**

---

## 0. Les 5 règles d'or (à ne jamais enfreindre)

1. **Reste dans le module demandé.** Ne modifie jamais un autre module sans demander d'abord.
2. **Lis le `.md` du module avant de coder, mets-le à jour après.**
3. **Ne touche jamais au `pom.xml` ni au `pubspec.yaml`** sans autorisation explicite.
4. **N'invente jamais un écran ni un asset.** Les maquettes sont dans `mobile/assets/<nom du jeu>/`.
5. **Réutilise les composants partagés.** Ne réécris pas ce qui existe déjà.

---

## 1. Périmètre : ne travaille QUE sur le module demandé

Le projet est un **monolithe modulaire** découpé en bounded contexts. Quand on te demande de
travailler sur un module, **tu ne touches qu'à ce module**.

**Modules (bounded contexts) :**
| Module | Backend | Mobile | Doc de référence |
|--------|---------|--------|------------------|
| `games` | `backend/src/main/java/com/zennyt/games/**` | `mobile/lib/features/games/**` | `GAMES_MODULE.md` |
| `identity` | `backend/src/main/java/com/zennyt/identity/**` | `mobile/lib/features/auth/**` | `IDENTITY_AUTH_README.md` |
| `recruitment` | `backend/src/main/java/com/zennyt/recruitment/**` | — | *(à créer)* |
| `engagement` | `backend/src/main/java/com/zennyt/engagement/**` | — | *(à créer)* |
| `analytics` | `backend/src/main/java/com/zennyt/analytics/**` | — | *(à créer)* |
| `shared` | `backend/src/main/java/com/zennyt/shared/**` | `mobile/lib/core/**` | ⚠️ **transversal — demande avant de toucher** |

**Règle :**
- ✅ On te dit « travaille sur games » → tu modifies `games` (backend + mobile + son contrat).
- ❌ Tu as besoin de toucher `identity`, `shared`, ou `core/` → **ARRÊTE et demande**, en expliquant
  précisément pourquoi c'est nécessaire et ce que tu comptes changer.
- ❌ Tu vois un bug dans un autre module → **signale-le**, ne le corrige pas de toi-même.

**Cas particulier — `shared` / `core`** : ces dossiers sont utilisés par TOUS les modules. Une
modification y a un effet de bord potentiel partout. Demande toujours avant d'y toucher, même pour
« juste ajouter un helper ».

---

## 2. Documentation : lis avant, mets à jour après

**Avant de commencer** toute tâche sur un module :
1. Lis **entièrement** le `.md` de ce module (ex. `GAMES_MODULE.md` pour games).
2. Lis la section « Zones protégées » et « Décisions à valider » — elles te disent ce qu'il ne faut
   pas casser et ce qui est encore en suspens.
3. Si le `.md` du module n'existe pas, **demande** s'il faut le créer avant de coder.

**À la fin de toute tâche**, dans la **même PR** :
1. Mets à jour le `.md` du module (arborescence des fichiers, barèmes, tableau de statut, roadmap).
2. Ajoute une **entrée de changelog** numérotée et datée, courte, décrivant ce qui a changé.
3. Mets à jour la ligne « **Dernière mise à jour** ».
4. Si tu as pris une décision produit qui n'était pas dans la spécification, **trace-la** dans la
   section « Décisions à valider » — ne la fais jamais passer silencieusement pour du validé.

> ⚠️ **Ne réécris jamais l'historique du changelog.** Les entrées passées décrivent le passé et
> doivent rester intactes, même si elles décrivent un état transitoire depuis dépassé.

---

## 3. Dépendances : ne touche pas au `pom.xml` / `pubspec.yaml`

**Interdit sans autorisation explicite :**
- Ajouter, retirer ou mettre à jour une dépendance dans `backend/pom.xml`.
- Ajouter, retirer ou mettre à jour une dépendance dans `mobile/pubspec.yaml`.
- Changer une version de framework, de plugin, ou de la JVM/SDK.

**Si tu penses avoir besoin d'une nouvelle dépendance :**
1. **ARRÊTE.**
2. Explique : quelle dépendance, pourquoi, quelle alternative existe avec ce qui est déjà installé.
3. Attends la réponse. Ne l'ajoute pas « en attendant ».

Dans 90 % des cas, ce dont tu as besoin existe déjà dans le projet — cherche d'abord.

---

## 4. Implémentation d'écrans : les maquettes font autorité

**N'invente JAMAIS un écran, une couleur, une icône ou un asset.**

Quand on te demande d'implémenter des pages/écrans pour un jeu :

1. **Va d'abord dans** `/Users/mac/Documents/GitHub/zennyt-private/zennyt-project/mobile/assets/`
2. **Trouve le dossier portant le nom du jeu** (ex. `04 Optimal Path/`, `04 Predictive Puzzle/`,
   `J'investigue/`…).
3. **Analyse TOUS les écrans et objets de ce dossier** avant d'écrire une ligne de code : ordre des
   écrans, structure, composants visuels, illustrations, icônes, objets de jeu.
4. **Liste ce que tu as trouvé** et le flow que tu en déduis, **avant** de coder.
5. Si un écran ou un asset **manque** dans le dossier : **demande**, ne l'invente pas.
6. Déclare les nouveaux assets dans `pubspec.yaml` → ⚠️ c'est une modification de `pubspec.yaml`,
   donc **demande** (voir §3). En pratique : signale les assets à déclarer, ne le fais pas toi-même.

**Attention aux chemins avec caractères spéciaux** (apostrophes unicode, espaces, accents) : vérifie
que le chemin déclaré correspond **exactement** au nom réel du dossier sur disque, et teste le
chargement.

---

## 5. Réutilise les composants partagés — ne recode pas ce qui existe

**Avant d'écrire un widget, un bouton, une carte, un HUD, un dialogue de pause, un écran de
résultats : cherche s'il existe déjà.**

- Design system jeux : `mobile/lib/features/games/presentation/widgets/game_system_components.dart`
  (et tout autre fichier de composants partagés du module).
- Composants transversaux : `mobile/lib/core/**` (⚠️ lecture OK, modification → demande, §1).

**Règle :**
- ✅ Le composant existe → **utilise-le tel quel**.
- ✅ Il existe mais il lui manque une variante → **étends-le proprement** (nouveau paramètre optionnel
  avec valeur par défaut, pour ne pas casser les usages existants).
- ❌ Copier-coller un widget existant pour le modifier localement → **interdit**. Ça crée de la
  duplication qui divergera.
- ❌ Recoder un bouton/HUD/panneau qui existe déjà → **interdit**.

**Même principe pour la logique** : constantes de barème, config, helpers de scoring — une seule
source de vérité. Si une valeur est dupliquée entre deux fichiers, **centralise-la** au lieu de la
copier.

---

## 6. Intégrations entre modules : analyse avant, plan d'abord

Quand on te demande d'**intégrer** deux modules (ex. brancher les jeux sur le profil, relier
identity au reste), tu ne fonces pas dans le code.

**Procédure obligatoire :**

1. **Analyse l'existant des DEUX côtés** : quels endpoints existent déjà, quels écrans existent déjà,
   quels modèles de données, qu'est-ce qui est provisoire.
2. **Repère les écrans / endpoints provisoires** (mocks, placeholders, « coming soon », données en
   dur) qui devront être **supprimés** une fois la vraie intégration faite. Ne les laisse pas
   traîner à côté du vrai code.
3. **Repère les conflits d'endpoints similaires** : si deux endpoints font presque la même chose
   (ex. `/api/v1/profiles/me` et `/api/v1/users/me`), **ARRÊTE et demande** lequel garder. Ne
   choisis pas tout seul, ne crée pas un troisième endpoint.
4. **Présente un plan écrit** avant de coder : ce que tu gardes, ce que tu supprimes, ce que tu
   crées, dans quel ordre.
5. **Attends la validation du plan.**
6. Seulement ensuite : implémente.

**Règle de câblage** : chaque endpoint backend doit être **effectivement branché** au front. Un
endpoint qui n'est appelé par personne, ou un écran qui affiche des données en dur alors que
l'endpoint existe, est un travail **non terminé**. Signale-le.

---

## 7. Architecture : les règles non négociables

Ces règles sont vérifiées automatiquement par **ArchUnit** en CI. Si tu les enfreins, la build casse.

1. **Le domaine est pur.** Aucune annotation Spring ni JPA dans `domain/`. Java pur uniquement.
2. **Les couches vont vers le centre** : `api/` → `application/` → `domain/` ; `infrastructure/` →
   `domain/`. Le domaine ne dépend de rien.
3. **Les modules communiquent uniquement par Domain Events.** Un module n'appelle jamais le code
   interne d'un autre. Seule liaison autorisée : écouter un événement.
4. **Le score/la logique métier est TOUJOURS calculé côté serveur.** Le client mesure et envoie des
   métriques brutes, jamais un résultat calculé. (Anti-triche par conception.)
5. **Contract-first** : toute évolution d'API modifie `contracts/<module>.openapi.yaml` **en
   premier**, puis le backend, puis le mobile.
6. **Le schéma DB passe par Flyway uniquement** (`ddl-auto: validate`). Nouvelle migration
   `V<n>__*.sql` ; **ne modifie JAMAIS une migration existante**. Vérifie d'abord si une migration
   est vraiment nécessaire (la contrainte existe peut-être déjà).
7. **Parité mock ⇄ backend** : si un mock mobile reproduit une logique serveur, les deux doivent
   rester identiques. Toute modification de l'un impose la modification de l'autre **dans la même
   PR**, avec un commentaire croisé pointant l'un vers l'autre.

---

## 8. Qualité : ce qui est attendu à chaque tâche

- **Tests** : toute logique métier ajoutée ou modifiée a un test (domaine en Java pur, sans Spring).
  Les cas limites et les pièges connus sont testés explicitement.
- **Non-régression** : si tu modifies un calcul existant, prouve par un test que le comportement
  antérieur est préservé (ou explique précisément ce qui change et pourquoi).
- **Nommage** : les constantes portent le **nom exact de la clé de la spécification** métier, pour
  que la traçabilité spec → code soit immédiate.
- **Constantes, pas de magie** : aucune valeur numérique en dur dans la logique. Sors-la dans un
  fichier de config nommé, avec un commentaire si c'est une valeur provisoire ou non validée.
- **Décisions non validées** : marque-les explicitement en commentaire
  (`// PROVISOIRE — à valider`) **et** dans la section « Décisions à valider » du `.md` du module.
- La CI doit rester verte : ArchUnit, tests backend, `flutter analyze`, tests mobile.

---

## 9. Ce que tu fais AVANT de commencer (checklist)

- [ ] J'ai lu le `.md` du module concerné, y compris « Zones protégées » et « Décisions à valider ».
- [ ] J'ai identifié le périmètre exact : quels fichiers je vais toucher, et **aucun autre module**.
- [ ] Si des écrans sont demandés : j'ai exploré `mobile/assets/<nom du jeu>/` et listé les maquettes.
- [ ] J'ai cherché les composants/helpers existants à réutiliser (pas de duplication).
- [ ] Je n'ai besoin d'aucune nouvelle dépendance (sinon → je demande avant).
- [ ] Si c'est une intégration : j'ai présenté un plan et attendu sa validation.

## 10. Ce que tu fais AVANT de livrer (checklist)

- [ ] Contrat OpenAPI modifié en premier si l'API a changé.
- [ ] Parité mock ⇄ backend vérifiée, commentaires croisés en place.
- [ ] Tests écrits et verts (backend + mobile), ArchUnit vert, `flutter analyze` clean.
- [ ] Aucun fichier d'un autre module modifié (ou alors : autorisation obtenue et mentionnée).
- [ ] `pom.xml` / `pubspec.yaml` non modifiés (ou alors : autorisation obtenue).
- [ ] `.md` du module mis à jour : arborescence, barème, statut, roadmap, changelog, « Dernière mise
      à jour ».
- [ ] Décisions produit non spécifiées → tracées dans « Décisions à valider ».
- [ ] Écrans/assets provisoires devenus inutiles → supprimés, pas laissés en doublon.

---

## 11. Quand tu dois t'ARRÊTER et demander

Arrête-toi et pose la question dans **tous** ces cas :

- Tu as besoin de toucher **un autre module** que celui demandé.
- Tu as besoin de toucher **`shared/` ou `core/`**.
- Tu as besoin d'**une nouvelle dépendance** (`pom.xml` / `pubspec.yaml`).
- Un **écran ou un asset manque** dans le dossier des maquettes.
- Tu trouves **deux endpoints similaires** et tu ne sais pas lequel garder.
- Une **spécification est ambiguë** ou contredit le code existant.
- Tu t'apprêtes à **modifier un barème / une règle métier validée** (zone protégée).
- Tu t'apprêtes à **modifier une migration Flyway existante**.
- Le travail demandé impliquerait de **supprimer du code existant** dont tu n'es pas sûr qu'il soit
  mort.

**Formule la question précisément** : ce que tu veux faire, pourquoi, quelles options existent, ce
que tu recommandes. Puis **attends la réponse** — ne code pas « en attendant ».

---

## 12. Format de tes livrables

À la fin de chaque tâche, fournis systématiquement :

1. **Fichiers créés** / **Fichiers modifiés**, groupés par côté (backend / contrat / mobile / doc).
2. **Diff du contrat OpenAPI** si l'API a changé.
3. **Résultats des tests** (nombre de tests verts, backend et mobile).
4. **Décisions produit prises** et tracées (celles qui ne venaient pas de la spécification).
5. **Points ouverts / questions** restées sans réponse.
6. **Confirmation explicite** que les zones protégées n'ont pas été touchées.

Sois **concis et factuel**. Pas de paraphrase de ce que tu viens de faire ligne par ligne — un
récapitulatif structuré suffit.
