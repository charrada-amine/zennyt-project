# Plan 009 : Intégrer Engagement de bout en bout avec Auth, Recruitment et les 10 endpoints

> **Instructions exécuteur** : exécuter ce plan en six PR ordonnées. Ne jamais regrouper les six
> lots dans une seule PR. Lancer chaque gate avant de passer au lot suivant. Si une condition STOP
> survient, arrêter et faire valider la décision au lieu de copier le dépôt source tel quel.
>
> **Drift check initial** :
> `git diff --stat a52ecf0..HEAD -- contracts/engagement.openapi.yaml backend/pom.xml backend/src/main/java/com/zennyt/engagement backend/src/test/java/com/zennyt/engagement backend/src/main/java/com/zennyt/recruitment backend/src/test/java/com/zennyt/recruitment backend/src/main/resources/db/migration mobile/lib/features/notifications mobile/lib/features/engagement mobile/lib/core/router mobile/pubspec.yaml ENGAGEMENT_MODULE.md RECRUITMENT_MODULE.md`
>
> Le commit `a52ecf0` ne contient pas encore l'étape 1 Engagement, qui est présente comme fichiers
> non suivis dans le worktree au moment de la rédaction. Avant toute exécution, l'étape 1 doit être
> commitée et les changements Recruitment déjà présents doivent être identifiés. Vérifier aussi les
> SHA-256 consignés dans `plans/008-port-engagement-domain.md`. Si le domaine Engagement ou les
> événements Recruitment ont dérivé, STOP et rebaser le plan sur leur état réel.

## Statut

- **Priorité** : P1
- **Effort** : L — six PR, plusieurs jours
- **Risque** : HIGH — modèle conversationnel, sécurité objet, migration et temps réel
- **Dépend de** : plan 008 commitée et verte
- **Catégorie** : direction, sécurité, architecture, migration, tests, API
- **Planifié au** : commit `a52ecf0`, worktree post-plan-008, 2026-07-18
- **Branche observée** : `integration-recruitment-align`

## Autorisations obligatoires avant exécution

La validation générale de ce plan ne remplace pas les autorisations protégées de `AGENTS.md`.
Obtenir explicitement, dans le même message de validation :

1. l'autorisation de modifier `contracts/engagement.openapi.yaml` ;
2. l'autorisation d'ajouter l'exécution OpenAPI Engagement dans `backend/pom.xml` ;
3. l'autorisation de modifier les événements et use cases du module Recruitment ;
4. l'autorisation de créer la migration Flyway `V19__engagement_core.sql` ;
5. pour le lot mobile, l'autorisation de modifier `mobile/lib/core/router/**` et, si une dépendance
   temps réel/push est retenue, `mobile/pubspec.yaml` ;
6. pour le temps réel, la confirmation du fournisseur Azure et l'autorisation des changements
   `infra/` nécessaires.

Ne pas modifier `shared/` : les JWT sont déjà validés globalement et les erreurs partagées existent.
Ne pas modifier Identity : Engagement peut consommer l'événement existant
`UserAccessStateChangedEvent` et son snapshot de démarrage.

## Résultat attendu

Les dix opérations de `contracts/engagement.openapi.yaml` sont réellement implémentées, protégées
par JWT, contrôlées par participant/propriétaire, persistées dans PostgreSQL et consommées par le
mobile. Engagement ne lit jamais un repository ou un service interne de Recruitment/Identity.
L'intégration inter-contextes passe exclusivement par Domain Events.

```text
Identity --UserAccessStateChangedEvent--> Engagement actor projection
Recruitment --ApplicationSubmittedEvent--> Conversation candidat/recruteur
Recruitment --ApplicationStatusChangedEvent--> Notification candidat
Recruitment --MatchCreatedEvent--> Notification JOB_MATCH
Engagement --MessageSentEvent--> Notification NEW_MESSAGE + Azure SignalR
Mobile --JWT REST/SignalR--> Engagement
```

## État actuel confirmé

### Cible

- Le contrat cible expose **10 opérations**, toutes sous `bearerAuth`, et aucun contrôleur
  Engagement n'existe encore.
- Le domaine étape 1 contient `Conversation`, `Notification`, `PushDevice`, quatre enums et trois
  ports. Les 17 tests de caractérisation sont verts.
- `backend/pom.xml` génère Recruitment, Identity et Games, mais pas Engagement.
- La dernière migration est V18 ; aucun schéma/table Engagement n'existe dans la cible.
- `ApplicationSubmittedEvent` contient `applicationId`, `candidateId`, `jobOfferId`, mais pas le
  `recruiterId` nécessaire pour construire une conversation partagée.
- `ApplicationStatusChangedEvent` utilise les statuts cibles `PENDING`, `SHORTLISTED`, `APPROVED`,
  `REJECTED` ; le listener source attend d'autres statuts et ne peut pas être copié.
- Identity publie déjà `UserAccessStateChangedEvent(publicUserId, role, active)` et rejoue un
  snapshot au démarrage.
- Le mobile possède un `Dio` partagé avec refresh JWT, mais l'écran Notifications est un
  `PlaceholderScreen`; aucun écran Conversations/Messages ni maquette dédiée n'a été trouvé.

### Défauts du dépôt source à ne pas reproduire

- Les anciennes routes acceptent un `userId` fourni par le client. La cible doit utiliser
  exclusivement le `sub` du JWT.
- `MessagesController` force `MessageSenderRole.CANDIDATE`, même pour un recruteur.
- `MarkNotificationAsReadUseCase` charge une notification par ID sans vérifier son propriétaire.
- `Conversation` ne possède qu'un `userId` et un compteur non lu global : l'interlocuteur ne peut
  pas accéder correctement au même fil et chaque envoi augmente le mauvais compteur.
- `RecruitmentDirectory` est un stub de démonstration et son remplacement par un appel direct aux
  repositories Recruitment/Identity violerait l'ADR-001.
- `/realtime/negotiate` renvoie un objet vide et `/realtime/devices` ne persiste rien.
- La source appelle `event.jobId()` et des constantes Notification absentes de la cible.
- Les adaptateurs source réécrivent toute la collection de messages avec cascade JPA ; ils ne sont
  pas adaptés à un fil paginé et concurrent.

## Périmètre fonctionnel retenu

### Les 10 opérations à livrer

| # | Méthode et route | Accès | Contrôle métier |
|---:|---|---|---|
| 1 | `GET /conversations` | JWT C/STUDENT/R | Conversations où le `sub` est participant |
| 2 | `POST /conversations` | JWT C/STUDENT/R | Retourne/crée idempotemment la conversation de l'application si le `sub` est participant |
| 3 | `GET /conversations/{id}/messages` | JWT participant | Curseur + taille, plus récents d'abord |
| 4 | `POST /conversations/{id}/messages` | JWT participant | Expéditeur et rôle dérivés du JWT/projection |
| 5 | `POST /conversations/{id}/read` | JWT participant | Remet uniquement le compteur du lecteur à zéro |
| 6 | `GET /notifications` | JWT actif | Notifications du `sub` uniquement, paginées |
| 7 | `POST /notifications/{id}/read` | JWT propriétaire | IDOR impossible ; autre propriétaire renvoie 404 |
| 8 | `POST /notifications/read-all` | JWT actif | Met à jour uniquement les notifications du `sub` |
| 9 | `POST /realtime/negotiate` | JWT actif | Jeton Azure court, `nameid/sub` = acteur courant |
| 10 | `POST /realtime/devices` | JWT actif | Enregistrement/upsert du token pour le `sub`, réponse 201 |

### Hors périmètre

- Les 19 routes supplémentaires du contrat source : Posts, Comments, Calls, HelpChat,
  UserPostPreferences, Friendship et Media Upload.
- Un endpoint public de création de notification : les notifications sont créées par les use cases
  et listeners, jamais par un client.
- Un appel direct d'Engagement vers Recruitment ou Identity.
- Une modification de `shared/SecurityConfig` : `.anyRequest().authenticated()` protège déjà les
  nouvelles routes.
- Les événements `JobOpportunityOfferSent/Confirmed` et
  `VideoConferencePaymentConfirmed` tant qu'aucun type/endpoint cible ne les représente.
- `APPLICATION_VIEWED` et `PROFILE_VIEWED` restent disponibles dans l'enum, sans notification
  factice tant que les producteurs métier n'existent pas.

## Décisions contractuelles recommandées

Ces décisions sont à faire valider dans la PR contrat avant le code :

1. Le contrat cible à 10 opérations reste maître ; ne pas fusionner le contrat historique à 29.
2. Tous les identifiants Conversation/Message deviennent des UUID explicites (`format: uuid`).
3. Ajouter les `operationId` : `listConversations`, `createConversation`,
   `listConversationMessages`, `sendConversationMessage`, `markConversationRead`,
   `listNotifications`, `markNotificationRead`, `markAllNotificationsRead`,
   `negotiateRealtime`, `registerPushDevice`.
4. Remplacer les schémas inline par `ConversationPage`, `NotificationPage`,
   `ConversationCreateRequest` et `RealtimeConnection`.
5. `Notification.body` correspond au domaine ; supprimer le vocabulaire source `subtitle`,
   `contactName`, `contactInitials`, `chatId`. Conserver `actionUrl`.
6. Ajouter `counterpartId`, `counterpartRole` et `jobOfferId` à `Conversation` pour permettre au
   mobile de naviguer sans données en dur. Les noms/photos restent nullables jusqu'à un futur
   événement de profil Identity.
7. Déclarer les réponses communes 400/401/403/404/409 pertinentes et rendre obligatoires les
   propriétés réellement toujours renvoyées.
8. Conserver les cinq `NotificationType` exacts : `APPLICATION_VIEWED`,
   `APPLICATION_STATUS_CHANGED`, `NEW_MESSAGE`, `JOB_MATCH`, `PROFILE_VIEWED`.

## Commandes de référence

Le poste local ne possède pas `mvn`/`mvnw`; utiliser Java 21 via Docker :

| But | Command | Résultat attendu |
|---|---|---|
| Génération/compilation | `docker run --rm -v zennyt-maven-cache:/root/.m2 -v "$PWD":/workspace -w /workspace/backend maven:3.9.9-eclipse-temurin-21 mvn -DskipTests compile` | `BUILD SUCCESS` |
| Tests Engagement | même préfixe Docker puis `mvn -Dtest='com.zennyt.engagement.**' test` | tous verts |
| Architecture/routes | même préfixe puis `mvn -Dtest='ArchitectureTest,ApiContractRouteParityTest,EngagementSecurityAnnotationTest' test` | 3 ArchUnit + parité 10 + sécurité 10 verts |
| Suite backend | même préfixe puis `mvn test` | baseline 146 + nouveaux tests, 0 échec |
| Contrat | `npx @redocly/cli lint contracts/engagement.openapi.yaml` | 0 erreur bloquante |
| Mobile | `cd mobile && flutter analyze && flutter test` | 0 erreur, tous les tests verts |
| Diff | `git diff --check && git status --short` | aucun fichier hors lot |

Si `npx` ou Flutter nécessite une installation réseau indisponible, STOP et consigner le gate non
exécuté ; ne modifier aucune dépendance pour contourner le problème.

## Workflow Git anti-conflits

- Créer chaque branche depuis la branche d'intégration mise à jour :
  `feature/ENGAGEMENT-09a-contract`, puis `09b-domain`, `09c-persistence`, `09d-events`,
  `09e-api-realtime`, `09f-mobile`.
- Rebaser avant chaque nouvelle PR ; ne jamais travailler par-dessus les changements Recruitment
  non commités actuels.
- Une PR = un lot ci-dessous, idéalement moins de 300 lignes hors génération/migration/tests.
- Commits conventionnels, par exemple `feat(engagement): secure conversation endpoints`.
- Ne pas pousser ni ouvrir de PR sans instruction explicite.

## Lot A — Contrat et matrice de sécurité

### Fichiers autorisés

- `contracts/engagement.openapi.yaml`
- `ENGAGEMENT_MODULE.md`
- `plans/README.md` pour le statut uniquement

### Étapes

1. Appliquer les huit décisions contractuelles ci-dessus avant tout backend.
2. Ajouter dans `ENGAGEMENT_MODULE.md` la matrice des 10 routes, leurs rôles, leurs contrôles de
   propriété, les événements producteurs et les décisions temps réel encore ouvertes.
3. Incrémenter le contrat en `1.1.0` si les ajouts restent compatibles. Si un champ existant est
   supprimé ou rendu obligatoire pour un client déjà publié, STOP et décider `2.0.0` ou une phase
   de dépréciation.
4. Vérifier qu'aucun `userId`, `senderId`, `senderRole`, `candidateId` ou `recruiterId` contrôlé par
   l'acteur n'est accepté dans les requêtes.

**Gate A** : le linter OpenAPI est vert ; `rg -c '^    (get|post|put|patch|delete):$'` renvoie 10 ;
`rg -c '^      operationId:'` renvoie 10 ; aucun code Java n'est modifié dans cette PR.

## Lot B — Corriger le domaine et écrire les tests de caractérisation cible

### Fichiers autorisés

- `backend/src/main/java/com/zennyt/engagement/domain/**`
- `backend/src/test/java/com/zennyt/engagement/domain/**`
- `ENGAGEMENT_MODULE.md`

### Modèle cible

1. Refactorer `Conversation` autour de `candidateId`, `recruiterId`, `applicationId`, `jobOfferId`
   et `jobTitle`. Ajouter `isParticipant`, `roleOf`, `counterpartOf`,
   `unreadCountFor`, `markAsReadBy` et `recordMessage`.
2. Maintenir deux compteurs : candidat et recruteur. Un message incrémente uniquement le compteur
   de l'autre participant ; un message système incrémente les destinataires explicitement définis.
3. Extraire la persistance paginée des messages dans un nouveau port `MessageRepository` au lieu de
   charger/réécrire toute la collection depuis `Conversation`.
4. Aligner `Notification` sur `body` et `actionUrl`. La lecture exige le propriétaire dans le port :
   `findByIdAndUserId` ; ne conserver aucun `findById` utilisé par un endpoint acteur.
5. Étendre les ports Conversation/Notification avec page, taille, curseur et compte total. Garder
   les types de pagination Java purs dans Engagement, sans Spring Data dans `domain/`.
6. Faire de l'enregistrement Push un upsert explicite par token ; ajouter les recherches nécessaires
   au contrôle d'unicité et à la révocation future.
7. Ajouter `EngagementActor` et son port pour la projection Identity (`role`, `active`,
   `lastEventAt`, `lastEventId`).
8. Ajouter un port `ProcessedEventRepository.tryClaim(eventId, eventType, occurredAt)` afin que les
   listeners soient rejouables sans doublon.

### Tests minimum

- Conversation : les deux participants accèdent au fil ; un tiers est refusé ; rôle dérivé ;
  compteurs séparés ; lecture séparée ; message candidat/recruteur/système ; idempotence par
  application.
- Notification : mapping `body`, propriétaire, lecture idempotente et cinq types exacts.
- PushDevice : token requis, plateforme requise et règle d'upsert.
- EngagementActor : événement plus ancien/rejoué ignoré, désactivation appliquée.
- Aucun test Spring/JPA dans ce lot.

**Gate B** : tests domaine Engagement verts ; recherche Spring/JPA dans `engagement/domain` vide ;
3/3 ArchUnit verts. Ne pas commencer la persistance tant que les règles de compteurs ne sont pas
validées par ces tests.

## Lot C — Persistance PostgreSQL et cas d'usage

### Fichiers autorisés

- `backend/src/main/resources/db/migration/V19__engagement_core.sql` — création uniquement
- `backend/src/main/java/com/zennyt/engagement/infrastructure/persistence/**`
- `backend/src/main/java/com/zennyt/engagement/application/usecase/**`
- `backend/src/test/java/com/zennyt/engagement/application/**`
- `backend/src/test/java/com/zennyt/engagement/infrastructure/**`
- `ENGAGEMENT_MODULE.md`

### Migration V19

Créer le schéma `engagement` et les tables :

- `actors(public_user_id PK, role, active, last_event_at, last_event_id)` ;
- `conversations(id PK UUID, application_id UNIQUE, job_offer_id, candidate_id, recruiter_id,
  job_title, last_message_at, candidate_unread_count, recruiter_unread_count, version)` ;
- `messages(id PK UUID, conversation_id FK engagement.conversations, sender_id, sender_role,
  content, content_type, attachment_url, sent_at, read_at)` ;
- `notifications(id PK UUID, user_id, type, title, body, action_url, is_read, created_at)` ;
- `push_devices(id PK UUID, user_id, token UNIQUE, platform, device_name, updated_at)` ;
- `processed_events(event_id PK UUID, event_type, occurred_at, processed_at)`.

Ajouter les index de lecture : conversations par candidat/recruteur + `last_message_at`, messages
par conversation + `sent_at`, notifications par utilisateur + `is_read` + `created_at`, appareils
par utilisateur. Ne créer aucune FK vers les schémas Identity ou Recruitment.

### Adaptateurs et use cases

1. Créer des entités JPA séparées des modèles domaine. Utiliser `@Version` sur Conversation.
2. Implémenter les ports avec des requêtes bornées et ordonnées ; le curseur message doit être
   résolu dans la conversation courante, jamais globalement.
3. Implémenter les neuf use cases REST métier : liste/création conversation, liste/envoi/lecture
   messages, liste/lecture unitaire/lecture globale notifications, enregistrement appareil.
   `negotiateRealtime` reste un port dans ce lot.
4. Annoter les mutations `@Transactional` et les lectures `@Transactional(readOnly=true)`.
5. Utiliser `NotFoundException`, `ForbiddenException`, `ConflictException` et
   `BadRequestException` partagées ; ne pas exposer `IllegalArgumentException` brute au contrôleur.
6. L'envoi d'un message doit persister message + métadonnées conversation + notification
   `NEW_MESSAGE` dans une transaction Engagement unique, puis publier un événement Engagement
   interne pour le temps réel après commit.

### Tests minimum

- Chaque use case : succès candidat et recruteur, tiers/IDOR, ressource absente, bornes page/size.
- Deux envois concurrents ne perdent ni message ni compteur ; tester le conflit optimiste/retry
  borné si le pattern est ajouté.
- Lecture d'une notification étrangère = 404 et aucune mutation.
- `markAllAsRead` et enregistrement du même token sont idempotents.
- Mapping JPA aller-retour pour les quatre agrégats/projections.
- Flyway V1→V19 et `ddl-auto=validate` sur PostgreSQL 16.

**Gate C** : compilation + tests Engagement + Flyway/validate verts. `git diff` ne modifie aucune
migration V1–V18.

## Lot D — Intégration Identity/Recruitment par événements et sécurité active

### Fichiers autorisés

- `backend/src/main/java/com/zennyt/engagement/application/listener/**`
- `backend/src/main/java/com/zennyt/engagement/api/security/**`
- `backend/src/test/java/com/zennyt/engagement/application/**`
- `backend/src/test/java/com/zennyt/engagement/api/EngagementSecurityAnnotationTest.java`
- Les événements/use cases/tests Recruitment strictement nécessaires à l'enrichissement ci-dessous
- `RECRUITMENT_MODULE.md` et `ENGAGEMENT_MODULE.md`

### Événements Recruitment

1. Enrichir `ApplicationSubmittedEvent` avec `recruiterId` et un snapshot `jobTitle`. Pour éviter de
   faire porter à l'agrégat Application des données qu'il ne possède pas, publier l'événement
   enrichi dans `SubmitApplicationUseCase` après sauvegarde, à partir du `JobOffer` déjà chargé.
   Retirer l'ancien enregistrement incomplet de l'agrégat uniquement dans la même PR et adapter ses
   tests de non-régression.
2. Appliquer le même principe à `ApplicationStatusChangedEvent` dans
   `ChangeApplicationStatusUseCase`, en conservant `previousStatus/newStatus` et en ajoutant
   `recruiterId/jobTitle`.
3. Ne changer ni les machines à états ni les endpoints Recruitment.
4. Vérifier que chaque événement est publié une seule fois après persistance réussie et jamais si la
   transaction échoue.

### Listeners Engagement

1. `IdentityAccessStateListener` consomme l'événement Identity existant, conserve le plus récent et
   accepte le snapshot de démarrage. Aucun import d'un repository/service Identity.
2. `ApplicationSubmittedListener` utilise `tryClaim`, crée une conversation partagée idempotente par
   `applicationId` et ne crée pas de notification avec un type mensonger.
3. `ApplicationStatusChangedListener` crée `APPLICATION_STATUS_CHANGED` pour le candidat et peut
   ajouter un message système au fil. Mapper uniquement `SHORTLISTED`, `APPROVED`, `REJECTED`.
4. `MatchCreatedListener` crée `JOB_MATCH` pour les participants pertinents sans créer de conversation
   de candidature fictive.
5. Tous les listeners Recruitment après commit utilisent une nouvelle transaction Engagement ; le
   claim d'événement et les effets sont atomiques.

### Auth Engagement

Créer une annotation locale `@EngagementAuthenticated` basée sur
`@PreAuthorize("isAuthenticated() and @engagementActorPolicy.active(authentication.name)")`.
Les rôles viennent de la projection locale ; le `sub` vient du `Principal`. Ne pas importer les
annotations ou resolvers internes Identity/Recruitment.

### Tests minimum

- Événement Recruitment enrichi exact, publié une fois et après sauvegarde.
- Rejeu du même event : zéro conversation/notification supplémentaire.
- Événement plus ancien Identity ignoré ; acteur désactivé refusé malgré JWT valide.
- Status changed : destinataire/type/actionUrl corrects pour chaque statut cible.
- ArchUnit reste vert et aucune dépendance cross-context hors `domain.event` n'apparaît.

**Gate D** : tests Recruitment existants + nouveaux tests Engagement verts ; 3/3 ArchUnit verts ;
aucun `RecruitmentDirectory`/stub/appel direct inter-contextes ne subsiste.

## Lot E — Génération OpenAPI, contrôleurs REST et Azure SignalR

### Fichiers autorisés

- `backend/pom.xml` — ajouter uniquement l'exécution generator `engagement-api`, après autorisation
- `backend/src/main/java/com/zennyt/engagement/api/**`
- `backend/src/main/java/com/zennyt/engagement/infrastructure/realtime/**`
- `backend/src/main/java/com/zennyt/engagement/application/port/Realtime*.java`
- `backend/src/test/java/com/zennyt/engagement/api/**`
- `backend/src/test/java/com/zennyt/architecture/ApiContractRouteParityTest.java`
- `backend/src/main/resources/application.yml` pour configuration non secrète
- `ENGAGEMENT_MODULE.md`

### REST

1. Ajouter une exécution OpenAPI identique aux trois existantes avec packages
   `com.zennyt.engagement.api.generated` et `.generated.dto`.
2. Implémenter les interfaces générées avec quatre contrôleurs : Conversations, Messages,
   Notifications, Realtime. Ajouter `@EngagementAuthenticated` aux 10 méthodes.
3. Extraire `UUID actorId = UUID.fromString(principal.getName())`; ne jamais accepter d'identifiant
   d'acteur dans une requête.
4. Mapper page/meta, DTO, enums et 201/204 exactement comme le contrat.
5. Étendre `ApiContractRouteParityTest` avec les 10 routes Engagement et ajouter un test qui exige
   une annotation de sécurité sur chacune.
6. Ajouter des tests HTTP avec JWT : 401 sans JWT, 403 acteur inactif, 200/201/204 succès, 404 IDOR,
   validation 400 et rôles candidat/recruteur.

### Temps réel recommandé

Conserver Azure SignalR, car le contrat et `package-info.java` le promettent. Ne pas copier le STOMP
source. Utiliser un port `RealtimeNegotiationPort` et un port `RealtimePublisher` afin de tester le
métier sans Azure.

- `/realtime/negotiate` génère une URL et un jeton courts liés au `sub` courant (`nameid`) ; aucune
  connection string ni access key ne sort du backend.
- L'adaptateur Azure publie après commit les messages et mises à jour aux deux participants.
- Si Azure SignalR n'est pas configuré, retourner 503 explicite ; ne jamais renvoyer `{url:null,
  accessToken:null}`.
- Privilégier Managed Identity/RBAC. Si l'équipe choisit temporairement une access key, la stocker
  dans Key Vault/App Service, jamais dans Git, et prévoir rotation.
- Référence officielle :
  `https://learn.microsoft.com/azure/azure-signalr/signalr-concept-client-negotiation` et
  `https://learn.microsoft.com/azure/azure-signalr/signalr-reference-data-plane-rest-api`.

La documentation Microsoft confirme que le serveur de négociation doit renvoyer `url` +
`accessToken`, que le client se connecte ensuite directement au service et que le `nameid` identifie
l'utilisateur pour les envois ciblés. Si la ressource choisie est Azure Web PubSub et non SignalR,
STOP : modifier d'abord le contrat et la terminologie au lieu de masquer ce changement.

**Gate E** : 10/10 routes runtime = contrat ; 10/10 protégées ; tests HTTP/IDOR verts ; configuration
absente = 503 ; aucun secret dans le diff/log ; suite backend complète verte.

## Lot F — Mobile : brancher réellement les endpoints

### Prérequis bloquants

Le dépôt ne contient pas de maquettes Conversations/Messages et l'écran Notifications est un
placeholder. Obtenir les maquettes et le flow validé avant tout widget. Sans maquettes, ce lot reste
`BLOCKED` ; ne pas inventer d'écran, couleur, icône ou asset.

Confirmer également le SDK Flutter compatible avec le fournisseur temps réel retenu. Toute nouvelle
dépendance `pubspec.yaml` exige une autorisation séparée.

### Fichiers prévus

- créer `mobile/lib/features/engagement/domain/**`
- créer `mobile/lib/features/engagement/data/**`
- créer `mobile/lib/features/engagement/presentation/**` après maquettes
- remplacer `mobile/lib/features/notifications/presentation/view/notifications_screen.dart`
- modifier `mobile/lib/core/router/**` seulement après autorisation
- tests sous `mobile/test/features/engagement/**`

### Étapes

1. Créer les DTO/modèles/repositories REST en réutilisant `dioProvider` et
   `ApiException.fromDio`; aucun second client HTTP ni stockage JWT.
2. Brancher pagination/curseur, états loading/empty/error/retry et lecture optimiste avec rollback.
3. Remplacer le placeholder Notifications et ajouter liste conversations + fil messages selon les
   maquettes. Supprimer le placeholder devenu mort dans la même PR.
4. Appeler réellement les 8 opérations UI : liste/création conversation, messages, lecture,
   notifications. Brancher `registerPushDevice` au cycle d'auth/session et non au rendu d'un écran.
5. Négocier le temps réel avec le JWT Zennyt, ouvrir la connexion Azure, reconnecter avec backoff,
   dédupliquer par `message.id` et retomber sur refresh REST après reconnexion.
6. Mapper `actionUrl` uniquement vers une allow-list de routes internes ; ne jamais passer une URL
   notification arbitraire directement au routeur.
7. Ajouter tests repository, provider/viewmodel, widget et déconnexion/reconnexion.

**Gate F** : `flutter analyze` et `flutter test` verts ; recherche `PlaceholderScreen` dans
Notifications vide ; chaque endpoint Engagement a au moins un appel mobile ou une justification
documentée (les lectures `read` et l'enregistrement device inclus).

## Plan de tests de bout en bout

1. Inscrire/charger un candidat et un recruteur actifs ; vérifier JWT absent/invalide/inactif.
2. Soumettre une candidature : une seule conversation partagée apparaît pour les deux acteurs.
3. Le candidat et le recruteur envoient chacun un message ; le rôle serveur est correct et le tiers
   reçoit 404.
4. Chaque participant voit uniquement son compteur non lu et le remet à zéro sans affecter l'autre.
5. Changer PENDING→SHORTLISTED→APPROVED ou REJECTED : notifications exactes, aucun doublon au rejeu.
6. Créer un match : `JOB_MATCH` aux destinataires attendus.
7. Marquer une notification propre/étrangère ; l'étrangère reste inchangée.
8. Enregistrer deux fois le même token push ; résultat idempotent et associé au JWT courant.
9. Négocier SignalR : jeton lié au bon utilisateur, expiration courte, message ciblé reçu une fois.
10. Désactiver l'utilisateur via Identity event : les appels suivants sont 403 même si le JWT n'est
    pas encore expiré.

## Critères DONE globaux

- [ ] Le contrat comporte exactement 10 opérations et 10 `operationId`.
- [ ] 10/10 routes runtime sont égales au contrat et protégées.
- [ ] Aucun identifiant acteur ne vient du client ; `sub` JWT est la seule identité agissante.
- [ ] Toutes les lectures/mutations vérifient participant ou propriétaire.
- [ ] Aucun appel direct entre bounded contexts ; seuls les packages `domain.event` sont importés.
- [ ] V19 est la seule nouvelle migration et V1–V18 sont inchangées.
- [ ] Rejeu d'événements sans doublons ; effets après commit testés.
- [ ] Azure absent retourne 503, configuré renvoie un vrai jeton et publie aux bons utilisateurs.
- [ ] Backend complet, ArchUnit, contrat, Flutter analyze/tests sont verts.
- [ ] Mobile n'affiche plus de données placeholder pour Engagement.
- [ ] `ENGAGEMENT_MODULE.md` et `RECRUITMENT_MODULE.md` ont statut, arborescence, décisions,
  roadmap, changelog numéroté et date mis à jour sans réécrire l'historique.
- [ ] Aucune modification Identity, Shared ou fonctionnalité source hors contrat.

## Conditions STOP

Arrêter et demander avant de poursuivre si :

- l'étape 1 Engagement ou les changements Recruitment ne sont pas commités/rebasés ;
- l'une des six autorisations protégées manque ;
- l'équipe veut aussi les 19 endpoints Posts/Calls/HelpChat historiques ; cela exige un nouveau plan
  contract-first et des maquettes ;
- un client publié dépend déjà des schémas Engagement 1.0 et rend le changement cassant ;
- la conversation doit exister sans candidature ni match : une nouvelle règle produit est requise ;
- le fournisseur réel est Web PubSub/STOMP plutôt qu'Azure SignalR ;
- les maquettes mobile Conversations/Messages/Notifications manquent ;
- la correction nécessite un appel direct vers un repository Identity/Recruitment ;
- une migration V1–V18 devrait être modifiée ; créer une nouvelle migration à la place ;
- un gate échoue deux fois après une correction raisonnable.

## Notes de maintenance et revue

- Scruter particulièrement les IDOR, l'origine du rôle expéditeur, les compteurs séparés, la
  concurrence d'envoi, l'idempotence des listeners et l'absence de secret SignalR dans les logs.
- Un futur événement profil Identity pourra enrichir `counterpartName/photoUrl` via projection locale
  sans changer les endpoints ni appeler Identity.
- Les opportunités, paiements vidéo, Calls, Posts et HelpChat doivent rester des plans distincts :
  ils nécessitent types de notification, contrats, migrations et maquettes propres.
- Si Engagement devient un service séparé, remplacer les listeners in-process par Service Bus et
  conserver `processed_events` comme inbox transactionnelle.
