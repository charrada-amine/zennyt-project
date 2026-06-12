# Zennyt

Plateforme mobile de gestion de carrières — application Flutter et back-end Java
(monolithe modulaire DDD) déployé sur Azure App Service.

## Démarrage rapide

| Composant | Emplacement | Lancer en local |
|-----------|-------------|-----------------|
| Back-end + PostgreSQL | racine | `docker compose up` |
| Back-end seul | `backend/` | `cd backend && mvn spring-boot:run -Dspring-boot.run.profiles=dev` |
| Mobile    | `mobile/`   | `cd mobile && flutter run` |
| Contrats  | `contracts/`| fichiers OpenAPI partagés |
| Infra     | `infra/`    | templates Bicep |

Le Compose local expose PostgreSQL sur `localhost:5432`, l'API sur
`http://localhost:8080` et Swagger UI sur
`http://localhost:8080/swagger-ui.html`. Les dépendances Maven et les données
PostgreSQL sont conservées dans des volumes Docker.

Pour personnaliser les ports ou identifiants :

```bash
cp .env.example .env
docker compose up
```

Arrêter les services avec `docker compose down`. Ajouter `-v` pour supprimer
également la base locale et les caches Docker.

## Architecture

Monolithe Spring Boot organisé en 4 bounded contexts (identity, recruitment,
engagement, analytics) communiquant par Domain Events. Voir
[docs/adr/ADR-001](docs/adr/ADR-001-monolithe-modulaire-appservice.md).

## Contribuer

Lisez [CONTRIBUTING.md](CONTRIBUTING.md) : modèle de branches, workflow de merge,
règles anti-conflits et processus de déploiement de fin de sprint.

## Pipelines

- `backend-cd` — build, test, image, déploiement App Service (slot swap en prod)
- `flutter-cd` — test, build Android (AAB) + iOS (IPA), distribution
- `infra-cd` — provisionnement Bicep (sur modification de `infra/`)

## Environnements

| Env | Branche déclencheuse | Cible |
|-----|----------------------|-------|
| DEV | push `develop` | `zennyt-dev` (auto) |
| STAGING | `release/*` | `zennyt-staging` + tests E2E |
| PROD | `main` (tag) | `zennyt-prod` via slot swap + approbation |
