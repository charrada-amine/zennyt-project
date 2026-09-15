# Module Analytics

**Dernière mise à jour :** 2026-09-11

## Rôle

Bounded context `analytics` : tableaux de bord candidat et recruteur. **Lecture
seule** — le read-model est alimenté par les Domain Events des autres contextes,
jamais par un appel direct à leur modèle interne (règle ArchUnit
`boundedContextsDoNotDependOnEachOthersInternals`, seule exception autorisée :
`..<ctx>.domain.event..`).

Contrat public : `contracts/analytics.openapi.yaml`
(`GET /analytics/candidate/me`, `/recruiter/me`, `/jobs/{jobId}`).

## Architecture

| Couche | Emplacement |
|---|---|
| API | `analytics/api/` (`AnalyticsController`) |
| Application | `analytics/application/` (`AnalyticsQueryService`, `listener/`) |
| Domaine | `analytics/domain/repository/` (ports lecture/écriture, pas de modèle métier) |
| Infrastructure | `analytics/infrastructure/persistence/` (JDBC) |

## Read-model (schéma `analytics`)

| Table | Rôle |
|---|---|
| `job_offer_projection` | offre → recruteur + statut (pour les stats recruteur) |
| `candidate_activity` | activité candidat : `INTERESTED` (swipe RIGHT), `MATCHED`, `TEST_COMPLETED` |

Alimenté par les listeners : `JobOfferCreatedEvent`, `JobOfferStatusChangedEvent`,
`SwipeRecordedEvent`, `MatchCreatedEvent`, `TestResultCompletedEvent`.

## Décision produit (à valider)

- Une **candidature** = un **swipe RIGHT du candidat** sur une offre (l'entité
  `Application` a été supprimée au profit du swipe mutuel, V34).
- `applicationsByStatus` porte les clés `INTERESTED` / `MATCHED` / `TEST_COMPLETED`.

## Non instrumenté (renvoyé à 0/vide, jamais inventé)

Vues de profil/offre (`profileViews`, `views`, `viewsTimeline`),
`profileCompleteness`, `avgResponseTimeHours`, `responseRate`. Nécessitent des
événements de vue/temps de réponse qui n'existent pas encore.

## Changelog

1. **2026-09-11** — Première implémentation : read-model événementiel (migration
   V80), listeners, service de requête et contrôleur pour les 3 opérations du
   contrat. Tests unitaires + ArchUnit verts (JDK 21).
