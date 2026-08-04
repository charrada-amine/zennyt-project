# Wiring the Flutter app (`mobile_preview/`) to the real backend + Identity auth

> **Purpose.** This is a self-contained handoff for the conversation/dev that will
> replace the **mock datasources** in the Flutter app with **real HTTP calls** to the
> Zennyt backend, using the **Identity team's** authentication (real users, real JWT),
> so the **recruitment flow works end-to-end through the UI**.
>
> **Where to work:** only inside `mobile_preview/` (the working copy). Do **not** touch
> the teammate's `mobile/` folder. Nothing here should be pushed unless the owner says so.
>
> **What already exists:**
> - A complete Flutter UI (Clean Architecture: domain / data / presentation, flutter_bloc,
>   get_it, go_router, dio, dartz) with **mock** datasources for every screen.
> - A backend **Recruitment API** (Spring Boot 3 / Java 21) that runs standalone today with a
>   **dev auth simulation** (`X-Dev-User` header) — see `tooling/bruno/PARAMETERS.md`.
> - An **Identity API** (separate squad) that issues real JWTs — contract in
>   `contracts/identity.openapi.yaml`. Merge plan in `docs/IDENTITY_INTEGRATION_PLAN.md`.

---

## 0. The one fact that makes this easy

Identity issues a JWT whose **`sub` claim = the user's public UUID**, and the recruitment
controllers already read the caller as `UUID.fromString(principal.getName())` — i.e. that
same `sub`. So:

- **`candidateId` / `recruiterId` are never sent by the client.** The backend derives them
  from *who you are* (the token, or in dev the `X-Dev-User` header).
- The Flutter client only ever sends **the other party + context** (offer id, target id, answers…).
- A user's **role** (`CANDIDATE` / `RECRUITER` / `ADMIN`) comes from Identity (`GET /users/me`
  or the JWT `role` claim). In the app this maps directly to the existing global flag
  `appIsRecruiter` (`lib/shared/app_mode.dart`).

---

## 1. Two phases — pick where you are

The backend on this branch (`feature/REC-01-...`) runs **recruitment only**, with the
`X-Dev-User` dev simulation (no login). The full auth only exists once the Identity branch
is merged (`docs/IDENTITY_INTEGRATION_PLAN.md`). So wire in two phases:

| | **Phase A — works NOW** | **Phase B — after Identity merge** |
|---|---|---|
| Backend | recruitment standalone, `dev` profile | merged monolith (recruitment + identity) |
| "Who am I" | header `X-Dev-User: <uuid>` | header `Authorization: Bearer <jwt>` |
| Login screen | not needed (pick a seeded UUID) | real `POST /auth/login` |
| Goal | prove the recruitment flow over HTTP | production-shaped auth |

**The remote datasources you write are identical in both phases** — only the auth header
changes (one interceptor). Build Phase A first; flip to Phase B by swapping the interceptor.

---

## 2. Step 0 — run the backend and point the app at it

1. Start Postgres + the API (see `TRY_IT.md`):
   ```bash
   # Postgres on 5433 (avoids a local 5432), schema "recruitment"
   docker compose -f backend/docker-compose.yml up -d   # or your local compose
   cd backend && ./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
   ```
   API base path is **`/api/v1`** (e.g. `http://localhost:8080/api/v1/job-offers`).

2. Add the base URL to the app config. The DI already builds Dio from a base URL
   (`lib/core/network/dio_client.dart`). Set it per platform:

   | Run target | Base URL |
   |---|---|
   | Chrome / Windows desktop | `http://localhost:8080/api/v1` |
   | Android emulator | `http://10.0.2.2:8080/api/v1` |
   | Physical phone | `http://<your-LAN-ip>:8080/api/v1` |

   Pass it via `--dart-define=API_BASE_URL=...` and read with
   `const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080/api/v1')`
   in `lib/core/di/injection.dart` where Dio is created.

3. **CORS for Chrome:** the backend dev profile must allow the Flutter web origin
   (`http://localhost:<port>`). If you get CORS errors, add the origin to the backend
   `SecurityConfig`/`CorsConfiguration` (dev only), or run on Windows/Android instead of web.

---

## 3. Step 1 — authentication (the only auth-specific code)

### Phase A — dev identity header (do this first)

The recruitment API in `dev` reads `X-Dev-User: <uuid>`. Add **one** Dio interceptor that
injects the current actor's UUID based on the app mode flag. The dev seeder
(`backend/.../DevDataSeeder.java`) creates fixed candidate/recruiter UUIDs — copy them.

```dart
// lib/core/network/dev_identity_interceptor.dart
import 'package:dio/dio.dart';
import '../../shared/app_mode.dart';   // ValueNotifier<bool> appIsRecruiter

class DevIdentityInterceptor extends Interceptor {
  // Real fixed UUIDs seeded by DevDataSeeder.java (the demo offers/assessment/
  // fit-score are attached to these). See IDENTITY_USER_LINKING.md §3.
  static const _recruiterId = '11111111-1111-1111-1111-111111111111';
  static const _candidateId = '22222222-2222-2222-2222-222222222222';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Dev-User'] =
        appIsRecruiter.value ? _recruiterId : _candidateId;
    handler.next(options);
  }
}
```
Register it on the Dio instance instead of (or in dev, alongside) `AuthInterceptor`.

### Phase B — real JWT login

The existing `AuthInterceptor` (`lib/core/network/dio_client.dart`) **already** does the
production behaviour:
- reads `access_token` from `flutter_secure_storage`, attaches `Authorization: Bearer …`;
- on **401**, calls `POST /auth/refresh` with `{refreshToken}`, stores the new
  `accessToken`/`refreshToken`, and replays the request once.

This matches Identity's `AuthTokens` schema exactly (`accessToken`, `refreshToken`,
`tokenType`, `expiresIn` — see `contracts/identity.openapi.yaml`). So Phase B is just:

1. Build a tiny **auth feature** (the skeleton folder exists, currently empty):
   - `POST /auth/login` `{email, password}` → store `accessToken` under key **`access_token`**
     and `refreshToken` under **`refresh_token`** (the exact keys `AuthInterceptor` reads).
   - `POST /auth/register` `{email, password, role, firstName, lastName}` → same.
2. After login, call `GET /users/me` → read `role` → set
   `appIsRecruiter.value = (role == 'RECRUITER')`. This drives the whole UI (center tab,
   home/notifications variants) automatically.
3. Add the route guard in `lib/core/router/app_router.dart` (the `redirect:` is already
   stubbed with a comment): if no token → go `/auth/login`.
4. Remove `DevIdentityInterceptor`; keep `AuthInterceptor`.

> **Identity user attributes** (from `contracts/identity.openapi.yaml`):
> `UserProfile { id(uuid), email, role(CANDIDATE|RECRUITER|ADMIN), isVerified, createdAt }`
> and `CandidateProfile { userId, firstName, lastName, phone, location, bio, photoUrl,
> cvUrl, experienceYears, availability, skills[] }`. `id`/`userId` is the same UUID the
> recruitment API uses as `candidateId`/`recruiterId`. Wire the **Profile** and
> **Candidate Profile** screens to these once available.

---

## 4. Step 2 — replace each feature's mock with a real remote datasource

Pattern per feature (keep domain entities + bloc untouched; only swap the data layer):

1. Create `…/data/datasources/<feature>_remote_datasource.dart` taking the shared `Dio`.
2. Call the endpoint(s) in the table below, map JSON → existing entity (see field maps).
3. In `lib/core/di/injection.dart`, change the repository registration to use the **remote**
   datasource instead of the mock. **Nothing else changes** — blocs/pages already consume
   the repository via get_it.

### Recruitment flow coverage (build these — backend exists)

| Flutter screen / feature | HTTP call(s) | Notes |
|---|---|---|
| **Fits — Job Offers tab** (swipe deck) | `GET /job-offers?q=&location=&contractType=&experienceLevel=&page=&size=` | candidate browsing offers |
| **Fits — swipe LIKE/PASS** | `POST /swipes` `{targetId: offerId, targetType:"JOB_OFFER", direction:"LIKE"\|"PASS"}` | match created when both sides LIKE |
| **Fits — match banner** | `GET /candidates/me/matches` | poll/refresh after a like |
| **Search — Job Offers** | `GET /job-offers?q=…` | same source as Fits offers |
| **Job Detail** | `GET /job-offers/{id}` | pass the offer id via `state.extra` |
| **Job Detail → Apply** | `POST /applications` `{jobOfferId}` | candidate |
| **Assessment test → submit** | `POST /assessment-attempts` `{assessmentId, jobOfferId, answers:[int]}` | candidate; score returned |
| **Careers — Your Job Offers** | `GET /recruiters/me/job-offers?status=&page=&size=` | recruiter |
| **Add Job Offer → publish** | `POST /job-offers` `{title, description, contractType, workplaceType, experienceLevel, locationCity, locationCountry, locationRemote, …}` then `PATCH /job-offers/{id}/status {status:"ACTIVE"}` | recruiter |
| **Careers — Your Tests / My tests** | `GET /assessments/mine?page=&size=` | recruiter |
| **Create test / Add questions → save** | `POST /assessments` `{title, questions:[{text, options[4], correctOptionIndex}]}` | recruiter |
| **Hard Skills Scores list** | `GET /assessment-attempts?jobOfferId={id}&page=&size=` | recruiter; `score`, `passed`, `integrityStatus` |
| **Candidate fit % badge** | `GET /fit-scores?candidateId={id}&jobOfferId={id}` | the % shown on cards/profile |
| **Job Opportunity card → send** | `POST /job-opportunity-offers` `{candidateId, jobOfferId}` | recruiter |
| **Conversation → Confirm offer** | `POST /job-opportunity-offers/{id}/confirm` | candidate |
| **Confirmation SMS popup → Continue** | `POST /job-opportunity-offers/{id}/verify-otp` `{otpCode}` | candidate (the 6-digit OTP screen) |
| **Reject opportunity** | `POST /job-opportunity-offers/{id}/reject` | candidate |
| **Video call → pay** | `POST /payments` `{candidateId, matchId, cardLast4, cardType}` then `POST /payments/{id}/verify-otp {otpCode}` | recruiter |
| **Identity verification (anti-fraud)** | `POST /identity-verifications` `{candidateId, jobOfferId}` → `GET /identity-verifications/{id}` | recruiter |

### Field mapping — `JobOfferResponse` → `FitItem` / job entities

Backend JSON (from `JobOfferResponse.java`):
`id, recruiterId, title, companyName, locationCity, locationCountry, locationRemote,
salaryMin, salaryMax, salaryCurrency, contractType, workplaceType, experienceLevel,
fieldOfWork, description, responsibilities, minimumQualifications, preferredQualifications,
whatWeOffer, howToApply, companyInfo, assessmentIds[], openToInternational, status, postedAt`

| Flutter field | From backend |
|---|---|
| `role` / job title | `title` |
| `company` / `name` | `companyName` |
| `location` | `"$locationCity, $locationCountry"` (`Remote` if `locationRemote`) |
| `salary` | `"$salaryMin–$salaryMax $salaryCurrency"` |
| `about` / description | `description` (+ the rich sections for Job Detail) |
| `tags` | derive from `contractType`, `workplaceType`, `experienceLevel`, `fieldOfWork` |
| `fitScore` (the %) | **separate call** `GET /fit-scores?candidateId&jobOfferId` (not on the offer) |

### Enum values (send these exact strings — anything else → HTTP 400)

- **ContractType:** `FULL_TIME, PART_TIME, CONTRACT, TEMPORARY, APPRENTICESHIP, VOLUNTEER`
- **WorkplaceType:** `ON_SITE, REMOTE, HYBRID, FLEXIBLE`
- **ExperienceLevel:** `JUNIOR, SENIOR, LEAD, MANAGER`
- **JobOfferStatus:** `DRAFT, ACTIVE, HIDDEN, CLOSED`
- **ApplicationStatus:** `PENDING, SHORTLISTED, APPROVED, REJECTED`
- **SwipeDirection:** `LIKE, PASS` — **targetType:** `JOB_OFFER, CANDIDATE`

---

## 5. Screens that have NO recruitment backend (keep mock for now)

These belong to the **Engagement** context (not built) or aren't exposed by recruitment.
Leave them on mock datasources and note it:

- **Home feed** (social posts), **Notifications**, **Chat list / messages / video call UI**
  → Engagement context — no endpoints yet.
- **Fits — "Professionnels" tab** (recruiter swiping candidates): there is no public
  candidate-search endpoint in recruitment. The *write* side works
  (`POST /swipes` with `targetType:"CANDIDATE"`, `jobOfferId` required), but the *list* of
  candidates to show must stay mock until a candidate-feed endpoint exists.
- **Assessment test — the questions themselves:** `GET /assessments/{id}` returns metadata;
  the MCQ **question text/options are not returned** by the API today (only stored). Keep the
  question UI on mock data, but submit real answers to `POST /assessment-attempts`. (Flag this
  gap to the backend owner — the test-taking screen needs a "get questions" response.)
- **Resume AI / Industry sectors:** AI summaries are mock; candidate profile data can come
  from Identity's `CandidateProfile` once merged.

---

## 6. Gotchas / coordination

- **Don't send `candidateId`/`recruiterId` for the actor** — it comes from the header/token.
  Body carries only the *other* party + context (`PARAMETERS.md` "golden rule").
- **Recruiter→candidate swipe** requires `jobOfferId` in the body; candidate→offer does not.
- **Matches are two-sided** — a single LIKE does not create a match; refresh
  `GET /candidates/me/matches` after liking.
- **`X-Dev-User` disappears after the Identity merge** — see §6 of
  `docs/IDENTITY_INTEGRATION_PLAN.md`. Don't hardcode it anywhere except the dev interceptor.
- **Secure-storage keys must be exactly** `access_token` / `refresh_token` (what
  `AuthInterceptor` reads).
- **Enum spelling:** recruitment uses `ON_SITE`; Identity's own context uses `ONSITE` — they
  don't clash, but use recruitment's spelling when calling recruitment endpoints.

---

## 7. Execution checklist

- [ ] Backend running (`dev`), base URL wired via `--dart-define` (§2).
- [ ] **Phase A:** add `DevIdentityInterceptor`, paste real seeded UUIDs (§3).
- [ ] Fits offers: remote datasource on `GET /job-offers`, map to `FitItem` (§4).
- [ ] Swipe: `POST /swipes`; refresh matches.
- [ ] Job detail + apply: `GET /job-offers/{id}`, `POST /applications`.
- [ ] Assessment submit: `POST /assessment-attempts`.
- [ ] Careers offers/tests: `GET /recruiters/me/job-offers`, `GET /assessments/mine`.
- [ ] Create offer / create test: `POST /job-offers` (+ status `ACTIVE`), `POST /assessments`.
- [ ] Scores: `GET /assessment-attempts?jobOfferId=…`; fit %: `GET /fit-scores`.
- [ ] Opportunity offer + OTP: `POST /job-opportunity-offers`, `/confirm`, `/verify-otp`.
- [ ] Swap DI registrations mock → remote for each wired feature.
- [ ] `flutter analyze` → 0 errors; manual click-through of the recruitment flow.
- [ ] **Phase B (when Identity merged):** build auth feature (login/register), `GET /users/me`
      → set `appIsRecruiter`, enable the router auth guard, drop `DevIdentityInterceptor`.

---

## 8. Reference files

- Endpoint catalogue + param rules: `tooling/bruno/PARAMETERS.md`
- Identity contract (auth, tokens, profiles): `contracts/identity.openapi.yaml`
- Recruitment contract: `contracts/recruitment.openapi.yaml`
- Backend↔Identity merge plan (Flyway, security, X-Dev-User removal): `docs/IDENTITY_INTEGRATION_PLAN.md`
- Run/test the backend locally: `TRY_IT.md`
- Working Bruno collection (every call, ready to copy headers/bodies): `tooling/bruno/`
- Flutter network layer to reuse: `mobile_preview/lib/core/network/dio_client.dart`
- DI to edit when swapping datasources: `mobile_preview/lib/core/di/injection.dart`
- App-mode flag (role ↔ UI): `mobile_preview/lib/shared/app_mode.dart`
