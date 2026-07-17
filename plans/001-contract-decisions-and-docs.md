# Plan 001 : Figer le contrat canonique et documenter Recruitment

> **Instructions exécuteur** : ce plan est contract-first et documentaire. Ne modifier
> aucun contrôleur avant validation écrite des décisions ci-dessous. Si le worktree contient
> encore les changements Recruitment non commités observés pendant l’audit, les isoler ou
> demander au propriétaire de les stabiliser ; ne pas les écraser.
>
> **Drift check** : `git diff --stat 2359b37..HEAD -- contracts idendity.md backend/src/main/java/com/zennyt/recruitment`

## Statut

- **Priorité** : P1
- **Effort** : M
- **Risque** : MED — choix de routes potentiellement cassants
- **Dépend de** : aucun
- **Catégorie** : contrat, documentation
- **Planifié au** : commit `2359b37`, 2026-07-14

## Pourquoi

`contracts/recruitment.openapi.yaml` n’est pas conforme aux contrôleurs en cours. L’audit a
mesuré 18 opérations contract-only et 11 runtime-only. Implémenter la sécurité ou des tests
avant de choisir les routes canoniques obligerait à maintenir deux surfaces concurrentes.

## État actuel

- `contracts/recruitment.openapi.yaml` : source de vérité déclarée, mais `operationId` est vide
  sur les opérations et plusieurs routes ne correspondent pas au runtime.
- `backend/src/main/java/com/zennyt/recruitment/api/` : expose notamment
  `/assessment-attempts`, `/candidates/me/applications`, `/recruiters/me/job-offers`,
  `/callbacks/integrity` et `/payments`.
- `idendity.md` existe et doit rester le document Identity tant qu’un renommage n’est pas validé.
- Aucun document Recruitment n’existe. `AGENTS.md` exige une autorisation avant de le créer.
- Aucun appel Recruitment n’a été trouvé dans `mobile/lib`, donc aucune compatibilité mobile
  existante n’est démontrée.

## Périmètre

**Dans le périmètre** :

- `contracts/recruitment.openapi.yaml`
- `contracts/identity.openapi.yaml` uniquement si une divergence confirmée est trouvée
- `RECRUITMENT_MODULE.md` à créer après autorisation
- `idendity.md` pour tracer les décisions transversales pertinentes

**Hors périmètre** : contrôleurs, domaine, persistance, migrations, `pom.xml`, mobile.

## Étapes

### 1. Obtenir quatre validations

Faire valider : création de `RECRUITMENT_MODULE.md`, accès futur à `shared/`, politique de
routes proposée dans `plans/README.md`, et politique d’expiration des JWT après désactivation
(recommandation : révocation immédiate fonctionnelle via projection d’état, plan 006).

**Vérifier** : une décision écrite existe pour chaque point. Sans réponse, STOP.

### 2. Produire une matrice contract/runtime

Pour chaque opération Recruitment, consigner : route canonique, rôle, propriétaire de la
ressource, statut attendu et sort de l’ancienne route (`keep`, `remove`, `defer`). Les 18 routes
contract-only doivent toutes avoir une décision explicite.

**Vérifier** : aucune ligne de la comparaison contract/runtime ne reste sans décision.

### 3. Modifier le contrat avant le backend

Appliquer les décisions dans `contracts/recruitment.openapi.yaml`, renseigner un `operationId`
unique et descriptif, déclarer JWT ou `callbackSecret`, documenter les réponses 400/401/403/404/
409/415/422/429/503 pertinentes et incrémenter `info.version` selon `contracts/README.md`.

**Vérifier** : `docker compose run --rm backend mvn -B generate-sources` sort avec code 0 et
aucun avertissement `Empty operationId` pour Recruitment.

### 4. Créer la documentation Recruitment

Après autorisation, documenter l’arborescence, les agrégats, machines à états, matrice des
rôles, événements consommés/publiés, routes canoniques, zones protégées, décisions à valider,
roadmap, changelog numéroté et date de dernière mise à jour.

**Vérifier** : `rg -n "Zones protégées|Décisions à valider|Changelog|Dernière mise à jour" RECRUITMENT_MODULE.md` retourne les quatre sections.

## Critères de fin

- [ ] Toutes les routes concurrentes ont une décision validée.
- [ ] Chaque opération OpenAPI possède un `operationId` unique.
- [ ] La génération OpenAPI réussit sans avertissement d’operationId vide.
- [ ] `RECRUITMENT_MODULE.md` existe avec autorisation et sections obligatoires.
- [ ] Aucun fichier Java, migration, `pom.xml` ou mobile n’est modifié.

## Conditions STOP

- Deux consommateurs exigent simultanément deux routes concurrentes.
- Le référent refuse la création du document ou la modification du contrat.
- Une opération absente du runtime doit finalement être livrée dans cette correction : créer
  un plan fonctionnel séparé au lieu de l’improviser ici.

