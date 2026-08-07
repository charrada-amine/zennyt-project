# Zennyt Recruitment — Bruno API collection

A clickable request collection covering the **Recruitment** backend (job
offers, job positions, assessments, swipes & matches, hard skill test
results, fit scores, candidate resume, identity verification, job
opportunity offers, video-call payments) plus the shared **Identity** login
flow, exactly as the mobile app calls it.

> Auth is real JWT (`POST /api/v1/auth/login`), never a simulated header.
> Every request after the logins carries a real `Authorization: Bearer
> <accessToken>`.

## Prerequisites

1. **Bruno** installed — https://www.usebruno.com (free, open source).
2. Postgres running and the backend started (see `docs/DEMO_INTEGRATION.md`
   at the repo root for the full fresh-database bring-up script, including
   the 6 demo accounts this collection logs in as).

## Open the collection

1. Bruno → **Open Collection** → select this folder (`tooling/bruno`).
2. Top-right environment dropdown → choose **Local**.
3. Open the **Demo** folder and click **Send** in order (00 → 12), or use
   **Run Collection**, or the CLI:
   ```powershell
   cd tooling/bruno
   npx @usebruno/cli run Demo --env Local
   ```

## What's in `Demo`

The only folder in this collection — see `Demo/README.md` for the full
request-by-request walkthrough (accounts, story order, expected statuses).
It is self-sufficient (creates its own job position, offer, assessment) and
rejayable without a database reset — each run creates fresh entities, except
the two idempotent job-position-proposal steps which suffix their name with
a per-run timestamp.

## Demo accounts (seeded, fixed UUIDs — see the bring-up script)

| Role                | Email                     | Bruno var             |
|---------------------|----------------------------|------------------------|
| Recruiter (Rania)   | `recruiter1@zennyt.com`   | `{{recruiterId}}`     |
| Recruiter (Youssef) | `recruiter2@zennyt.com`   | `{{recruiter2Id}}`    |
| Candidate (Aicha)   | `candidate1@zennyt.com`   | `{{candidateId}}`     |
| Candidate (Omar)    | `candidate2@zennyt.com`   | `{{candidate2Id}}`    |
| Candidate (Lina)    | `candidate3@zennyt.com`   | `{{candidate3Id}}`    |
| Admin (Sami)        | `admin1@zennyt.com`       | `{{adminId}}`         |

Password for all: `zennyt123`.

## Notes & gotchas

- **One TestAttempt/TestResult per (candidate, job offer), forever** —
  enforced at the database level. Re-running the collection from scratch on
  a non-fresh database will hit `ATTEMPT_ALREADY_CONSUMED` (409) on the
  hard-skill-test steps; reset the database (see the runbook) for a clean
  full pass.
- **Real OTP, not simulated.** `POST .../confirm` and `POST .../initiate`
  (payments) issue a genuine 6-digit code, salted + hashed, logged in clear
  text server-side only (`DevOtpDeliveryLogger`, dev profile). This
  collection demonstrates the deterministic *wrong-code → 401* path; the
  real code is only readable from the backend log — see
  `docs/DEMO_INTEGRATION.md` §B for verifying end-to-end live.
- **Callbacks** (`/callbacks/...`) use `X-Callback-Secret`, never a JWT — a
  wrong secret is rejected (401), matching real external-service auth.
- **Uniform error envelope**: every 4xx/5xx body is
  `{error: "CODE", message, ...context}` (`error` is a machine-readable
  code — a specific business one like `JOB_NOT_ACTIVE`/`ASSESSMENT_IN_USE`
  where one exists, otherwise a generic one derived from the HTTP status).
  Shared by Identity and Recruitment alike (`GlobalExceptionHandler`,
  `contracts/common.openapi.yaml#/components/schemas/Error`).
