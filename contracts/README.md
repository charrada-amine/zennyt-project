# Contrats d'API — Zennyt

Ces fichiers OpenAPI 3.0 sont **la source de vérité** des échanges entre l'app
Flutter (front) et le monolithe Spring Boot (back). Approche **API-first** :
le contrat est rédigé et validé **avant** l'implémentation.

## Fichiers

| Fichier | Bounded context | Contenu |
|---------|-----------------|---------|
| `common.openapi.yaml` | (partagé) | Erreurs, pagination, sécurité JWT |
| `identity.openapi.yaml` | Identity | Auth, OAuth2, profils, CV, compétences |
| `recruitment.openapi.yaml` | Recruitment | Offres, recherche, candidatures, favoris |
| `engagement.openapi.yaml` | Engagement | Chat, notifications, temps réel SignalR |
| `analytics.openapi.yaml` | Analytics | Insights candidat & recruteur (lecture) |

## Règles de travail

1. **Toute évolution d'API commence ici.** On modifie le contrat dans une PR
   dédiée *avant* de coder. Le squad consommateur (souvent Flutter) la relit.
2. Le `CODEOWNERS` impose l'approbation du Tech Lead sur ce dossier.
3. Versionnage : on incrémente `info.version` (semver) à chaque changement
   cassant. Le préfixe d'URL `/api/v1` ne change qu'en cas de rupture majeure.

## Côté back-end (Spring Boot)

Générer les interfaces et DTO depuis le contrat avec `openapi-generator`
(plugin Maven) — approche *contract-first*. Le contrôleur implémente
l'interface générée, garantissant la conformité au contrat.

## Côté front-end (Flutter)

Générer un client Dart mocké pour avancer sans attendre le back :

```bash
# Exemple avec openapi-generator
openapi-generator generate \
  -i contracts/recruitment.openapi.yaml \
  -g dart-dio \
  -o mobile/lib/core/network/generated/recruitment
```

Le Flutter peut développer contre des réponses mockées conformes au schéma,
puis basculer vers les vrais endpoints une fois le back-end prêt.

## Validation locale

```bash
# Linter recommandé (à installer là où le réseau est disponible)
npx @redocly/cli lint contracts/*.openapi.yaml
```
