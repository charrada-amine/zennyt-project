# Démo encadrant — backend intégré (`integration-recruitment-align`)

Démo du backend **fusionné** (identity + games + recruitment alignés) sur une
**base fraîche**, avec les 6 comptes de démo. Vérifié de bout en bout le 20/07 :
**Bruno Demo 67/67 requêtes, 45/45 assertions**, base neuve à chaque exécution —
couvre maintenant les 4 fonctionnalités backend du 20/07 (présélection →
réponse candidat, génération de test par IA, résumé IA candidat, référentiel
de métiers). Détail : `RECAP_20260720_BACKEND.md` à la racine du repo.

Comptes (mdp `zennyt123`) : `recruiter1@` (Rania), `recruiter2@` (Youssef),
`candidate1@` (Aicha), `candidate2@` (Omar), `candidate3@` (Lina),
`admin1@` (Sami, rôle ADMIN — nouveau 20/07, promu par SQL car l'auto-inscription
refuse ce rôle) `…@zennyt.com`.

> ⚠️ **Le mot de passe n'est plus `1234`.** L'écran de connexion réel de l'app
> mobile (`login_screen.dart`/`login_viewmodel.dart`) rejette côté client tout
> mot de passe < 6 caractères, **avant même l'appel réseau** — `1234` semblait
> "ne pas marcher" alors que le backend l'acceptait très bien. D'où `zennyt123`.

> ⚠️ L'ancien conteneur `zennyt-project-backend-1` fait tourner l'ancien backend
> REC-04, PAS le backend intégré. Le bloc ci-dessous l'arrête et lance le jar
> intégré sur le port 8080. (Rollback : `docker start zennyt-project-backend-1`.)

> ⚠️ **Appli mobile factice à désinstaller.** L'AVD `zennyt_phone` héberge aussi
> un très vieil APK `com.example.zennyt` (avec un "t" final) — un écran de dev
> avec 5 boutons de comptes statiques ("Zennyt — Dev Login"), sans rapport avec
> l'app réelle. L'app réelle et actuellement en développement est
> `com.example.zenny` (SANS "t" final, cf. `mobile/android/app/build.gradle.kts`).
> Si ce vieil APK traîne encore : `adb uninstall com.example.zennyt`.

---

## ⏱ 10 minutes avant la séance — préparation (PowerShell, racine du projet)

Pré-requis : Docker Desktop démarré (le conteneur postgres `zennyt-project-db-1`
doit tourner), jar déjà construit (`backend\mvnw.cmd -q package -DskipTests`).

```powershell
Set-Location "C:\Users\Ghassen\Documents\zennyt-project\zennyt-project"

# 0. Libérer le port 8080 (ancien backend REC-04) + arrêter tout jar résiduel
docker stop zennyt-project-backend-1 2>$null
taskkill /F /IM java.exe 2>$null

# 1. Base 100% fraîche
docker exec zennyt-project-db-1 psql -U postgres -c "DROP DATABASE IF EXISTS zennyt_int WITH (FORCE)"
docker exec zennyt-project-db-1 psql -U postgres -c "CREATE DATABASE zennyt_int"

# 2. Variables (GROQ_API_KEY lu depuis .env) + lancement du backend intégré
Get-Content .env | Where-Object { $_ -match '^\s*[^#].*=' } | ForEach-Object {
  $k,$v = $_ -split '=',2; [Environment]::SetEnvironmentVariable($k.Trim(), $v.Trim())
}
$env:DB_USER='postgres'; $env:DB_PASSWORD='postgres'; $env:RECRUITMENT_CALLBACK_SECRET='dev-secret'
Start-Process -WindowStyle Hidden -FilePath java -ArgumentList @(
  '-jar','backend\target\zennyt-api-1.0.0.jar',
  '--spring.profiles.active=dev',
  '--spring.datasource.url=jdbc:postgresql://localhost:5433/zennyt_int'
) -RedirectStandardOutput backend-int.log -RedirectStandardError backend-int.err.log
do { Start-Sleep 3; try { $h = Invoke-RestMethod http://localhost:8080/actuator/health } catch {} } while (-not $h)

# 3. Créer les 6 comptes (l'API exige un mdp >= 8 caractères), puis figer
#    les UUID fixes attendus par Bruno/le seeder ET le hash BCrypt de « zennyt123 »
#    (PAS « 1234 » : l'app mobile refuse tout mdp < 6 caractères côté client)
#    admin1 s'inscrit en RECRUITER puis est promu ADMIN par SQL ci-dessous :
#    l'auto-inscription refuse ce rôle ("Le rôle administrateur ne peut pas
#    être créé publiquement", 400) — même mécanique que les UUID figés.
$users = @(
  @{f='Rania';   l='Ben Ali';  e='recruiter1@zennyt.com'; r='RECRUITER'; c='Tunis'},
  @{f='Youssef'; l='Trabelsi'; e='recruiter2@zennyt.com'; r='RECRUITER'; c='Sousse'},
  @{f='Aicha';   l='Gharbi';   e='candidate1@zennyt.com'; r='CANDIDATE'; c='Tunis'},
  @{f='Omar';    l='Sassi';    e='candidate2@zennyt.com'; r='CANDIDATE'; c='Sfax'},
  @{f='Lina';    l='Bouazizi'; e='candidate3@zennyt.com'; r='CANDIDATE'; c='Tunis'},
  @{f='Sami';    l='Khelifi';  e='admin1@zennyt.com';     r='RECRUITER'; c='Tunis'}
)
foreach ($u in $users) {
  $body = @{ firstName=$u.f; lastName=$u.l; email=$u.e; password='bootstrap-1234';
             role=$u.r; city=$u.c; country='Tunisie'; termsAccepted=$true } | ConvertTo-Json
  Invoke-RestMethod -Uri http://localhost:8080/api/v1/auth/register -Method Post `
    -ContentType 'application/json' -Body $body | Out-Null
}
$hash = '$2a$12$ICQvy9treApWAg4ADVBe.Obtl7RoHSvzEI9cg8gnUr../B2tHNPgG'  # BCrypt(12) de « zennyt123 »
docker exec zennyt-project-db-1 psql -U postgres -d zennyt_int -q -c "
UPDATE users SET public_id='11111111-1111-1111-1111-111111111111', password_hash='$hash' WHERE email='recruiter1@zennyt.com';
UPDATE users SET public_id='33333333-3333-3333-3333-333333333333', password_hash='$hash' WHERE email='recruiter2@zennyt.com';
UPDATE users SET public_id='22222222-2222-2222-2222-222222222222', password_hash='$hash' WHERE email='candidate1@zennyt.com';
UPDATE users SET public_id='44444444-4444-4444-4444-444444444444', password_hash='$hash' WHERE email='candidate2@zennyt.com';
UPDATE users SET public_id='55555555-5555-5555-5555-555555555555', password_hash='$hash' WHERE email='candidate3@zennyt.com';
UPDATE users SET public_id='66666666-6666-6666-6666-666666666666', password_hash='$hash', role='ADMIN' WHERE email='admin1@zennyt.com';
DELETE FROM recruitment.actors;"

# 4. Redémarrer le backend : la projection recruitment.actors est rejouée au boot
#    (IdentityAccessSnapshotPublisher) avec les UUID figés
taskkill /F /IM java.exe 2>$null
Start-Process -WindowStyle Hidden -FilePath java -ArgumentList @(
  '-jar','backend\target\zennyt-api-1.0.0.jar',
  '--spring.profiles.active=dev',
  '--spring.datasource.url=jdbc:postgresql://localhost:5433/zennyt_int'
) -RedirectStandardOutput backend-int.log -RedirectStandardError backend-int.err.log
do { Start-Sleep 3; $h = $null; try { $h = Invoke-RestMethod http://localhost:8080/actuator/health } catch {} } while (-not $h)
"PRET ✔  -> http://localhost:8080/actuator/health"
```

## 🅲 App mobile (Android emulator)

Le backend intégré doit écouter sur le **port 8080** (pas 8081) — l'app
Android résout `10.0.2.2:8080` par défaut (`mobile/lib/core/config/app_config.dart`).

```powershell
flutter emulators --launch zennyt_phone
cd mobile
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
```

Prérequis : `mobile\.env` doit exister (même vide) — `pubspec.yaml` le déclare
comme asset et le build échoue sinon (fichier gitignored, jamais committé).

## 🅰 Vérification express (2 min)

```powershell
cd tooling\bruno
npx @usebruno/cli run Demo --env Local
```

Attendu : **67 requêtes, 0 échec, 45/45 assertions.** Le dossier Demo couvre :
login JWT réel (recruteur, candidat, **admin**), **référentiel de métiers**
(liste, proposition recruteur, approbation/rejet admin, `jobPositionId` sur
l'offre), offres, recherche filtrée, **génération de test par IA** (prompt
libre + fichier PDF uploadé), swipes + matchs, candidatures (shortlist →
**réponse du candidat**, plus recruteur-approuve-directement = 403 volontaire),
**la tentative EST la candidature** (consentement 422 sans, `applicationId`
dans la réponse), **résumé IA candidat** (soft + hard skills), résultats +
stats (enveloppe applications), fit scores (recompute Groq, deck
`/recruiters/me/candidate-feed`, dismiss), vérification d'identité,
opportunités, paiements, et les tests négatifs (401 secret callback, 403
non-propriétaire, 404 candidat fantôme).

Les numéros de fichier ne suivent plus l'ordre d'exécution après les
insertions du 20/07 (ex. "24a" tourne bien après "24", mais "44" tourne après
"42" à cause d'un trou de numérotation historique) — l'ordre réel est piloté
par `seq` dans chaque `.bru`, pas par le préfixe du nom de fichier.

## 🅱 Le tunnel OTP réel — à montrer en direct (argument fort)

Le backend intégré génère un **vrai OTP** (6 chiffres, salé + haché SHA-256,
TTL 10 min, 5 tentatives max) — fini le « tout code passe » de l'ancien dev.
En dev le code est livré dans le log applicatif (`DevOtpDeliveryLogger`).

1. Bruno : `31 Send opportunity offer` puis `33 Confirm opportunity`.
2. `34 Verify opportunity OTP` avec `12345` → **401** (le mauvais code est rejeté — le montrer !).
3. Récupérer le vrai code :
   ```powershell
   Select-String "DEV OTP" backend-int.log | Select-Object -Last 1
   ```
4. Rejouer `34` avec ce code → **200**, statut `CONFIRMED`, `otpVerified: true`.

Même mécanique pour le paiement (37 → 39).

## Notes / limites connues

- L'assertion `pairsWritten >= 1` du recompute (44) suppose une **base fraîche**
  (les projections soft-skills sont seedées par `DevDataSeeder`).
- Les dossiers Bruno hors `Demo` (Auth, Candidate, Recruiter, Callbacks) datent
  de REC-04 et peuvent référencer d'anciennes routes — seule la collection
  `Demo` est la suite de régression vérifiée sur le backend intégré.
- La collection **est idempotente même sur base non fraîche** : "00b Propose
  job position" et "55 Propose throwaway position" suffixent leur nom avec un
  timestamp (`{{demoRunId}}`, fixé une fois par run via `script:pre-request`)
  pour ne jamais reproduire la collision de contrainte unique (nom, secteur)
  observée le 20/07 en rejouant `Demo` deux fois via le GUI sans reset —
  vérifié en rejouant deux fois d'affilée sans reset (67/67, 45/45 les deux
  fois). Une base fraîche reste recommandée avant une vraie démo (assertion
  `pairsWritten` ci-dessus), mais un rejeu accidentel en GUI ne casse plus
  toute la chaîne en cascade.
- **Résumé IA candidat (24a)** : `hardSkills` est généré de façon asynchrone
  (`HardSkillsSummaryListener`, appel Groq hors thread de requête) après
  soumission d'une tentative. `available` peut valoir `false` juste après —
  rejouer la requête quelques secondes plus tard montre le vrai résumé, comme
  pour le tunnel OTP (§B).
- Bug corrigé le 20/07 pendant cette vérification : `@Lob` sur `String` dans
  `CvProfileProjectionEntity`/`HardSkillsSummaryEntity`/`SoftSkillsSummaryEntity`
  faisait échouer le **boot** (Hibernate attendait `oid`, la migration déclare
  `TEXT`) — le backend intégré ne démarrait tout simplement pas sur une vraie
  base tant que ce n'était pas corrigé (`@Column(columnDefinition = "TEXT")`,
  même convention que `JobOfferEntity`/`AssessmentEntity`). Comme le bug
  ci-dessous, invisible aux tests unitaires — seule cette vérification live
  l'a révélé.
- Bug corrigé le 20/07 pendant cette vérification : `POST /job-positions`
  renvoyait un 500 brut (contrainte SQL non gérée) au lieu d'un 409 propre
  sur un doublon (nom, secteur) — `ProposeJobPositionUseCase` fait maintenant
  un `existsByNameAndSector` avant écriture, comme le reste du code applicatif
  (cf. `ConflictException`). Trouvé uniquement grâce à cette première
  vérification live — les tests unitaires (repository mocké) ne
  l'auraient jamais détecté.
