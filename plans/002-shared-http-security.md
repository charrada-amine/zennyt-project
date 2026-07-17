# Plan 002 : Corriger le socle HTTP et les règles publiques partagées

> **Instructions exécuteur** : ce plan touche `shared/`. Obtenir l’autorisation explicite
> avant toute édition. Ne déplacer aucune logique métier Identity ou Recruitment dans shared.
>
> **Drift check** : `git diff --stat 2359b37..HEAD -- backend/src/main/java/com/zennyt/shared contracts/common.openapi.yaml backend/src/test`

## Statut

- **Priorité** : P1
- **Effort** : M
- **Risque** : MED — filtre de sécurité transversal
- **Dépend de** : plan 001 et autorisation `shared/`
- **Catégorie** : sécurité, correction
- **Planifié au** : commit `2359b37`, 2026-07-14

## Pourquoi

La règle publique `GET /api/v1/job-offers/**` expose actuellement les candidatures d’une offre.
De plus, `AuthorizationDeniedException`, contenu multipart invalide, header obligatoire absent et
JSON illisible tombent dans le handler générique 500. Les clients reçoivent donc des erreurs
mensongères et des données Recruitment sont accessibles sans JWT.

## État actuel

- `SecurityConfig.java:69` autorise `/api/v1/job-offers/**` en GET.
- `SecurityConfig.java:70` autorise tous les callbacks, en supposant un secret applicatif.
- `GlobalExceptionHandler.java:82-85` convertit toute exception non prévue en 500.
- Test live : mauvais rôle Identity → 500 ; candidature d’une offre sans JWT → 200 ; multipart
  non supporté → 500.

## Périmètre

**Dans le périmètre** :

- `backend/src/main/java/com/zennyt/shared/infrastructure/config/SecurityConfig.java`
- `backend/src/main/java/com/zennyt/shared/infrastructure/web/GlobalExceptionHandler.java`
- nouveaux tests sous `backend/src/test/java/com/zennyt/shared/infrastructure/`
- `contracts/common.openapi.yaml` si le format d’erreur doit être complété

**Hors périmètre** : annotations de rôles Recruitment, logique OTP/callback, `pom.xml`.

## Étapes

### 1. Réduire la surface publique

Autoriser seulement `GET /api/v1/job-offers` et le détail dont le dernier segment est un UUID.
Utiliser un matcher exact/regex ; ne jamais autoriser les sous-ressources `applications`,
`candidates`, `assessments` ou `assessment-results`.

**Vérifier** : test MockMvc sans JWT : liste/détail offre = 200 ou 404 métier ;
`/job-offers/{uuid}/applications` = 401.

### 2. Mapper les erreurs protocolaires

Ajouter des handlers ciblés : refus Spring Security → 403 ; media type → 415 ; JSON illisible,
header/paramètre requis absent et type de paramètre invalide → 400. Conserver le format `ApiError`
et ne jamais exposer une stack trace.

**Vérifier** : tests unitaires/MockMvc couvrant chaque exception, avec statut et schéma d’erreur.

### 3. Conserver les callbacks publics uniquement au niveau réseau

Laisser `/callbacks/**` sans JWT seulement si le plan 004 valide le secret avant mutation. Ajouter
un commentaire explicite et un test qui prouve qu’un callback sans header n’atteint pas le use case.

**Vérifier** : callback sans secret = 401/403, jamais 500 et aucune écriture repository.

## Tests

- Public job list/detail.
- Sous-route job sensible sans JWT.
- JWT invalide = 401 ; rôle invalide = 403.
- JSON invalide = 400 ; multipart invalide = 415 ; validation DTO = 400.
- Erreur inattendue = 500 avec message générique.

Commande : `docker compose run --rm backend mvn -B -Dtest='*Security*Test,*ExceptionHandler*Test' test` → tous verts.

## Critères de fin

- [ ] Aucune wildcard publique ne couvre une sous-ressource Recruitment sensible.
- [ ] Les statuts 400/401/403/415 sont distincts et testés.
- [ ] Le schéma `ApiError` reste compatible avec `common.openapi.yaml`.
- [ ] Aucun import de module Identity/Recruitment n’est ajouté dans shared.
- [ ] `pom.xml` n’est pas modifié.

## Conditions STOP

- Autorisation `shared/` absente.
- Une autre API dépend volontairement du wildcard `/job-offers/**`.
- La correction semble nécessiter une dépendance Maven supplémentaire.

