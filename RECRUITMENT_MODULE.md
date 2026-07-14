# Module Recruitment

**Dernière mise à jour :** 2026-07-14

## Périmètre

Le bounded context `recruitment` gère les offres, swipes, matchs, évaluations,
tentatives, candidatures, scores de compatibilité, offres d'opportunité,
vérifications d'identité et paiements de visioconférence. Son contrat public est
`contracts/recruitment.openapi.yaml` et expose 40 opérations sous `/api/v1`.

## Architecture

- `api/` : contrôleurs REST, DTO et annotations locales de sécurité.
- `application/` : cas d'usage, projection des états d'accès Identity et OTP.
- `domain/` : modèles, événements, value objects et ports de persistance Java purs.
- `infrastructure/` : adaptateurs JPA, vérification du secret callback et données de développement.
- `V13__recruitment_full_schema.sql` : schéma fonctionnel initial, immuable.
- `V14__recruitment_actor_projection.sql` : projection locale des rôles et états Identity.
- `V15__recruitment_otp_challenges.sql` : challenges OTP hashés et expirants.

## Sécurité et propriété

- Les acteurs sont toujours dérivés du JWT ; les requêtes ne choisissent jamais le
  recruteur, candidat ou swiper agissant.
- Les annotations `RecruiterOnly`, `CandidateOrStudentOnly` et `Authenticated`
  vérifient le rôle JWT ainsi que la projection locale active issue d'Identity.
- Chaque lecture ou mutation privée vérifie la propriété de l'offre, candidature,
  tentative, swipe, match, paiement, vérification ou offre d'opportunité.
- Seuls la recherche et le détail des offres sont publics. Les trois callbacks sont
  `permitAll` au niveau HTTP mais exigent `X-Callback-Secret`, comparé en temps constant.
- Le détail public d'une offre retourne uniquement une offre `ACTIVE`; les brouillons,
  offres masquées et clôturées répondent `404`.
- Un callback répété avec le même résultat est idempotent ; un résultat contradictoire
  retourne `409 Conflict`.

## Intégration Identity

Identity publie `identity.user.access-state-changed.v1` après inscription,
authentification, changement de rôle, désactivation et suppression. Recruitment
maintient une projection minimale (`publicUserId`, rôle, actif), sans PII et sans
appel direct à un autre module. Un snapshot au démarrage initialise les comptes
préexistants. Les événements anciens ou rejoués sont ignorés.

## OTP

Les OTP ont six chiffres, sont stockés sous forme de hash SHA-256 salé, expirent après
la durée configurée et ont un nombre d'essais limité. Ils sont à usage unique.
`recruitment.otp.requested.v1` transporte le code uniquement de façon éphémère vers
un futur consommateur de livraison ; aucun code clair n'est persisté.

## Contrat et routes canoniques

- Offres : `/job-offers`, `/recruiters/me/job-offers`.
- Candidatures et matchs : `/candidates/me/applications`,
  `/candidates/me/matches`, `/recruiters/me/matches`.
- Évaluations : `/assessments`, `/assessment-attempts`.
- Intégrations : `/callbacks/integrity`, `/callbacks/identity-verification`,
  `/callbacks/fit-score`.
- Paiements et opportunités : `/payments`, `/job-opportunity-offers`.

Les anciennes promesses sans runtime (génération IA d'évaluations, dashboard,
recherche de candidats, liens partageables et résultats agrégés) ne figurent plus
dans le contrat v1.

## Zones protégées

- Calcul du score d'évaluation côté serveur uniquement.
- Création d'un match uniquement après deux `LIKE` opposés sur la même paire
  candidat/offre.
- Transitions de statuts des offres, candidatures, opportunités et paiements.
- Migrations Flyway existantes, en particulier `V13`.
- Absence de dépendance directe vers les couches internes d'Identity.

## Décisions à valider

- Le canal de livraison effectif de `OtpRequestedEvent` (SMS, e-mail ou fournisseur
  externe) reste à brancher dans le module responsable de la communication.
- Le paiement actuel enregistre uniquement le résumé de carte (`last4`, type) et ne
  contacte pas encore un PSP ; le choix du fournisseur reste une décision produit.
- Le mobile n'appelle actuellement aucun endpoint Recruitment. Son intégration doit
  être planifiée avant de considérer les parcours Recruitment disponibles aux clients.
- Une vue candidat expurgée des réponses correctes est nécessaire avant d'exposer les
  questions d'une évaluation dans le mobile.

## Tests et garde-fous

- Parité automatique entre les routes runtime et les deux contrats OpenAPI.
- Vérification que les 40 opérations Recruitment sont protégées ou explicitement publiques.
- Tests de propriété des swipes, états métier, OTP, callbacks et projection Identity.
- ArchUnit interdit les dépendances de couches et de modules non autorisées.

## Roadmap

1. Brancher un consommateur sécurisé de `OtpRequestedEvent` avec rate limiting.
2. Ajouter les écrans et repositories mobile Recruitment à partir du contrat généré.
3. Exposer une projection d'évaluation candidat sans `correctOptionIndex`.
4. Intégrer le PSP et remplacer le paiement simulé.
5. Réintroduire les fonctions différées uniquement en contract-first.

## Changelog

1. 2026-07-14 — Création de la documentation du module ; contrat aligné sur les 40
   routes runtime ; sécurité par rôle/propriété, projection Identity, callbacks signés
   et OTP persistants ajoutés ; couverture de contrat et de sécurité installée. La revue
   `claude -p` a ensuite verrouillé le détail public aux seules offres actives.
