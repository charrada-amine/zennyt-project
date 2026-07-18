# Démo encadrant — backend intégré (`integration-recruitment-align`)

Démo du backend **fusionné** (identity + games + recruitment alignés) sur une
**base fraîche**, avec les 5 comptes de démo. Vérifié de bout en bout le 18/07 :
**Bruno Demo 56/56 requêtes, 21/21 assertions**, base neuve à chaque exécution.

Comptes (mdp `1234`) : `recruiter1@` (Rania), `recruiter2@` (Youssef),
`candidate1@` (Aicha), `candidate2@` (Omar), `candidate3@` (Lina) `…@zennyt.com`.

> ⚠️ L'ancien conteneur `zennyt-project-backend-1` fait tourner l'ancien backend
> REC-04, PAS le backend intégré. Le bloc ci-dessous l'arrête et lance le jar
> intégré sur le port 8080. (Rollback : `docker start zennyt-project-backend-1`.)

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

# 3. Créer les 5 comptes (l'API exige un mdp >= 8 caractères), puis figer
#    les UUID fixes attendus par Bruno/le seeder ET le hash BCrypt de « 1234 »
$users = @(
  @{f='Rania';   l='Ben Ali';  e='recruiter1@zennyt.com'; r='RECRUITER'; c='Tunis'},
  @{f='Youssef'; l='Trabelsi'; e='recruiter2@zennyt.com'; r='RECRUITER'; c='Sousse'},
  @{f='Aicha';   l='Gharbi';   e='candidate1@zennyt.com'; r='CANDIDATE'; c='Tunis'},
  @{f='Omar';    l='Sassi';    e='candidate2@zennyt.com'; r='CANDIDATE'; c='Sfax'},
  @{f='Lina';    l='Bouazizi'; e='candidate3@zennyt.com'; r='CANDIDATE'; c='Tunis'}
)
foreach ($u in $users) {
  $body = @{ firstName=$u.f; lastName=$u.l; email=$u.e; password='bootstrap-1234';
             role=$u.r; city=$u.c; country='Tunisie'; termsAccepted=$true } | ConvertTo-Json
  Invoke-RestMethod -Uri http://localhost:8080/api/v1/auth/register -Method Post `
    -ContentType 'application/json' -Body $body | Out-Null
}
$hash = '$2a$12$YRdSmCskupDl0hT85MsdZO6/5aBiRzwVxZMltpa4SHuwa0Pnkvjwq'  # BCrypt(12) de « 1234 »
docker exec zennyt-project-db-1 psql -U postgres -d zennyt_int -q -c "
UPDATE users SET public_id='11111111-1111-1111-1111-111111111111', password_hash='$hash' WHERE email='recruiter1@zennyt.com';
UPDATE users SET public_id='33333333-3333-3333-3333-333333333333', password_hash='$hash' WHERE email='recruiter2@zennyt.com';
UPDATE users SET public_id='22222222-2222-2222-2222-222222222222', password_hash='$hash' WHERE email='candidate1@zennyt.com';
UPDATE users SET public_id='44444444-4444-4444-4444-444444444444', password_hash='$hash' WHERE email='candidate2@zennyt.com';
UPDATE users SET public_id='55555555-5555-5555-5555-555555555555', password_hash='$hash' WHERE email='candidate3@zennyt.com';
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

## 🅰 Vérification express (2 min)

```powershell
cd tooling\bruno
npx @usebruno/cli run Demo --env Local
```

Attendu : **56 requêtes, 0 échec, 21/21 assertions.** Le dossier Demo couvre :
login JWT réel, offres, recherche filtrée, swipes + matchs, candidatures
(shortlist → approve), **la tentative EST la candidature** (consentement 422 sans,
`applicationId` dans la réponse), résultats + stats (enveloppe applications),
fit scores (recompute Groq, deck `/recruiters/me/candidate-feed`, dismiss),
vérification d'identité, opportunités, paiements, et les tests négatifs
(401 secret callback, 403 non-propriétaire, 404 candidat fantôme).

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

- `POST /assessments/generate` (génération IA du QCM) n'existe **pas encore**
  sur le backend intégré (retiré du dossier Demo, cf. plan de portage).
- L'assertion `pairsWritten >= 1` du recompute (44) suppose une **base fraîche**
  (les projections soft-skills sont seedées par `DevDataSeeder`).
- Les dossiers Bruno hors `Demo` (Auth, Candidate, Recruiter, Callbacks) datent
  de REC-04 et peuvent référencer d'anciennes routes — seule la collection
  `Demo` est la suite de régression vérifiée sur le backend intégré.
