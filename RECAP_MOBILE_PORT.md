# Recap — mobile frontend integration (Fits, Search, Careers/Progress)

Hand-off note to continue in a fresh conversation. Covers porting the REC-04
mobile UI onto the `integration-recruitment-align` backend, plus a fresh-DB
demo runbook and a debug-APK install for a physical phone. Everything below
is **verified live** (emulator + adb screenshots) but **nothing is committed
yet** — see §6.

---

## 0. Context

- **Zennyt** = school recruitment app. Branch: `integration-recruitment-align`
  (backend merged from `amine/integration` + our corrections, see `RECAP.md`
  at repo root for that history — this file covers the *frontend* work that
  came after).
- Two Flutter apps exist in this repo's history:
  - **`mobile/`** (current branch, package `com.example.zenny`) — the one
    being worked on. Real JWT auth (login/signup/Google/GitHub), but Fits/
    Search/Careers were placeholder screens until this session.
  - **`mobile/zennyt/`** on `feature/REC-04-mobile-integration` (package
    `com.example.zennyt`, note the extra "t") — a *different, more complete*
    frontend with real Fits/Search/Careers screens, built against the old
    REC-04 backend contract. **This is what got ported.**
- Full comparison of what differs between the two apps:
  [docs/MOBILE_APP_COMPARISON.md](docs/MOBILE_APP_COMPARISON.md).

## 1. What was ported this session

Approach for all three: extract the REC-04 screen/widget code **verbatim**
(same UI, same file structure), then only rewrite the **data layer**
(repository + provider) to hit the merged backend's actual routes, and strip
REC-04-only infra the current app doesn't have (their own l10n system,
`Failure`/dartz error types, GetIt DI, `AppColors`/`AppTypography` theme
classes) in favour of hardcoded strings/colors and the current app's
`ApiException` pattern.

### Fits (`mobile/lib/features/fits/`)
- Candidate: swipe deck of job offers (`GET /job-offers`).
- Recruiter: swipe deck of fit-scored candidates for a selected offer
  (`GET /recruiters/me/candidate-feed`), with a "Sourcing: <offer>" chip
  selector.
- Real backend calls: `POST /swipes`, `DELETE /swipes/{id}` (undo),
  `GET /swipes/targets`, `GET /candidates/me/matches`,
  `GET /recruiters/me/matches`.
- Match celebration dialog wired to real `matched` flag from `POST /swipes`.

### Search (`mobile/lib/features/search/`)
- Same UI for both roles; candidate searches job offers, recruiter searches
  candidates from the *currently sourced offer's* fit-scored deck (the merged
  backend has no bare "all candidates" endpoint — only per-offer).
- Filter page (`/search-filter` route) for salary/workplace/level/contract.

### Careers (recruiter) / Progress (candidate) — the 3rd bottom-nav tab
- **This tab is now role-branched**, per explicit instruction:
  - Candidate/student → label **"Progress"** → unchanged `GamesHubScreen`
    (cognitive games; this feature has no REC-04 equivalent, it's separate
    work already on this branch).
  - Recruiter → label **"Careers"** → ported `RecruiterHomePage`
    (`mobile/lib/features/jobs/`): "Your Tests" + "Your Job Offers" sections,
    each with a real create flow:
    - **Create job offer** wizard (position, workplace type, location,
      employment type, salary, description sub-page, hard-skills-test
      picker) → `POST /job-offers`. **Verified**: posted a real offer, it
      appeared in the list immediately.
    - **Create test** wizard (title, question count, per-question editor
      with 4 answers + correct-answer radio) → `POST /assessments`. **Verified**:
      created a real test, got a real shareable link back from the backend,
      detail page rendered correctly.
  - `AppStrings.tabProgress`/`tabCareers` + `AppBottomNav` now read the
    signed-in user's role to pick the label; `ProgressScreen` picks the
    widget the same way.

### Known gaps (visible placeholders, not silent failures)
- **Job offer detail page** (description/company/assessment tabs) and
  **hard-skills results page** — not ported yet. Tapping into an existing
  job offer or "results" shows a `_NotYetPortedPage` placeholder
  (`app_router.dart`) instead of crashing.
- **"Générer avec l'IA"** (AI test generation) — the merged backend doesn't
  expose `POST /assessments/generate` yet (tracked in
  `PLAN_FITSCORE_V3.md` Phase 0, ported from REC-04's Groq-backed version).
  The button is wired and will fail with a clear `ApiException` message
  rather than pretending to work.
- **Applications/candidate-progress tracking** (REC-04's
  `CandidateProgressPage`, a *different* thing from the Games "Progress" tab
  — it's the candidate's application-status list) — not ported. Not asked
  for this session; flagged in `docs/MOBILE_APP_COMPARISON.md` as a gap.

## 2. Backend changes made to support the port

Two backend fixes landed (committed, see §6):

1. **`f6936e9`** — `recruitment.actors` projection enriched with
   `fullName`/`avatarUrl`/`city`/`country` (via `UserAccessStateChangedEvent`,
   published live on register/role-change, replayed on boot). Wired into
   `GET /recruiters/me/candidate-feed` and `GET /*/matches`. Without this,
   candidate cards/match lists had no name to show — `MatchResponse
   .candidateName` was a permanent `null` before this fix.
2. **`9afe76c`** — demo password changed from `1234` to `zennyt123` because
   the *mobile app's own login form* rejects passwords under 6 characters
   client-side (before any network call). This was mistaken for a broken
   backend; it wasn't — curl to the backend with `1234` always worked.

## 3. How to resume — full environment bring-up

**This dev machine does not survive sleep/restart.** Docker, the backend
process, and the emulator all die together. Check before assuming anything
is running: `docker info`, `curl localhost:8080/actuator/health`,
`adb devices`.

```powershell
# 1. Start Docker Desktop (GUI), wait for `docker info` to succeed, then:
docker start zennyt-project-db-1   # data volume zennyt-project_pgdata persists

# 2. Fresh DB + boot the backend jar (already built at backend/target/zennyt-api-1.0.0.jar;
#    rebuild with `cd backend && ./mvnw -q package -DskipTests -o` if source changed)
docker exec zennyt-project-db-1 psql -U postgres -c "DROP DATABASE IF EXISTS zennyt_int WITH (FORCE)" -c "CREATE DATABASE zennyt_int"
# then boot on port 8080 (NOT 8081 — the Android emulator always resolves 10.0.2.2:8080):
#   java -jar backend/target/zennyt-api-1.0.0.jar --spring.profiles.active=dev
#     --spring.datasource.url=jdbc:postgresql://localhost:5433/zennyt_int
#   (env vars needed: DB_USER=postgres DB_PASSWORD=postgres RECRUITMENT_CALLBACK_SECRET=dev-secret
#    GROQ_API_KEY + JWT_ACCESS_TTL from repo-root .env)

# 3. Seed the 5 demo accounts (password is now `zennyt123`, not `1234`):
#    register each via POST /api/v1/auth/register, then SQL-pin their public_id to the
#    fixed UUIDs (11111111.../22222222... etc.) and password_hash to
#    $2a$12$ICQvy9treApWAg4ADVBe.Obtl7RoHSvzEI9cg8gnUr../B2tHNPgG (bcrypt of zennyt123),
#    then DELETE FROM recruitment.actors and restart the jar to replay the projection.
#    Full copy-pasteable script: docs/DEMO_INTEGRATION.md

# 4. Emulator + app
flutter emulators --launch zennyt_phone
cd mobile
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
```

Login: `recruiter1@zennyt.com` / `zennyt123` (Rania) or
`candidate1@zennyt.com` / `zennyt123` (Aicha), etc. — see
`docs/DEMO_INTEGRATION.md` for the full account list.

Full regression check: `cd tooling/bruno && npx @usebruno/cli run Demo --env Local`
→ expect 56/56 requests, 21/21 assertions.

### Driving the emulator without computer-use

The computer-use tool can't target the bare QEMU emulator window (no
Start-Menu app name to resolve it by). Use `adb` instead:
```
adb shell input tap X Y          # coordinates from a screenshot
adb shell input text "..."       # %s does NOT reliably mean space from bash — avoid multi-word in one call
adb exec-out screencap -p > out.png   # NOT `adb shell screencap ... > out.png` — that corrupts the PNG via CRLF translation on Windows
```

### Installing on a physical Android phone (no cable)

Built and verified this session:
```powershell
cd mobile
flutter build apk --debug --dart-define=API_BASE_URL=http://<PC-LAN-IP>:8080/api/v1
```
Debug builds have a permissive `network_security_config` (cleartext HTTP to
any host — see `android/app/src/debug/res/xml/network_security_config.xml`),
so plain `http://` to a LAN IP works without extra config.

To install without a cable: serve the built APK
(`build/app/outputs/flutter-apk/app-debug.apk`) over the LAN —
`python -m http.server 8090 --bind 0.0.0.0` from that folder — then open
`http://<PC-LAN-IP>:8090/app-debug.apk` in the phone's browser (same Wi-Fi),
download, and install (allow "install unknown apps" for the browser when
prompted). PC's Wi-Fi LAN IP this session was `192.168.1.15` — re-check with
`ipconfig` (look for "Carte réseau sans fil Wi-Fi"), it may differ.

**⚠️ The `python -m http.server` file server and the backend both died** when
the last session/machine reset — confirmed dead (`curl` to both returned
nothing/503) right before this recap was written. Both need restarting per
§3 before resuming the phone install.

If the phone can't reach the PC: Windows Firewall may block inbound
connections from other LAN devices. The user needs to run this themselves
(elevated PowerShell) — don't run it for them without asking:
```powershell
New-NetFirewallRule -DisplayName "Zennyt dev" -Direction Inbound -Protocol TCP -LocalPort 8080,8090 -Action Allow
```

## 4. Files touched this session (all uncommitted — see §6)

New feature code:
```
mobile/lib/features/fits/{data,domain,presentation/{providers,states,widgets}}/
mobile/lib/features/search/presentation/{pages,providers}/
mobile/lib/features/jobs/                          # entire feature, new
mobile/lib/features/auth/presentation/current_user_provider.dart
mobile/lib/shared/widgets/{custom_app_bar.dart,session_avatar.dart}
```
Modified:
```
mobile/lib/core/constants/app_strings.dart          # tabProgress/tabCareers split
mobile/lib/core/router/{app_router.dart,app_routes.dart}   # new routes for jobs/assessments
mobile/lib/features/fits/presentation/view/fits_screen.dart
mobile/lib/features/navigation/presentation/widgets/app_bottom_nav.dart
mobile/lib/features/progress/presentation/view/progress_screen.dart  # role branch
mobile/lib/features/search/presentation/view/search_screen.dart
mobile/pubspec.yaml / pubspec.lock                  # added `equatable` dependency
```
Also modified but **not part of this session's work** (pre-existing at
session start, left untouched — probably a prior abandoned attempt):
`mobile/lib/l10n/gen/app_localizations*.dart`,
`mobile/{linux,macos,windows}/**/generated_plugin*` — investigate before
committing/discarding.

## 5. Verified this session (adb screenshots)

- Fits: real swipe deck both roles, real match dialog.
- Search: real candidate/job-offer results with real fit scores.
- Careers: recruiter home with real "Your Tests"/"Your Job Offers".
- **Created a real job offer** ("QAAutomationEngineer") → appeared instantly.
- **Created a real test** ("QuickCheck", 1 question) → success sheet → real
  shareable link (`https://www.zennyt.com/tests/<uuid>`) → detail page.
- Progress: candidate role still shows Games hub, unaffected.
- `flutter analyze`: **zero errors**, only pre-existing style infos, across
  the whole project.

## 6. ⚠️ Outstanding / next steps

- **Nothing from this session is committed.** Review `git status` (43
  changed/new paths under `mobile/`), decide whether to split into commits
  (e.g. `feat: port Fits`, `feat: port Search`, `feat: port Careers +
  role-branch Progress tab`) — user has not requested a commit yet, ask
  before doing so.
- Two backend commits already landed on this branch, not pushed:
  `9afe76c` (password fix), `f6936e9` (actor enrichment). Check `git log`
  for the full picture; push only if asked.
- Environment is currently **fully down** (Docker/backend/emulator/file
  server) — bring up via §3 before continuing.
- Next logical scope, if continuing the port: job offer detail page (tabs:
  description/company/assessment) and hard-skills results page — both
  currently a `_NotYetPortedPage` stub. See `docs/MOBILE_APP_COMPARISON.md`
  for the REC-04 source file sizes (~756 + ~472 lines).
- The phone APK install was in progress when this session ended — user was
  about to try downloading it. Confirm whether they succeeded before
  rebuilding.

---

## Prompt to start the new conversation

> Read your memory first (MEMORY.md + zennyt-project-state.md), then read
> `RECAP_MOBILE_PORT.md` at the repo root — it covers the mobile frontend
> port (Fits/Search/Careers) from REC-04 onto `integration-recruitment-align`,
> done in the previous session, verified live but **not committed**. I want
> to <DESCRIBE NEXT TASK — e.g. "bring the environment back up and finish the
> phone APK install", "commit this work", "port the job offer detail page",
> "port the hard-skills results page">. Backend scope stays hexagonal-
> architecture + guardrail tests green; no Claude co-author trailer on
> commits.
