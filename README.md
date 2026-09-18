# Zennyt

Plateforme mobile de gestion de carrières — application Flutter et back-end Java
(monolithe modulaire DDD). Monorepo orchestré par [Turborepo](https://turbo.build).

## Démarrage rapide

Installations utiles : [bun](https://bun.sh), Docker, Flutter 3.x.

```bash
bun install          # turbo + tooling racine
bun run dev          # backend (Docker) + Game Studio (3001) + Platform Console (3002)
bun run mobile       # application Flutter contre http://localhost:8080/api/v1
```

À la place, chaque composant se lance individuellement :

| Tâche turbo | Composant | Ce qui tourne |
|-------------|-----------|---------------|
| `bun run backend` | API + PostgreSQL | `docker compose up backend` (API sur :8080) |
| `bun run web` | Game Studio | `admin/apps/web` en Vite dev (port 3001) |
| `bun run console` | Platform Console | `admin/apps/console` en Vite dev (port 3002) |
| `bun run mobile` | App Flutter | `flutter run` dans `mobile/` |

Le Compose local expose PostgreSQL sur `localhost:5432`, l'API sur
`http://localhost:8080` et Swagger UI sur
`http://localhost:8080/swagger-ui.html`. Les dépendances Maven et les données
PostgreSQL sont conservées dans des volumes Docker.

Pour personnaliser les ports, identifiants ou l'URL d'API vue par le mobile :

```bash
cp .env.example .env          # ports Compose, secrets, BILLING_RECEIPT_VERIFIER…
API_BASE_URL=http://10.0.2.2:8080/api/v1 bun run mobile   # émulateur Android
```

Arrêter les services avec `docker compose down`. Ajouter `-v` pour supprimer
également la base locale et les caches Docker.

## Layout

| Chemin | Rôle |
|--------|------|
| `backend/` | API Spring Boot (monolithe DDD, Maven) |
| `mobile/` | Application Flutter |
| `admin/` | Workspace Bun + Turborepo des deux back-offices (`apps/web`, `apps/console`) |
| `contracts/` | Contrats OpenAPI partagés (contract-first) |
| `docs/` | Documentation, plans, audits, ADR |
| `infra/` | Infra as code |
| `figma/`, `fit_score/`, `plans/`, `tooling/` | Maquettes, corpus FitScore, plans d'intégration, outillage |

## Architecture

Monolithe Spring Boot organisé en bounded contexts (identity, recruitment,
engagement, analytics) communiquant par Domain Events. Voir
[docs/adr/ADR-001](docs/adr/ADR-001-monolithe-modulaire-appservice.md).

## Contribuer

Lisez [CONTRIBUTING.md](CONTRIBUTING.md) : modèle de branches, workflow de merge,
règles anti-conflits et processus de déploiement de fin de sprint.

## CI (suite de tests locale)

- `backend-ci` — build Maven + tests + ArchUnit (JDK 21)
- `flutter-ci` — format, `flutter analyze`, tests + couverture, goldens

Aucun déploiement cloud dans la CI : les workflows ne font que construire et
tester.
