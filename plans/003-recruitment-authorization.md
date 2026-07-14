# Plan 003 : Appliquer les rôles et la propriété à chaque endpoint Recruitment

> **Instructions exécuteur** : les identifiants d’acteur viennent toujours du JWT. Ne réutiliser
> aucune annotation interne à Identity et ne toucher ni `identity/` ni `shared/` dans ce plan.
>
> **Drift check** : `git diff --stat 2359b37..HEAD -- backend/src/main/java/com/zennyt/recruitment contracts/recruitment.openapi.yaml backend/src/test/java/com/zennyt/recruitment`

## Statut

- **Priorité** : P1
- **Effort** : L
- **Risque** : HIGH — modification de tous les chemins métier Recruitment
- **Dépend de** : plans 001 et 002
- **Catégorie** : sécurité
- **Planifié au** : commit `2359b37`, 2026-07-14

## Pourquoi

Les contrôleurs Recruitment n’ont pas de frontières de rôle cohérentes. Les tests live ont montré
qu’un candidat peut créer une offre, une évaluation, une vérification d’identité et un paiement,
modifier une candidature et swiper sous l’UUID d’un tiers. Les lectures par identifiant ne valident
souvent ni rôle ni propriété : c’est une famille d’IDOR, pas un défaut isolé.

## État actuel

- `JobOfferController.java:40` accepte `req.recruiterId()` au lieu d’imposer le principal.
- `SwipeController.java:36` accepte `req.swiperId()` ; `targets` accepte aussi un acteur arbitraire.
- `MatchController.java:30,42` permet de remplacer l’identité `/me` par query param.
- `ApplicationController.java:57-80` ne reçoit aucun principal pour les listes recruteur, détail
  et changement de statut.
- Payment, opportunités, vérifications et tentatives font des `findById` sans ownership.

## Matrice cible

| Ressource | Candidat/étudiant | Recruteur | Public |
|---|---|---|---|
| Job offers | lire liste/détail | CRUD de ses offres | liste/détail actifs |
| Applications | créer/lire les siennes | lire/changer celles de ses offres | aucun |
| Assessments | passer une évaluation assignée | CRUD des siennes | aucun |
| Attempts | créer/lire la sienne | lire celles de ses offres | aucun |
| Swipes/matches | agir/lire comme soi | agir/lire comme soi et pour ses offres | aucun |
| Opportunity offer | lire/confirmer/rejeter si destinataire | créer/lire si émetteur | aucun |
| Identity verification/payment | aucun write recruteur | créer/lire pour ses matches/offres | aucun |
| Fit score | lire si partie au processus | lire si propriétaire de l’offre | aucun |

## Périmètre

Contrat Recruitment validé, contrôleurs Recruitment, DTO de requête, use cases, ports repository,
adapters JPA et tests Recruitment. Toute nouvelle annotation de sécurité reste dans
`recruitment/api/security/`.

Hors périmètre : callbacks/OTP (plan 004), Identity, shared, front mobile, dépendances.

## Étapes

### 1. Créer les annotations locales

Créer `RecruiterOnly`, `CandidateOrStudentOnly` et, si utile, `Authenticated` sous
`recruitment/api/security`, avec `@PreAuthorize`. Les noms et expressions doivent suivre les
annotations Identity sans importer le package Identity.

**Vérifier** : test de réflexion listant toutes les méthodes et leurs rôles attendus.

### 2. Supprimer les identités contrôlées par le client

Retirer `recruiterId`, `swiperId`, `candidateId` de toute requête où ils représentent l’acteur
connecté. Les IDs de cible restent autorisés. Dans `/me`, supprimer les query params permettant
de remplacer le principal.

**Vérifier** : `rg -n "req\.(recruiterId|swiperId)|RequestParam.*(candidateId|recruiterId)" backend/src/main/java/com/zennyt/recruitment/api` ne retourne aucun override d’acteur.

### 3. Déplacer les contrôles de propriété dans les use cases

Chaque mutation charge la ressource, vérifie l’acteur et l’état, puis persiste dans la même
transaction. Utiliser `ForbiddenException` pour un acteur connu mais non propriétaire,
`NotFoundException` si la ressource n’existe pas, `ConflictException` pour transition métier.
Ne laisser aucune règle de propriété uniquement dans un contrôleur.

**Vérifier** : tests unitaires par use case : propriétaire accepté, autre acteur 403, ressource
absente 404, transition interdite 409/400 selon contrat validé.

### 4. Sécuriser toutes les lectures par ID

Ajouter le principal aux détails candidature/tentative/assessment/payment/opportunity/verification.
Retourner la donnée seulement si l’utilisateur est candidat concerné ou recruteur propriétaire de
l’offre/match associé.

**Vérifier** : matrice MockMvc avec deux candidats et deux recruteurs ; chaque accès croisé = 403/404.

### 5. Aligner OpenAPI, implémentations générées et documentation

Implémenter les interfaces générées lorsque le pattern du projet le permet, mettre à jour
`RECRUITMENT_MODULE.md`, son statut et son changelog sans réécrire l’historique.

**Vérifier** : `docker compose run --rm backend mvn -B test` → aucun échec sécurité, génération ou ArchUnit.

## Critères de fin

- [ ] Aucun endpoint Recruitment ne fait confiance à un actor ID fourni par le client.
- [ ] Toutes les opérations ont un rôle explicite et un test négatif.
- [ ] Toutes les ressources par ID ont une vérification d’ownership serveur.
- [ ] Les règles sont dans les use cases transactionnels, pas seulement dans les contrôleurs.
- [ ] Aucun import interne Identity n’existe dans Recruitment hors `identity.domain.event` prévu au plan 006.

## Conditions STOP

- Le contrat validé ne précise pas qui peut lire une ressource.
- Une vérification nécessite un appel direct à Identity.
- Le changement requiert une nouvelle dépendance ou une modification de migration existante.

