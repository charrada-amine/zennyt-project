# Backend corrections — implementation plan (post-cadrage 16/07)

Branch: `feature/REC-04-mobile-integration` · Scope: **backend only** (recruitment BC)
Inputs: `notes.md` (critique + questions), 13 design mockups, meeting decisions confirmed 16/07.

---

## 0. Decisions locked at the réunion de cadrage

| Topic | Decision |
|---|---|
| **Fit score — trigger** | Precomputed per (candidate, job offer) pair **before any interaction**: on job-offer activation (vs known candidate profiles) and on profile arrival/update (vs ACTIVE offers). Not tied to application or match events. |
| **Fit score — inputs** | Soft-skills scores (psychometric games) + CV/profile vs job description + company description. **Hard-skill test results excluded** (score precedes testing). |
| **Fit score — calculator** | **Groq behind a `FitScoreCalculator` port** (works today). `POST /callbacks/fit-score` stays as the alternative writer so the other squad's AI service can take over later without domain changes. Offline stub when no `GROQ_API_KEY`. |
| **Fit score — consumers** | Both Fits decks ("Job Offers" tab for candidates, "Professionnels" tab for recruiters), Search suggestions (both directions), job-detail & profile badges. "Remove from Fit Scores" dismissal action. |
| **Funnels (1.2)** | The meeting went **against** the notes' convergence recommendation: tunnels stay separate. "Recruit" sends a `JobOpportunityOffer` **directly from a fit-scored profile** — no match, no application, no APPROVED precondition. Only guards: candidate exists, caller is a recruiter, OTP flow unchanged (PENDING → OTP_SENT → CONFIRMED). |
| **Assessments (1.3)** | **The assessment IS the application**: starting/submitting an offer's attached test (with security-monitoring consent) is what creates the Application. Pass mark **60% default, per-offer override**. Recruiter sees a per-offer results list: candidate, QCM score %, Successful/Failed, test date + success rate & applicant count. |
| **Vocabulary** | "Fits" (swipe tab) ≠ "fit score" — mobile rename out of backend scope; backend keeps `FitScore` as the single score concept. |
| **Games module (D18)** | Feeds the fit score (soft-skills input), not a separate stream. |

## 1. Current-state audit (code read on 16/07)

What already exists and is reused (do NOT rebuild):

- `FitScore` aggregate (0–100, per candidate×offer, upsert via `fromCallback`) + `FitScoreRepository` (`save`, `findByCandidateIdAndJobOfferId` only) + `GET /api/v1/fit-scores` + `POST /api/v1/callbacks/fit-score` (secret **not yet validated** — TODO in `CallbackController`).
- `JobOffer` already has: status machine DRAFT→ACTIVE→HIDDEN→CLOSED (mockup "Show/Hide" ✓), `salary`, `hiringContactId`, `companyInfo`, `assessmentId`, `PATCH /job-offers/{id}/status` ✓.
- `Assessment` already has: test library per recruiter, `shareableLink` (mockup "Get a link" ✓), max questions, time limit, Groq generation (`GroqAssessmentGenerator` behind `AssessmentGeneratorPort`, stub fallback).
- `AssessmentAttempt`: unique per (candidate, assessment, offer), QCM scoring, **hard-coded pass ≥ 50** (to change), `IntegrityStatus` via callback.
- `Application`: PENDING → SHORTLISTED → APPROVED/REJECTED, unique per (candidate, offer); `SubmitApplicationUseCase` publishes events after save.
- `CandidateProfile`: local read-model record with a **static seeded `fitScore` int** (to be superseded by real per-offer scores), psychometrics as text (decisionMaking…), hard skills map.
- `JobOpportunityOffer`: OTP_SENT state machine done; **controller builds the domain object directly (no use case) and never publishes its domain events**.
- Seeder (`DevDataSeeder`): fixed UUIDs shared with Bruno/mobile; 4 offers, 6 profiles, 4 fit scores.
- Bruno `Demo/` = 45 requests seq 1–45 (2 logins + 43), run from `tooling/bruno` with `npx @usebruno/cli run Demo --env Local`.
- Schema managed by `ddl-auto: update` in dev — **no Flyway migrations to write**; new columns/tables appear automatically.
- ArchUnit rules: domain must stay Spring-free; api → application → domain; infrastructure implements ports.

---

## 2. Phases

### Phase 1 — Fit score wiring (notes §1.1) → commit `feat(recruitment): wire the fit score end-to-end (Groq calculator behind a port)`

**1a. Domain**
- `FitScore`: add `boolean dismissed` (recruiter's "Remove from Fit Scores") + `dismiss()`/factory updates + a `source` enum {`CALLBACK`, `INTERNAL`} for traceability. New factory `FitScore.computed(candidateId, jobOfferId, score)` alongside `fromCallback`. Keep the invariant 0–100.
- `FitScoreRepository` port gains:
  - `List<FitScore> findByCandidateId(UUID candidateId)` (candidate's scores across offers, non-dismissed, score desc)
  - `List<FitScore> findByJobOfferId(UUID jobOfferId)` (recruiter side, non-dismissed, score desc)
  - upsert semantics documented on `save` (existing behaviour: last write wins on the pair).

**1b. Application layer**
- New port `application/port/FitScoreCalculator`:
  `record FitInput(CandidateProfile candidate, JobOffer offer) {}` → `int score(FitInput input)` (0–100; throws `UpstreamServiceException` on AI failure).
- New use case `ComputeFitScoresUseCase`:
  - `forOffer(UUID jobOfferId)` — score every known `CandidateProfile` against the offer, upsert.
  - `forCandidate(UUID candidateId)` — score the profile against every ACTIVE offer, upsert.
  - Failure-tolerant per pair (log + continue); never blocks the caller's transaction.
- New listener `application/listener/FitScoreTriggerListener`:
  - `@EventListener(JobOfferStatusChangedEvent)` when target == ACTIVE → `forOffer` (async, `@Async` + try/catch).
  - `@EventListener(JobOfferCreatedEvent)` → no-op (offers are created ACTIVE via use case? verify — `CreateJobOfferUseCase` publishes Created; trigger on whichever event marks the offer visible).
- Dev/demo lever: `POST /api/v1/fit-scores/recompute` (`hasRole('RECRUITER')`, body `{jobOfferId?}`) — synchronous recompute for the demo script (Groq latency visible, deterministic ordering).

**1c. Infrastructure**
- `infrastructure/ai/GroqFitScoreCalculator` — same integration style as `GroqAssessmentGenerator` (chat completions, JSON mode, fence-stripping, `UpstreamServiceException` mapping). Prompt inputs: target role, seniority, psychometrics (decisionMaking/cognitiveFlexibility/emotionalRegulation), hard-skills map, contract types ⟷ offer title, description, responsibilities, qualifications, companyInfo/companyName. Output schema `{"score": <0-100>, "rationale": "…"}` (rationale logged only).
- `infrastructure/ai/StubFitScoreCalculator` — deterministic offline heuristic (e.g. token overlap between profile skills/role and offer title/description scaled to 40–95) so the demo works keyless.
- Wire both in `AssessmentAiConfig` (rename → `RecruitmentAiConfig` if trivial, else new `FitScoreAiConfig`), keyed on the same `groq.api-key`.
- `FitScoreEntity`/adapter: new columns `dismissed`, `source`; new Jpa queries.

**1d. API / exposure**
- `GET /api/v1/candidates` (recruiter deck): optional `jobOfferId` param → decorate each profile with the real `FitScore` for that offer (fallback: profile's seeded value), **sort desc, exclude dismissed**. Response becomes a DTO (`CandidateCardResponse`) — stop returning the domain record raw.
- `JobOfferResponse` gains `Integer fitScore` (nullable). Candidate-facing reads (`GET /job-offers` search + `GET /job-offers/{id}`) fill it for the authenticated candidate when role is CANDIDATE/STUDENT; sorted desc when `sort=fit`.
- Search "Professionnels" direction: `GET /api/v1/candidates?q=…` simple filter (name/targetRole contains) with the same score decoration.
- Dismissal: `DELETE /api/v1/fit-scores?candidateId&jobOfferId` (`hasRole('RECRUITER')`) → marks dismissed.
- `CallbackController.fitScore`: validate `X-Callback-Secret` against `${callbacks.secret}` (new property, env `CALLBACK_SECRET`, dev default kept in Bruno env) → 401 on mismatch. (Fixes the standing TODO; applies to all three callbacks.)

**1e. Tests**
- Unit: stub calculator determinism; Groq calculator JSON parsing/clamping (mock RestTemplate, mirror `GroqAssessmentGeneratorTest`); `ComputeFitScoresUseCase` upsert + failure tolerance; dismissal excluded from lists.

### Phase 2 — Tunnels stay separate: opportunity-offer guards (notes §1.2) → commit `feat(recruitment): opportunity offer sent from sourcing with explicit minimal guards`

- New `SendOpportunityOfferUseCase` (move logic out of the controller):
  - validates the candidate exists (`CandidateProfileRepository`) → 404-style domain error otherwise (kills the "candidateId sorti de nulle part" hole);
  - validates the referenced `jobOfferId` exists **and belongs to the caller** (a recruiter can only attach their own offer);
  - persists then **publishes the aggregate's domain events** (currently silently dropped);
  - documents the meeting decision in the Javadoc: *no match/application precondition — décision de cadrage 16/07, sourcing direct*.
- Controller delegates; OTP endpoints untouched.
- Unit tests: unknown candidate rejected; foreign offer rejected; happy path publishes `JobOpportunityOfferSentEvent`.

### Phase 3 — Assessment = application (notes §1.3) → commit `feat(recruitment): the assessment attempt is the application; pass mark per offer`

**3a. Domain**
- `JobOffer`: new `int passMark` (default **60**), settable via update/create; validation 0–100.
- `AssessmentAttempt.submit(...)`: takes `int passMark` parameter — drop the hard-coded 50. `rehydrate` unchanged (stored `passed` is authoritative history).
- `AssessmentAttempt`: add `boolean monitoringConsent` (the mockup's "I agree to security monitoring" checkbox) recorded at submission.
- `Application`: no structural change — the (candidateId, jobOfferId) pair remains the join key; linkage is behavioural (below).

**3b. Application layer**
- New `SubmitAssessmentAttemptUseCase` (move logic out of `AssessmentAttemptController`):
  1. uniqueness check (existing);
  2. resolve the assessment **through the offer** (`jobOffer.assessmentId` must equal the submitted `assessmentId` — closes "réussir un test sans avoir postulé");
  3. score with `offer.passMark()`;
  4. **auto-create the Application (PENDING)** for (candidate, offer) if absent — the attempt registers the candidacy; publish `ApplicationSubmittedEvent` + `AssessmentAttemptSubmittedEvent`.
- `ChangeApplicationStatusUseCase` untouched (non-blocking per decision — recruiter can approve regardless of score; the info is surfaced instead).

**3c. API**
- `POST /api/v1/assessment-attempts`: body gains `monitoringConsent` (required true — 422 otherwise, mirroring the mockup gate); response gains `applicationId`.
- `GET /api/v1/job-offers/{id}/applications` (recruiter): **ownership check** (only the offer's recruiter — currently any recruiter can read any offer's pipeline: same class of hole as notes §1.4) and each row enriched:
  ```json
  { ...application, "candidateName": "...", "candidateAvatarUrl": "...",
    "attempt": {"score": 92, "passed": true, "integrityStatus": "VALIDATED", "submittedAt": "..."} | null,
    "fitScore": 87 | null }
  ```
- New `GET /api/v1/job-offers/{id}/application-stats` (recruiter owner): `{applicantCount, attemptedCount, successRate}` — powers the mockup's "Candidates 30 / Success rate 76%" header.
- `passMark` exposed in `JobOfferResponse` and accepted in create/update requests.

**3d. Tests**
- Attempt with wrong assessment for the offer → rejected. Attempt auto-creates the application; second attempt blocked; application not duplicated if it pre-exists (invited/spontaneous). Pass mark override respected (59 fails at 60; custom 75 map). Non-owner recruiter gets 403 on the applications list. Stats math (flagged attempts excluded from success rate, consistent with the mobile results page).

### Phase 4 — Cross-cutting leftovers → commit `fix(recruitment): callback secret enforcement + event publication`

(Items that fall out of phases 1–3 if not already absorbed there: callback secret on all three callbacks, opportunity-offer event publication, any DTO/serialization polish. Skip the commit if empty.)

### Phase 5 — Bruno + full verification → commit `test(bruno): cover fit-score wiring, apply-via-assessment and results endpoints`

- New Demo requests (renumber `seq` carefully — GUI treats seq 0 as unset, cf. commit 728d180):
  - Recompute fit scores (REC) → deck with scores (REC, `jobOfferId` param) → job-offers-with-fitScore (CAND) → dismissal + list-after-dismissal (REC) → callback with wrong secret → 401 (negative).
  - Submit attempt **with consent** → assert `applicationId` present → applications-for-offer enriched (REC) asserts `attempt.score` & `fitScore` → application-stats (REC) → non-owner recruiter applications → 403 (negative) → attempt without consent → 422 (negative).
  - Adjust existing #14 (Apply) / #20 (Submit attempt) to the new contract without breaking the scenario's arc.
- Verification gates, in order:
  1. `mvn -q test` in `backend/` — all unit tests + `ArchitectureTest` green.
  2. DB reset via the prep block in `docs/DEMO_ENCADRANT.md`.
  3. Backend up (dev profile, `.env` with `GROQ_API_KEY`).
  4. `npx @usebruno/cli run Demo --env Local` from `tooling/bruno` — 100% pass, count updated in README + memory.

### Phase 6 — Docs & bookkeeping → commit `docs: record the cadrage decisions and mark notes.md sections applied`

- Annotate `notes.md` §1.1/§1.2/§1.3 with ✅ + the decision actually taken (mirroring how §1.4/§1.5 were annotated).
- Update `docs/DEMO_ENCADRANT.md` if the demo script ordering changes; update Bruno README count.
- No Claude co-author trailer on any commit.

---

## 3. Commit map

| # | Message | Content |
|---|---|---|
| 1 | `feat(recruitment): wire the fit score end-to-end (Groq calculator behind a port)` | Phase 1 |
| 2 | `feat(recruitment): opportunity offer sent from sourcing with explicit minimal guards` | Phase 2 |
| 3 | `feat(recruitment): the assessment attempt is the application; pass mark per offer` | Phase 3 |
| 4 | `fix(recruitment): callback secret enforcement + event publication` | Phase 4 (if any residue) |
| 5 | `test(bruno): cover fit-score wiring, apply-via-assessment and results endpoints` | Phase 5 |
| 6 | `docs: record the cadrage decisions and mark notes.md sections applied` | Phase 6 |

## 4. Architecture guardrails (checked at every phase)

- Domain stays pure Java (no Spring/Jakarta imports) — calculators are **ports in `application/port`**, adapters in `infrastructure/ai`.
- Controllers never construct aggregates for write flows — use cases own transactions and event publication.
- No cross-context dependency (recruitment never imports identity internals); profile data keeps flowing through the local `CandidateProfile` read model.
- `ArchitectureTest` is the tripwire — run it after each phase, not only at the end.
