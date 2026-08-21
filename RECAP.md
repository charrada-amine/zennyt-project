# Recap — recruitment backend corrections + integration alignment

Hand-off note to continue in a fresh conversation. Covers the two-day work on the
Zennyt recruitment backend: implementing the réunion-de-cadrage (16/07) corrections
on our branch, then aligning the other squad's integration branch on those rules.

---

## 0. Project context

- **Zennyt** = school recruitment app, two squads. Our scope = **backend only** (recruitment bounded context), hexagonal architecture (domain pure, ports in application, adapters in infrastructure). ArchUnit `ArchitectureTest` enforces it.
- **Our repo/remote:** `origin` = github.com/Ghassenboussalem/recruitment_zennyt
- **Other squad's repo/remote:** `amine` = github.com/charrada-amine/zennyt-project
- **Stack:** Spring Boot, PostgreSQL, Flyway/`ddl-auto` (dev = `ddl-auto: update`, no migrations), Groq (`openai/gpt-oss-120b`) for AI, JWT (RS256) auth, Bruno API collection in `tooling/bruno` (Demo folder = regression suite).
- **Source of decisions:** `notes.md` (critique parts 1–3) + 13 design mockups pasted in chat + explicit user confirmations.

## 1. Réunion de cadrage decisions (16/07) — what was locked

| Topic | Decision |
|---|---|
| **Fit score — trigger** | Precomputed per (candidate, offer) pair **before any interaction** (offer activation × known profiles; profile/games change × active offers). Not tied to application/match. |
| **Fit score — inputs** | Soft-skills (psychometric **games**) + CV/profile vs job description + company description. **Hard-skill test results excluded** (score precedes testing). |
| **Fit score — calculator** | Groq behind a `FitScoreCalculator` port; `POST /callbacks/fit-score` kept as alternative writer for the other squad's AI. Offline stub when no key. |
| **Fit score — consumers** | Both Fits decks (candidate "Job Offers" / recruiter "Professionnels"), Search suggestions, profile/job-detail badges. "Remove from Fit Scores" dismissal. |
| **Funnels** | Two tunnels stay **separate** (against the notes' convergence recommendation). "Recruit" sends a JobOpportunityOffer straight from a fit-scored profile — **no match, no application precondition**. |
| **Assessments** | The **assessment IS the application** — completing the offer's test creates the Application. Pass mark **60% default, per-offer override**. Recruiter results = per-offer list (score %, pass/fail, success rate, applicant count). |
| **Games** | Feed the fit score (soft-skills input), not a separate stream. |

## 2. Work on OUR branch `feature/REC-04-mobile-integration` (pushed to origin)

All six planned phases completed. Planning docs at repo root: `PLAN.md`, `TASKS.md`, `PROBLEMS.md`.

| Commit | What |
|---|---|
| `6b50e54` | **Phase 1 — fit score wiring.** `FitScoreCalculator` port; `GroqFitScoreCalculator` + `StubFitScoreCalculator`; `ComputeFitScoresUseCase` (fault-tolerant per pair); `FitScoreTriggerListener` (async `@TransactionalEventListener` on offer→ACTIVE); `FitScore` gains `source` + `dismissed`; exposure on `GET /candidates?jobOfferId=` (deck, sorted, dismissed excluded), `GET /job-offers` (+`sort=fit`) & detail for candidate; `DELETE /fit-scores` dismiss; `POST /fit-scores/recompute`; `X-Callback-Secret` validated on all 3 callbacks. |
| `b841054` | **Phase 2 — opportunity offer guards.** `SendOpportunityOfferUseCase`: candidate exists + offer ownership, publishes events, no match/application precondition. |
| `d6196a3` | **Phase 3 — assessment = application.** `JobOffer.passMark` (default 60); `AssessmentAttempt` takes `passMark` + `monitoringConsent`; `SubmitAssessmentAttemptUseCase` auto-creates the PENDING application; enriched recruiter applications + stats endpoints. |
| `b16c6d4` | **Phase 5 — Bruno** coverage for the new endpoints. |
| `93b4cc4` | **Phase 6 — docs**; annotate notes.md sections applied. |

Baseline before work: 32 tests + ArchitectureTest green, Bruno Demo 45/45. After: ~55 tests green. Groq verified live (e.g. Flutter profile scored 98 on the Flutter offer; DevOps profile 98 on a DevOps offer created hot via the async trigger).

> Note: this branch uses OUR `FitScore` model (`source`, `dismissed`). The merged repo uses a DIFFERENT model — see §3.

## 3. Integration alignment — branch `integration-recruitment-align` (MERGED into amine/integration)

Pulled `amine/integration` into a local branch. **Discovery:** the other squad had *independently* implemented most cadrage decisions with their own (often stronger) design:
- Fit score behind a port + Groq/stub, **games→SoftSkillsProjection** feeding soft-skills, `FitScore` with `softSkillScore`/`cvMatchScore`/`goodFit`, native SQL upsert, separate `FitScoreDismissal` table.
- Real **OTP** (salted SHA-256, TTL, max attempts) via `OtpService`; `passingScore` 60; attempt has an `applicationId` FK; `CallbackSecretVerifier`; `@RecruiterOnly`/`@CandidateOrStudentOnly` annotations; contract-parity + security-annotation **guardrail tests**.

So most of our parallel work was **duplicated effort** (two squads, same spec, no sync). Only these **five deltas** were genuinely missing and were ported in commit **`a52ecf0`**:
1. `SendOpportunityOfferUseCase` — ghost-candidate guard via `RecruitmentActorRepository` (theirs accepted any `candidateId`) + **domain-event publication** (theirs dropped them).
2. `monitoringConsent` — accepted (legacy `consent` still works), enforced **before any write** (**422**), and **persisted** on the attempt.
3. `IllegalStateException → 422` mapping in their `GlobalExceptionHandler` — also fixes OTP state-violations that returned **500**.
4. `POST /fit-scores/recompute` — synchronous demo lever (per-offer or all-ACTIVE), fault-tolerant per pair; flow stays async normally.
5. OpenAPI contract entry for the new route + guardrail counts 43→44 (parity test + security-annotation test).

Their full suite: **148 tests green**. Pushed to origin AND to `amine`; user has write access to their repo. **PR merged into `charrada-amine/zennyt-project` `integration`.**

> Their backend has **no maven wrapper** (builds via Docker). `backend/mvnw*` + `backend/.mvn/` were copied locally as test tooling — **untracked**, do not commit.

## 4. Credential cleanup (done this session)

- Removed exposed PAT from `~/.gitconfig` (`git config --global --unset-all user.password`) — it was under a bogus key and did nothing for auth.
- Deleted stale `Gastonlagaffe02` Windows credential (via `CredDelete` API; `cmdkey` couldn't handle the space).
- Working credential remains: `git:https://github.com` → **Ghassenboussalem**, via Git Credential Manager. Pushes work.

## 5. ⚠️ Outstanding / next steps

- 🔴 **Revoke the leaked PAT** `ghp_yme…29ytrc` on GitHub → Settings → Developer settings → Personal access tokens. (It leaked in plaintext; already removed from config but must be killed.)
- **Git stash** holds a `mobile/zennyt/android/gradle.properties` change from REC-04 — `git stash pop` after switching to `feature/REC-04-mobile-integration` if wanted.
- **Model divergence to watch:** our `feature/REC-04` `FitScore` (`source`/`dismissed`) ≠ the merged model (`softSkillScore`/`cvMatchScore`/`goodFit` + `FitScoreDismissal` table). If REC-04 is still the mobile app's live backend, that's fine; if REC-04 must merge into the shared repo later, reconcile to the merged model.
- **Process lesson:** the other squad's repo was referenced in memory from the start — check it BEFORE building parallel implementations next time.
- Untracked at repo root: `PLAN.md`, `TASKS.md`, `PROBLEMS.md`, `RECAP.md` (working docs; commit or ignore as desired).

## 6. Current git state

- On branch **`integration-recruitment-align`** (= `amine/integration` + `a52ecf0`), merged into their `integration`.
- `feature/REC-04-mobile-integration` pushed to origin with all six phases.
- Remotes: `origin` (ours), `amine` (theirs) — both writable.

---

## Prompt to start the new conversation

> Read your memory first (MEMORY.md + zennyt-project-state.md + cadrage-decisions-2026-07-16.md), then read `RECAP.md` at the repo root — it summarizes the recruitment backend corrections and the integration alignment I merged into the other squad's repo (charrada-amine/zennyt-project). We're on branch `integration-recruitment-align`. I want to <DESCRIBE NEXT TASK — e.g. "verify the merged integration backend end-to-end with Bruno", "reconcile the REC-04 FitScore model with the merged model", "start on the mobile side", etc.>. Backend scope unless I say otherwise; follow the hexagonal architecture, keep the guardrail tests (ArchitectureTest, ApiContractRouteParityTest, RecruitmentSecurityAnnotationTest) green, and no Claude co-author trailer on commits.
