# Linking the two users (Candidate & Recruiter) to the recruitment flow

> **Purpose.** Companion to `BACKEND_WIRING.md` (endpoint wiring) and
> `BACKEND_WIRING_EXAMPLE.md` (one worked feature). Those two answer *"which HTTP call
> backs which screen."* **This file answers the other half of the question the recruitment
> flow depends on: _who is the logged-in user, what attributes do they carry, and how does
> that identity flow into every recruitment call so the right person acts as candidate vs
> recruiter."*
>
> Read this first if your goal is *"make the recruitment flow work for a real candidate and
> a real recruiter through the UI."*
>
> **Where to work:** only inside `mobile_preview/`. Do **not** touch the teammate's
> `mobile/` folder. **Do not push** — the owner will integrate from another conversation.

---

## 0. The whole thing in one sentence

**Identity owns *who you are* (UUID + role + profile). Recruitment owns *what you do*
(offers, swipes, matches, assessments). The bridge between them is a single value: the
user's UUID — issued by Identity as the JWT `sub` claim, and read by every recruitment
controller as the acting `candidateId` / `recruiterId`.**

```
 ┌─────────────────────────┐         JWT  sub = <uuid>          ┌──────────────────────────┐
 │        IDENTITY          │  ───────────────────────────────▶ │       RECRUITMENT        │
 │  (who you are)           │         role  = CANDIDATE          │  (what you do)           │
 │                          │              | RECRUITER           │                          │
 │  UserProfile  ──────────┐│                                    │  controller reads        │
 │  CandidateProfile       ││   Authorization: Bearer <jwt>      │  UUID.fromString(        │
 │  Role                    ││  (Phase A dev: X-Dev-User: <uuid>) │    principal.getName())  │
 └──────────────────────────┘                                    │  → that = candidateId    │
              │                                                   │     or recruiterId       │
              ▼                                                   └──────────────────────────┘
   Flutter sets appIsRecruiter = (role == RECRUITER)
   → drives every screen variant (center tab, home, careers, fits tabs…)
```

Consequences you must internalise (they shape every datasource you write):

1. **The client never sends its own id.** No request body carries `candidateId` /
   `recruiterId` *for the caller* — the backend derives it from the token/header. Bodies
   only ever carry the **other** party + context (offer id, target id, answers, otp…).
2. **One `role` value drives the entire UI.** `appIsRecruiter` (`lib/shared/app_mode.dart`)
   already exists and already flips the navigation/home/fits variants. Logging in = read
   the role once, set this flag once.
3. **The two users share almost all screens.** Home, Notifications, Search, Fits are shared;
   only the center tab differs (Progress for candidate, Careers for recruiter). So "linking
   both users" is mostly: *resolve identity → set one boolean → let the existing UI react.*

---

## 1. The two user types and their Identity attributes (side by side)

Source of truth: `contracts/identity.openapi.yaml`. Both users are the **same** `UserProfile`
shape; only the **role** and the **attached profile** differ.

### Common to both — `UserProfile` (`GET /users/me`)

| Attribute | Type | Meaning / use in app |
|---|---|---|
| `id` | uuid | **The bridge value.** Same UUID recruitment uses as `candidateId`/`recruiterId`. |
| `email` | string | Profile header, account screen. |
| `role` | `CANDIDATE \| RECRUITER \| ADMIN` | Sets `appIsRecruiter`; gates routes & tabs. |
| `isVerified` | bool | Email/identity verified badge; can gate sensitive actions. |
| `createdAt` | date-time | "Member since"; cosmetic. |

### Candidate — `UserProfile` **+** `CandidateProfile` (`GET/PUT /candidates/me`)

| Attribute | Type | Frontend screen that uses it |
|---|---|---|
| `userId` | uuid | = `UserProfile.id` = recruitment `candidateId`. |
| `firstName`, `lastName` | string | Profile header, candidate card name. |
| `phone` | string | Profile; OTP/SMS confirmation context. |
| `location` | string (`"Tunis, Tunisie"`) | Profile, candidate card location. |
| `bio` | string | Profile "about". |
| `photoUrl` | uri | Avatar everywhere (Fits card, profile, chat). |
| `cvUrl` | uri | Resume screen / "view CV". |
| `experienceYears` | int | Profile, candidate card. |
| `availability` | `IMMEDIATE \| ONE_MONTH \| THREE_MONTHS \| NOT_AVAILABLE` | Profile, recruiter's view of candidate. |
| `skills[]` | `Skill{ id, name, level }` | Profile skills chips; `level ∈ BEGINNER\|INTERMEDIATE\|ADVANCED\|EXPERT`. |

Candidate-only Identity endpoints to wire on the **Profile** screens (not the recruitment flow):
`PUT /candidates/me`, `POST /candidates/me/photo` (signed upload URL),
`GET/POST /candidates/me/skills`.

### Recruiter — `UserProfile` **only** (role = `RECRUITER`)

> ⚠️ **Gap to confirm with the Identity squad.** The current
> `contracts/identity.openapi.yaml` defines **no `RecruiterProfile` schema** — a recruiter
> is just a `UserProfile` with `role = RECRUITER`. There is **no** company name / logo /
> recruiter bio endpoint today.
>
> In the recruitment domain, company identity lives **on each job offer** instead
> (`JobOfferResponse.companyName`, `companyInfo`), not on a recruiter profile object. So:
> - For the recruiter's **own** screens, you only have `id`, `email`, `role`, `isVerified`.
> - "Company" shown on cards comes from the **offer**, not the recruiter.
>
> **Action:** if the designs need a recruiter/company profile (logo, company description,
> website), raise it with Identity — it's not in the contract yet. Until then, keep those
> fields mock and source company display data from the job offer.

---

## 2. How identity reaches the backend — the two phases

The two phases are identical for **every recruitment datasource**; only the auth header
differs. See `BACKEND_WIRING.md` §1–§3 for the full version. Summary keyed to *identity*:

| | **Phase A — works NOW** | **Phase B — after Identity merge** |
|---|---|---|
| Who am I | header `X-Dev-User: <uuid>` | `Authorization: Bearer <jwt>` (token's `sub` = uuid) |
| Role source | the app's `appIsRecruiter` toggle (manual) | `GET /users/me` → `role` (authoritative) |
| Login screen | none — pick a seeded user | real `POST /auth/login` / `POST /auth/register` |
| Profile data | mock | Identity `GET /users/me`, `GET /candidates/me` |

You can prove the **whole recruitment flow for both users today** in Phase A, then change
**one interceptor** for Phase B.

---

## 3. Test BOTH users right now (Phase A) — real seeded UUIDs

The backend `dev` profile seeds **fixed** identities (`DevDataSeeder.java`). Use these exact
UUIDs — they are the ones the demo data (offers, assessment, fit score) is attached to:

| User | Seeded UUID | Owns / sees |
|---|---|---|
| **Recruiter** | `11111111-1111-1111-1111-111111111111` | the 3 demo ACTIVE offers + the demo assessment |
| **Candidate** | `22222222-2222-2222-2222-222222222222` | browses those offers, swipes, applies, takes the test |

> ⚠️ **Correction to `BACKEND_WIRING.md` §3:** that example used placeholder UUIDs
> (`00000000-…-0001/0002`). The **real** seeded values are the two above — use these so the
> demo offers/assessment/fit-score actually resolve.

### The dev identity interceptor (switches user by the app toggle)

```dart
// lib/core/network/dev_identity_interceptor.dart
import 'package:dio/dio.dart';
import '../../shared/app_mode.dart'; // ValueNotifier<bool> appIsRecruiter

/// Phase A only. Impersonates the seeded recruiter or candidate based on the
/// in-app mode toggle, so you can walk the whole recruitment flow without login.
class DevIdentityInterceptor extends Interceptor {
  static const recruiterId = '11111111-1111-1111-1111-111111111111';
  static const candidateId = '22222222-2222-2222-2222-222222222222';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Dev-User'] =
        appIsRecruiter.value ? recruiterId : candidateId;
    handler.next(options);
  }
}
```

Register it in `lib/core/di/injection.dart` right after Dio is created (see
`BACKEND_WIRING_EXAMPLE.md` "The auth header (Phase A)"). Flip the in-app recruiter/candidate
toggle to switch which seeded user you act as — every recruitment call follows automatically.

---

## 4. The frontend identity model to build (Phase B)

Right now `features/auth/` and `features/profile/` are **empty skeletons** (only `.gitkeep`),
and identity is faked by the `appIsRecruiter` boolean. To make real users work, add a thin
identity layer. Keep it minimal — recruitment screens don't need the full profile, only the
**role** + the **current user id** (and the id is implicit server-side).

### 4.1 Domain — a `CurrentUser` entity

```dart
// features/auth/domain/entities/current_user.dart
enum UserRole { candidate, recruiter, admin }

class CurrentUser {
  final String id;        // = JWT sub = recruitment candidateId/recruiterId
  final String email;
  final UserRole role;
  final bool isVerified;
  const CurrentUser({
    required this.id,
    required this.email,
    required this.role,
    required this.isVerified,
  });

  bool get isRecruiter => role == UserRole.recruiter;
}
```

### 4.2 Map Identity `role` string → enum → the existing UI flag

```dart
UserRole roleFromApi(String r) => switch (r) {
      'RECRUITER' => UserRole.recruiter,
      'ADMIN'     => UserRole.admin,
      _           => UserRole.candidate,
    };

// The ONE line that lights up the whole UI after login / on app start:
appIsRecruiter.value = currentUser.isRecruiter;
```

`appIsRecruiter` (`lib/shared/app_mode.dart`) is already consumed by `AppBottomNav` and the
home/notifications/fits variants. Setting it once = both user experiences work. No screen
needs to know the user's id — the backend derives it from the token.

### 4.3 Login + bootstrap (minimal)

```dart
// features/auth/data/auth_remote_datasource.dart
Future<CurrentUser> login(String email, String password) async {
  final t = await dio.post('/auth/login', data: {'email': email, 'password': password});
  await storage.write(key: 'access_token',  value: t.data['accessToken']);
  await storage.write(key: 'refresh_token', value: t.data['refreshToken']);
  final me = await dio.get('/users/me'); // UserProfile
  return CurrentUser(
    id: me.data['id'],
    email: me.data['email'],
    role: roleFromApi(me.data['role']),
    isVerified: me.data['isVerified'] == true,
  );
}
```

> **Storage keys must be exactly `access_token` / `refresh_token`** — that is what the
> already-present `AuthInterceptor` (`lib/core/network/dio_client.dart`) reads to attach the
> Bearer header and to refresh on 401. Get those keys right and auth "just works" with zero
> extra code.

### 4.4 App-start & route guard

- On launch: if a token exists → call `GET /users/me` → build `CurrentUser` → set
  `appIsRecruiter` → go to `/home`. Else → `/auth/login`.
- `GET /candidates/me` (candidate only) backs the Profile screen; recruiter Profile uses
  `UserProfile` only (see the gap in §1).
- The router guard stub already exists in `lib/core/router/app_router.dart` (`redirect:`).

---

## 5. The recruitment flow, per user — which identity acts, with which attributes

This is the same endpoint set as `BACKEND_WIRING.md` §4, re-cut by **actor** so you can see
the two journeys end to end. "Actor id" is always implicit (header/token) — never in the body.

### 5.1 Candidate journey (acts as `candidateId` = the seeded `2222…` in Phase A)

| Step / screen | Endpoint | Body carries (NOT the actor) | Identity attrs shown |
|---|---|---|---|
| Browse offers (Fits / Search) | `GET /job-offers?…` | — | offer's `companyName`, location |
| Swipe LIKE/PASS an offer | `POST /swipes` | `targetId=offerId, targetType=JOB_OFFER, direction` | — |
| See matches | `GET /candidates/me/matches` | — | recruiter side of match |
| Open job detail | `GET /job-offers/{id}` | — | full offer |
| Apply | `POST /applications` | `jobOfferId` | — |
| Take assessment → submit | `POST /assessment-attempts` | `assessmentId, jobOfferId, answers[]` | score returned |
| Receive opportunity → confirm | `POST /job-opportunity-offers/{id}/confirm` | — | recruiter/offer |
| OTP popup → verify | `POST /job-opportunity-offers/{id}/verify-otp` | `otpCode` | candidate `phone` (Identity) |
| Reject opportunity | `POST /job-opportunity-offers/{id}/reject` | — | — |
| Profile screen | `GET /candidates/me` (Identity) | — | **all** `CandidateProfile` fields |

### 5.2 Recruiter journey (acts as `recruiterId` = the seeded `1111…` in Phase A)

| Step / screen | Endpoint | Body carries (NOT the actor) | Identity attrs shown |
|---|---|---|---|
| Your job offers (Careers) | `GET /recruiters/me/job-offers?…` | — | own offers |
| Create offer → publish | `POST /job-offers` then `PATCH /job-offers/{id}/status` | offer fields; `status=ACTIVE` | `companyName` is on the offer |
| Your tests | `GET /assessments/mine` | — | — |
| Create test | `POST /assessments` | `title, questions[]` | — |
| Hard-skill scores | `GET /assessment-attempts?jobOfferId={id}` | — | candidate `score/passed` |
| Candidate fit % | `GET /fit-scores?candidateId={id}&jobOfferId={id}` | — | the % badge |
| Send opportunity to candidate | `POST /job-opportunity-offers` | `candidateId, jobOfferId` | candidate name/photo (Identity) |
| Pay for video call | `POST /payments` + `POST /payments/{id}/verify-otp` | `candidateId, matchId, card…`; `otpCode` | — |
| Anti-fraud identity check | `POST /identity-verifications` → `GET /identity-verifications/{id}` | `candidateId, jobOfferId` | candidate verification status |

> Note the **asymmetry**: a recruiter→candidate swipe and the opportunity/payment/verify
> calls **do** include the *candidate's* id in the body (that's the *other* party), plus a
> required `jobOfferId` on recruiter→candidate swipes. The recruiter's own id is still
> implicit. Candidate→offer calls carry no candidate id at all.

---

## 6. Where each displayed attribute comes from (don't double-source)

| UI element | Comes from | Context |
|---|---|---|
| Logged-in user's name/photo/bio/skills | **Identity** `CandidateProfile` | candidate only |
| Logged-in recruiter's name/email | **Identity** `UserProfile` | no company profile (gap §1) |
| Company name / logo on a job card | **Recruitment** `JobOfferResponse.companyName` / `companyInfo` | the offer, not the recruiter |
| The other candidate's name/photo (recruiter view) | **Identity** profile of that `candidateId` | via match/opportunity |
| Role-based tab/home variant | `appIsRecruiter` ← Identity `role` | set once at login |
| Fit % | **Recruitment** `GET /fit-scores` | separate call, not on offer or profile |

Rule of thumb: **person attributes → Identity; job/company/match/score attributes →
Recruitment.** The only join key between the two systems is the **UUID**.

---

## 7. Gotchas specific to identity wiring

- **Never put the caller's id in a body.** It comes from `X-Dev-User` (A) / Bearer (B).
  (`tooling/bruno/PARAMETERS.md` "golden rule".)
- **Role is authoritative from Identity, not user choice.** In Phase B set `appIsRecruiter`
  from `GET /users/me`, not from a UI toggle. (OAuth first-login uses `PATCH /users/me/role`
  to pick candidate/recruiter once.)
- **Recruitment uses `ON_SITE`; Identity uses `ONSITE`.** Different contexts, no clash —
  use each context's own spelling when calling that context.
- **`X-Dev-User` disappears after the Identity merge** (`docs/IDENTITY_INTEGRATION_PLAN.md`
  §6). Hardcode the seeded UUIDs **only** in `DevIdentityInterceptor`, nowhere else.
- **No `RecruiterProfile` yet** (§1) — don't invent endpoints; flag the need to Identity.

---

## 8. Checklist — "both users working through the recruitment flow"

- [ ] Backend `dev` running; base URL wired (`BACKEND_WIRING.md` §2).
- [ ] **Phase A:** add `DevIdentityInterceptor` with the **real** seeded UUIDs (§3).
- [ ] Toggle = candidate → walk §5.1 (browse → swipe → apply → assessment → confirm → OTP).
- [ ] Toggle = recruiter → walk §5.2 (create offer → publish → test → scores → opportunity).
- [ ] Confirm each call works with the actor id implicit (no id in body).
- [ ] **Phase B (after Identity merge):** build `features/auth` (login/register), add
      `CurrentUser` (§4), set `appIsRecruiter` from `GET /users/me`, enable the router guard,
      drop `DevIdentityInterceptor`.
- [ ] Wire candidate **Profile** to Identity `GET/PUT /candidates/me`, skills, photo.
- [ ] Raise the **RecruiterProfile gap** with Identity if designs need company profile data.

---

## 9. Reference files

- Endpoint → screen catalogue, field maps, enums: `BACKEND_WIRING.md`
- One feature wired end-to-end (copy-paste): `BACKEND_WIRING_EXAMPLE.md`
- Identity attributes (authoritative): `contracts/identity.openapi.yaml`
- Recruitment contract: `contracts/recruitment.openapi.yaml`
- Identity↔recruitment merge plan (X-Dev-User removal, security): `docs/IDENTITY_INTEGRATION_PLAN.md`
- Seeded dev identities/data: `backend/.../infrastructure/DevDataSeeder.java`
- Param rules / golden rule: `tooling/bruno/PARAMETERS.md`
- Role↔UI flag: `mobile_preview/lib/shared/app_mode.dart`
- Network layer (AuthInterceptor, keys): `mobile_preview/lib/core/network/dio_client.dart`
- DI to edit: `mobile_preview/lib/core/di/injection.dart`
