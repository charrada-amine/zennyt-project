# Zennyt Recruitment — Bruno API test collection

A clickable request collection for manually testing the Recruitment backend, the
way the Flutter app will. Two folders simulate the two user types — **Recruiter**
and **Candidate** — plus a **Callbacks** folder for external-service callbacks.

> There is **no login** in this backend (the `identity` context is not implemented).
> A "user" is just a UUID. In the `dev` profile, the backend reads the UUID from the
> `X-Dev-User` header, so each folder sends a different value to act as that person.

## Prerequisites

1. **Bruno** installed — https://www.usebruno.com (free, open source).
2. Postgres running and the backend started on the `dev` profile. From `backend/`:
   ```powershell
   docker start zennyt-pg
   .\mvnw.cmd spring-boot:run "-Dspring-boot.run.profiles=dev"
   ```
   On first start, the `dev` profile seeds demo data (3 active job offers, an
   assessment, a fit score). See the `DevDataSeeder` log line for the IDs.

## Open the collection

1. Bruno → **Open Collection** → select this folder (`tooling/bruno`).
2. Top-right environment dropdown → choose **Local**.
3. Click any request → **Send**.

## Demo identities (seeded, fixed UUIDs)

| Role      | UUID                                   | Bruno var       |
|-----------|----------------------------------------|-----------------|
| Recruiter | `11111111-1111-1111-1111-111111111111` | `{{recruiterId}}` |
| Candidate | `22222222-2222-2222-2222-222222222222` | `{{candidateId}}` |
| Offer 1   | `a0000000-0000-0000-0000-000000000001` | `{{offer1}}`    |
| Offer 2   | `a0000000-0000-0000-0000-000000000002` | `{{offer2}}`    |
| Offer 3   | `a0000000-0000-0000-0000-000000000003` | `{{offer3}}`    |
| Assessment| `b0000000-0000-0000-0000-000000000001` | `{{assessment1}}` |

## Recommended end-to-end run order

Requests capture IDs into shared variables (e.g. `matchId`, `applicationId`), so
order matters for the chained flows:

1. **Candidate → 01 Search job offers** — see the 3 seeded offers.
2. **Candidate → 04 Swipe offer** — candidate LIKEs offer1. Returns `matched: false` on its own — this is only half of the match.
3. **Recruiter → 08 Swipe candidate** — recruiter LIKEs the candidate *for offer1* (`jobOfferId`). Both sides have now LIKEd the same (candidate, offer) pair → returns `matched: true`, captures `matchId`.
4. **Candidate → 05 My matches** — the match shows up.
5. **Candidate → 06 Apply to offer** — captures `applicationId`.
6. **Recruiter → 06 Applications for offer** — recruiter sees the application.
7. **Recruiter → 07 Change application status** — PENDING → SHORTLISTED.
8. **Candidate → 08 Submit assessment attempt** — captures `attemptId`.
9. **Recruiter → 14 Assessment results for offer** — recruiter sees the score.
10. **Recruiter → 10 Send opportunity offer** — captures `opportunityOfferId`.
11. **Candidate → 11 Confirm opportunity offer** → **12 Verify opportunity OTP**.
12. **Recruiter → 12 Initiate payment** (needs `matchId`) → **13 Verify payment OTP**.
13. **Recruiter → 11 Request identity verification** → **Callbacks → 03** to resolve it.

## Notes & gotchas

- **One swipe / one application / one attempt per (user, target).** Re-sending those
  returns a 4xx "already done". To start fresh, reset the database:
  ```powershell
  docker exec zennyt-pg psql -U postgres -d zennyt -c "TRUNCATE recruitment.swipes, recruitment.matches, recruitment.applications, recruitment.assessment_attempts, recruitment.job_opportunity_offers, recruitment.video_conference_payments, recruitment.identity_verifications RESTART IDENTITY CASCADE;"
  ```
  (Leave job_offers / assessments / fit_scores intact, or truncate them too and
  restart the app to re-seed.)
- **OTP codes are not validated in dev** — any value (e.g. `12345`) confirms.
- **Callbacks** use `X-Callback-Secret` instead of `X-Dev-User`; the secret is not
  validated yet on the backend (it's a TODO), so any value passes.
- A 500 with a generic body means a real server error — the stack trace prints in
  the terminal running Spring Boot.
