# Module Engagement

**Dernière mise à jour :** 2026-08-07 — appels : l'appel sortant initie réellement la session serveur (REST `POST /calls/start`), l'overlay d'appel entrant s'affiche chez le destinataire ; enregistrement : chunks mp4 écrits sur disque (`call_recordings/`), fini le `MediaRecorder` `-5`, et suppression de la reconfiguration audio (`audioProfileMusicHighQualityStereo` + game streaming) qui coupait le son dans l'appel et dans l'enregistrement.

## Périmètre

Le bounded context `engagement` couvre le fil social (posts, médias, sondages, likes,
commentaires et préférences), les conversations candidat/recruteur (temps réel inclus), les
notifications, les appareils push, la signalisation d'appels audio/vidéo, le centre d'aide et
l'upload média. Le backend est complet ; le chat mobile (conversations, messages, temps réel)
est intégré.

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
| Conversations et messages | 5 | Opérationnel (+ push temps réel) |
| Notifications | 3 | Opérationnel |
| Realtime et appareils push | 2 | Handshake JWT sécurisé, push messages opérationnels |
| Appels | 3 | Session REST (start/join/end) + signalisation WebRTC via STOMP |
| Centre d'aide | 3 | Opérationnel |
| Média | 1 | Cloudinary, clés requises pour un upload réel |

`POST /realtime/negotiate` renvoie `/ws-engagement`; le client réutilise son bearer token lors
de l'upgrade HTTP. L'handshake valide le JWT (`JwtHandshakeInterceptor`) et installe un principal
STOMP (`JwtPrincipalHandshakeHandler`) pour le routage `/user/queue/**`. À chaque message
enregistré, `SendMessageUseCase` pousse le payload (schéma `Message`) vers le destinataire sur
`/user/queue/messages` ; l'historique reste récupéré en HTTP. Les destinations utilisateur
supplémentaires sont `/user/queue/call/invite`, `/user/queue/call/accept` et `/user/queue/call/end`.

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
- Suite backend : 204 tests, 0 échec, 0 erreur, 0 ignoré, PostgreSQL inclus.
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
- Handshake WebSocket : le JWT est obligatoire et validé (aucune route temps réel non authentifiée).
- Attribution des bulles pilotée par le serveur (`Conversation.myRole`), jamais devinée côté client.
- Aucun fichier `shared` modifié.

## Décisions à valider / roadmap

1. Choisir et configurer le fournisseur de livraison push FCM/APNs ; l'enregistrement des tokens
   est prêt mais aucune livraison externe n'est simulée.
2. Définir l'événement/source d'amitié qui alimentera `engagement.friendships`; la visibilité
   `FRIENDS` est implémentée mais la création d'amitié n'est pas une opération du contrat v2.
3. Définir le traitement agent du centre d'aide ; les messages utilisateurs sont persistés,
   sans réponse automatique inventée.
4. **Pack mobile engagement (en cours).** Le chat (messages, conversations, notifications,
   temps réel WebSocket) et le câblage des appels (session REST start/join/end, overlay d'appel
   entrant) sont intégrés côté mobile. Reste à intégrer : posts/likes/commentaires, sondages, aide.
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
7. **2026-08-04 — Chat temps réel sécurisé + attribution correcte des bulles :** handshake
   STOMP validant le JWT (`JwtHandshakeInterceptor` + `JwtPrincipalHandshakeHandler`, aucun
   endpoint temps réel non authentifié), poussée de chaque message au destinataire sur
   `/user/queue/messages` depuis `SendMessageUseCase`, et `Conversation.myRole` ajouté au
   contrat (enum `CANDIDATE`/`RECRUITER`) et à la réponse `GET /conversations`. Mobile :
   `myRole` parsé, `MessageBubble` aligné sur le rôle serveur (fini le bug "le destinataire voit
   ses messages comme les siens"), messages temps réel insérés directement dans la conversation
   ouverte (`ConversationMessagesNotifier` + `realtimeMessageStreamProvider`) sans refetch,
   liste de conversations et notifications rafraîchies à la réception. 204 tests backend, 27
   tests mobile, ArchUnit 3/3, `flutter analyze` sans erreur.
8. **2026-08-04 — Handshake WebSocket mobile authentifié par défaut :** le singleton
   `WebSocketService.connect` relit le bearer token depuis le stockage sécurisé
   (`defaultTokenStorage` dans `mobile/lib/core/storage/token_storage.dart`) quand `authToken`
   est absent, et l'envoie en `Authorization: Bearer <JWT>` lors de l'upgrade STOMP. Corrige les
   connexions de la page de test (`messaging_test_page.dart`) et de l'appel vidéo hérité
   (`video_call_page_old.dart`) qui n'en passaient pas : le serveur rejetait le handshake en 401
   (cf. `JwtHandshakeInterceptor`), provoquant une boucle de reconnexion toutes les 5 s.
9. **2026-08-04 — Invalidation inter-comptes du cache utilisateur :** `currentUserProvider`
   (`mobile/lib/features/home/presentation/providers/home_providers.dart`) écoute désormais
   `authControllerProvider` et renvoie `CurrentUser.empty()` quand la session est déconnectée.
   Comme `conversationsProvider` et `notificationsProvider` dérivent tous deux de
   `currentUserProvider.future`, la liste des conversations et les notifications sont
   reconstruites au login/logout/switch de compte au lieu de conserver le cache du compte
   précédent (bug : après un switch de compte, les conversations de l'ancien compte restaient
   affichées jusqu'à un rechargement manuel).
10. **2026-08-07 — Appels : l'overlay d'appel entrant s'affiche enfin chez le destinataire.** Le
    bouton d'appel de la page chat envoyait une invitation STOMP `/app/call/{conversationId}/invite`
    sans handler côté backend (aucun `@MessageMapping`) : le serveur ne créait jamais la session
    d'appel et ne poussait donc jamais l'invitation au correspondant. L'appel sortant passe
    désormais par `POST /api/v1/calls/start` (`InitiateCallUseCase`, qui pousse
    `/user/queue/call/invite`), l'acceptation entrante par `POST /api/v1/calls/{callId}/join`
    (`JoinCallUseCase`, qui pousse `/user/queue/call/accept`) et la fin d'appel par
    `POST /api/v1/calls/{callId}/end` (`EndCallUseCase`, qui pousse `/user/queue/call/end`).
    Correction aussi de `CallSignalingRepositoryImpl.dispose()` qui retirait le listener global
    `call/invite` de l'overlay (après le premier appel, plus aucune invitation ne pouvait
    s'afficher) ; l'overlay se ré-enregistre en outre sur `call/end`/`call/reject` à chaque
    nouvelle invitation. Fichiers mobile : `call_page_controller.dart`,
    `call_signaling_repository_impl.dart`, `incoming_call_overlay.dart`. 27 tests mobile verts,
    `flutter analyze` sans nouvelle erreur ni nouveau warning.
11. **2026-08-07 — Enregistrement d'appel : les chunks mp4 sont enfin écrits sur disque.**
    `CallRecordingService` appelait `MediaRecorder.stopRecording()` avant tout
    `startRecording()` (le premier `startRecording` n'avait lieu qu'à la 1ʳᵉ expiration du timer,
    *après* un stop) : Agora renvoyait `-5 (ERR_REFUSED)`, l'exception interrompait le chunk et
    **aucun fichier n'était jamais produit**. Le service démarre désormais le premier chunk
    immédiatement dans `startRecording()` ; le timer 10 s ferme le chunk courant
    (`stopRecording()` → flush mp4 → `saveChunk`) puis en ouvre un nouveau (`_startNewChunk()`),
    et `stopRecording()` final clôt le dernier chunk avant `destroyMediaRecorder`. `maxDurationMs`
    porté de 10 000 à 60 000 ms (filet de sécurité : l'arrêt manuel gagne toujours la course).
    Fichier : `call_recording_service.dart`. 27 tests mobile verts, `flutter analyze` sans
    nouvelle erreur ni nouveau warning.
12. **2026-08-07 — Enregistrement : logs de diagnostic + démarrage robuste.** Aucune ligne de log
    ne mentionnait l'enregistrement, impossible de savoir s'il démarrait. Ajout de logs explicites
    dans `call_page_controller` (`✅ Joined Agora channel`, `👥 Remote user joined`,
    `_startRecordingIfNeeded` : raison du skip) et `call_recording_service` (`🔴 Recording started
    → <dossier>`, `🎬 Chunk N saved: <fichier>`, `⏹ Recording stopped`, `🎙 Recorder state/reason`).
    Le premier chunk démarre maintenant immédiatement, avec **15 tentatives espacées de 2 s** si le
    flux local n'est pas encore publié (cas fréquent : caméra absente/muette côté desktop → Agora
    renvoie `RecorderReasonCode.recorderReasonNoStream`, ou appel vidéo démarré caméra éteinte) ;
    un échec ne laisse plus de « chunk fantôme » (qui déclenchait un `-5` au stop). Rappel :
    l'enregistrement ne démarre que pour un **appel vidéo** après que le correspondant a rejoint le
    canal Agora (`onUserJoined`), et il enregistre le **flux local** de l'appareil.
13. **2026-08-07 — Enregistrement : plus aucune reconfiguration audio de l'appel.** Le service
    appliquait `setAudioProfile(audioProfileMusicHighQualityStereo, audioScenarioGameStreaming)`
    au moteur **pendant** l'appel (au démarrage de l'enregistrement, donc sur les deux appareils).
    Le scénario « game streaming » remplace la chaîne audio optimisée voix (AEC/NS/routage) et peut
    couper la capture micro locale jusqu'au redémarrage du moteur → plus de son dans l'appel ni
    dans l'enregistrement. Suppression de cet appel : l'enregistreur capture le flux que le moteur
    publie déjà, il ne doit pas re-pipeliner l'audio de l'appel. La config vidéo 720p/30 fps reste
    (l'enregistrement bénéficie de la qualité du flux publié). Fichier :
    `call_recording_service.dart`. 27 tests mobile verts, `flutter analyze` sans nouvelle erreur
    ni nouveau warning.
