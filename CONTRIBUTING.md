# Guide de contribution — Zennyt

Ce document décrit notre façon de travailler ensemble sur le code. Il complète la Definition of Done du `pull_request_template.md`.

## Structure du repo (monorepo)

```
backend/    Monolithe Spring Boot (DDD) — 4 bounded contexts
mobile/     Application Flutter
contracts/  Contrats OpenAPI partagés (API-first)
infra/      Infrastructure as Code (Bicep)
docs/adr/   Décisions d'architecture
```

## Modèle de branches (GitFlow allégé)

Branches permanentes (protégées, push direct interdit) :
- `main` — reflète la production, chaque commit est taggé en semver
- `develop` — branche d'intégration où converge tout le travail du sprint

Branches éphémères :
- `feature/<SQUAD-ID>-<description>` — une par user story, ex. `feature/JOBS-12-filtres-offres`
- `release/sprint-N` — créée en fin de sprint pour stabiliser
- `hotfix/<description>` — urgence prod, depuis `main`, mergée dans `main` **et** `develop`

## Cycle de vie d'une feature

1. Créer la branche depuis `develop` à jour :
   ```bash
   git checkout develop && git pull
   git checkout -b feature/JOBS-12-filtres-offres
   ```
2. Développer par petits commits fréquents.
3. **Rebase quotidien** sur `develop` (chaque matin) :
   ```bash
   git pull --rebase origin develop
   ```
4. Ouvrir une PR vers `develop`. La CI doit être verte.
5. Obtenir au moins 1 approbation (routée par CODEOWNERS).
6. **Squash merge** — 1 PR devient 1 commit propre sur `develop`.

## Règles anti-conflits

- Une branche `feature` vit **moins de 3 jours**. Découpez les grosses stories.
- PR **petites** (idéalement < 300 lignes) — revue rapide, merge le jour même.
- Chaque squad travaille dans **son** bounded context : peu de fichiers partagés.
- Toute PR de plus de 2 jours doit être rebasée avant merge.
- Ne jamais modifier `contracts/` ou `shared/` sans l'approbation du référent.

## Communication inter-contextes

Les bounded contexts **ne s'appellent jamais directement**. Toute communication
passe par un Domain Event publié sur l'event bus interne. C'est la règle qui
garde nos frontières propres et rend le découpage futur possible.

## Contrats d'API d'abord

Avant d'implémenter un endpoint, publiez/mettez à jour son contrat dans
`contracts/*.openapi.yaml`. Le développeur Flutter génère un client mocké à
partir du contrat et avance sans attendre le backend.

## Déploiement de fin de sprint

1. `git checkout -b release/sprint-N` depuis `develop` → déploie en STAGING
2. Stabilisation : bugfixes sur la release, back-mergés vers `develop`
3. Après validation : merge dans `main`, tag semver → déploiement PROD (slot swap)
4. Back-merge `main` → `develop` pour récupérer les bugfixes

## Commits

Format conventionnel recommandé :
```
feat(jobs): ajout du filtre par localisation
fix(identity): corrige l'expiration du refresh token
chore(infra): bump version App Service Plan
```
