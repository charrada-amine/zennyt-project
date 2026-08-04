# Problems register — recruitment backend

Three sections: (A) problems this iteration **solves** and how, (B) problems/risks **introduced or accepted** by the chosen design, (C) known problems **left open** (deliberately out of scope, with owner/next step).

---

## A. Problems being solved (mapped to notes.md)

| # | Problem (as observed in code) | Resolution in this iteration |
|---|---|---|
| A1 | **Fit score is an orphan contract** (§1.1): only writer is a callback nobody calls; only reader is a point query; decks/lists ignore it | `FitScoreCalculator` port + Groq adapter compute scores internally; triggered on offer activation (+ manual recompute endpoint); decks, search and detail responses expose and sort by it |
| A2 | **No trigger semantics**: nothing defines *when* a pair (candidate, offer) deserves a score | Decision: precomputed per pair before any interaction (offer activation × known profiles), matching the mockups where decks/search are ranked before any swipe/application |
| A3 | **Static seeded `CandidateProfile.fitScore`** masquerades as a real score (one number per candidate, not per offer) | Real per-offer `FitScore` decoration supersedes it in API responses; seeded value kept only as fallback for pairs not yet computed |
| A4 | **`POST /callbacks/fit-score` secret never validated** (TODO since creation) — anyone can forge scores | `X-Callback-Secret` checked against `${callbacks.secret}` on all three callbacks; 401 on mismatch; negative Bruno test |
| A5 | **Recruiter can't act on the score list** (mockup "Remove from Fit Scores" has no backend) | `dismissed` flag + `DELETE /fit-scores` endpoint; dismissed pairs excluded from decks/lists |
| A6 | **`JobOpportunityOffer.send()` accepts any `candidateId` from nowhere** (§1.2) | `SendOpportunityOfferUseCase` validates candidate existence and offer ownership. Per the 16/07 decision, **no** match/application precondition — direct sourcing is the intended product flow |
| A7 | **Opportunity-offer domain events silently dropped** (controller persists without publishing) | Use case publishes after save, aligning with `SubmitApplicationUseCase`'s pattern |
| A8 | **Attempt ↔ application never linked** (§1.3): pass a test without applying, approve without any test | The attempt **creates** the application (decision: assessment = the application). Attempt must reference the offer's own assessment |
| A9 | **Hard-coded 50% pass mark in the domain** while mockups show Successful@65 / Failed@58 | `passMark` on `JobOffer` (default 60, override per offer) injected into `AssessmentAttempt.submit` |
| A10 | **Recruiter decides blind** (§1.3): applications list shows no score/integrity | Rows enriched with best attempt (score, passed, integrity, date), candidate identity, fit score; `/application-stats` gives applicant count + success rate |
| A11 | **`GET /job-offers/{id}/applications` readable by any recruiter** (same class as the §1.4 hole, missed by the 16/07 sweep) | Ownership check → 403 for non-owners |
| A12 | **Mockup consent checkbox has no contract** ("I agree to security monitoring") | `monitoringConsent` required-true on attempt submission (422 otherwise), stored on the attempt |

## B. Risks accepted by the chosen design (watch list)

| # | Risk | Mitigation in place / accepted because |
|---|---|---|
| B1 | **N×M explosion**: precomputing candidate×offer scores via an LLM is O(profiles × offers) Groq calls; rate limits (free tier) will throttle | Dev dataset is 6×4; compute is async + per-pair fault-tolerant; manual recompute endpoint for demos; stub is free. If scaled: batch prompts or move to their AI service (the port makes the swap a one-liner) |
| B2 | **Score staleness**: profile or offer edits don't retrigger computation in every path (only offer-activation is wired; profile updates have no write endpoint today) | Accepted: profiles are seeder-fed placeholders until the Identity-events projection exists (C2). Recompute endpoint covers demos |
| B3 | **Non-determinism**: Groq may return different scores run-to-run → demo ordering may shift | Temperature 0.2 + rationale logged; stub is fully deterministic when keyless; seeder scores stay as stable fallback |
| B4 | **Assessment-as-application inverts the notes' recommendation** — if the product later wants spontaneous applications without a test, `POST /applications` still exists but nothing in the mobile flow calls it | Kept the endpoint; auto-create logic tolerates a pre-existing application, so both entry orders work |
| B5 | **Changing `AssessmentAttempt.submit` signature** breaks any existing caller/test using the 50% rule | Grep all callers; update `AssessmentAttemptController` → use case; adjust unit tests; stored `passed` on old rows untouched (history preserved) |
| B6 | **`ddl-auto: update` schema drift**: new columns (`dismissed`, `source`, `pass_mark`, `monitoring_consent`) appear automatically in dev but there are **no migrations** for prod | Accepted for the school demo (prod profile unused); flagged for the repo-merge plan where Flyway numbering is already a known hard point (`docs/IDENTITY_INTEGRATION_PLAN.md`) |
| B7 | **Callback secret in Bruno env** is effectively public in the repo | Dev-only secret; prod value would come from Key Vault per `application.yml` conventions |
| B8 | **Async listener + `@Async`** needs an executor and can't run in the caller's TX; failures are only logged | Deliberate: scoring must never block/rollback offer creation. Demo uses the synchronous recompute endpoint |

## C. Left open (explicitly out of scope this iteration)

| # | Open problem | Why deferred / next step |
|---|---|---|
| C1 | **Who computes long-term** — their AI service via callback vs our Groq | Port + callback both kept; swap is config-level. Revisit at repo merge |
| C2 | **`CandidateProfile` is still a seeded placeholder** (§1.6) — no `ProfileUpdated` event feed from Identity | Needs the other squad's event contract; recommendation (local projection) already in notes.md §1.6 |
| C3 | **Soft-skills inputs are qualitative strings** (High/Strong/Medium), not the numeric games scores the fit formula implies | Games module lives outside this repo; the calculator consumes what the profile has today. Recheck when games land |
| C4 | **"Pass an online interview"** wording on the offer page has no backend concept (no INTERVIEW status) | Mockups show no interview flow; treat as descriptive copy until the product says otherwise |
| C5 | **No HIRED terminal status / rejection reason** (§B10 of notes) | Meeting didn't decide; state machine untouched. Cheap to add later (one enum value + transition) |
| C6 | **`JobOpportunityOffer` → `SalaryProposal` rename** (§1.5) | Recommended "calm refactor before repo merge"; mechanical, not now |
| C7 | **OTP code is not actually verified** (any non-empty code passes) | Known dev stub, TODO sits in the domain since the 16/07 fix; needs an SMS/email provider decision |
| C8 | **VideoConferencePayment & Engagement/Analytics stubs** (§1.7) | Frozen pending an owner for Engagement, per meeting position |
| C9 | **IdentityVerification duplication** with the Identity squad (§1.7) | To cede at repo merge; endpoints kept meanwhile for the demo |
| C10 | **Public shareable test link** resolves to a URL that no backend route serves (link exists, no anonymous taking flow) | Anonymous attempts raise auth questions (who is the candidate?) — needs a product decision before building |
| C11 | **Fits tab rename** ("Discover"/"Matching") | Mobile copy change, out of backend scope |
