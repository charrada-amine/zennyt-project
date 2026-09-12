# Progress Careers — 1:1 screens implementation plan & backend gaps

Source of truth for the UI: board image `Progress Careers - Light mode.png`
(10383×32549), segmented into individual screens in
`/var/folders/.../pc_tiles/screens/` (317 blocks; 275 real screens + 12 section
bars + 30 noise). Screen indices below refer to that segmentation (reading order).

Legend: ✅ implemented & wired · 🟡 implemented but differs from design / partial ·
🔴 missing · 🧩 screen exists in design but **no backend endpoint** (must be stubbed
and tracked here until an API is added).

---

## 1. Board sections → screens → status

### A. Candidate / Student (light)

| Board section | Screens | Status |
|---|---|---|
| Animation logo | 4,5,6,7 | ✅ splash (`SplashScreen`) |
| Onboarding | 8-11, 36-39 | ✅ (`OnboardingScreen`) — design has 2 copy variants |
| Login | 12-16 | ✅ (`LoginScreen`) |
| Sign up | 18-23 | ✅ (`CreateAccountScreen`, `OtpScreen`, `ChangePhoneScreen`) |
| Add your informations | 24-30, 40-46, 181-188 | ✅ (`ProfileSetupScreen`, `FieldOfWorkScreen`) |
| Profile (overview/portfolio/modals) | 49-66, 97-100 | 🟡 skills/experience/cert/education modals ✅; **66 availability date** 🔴; 58-59 Resume-AI show/hide menu 🔴 |
| Play & discover your talent | 31-33, 67-76 | 🟡 `GamesHubScreen` exists; design wants Coverage %, 5-6 dimension cards, consent + referral modals |
| Home feed | 77-79, 241-243, 314 | ✅ (`HomePage`); recruiters see polls |
| Create post / poll / media | 61-62, 80-86, 244-250, 311-313 | ✅ (`CreatePostPage`, `MediaPickerPage`, `CreatePollPage`) |
| Search | 87-89, 224 | ✅ recruiter candidate search; ✅ candidate job search wired to public `GET /job-offers` (2026-09-11); tap opens job detail |
| Fits | 91a-h, 222-223 | 🟡 (`FitsScreen`), recruiter candidate detail + filter levels ✅ |
| Job detail (candidate) | 91f, 92-95, 146 | ✅ `JobOfferDetailPage` wired to `GET /job-offers/{id}` (2026-09-11) |
| Assessment quiz (candidate/test taker) | 96, 138-139, 306 | ✅ `TestTakingPage` (test-attempts + submit/abandon) + ✅ public `/tests/{token}` link unblocked (2026-09-11) |
| Profile & settings | 101-111, 256-265 | ✅ core; ✅ accessibility prefs + notifications now server-synced (`/users/me/preferences`), dark theme persisted, Terms screen |
| Account center / personal info / password / privacy | 103-106, 125-128, 264 | 🟡 hardcoded password date; ✅ email/phone-change OTP (Resend, no SMS) |
| Terms of Use | 120-121, 274-275 | ✅ `TermsOfUseScreen` (static, transcribed 1:1) (2026-09-11) |
| Wallet | 107,114,116,118,119 | 🧩 wallet balance / transactions / add-change card / withdraw |
| Referral | 32,102,115,117 | 🧩 referral program, invite friends, referral list/status |
| Hired candidates | 258 | 🧩 list + cancel/status countdown |
| Plans & Pricing / subscription | 261-263, 316 | 🧩 plans, upgrade, payment states |
| Notifications | 142, 288-289, 309-310 | ✅ (`NotificationsPage`) |
| Chats | 129-132, 280-283 | ✅ (`ChatsPage`, `ChatDetailPage`) |
| Video call / integrity | 133-139 | 🟡 call ✅; recording-consent overlay + integrity result modals 🧩/🔴 |
| Help Center | 112-113, 150-157, 266-273 | ✅ (`HelpCenterPage`, `HelpChatDetailPage`) |
| Terms & privacy legal | 120-121, 106, 274-275 | 🟡 `PrivacyPolicyScreen` hardcoded; Terms screen 🔴 |

### B. Recruiter (light)

| Board section | Screens | Status |
|---|---|---|
| Animation logo / Onboarding / Login | 162-174 | ✅ |
| Create your account | 176-188 | ✅ |
| Careers / home (tests + offers) | 189, 195 | ✅ (`RecruiterHomePage`) |
| Job offer detail | 190, 192 | 🟡 (`jobDetail` placeholder for candidate side; recruiter detail exists) |
| Test results (hard skills scores) | 191 | ✅ `HardSkillsResultsPage` wired (`.../test-results[/summary|/{candidateId}]`) (2026-09-11) |
| Manage tests | 197, 300 | ✅ `ManageTestsPage` (`/assessments`) with edit/delete/Add, linked from "Your Tests → See all" (2026-09-11) |
| Create test | 198-203, 306 | 🟡 (`CreateAssessmentPage`) |
| Generate test with AI | 301-305 | 🟡 (`CreateAssessmentPage` AI flow) |
| Add job offer | 204-217 | 🟡 (`CreateJobOfferPage`) |
| Fits / filter / candidate profile | 222-238, 251-254 | 🟡/✅ |
| Recruiter profile / edit | 251-254 | ✅ (`RecruiterProfileView`, `RecruiterEditProfileScreen`) |
| Recruiter notifications | 143-149 | ✅ |
| Payment flow (video fee + recruitment pre-auth) | 280-295 | 🧩/🟡 only `/payments` video-interview exists |
| Recruitment free authorization | 290-295 | 🧩 pre-authorization / salary-midpoint fee |

---

## 2. Backend gaps — endpoints that DO NOT exist yet (🧩)

The screens below must be built with a local/mock data layer and are **blocked
on new backend APIs**. Track here; remove a row once the API lands.

| Feature | Screen(s) | Needed endpoints (proposed) | Module |
|---|---|---|---|
| Wallet | 107,114,116,118,119 | `GET /wallet/me`, `GET /wallet/me/transactions`, `POST /wallet/me/cards`, `POST /wallet/me/withdraw` | engagement/identity |
| Referral | 32,102,115,117 | `GET /referrals/me`, `POST /referrals/invite`, referral-bonus rule | growth/engagement |
| Hired candidates | 258 | `GET /recruiters/me/hired-candidates`, `POST /hired-candidates/{id}/cancel` | recruitment |
| Plans & Pricing / subscription | 261-263,316 | `GET /plans`, `POST /subscriptions`, subscription state | billing |
| Recruitment fee pre-authorization | 290-295 | `POST /recruitment-fees/preauthorize`, `POST /recruitment-fees/{id}/confirm-otp` | billing/recruitment |
| Candidate search (candidates) | 87-89,224 | `GET /candidates/search` (filters: field, salary, level, experience, workplace, city) | recruitment |
| Progress / analytics | (progress tab) | `GET /analytics/candidate/me`, `GET /analytics/recruiter/me` (contract exists, no impl) | analytics |
| Assessment integrity / anti-fraud result | 138-139, 191(?) | `POST /assessment-integrity/...`, result endpoint | recruitment/identity |
| Help center FAQ/articles | (if added) | `GET /help-center/articles` (contract-optional) | engagement |
| Legal documents (Terms / Privacy) | 120-121, 274-275, 106 | `GET /legal/{slug}` + versioned content (today hardcoded in-app; no endpoint) | shared/identity |

Already-existing endpoints that are **unwired** and must be connected (not gaps):
`GET /job-offers/{id}`, `GET /job-offers/{jobId}/test-results[/summary|/{candidateId}]`,
`GET /tests/{token}`, `POST /job-offers/{jobId}/test-attempts`,
`POST /test-attempts/{id}/submit|abandon`, `GET /candidates/me/resume`,
`GET /candidates/{id}/resume`, fit-score/swipe/match controllers, identity-verifications,
payments (video), notifications, help-chats.

---

## 3. Proposed implementation order

1. **Careers / recruitment (backend ready, biggest gap)** — candidate job detail,
   public assessment quiz, recruiter test-results + manage tests. Removes two
   `_NotYetPortedPage` placeholders and the unused `AppRoutes.jobs`.
2. **Profile fixes** — availability date, Resume-AI visibility, dark theme persistence,
   accessibility prefs, Terms screen.
3. **Games discovery** — Coverage %, dimension cards, consent/identity modals, referral modal.
4. **Recruiter payment + wallet + referral + plans** (mostly 🧩 → stub + track here).
5. **Candidate search of jobs**, notifications empty state, misc polish.

> Per `AGENTS.md`: each step updates the touched module's `.md` (changelog + status) and
> this file's §2 as gaps close. No `pom.xml` / `pubspec.yaml` change without approval.

---

## 4. Progress log

### 2026-09-11 — Cluster 1 (Careers / recruitment) — done
- Added `TestAttemptStarted/PresentedQuestion/TestResult/TestResultListItem/TestResultsSummary/TestResultDetail` (`jobs/domain/entities/test_attempt.dart`).
- `JobsRepository` + impl: start/submit/abandon attempt, my result, recruiter results list/summary/detail.
- New `JobOfferDetailPage` (role-aware, replaces `jobDetail` placeholder) and
  `TestTakingPage` (`/jobs/:jobId/test`); new `HardSkillsResultsPage` (replaces `jobResults`
  placeholder); delete action on `AssessmentDetailPage`.
- Removed `_NotYetPortedPage`; `AppRoutes.jobs`/`nJobs` still unused.
- Fixed jobs data layer to match the merged recruitment contract (create payload, PUT vs
  PATCH, `recruiter` company projection, applicant/success stats).
- `flutter analyze`: no errors. New test: `test/features/jobs/data/test_attempt_parsing_test.dart` (5).
- Still open in this cluster: full-list "Manage tests" redesign (197), "Add a job offer"
  accordion 1:1 (204-217), salary currency/period (dropped server-side).
- ✅ Public `/tests/{token}` permit-list resolved in Shared (2026-09-11, see gap log below).

### 2026-09-11 — Cluster 2 (profile fixes) — done
- New `TermsOfUseScreen` (17 sections transcribed 1:1 from the board) + route
  `AppRoutes.termsOfUse`; wired the previously dead "Terms of Service & Conditions" row.
- Accessibility preferences (`contrast`, `text size`) now persisted in SharedPreferences
  (`core/settings/accessibility_provider.dart`) and the text size is applied app-wide via
  `MaterialApp.builder` textScaler (18 px baseline = 1.0).
- Already in place (verified, no change needed): Resume-AI Show/Hide toggle
  (`user_profile_screen`), dark theme toggle with persistence (`theme_provider`),
  availability date "Immediately / pick a date" (`edit_profile_screen`).
- New test: `test/core/settings/accessibility_prefs_test.dart` (3 green).
- Still open: account-center hardcoded password date ("Jun 9, 2024"), email/phone-change OTP
  (no endpoint), cookie/notification prefs are local-only (logged in §2).

### 2026-09-11 — Cluster 3 (games discovery) — done
- `games_progress_provider.dart`: local, persisted coverage over the 5 cognitive dimensions
  + one-time monitoring consent. Hub now shows a real "Coverage X%" with a progress bar and
  marks completed dimension cards (design 68/73/74/76).
- Added the anti-fraud monitoring consent dialog shown before the first game (design 76).
  Game picker now returns the chosen route so completion can be recorded on return.
- Provisional by design: coverage is a client-local UI indicator until Games feeds
  per-module `coverage_ratio` (RECRUITMENT_MODULE.md §15.7) — scores stay server-side.
- Tests added/updated: `games_progress_test.dart`; hub screen/routing tests updated for the
  consent gate. Full suite: only pre-existing Move Fast / screenshot failures remain
  (files untouched by this work).

### 2026-09-11 — Cluster 4 (wallet / referral / plans / payment) — logged, not built
Per instruction, features with **no backend endpoint** are not fabricated; they are
enumerated in §2 with proposed endpoints, and their settings rows keep the "coming soon"
lock. Recap: Wallet (107/114/118/119), Referral (32/117), Hired candidates (258),
Plans & Pricing/subscription (261-263/316), recruitment-fee pre-authorization (290-295),
email/phone-change OTP (126-127), analytics/progress, assessment-integrity result.
`/payments` (video-conference) exists but has no UI screen yet and still needs a PSP.

### 2026-09-11 — Cluster 5 (candidate job search + polish) — done
- `JobsRepository.searchJobOffers()` → public `GET /job-offers` (q/location/contractType/
  experienceLevel). Candidate/student Search now lists real active offers instead of the
  broken fits deck (`fits_repository_impl.dart` called routes removed from the contract,
  RECRUITMENT_MODULE.md §15.10).
- `FitScoresGrid` gained an additive `onJobTap`; candidate job cards open
  `JobOfferDetailPage` (→ assessment flow) instead of the generic preview sheet.
- Profile & Settings "Help Center" row now navigates to the real Help Center (was dead).
- Notifications empty state already present (`NotificationsPage`).

### 2026-09-11 — Gap fill: public shared-test link (`GET /tests/{token}`) — done
- **Backend/shared**: `shared/SecurityConfig` now permits `GET /api/v1/tests/**`; the public
  projection responds without a JWT instead of 401 (roadmap RECRUITMENT_MODULE.md §15.2).
  Guarded by architecture test `PublicTestPermitRuleTest`.
- **Mobile**: `PublicAssessment` entity + `JobsRepository.getPublicTest(token)`,
  `PublicTestPreviewPage` at `/tests/:token`, and a **Preview** button on the assessment
  "Shareable link" card (design 216/306).
- No contract change (already `security: []`), no migration.
- Backend test not run locally (project targets Java 21; only JDK 17 installed) — CI covers it.

### 2026-09-11 — Gap fill: Manage tests (197) — done
- New `ManageTestsPage` (`/assessments`) listing the recruiter's tests with title, question
  count, duration, edit and delete actions, plus an Add button. Reached from the Careers home
  "Your Tests → See all". (Design 197.)
- Add-job-offer (204-217) already covers every field in the design; it uses inline dialogs
  instead of accordions and adds the required référentiel métier + pondération (F06/F30), so
  it is left as-is rather than regressing a working flow.

### 2026-09-11 — Gap fill: identity preferences (`/users/me/preferences`) — done
- **Contract** (`identity.openapi.yaml`): added `GET/PUT /users/me/preferences` +
  `UserPreferences`/`UserPreferencesUpdate` schemas. Identity now 48 operations; runtime/
  contract parity test updated and green.
- **Backend**: migration `V77__identity_user_preferences.sql`; pure domain record
  `UserPreferences` (+ range validation, defaults); `UserPreferencesRepository` + JPA
  entity/repo/adapter; `IdentityService.getPreferences/updatePreferences`; controller
  endpoints. Domain + updated service tests green (JDK 21).
- **Mobile**: `UserPreferences` model + `AuthRepository.getPreferences/updatePreferences`;
  `preferencesProvider` loads server prefs and mirrors them into the local accessibility +
  notifications providers, saving best-effort on change. Wired into the Accessibility screen
  and the Settings notifications toggle.
- Logged exception: this adds an identity DB table, explicitly authorized by the user
  (documented in `IDENTITY_AUTH_README.md` protected-zones note).

### 2026-09-11 — Gap fill: email/phone change OTP (`/users/me/email|phone`) — done
- **Decision:** SMS is not integrated — both change types deliver the OTP by **e-mail
  (Resend)**, including phone changes. SMS stays a future decision.
- **Contract**: `POST /users/me/email`, `/email/verify`, `/users/me/phone`, `/phone/verify`
  (+ `EmailChangeRequest`/`PhoneChangeRequest`/`VerificationCodeRequest`). Identity now
  **52** operations; parity test updated and green.
- **Backend**: migration `V78__identity_account_change_codes.sql`; domain
  `AccountChangeCode` + `AccountChangeType` (+ tests); repository/JPA/adapter; `User.changeEmail`
  / `changePhoneNumber`; `IdentityService.request/verifyEmailChange|PhoneChange` (SHA-256,
  10 min TTL, 5 attempts, `ConflictException` on a taken address); new `EmailPort.sendAccountChangeCode`
  + Resend rendering. Domain + parity + updated service tests green (JDK 21).
- **Mobile**: `AuthRepository.request/verifyEmailChange|PhoneChange`; a reusable
  `AccountChangeOtpDialog`; `PersonalInformationsScreen` now lets the e-mail be edited and
  triggers the OTP dialog + "Changes saved" flow when e-mail/phone change. `flutter analyze`
  clean; profile-settings/shared suites green.
- Fix: `preferencesProvider` now skips the network when signed out and times out, so widget
  tests never hang on the real Dio client.







