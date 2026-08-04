# Backend corrections — task checklist

Companion to `PLAN.md`. Tick items as they land; one commit per phase.
Legend: **[D]** domain · **[A]** application · **[I]** infrastructure · **[C]** api/controller · **[T]** test · **[B]** bruno

---

## Phase 0 — Baseline (no commit) ✅ 17/07

- [x] `git status` clean apart from planning files; on `feature/REC-04-mobile-integration`
- [x] `.env` present at repo root (`GROQ_API_KEY`, `JWT_ACCESS_TTL=PT2H`)
- [x] `mvn -q test` green in `backend/` (32 tests + ArchitectureTest)
- [x] DB reset per `docs/DEMO_ENCADRANT.md` prep block; backend boots on :8080 (dev profile)
- [x] `npx @usebruno/cli run Demo --env Local` from `tooling/bruno` → 45/45 (baseline proof)

## Phase 1 — Fit score wiring (§1.1) ✅ 17/07 — commit 6b50e54

### Domain
- [x] **[D]** `FitScore`: add `dismissed` (boolean) + `source` enum (`CALLBACK`/`INTERNAL`); factories `computed(...)` / `fromCallback(...)`; `dismiss()`; keep 0–100 invariant; extend `rehydrate`
- [x] **[D]** `FitScoreRepository`: `findByCandidateId(UUID)` and `findByJobOfferId(UUID)` — non-dismissed, score desc; document upsert on `save`

### Application
- [x] **[A]** Port `application/port/FitScoreCalculator` (`FitInput(candidate, offer)` → `int`, throws `UpstreamServiceException`)
- [x] **[A]** `ComputeFitScoresUseCase`: `forOffer(jobOfferId)` + `forCandidate(candidateId)`; per-pair try/catch (log & continue); upsert
- [x] **[A]** `FitScoreTriggerListener`: on offer becoming ACTIVE → async `forOffer`; verify which event fires on creation-as-ACTIVE (`JobOfferCreatedEvent` vs `JobOfferStatusChangedEvent`) and hook the right one(s)

### Infrastructure
- [x] **[I]** `GroqFitScoreCalculator` (JSON mode, `{"score", "rationale"}`, fence-stripping, clamp 0–100, `UpstreamServiceException` mapping — mirror `GroqAssessmentGenerator`)
- [x] **[I]** `StubFitScoreCalculator` (deterministic token-overlap heuristic, keyless demo)
- [x] **[I]** Bean wiring in AI config (same `groq.api-key` switch as assessments)
- [x] **[I]** `FitScoreEntity` + adapter + Jpa repo: `dismissed`, `source` columns; the two list queries (ddl-auto handles schema)

### API
- [x] **[C]** `GET /candidates`: optional `jobOfferId` → real per-offer score, sort desc, exclude dismissed; new `CandidateCardResponse` DTO (stop exposing the domain record); optional `q` filter (name/targetRole) for the "Professionnels" search
- [x] **[C]** `JobOfferResponse.fitScore` (nullable) filled for authenticated CANDIDATE/STUDENT on `GET /job-offers` + `GET /job-offers/{id}`; `sort=fit` param
- [x] **[C]** `POST /fit-scores/recompute` (RECRUITER; body `{jobOfferId?}`) — synchronous demo lever
- [x] **[C]** `DELETE /fit-scores?candidateId&jobOfferId` (RECRUITER) → dismiss
- [x] **[C]** `X-Callback-Secret` validated on **all three** callbacks against `${callbacks.secret}` (env `CALLBACK_SECRET`; dev default aligned with Bruno env) → 401 mismatch

### Tests
- [x] **[T]** Stub calculator determinism; Groq calculator parse/clamp/error paths (mock RestTemplate)
- [x] **[T]** `ComputeFitScoresUseCase`: upsert, one-pair failure doesn't abort the batch
- [x] **[T]** Dismissed scores excluded from both list queries
- [x] **[T]** `ArchitectureTest` still green
- [x] Commit 1: `feat(recruitment): wire the fit score end-to-end (Groq calculator behind a port)`

## Phase 2 — Opportunity-offer guards (§1.2) ✅ 17/07 — commit b841054

- [x] **[A]** `SendOpportunityOfferUseCase`: candidate exists (`CandidateProfileRepository`), offer exists **and belongs to caller**, save, **publish domain events** (currently dropped); Javadoc records the 16/07 decision (no match/application precondition — direct sourcing)
- [x] **[C]** `JobOpportunityOfferController.send` delegates to the use case; OTP endpoints untouched
- [x] **[T]** Unknown candidate → error; foreign offer → error; happy path publishes `JobOpportunityOfferSentEvent`
- [x] Commit 2: `feat(recruitment): opportunity offer sent from sourcing with explicit minimal guards`

## Phase 3 — Assessment = application (§1.3) ✅ 17/07 — commit d6196a3

### Domain
- [x] **[D]** `JobOffer.passMark` int, default 60, validated 0–100, in create/update/rehydrate
- [x] **[D]** `AssessmentAttempt.submit(..., int passMark)` — remove hard-coded 50
- [x] **[D]** `AssessmentAttempt.monitoringConsent` recorded at submission (+ rehydrate/entity)

### Application
- [x] **[A]** `SubmitAssessmentAttemptUseCase`: uniqueness → assessment must be the offer's (`jobOffer.assessmentId == req.assessmentId`) → score with `offer.passMark()` → **auto-create Application PENDING if absent** → publish both events
- [x] **[A]** `ChangeApplicationStatusUseCase` untouched (non-blocking decision)

### API
- [x] **[C]** `POST /assessment-attempts`: `monitoringConsent` required true (422 otherwise); response gains `applicationId`
- [x] **[C]** `GET /job-offers/{id}/applications`: **ownership check** (403 non-owner) + rows enriched with `candidateName`, `candidateAvatarUrl`, `attempt{score,passed,integrityStatus,submittedAt}`, `fitScore`
- [x] **[C]** `GET /job-offers/{id}/application-stats` (owner): `{applicantCount, attemptedCount, successRate}` — flagged (NOT_VALIDATED) attempts excluded from successRate, consistent with mobile
- [x] **[C]** `passMark` in `JobOfferResponse` + create/update requests

### Tests
- [x] **[T]** Wrong assessment for the offer → rejected
- [x] **[T]** Attempt auto-creates the application; doesn't duplicate a pre-existing one; second attempt blocked
- [x] **[T]** Pass-mark override respected (59 fails at 60; custom mark honoured)
- [x] **[T]** Non-owner recruiter → 403 on applications list; stats math incl. flagged exclusion
- [x] Commit 3: `feat(recruitment): the assessment attempt is the application; pass mark per offer`

## Phase 4 — Residue sweep ✅ vide (secret + événements absorbés en P1/P2)

- [x] Anything from phases 1–3 that slipped (callback secret on all callbacks, event publication, DTO polish)
- [x] Commit 4 only if non-empty: `fix(recruitment): callback secret enforcement + event publication`

## Phase 5 — Bruno + verification ✅ 17/07 — commit b16c6d4 (57/57, 22/22 assertions)

- [x] **[B]** New Demo requests (mind `seq` ≥ 1, cf. commit 728d180): recompute fit scores → recruiter deck with scores → candidate offers with `fitScore` → dismiss + verify exclusion → callback wrong secret 401 → attempt with consent (asserts `applicationId`) → enriched applications (asserts `attempt.score`, `fitScore`) → application-stats → non-owner 403 → attempt without consent 422
- [x] **[B]** Existing #14/#20 adjusted to the new contract; whole scenario still tells one demo story
- [x] `mvn -q test` green (unit + ArchitectureTest)
- [x] DB reset (prep block) → backend up → `npx @usebruno/cli run Demo --env Local` → 100%
- [x] Bruno README count updated
- [x] Commit 5: `test(bruno): cover fit-score wiring, apply-via-assessment and results endpoints`

## Phase 6 — Docs ✅ 17/07 — commit 93b4cc4

- [x] `notes.md` §1.1/§1.2/§1.3 annotated ✅ with the decision actually applied (style of §1.4/§1.5)
- [x] `docs/DEMO_ENCADRANT.md` demo script updated if ordering changed
- [x] Commit 6: `docs: record the cadrage decisions and mark notes.md sections applied`
- [x] Memory file updated (suite count, state)

> Reminder: **no Claude co-author trailer** on any commit.
