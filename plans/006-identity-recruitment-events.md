# Plan 006 : Synchroniser l’état des acteurs par Domain Events

> **Instructions exécuteur** : cette intégration ne doit contenir aucun appel direct entre modules.
> Recruitment peut importer uniquement les événements publics sous `identity.domain.event`.
>
> **Drift check** : `git diff --stat 2359b37..HEAD -- backend/src/main/java/com/zennyt/identity backend/src/main/java/com/zennyt/recruitment backend/src/main/resources/db/migration backend/src/test`

## Statut

- **Priorité** : P1
- **Effort** : L
- **Risque** : HIGH — synchronisation de sécurité entre bounded contexts
- **Dépend de** : plans 003 et 005
- **Catégorie** : architecture, sécurité
- **Planifié au** : commit `2359b37`, 2026-07-14

## Pourquoi

Recruitment utilise le subject/role JWT mais ne sait pas si le compte Identity a été désactivé,
supprimé ou a changé de rôle après émission du token. L’ADR-001 interdit un appel direct vers
Identity. Une projection locale alimentée par événements permet à Recruitment d’appliquer ces
règles sans casser la frontière du bounded context.

## État actuel

- `identity/package-info.java` annonce `UserRegisteredEvent` et `ProfileCompletedEvent`, mais aucun
  événement Identity n’est effectivement publié par les services actuels.
- Recruitment publie déjà ses événements via `ApplicationEventPublisher` après persistance.
- ArchUnit autorise la dépendance vers `..domain.event..` d’un autre contexte, mais interdit ses
  modèles, repositories, application et infrastructure.

## Périmètre

- Événements publics dans `identity/domain/event/`.
- Publication dans les use cases/services Identity.
- Listener, projection et policy port dans Recruitment.
- Nouvelle migration `V15__recruitment_actor_projection.sql` si V14 appartient au plan OTP.
- Tests domaine/application/architecture et docs des deux modules.

Hors périmètre : bus externe Azure, engagement, shared, appel SQL inter-schema, appel REST interne.

## Étapes

### 1. Définir les événements minimaux et non sensibles

Créer des événements versionnés pour registered, role-changed, deactivated, reactivated si le
produit le permet, et deleted. Inclure uniquement publicUserId, rôle, active, occurredAt et eventId.
Ne pas inclure email, téléphone, CV ou autre PII inutile.

**Vérifier** : tests de structure et revue confirmant l’absence de PII.

### 2. Publier après persistance Identity

Les événements doivent être émis après sauvegarde réussie. Les transitions idempotentes ne doivent
pas émettre de doublon incohérent. Documenter la limite du bus Spring in-process ; ne pas ajouter
un outbox silencieusement.

**Vérifier** : tests application capturant exactement un événement par transition réussie et zéro en cas d’échec.

### 3. Construire une projection Recruitment

Créer `RecruitmentActor` avec publicUserId, rôle, active, lastEventAt/version. Le listener effectue
un upsert idempotent et ignore les événements anciens/dupliqués. Ajouter un port `ActorPolicy` que
les use cases Recruitment utilisent avant toute action.

**Vérifier** : événements doublés/hors ordre, changement de rôle, désactivation et suppression.

### 4. Initialiser les utilisateurs existants sans couplage direct

Ajouter côté Identity un mécanisme explicite de publication de snapshots au démarrage contrôlé ou
via commande administrative interne. Il publie les mêmes événements ; Recruitment ne lit jamais
la base Identity. Rendre la procédure rejouable et documentée.

**Vérifier** : sur une base avec utilisateurs existants et projection vide, la procédure remplit la
projection ; une seconde exécution ne crée aucun doublon.

### 5. Bloquer immédiatement les acteurs inactifs dans Recruitment

Chaque use case sensible consulte `ActorPolicy`. Après événement de désactivation/suppression,
les nouvelles requêtes avec un JWT encore cryptographiquement valide sont rejetées 401/403.

**Vérifier** : test d’intégration register → action autorisée → deactivate event → même JWT rejeté.

## Critères de fin

- [ ] Aucun import inter-module hors `identity.domain.event`.
- [ ] La projection ne contient aucune PII non nécessaire.
- [ ] Les listeners sont idempotents et tolèrent le désordre.
- [ ] Les utilisateurs existants ont une procédure de resynchronisation rejouable.
- [ ] Un compte désactivé ne peut plus agir dans Recruitment avec son ancien JWT.
- [ ] ArchUnit reste vert.

## Conditions STOP

- Le besoin exige une transaction atomique entre les deux modules.
- Quelqu’un propose un appel direct à un repository/service Identity.
- Les changements précédents ont déjà pris le numéro de migration V15 : choisir le prochain numéro, ne jamais renommer une migration appliquée.
- Le produit exige une garantie de livraison durable : ouvrir un plan outbox séparé.

