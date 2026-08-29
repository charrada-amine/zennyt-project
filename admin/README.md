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

```bash
bun install
bun run dev:web
```

Ouvrir [http://localhost:3001](http://localhost:3001).

La console fonctionne uniquement avec le backend Spring réel : il n'existe ni mode démo ni données
locales de remplacement. La connexion appelle `/api/v1/auth/login`, vérifie le claim JWT
`role=ADMIN`, puis charge `/api/v1/games/admin/**`. Les tokens sont conservés dans `sessionStorage`,
jamais dans un cookie ou stockage persistant créé par le frontend.

## Commandes

```bash
bun run check-types
bun run build
bun run check
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
