# Module Engagement

**Dernière mise à jour :** 2026-07-18 — stabilisation concurrence, événements et feed.

## Périmètre

Le bounded context `engagement` couvre le fil social (posts, médias, sondages, likes,
commentaires et préférences), les conversations candidat/recruteur, les notifications,
les appareils push, la signalisation d'appels audio/vidéo, le centre d'aide et l'upload média.
Cette livraison est backend uniquement : aucun fichier mobile ni `shared` n'est modifié.

Le contrat de référence est `contracts/engagement.openapi.yaml` v2.0.0. Ses 30 opérations
sont toutes exposées sous `/api/v1`, utilisent le `sub` du JWT comme acteur et sont protégées
par la projection locale `engagement.actors`.

## Architecture

```text
engagement/
├── api/                  # 8 contrôleurs, DTO, sécurité locale
├── application/
│   ├── listener/         # événements Recruitment
│   ├── port/             # média, realtime, négociation
│   └── usecase/          # règles d'accès et orchestration
├── domain/
│   ├── model/            # Java pur
│   ├── repository/       # ports
│   └── vo/
└── infrastructure/
    ├── persistence/      # JPA/PostgreSQL
    ├── realtime/         # STOMP/WebSocket
    └── storage/          # Cloudinary
```

Le domaine reste strictement Java pur. Les liens inter-contextes sont uniquement des Domain
Events : `UserAccessStateChangedEvent`, `ApplicationSubmittedEvent` et
`ApplicationStatusChangedEvent`. Engagement n'appelle ni Identity ni Recruitment.

## Contrat et modèle

- `NotificationType` : `APPLICATION_VIEWED`, `APPLICATION_STATUS_CHANGED`, `NEW_MESSAGE`,
  `JOB_MATCH`, `PROFILE_VIEWED`, `NEW_COMMENT`, `NEW_LIKE`.
- Une conversation est unique par candidature et contient exactement un candidat et un
  recruteur. L'événement de soumission enrichi fournit l'offre, le recruteur et le titre.
- Les noms/photos affichés proviennent de la projection Identity, mise à jour après changement
  de nom, avatar, rôle ou état du compte.
- `PUBLIC` est visible par tout acteur autorisé ; `FRIENDS` par l'auteur et ses amis. Les posts
  masqués et auteurs bloqués sont filtrés côté repository et côté accès direct.
- Un utilisateur ne peut liker qu'une fois et voter qu'une fois par sondage. Le serveur calcule
  compteurs et identité des auteurs.
- Les appels exigent l'appartenance à la conversation. Seul le destinataire peut rejoindre ;
  chaque participant peut terminer.

## Endpoints

| Groupe | Opérations | État |
|---|---:|---|
| Posts, likes, commentaires, sondages | 9 | Opérationnel |
| Préférences, masquer, bloquer | 4 | Opérationnel |
| Conversations et messages | 5 | Opérationnel |
| Notifications | 3 | Opérationnel |
| Realtime et appareils push | 2 | STOMP local + enregistrement opérationnels |
| Appels | 3 | Signalisation WebRTC via STOMP |
| Centre d'aide | 3 | Opérationnel |
| Média | 1 | Cloudinary, clés requises pour un upload réel |

`POST /realtime/negotiate` renvoie `/ws-engagement`; le client réutilise son bearer token lors
de l'upgrade HTTP. Les destinations utilisateur sont `/user/queue/call/invite`,
`/user/queue/call/accept` et `/user/queue/call/end`.

## Persistance

- V19 : `actors`, `conversations`, `messages`, `notifications`, `push_devices`.
- V20 : posts/médias/sondages/likes/votes/commentaires, préférences, amitiés, appels et aide.
- V22 : projection candidature et idempotence de consommation par `event_id`.
- V23 : file locale durable de retry des événements Recruitment échoués.
- Aucun FK inter-schéma ; identités étrangères conservées comme UUID de projection.
- Verrous optimistes sur les agrégats mutables et index sur les feeds/listes.
- Les enfants de sondage ne sont pas supprimés lors d'une sauvegarde, afin de préserver les votes.

## Sécurité

Chaque endpoint porte `@EngagementAuthenticated`. L'acteur doit exister dans la projection,
être actif et avoir le rôle `CANDIDATE`, `STUDENT` ou `RECRUITER`. Les identifiants `userId`,
`authorId` agissant, `senderId` et `senderRole` ne sont jamais acceptés depuis le client.

## Vérification

- Compilation Java 21 : succès.
- Suite backend : 201 tests, 0 échec, 0 erreur, 0 ignoré, PostgreSQL inclus.
- ArchUnit : 3/3 verts (`domainIsFrameworkAgnostic`, `domainDoesNotDependOnOuterLayers`,
  `boundedContextsDoNotDependOnEachOthersInternals`).
- Parité : 30 routes runtime = 30 opérations OpenAPI, toutes protégées.
- PostgreSQL 16 : 23 migrations validées/appliquées ; Hibernate `ddl-auto=validate` vert.
- Démarrage Spring : succès, 40 repositories JPA et broker STOMP actifs.
- Smoke authentifié : posts, votes, likes, commentaires, préférences, aide, conversations,
  messages, notifications, devices, realtime et appels retournent les statuts attendus.
- Upload : validation locale testée ; succès distant conditionné aux identifiants Cloudinary.

## Zones protégées

- Domaine sans Spring/JPA.
- Isolation par événements, sans appel interne Identity/Recruitment.
- Contrat-first et identité agissante issue du JWT.
- Aucun écran ou fichier mobile ajouté.
- Aucun fichier `shared` modifié.

## Décisions à valider / roadmap

1. Choisir et configurer le fournisseur de livraison push FCM/APNs ; l'enregistrement des tokens
   est prêt mais aucune livraison externe n'est simulée.
2. Définir l'événement/source d'amitié qui alimentera `engagement.friendships`; la visibilité
   `FRIENDS` est implémentée mais la création d'amitié n'est pas une opération du contrat v2.
3. Définir le traitement agent du centre d'aide ; les messages utilisateurs sont persistés,
   sans réponse automatique inventée.
4. Intégrer le pack mobile dans une livraison séparée.
5. **Pagination des commentaires — reportée (décision Lot D).** `GET /posts/{id}/comments`
   retourne aujourd'hui un tableau consommé par un client mobile déjà publié. Passer à une
   réponse paginée est un changement de contrat cassant : il doit être fait contract-first et
   coordonné avec le mobile. La lecture reste bornée par la pagination du feed en amont ; ce
   point est suivi séparément plutôt que modifié ici sans contrat.
6. **Durabilité des événements.** Les échecs de consommation Recruitment sont persistés dans
   `pending_application_events` et rejoués avec backoff borné ; `processed_events` conserve
   l'idempotence. Un outbox côté producteur reste recommandé avant toute séparation en
   microservices ou pour couvrir une indisponibilité totale de la base Engagement. Le worker est
   actuellement dimensionné mono-instance ; en scale-out, l'idempotence évite les doublons
   métier mais un mécanisme de lease/`SKIP LOCKED` évitera le travail de retry redondant.

## Correctifs revue (Lot A→D, 2026-07-18)

- **Lot A — Isolation transactionnelle.** Les projections d'accès Identity (Engagement et
  Recruitment) passent par un callback `AFTER_COMMIT` qui capture les erreurs et délègue à un
  projector `REQUIRES_NEW` : une panne ne rollback pas Identity et ne transforme pas une réponse
  réussie en 500 ; le snapshot hors transaction reste supporté.
- **Lot B — Sondages corrects et atomiques.** Read model `PostView` (données dépendantes de
  l'acteur hors agrégat) : `selectedByMe` reflète le vote réel. Le vote devient une réservation
  atomique `INSERT ... ON CONFLICT (post_id,user_id) DO NOTHING` ; second vote concurrent =
  409 déterministe. L'update natif vide le contexte JPA pour retourner immédiatement le compteur
  frais (vérifié en concurrence sur PostgreSQL 16).
- **Lot C — Conversation idempotente.** `POST /conversations` accepte un DTO validé
  `ConversationCreateRequest(@NotNull applicationId)` et répond 201 (créée) ou 200 (préexistante)
  conformément au contrat. La création utilise `ON CONFLICT (application_id) DO NOTHING`, sans
  dépendre d'une exception tardive au commit. Projection locale `application_projections` alimentée par
  `ApplicationSubmittedEvent` et table `processed_events` (V22) : un `eventId` rejoué est un
  no-op complet. V23 conserve et rejoue les projections échouées.
- **Lot D — Feed borné.** Suppression du chargement de tous les likers (`findLikedUserIds`) au
  profit d'un agrégat `count(*)` + `bool_or(actor)` et de chargements par lots d'IDs
  (`WHERE post_id IN (...)`). Les auteurs sont aussi résolus en un batch unique avant mapping :
  nombre de requêtes constant, indépendant du nombre de posts.

## Changelog

1. **2026-07-18 — Étape 1 :** portage Java pur de Conversations / Notifications / Push et
   vocabulaire `NotificationType` contract-first.
2. **2026-07-18 — Backend autonome :** use cases, sécurité locale, JPA/Flyway V19 et 9 premières
   routes protégées.
3. **2026-07-18 — Intégration v2 complète :** contrat porté à 30 opérations, domaines social,
   appels et aide, V20, STOMP, Cloudinary, événements Recruitment/Identity enrichis, création
   idempotente des conversations et vérification complète Java/PostgreSQL.
4. **2026-07-18 — Correctifs revue (Lot A→D) :** isolation transactionnelle des projections
   (AFTER_COMMIT/REQUIRES_NEW), sondages atomiques + `selectedByMe` réel, `POST /conversations`
   validé/idempotent (200/201) avec projection + `processed_events` (V22), feed borné sans
   chargement des likers. 188 tests, ArchUnit 3/3, Flyway V1→V22 vérifié sur PostgreSQL 16.
5. **2026-07-18 — Stabilisation post-revue :** contrat conversation aligné sur 200/201,
   création concurrente atomique, compteur de vote rafraîchi, auteurs du feed batchés, callbacks
   `AFTER_COMMIT` non propagés et retry local durable V23. 201 tests verts, dont concurrence
   réelle PostgreSQL, Flyway V1→V23 et `ddl-auto=validate`.
6. **2026-07-18 — Revue Claude finale :** verdict GO sans finding P0/P1 ; réserve PostgreSQL
   confirmée par 4 tests conditionnels exécutés, et limite multi-instance du worker tracée dans
   la roadmap.
