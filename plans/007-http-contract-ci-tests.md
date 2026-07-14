# Plan 007 : Couvrir tous les endpoints et rendre la dérive impossible en CI

> **Instructions exécuteur** : ce plan ne corrige pas les comportements ; il les verrouille après
> les plans 001–006. Si un test révèle encore un défaut fonctionnel, STOP et renvoyer au plan propriétaire.
>
> **Drift check** : `git diff --stat 2359b37..HEAD -- backend/src/test contracts .github/workflows/backend-cd.yml backend/src/main/java`

## Statut

- **Priorité** : P1
- **Effort** : L
- **Risque** : MED
- **Dépend de** : plans 001 à 006
- **Catégorie** : tests, CI
- **Planifié au** : commit `2359b37`, 2026-07-14

## Pourquoi

Les 86 opérations runtime ont été testées manuellement, mais le dépôt n’a pas de tests MockMvc/
Spring Boot couvrant les contrôleurs Identity et Recruitment. Les 13 tests Recruitment sont
unitaires seulement. La dérive 93 contrats/86 runtime et les failles de rôle ont donc traversé la
suite existante.

## Périmètre

- `backend/src/test/java/com/zennyt/identity/**`
- `backend/src/test/java/com/zennyt/recruitment/**`
- tests de conformité sous `backend/src/test/java/com/zennyt/contracts/**`
- `.github/workflows/backend-cd.yml` après autorisation du référent
- docs/changelogs de module

Hors périmètre : nouvelles features, nouveau framework de test, `pom.xml`, tests mobile UI.

## Étapes

### 1. Créer des fixtures sans réseau

Mocker les ports Cloudinary, Groq, email, callback et OTP. Utiliser des utilisateurs distincts :
deux candidats, un étudiant, deux recruteurs, un admin. Les tests doivent être déterministes,
transactionnels et ne jamais appeler un service externe.

**Vérifier** : suite lancée réseau désactivé → mêmes résultats.

### 2. Couvrir les 46 opérations Identity

Pour chaque opération : happy path, JWT absent/invalide, rôle incorrect, validation et erreur métier
principale. Couvrir rotation/logout, désactivation/suppression, upload multipart, CV spoofé, OCR
200/429/503 et ownership des sous-ressources profil.

**Vérifier** : matrice de test liée à chaque `operationId` Identity ; aucune opération sans cas.

### 3. Couvrir les 40 opérations Recruitment canoniques

Pour chaque opération : happy path et matrice rôle/ownership. Couvrir explicitement sous-route job
sans JWT, actor IDs forgés, accès croisé entre deux recruteurs/candidats, callback secret,
idempotence, OTP expiré/réutilisé et machines à états.

**Vérifier** : chaque `operationId` Recruitment a au moins un happy path et un test négatif pertinent.

### 4. Ajouter un test contract/runtime automatique

Démarrer le contexte Spring de test, récupérer la description SpringDoc et comparer méthode + route
normalisée avec les deux contrats. Vérifier aussi unicité/non-vacuité des `operationId`, schémas de
sécurité et réponses obligatoires. Utiliser les bibliothèques déjà transitives ; ne pas modifier le pom.

**Vérifier** : supprimer temporairement une route dans une copie de test fait échouer le test de parité ; restaurer avant commit.

### 5. Verrouiller la CI

Dans `backend-cd.yml`, exécuter génération OpenAPI, tests, ArchUnit et rapport JaCoCo avant build
d’image. Ne pas imposer un pourcentage global arbitraire ; imposer la réussite de la matrice des
opérations et zéro violation ArchUnit.

**Vérifier** : `docker compose run --rm backend mvn -B clean verify` → BUILD SUCCESS, zéro test échoué, zéro divergence contract/runtime.

### 6. Mettre à jour les docs

Ajouter nombres de tests, commande de reproduction, statut et changelog dans `idendity.md` et
`RECRUITMENT_MODULE.md`. Ne pas réécrire les entrées passées.

## Critères de fin

- [ ] Les 86 opérations canoniques ont une couverture HTTP automatisée.
- [ ] Chaque mutation sensible possède au moins un test de rôle et un test d’ownership.
- [ ] Contract/runtime drift fait échouer la CI.
- [ ] Les adapters externes ne sont jamais appelés par la suite de test.
- [ ] `mvn clean verify` est vert, y compris ArchUnit.
- [ ] Aucun changement `pom.xml`/mobile.

## Conditions STOP

- Un plan précédent n’est pas DONE ou son comportement cible reste ambigu.
- Une bibliothèque de test supplémentaire semble nécessaire.
- Les tests exigent de vraies credentials ou un réseau externe.
- La modification CI/shared n’a pas l’autorisation requise.

