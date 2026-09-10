# Zennyt Game Studio

Console web d'administration du bounded context `games`, créée avec
[Better T Stack](https://github.com/AmanVarshney01/create-better-t-stack).

## Stack

- TanStack Start + React + TypeScript
- Tailwind CSS, Turborepo, Bun, Oxlint/Oxfmt
- backend unique : Spring Boot sous `/api/v1`
- authentification : JWT Spring existant, rôle `ADMIN` obligatoire en mode live

Le projet n'embarque ni Hono, ni oRPC, ni base de données JavaScript. En développement, Vite
proxifie `/api` vers `http://localhost:8080`; en production, servir le front et l'API sous le même
origin évite une configuration CORS transversale.

## Démarrage

Depuis la racine du dépôt : `docker compose up -d --build`. PostgreSQL, Spring et le web
redémarrent avec Docker (`unless-stopped`). La console utilise **`zennyt`**, la base historique
mobile. `postgres-data` conserve les comptes/contenus ; `games-assets` conserve les uploads
locaux entre recréations. Ne pas utiliser `docker compose down -v` pour un redémarrage.

Le web est exposé sur `127.0.0.1:3001` et utilise Vite pour le développement, pas pour la production.
Le démarrage Maven exclut la compilation des tests, sans modifier la CI : des tests recruitment
préexistants ne compilent pas. Pour travailler hors Docker, arrêter le service `admin`, puis
exécuter depuis `admin/` :

```bash
bun install
bun run dev:web
```

Ouvrir [http://localhost:3001](http://localhost:3001).

La console fonctionne uniquement avec le backend Spring réel : il n'existe ni mode démo ni données
locales de remplacement. La connexion appelle `/api/v1/auth/login`, vérifie le claim JWT
`role=ADMIN`, puis charge `/api/v1/games/admin/**`. Les tokens sont conservés dans `sessionStorage`,
jamais dans un cookie ou stockage persistant créé par le frontend.

Le refresh token Spring est conservé dans le même `sessionStorage`. Son renouvellement est
mutualisé entre requêtes concurrentes ; la déconnexion efface la session locale immédiatement
et révoque le refresh token. Les pannes réseau/5xx ne sont plus présentées comme un mot de passe
incorrect. Les anciennes sessions sans refresh token demandent une reconnexion après expiration.

`API_PROXY_TARGET` change la cible serveur Vite (défaut hors Docker : `http://localhost:8080`).
**Mobile reste en démo à la demande de l'utilisateur** : `kLot1DemoBuild` dans le routeur core
force ce mode, même avec `GAMES_MOCK=false`. Les contrôles sont consommés par le code mobile en
mode live, mais n'affectent pas cette démo.

## Commandes

```bash
bun run check-types
bun run build
bun run check
bun test tests/admin-api.test.ts
```

## Architecture

```text
admin/
├── apps/web/
│   ├── public/assets/       # copies web des graphismes Flutter officiels
│   └── src/features/admin/
│       ├── admin-api.ts         # client Spring et chargement parallèle
│       ├── admin-app.tsx        # shell, auth et navigation responsive
│       ├── admin-components.tsx # composants du langage visuel Flutter
│       ├── admin-editor.tsx     # éditeurs et composition ordonnée
│       ├── admin-pages.tsx      # 7 espaces d'administration réels
│       └── admin-types.ts       # contrat UI typé
└── packages/
    ├── ui/                  # primitives partagées du scaffold
    ├── env/
    └── config/
```

Les règles de score ne sont jamais envoyées par la console. Les paramètres modifiables concernent
uniquement le déroulé, l'accessibilité et la présentation ; le backend refuse les clés de scoring.
Questions, banques, settings, modifiers et assets utilisent le cycle versionné brouillon → publié →
archivé. Les suppressions sont limitées aux brouillons et les publications précédentes sont archivées
atomiquement. Supprimer un asset brouillon purge également son objet Cloudinary ou son fichier local.

En profil Spring `dev`, l'absence d'identifiants Cloudinary active un stockage temporaire games-owned
dans le conteneur. L'aperçu reste protégé par le JWT ADMIN. Les environnements hors `dev` continuent
d'utiliser exclusivement Cloudinary.

## Timers et contrôle par jeu

Sélecteur illustré, filtres actives/brouillons/archives, bornes et conversion ms/s. Huit SETTINGS
optionnels couvrent observation/intervalle des chiffres, manipulation/rétention des images,
lecture du plan Predictive Puzzle, feedback Move Fast, réflexion/transition Reflective Pause.
Defaults et overrides sont matérialisés dans le snapshot des nouvelles sessions ; les anciennes
publications restent compatibles. Protocoles anti-triche et seuils de scoring restent protégés.

## Réconciliation locale — 2026-09-06

La base mobile enregistrait Attention/Coordination/Object Location sous V59/V60/V61 ; le dépôt
les attend sous V60/V61/V62 et réserve V59 au catalogue Decision manquant. Après comparaison
identique des schémas et répétition sur clone, trois entrées d'historique ont été réalignées puis
Flyway a appliqué huit migrations. La validation reste activée ; aucun ancien fichier SQL modifié.

Le compte admin, six tables `games.admin_*` et le PNG ont été transférés. Seules les graines admin
fraîchement créées ont été remplacées dans une transaction gardée. Utilisateurs et sessions mobile
préservés (checksums comparés). `zennyt_admin_dev` et son conteneur arrêté restent disponibles,
sans servir l'application. Backups privés : `/Users/slimane/zennyt-db-backup-20260906-ol9FWC/`.
Les scripts audités se trouvent dans `tooling/games/` ; ne pas rejouer sur une autre base sans
comparaison préalable. Le script de réparation refuse un historique différent.

Smoke test depuis la racine, avec `ADMIN_PASSWORD` fourni dans l'environnement :

```bash
node tooling/games/smoke-admin.mjs
# Option explicite : vérifie le refresh après redémarrage Spring.
node tooling/games/smoke-admin.mjs --restart-backend
```
