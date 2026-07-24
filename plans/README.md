# Plans de stabilisation Identity ↔ Recruitment

Générés avec le skill `improve` puis exécutés le 2026-07-14 à partir du commit
`2359b37`, dans un worktree contenant déjà des changements Recruitment non commités.
Les drift checks restent documentés dans chaque plan pour la traçabilité.

## Ordre d’exécution et statut

| Plan | Titre | Priorité | Effort | Dépend de | Statut |
|---|---|---:|---:|---|---|
| 001 | Figer les décisions, le contrat et la documentation | P1 | M | — | DONE |
| 002 | Corriger le socle HTTP et sécurité partagé | P1 | M | 001 + autorisation `shared/` | DONE |
| 003 | Verrouiller les rôles et la propriété dans Recruitment | P1 | L | 001, 002 | DONE |
| 004 | Sécuriser callbacks, OTP et transitions externes | P1 | L | 003 | DONE |
| 005 | Durcir Identity, CV et OCR | P1 | L | 001, 002 | DONE |
| 006 | Synchroniser l’état Identity vers Recruitment par événements | P1 | L | 003, 005 | DONE |
| 007 | Installer la couverture HTTP et les gates CI | P1 | L | 001–006 | DONE |
| 008 | Porter le domaine Engagement Conversations / Notifications / Push | P1 | M | validation + autorisation doc | DONE |
| 009 | Intégrer Engagement de bout en bout avec Auth, Recruitment et les 10 endpoints | P1 | L | 008 commitée + autorisations protégées | TODO |
| 010 | Corriger les findings de la revue Engagement avant production | P0 | L | intégration backend Engagement actuelle sauvegardée | DONE |

Valeurs de statut : `TODO`, `IN PROGRESS`, `DONE`, `BLOCKED`, `REJECTED`.

## Dépendances et portes de décision

- Le plan 001 doit être validé avant le code : plusieurs routes du contrat et du runtime
  se recouvrent sans porter les mêmes noms.
- Les plans 002 et 007 touchent `shared/`; l’autorisation explicite du référent est
  obligatoire selon `AGENTS.md` et `CONTRIBUTING.md`.
- La création de `RECRUITMENT_MODULE.md` doit être autorisée avant le premier changement
  Recruitment, car aucune documentation de module n’existe aujourd’hui.
- Le plan 004 doit connaître le canal OTP retenu. Recommandation : challenge local à durée
  courte, émission d’un Domain Event de livraison, aucun appel direct vers Identity ou
  Engagement.
- Ne jamais modifier `V13__recruitment_full_schema.sql`. Toute évolution DB commence à
  `V14__...` une fois V13 stabilisée.
- Le plan 008 est une nouvelle séquence Engagement indépendante des plans de stabilisation
  Identity ↔ Recruitment déjà terminés. Il exige l'autorisation de créer `ENGAGEMENT_MODULE.md`
  avant toute copie, puis reste strictement limité au domaine et à ses tests.
- Le plan 009 dépend du domaine du plan 008 et doit être exécuté en six PR : contrat, domaine,
  persistance, événements/auth, API/realtime, puis mobile. Le lot mobile reste bloqué tant que les
  maquettes Conversations/Messages ne sont pas présentes. Les modifications de contrat, `pom.xml`,
  Recruitment, migration, `core/`, `pubspec.yaml` et infra exigent les autorisations listées dans
  le plan.
- Le plan 010 remplace la phase de stabilisation backend post-intégration de 009. Il corrige les
  transactions inter-contextes, les sondages, la commande conversation, l'idempotence et le N+1.
  Le mobile reste hors périmètre et doit conserver un plan séparé.

## Politique contractuelle recommandée à valider

- Conserver une seule route paramétrable `GET /api/v1/job-offers` pour feed et recherche.
- Conserver les routes centrées sur l’acteur :
  `/candidates/me/applications`, `/candidates/me/matches`,
  `/recruiters/me/job-offers`, `/recruiters/me/matches`.
- Conserver `/assessment-attempts`, `/payments` et `/callbacks/integrity`.
- Retirer du contrat v1 les capacités encore absentes du runtime, ou les marquer dans la
  roadmap du module : génération IA d’évaluations, dashboard recruteur, recherche de
  candidats, liens partageables et résultats agrégés.
- Ne conserver aucun alias après migration, sauf exigence explicite d’un client déjà publié.
  Aucun appel Recruitment n’a été trouvé dans `mobile/lib` lors de l’audit.

## Baseline observée

- Runtime : 86 opérations Identity + Recruitment.
- Contrats : 93 opérations ; 18 contract-only et 11 runtime-only.
- Maven : 91 tests, 4 échecs.
- Recruitment : 13/13 tests unitaires verts, mais aucune couverture HTTP de sécurité.
- Identity : 18/21 tests verts ; trois attentes d’annotations sont obsolètes.
- ArchUnit : une violation Infrastructure → API dans `GroqCvParser`.

## Éléments considérés et non retenus

- Appel direct de Recruitment vers `identity.application` pour vérifier un utilisateur :
  rejeté, car contraire à l’ADR-001 et aux tests ArchUnit.
- Réutilisation des annotations `identity.api.security` dans Recruitment : rejetée, car elle
  créerait une dépendance interne entre bounded contexts.
- Modification de `pom.xml` pour ajouter une bibliothèque de test ou de détection MIME :
  rejetée à ce stade ; les dépendances Spring déjà présentes suffisent pour les plans.
