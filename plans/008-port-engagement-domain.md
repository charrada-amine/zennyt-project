# Plan 008 : Porter le domaine Engagement Conversations / Notifications / Push

> **Instructions exécuteur** : suivre ce plan dans l’ordre et rester strictement dans le
> périmètre Engagement défini ci-dessous. Cette étape porte uniquement le domaine de production,
> ses tests Java purs et la documentation du module. Ne pas porter les listeners, use cases,
> contrôleurs, adaptateurs JPA, migrations, Posts, Comments, Calls, HelpChat,
> UserPostPreferences ou Friendship.
>
> **Drift check (à lancer en premier)** :
> `git diff --stat a52ecf0..HEAD -- backend/src/main/java/com/zennyt/engagement backend/src/test/java/com/zennyt/engagement contracts/engagement.openapi.yaml ENGAGEMENT_MODULE.md`
> Si un des dix fichiers de domaine visés existe déjà ou si le contrat Engagement a changé,
> comparer l’état réel à ce plan puis s’arrêter pour faire valider la nouvelle base.

## Statut

- **Priorité** : P1
- **Effort** : M
- **Risque** : LOW pour l’étape domaine ; MED pour la compatibilité des étapes suivantes
- **Dépend de** : validation du plan et autorisation de créer `ENGAGEMENT_MODULE.md`
- **Catégorie** : migration, architecture, tests, docs
- **Planifié au** : cible `a52ecf0`, source `62fe45c`, 2026-07-18
- **Branche cible observée** : `integration-recruitment-align`
- **Exécuté le** : 2026-07-18 — DONE (17 tests Engagement, 3/3 ArchUnit, 146/146 backend)

## Pourquoi

Le socle événementiel Recruitment est présent dans la cible, mais Engagement ne contient encore
qu’un listener placeholder et aucun domaine Conversations / Notifications / Push. Cette étape
installe les agrégats, value objects et ports nécessaires sans introduire Spring, JPA, API ou
persistance. Le contrat cible reste la source de vérité pour `NotificationType`.

## État actuel vérifié

### Cible

- Le contrat OpenAPI ne déclare aucun package Java (`x-java-package` absent). Le namespace réel
  observé dans la source et dans la cible est `com.zennyt.engagement`; aucun package
  `com.progresscareers` n’apparaît dans les dix fichiers source.
- `contracts/engagement.openapi.yaml:215-234` définit :
  - `Notification.type` = `APPLICATION_VIEWED`, `APPLICATION_STATUS_CHANGED`, `NEW_MESSAGE`,
    `JOB_MATCH`, `PROFILE_VIEWED` ;
  - `Message.senderRole` = `CANDIDATE`, `RECRUITER`, `SYSTEM` ;
  - `Message.contentType` = `TEXT`, `IMAGE`, `FILE`, `SYSTEM` ;
  - `PushDeviceRegistration.platform` = `ANDROID`, `IOS`.
- `AggregateRoot` et `DomainEvent` sont identiques entre source et cible, mais aucun des dix
  fichiers à porter ne les importe ni ne les étend. Ne pas ajouter artificiellement cet héritage.
- Baseline Java 21 du 2026-07-18 : `ArchitectureTest` exécute 3 tests, 0 échec, 0 erreur ; le build
  Maven compile avec succès.
- La cible ne contient pas de `ENGAGEMENT_MODULE.md`. `AGENTS.md` exige de demander sa création
  avant de coder, puis de le mettre à jour dans la même PR.
- Le worktree contient déjà des modifications utilisateur non commitées sous Recruitment et
  `contracts/recruitment.openapi.yaml`. Elles sont hors périmètre et doivent rester intactes.

### Source exacte à porter

Source absolue : `/Users/mac/Documents/GitHub/zennyt-private/zennyt`, commit `62fe45c`.

| Fichier source | Contenu public utile | Lignes | SHA-256 observé |
|---|---|---:|---|
| `backend/src/main/java/com/zennyt/engagement/domain/model/Conversation.java` | Agrégat avec `JobOpportunity` et `Message` imbriqués ; factories `create`/`rehydrate`, `sendMessage`, `markAsRead`, `attachJobOpportunity`, preview 100 caractères | 139 | `2b9d05e8c72fe3b7157c48ada5b2e26d0fef68d41e60b567abea1fd172ec4c6a` |
| `backend/src/main/java/com/zennyt/engagement/domain/model/Notification.java` | Agrégat avec factories `create`/`rehydrate`, `markAsRead`, getters | 78 | `886dc8327ac7f240615d73caed1b6b77d72a1238bd41405ee1b3c2876dac3a60` |
| `backend/src/main/java/com/zennyt/engagement/domain/model/PushDevice.java` | Agrégat avec factories `register`/`rehydrate`, getters | 39 | `6d89a23e855ceb62991bb228e8309ace4b3c3287a5da5e500583f4c91d038609` |
| `backend/src/main/java/com/zennyt/engagement/domain/vo/NotificationType.java` | Enum source incompatible avec le contrat cible ; ne pas copier son contenu | 16 | `59431e7a6abb2eed5ee7de85a939f5d63f48279432e1c3e00f3fcf7d4ff47393` |
| `backend/src/main/java/com/zennyt/engagement/domain/vo/MessageContentType.java` | `TEXT`, `IMAGE`, `FILE`, `SYSTEM` | 11 | `89281d6346805839fbb720507bbccbe1a40c7de12d420d0526ed628bc47bb77f` |
| `backend/src/main/java/com/zennyt/engagement/domain/vo/MessageSenderRole.java` | `CANDIDATE`, `RECRUITER`, `SYSTEM` | 10 | `d03847d9afa599c9d46259091df737505f9e5d27c479ea649150c4c8438cbb60` |
| `backend/src/main/java/com/zennyt/engagement/domain/vo/PushPlatform.java` | `ANDROID`, `IOS` | 9 | `ed1f88bea9065822090a457536b8565b160be4841d4f7082ef44df76634bcbd1` |
| `backend/src/main/java/com/zennyt/engagement/domain/repository/ConversationRepository.java` | `save`, `findById`, `findByIdAndUserId`, `findByApplicationId`, `findByUserId` | 22 | `7db2724c4df82ec9335ed2472f2df6e418b8316121ae54301fb4ed1babede2bf` |
| `backend/src/main/java/com/zennyt/engagement/domain/repository/NotificationRepository.java` | `save`, `findById`, `findByUserId`, `countUnreadByUserId`, `markAllAsRead` | 22 | `a828b0af3ad4a421e763d677226f1915dfb4638a0f7a7ed5b1b1d0536354eb21` |
| `backend/src/main/java/com/zennyt/engagement/domain/repository/PushDeviceRepository.java` | `save` | 10 | `7d5ad9f054e19eff1a0ef6008dbb4f53dea3371c03071b20c9ede58ba7cf5a91` |

Les dix fichiers source compilent ensemble en Java 21 sans implémentation des trois ports.

## Contrat de `NotificationType`

Créer exactement ce contenu, sans alias ni valeur différée :

```java
package com.zennyt.engagement.domain.vo;

/**
 * Type de notification défini par contracts/engagement.openapi.yaml.
 */
public enum NotificationType {
    APPLICATION_VIEWED,
    APPLICATION_STATUS_CHANGED,
    NEW_MESSAGE,
    JOB_MATCH,
    PROFILE_VIEWED
}
```

Le contrat OpenAPI n’est pas modifié dans cette étape.

## Commandes de vérification

À lancer depuis `backend/` avec Java 21. Si `mvn` n’est pas disponible localement, utiliser
l’image déjà prévue pour Java 21 :

| But | Command | Résultat attendu |
|---|---|---|
| Compilation | `mvn -DskipTests compile` | `BUILD SUCCESS`, aucune erreur |
| Tests domaine Engagement | `mvn -Dtest='ConversationTest,NotificationTest,PushDeviceTest,EngagementValueObjectsContractTest' test` | au moins 14 tests, 0 échec/erreur |
| ArchUnit | `mvn -Dtest=ArchitectureTest test` | 3 tests, 0 échec/erreur |
| Suite backend | `mvn test` | tous les tests verts ; sinon classifier précisément les échecs préexistants |

Fallback Docker depuis la racine :

```bash
docker run --rm \
  -v /Users/mac/Documents/GitHub/zennyt-private/zennyt-project:/workspace \
  -w /workspace/backend \
  maven:3.9.9-eclipse-temurin-21 \
  mvn -Dtest=ArchitectureTest test
```

La CI référence `./mvnw clean verify`, mais aucun `mvnw` n’existe actuellement dans la cible.
Ne pas corriger ce problème dans cette étape et ne pas copier le wrapper source sans autorisation.

## Périmètre

### Fichiers de production à créer — exactement dix

- `backend/src/main/java/com/zennyt/engagement/domain/model/Conversation.java`
- `backend/src/main/java/com/zennyt/engagement/domain/model/Notification.java`
- `backend/src/main/java/com/zennyt/engagement/domain/model/PushDevice.java`
- `backend/src/main/java/com/zennyt/engagement/domain/vo/NotificationType.java`
- `backend/src/main/java/com/zennyt/engagement/domain/vo/MessageContentType.java`
- `backend/src/main/java/com/zennyt/engagement/domain/vo/MessageSenderRole.java`
- `backend/src/main/java/com/zennyt/engagement/domain/vo/PushPlatform.java`
- `backend/src/main/java/com/zennyt/engagement/domain/repository/ConversationRepository.java`
- `backend/src/main/java/com/zennyt/engagement/domain/repository/NotificationRepository.java`
- `backend/src/main/java/com/zennyt/engagement/domain/repository/PushDeviceRepository.java`

### Tests à créer

- `backend/src/test/java/com/zennyt/engagement/domain/ConversationTest.java`
- `backend/src/test/java/com/zennyt/engagement/domain/NotificationTest.java`
- `backend/src/test/java/com/zennyt/engagement/domain/PushDeviceTest.java`
- `backend/src/test/java/com/zennyt/engagement/domain/EngagementValueObjectsContractTest.java`

### Documentation à créer après autorisation

- `ENGAGEMENT_MODULE.md`

### Lecture seule

- `contracts/engagement.openapi.yaml`
- Les primitives `backend/src/main/java/com/zennyt/shared/domain/**`
- Les événements `backend/src/main/java/com/zennyt/recruitment/domain/event/**`
- `backend/src/test/java/com/zennyt/architecture/ArchitectureTest.java`

### Hors périmètre absolu

- `backend/pom.xml`, `mobile/pubspec.yaml`, `shared/`, `identity/`, `recruitment/`.
- `engagement/application/`, `engagement/infrastructure/`, `engagement/api/` et le listener
  placeholder existant.
- Posts, Comments, Calls, HelpChat, UserPostPreferences, Friendship.
- Contrôleurs, use cases, entités/adaptateurs JPA, Flyway, génération OpenAPI, mobile.
- Suppression ou remplacement de changements utilisateur déjà présents.

## Workflow Git

- Rester sur `integration-recruitment-align`; ne pas changer de branche avec le worktree sale.
- Commits conventionnels recommandés, par exemple `feat(engagement): port conversation notification push domain`.
- Ne pas pousser ni ouvrir de PR sans instruction explicite.

## Étapes

### 0. Obtenir la validation obligatoire

Faire valider ce plan et demander explicitement l’autorisation de créer `ENGAGEMENT_MODULE.md`.
Confirmer également que les quatre fichiers de tests sont inclus dans “domain/ seulement” au sens
où aucun code de production hors domaine n’est ajouté.

**Vérifier** : validation écrite reçue. Sans elle, STOP.

### 1. Refaire l’exploration immédiatement avant copie

Afficher intégralement les dix fichiers source, vérifier leurs SHA-256, relire les lignes 215-234
du contrat cible et comparer les deux primitives shared source/cible. Rechercher toute annotation
Spring/JPA et tout package `com.progresscareers` dans les dix fichiers.

**Vérifier** : les neuf fichiers copiables ont les SHA ci-dessus ; `NotificationType` source est
explicitement exclu ; aucune annotation/import framework ; aucun import `AggregateRoot` ou
`DomainEvent` ; packages `com.zennyt.engagement.domain.*`.

### 2. Créer la documentation initiale du module

Créer `ENGAGEMENT_MODULE.md` avec au minimum : périmètre Conversations / Notifications / Push,
arborescence, contrat maître, zones protégées, décisions à valider, tableau de statut, roadmap,
changelog numéroté daté du 2026-07-18 et `Dernière mise à jour`.

Tracer comme décisions : `NotificationType` est piloté par le contrat cible ; aucun événement
Engagement ni héritage `AggregateRoot` n’est introduit à cette étape ; le mapping futur
`Notification.subtitle` vers le champ OpenAPI `body` reste différé.

**Vérifier** : toutes les sections exigées par `AGENTS.md` sont présentes ; aucun historique
préexistant n’a été inventé.

### 3. Porter les modèles et value objects

Copier `Conversation`, `Notification`, `PushDevice`, `MessageContentType`, `MessageSenderRole` et
`PushPlatform` à l’identique. Recréer `NotificationType` avec les cinq valeurs du contrat cible.
Ne pas ajouter validation, événement, héritage, annotation, nouvelle méthode ou renommage de champ.

**Vérifier** : `cmp` est identique à la source pour les six fichiers copiés ; seul
`NotificationType` diffère volontairement et son tableau `values()` correspond exactement au
contrat cible.

### 4. Porter les trois ports repository

Copier les interfaces et leurs signatures à l’identique. Ne créer aucune implémentation, bean
Spring ou adapter de persistance.

**Vérifier** : `cmp` identique pour les trois interfaces ; compilation Java 21 verte.

### 5. Ajouter les tests de caractérisation du domaine

Suivre le style JUnit 5 Java pur de
`backend/src/test/java/com/zennyt/recruitment/domain/ApplicationTest.java`. Aucun contexte Spring,
aucun mock repository, aucune base.

**Vérifier** : commande tests Engagement verte avec au moins 14 tests.

### 6. Exécuter les gates et classifier le résultat

Lancer compilation, tests Engagement, ArchUnit puis suite backend. Pour ArchUnit, consigner
séparément les trois méthodes : `domainIsFrameworkAgnostic`,
`domainDoesNotDependOnOuterLayers`, `boundedContextsDoNotDependOnEachOthersInternals`.

**Vérifier** : 3/3 ArchUnit verts. La compilation attendue est verte : l’absence
d’implémentations des ports n’est pas une erreur Java.

### 7. Finaliser la documentation et le rapport

Mettre à jour l’arborescence, le statut, la roadmap, le changelog et la dernière mise à jour du
module. Produire le rapport imposé par `AGENTS.md`, avec fichiers créés groupés, contrat inchangé,
nombre exact de tests, décisions, points ouverts et confirmation des zones protégées.

**Vérifier** : `git diff --name-only` ne montre que les dix fichiers domaine, quatre tests,
`ENGAGEMENT_MODULE.md` et éventuellement la mise à jour de statut de ce plan.

## Plan de tests détaillé

### `ConversationTest` — minimum 8 tests

- `create` initialise ID, champs, liste vide, `lastMessageAt == null`, compteur 0 et preview vide.
- `sendMessage` utilise `TEXT` si `contentType` est null.
- `sendMessage` ajoute le message, incrémente le compteur et met à jour `lastMessageAt`.
- `messages()` retourne une copie défensive.
- `rehydrate` copie une `List.of(...)` et permet encore `sendMessage`.
- `markAsRead` ramène le compteur à zéro.
- `lastMessagePreview` couvre vide, 100 caractères et 101 caractères tronqués avec `...`.
- `attachJobOpportunity` attache puis remplace l’offre.

### `NotificationTest` — minimum 3 tests

- `create` génère ID/date et démarre non lue tout en préservant tous les champs.
- `markAsRead` passe à vrai et reste idempotent.
- `rehydrate` préserve ID, date, lecture et champs optionnels.

### `PushDeviceTest` — minimum 2 tests

- `register` génère l’ID et préserve utilisateur/token/platform/deviceName.
- `rehydrate` préserve tous les champs.

### `EngagementValueObjectsContractTest` — minimum 1 test

- Vérifier par `assertArrayEquals` les valeurs exactes et leur ordre pour les quatre enums, en
  particulier les cinq valeurs de `NotificationType` et l’absence des anciennes valeurs source.

## Résultats de compilation : classification attendue

### Attendu

- Aucune erreur de compilation.
- Aucun bean/adaptateur ne fournit encore les ports, mais cela ne devient une erreur qu’au futur
  démarrage d’un contexte Spring qui injecterait un use case consommateur. Ces consommateurs ne
  sont pas créés dans cette étape.

### Inattendu — arrêter et corriger dans le périmètre ou rapporter

- symbole introuvable pour un des quatre enums ou un modèle imbriqué ;
- package autre que `com.zennyt.engagement.domain.*` ;
- erreur sur `List.getLast()` indiquant que la compilation n’utilise pas Java 21 ;
- dépendance Spring/JPA ou vers les internes d’un autre bounded context ;
- classe dupliquée à cause d’un drift concurrent ;
- toute erreur provenant des dix nouveaux fichiers qui n’existait pas à la baseline.

Les erreurs provenant exclusivement de changements Recruitment non commitées doivent être
classifiées comme préexistantes et ne doivent pas être corrigées dans cette PR Engagement.

## Incompatibilités différées à ne pas traiter dans l’étape 1

- Le listener source appelle `event.jobId()`, tandis que les événements cible exposent
  `jobOfferId()`.
- Le listener source traite `OFFER`, `ACCEPTED`, `WITHDRAWN`, `VIEWED`, `INTERVIEW`, `SUBMITTED`,
  tandis que la cible expose actuellement `PENDING`, `SHORTLISTED`, `APPROVED`, `REJECTED`.
- Les listeners source utilisent `INTEREST_CONFIRMED`, `NEW_JOB` et `APPLICATION_REJECTED`, absents
  du `NotificationType` cible.
- Le modèle `Notification` source expose `subtitle`, `contactName`, `contactInitials`, `chatId`,
  alors que l’OpenAPI cible expose `body`. Le mapping devra être décidé à l’étape API/application.
- `backend/pom.xml` ne contient pas encore d’exécution openapi-generator pour Engagement. Toute
  modification future du `pom.xml` demandera une autorisation explicite.

Ces écarts rendent impossible le portage ultérieur des listeners “copier-coller”. Ils doivent faire
l’objet d’un plan contract-first séparé après cette étape.

## Critères de fin

- [ ] Autorisation explicite de créer `ENGAGEMENT_MODULE.md` reçue.
- [ ] Exactement dix fichiers de production Engagement créés, aucun autre package de production.
- [ ] `NotificationType` contient exactement les cinq valeurs du contrat cible.
- [ ] Les neuf autres fichiers sont identiques à la source observée.
- [ ] Au moins 14 tests domaine Java pur verts.
- [ ] Compilation Java 21 verte, aucune “erreur attendue de port non implémenté”.
- [ ] ArchUnit : 3 tests verts, dont les trois règles nommées.
- [ ] Suite backend exécutée et toute régression classifiée.
- [ ] `ENGAGEMENT_MODULE.md` à jour avec changelog et dernière mise à jour.
- [ ] Contrat OpenAPI, Recruitment, Identity, Shared, `pom.xml` et mobile inchangés.
- [ ] Posts, Comments, Calls, HelpChat, UserPostPreferences et Friendship absents du diff.

## Conditions STOP

- L’autorisation de créer la documentation module n’est pas donnée.
- Un des dix fichiers cible existe déjà ou a divergé depuis ce plan.
- Le contrat cible ne contient plus exactement les cinq valeurs constatées.
- Un besoin réel impose de modifier `shared/`, Recruitment, Identity, `pom.xml`, une migration,
  l’application, l’infrastructure ou l’API Engagement.
- Un écran/endpoint/adapter doit être inventé pour faire passer l’étape.
- La logique interne source doit être modifiée pour satisfaire un test non caractérisant.
- Une erreur de compilation exige de copier un fichier source hors de la liste des dix.

## Notes de maintenance

- Une conversation représente actuellement un propriétaire `userId` et un `counterpartId`, pas
  une collection générique de participants. Préserver ce modèle jusqu’à une décision produit.
- `unreadCount` est incrémenté pour tout message, y compris potentiellement celui envoyé par le
  propriétaire ; ne pas corriger silencieusement cette règle pendant le portage.
- Le domaine n’émet aucun événement Engagement à cette étape. L’intégration Recruitment →
  Engagement sera réalisée dans l’application lors d’une étape ultérieure.
- En revue, vérifier en priorité la pureté Java, l’égalité source/cible des neuf fichiers et la
  liste exacte de `NotificationType`.
