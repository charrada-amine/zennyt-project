# Frontend — Zennyt

Application mobile **Flutter** en **Clean Architecture**, pendant du backend DDD.

## Lancer en local

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

## Organisation

```
lib/
├── core/                Partagé par toutes les features (Référent Design System)
│   ├── network/         Dio + AuthInterceptor (refresh JWT auto), NetworkInfo
│   ├── error/           Failure (sealed) + Exception
│   ├── usecase/         Classe de base UseCase<Type, Params>
│   ├── di/              Injection de dépendances (GetIt)
│   ├── router/          GoRouter central
│   └── theme/           Design tokens (seule source visuelle)
│
├── features/
│   ├── jobs/            ◀ feature de référence, entièrement développée
│   ├── auth/            squelette (structure prête)
│   ├── profile/         squelette
│   ├── applications/    squelette
│   ├── chat/            squelette
│   └── notifications/   squelette
│
└── shared/              Widgets communs réutilisables
```

## Les 3 couches de chaque feature

```
<feature>/
├── domain/          Cœur métier, PUR (aucune dépendance framework)
│   ├── entities/        Objets métier (Equatable)
│   ├── repositories/    Ports (interfaces abstraites)
│   └── usecases/        Une intention métier = un use case
│
├── data/            Implémentation technique
│   ├── models/          DTO (fromJson/toJson) + mapping vers entités
│   ├── datasources/     remote (Dio) + local (Hive)
│   └── repositories/    Implémentent les ports, gèrent offline-first
│
└── presentation/    UI
    ├── bloc/            Events, States, logique de présentation
    ├── pages/           Écrans
    └── widgets/         Composants de la feature
```

## Règles de dépendance (Dependency Rule)

```
presentation  ──►  domain  ◄──  data
```

- **domain** ne dépend de rien (ni Flutter, ni Dio, ni Hive).
- **presentation** dépend de domain (via use cases), jamais de data directement.
- **data** implémente les ports de domain.
- Une feature **n'importe jamais** une autre feature. Le partage passe par `core/`
  ou `shared/`.

## Pattern Either<Failure, T>

Les use cases et repositories retournent `Either<Failure, T>` (dartz) — pas
d'exception qui traverse les couches. Le BLoC fait le `fold()` : branche gauche
→ état d'erreur, branche droite → état de succès.

## Injection de dépendances

`core/di/injection.dart` enregistre tout dans GetIt au démarrage. Les BLoCs sont
en `factory` (instance neuve par écran), le reste en `singleton`. Les BLoCs
reçoivent leurs dépendances par constructeur — jamais de `GetIt.instance` au
milieu du code, ce qui les garde testables.

## Génération de code

```bash
dart run build_runner build --delete-conflicting-outputs
```

Pour générer un client API depuis les contrats OpenAPI :

```bash
openapi-generator generate -i ../contracts/recruitment.openapi.yaml \
  -g dart-dio -o lib/core/network/generated/recruitment
```

## Tests

```bash
flutter test
```

- `test/features/jobs/job_list_bloc_test.dart` — test du BLoC (bloc_test + mocktail).
  Modèle à suivre pour tester les autres BLoCs et repositories.
