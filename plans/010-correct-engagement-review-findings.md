# Plan 010 : Corriger les findings de la revue Engagement avant mise en production

> **Instructions exécuteur** : lire ce plan entièrement avant de modifier le code. Exécuter les
> phases dans l'ordre et lancer chaque gate. Ne pas toucher au mobile ni à `shared/`. Les
> modifications Identity et Recruitment sont limitées aux listeners d'état d'accès et à leurs
> tests. Ne pas modifier V1–V21 : toute évolution SQL utilise une nouvelle migration.
>
> **Drift check initial** :
> `git diff --stat 9522c4a -- contracts/engagement.openapi.yaml backend/src/main/java/com/zennyt/engagement backend/src/test/java/com/zennyt/engagement backend/src/main/java/com/zennyt/identity backend/src/main/java/com/zennyt/recruitment backend/src/test/java/com/zennyt/recruitment backend/src/main/resources/db/migration ENGAGEMENT_MODULE.md RECRUITMENT_MODULE.md idendity.md`
>
> Ce plan est rédigé sur le commit `9522c4a` avec une intégration Engagement encore non commitée.
> Comparer les extraits de la section « État actuel » au worktree avant toute action. Si
> l'intégration actuelle n'a pas été commitée ou sauvegardée de façon récupérable, STOP.

## Statut

- **Priorité** : P0 avant merge/déploiement — **DONE 2026-07-18**
- **Effort** : L — 4 lots backend + 1 lot de décisions externes
- **Risque** : HIGH — transactions inter-contextes, contrat public, concurrence SQL
- **Dépend de** : intégration Engagement actuelle compilable et sauvegardée
- **Catégories** : bug, sécurité, architecture, performance, migration, tests
- **Planifié au** : commit `9522c4a`, worktree `integration-recruitment-align`, 2026-07-18

## Résultat attendu

L'intégration conserve les 30 opérations Engagement, mais :

1. une panne de projection Engagement/Recruitment ne rollback plus une transaction Identity ;
2. un utilisateur voit l'option de sondage qu'il a sélectionnée ;
3. le double vote concurrent retourne un résultat métier déterministe et ne produit pas de 500 ;
4. `POST /conversations` est une vraie commande idempotente avec requête validée ;
5. le rejeu d'un événement ne duplique ni conversation ni notification ;
6. le feed utilise un nombre borné de requêtes et ne charge plus tous les UUID des likers ;
7. les limites externes STOMP/push/Cloudinary sont décidées explicitement avant production.

## État actuel confirmé

### Transactions inter-contextes

`EngagementIdentityAccessStateListener` et le listener Recruitment utilisent actuellement :

```java
@EventListener
@Transactional
public void on(UserAccessStateChangedEvent event) { ... }
```

Ils rejoignent donc la transaction Identity qui publie l'événement. Le snapshot de démarrage
publie aussi les événements hors transaction : la correction doit préserver ce chemin.

### Sondages

`PostDtos.PollResponse.from` construit chaque `PollOptionResponse` avec
`selectedByMe = false`. `VoteOnPollUseCase` fait `hasVoted` puis `save` puis `recordVote`, ce qui
constitue un check-then-act concurrent. Le port Post hydrate tous les UUID de likes pour calculer
le compteur et `isLikedByMe`.

### Conversations et événements

`CreateConversationUseCase` est `readOnly` et ne fait qu'un `find-or-404`, alors que le contrôleur
retourne 201. Le contrôleur accepte une `Map<String, UUID>` sans validation. Le listener de
soumission protège la conversation par recherche préalable, mais crée toujours une nouvelle
notification lors d'un rejeu.

### Baseline de vérification

- Java 21 : compilation verte.
- Suite backend : 168 tests, 0 échec.
- ArchUnit : 3/3 vert.
- Contrat/runtime : 30/30 routes.
- PostgreSQL 16 : Flyway V1–V21 et `ddl-auto=validate` verts.

## Commandes de référence

| But | Command | Résultat attendu |
|---|---|---|
| Compilation | `JAVA_HOME=/opt/homebrew/opt/openjdk@21 '/Applications/IntelliJ IDEA.app/Contents/plugins/maven/lib/maven3/bin/mvn' -q -DskipTests compile` dans `backend/` | exit 0 |
| Tests ciblés | même préfixe Maven puis `-q -Dtest='com.zennyt.engagement.**,com.zennyt.recruitment.application.IdentityAccessStateListenerTest' test` | tous verts |
| Suite complète | même préfixe Maven puis `-q test` | 0 échec, au moins 168 tests |
| Diff | `git diff --check` | aucune erreur |
| Domaine pur | `rg 'org.springframework|jakarta.persistence|javax.persistence' backend/src/main/java/com/zennyt/engagement/domain` | aucune sortie |
| Routes | test `EngagementApiSafetyTest` | 30 endpoints protégés et parité exacte |

Si les chemins IntelliJ/JDK ne sont pas disponibles, utiliser l'image Maven 3.9.9 + Temurin 21
déjà documentée dans `plans/009-integrate-engagement-end-to-end.md`; ne modifier aucune dépendance.

## Lot A — Isoler les projections Identity après commit

### Portée autorisée

- `backend/src/main/java/com/zennyt/engagement/application/EngagementIdentityAccessStateListener.java`
- `backend/src/main/java/com/zennyt/recruitment/application/IdentityAccessStateListener.java`
- tests correspondants dans Engagement et Recruitment
- `idendity.md`, `RECRUITMENT_MODULE.md`, `ENGAGEMENT_MODULE.md`

### Étapes

1. Remplacer les listeners synchrones transactionnels par
   `@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)`.
   `fallbackExecution = true` est obligatoire pour conserver le replay hors transaction de
   `IdentityAccessSnapshotPublisher`.
2. Exécuter chaque écriture de projection dans une transaction indépendante avec
   `@Transactional(propagation = Propagation.REQUIRES_NEW)`.
3. Conserver les protections `lastEventAt`/`lastEventId`. Ne transformer aucun listener en appel
   direct Identity → Engagement/Recruitment.
4. Ajouter un test d'intégration événementiel prouvant :
   - aucune projection avant commit ;
   - projection après commit ;
   - événement hors transaction traité par fallback ;
   - événement ancien ou rejoué ignoré ;
   - une exception de projection ne rollback pas l'utilisateur Identity déjà sauvegardé.
5. Documenter que le mécanisme reste in-process et non durable. Ne simuler ni broker ni outbox.

### Gate A

- Tests Identity/Engagement/Recruitment verts.
- Aucun `@EventListener` restant sur ces deux projections.
- Une transaction Identity peut réussir indépendamment d'une transaction de projection.

### STOP

STOP si la sémantique Spring observée fait remonter l'exception `AFTER_COMMIT` jusqu'à la réponse
HTTP malgré le commit. Dans ce cas, produire un test de caractérisation et faire valider soit un
handler d'erreur explicite, soit un outbox ; ne pas avaler silencieusement l'exception.

## Lot B — Rendre les sondages corrects et atomiques

### Portée autorisée

- contrat Engagement uniquement si une précision de schéma est nécessaire
- domaine/ports Post, use cases de lecture/vote, adaptateurs JPA Post/Poll
- DTO/controller Posts
- tests domaine/application/persistence/API Engagement
- nouvelle migration uniquement si une contrainte SQL supplémentaire est requise

### Étapes

1. Introduire un read model applicatif, par exemple `PostView(Post post, UUID selectedOptionId,
   long likesCount, boolean likedByActor)`. Ne pas ajouter d'état dépendant de l'acteur dans
   l'agrégat `Post`.
2. Étendre le port de lecture pour récupérer, pour l'acteur courant :
   - le nombre de likes ;
   - si l'acteur a liké ;
   - l'option sur laquelle il a voté.
3. Mapper `selectedByMe` à `true` uniquement pour `selectedOptionId`. Vérifier le feed, le détail,
   la réponse après création et la réponse après vote.
4. Remplacer le double-vote check-then-act par une réservation SQL atomique :
   `INSERT ... ON CONFLICT DO NOTHING` retournant un booléen. Valider d'abord que l'option
   appartient au sondage, puis tenter l'insert ; si aucune ligne n'est insérée, retourner
   `ConflictException`. Incrémenter le compteur dans la même transaction après réservation.
5. Ajouter les tests : jamais voté, vote réussi, option invalide, second vote séquentiel = 409,
   deux votes concurrents du même acteur = un succès + un conflit, rollback complet si la mise à
   jour du compteur échoue.

### Gate B

- Aucune occurrence de `selectedByMe` câblée à `false` dans le mapper.
- `recordVote` est atomique et retourne un résultat exploité par le use case.
- Test concurrent vert sur PostgreSQL, pas uniquement avec mocks.
- Contrat toujours à 30 opérations.

## Lot C — Corriger la commande conversation et l'idempotence événementielle

### Décision obligatoire avant code

Valider l'option recommandée : maintenir une projection locale minimale de candidature alimentée
par `ApplicationSubmittedEvent`, puis rendre `POST /conversations` réellement idempotent.
Alternative : modifier le contrat pour présenter l'opération comme récupération d'une conversation
précréée. Ne pas conserver le couple actuel « find-only + 201 Created ».

### Portée autorisée

- contrat Engagement
- domaine/ports/use cases/listeners/API/persistence Engagement concernés
- tests Engagement
- nouvelle migration Flyway `V22__engagement_event_idempotency.sql` si aucune V22 n'existe au
  moment de l'exécution
- documentation Engagement

### Étapes — option recommandée

1. Ajouter un DTO typé `ConversationCreateRequest(@NotNull UUID applicationId)` avec `@Valid`.
   Corps absent, clé absente ou UUID invalide doivent retourner 400.
2. Ajouter une projection locale `EngagementApplication` contenant `applicationId`, `jobOfferId`,
   `candidateId`, `recruiterId`, `jobTitle`, `lastEventId` et `lastEventAt`. Aucun FK inter-schéma.
3. Ajouter dans V22 une table de projection et une table `processed_events` avec `event_id` unique.
   Ne modifier ni V19, ni V20, ni V21.
4. Extraire `EnsureConversationUseCase` :
   - charger la projection par `applicationId` et participant ;
   - retourner l'existante ou créer une conversation ;
   - s'appuyer sur `UNIQUE(application_id)` pour arbitrer deux créations concurrentes ;
   - retourner un résultat indiquant `created` afin que le contrôleur réponde 201 ou 200.
5. Faire traiter `ApplicationSubmittedEvent` dans une transaction Engagement indépendante : claim
   atomique de `eventId`, upsert projection, ensure conversation, création de notification. Un
   rejeu du même événement doit être un no-op complet.
6. Appliquer la même stratégie `processed_events` au listener de changement de statut.
7. Tester : body invalide = 400, outsider = 404, création = 201, répétition = 200 avec même ID,
   double appel concurrent = une conversation, rejeu événement = une notification, événement
   différent légitime = nouvelle notification.

### Gate C

- `CreateConversationUseCase` n'est plus `readOnly` et crée réellement lorsque nécessaire.
- Aucun `Map<String, UUID>` dans le contrôleur.
- Un `eventId` ne peut produire qu'un effet Engagement.
- Flyway V1→V22 et `ddl-auto=validate` verts sur PostgreSQL 16.

### STOP

STOP si la projection candidature nécessiterait une information absente de
`ApplicationSubmittedEvent`. L'enrichissement doit être validé dans Recruitment ; aucun appel
direct vers ses repositories/services n'est autorisé.

## Lot D — Borner les requêtes du feed et les listes

### Portée autorisée

- repositories/adaptateurs/read models Post/Comment Engagement
- use cases/DTO/contrat Posts et Comments
- tests de requêtes et performance bornée
- documentation Engagement

### Étapes

1. Remplacer `findLikedUserIds(postId)` par des projections SQL ciblées : `count(*)` et
   `exists(postId, actorId)`. Ne jamais charger tous les likers.
2. Charger médias et options par lots d'IDs (`WHERE post_id IN (...)`) puis les regrouper en maps.
   Le chargement d'une page doit utiliser un nombre constant de requêtes, indépendant du nombre de
   posts ; cible recommandée : au plus 6 requêtes pour une page.
3. Conserver exactement les filtres PUBLIC/FRIENDS, auteur courant, posts masqués et auteurs
   bloqués. Ajouter un test pour les deux orientations d'une amitié.
4. Ajouter pagination à la liste des commentaires uniquement après évolution contract-first.
   Préférer `page/size` avec taille max 100 et une réponse paginée cohérente avec `PageMeta`.
5. Ajouter un test d'intégration qui compte les requêtes pour 1 puis 20 posts et prouve que le
   nombre ne croît pas linéairement.

### Gate D

- Aucun `findLikedUserIds` restant.
- Feed de 20 posts : nombre de requêtes borné par le seuil testé.
- Pagination commentaires bornée et documentée, ou décision explicite de report si elle est
  incompatible avec un client déjà publié.
- Suite complète, ArchUnit et smoke PostgreSQL verts.

## Lot E — Décisions de production externes

Ce lot est un gate de décision, pas une autorisation d'ajouter des dépendances.

1. **Realtime multi-instance** : confirmer mono-instance ou choisir un broker relay. Si plusieurs
   instances sont prévues, définir RabbitMQ STOMP/Redis et la stratégie d'authentification avant
   d'abandonner `enableSimpleBroker`.
2. **Négociation** : décider si `accessToken` reste nullable et documenté, ou si le contrat retire
   ce champ hérité de SignalR. Ne générer aucun faux token.
3. **Push** : choisir FCM/APNs, politique de révocation des tokens et retry. L'enregistrement seul
   n'est pas une livraison push complète.
4. **Cloudinary** : définir timeouts, erreurs 503/429 et stratégie de retry bornée avec les
   capacités de la dépendance existante. Toute nouvelle dépendance exige une autorisation dédiée.
5. **Friendship et HelpChat** : définir les producteurs d'amitié et le répondant support. Ne pas
   inventer d'endpoint ou de réponse automatique sans contrat/produit validé.
6. **Snapshot Identity** : mesurer le volume en production. Si le temps dépasse le budget de
   readiness, paginer ou remplacer le replay complet par un mécanisme durable.

## Ordre de livraison recommandé

```text
Lot A (transactions)
  └── Lot B (sondages atomiques)
       └── Lot C (conversation + idempotence)
            └── Lot D (performance)
                 └── validation finale + décisions Lot E
```

Faire une PR par lot. Ne pas mélanger Lot A et Lot C : en cas de régression événementielle, cette
séparation permet d'identifier si le défaut vient de la phase transactionnelle ou de
l'idempotence métier.

## Done criteria globaux

- [x] Aucun listener de projection Identity ne rejoint la transaction émettrice.
- [x] `selectedByMe` reflète le vote réel de l'acteur.
- [x] Double vote concurrent : aucun 500 et aucun double comptage.
- [x] `POST /conversations` possède une sémantique validée et un DTO `@Valid`.
- [x] Rejeu d'événement : aucun doublon conversation/notification.
- [x] Feed paginé : nombre constant de requêtes et aucun chargement de tous les likers.
- [x] 30/30 endpoints protégés et alignés sur OpenAPI.
- [x] Domaine Engagement sans Spring/JPA ; ArchUnit 3/3.
- [x] Suite backend >= 168 tests, 0 échec.
- [x] Flyway complet + `ddl-auto=validate` + démarrage Spring verts sur PostgreSQL 16.
- [x] Aucun fichier mobile ou `shared` modifié.
- [x] Documentation et changelog des trois modules touchés mis à jour.

## Conditions STOP globales

- Une correction exige de modifier une migration existante V1–V21.
- Une correction exige un appel direct entre Engagement et Identity/Recruitment.
- Le nombre ou la sémantique publique des endpoints change sans modification contract-first.
- Une nouvelle dépendance `pom.xml` devient nécessaire sans autorisation explicite.
- Des changements existants non liés dans Recruitment/Identity risquent d'être écrasés.
- Un test de concurrence ou PostgreSQL échoue deux fois sans cause déterminée.

## Notes de maintenance

- Le correctif `AFTER_COMMIT` isole le rollback, mais ne rend pas les événements durables. Un
  outbox reste le suivi recommandé avant séparation en microservices.
- `selectedByMe`, `likedByActor` et les autres données dépendantes de l'acteur appartiennent à un
  read model applicatif, pas à l'agrégat domaine.
- Une contrainte unique SQL reste l'arbitre final de l'idempotence ; les checks Java améliorent les
  messages d'erreur mais ne suffisent jamais sous concurrence.
- Surveiller spécialement, en revue de PR, les chemins 200/201/400/404/409 et les rollbacks de
  transactions multi-écritures.
