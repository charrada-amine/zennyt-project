# Backend — Zennyt

Monolithe modulaire **Spring Boot 3 / Java 21**, organisé en bounded contexts
selon le **Domain-Driven Design** et l'**architecture hexagonale**.

## Lancer en local

```bash
mvn spring-boot:run -Dspring-boot.run.profiles=dev
# Swagger UI : http://localhost:8080/swagger-ui.html
```

Depuis la racine du projet, `docker compose up` lance simultanément Maven,
l'API Spring Boot et PostgreSQL avec les variables de développement adaptées.

## Connexion Google et Apple

Le client obtient un ID token auprès de Google ou Apple, puis l'échange via
`POST /api/v1/auth/social`. Le backend valide la signature, l'émetteur,
l'audience et l'email vérifié avant d'émettre les JWT Zennyt.

Configurez les audiences autorisées dans `.env` :

```bash
GOOGLE_CLIENT_IDS=google-web-client-id,google-ios-client-id
APPLE_CLIENT_IDS=com.zennyt.app,com.zennyt.web
```

Pour un nouveau compte, la requête doit aussi fournir `role`,
`termsAccepted: true` et les noms si le fournisseur ne les inclut pas.

```json
{
  "provider": "APPLE",
  "idToken": "<provider-id-token>",
  "firstName": "Ada",
  "lastName": "Lovelace",
  "role": "CANDIDATE",
  "termsAccepted": true
}
```

## Organisation

```
com.zennyt/
├── shared/              Noyau partagé (DomainEvent, AggregateRoot, VO, config, sécurité)
├── identity/            BC Identity      — Squad Identity
├── recruitment/         BC Recruitment   — Squad Jobs   ◀ contexte de référence complet
├── engagement/          BC Engagement    — Squad Engagement
└── analytics/           BC Analytics     — Squad Engagement
```

Chaque contexte suit les **4 couches hexagonales** :

```
<context>/
├── domain/          Modèle pur : aggregates, value objects, events, ports (repository), services
├── application/     Use cases, commandes, listeners d'events
├── infrastructure/  Adapters : JPA, recherche, messaging (implémentent les ports)
└── api/             Contrôleurs REST + DTO
```

Le contexte **recruitment** est entièrement développé (de l'agrégat au contrôleur)
comme modèle à suivre pour les autres squads.

## Les règles non négociables

1. **Isolation des contextes** — un contexte ne dépend jamais du modèle interne
   d'un autre. La seule dépendance autorisée est l'écoute d'un Domain Event
   (package `domain.event`). Voir `ApplicationSubmittedListener` dans engagement.

2. **Communication par Domain Events** — un agrégat enregistre ses événements
   (`registerEvent`), le use case les publie après persistance. Aujourd'hui via
   l'event bus Spring ; demain via Service Bus sans changer la logique.

3. **Domaine pur** — pas d'annotation Spring ni JPA dans `domain/`. Les entités
   JPA vivent dans `infrastructure/` et sont mappées vers/depuis les agrégats.

Ces trois règles sont **vérifiées automatiquement** par `ArchitectureTest`
(ArchUnit) : la CI échoue si elles sont violées.

## Contract-first

Les contrôleurs implémentent les interfaces générées par `openapi-generator`
depuis `../contracts/*.openapi.yaml` (configuré dans le `pom.xml`). Régénérer :

```bash
mvn generate-sources
```

## Tests

```bash
mvn test                # tests unitaires + tests d'architecture
```

- `ApplicationTest` — exemple de test d'agrégat pur (sans Spring).
- `ArchitectureTest` — enforce l'isolation des contextes et l'hexagonal.
