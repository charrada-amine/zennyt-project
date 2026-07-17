# Plan 005 : Corriger le cycle de vie Identity, les uploads et l’architecture OCR

> **Instructions exécuteur** : travailler seulement dans Identity, son contrat et sa documentation.
> Les handlers shared nécessaires doivent déjà être livrés par le plan 002.
>
> **Drift check** : `git diff --stat 2359b37..HEAD -- backend/src/main/java/com/zennyt/identity backend/src/test/java/com/zennyt/identity contracts/identity.openapi.yaml idendity.md`

## Statut

- **Priorité** : P1
- **Effort** : L
- **Risque** : MED
- **Dépend de** : plans 001 et 002
- **Catégorie** : correction, sécurité, architecture
- **Planifié au** : commit `2359b37`, 2026-07-14

## Pourquoi

Les uploads Cloudinary fonctionnent, mais un PNG déclaré `application/pdf` a été accepté comme CV.
L’OCR retourne 500 lorsque Groq n’est pas configuré. `GroqCvParser` dépend d’un DTO API, ce qui fait
échouer ArchUnit. Enfin, un compte désactivé reste utilisable avec un access token existant et
`currentUser` ne filtre pas l’état actif.

## État actuel

- `GroqCvParser.java:4,82,138` importe/retourne `IdentityDtos.CvParseResult` depuis Infrastructure.
- `CvParseController` dépend directement de `GroqCvParser`.
- `ProfileController` valide le MIME déclaré mais pas la signature ni la taille localement.
- `IdentityService.currentUser` retourne un utilisateur inactif ; deactivate révoque seulement les
  refresh sessions, conformément à la nature stateless du JWT.
- Trois méthodes de `IdentitySecurityAnnotationTest` ont des listes attendues obsolètes.

## Périmètre

Identity API/application/domain/infrastructure, tests Identity, contrat Identity et `idendity.md`.
Hors périmètre : Recruitment, shared, `pom.xml`, `pubspec.yaml`, mobile UI.

## Étapes

### 1. Réparer la frontière OCR

Créer un `CvParserPort` dans application avec un modèle de résultat application/domain sans Spring.
Faire implémenter ce port par l’adapter Groq. Ajouter un use case de parsing ; le contrôleur dépend
du use case et mappe le résultat vers le DTO API.

**Vérifier** : `ArchitectureTest.domainDoesNotDependOnOuterLayers` passe et aucun fichier
`identity/infrastructure` n’importe `identity/api`.

### 2. Gérer l’indisponibilité OCR proprement

Si la clé/configuration ou le fournisseur est indisponible, retourner 503 avec `ApiError`. Mapper
429 sans l’engloutir dans le catch générique ; conserver des timeouts réseau explicites et ne pas
journaliser le contenu complet du CV.

**Vérifier** : adapter mocké : succès 200, non configuré 503, quota 429, timeout 503, JSON fournisseur invalide 502/503 selon contrat.

### 3. Durcir les fichiers

Appliquer la limite contractuelle de 5 Mo avant stockage, refuser fichier vide, vérifier MIME et
magic bytes minimaux pour PNG/JPEG/WEBP/PDF/DOC/DOCX, normaliser le nom et conserver les dossiers
Cloudinary séparés. Corriger `deleteAccount` pour supprimer le CV avec le bon `ResourceType.RAW`.

**Vérifier** : tests avec MIME spoofé, extension spoofée, dépassement 5 Mo, fichier vide, upload
valide, remplacement et suppression idempotente.

### 4. Bloquer les opérations Identity des comptes inactifs

Introduire `requireActiveUser` pour toutes les opérations authentifiées Identity. Maintenir la
révocation des refresh tokens. Publier les événements de désactivation/suppression/changement de
rôle nécessaires au plan 006 pour que Recruitment bloque également l’acteur.

**Vérifier** : après désactivation, `/auth/me` et toute mutation Identity = 401/403 ; refresh = 401.

### 5. Mettre à jour les tests et la documentation

Actualiser `IdentitySecurityAnnotationTest` pour inclure change-password, avatar, logo, CV,
deactivate/delete. Ajouter une entrée de changelog datée sans modifier l’historique et tracer les
limites OCR/mobile provisoires.

**Vérifier** : `docker compose run --rm backend mvn -B -Dtest='com.zennyt.identity.*Test,com.zennyt.architecture.ArchitectureTest' test` → tous verts.

## Critères de fin

- [ ] ArchUnit ne détecte plus Infrastructure → API.
- [ ] OCR non configuré ne produit plus un 500 générique.
- [ ] MIME spoofé et fichiers >5 Mo sont rejetés avant Cloudinary.
- [ ] Le CV est supprimé avec `ResourceType.RAW`.
- [ ] Un compte inactif ne peut plus agir dans Identity.
- [ ] Tous les tests Identity sont verts.

## Conditions STOP

- La correction nécessite une bibliothèque MIME ou HTTP supplémentaire.
- Le contrat ne définit pas le statut de service OCR indisponible.
- Le produit exige la révocation cryptographique immédiate de tous les JWT sans accepter la
  projection événementielle du plan 006.

