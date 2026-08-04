# Recap — backend session, 2026-07-20

Hand-off note for a fresh conversation. Four backend features built on
`integration-recruitment-align`, on top of the previously-recapped mobile port
(see `RECAP_MOBILE_PORT.md`) and the earlier integration-alignment work (see
`RECAP.md`). **Nothing in this recap is committed.** Full backend suite is
green (196 tests) and all 27 Flyway migrations were manually verified against
a real Postgres 17, but there has been no live Bruno/mobile pass yet.

---

## 0. Session shape

User asked for four things in sequence, each scoped to **backend only**
(mobile/frontend explicitly deferred each time):

1. Recruiter shortlist → candidate approval flow, gating the "send job
   opportunity" action.
2. AI test generation from a job description prompt or an uploaded PDF.
3. AI candidate "résumé" (soft-skills + hard-skills summary) for recruiters.
4. A 142-position job catalog seeded from an HR-provided weighting matrix,
   plus admin approval for recruiter-proposed new positions.

Feature 4 turned out to be **Phase 1** of a pre-existing plan
(`PLAN_FITSCORE_V3.md` at repo root, drafted 2 days earlier from a cahier des
charges + the same matrix PDF) — see that file for the full fit-score v3
roadmap and its D1-D8 decision gates (still unresolved; this session did not
touch the fit-score formula itself, which stays Groq-based).

---

## 1. Shortlist → candidate approval flow

Recruiter shortlists an applicant (existing `PENDING → SHORTLISTED` transition,
now actually publishes a domain event — it silently didn't before). The
candidate approves or rejects via a new endpoint; the recruiter can no longer
set `APPROVED` directly, or reject once already `SHORTLISTED`. Sending a job
opportunity offer ("Good Fit") now requires an `APPROVED` application **or**
an `ACTIVE` match for that job offer — this **reverses** the 16/07 "no
precondition" decision (recorded in memory).

- New: `ApplicationShortlistedEvent`, `RespondToShortlistUseCase`,
  `PATCH /applications/{id}/respond`.
- Changed: `ChangeApplicationStatusUseCase` (recruiter transitions
  restricted + events actually published), `SendOpportunityOfferUseCase`
  (new precondition).
- No notification/inbox system was built — the candidate app can already
  poll `GET /candidates/me/applications?status=SHORTLISTED`; the Engagement
  bounded context (separate squad, per its own `package-info.java`) owns
  actual push delivery off the new domain event.

## 2. AI test generation

Two new endpoints, matching a mobile mockup's actual fields (not the older
REC-04 dialog's job-title/difficulty fields):

- `POST /assessments/generate/from-prompt` — `{jobDescription (≤1000 chars),
  questionCount (1-30)}`.
- `POST /assessments/generate/from-file` — multipart `{file, questionCount}`,
  PDF only, treated as source material (a manual/book/existing quiz), not a
  job description.

Hexagonal: `AssessmentGeneratorPort` (Groq + offline stub, mirrors the
existing `FitScoreCalculatorPort` pattern) + `SourceDocumentExtractorPort`
(PDFBox adapter — kept out of the application layer on purpose, since
Infrastructure may only be depended on by the Api layer per
`ArchitectureTest`). Added the `pdfbox` 3.0.3 dependency.

Two latent bugs fixed in passing: `Assessment.createFromGeneration` never set
`shareableLink` (only `createManual` did); `UpstreamServiceException` (used by
the existing FitScore Groq adapter too) had **no handler at all** in
`GlobalExceptionHandler` — silently fell through to generic 500s. Now maps to
502.

## 3. AI candidate résumé

`GET /candidates/{candidateId}/resume?jobOfferId=` (RecruiterOnly) returns two
bilingual (fr+en, one Groq call each) sections:

- **Soft Skills Summary** — candidate-level, generated only from psychometric
  game module scores (matches the mockup's own caption: "measured through
  validated psychometric games"). Falls back to a static message if no games
  played yet.
- **Hard Skills Summary** — per (candidate, job offer): CV + that offer's
  test result. Falls back to *"a hard skill test should be tested for this
  job opportunity"* until an attempt exists, then regenerates on every
  submission.

Two real gaps closed to make this possible:

- **CV data never crossed into recruitment.** `FitScoreCalculatorPort`'s
  `cvText` input was hard-coded `null` with a `// PROVISOIRE` comment
  literally waiting for this. New `identity.ProfileCvUpdatedEvent`, wired into
  ~15 profile-mutation points in `IdentityService`, feeds a new
  `CvProfileProjection` in recruitment (a single pre-formatted text blob, not
  a structured model — it only feeds an LLM prompt).
- **Soft-skill scores were a single overwritten scalar.** `SoftSkillsProjection`
  used to be one row per candidate, clobbered by whichever game finished
  last. Now one row per (candidate, module) — `GameSoftSkillsListener` and
  `RecomputeFitScoresUseCase` updated accordingly (fit-score's "games" input
  is now an average across whatever modules exist).

## 4. Job-position catalog (142 métiers) + ExperienceLevel breaking change

⚠️ **Breaking change, chosen explicitly over the safer alternative**:
`ExperienceLevel` enum remapped `JUNIOR/MID/SENIOR/EXECUTIVE` →
`JUNIOR/SENIOR/LEAD/MANAGER` (matches the matrix's 4 bands; migration V24
remaps existing rows: MID→SENIOR, EXECUTIVE→MANAGER). **Mobile was not
updated** — anything sending/expecting the old 4 values on job-offer
create/filter will now behave wrong or 400.

New `recruitment.job_positions` table (migrations V25/V26), 142 rows seeded
from `Zennyt_Matrice_Finale_Ponderation_Metiers_v4.1.pdf` (9 transverse +
133 across 12 sectors), each with a RIASEC-style `profileType` and
`calibrated=false` (the matrix's own "v1 — non calibrée" caveat — don't treat
as production-validated). 13 of the 142 carry custom per-level display labels
from the PDF's annex (e.g. "Ouvrier / Compagnon qualifié": Junior="Apprenti /
Ouvrier débutant" … Manager="Chef de chantier"); the rest default to plain
Junior/Senior/Lead/Manager.

- `GET /job-positions?sector=` — any authenticated user, approved-only,
  embeds a `levelLabels` map so a frontend position-select can immediately
  populate the level-select with zero extra round-trips.
- `POST /job-positions` (RecruiterOnly) — propose a new one (`{name, sector}`
  only — no profile-type field; the matrix itself says that classification
  needs an HR workshop, so an admin assigns it at approval time). Usable on
  the recruiter's own offer immediately as `PENDING_APPROVAL`; only visible
  in the shared dropdown once approved.
- `GET /job-positions/pending` + `PATCH /job-positions/{id}/approve|reject`
  — new `@AdminOnly` (mirrors `@RecruiterOnly`; reuses the existing
  `RecruitmentActorPolicy` generically — `Role.ADMIN` already existed, just
  had no recruitment-side guard yet).
- `JobOffer.jobPositionId` — new nullable FK, wired through create/update/
  response.

**Verified**: applied all 27 migrations (V1→V27, including the 142-row seed
with escaped apostrophes) against a real Postgres 17 container manually —
the test suite has zero Spring-context/Testcontainers integration tests
(pure-mock unit tests only), and `PLAN_FITSCORE_V3.md` itself flags a prior
incident where a bad migration silently broke fresh-DB boot. Confirmed: 142
rows, 9 transverse, 13 with custom labels.

---

## 5. Testing & guardrails

- Backend suite: **196 tests, 0 failures** (was 148 at the start of 2026-07-20).
- `ArchitectureTest`, `ApiContractRouteParityTest` (guardrail count 44→53
  across the session), `RecruitmentSecurityAnnotationTest` all green.
- `contracts/recruitment.openapi.yaml` updated for every new endpoint +
  schema + the `ExperienceLevel` enum change.
- No live Bruno run this session — the dev environment (Docker/backend
  jar/emulator) was down at session start per `RECAP_MOBILE_PORT.md`; I only
  brought up Postgres standalone to hand-verify migrations, then left it
  otherwise as found (existing "postgres" container was started but the app
  jar was never booted against it).

## 6. Outstanding / next steps

- **Nothing is committed.** ~100 changed/new backend files across 4 features
  (full list: `git status backend contracts`).
- **Mobile is now further out of sync**: on top of the already-unported
  "Generate a test with AI" and "Resume AI" mockups, job-offer creation's
  experience-level values changed shape. Anyone touching mobile job-offer
  code next should read this recap first.
- No live end-to-end verification (Bruno or emulator) of any of the 4
  features — only unit tests + standalone migration checks.
- Phase 2 of `PLAN_FITSCORE_V3.md` (deterministic fit-score formula using the
  matrix weights, per-module coverage, hard-skills-alert display) is still
  fully gated behind the unresolved 19/07 meeting decisions (D1-D8) — not
  started.
- Environment is presumably still down (Docker Desktop was brought up only
  long enough to verify migrations against a scratch DB, which was dropped
  afterward) — check `docker ps -a` before assuming anything is running.

---

## Prompt to start the new conversation

> Read your memory first (MEMORY.md + zennyt-project-state.md), then read
> `RECAP_20260720_BACKEND.md` at the repo root — it covers four backend
> features built 2026-07-20 (shortlist/approval flow, AI test generation,
> AI candidate résumé, and a 142-position job catalog with a breaking
> `ExperienceLevel` change) on `integration-recruitment-align`, all backend-
> only and uncommitted. I want to <DESCRIBE NEXT TASK — e.g. "commit this
> work", "bring the environment up and run a full Bruno pass", "port the
> mobile job-creation position/level selects", "start Phase 2 of
> PLAN_FITSCORE_V3.md">. No Claude co-author trailer on commits.
